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

--- Creates a timer that is called every millisecond
--- @param callback function A function to be called every interval
--- @param ... any arguments to pass to callback
function jutil.CreateTimer(ms, callback, ...)
    if not ms or not callback then error("Missing one or more properties: 'ms', and 'callback'") end
    local data = {...}
    util.create_tick_handler(function()
        callback(data)
        util.yield(ms)
        return true
    end)
end

--- Creates a timeout that is called after the specified amount of ms elapses
--- @param callback function A function to be called once time is up
--- @param ... any arguments to pass to callback
function jutil.CreateTimeout(ms, callback, ...)
    if not ms or not callback then error("Missing one or more properties: 'ms', and 'callback'") end
    local data = {...}
    util.create_tick_handler(function()
        ms = ms - 1
        if ms <= 0 then
            callback(data)
            return false
        end
        return true
    end)
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

--- Fetches a URL and parses JSON.
--- @param type string either 'GET' or 'POST'
--- @param uri string The full url to fetch from
--- @param headers Record<string, string> Key-value list of headers
--- @param payload ?string A payload optionally to send
--- @return any json object or false on invalid json, or nil on 204
function jutil.FetchJson(type, uri, headers, payload)
    local domain, path = uri:match("([a-zA-Z.-]+)(/.*)")
    if not domain then
        error("Invalid URI provided: " .. uri)
    end
    local result = nil
    async_http.init(domain, path, function(body, res_headers, status_code)
        if status_code == 200 then
            local status, obj = pcall(json.decode, body)
            if status then
                jutil.DumpTable(obj)
                result = obj
            else
                result = false
            end
        elseif status_code == 204 then
            return nil
        else
            error("Server returned status code " .. status_code)
        end
    end, function()
        error("Network Error")
    end)
    if type == "POST" then
        async_http.set_post("application/json", payload or "")
    elseif type ~= "GET" then
        error("Invalid method type, only GET or POST is supported.")
    end
    if headers then
        for k, v in pairs(headers) do
            async_http.add_header(k, v)
        end
    end
    async_http.dispatch()
    -- Wait for download to complete
    while result == nil do
        util.yield()
    end
    return result
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