require("colony/utils")

local JOB_SKILLS = {
    ["com.minecolonies.job.alchemist"] = {"Dexterity", "Mana"},
    ["com.minecolonies.job.archertraining"] = {"Agility", "Adaptability"},
    ["com.minecolonies.job.baker"] = {"Knowledge", "Dexterity"},
    ["com.minecolonies.job.beekeeper"] = {"Dexterity", "Adaptability"},
    ["com.minecolonies.job.blacksmith"] = {"Strength", "Focus"},
    ["com.minecolonies.job.builder"] = {"Adaptability", "Athletics"},
    ["com.minecolonies.job.chickenherder"] = {"Adaptability", "Agility"},
    ["com.minecolonies.job.combattraining"] = {"Adaptability", "Stamina"},
    ["com.minecolonies.job.composter"] = {"Stamina", "Athletics"},
    ["com.minecolonies.job.concretemixer"] = {"Stamina", "Dexterity"},
    ["com.minecolonies.job.cook"] = {"Adaptability", "Knowledge"},
    ["com.minecolonies.job.cookassistant"] = {"Creativity", "Knowledge"},
    ["com.minecolonies.job.cowboy"] = {"Athletics", "Stamina"},
    ["com.minecolonies.job.crusher"] = {"Stamina", "Strength"},
    ["com.minecolonies.job.deliveryman"] = {"Agility", "Adaptability"},
    ["com.minecolonies.job.druid"] = {"Mana", "Focus"},
    ["com.minecolonies.job.dyer"] = {"Creativity", "Dexterity"},
    ["com.minecolonies.job.enchanter"] = {"Mana", "Knowledge"},
    ["com.minecolonies.job.farmer"] = {"Stamina", "Athletics"},
    ["com.minecolonies.job.fisherman"] = {"Focus", "Agility"},
    ["com.minecolonies.job.fletcher"] = {"Dexterity", "Creativity"},
    ["com.minecolonies.job.florist"] = {"Dexterity", "Agility"},
    ["com.minecolonies.job.glassblower"] = {"Creativity", "Focus"},
    ["com.minecolonies.job.healer"] = {"Mana", "Knowledge"},
    ["com.minecolonies.job.knight"] = {"Adaptability", "Stamina"},
    ["com.minecolonies.job.lumberjack"] = {"Strength", "Focus"},
    ["com.minecolonies.job.mechanic"] = {"Knowledge", "Agility"},
    ["com.minecolonies.job.miner"] = {"Strength", "Stamina"},
    ["com.minecolonies.job.netherworker"] = {"Adaptability", "Strength"},
    ["com.minecolonies.job.planter"] = {"Agility", "Dexterity"},
    ["com.minecolonies.job.pupil"] = {{"Intelligence", "Knowledge"}, "Mana"},
    ["com.minecolonies.job.quarrier"] = {"Strength", "Stamina"},
    ["com.minecolonies.job.rabbitherder"] = {"Agility", "Athletics"},
    ["com.minecolonies.job.ranger"] = {"Agility", "Adaptability"},
    ["com.minecolonies.job.researcher"] = {"Knowledge", "Mana"},
    ["com.minecolonies.job.sawmill"] = {"Knowledge", "Dexterity"},
    ["com.minecolonies.job.shepherd"] = {"Focus", "Strength"},
    ["com.minecolonies.job.sifter"] = {"Focus", "Strength"},
    ["com.minecolonies.job.smelter"] = {"Athletics", "Strength"},
    ["com.minecolonies.job.stonemason"] = {"Creativity", "Dexterity"},
    ["com.minecolonies.job.stonesmeltery"] = {"Athletics", "Dexterity"},
    ["com.minecolonies.job.student"] = {"Intelligence"},
    ["com.minecolonies.job.swineherder"] = {"Strength", "Athletics"},
    ["com.minecolonies.job.teacher"] = {"Knowledge", "Mana"},
    ["com.minecolonies.job.undertaker"] = {"Strength", "Mana"},
}

