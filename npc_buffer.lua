--[[ Eluna NPC Buffer for AzerothCore 3.3.5a. Buff data in buffs_data.lua. ]]

local NPC_ID = 601017

-- NPC assignments for blessing entries. Entries not listed default to "player".
-- "player" means the target casts it themselves (most buffs including prayers).
local BLESSING_CASTERS = {
    blessing_of_might   = 190010,
    blessing_of_wisdom  = 601015,
    blessing_of_sanctuary = 601017,
}

local Config = {
    CureResSickness = true,
    AllowInCombat   = false,
    KeyOrder = {
        "pw_fortitude", "arcane_intellect", "divine_spirit", "shadow_protection",
        "mark_of_the_wild", "blessing_of_might", "blessing_of_wisdom", "blessing_of_kings", "blessing_of_sanctuary", "thorns",
    },
    MaxRows  = 32,
    Debug    = false,
}

local DATA_FILE       = "buffs_data.lua"
local DATA_GLOBAL     = "ElunaBufferBuffs"
local DATA_CANDIDATES = {
    DATA_FILE,
    "lua_scripts/" .. DATA_FILE,
    "./lua_scripts/" .. DATA_FILE,
    "../lua_scripts/" .. DATA_FILE,
    "../../lua_scripts/" .. DATA_FILE,
}

local Buffs = {}
local EntryIndex = {}   -- key -> index into Buffs
local EntryId = {}      -- key -> numeric gossip sender ID
local EntryById = {}    -- numeric gossip sender ID -> key
local EntryName = {}    -- key -> localized spell name
local EntryIcon = {}    -- key -> spell icon path
local bookLoaded = false

local MainMenu

local function GetScriptDir()
    local info = debug.getinfo(1, "S").source
    if info then
        info = info:gsub("^@", "")
        local dir = info:match("^(.*)/[^/]*$")
        if dir then return dir end
    end
    return nil
end

local SCRIPT_DIR = GetScriptDir()

