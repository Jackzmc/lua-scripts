local jutil = {}
function jutil.TouchFile(path)
    if not filesystem.exists(path) then
        local file = io.open(path, "w")
        file:close()
    end
end
function jutil.ReadKV(file)
    local kv = {}
    for line in file:lines("l") do
        local key, value = line:match("(.+): (%g+)")
        if key then
            kv[key] = value
        end
    end
    return kv
end

function jutil.WriteKV(file, kv, prefix)
    file:seek("set", 0)
    if prefix then
        file:write(prefix)
    end
    for k, v in pairs(kv) do
        file:write(k .. ": " .. v .. "\n")
    end
    file:flush()
end

local _timers = {}
local _timer_id = 1
function _get_timer_id()
    local id = _timer_id
    _timer_id = _timer_id + 1
    _timers[id] = true
    return id
end

--- Creates a timer that is called every millisecond. Use jtuil.StopTimer to cancel
--- @param callback function A function to be called every interval
--- @param ... any arguments to pass to callback
--- @returns number Returns a timer id
function jutil.CreateTimer(ms, callback, ...)
    if not ms or not callback then error("Missing one or more properties: 'ms', and 'callback'") end
    local data = {...}
    local timerId = _get_timer_id()
    util.create_tick_handler(function()
        callback(data)
        util.yield(ms)
        return _timers[timerId]
    end)
    return timerId
end

--- Creates a timeout that is called after the specified amount of ms elapses. Use jtuil.StopTimer to cancel
--- @param callback function A function to be called once time is up
--- @param ... any arguments to pass to callback
--- @returns number Returns a timer id
function jutil.CreateTimeout(ms, callback, ...)
    if not ms or not callback then error("Missing one or more properties: 'ms', and 'callback'") end
    local data = {...}
    local timerId = _get_timer_id()
    util.create_tick_handler(function()
        ms = ms - 1
        if ms <= 0 then
            callback(data)
            return false
        end
        return _timers[timerId]
    end)
    return timerId
end

--- Creates a timeout that is called after the specified amount of ms elapses. Use jtuil.StopTimer to cancel
--- @param callback function A function to be called once time is up
--- @param ... any arguments to pass to callback
--- @returns boolean returns true if timer was valid
function jutil.StopTimer(timerId)
    local result = false
    if _timers[timerId] then result = true end
    _timers[timerId] = nil
    return result
end

function jutil.ParseSemver(version)
    local major, minor, patch = version:match("(%d+)%.(%d+)%.(%d+)")
    if not major then return nil end
    return {
        major = tonumber(major) or 0,
        minor = tonumber(minor) or 0,
        patch = tonumber(patch) or 0
    }
end
--- Compares two semver versions.
--- @return number 1 if A > B, 0 if same, -1 if A < B
function jutil.CompareSemver(a, b)
    local av = jutil.ParseSemver(a)
    local bv = jutil.ParseSemver(b)

    if av.major > bv.major then return 1
    elseif av.major < bv.major then return -1
    elseif av.minor > bv.minor then return 1
    elseif av.minor < bv.minor then return -1
    elseif av.patch > bv.patch then return 1
    elseif av.patch < bv.patch then return -1
    else return 0 end
end

function jutil.DumpTable(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. jutil.DumpTable(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
end

--- Fetches json via GET
--- @param uri string The full url (with domain) to fetch from
--- @param headers ?Record<string, string> Key-value list of headers, optional
--- @param payload ?string A payload optionally to send, will be sent as serialized json (don't encode before)
--- @param successCallback function Called with json results (statusCode, resultHeaders, result). If status code is 204, result is nil
--- @param errorCallback ?function Optionally called with any errors. (statusCode, resultHeaders, errorMessage) Network error is -1 
function jutil.GetJson(uri, headers, successCallback, errorCallback)
    _doJsonRequest("POST", uri, headers, nil, successCallback, errorCallback)
end

--- POST to a URL and parses JSON.
--- @param uri string The full url (with domain) to fetch from
--- @param headers ?Record<string, string> Key-value list of headers, optional
--- @param payload ?string A payload optionally to send, will be sent as serialized json (don't encode before)
--- @param successCallback function Called with json results (statusCode, resultHeaders, result). If status code is 204, result is nil
--- @param errorCallback ?function Optionally called with any errors. (statusCode, resultHeaders, errorMessage) Network error is -1 
function jutil.PostJson(uri, headers, payload, successCallback, errorCallback)
    _doJsonRequest("GET", uri, headers, payload, successCallback, errorCallback)
end

function _doJsonRequest(type, uri, headers, payload, successCallback, errorCallback)
    if type == 'GET' and not successCallback then
        error("Missing success callback for GET request")
    end
    
    local domain, path = uri:match("([a-zA-Z.-]+)(/.*)")
    if not domain then
        error("Invalid URI provided: " .. uri)
    end
    async_http.init(
        domain, path, 
        function(body, resHeaders, statusCode)
            if statusCode == 200 then
                local status, obj = pcall(json.decode, body)
                if status then
                    successCallback(statusCode, resHeaders, obj)
                elseif errorCallback ~= nil then
                    errorCallback(statusCode, resHeaders, "Invalid json result: " .. obj)
                end
            elseif statusCode == 204 then
                successCallback(statusCode, resHeaders, nil)
            elseif errorCallback ~= nil then
                errorCallback(statusCode, resHeaders, "Server returned status code " .. statusCode)
            end
        end,
        function()
            if errorCallback ~= nil then
                errorCallback(-1, {}, "Network Error")
            end
        end
    )

    if type == "POST" then
        async_http.set_post("application/json", payload and json.encode(payload) or "")
    elseif type ~= "GET" then
        error("Invalid method type, only GET or POST is supported.")
    end

    if headers then
        for k, v in pairs(headers) do
            async_http.add_header(k, v)
        end
    end

    async_http.dispatch()
end

function jutil.ShowBusySpinner(text)
    HUD.BEGIN_TEXT_COMMAND_BUSYSPINNER_ON("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    HUD.END_TEXT_COMMAND_BUSYSPINNER_ON(2)
end
function jutil.StopBusySpinner(text)
    HUD.BUSYSPINNER_OFF()
end


return jutil