local JOBS_FOR_BUILDING = {
    ["com.minecolonies.building.alchemist"] = "com.minecolonies.job.alchemist",
    ["com.minecolonies.building.archery"] = "com.minecolonies.job.archertraining", -- * level
    ["com.minecolonies.building.baker"] = "com.minecolonies.job.baker",
    ["com.minecolonies.building.barracks"] = nil,
    ["com.minecolonies.building.barrackstower"] = {"com.minecolonies.job.ranger", "com.minecolonies.job.knight", "com.minecolonies.job.druid"}, -- * level
    ["com.minecolonies.building.beekeeper"] = "com.minecolonies.job.beekeeper",
    ["com.minecolonies.building.blacksmith"] = "com.minecolonies.job.blacksmith",
    ["com.minecolonies.building.builder"] = "com.minecolonies.job.builder",
    ["com.minecolonies.building.chickenherder"] = "com.minecolonies.job.chickenherder",
    --["com.minecolonies.building.combatacademy"] = "com.minecolonies.job.combattraining", -- * level
    ["com.minecolonies.building.composter"] = "com.minecolonies.job.composter",
    ["com.minecolonies.building.concretemixer"] = "com.minecolonies.job.concretemixer",
    --["com.minecolonies.building.cook"] = cook + assistant if level >= 3,
    ["com.minecolonies.building.cowboy"] = "com.minecolonies.job.cowboy",
    ["com.minecolonies.building.crusher"] = "com.minecolonies.job.crusher",
    ["com.minecolonies.building.deliveryman"] = "com.minecolonies.job.deliveryman",
    ["com.minecolonies.building.dyer"] = "com.minecolonies.job.dyer",
    ["com.minecolonies.building.enchanter"] = "com.minecolonies.job.enchanter",
    ["com.minecolonies.building.farmer"] = "com.minecolonies.job.farmer",
    ["com.minecolonies.building.fisherman"] = "com.minecolonies.job.fisherman",
    ["com.minecolonies.building.fletcher"] = "com.minecolonies.job.fletcher",
    ["com.minecolonies.building.florist"] = "com.minecolonies.job.florist",
    ["com.minecolonies.building.glassblower"] = "com.minecolonies.job.glassblower",
    ["com.minecolonies.building.graveyard"] = "com.minecolonies.job.undertaker",
    ["com.minecolonies.building.guardtower"] =  {"com.minecolonies.job.ranger", "com.minecolonies.job.knight", "com.minecolonies.job.druid"},
    ["com.minecolonies.building.hospital"] = "com.minecolonies.job.healer",
    ["com.minecolonies.building.library"] = "com.minecolonies.job.student", -- * 2 * level
    ["com.minecolonies.building.lumberjack"] = "com.minecolonies.job.lumberjack",
    ["com.minecolonies.building.mechanic"] = "com.minecolonies.job.mechanic",
    ["com.minecolonies.building.miner"] = "com.minecolonies.job.miner",
    ["com.minecolonies.building.mysticalsite"] = nil,
    ["com.minecolonies.building.netherworker"] = "com.minecolonies.job.netherworker",
    ["com.minecolonies.building.plantation"] = "com.minecolonies.job.planter",
    ["com.minecolonies.building.rabbithutch"] = "com.minecolonies.job.rabbitherder",
    ["com.minecolonies.building.residence"] = nil,
    ["com.minecolonies.building.sawmill"] = "com.minecolonies.job.sawmill",
    ["com.minecolonies.building.school"] = "com.minecolonies.job.teacher",
    ["com.minecolonies.building.shepherd"] = "com.minecolonies.job.shepherd",
    ["com.minecolonies.building.sifter"] = "com.minecolonies.job.sifter",
    ["com.minecolonies.building.smeltery"] = "com.minecolonies.job.smelter",
    ["com.minecolonies.building.stonemason"] = "com.minecolonies.job.stonemason",
    ["com.minecolonies.building.stonesmeltery"] = "com.minecolonies.job.stonesmeltery",
    ["com.minecolonies.building.swineherder"] = "com.minecolonies.job.swineherder",
    ["com.minecolonies.building.tavern"] = nil,
    ["com.minecolonies.building.townhall"] = nil,
    ["com.minecolonies.building.university"] = "com.minecolonies.job.researcher",
    ["com.minecolonies.building.warehouse"] = nil, -- assign couriers to courier huts
}

local function isAdultJob(job)
    return job ~= "com.minecolonies.job.pupil"
end

local function isFinalJob(job)
    return job ~= "com.minecolonies.job.pupil" and job ~= "com.minecolonies.job.student" and job ~= "com.minecolonies.job.archertraining" and job ~= "com.minecolonies.job.combattraining"
end

local ALL_JOBS = table.keys(JOB_SKILLS)
local ADULT_JOBS = filter(ALL_JOBS, isAdultJob)
local FINAL_JOBS = filter(ALL_JOBS, isFinalJob)

local function scoreForSkill(skills, skill)
    if type(skill) == "table" then
        local score=0
        for i=1,#skill do
            score = score + scoreForSkill(skills, skill[i])
        end
        return score
    else
        return skills[skill].level or 0
    end
end

