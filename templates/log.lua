Log = {}
if SCRIPT_DEBUG == nil then
    SCRIPT_DEBUG = false
end
function Log._log(prefix, ...)
    local mod = debug.getinfo(3, "n").name or debug.getinfo(4, "n").name or "_anon_func"
    local msg = ""
    for _, a in ipairs(...) do
        if a == nil then a = "<nil>" end
        msg = msg .. tostring(a) .. "\t"
    end
    if prefix then prefix = "[" .. prefix .. "] "
    else prefix = "" end
    util.log(string.format("%s%s:%s/%s: %s", prefix, SCRIPT_NAME, SCRIPT_SOURCE or "DEV", mod, msg))
end
function Log.debug(...)
    if SCRIPT_DEBUG then
        local arg = {...}
        Log._log("debug", arg)
    end
end
function Log.debugTable(table)
    if SCRIPT_DEBUG then
        local mod = debug.getinfo(3, "n").name or debug.getinfo(4, "n").name or "_anon_func"
        util.log(string.format("%s:%s/%s: %s", SCRIPT_NAME, SCRIPT_SOURCE or "DEV", mod, dumpTable(table)))
    end
end
function Log.warn(...)
    local arg = {...}
    Log._log("Warn", arg)
end
function Log.error(...)
    local arg = {...}
    Log._log("Error", arg)
end
function Log.severe(...)
    local arg = {...}
    Log._log("Severe", arg)
    util.stop_script()
end
function Log.log(...)
    local arg = {...}
    Log._log(nil, arg)
end

function dumpTable(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dumpTable(v) .. ','
       end
       return s .. '} '
    elseif type(o) == "string" then
        return '"' .. o .. "'"
    else
       return tostring(o)
    end
end