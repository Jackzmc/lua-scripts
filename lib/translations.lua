-- Lua Translations API
-- Created by Jackz
-- File format: Empty lines and lines that start with # (only first two characters checked) are ignored.
-- Note: First character MUST be a # for auto download to work.
-- See the return { } table at bottom for public methods
-- See jackz_chat or jackz_vehicles for examples

local LIB_VERSION = "1.1.0"
local translations = {}
local translationAvailable = false
local autodownload = {
    active = false,
    domain = nil,
    uri = nil
}

local GAME_LANGUAGE_IDS = {
    [1] = "en-US",
    [2] = "fr-FR",
    [3] = "de-DE",
    [4] = "it-IT",
    [5] = "es-ES",
    [6] = "pt-BR",
    [7] = "pl-PL",
    [8] = "ru-RU",
    [9] = "ko-KR",
    [10] = "zh-TW",
    [11] = "ja-JP",
    [12] = "es-MX",
    [13] = "zh-CN",
}
local LANGUAGE_NAMES = {
    ["en-US"] = "English",
    ["fr-FR"] = "French",
    ["de-DE"] = "German",
    ["it-IT"] = "Italian",
    ["es-ES"] = "Spanish",
    ["pt-BR"] = "Brazilian",
    ["pl-PL"] = "Polish",
    ["ru-RU"] = "Russian",
    ["ko-KR"] = "Korean",
    ["zh-TW"] = "Chinese (Traditional)",
    ["ja-JP"] = "Japanese",
    ["es-MX"] = "Spanish (Mexican)",
    ["zh-CN"] = "Chinese (Simplified)"
}
local lang = GAME_LANGUAGE_IDS[LOCALIZATION.GET_CURRENT_LANGUAGE() + 1]
local HARDCODED_TRANSLATIONS = {
    ["en-US"] = {
        ["ERR_NO_TRANSLATION_KEY"] = "Unknown translation ",
        ["ERR_NO_TRANSLATION_FILE"] = "No language translation is available.",
        ["ERR_NO_TRANSLATION_FILE_LOADED"] = "Translation file was never loaded. Contact developer.",
        ["ERR_AUTODL_FAIL"] = "Could not automatically download translation files.",
        ["ERR_INVALID_STORED_LANGUAGE"] = "Ignoring unknown preferred language, falling back to en-US",
        ["LANG_PREF_CHANGED"] = "Preferred language has been switched. Please restart scripts to use selected language."
    }
}

local function get_internal_message(key)
    if HARDCODED_TRANSLATIONS[lang] and HARDCODED_TRANSLATIONS[lang][key] then
        return HARDCODED_TRANSLATIONS[lang][key]
    elseif HARDCODED_TRANSLATIONS["en-US"][key] then
        return HARDCODED_TRANSLATIONS["en-US"][key]
    else
        return "_NO_TRANSLATION_AVAILABLE_"
    end
end

local PREF_FILE = filesystem.stand_dir() .. "/Translations/Preferred Language.txt"
if filesystem.exists(PREF_FILE) then
    local file = io.open(PREF_FILE, "r")
    io.input(file)
    local value = io.read("*all")
    io.close(file)
    local valid = false
    for _, language in ipairs(GAME_LANGUAGE_IDS) do
        if value == language then
            lang = value
            valid = true
            break
        end
    end
    -- Discard invalid languages
    if not valid then
        util.toast(get_internal_message("ERR_INVALID_STORED_LANGUAGE"))
    end
end

local function parse_translations_from_file(file)
    local path = filesystem.stand_dir() .. "Translations/" .. file .. ".txt"
    if not filesystem.exists(path) then
        return false
    end
    for line in io.lines(path) do
        local key = ""
        local value = ""
        local isValueReady = 0
        line:gsub(".", function(c)
            if isValueReady == -1 then
                return
            end
            if isValueReady > 0 then
                if isValueReady == 1 and c ~= " " then
                    isValueReady = 2
                end
                if isValueReady == 2 then
                    value = value .. c
                end
            elseif c ~= ":" then
                if c == "#" then
                    isValueReady = -1
                end
                key = key .. c
            else
                isValueReady = 1
            end
        end)
        if isValueReady and isValueReady == 2 then
            translations[string.upper(key)] = value:gsub("\\([nt])", {n="\n", t="\t"})
        end
    end
    return true
end


---------------
-- Public API
---------------
-- Set the saved language preference. Returns true on success, returns false on invalid language
function set_language_preference(prefLang)
    for _, language in ipairs(GAME_LANGUAGE_IDS) do
        if prefLang == language then
            local file = io.open(PREF_FILE, "w")
            io.output(file)
            io.write(prefLang)
            io.close(file)
            return true
        end
    end
    return false
end
-- Optional, will automatically download translation files from domain and uri if set
function set_autodownload_uri(domain, uri)
    autodownload.domain = domain
    autodownload.uri = uri
end
-- Attempt to load the specified translation file, returns language if successful or false if none found
-- Needs to be called or all text will return translated ERR_NO_TRANSLATION_FILE_LOADED
function load_translation_file(filePrefix)
    if parse_translations_from_file(filePrefix .. "_" .. lang) then
        translationAvailable = true
        return lang
    elseif autodownload.domain ~= nil then
        download_translation_file(autodownload.domain, autodownload.uri, filePrefix .. "_" .. lang)
        while autodownload.active do
            util.yield()
        end
        if translationAvailable then
            return lang
        elseif parse_translations_from_file(filePrefix .. "_" .. "en-US") then -- Could not find any file to auto download, fall back to english
            translationAvailable = true
            lang = "en-US"
            return lang
        else
            download_translation_file(autodownload.domain, autodownload.uri, filePrefix .. "_en-US")
            while autodownload.active do
                util.yield()
            end
            if translationAvailable then
                lang = "en-US"
                return lang
            else
                return false
            end
        end
    end
    return false