function scoreForJob(skills, job)
    if type(job) == "table" then
        local scores = map(job, function(j) return scoreForJob(skills, j) end)
        table.sort(scores)
        return scores[#scores]
    end
    local jobSkills = JOB_SKILLS[job] or {}
    if #jobSkills == 0 then
        print("Job has no skills: " .. job)
    end
    local score = 0
    for i=1,#jobSkills do
        score = score + scoreForSkill(skills, jobSkills[i])
    end
    return score
end

function allJobs()
    return table.shallowCopy(ALL_JOBS)
end

-- includes training jobs (student and squires)
function adultJobs()
    return table.shallowCopy(ADULT_JOBS)
end

function finalJobs()
    return table.shallowCopy(FINAL_JOBS)
end

function jobsForBuilding(building, level)
    local jobs = JOBS_FOR_BUILDING[building]
    if building == "com.minecolonies.building.archery" or building == "com.minecolonies.building.barrackstower" or building == "com.minecolonies.building.combatacademy" or building == "com.minecolonies.building.university" then
        -- multiply by level
        return table.rep(jobs, level)
    elseif building == "com.minecolonies.building.library" then
        -- * 2 * level
        return table.rep(jobs, 2 * level)
    elseif building == "com.minecolonies.building.cook" then
        -- assistant cook on level >= 3
        if level < 3 then
            return {"com.minecolonies.job.cook"}
        else
            return {"com.minecolonies.job.cook", "com.minecolonies.job.cookassistant"}
        end
    end

    if type(jobs) == "string" then
        return {jobs}
    else
        return jobs or {}
    end
end

function jobsForBuildings(buildings, includeTraining)
    local jobs = {}
    for i = 1, #buildings do
        local building = buildings[i]
        local buildingJobs = jobsForBuilding(building.name, building.level)
        for j = 1, #buildingJobs do
            local job = buildingJobs[j] -- job (string) or job alternatives (list)
            -- this works because all traning jobs are a single one (string)
            if isFinalJob(job) or includeTraining then
                table.insert(jobs, job)
            end
        end
    end
    return jobs
end

-- sort jobs according to skills
function sortJobs(skills, jobs, minScore, includeScore)
    local sortedJobs = {}
    local scores = {}
    minScore = minScore or 0
    for i,job in ipairs(jobs or ALL_JOBS) do
        local score = scoreForJob(skills, job)
        if score > minScore then
            sortedJobs[1+#sortedJobs] = job
            scores[job] = score
        end
    end
    table.sort(sortedJobs, function(a,b)
        return scores[a] > scores[b]
    end)
    if includeScore then
        return map(sortedJobs, function(job)
            local skill1 = JOB_SKILLS[job][1]
            if type(skill1) == "table" then skill1 = skill1[1] end
            local skill2 = JOB_SKILLS[job][2]
            return {scores[job], job, skills[skill1].level, skills[skill2].level}
        end)
    end
    return sortedJobs
end

-- assign each job to the best suited citizen
local function assignJobsToCitizens(citizens, jobs)
    local availableJobs = table.shallowCopy(jobs)
    local citizensById = {}
    local availableCitizens = {}
    for i = 1, #citizens do
        local citizen = citizens[i]
        citizensById[citizen.id] = citizen
        table.insert(availableCitizens, citizen.id)
    end
    local assignedJobs = {}
    while #availableJobs > 0 do
        local nextJobs = table.remove(availableJobs)
        if type(nextJobs) == "string" then
            nextJobs = {nextJobs}
        end
        -- find best citizen
        local maxScore = 0
        local maxCitizenIndex = nil
        local assJob = nil
        for i = 1, #availableCitizens do
            local citizen = citizensById[availableCitizens[i]]
            for j = 1, #nextJobs do
                local score = scoreForJob(citizen.skills, nextJobs[j])
                if score > maxScore then
                    maxCitizenIndex = i
                    assJob = nextJobs[j]
                end
            end
        end
        assert(maxCitizenIndex ~= nil)
        assignedJobs[availableCitizens[maxCitizenIndex]] = assJob
        table.remove(availableCitizens, maxCitizenIndex)
    end
    return assignedJobs
end

--- assign each citizen to their best job
local function assignCitizensToJobs(citizens, jobs)
    local availableJobs = table.shallowCopy(jobs)
    local availableCitizens = table.shallowCopy(citizens)
    local assignedJobs = {}
    while #availableCitizens > 0 do
        local citizen = table.remove(availableCitizens)
        local sortedJobs = sortJobs(citizen.skills, availableJobs)
        local job = sortedJobs[1]
        if type(job) == "table" then
            sortedJobs = sortJobs(citizen.skills, job)
            job = sortedJobs[1]
        end
        assignedJobs[citizen.id] = job
        table.removeOneValue(availableJobs, job)
    end
    return assignedJobs
end

function assignJobs(citizens, jobs, jobsArePrioritised)
    jobs = jobs or ADULT_JOBS
    local adults = filter(citizens, function(citizen) return citizen.age == "adult" end)
    if #adults > #jobs or jobsArePrioritised then
        return assignJobsToCitizens(adults, jobs)
    else
        return assignCitizensToJobs(adults, jobs)
    end
end

function bestJobs(citizen, jobs, count)
    local sortedJobs = sortJobs(citizen.skills, jobs or FINAL_JOBS, nil, true)
    if #sortedJobs == 0 then
        return {}
    end
    local bestJobScore = sortedJobs[1][1]
    if count == nil then
        -- only job with highest score
        return filter(sortedJobs, function(job)
            return job[1] == bestJobScore
        end)
    else
        return { table.unpack(sortedJobs, 1, count) }
    end
    
end

function hasBestJob(citizen, jobs)
    local job = citizen.work.job
    if citizen.work == nil then
        return false
    end
    if citizen.age == "child" then
        return job == "com.minecolonies.job.pupil"
    end
    local topJobs = jobs or bestJobs(citizen)
    for index, value in ipairs(topJobs) do
        if value[2] == job then
            return true
        end
    end
    return false
end