local function LoadBuffBook()
    local published = rawget(_G, DATA_GLOBAL)
    if type(published) == "table" and #published > 0 then
        return published
    end

    local candidates = {}
    if SCRIPT_DIR then
        candidates[#candidates + 1] = SCRIPT_DIR .. "/" .. DATA_FILE
    end
    for _, path in ipairs(DATA_CANDIDATES) do
        candidates[#candidates + 1] = path
    end

    for _, path in ipairs(candidates) do
        local ok, res = pcall(dofile, path)
        if ok and type(res) == "table" and #res > 0 then
            return res
        end
    end
    return nil
end

local NameMemo = {}

local function Safe(fn, ...)
    local ok, value = pcall(fn, ...)
    if ok then return true, value end
    return false, nil
end

local function CachedName(kind, id)
    if type(id) ~= "number" or id <= 0 then return nil end
    local key = kind .. ":" .. id
    local hit = NameMemo[key]
    if hit ~= nil then return hit or nil end
    local ok, info = Safe(function() return GetSpellInfo(id) end)
    local name = nil
    if ok and info then
        local ok2, n = Safe(function() return info:GetName() end)
        if ok2 and type(n) == "string" and n ~= "" then name = n end
    end
    NameMemo[key] = name or false
    return name or nil
end

local function IndexEntries()
    EntryIndex = {}
    EntryId = {}
    EntryById = {}
    EntryName = {}
    EntryIcon = {}
    local nextId = 1
    for i = 1, #Buffs do
        local b = Buffs[i]
        local k = b.key or "misc"
        EntryIndex[k] = i
        EntryId[k] = nextId
        EntryById[nextId] = k
        nextId = nextId + 1
    end

    for _, b in ipairs(Buffs) do
        local k = b.key or "misc"
        if EntryName[k] == nil then
            local sid = b.spells and b.spells[1] and b.spells[1][1] or 0
            EntryName[k] = CachedName("spell", sid) or k
            if type(b.icon) == "string" and b.icon ~= "" then
                EntryIcon[k] = b.icon
            end
        end
    end
end

local function EnsureBook()
    if bookLoaded then return true end
    local book = LoadBuffBook()
    if book then
        Buffs = book
        IndexEntries()
        bookLoaded = true
        return true
    end
    return false
end

EnsureBook()

local Session = {}

local function Sid(player)
    return player:GetGUIDLow()
end

local function GetSession(player)
    local id = Sid(player)
    local sess = Session[id]
    if not sess then
        sess = { view = 1 }
        Session[id] = sess
    end
    return sess
end

local VIEW_MAIN = 1

local ACT = {
    CAST_ALL     = 18,
    CAST_ENTRY   = 20,
    PRINT_ALL    = 30,
}

local function tContains(list, value)
    if type(list) ~= "table" then return false end
    for i = 1, #list do
        if list[i] == value then return true end
    end
    return false
end

local function DiscoverCreaturesByEntry(entry, refPlayer, refCreature)
    local results = {}
    local seenGuids = {}

    local function addCreature(c)
        if not c then return end
        local ok, guid = Safe(function() return c:GetGUIDLow() end)
        if not ok or seenGuids[guid] then return end
        local ok2, e = Safe(function() return c:GetEntry() end)
        if ok2 and e == entry then
            seenGuids[guid] = true
            results[#results + 1] = c
        end
    end

    local function GetPos(obj)
        local ok, x, y, z = Safe(function() return obj:GetPosition() end)
        if ok and x then return x, y, z end
        local ok2, x2 = Safe(function() return obj:GetX() end)
        local ok3, y2 = Safe(function() return obj:GetY() end)
        local ok4, z2 = Safe(function() return obj:GetZ() end)
        if ok2 and ok3 and ok4 then return x2, y2, z2 end
        return nil
    end

    local function TryGetCreaturesInRange(obj)
        if not obj then return 0 end
        local ok, list = Safe(function() return obj:GetCreaturesInRange(100) end)
        if ok and type(list) == "table" then
            for _, c in ipairs(list) do addCreature(c) end
            return #list
        end
        local x, y, z = GetPos(obj)
        if x and type(GetCreaturesInRange) == "function" then
            local ok2, list = Safe(function() return GetCreaturesInRange(x, y, z, 100) end)
            if ok2 and type(list) == "table" then
                for _, c in ipairs(list) do addCreature(c) end
                return #list
            end
        end
        return 0
    end

    TryGetCreaturesInRange(refPlayer)
    TryGetCreaturesInRange(refCreature)

    if type(GetCreatureByEntry) == "function" then
        local ok, c = Safe(function() return GetCreatureByEntry(entry) end)
        if ok and c then addCreature(c) end
    end

    if type(GetCreaturesByEntry) == "function" then
        local ok, list = Safe(function() return GetCreaturesByEntry(entry) end)
        if ok and type(list) == "table" then
            for _, c in ipairs(list) do addCreature(c) end
        end
    end

    return results
end

local CasterCreatures = {}
local EntryCasterIdx = {}

local function GetCasterCreatures(entry, refPlayer, refCreature)
    local cached = CasterCreatures[entry]
    if cached ~= nil then
        local valid = {}
        local anyValid = false
        for _, c in ipairs(cached) do
            local ok, _ = Safe(function() return c:GetGUIDLow() end)
            if ok then
                valid[#valid + 1] = c
                anyValid = true
            end
        end
        if anyValid then
            if #valid < #cached then CasterCreatures[entry] = valid end
            return valid
        end
        CasterCreatures[entry] = nil
    end
    local creatures = DiscoverCreaturesByEntry(entry, refPlayer, refCreature)
    if #creatures > 0 then
        CasterCreatures[entry] = creatures
    end
    return creatures
end

local function GetCaster(key, refPlayer, refCreature)
    local entry = BLESSING_CASTERS[key]
    if entry == nil then entry = "player" end
    if entry == "player" then return nil end

    local creatures = GetCasterCreatures(entry, refPlayer, refCreature)
    if #creatures == 0 then return nil end

    local idx = EntryCasterIdx[key]
    if not idx then
        local used = {}
        for k, i in pairs(EntryCasterIdx) do
            if BLESSING_CASTERS[k] == entry then
                used[i] = true
            end
        end
        idx = 1
        while used[idx] do idx = idx + 1 end
        if idx > #creatures then idx = 1 end
        EntryCasterIdx[key] = idx
    end

    return creatures[idx]
end

local function VerifyCasters(player, creature)
    for key, entry in pairs(BLESSING_CASTERS) do
        if entry ~= "player" then
            GetCaster(key, player, creature)
        end
    end
end

local function TargetMinLevel(spellLevel)
    if not spellLevel or spellLevel <= 0 then return 1 end
    return math.max(1, spellLevel - 10)
end

local function BestSpellId(key, level, playerClass)
    local b = Buffs[EntryIndex[key]]
    if not b then return nil end

    local bestSpell, bestLvl = nil, -1
    if not b.classes or tContains(b.classes, playerClass) then
        for i = 1, #b.spells do
            local sid, spellLevel = b.spells[i][1], b.spells[i][2]
            local tml = TargetMinLevel(spellLevel)
            if tml and tml <= level and tml >= bestLvl then
                bestLvl, bestSpell = tml, sid
            end
        end
    end
    return bestSpell, bestLvl, b
end

local function SpellRankText(entry, spellId)
    if not entry or not entry.spells then return "" end
    for i = 1, #entry.spells do
        if entry.spells[i][1] == spellId then
            return " (rank " .. i .. ")"
        end
    end
    return ""
end

local function EntryMinLevel(key, playerClass)
    local b = Buffs[EntryIndex[key]]
    if not b then return nil end

    local best = nil
    if not b.classes or tContains(b.classes, playerClass) then
        for i = 1, #b.spells do
            local spellLevel = b.spells[i][2]
            local tml = TargetMinLevel(spellLevel)
            if tml and (not best or tml < best) then best = tml end
        end
    end
    return best
end

local function ActiveSpell(player, key)
    local b = Buffs[EntryIndex[key]]
    if not b then return nil end

    local activeSpell, activeLvl = nil, -1
    for i = 1, #b.spells do
        local sid = b.spells[i][1]
        local ok, has = Safe(function() return player:HasAura(sid) end)
        if ok and has then
            local spellLevel = b.spells[i][2]
            local tml = TargetMinLevel(spellLevel)
            if tml and tml > activeLvl then activeLvl, activeSpell = tml, sid end
        end
    end
    return activeSpell, activeLvl
end

local function FindRank(entry, spellId)
    if not entry or not entry.spells then return 0 end
    for i = 1, #entry.spells do
        if entry.spells[i][1] == spellId then return i end
    end
    return 0
end

local function PrintAllBuffs(player)
    local lines = {}
    lines[#lines + 1] = "|cffffff00[Eluna NPC Buffer] Spell dump (" .. #Buffs .. " entries)|r"

    for _, b in ipairs(Buffs) do
        for i = 1, #b.spells do
            local sid, spellLevel = b.spells[i][1], b.spells[i][2]
            local link = CachedName("spell", sid) or ("[" .. tostring(sid) .. "]")
            lines[#lines + 1] = string.format(
                "|cff71d5ff|Hspell:%d|h[%s]|h|r R:%d L:%d",
                sid, link, i, spellLevel
            )
        end
    end

    -- Send line by line to avoid breaking spell links across messages
    local out = {}
    for _, line in ipairs(lines) do
        if #line > 255 then
            for i = 1, #line, 255 do
                out[#out + 1] = line:sub(i, i + 254)
            end
        else
            out[#out + 1] = line
        end
    end
    for _, msg in ipairs(out) do
        player:SendBroadcastMessage(msg)
    end
end

local function ApplyBest(player, creature, key, report, caster)
    local level = player:GetLevel()
    local class = player:GetClass()

    if not Config.AllowInCombat then
        local ok, combat = Safe(function() return player:IsInCombat() end)
        if ok and combat then
            return false
        end
    end

    if Config.CureResSickness then
        local ok, has = Safe(function() return player:HasAura(15007) end)
        if ok and has then
            Safe(function() player:RemoveAura(15007) end)
        end
    end

    local spellId, needLvl, entry = BestSpellId(key, level, class)
    if not spellId then
        return false
    end

    local sname = CachedName("spell", spellId) or (entry and entry.name) or tostring(spellId)
    local casterUnit = caster or player

    local casterGuid = "player"
    if caster then
        local ok2, guid = Safe(function() return caster:GetGUIDLow() end)
        if ok2 then casterGuid = tostring(guid) end
    end

    local ok = Safe(function() return casterUnit:CastSpell(player, spellId, true) end)
    if not ok then
        return false
    end

    return true
end

local function ApplyAll(player, creature)
    local results = {}

    local casters = {}
    for _, key in ipairs(Config.KeyOrder) do
        if EntryIndex[key] then
            casters[key] = GetCaster(key, player, creature)
        end
    end

    for _, key in ipairs(Config.KeyOrder) do
        if EntryIndex[key] then
            local caster = casters[key]
            local ok = ApplyBest(player, creature, key, true, caster)
            results[#results + 1] = { key = key, ok = ok }
        end
    end

    local sess = GetSession(player)
    sess.view = VIEW_MAIN
    MainMenu(player, creature)
    return results
end

local MenuRowCount = 0

local function AddMenu(player, text, sender, action)
    if MenuRowCount >= Config.MaxRows then return false end
    MenuRowCount = MenuRowCount + 1
    player:GossipMenuAddItem(0, text, sender, action)
    return true
end

local function Button(player, text, sender, action)
    if MenuRowCount >= Config.MaxRows then return false end
    MenuRowCount = MenuRowCount + 1
    player:GossipMenuAddItem(0, text, sender, action)
    return true
end

local function Message(player, text)
    if MenuRowCount >= Config.MaxRows then return false end
    MenuRowCount = MenuRowCount + 1
    return AddMenu(player, text, 0, 0)
end

local function EntryRowText(player, key)
    local level, class = player:GetLevel(), player:GetClass()
    local label = EntryName[key] or key
    local icon = EntryIcon[key]
    local iconTxt = icon and ("|TInterface/Icons/" .. icon .. ":22:22:-18:0|t ") or ""
    local spellId, needLvl, entry = BestSpellId(key, level, class)
    local active, activeLvl = ActiveSpell(player, key)

    if active then
        local rank = FindRank(entry, active)
        if rank > 0 then
            return iconTxt .. label .. " |cff00ff00(Rank " .. rank .. ")|r", true
        end
        return iconTxt .. label .. " |cff00ff00(active)|r", true
    end

    if spellId then
        return iconTxt .. label .. " |cffff0000(Inactive)|r", true
    end

    return iconTxt .. label .. " |cffff0000(Inactive)|r", false
end

MainMenu = function(player, creature)
    player:GossipClearMenu()
    MenuRowCount = 0
    local sess = GetSession(player)
    sess.view = VIEW_MAIN

    Button(player, "|cff00ff00Buff All|r", 0, ACT.CAST_ALL)

    if Config.Debug then
        Button(player, "|cffff7f00Print All|r", 0, ACT.PRINT_ALL)
    end

    for _, key in ipairs(Config.KeyOrder) do
        if EntryIndex[key] then
            local text, castable = EntryRowText(player, key)
            if castable then
                AddMenu(player, text, EntryId[key], ACT.CAST_ENTRY)
            end
        end
    end

    player:GossipSendMenu(NPC_ID, creature)
end

local function Guard(label, fn)
    return function(event, player, creature, ...)
        local ok, err = pcall(fn, event, player, creature, ...)
        if not ok then
            print("[Eluna NPC Buffer] " .. label .. " error: " .. tostring(err))
            if player then
                player:SendBroadcastMessage(
                    "The buffer hit a snag - the error is in the worldserver console.")
                pcall(function() player:GossipComplete() end)
            end
        end
    end
end

local BOOK_MISSING = "[Eluna NPC Buffer] Buff book not found. Put buffs_data.lua "
    .. "in the same folder as npc_buffer.lua."

local function OnHello(event, player, creature)
    if not EnsureBook() then
        print(BOOK_MISSING)
        player:SendBroadcastMessage("The buffer cannot find his buff book.")
        player:GossipComplete()
        return
    end
    local sess = GetSession(player)
    VerifyCasters(player, creature)
    MainMenu(player, creature)
end

local function OnSelect(event, player, creature, sender, intid, code)
    if not EnsureBook() then
        print(BOOK_MISSING)
        player:GossipComplete()
        return
    end

    if intid == ACT.CAST_ALL then
        ApplyAll(player, creature)
        return
    end

    if intid == ACT.CAST_ENTRY then
        local key = EntryById[sender]
        if key then
            local caster = GetCaster(key, player, creature)
            ApplyBest(player, creature, key, true, caster)
        end
        MainMenu(player, creature)
        return
    end

    if intid == ACT.PRINT_ALL then
        PrintAllBuffs(player)
        MainMenu(player, creature)
        return
    end

    MainMenu(player, creature)
end

local function OnLogout(event, player)
    Session[Sid(player)] = nil
end

RegisterCreatureGossipEvent(NPC_ID, 1, Guard("hello", OnHello))
RegisterCreatureGossipEvent(NPC_ID, 2, Guard("select", OnSelect))
RegisterPlayerEvent(4, OnLogout)

if bookLoaded then
    print("[Eluna NPC Buffer] NPC " .. NPC_ID .. " loaded with "
        .. tostring(#Buffs) .. " entries from " .. DATA_FILE .. ".")
else
    print("[Eluna NPC Buffer] NPC " .. NPC_ID .. " loaded, but " .. DATA_FILE
        .. " was not found yet - it will be picked up on the first gossip.")
end