end
-- Attempt to download a translation file from https://domai/path/fileprefix_lang-code.txt
-- Example: download_translation_file("jackz.me", "/stand/translations/", "jackz_vehicles") -> https://jackz.me/stand/translations/jackz_vehicles-en-US.txt
function download_translation_file(domain, uri, filepart)
    filesystem.mkdir(filesystem.stand_dir() .. "Translations")
    async_http.init(domain, uri .. filepart .. ".txt" , function(result)
        if result:sub(1, 1) ~= "#" then -- IS HTML
            autodownload.active = false
            return
        end
        local file = io.open(filesystem.stand_dir() .. "/Translations/" .. filepart .. ".txt", "w")
        io.output(file)
        io.write(result:gsub("\r", "") .. "\n")
        io.flush() -- redudant, probably?
        io.close(file)
        parse_translations_from_file(filepart)
        translationAvailable = true
        autodownload.active = false
    end, function(e)
        util.toast(get_internal_message("ERR_AUTODL_FAIL"))
        autodownload.active = false
    end)
    autodownload.active = true
    async_http.dispatch()
end
-- Only works if an autodownload url was set
function update_translation_file(filePrefix)
    download_translation_file(autodownload.domain, autodownload.uri, filePrefix .. "_" .. lang)
    download_translation_file(autodownload.domain, autodownload.uri, filePrefix .. "_en-US")
end
-- Gets the language name (in english). en-US -> English, etc
function get_language_name()
    return LANGUAGE_NAMES[lang]
end
-- Gets the ISO language code (en-US, fr-FR, etc)
function get_language_id()
    return lang
end


-- Attempt to use translation ID & format text. Returns nil if translation key does not exist. Returns false if no translation file was loaded
function format(translationID, ...)
    if not translationAvailable then
        return get_internal_message("ERR_NO_TRANSLATION_FILE_LOADED")
    end
    local text = translations[string.upper(translationID)]
    if text == nil then
        return string.upper(translationID)
    elseif ... ~= nil then
        return string.format(text, ...)
    else
        return text
    end
end

-- Runs the format function and also toasts the value
function toast(translationID, ...)
    if not translationAvailable then
        util.toast(get_internal_message("ERR_NO_TRANSLATION_FILE_LOADED"))
    end
    local text = (... == nil) and format(translationID) or format(translationID, ...)
    util.toast(text)
end

function add_language_selector_to_menu(root)
    local list = menu.list(root, "Language", {}, "Sets your preferred language.\nCurrent language: " .. get_language_name() .. " (" .. lang .. ")")
    for _, iso in ipairs(GAME_LANGUAGE_IDS) do
        menu.action(list, LANGUAGE_NAMES[iso], {}, iso, function(_)
            set_language_preference(iso)
            util.toast(get_internal_message("LANG_PREF_CHANGED"))
        end)
    end
end

function no_op() end

return {
    VERSION = LIB_VERSION,
    load_translation_file = load_translation_file,
    download_translation_file = download_translation_file,
    set_autodownload_uri = set_autodownload_uri,
    update_translation_file = update_translation_file,
    set_language_preference = set_language_preference,
    get_language_name = get_language_name,
    get_language_id = get_language_id,
    format = format,
    toast = toast,
    translations = translations,
    is_downloading = function() return autodownload.active end,
    GAME_LANGUAGE_IDS = GAME_LANGUAGE_IDS,
    LANGUAGE_NAMES = LANGUAGE_NAMES,
    menus = {
        -- Creates a menu.list() with translation prefix
        list = function(root, section, commands)
            return menu.list(root, format(section .. "_NAME"), commands, format(section .. "_DESC"))
        end,
        -- Creates a menu.action() with translation prefix
        action = function(root, section, commands, callback, callback2, syntax)
            return menu.action(root, format(section .. "_NAME"), commands, format(section .. "_DESC"), callback, callback2 or no_op, syntax or no_op)
        end,
        -- Creates a menu.divider() with translation prefix
        divider = function(root, section)
            return menu.divider(root, format(section .. "_DIVIDER"))
        end,
        -- Creates a menu.toggle() with translation prefix
        toggle = function(root, section, commands, callback, default)
            return menu.toggle(root, format(section .. "_NAME"), commands,format(section .. "_DESC"), callback, default or false)
        end,
        -- Creates a menu.slider() with translation prefix
        slider = function(root, section, commands, min, max, default, step, callback)
            return menu.slider(root, format(section .. "_NAME"), commands, format(section .. "_DESC"), min, max, default or 0, step or 1, callback)
        end,
        -- Creates a menu.click_slider() with translation prefix
        click_slider = function(root, section, commands, min, max, default, step, callback)
            return menu.click_slider(root, format(section .. "_NAME"), commands, format(section .. "_DESC"), min, max, default or 0, step or 1, callback)
        end,
        -- Creates a menu.colour() (first method) with translation prefix
        colour = function(root, section, commands, color, transparency, callback)
            return menu.colour(root, format(section .. "_NAME"), commands, format(section .. "_DESC"), color, transparency, callback)
        end,
    },
    add_language_selector_to_menu = add_language_selector_to_menu
}


