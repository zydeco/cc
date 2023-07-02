local args = {...}
if #args == 1 then
    require("colony/stubs/" .. args[1])
    colony = COLONY_STUB
else
    colony = peripheral.find("colonyIntegrator")
    if colony == nil then
        print("No colony integrator")
        return 1
    end
end

require("colony/strings")
require("colony/jobs")

local citizens = colony.getCitizens()
local citizensById = {}
for i = 1, #citizens do
    local citizen = citizens[i]
    citizensById[citizen.id] = citizen
end
local jobsToAssign = jobsForBuildings(colony.getBuildings(), false)
local jobs = assignJobs(citizens, jobsToAssign)

local jobsFile = fs.open("jobs" .. args[1] .. ".txt", "w")
for id, job in pairs(jobs) do
    local citizen = citizensById[id]
    jobsFile.writeLine(citizen.name .. ": " .. translate(job))
end
jobsFile.close()
