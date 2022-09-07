Log = {}
if SCRIPT_DEBUG == nil then
    SCRIPT_DEBUG = false
end
function Log._log(prefix, ...)
    local mod = debug.getinfo(3).name or "_anon_func"
    local msg = ""
    for _, a in ipairs(...) do
        msg = msg .. tostring(a) .. "\t"
    end
    util.toast(string.format("[%s] %s:%s/%s: %s", prefix, SCRIPT_NAME, SCRIPT_SOURCE or "DEV", mod, msg))
end
function Log.debug(...)
    if SCRIPT_DEBUG then
        local arg = {...}
        Log._log("debug", arg)
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