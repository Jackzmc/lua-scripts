local Version = {
    PATH = filesystem.store_dir() .. "jackzscript.versions.txt",
    file = nil,
    versions = {}
}

function Version:Load()
    if not self.file then
        JUtil.TouchFile(self.PATH)
        self.file = io.open(self.PATH, "r+")
    end
    JUtil.ReadKV(self.file)
    if self.versions["_core_"] == nil or JUtil.CompareSemver(VERSION, self.versions["_core_"]) == 1 then
        if self.versions["_core_"] ~= nil then
            async_http.init("jackz.me", "/stand/changelog.php?raw=1&script=" .. SCRIPT_NAME .. "&since=" .. self.versions["_core_"], function(result)
                util.toast("Changelog for " .. SCRIPT_NAME .. " version " .. VERSION .. ":\n" .. result)
            end, function() util.log(SCRIPT_NAME ..": Could not get changelog") end)
            async_http.dispatch()
        end
        self.versions["_core_"] = VERSION
    end
    
end

function Version:Compare(module, b)
    return JUtil.CompareSemver(self.versions[module], b)
end

function Version:Get(module)
    return self.versions[module]
end

function Version:Set(module, v)
    self.versions[module] = v
    self:Save()
end

function Version:Save()
    if not self.file then
        error("Versions have not been loaded, cannot save")
    end
    JUtil.WriteKV(self.file, self.versions, "# DO NOT EDIT ! File is used for changelogs\n")
end

-- Check for core-version changelog

return Version