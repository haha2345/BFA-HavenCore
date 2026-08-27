local ADDON, HL = ...
HavenLab = HL

HL.version = "2.0.3"
HL.logs = {}
HL.stats = {}
HL.historyIndex = 0
HL.playerGUID = nil
HL.manualUntil = {}

BINDING_HEADER_HAVENLAB = "HavenLab 调试台"
BINDING_NAME_HAVENLAB_TOGGLE = "打开/关闭调试台"
BINDING_NAME_HAVENLAB_CMD = "聚焦命令栏"

local MAX_LOG = 400
local MAX_HISTORY = 80

local DEFAULTS = {
    history = {},
    watch = { 317257, 317260, 317262, 317265, 324889, 318274 },
    pack = "stars",
    filter = "test",
    uiVersion = 3,
    showTicker = true,
    showCmdBar = true,
    showMinimap = true,
    showSpeed = false,
    overview = {},
}

local SCHOOLS = {
    { 1, "物理" }, { 2, "神圣" }, { 4, "火焰" }, { 8, "自然" },
    { 16, "冰霜" }, { 32, "暗影" }, { 64, "奥术" },
}

local EVENT_CN = {
    SPELL_DAMAGE = "伤害",
    SPELL_PERIODIC_DAMAGE = "周期伤",
    SPELL_HEAL = "治疗",
    SPELL_CAST_SUCCESS = "施法成功",
    SPELL_CAST_START = "起手",
    SPELL_CAST_FAILED = "施法失败",
    SPELL_MISSED = "未命中",
    SPELL_AURA_APPLIED = "上光环",
    SPELL_AURA_APPLIED_DOSE = "叠层",
    SPELL_AURA_REMOVED = "掉光环",
    SPELL_AURA_REMOVED_DOSE = "掉层",
    SPELL_AURA_REFRESH = "刷新",
    SPELL_SUMMON = "召唤",
    SPELL_INTERRUPT = "打断",
    SPELL_ENERGIZE = "能量",
    SWING_DAMAGE = "普攻",
    SWING_MISSED = "普攻空",
    RANGE_DAMAGE = "远程伤",
    UNIT_DIED = "死亡",
    CLIENT_CAST = "客户端施法",
    SYSTEM = "系统",
    LAB = "LAB",
}

function HL:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff7ec8e3HavenLab:|r " .. tostring(msg))
end

local function CopyDefaults(src)
    local t = {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            local inner = {}
            for i, x in ipairs(v) do inner[i] = x end
            t[k] = inner
        else
            t[k] = v
        end
    end
    return t
end

function HL:InitDB()
    if type(HavenLabDB) ~= "table" then
        HavenLabDB = CopyDefaults(DEFAULTS)
    end
    self.db = HavenLabDB
    for k, v in pairs(DEFAULTS) do
        if self.db[k] == nil then
            if type(v) == "table" then
                self.db[k] = CopyDefaults({ tmp = v }).tmp
            else
                self.db[k] = v
            end
        end
    end
    if not self.db.watch or #self.db.watch == 0 then
        self.db.watch = { 317257, 317260, 317262, 317265, 324889, 318274 }
    end
    if type(self.db.overview) ~= "table" then
        self.db.overview = {}
    end
    if (self.db.uiVersion or 0) < 3 then
        self.db.filter = "test"
        self.db.uiVersion = 3
    end
end

function HL:WatchSet()
    local set = {}
    for _, id in ipairs(self.db.watch) do set[id] = true end
    return set
end

function HL:IsWatched(id)
    if not id or id == 0 then return false end
    for _, w in ipairs(self.db.watch) do
        if w == id then return true end
    end
    return false
end

function HL:AddWatch(id)
    id = tonumber(id)
    if not id or id < 1 then return end
    if self:IsWatched(id) then return end
    self.db.watch[#self.db.watch + 1] = id
    self:UI("watch")
end

function HL:RemoveWatch(id)
    id = tonumber(id)
    if not id then return end
    local out = {}
    for _, w in ipairs(self.db.watch) do
        if w ~= id then out[#out + 1] = w end
    end
    self.db.watch = out
    self:UI("watch")
end

function HL:LoadPack(key)
    local pack = self.PACKS and self.PACKS[key]
    if not pack then return end
    self.db.pack = key
    local ids = {}
    for i, id in ipairs(pack.ids) do ids[i] = id end
    self.db.watch = ids
    self:UI("pack")
    self:UI("watch")
    self:UI("chain")
    self:Print("监视包：" .. pack.title)
end

function HL:CurrentPack()
    return self.PACKS and self.PACKS[self.db.pack or "stars"]
end

function HL:VisiblePacks()
    local list = {}
    for _, pack in pairs(self.PACKS or {}) do
        if not pack.hidden then
            list[#list + 1] = pack
        end
    end
    table.sort(list, function(a, b)
        local ao, bo = a.order or 99, b.order or 99
        if ao ~= bo then return ao < bo end
        return (a.key or "") < (b.key or "")
    end)
    return list
end

function HL:SpellName(id)
    if not id or id == 0 then return "普攻" end
    local name = GetSpellInfo(id)
    if name and name ~= "" then return name end
    local pack = self:CurrentPack()
    if pack and pack.labels and pack.labels[id] then return pack.labels[id] end
    return "未知"
end

function HL:LabelOf(id)
    local pack = self:CurrentPack()
    if pack and pack.labels and pack.labels[id] then
        return pack.labels[id]
    end
    return self:SpellName(id)
end

function HL:SchoolName(mask)
    mask = tonumber(mask) or 0
    if mask == 0 then return "-" end
    local names = {}
    for i = 1, #SCHOOLS do
        if bit.band(mask, SCHOOLS[i][1]) ~= 0 then
            names[#names + 1] = SCHOOLS[i][2]
        end
    end
    if #names == 0 then return tostring(mask) end
    return table.concat(names, "+")
end

function HL:EventName(ev)
    return EVENT_CN[ev] or ev
end

function HL:ShortUnit(name, guid)
    if guid and self.playerGUID and guid == self.playerGUID then
        return "你"
    end
    if name and name ~= "" then return name end
    if guid and guid ~= "" then
        local entry = guid:match("Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)")
        if entry then return "Creature:" .. entry end
        return guid:sub(1, 18)
    end
    return "?"
end

function HL:Remember(text)
    if not text or text == "" then return end
    local hist = self.db.history
    if hist[#hist] == text then
        self.historyIndex = #hist + 1
        return
    end
    hist[#hist + 1] = text
    while #hist > MAX_HISTORY do table.remove(hist, 1) end
    self.historyIndex = #hist + 1
    self:UI("history")
end

function HL:HistoryPrev()
    local hist = self.db.history
    if #hist == 0 then return "" end
    self.historyIndex = math.max(1, (self.historyIndex or (#hist + 1)) - 1)
    return hist[self.historyIndex] or ""
end

function HL:HistoryNext()
    local hist = self.db.history
    if #hist == 0 then return "" end
    self.historyIndex = math.min(#hist + 1, (self.historyIndex or (#hist + 1)) + 1)
    if self.historyIndex > #hist then return "" end
    return hist[self.historyIndex] or ""
end

function HL:MarkManual(text)
    local id = tonumber(text:match("cast%s+(%d+)") or text:match("aura%s+(%d+)"))
    if not id then return end
    self.manualUntil[id] = time() + 3
end

function HL:IsManual(spellId)
    if not spellId then return false end
    local untilT = self.manualUntil[spellId]
    return untilT and time() <= untilT
end

function HL:Send(text)
    text = strtrim(text or "")
    if text == "" then return end
    self:Remember(text)
    self:MarkManual(text)
    if text:sub(1, 1) == "/" then
        local eb = DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox
        if eb then
            eb:SetText(text)
            ChatEdit_SendText(eb, 0)
        end
    else
        SendChatMessage(text, "SAY")
    end
    self:PushLog({
        t = time(),
        ev = "SYSTEM",
        text = "> " .. text,
        mine = true,
    })
end

function HL:StartPackTest(key)
    key = key or (self.db and self.db.pack) or "stars"
    local pack = self.PACKS and self.PACKS[key]
    if not pack then
        self:Print("没有测试包 " .. tostring(key))
        return
    end
    self:LoadPack(key)
    self:ClearLog()
    wipe(self.manualUntil)
    self.db.filter = "test"
    self:UI("filters")
    self.packBaseline = nil
    if pack.snapshotOnStart and self.StatSnapshot then
        self.packBaseline = self:StatSnapshot()
    end
    if pack.serverCmd then
        self:Send(pack.serverCmd)
    end
    self:PushLog({
        t = time(),
        ev = "SYSTEM",
        text = pack.startText or ("【测试开始】" .. pack.title),
        mine = true,
    })
    if pack.startPrint then
        self:Print(pack.startPrint)
    end
end

function HL:StartStarsTest()
    self:StartPackTest("stars")
end

function HL:StartTwilightTest()
    self:StartPackTest("twilight")
end

function HL:StartEchoTest()
    self:StartPackTest("echo")
end

function HL:StartTentacleTest()
    self:StartPackTest("tentacle")
end

function HL:StartRitualTest()
    self:StartPackTest("ritual")
end

function HL:SendMany(cmds, gap)
    gap = gap or 0.12
    for i, cmd in ipairs(cmds) do
        if i == 1 then
            self:Send(cmd)
        else
            local c = cmd
            C_Timer.After(gap * (i - 1), function() HL:Send(c) end)
        end
    end
end

function HL:GiveTestGear()
    self:Send(".labgear")
    self:Print("已发 .labgear。会先清掉旧测试装再穿一套（不会叠两件）。若提示 unknown command，先重启 worldserver。")
end

function HL:Stat(id)
    local s = self.stats[id]
    if not s then
        s = {
            casts = 0, damageN = 0, damageSum = 0, damageMax = 0, school = "-",
            stacks = 0, auraSelf = 0, auraTarget = 0, last = "-",
            autoDmg = 0, manDmg = 0, autoAura = 0, manAura = 0, autoCast = 0, manCast = 0,
            perTarget = {},
        }
        self.stats[id] = s
    end
    return s
end

function HL:ResetStats()
    wipe(self.stats)
    if self.ResetTrack then
        self:ResetTrack()
    end
    self:UI("chain")
end

function HL:NoteStats(rec)
    rec.manual = rec.spellId and rec.spellId > 0 and self:IsManual(rec.spellId) or false
    if self.NotePerTarget then
        self:NotePerTarget(rec)
    end
    if self.NoteProcForRec then
        self:NoteProcForRec(rec)
    end
    if self.NoteAuraSnapshot then
        self:NoteAuraSnapshot(rec)
    end
    local id = rec.spellId
    if not id or id == 0 or not self:IsWatched(id) then
        self:UI("chain")
        return
    end
    local s = self:Stat(id)
    if rec.isCast then
        s.casts = s.casts + 1
        if rec.manual then s.manCast = (s.manCast or 0) + 1 else s.autoCast = (s.autoCast or 0) + 1 end
        s.last = rec.manual and "手动施法" or "施法"
    end
    if rec.isDamage and rec.amount then
        s.damageN = s.damageN + 1
        s.damageSum = s.damageSum + rec.amount
        if rec.amount > s.damageMax then s.damageMax = rec.amount end
        if rec.school then s.school = self:SchoolName(rec.school) end
        if rec.manual then s.manDmg = (s.manDmg or 0) + 1 else s.autoDmg = (s.autoDmg or 0) + 1 end
        s.last = (rec.manual and "手动伤害 " or "平砍伤害 ") .. rec.amount
    end
    if rec.isAura then
        if rec.stacks then s.stacks = rec.stacks end
        if rec.ev and rec.ev:find("REMOVED", 1, true) then
            -- keep counts
        else
            if rec.dGUID == self.playerGUID then s.auraSelf = s.auraSelf + 1 end
            if rec.dGUID and rec.dGUID ~= self.playerGUID then
                s.auraTarget = s.auraTarget + 1
                if rec.manual then s.manAura = (s.manAura or 0) + 1 else s.autoAura = (s.autoAura or 0) + 1 end
            end
        end
        s.last = rec.ev == "SPELL_AURA_APPLIED_DOSE" and ("叠到" .. tostring(rec.stacks or "?")) or self:EventName(rec.ev)
    end
    self:UI("chain")
end

function HL:ShouldShow(rec)
    if rec.ev == "SYSTEM" or rec.ev == "LAB" then return true end
    if not self.db then return rec.mine == true end
    local f = self.db.filter or "test"
    local watched = rec.spellId and self:IsWatched(rec.spellId)
    if f == "test" then
        return watched == true or (rec.isDamage == true and rec.mine == true)
    elseif f == "watch" then
        return watched == true
    elseif f == "damage" then
        return rec.isDamage == true and rec.mine == true
    elseif f == "aura" then
        return rec.isAura == true and (rec.mine or watched)
    elseif f == "cast" then
        return rec.isCast == true and (rec.mine or watched)
    end
    return rec.mine == true or watched == true
end

function HL:PushLog(rec)
    if not rec then return end
    if rec.ev ~= "SYSTEM" and rec.ev ~= "LAB" and not rec.mine and not (rec.spellId and self:IsWatched(rec.spellId)) then
        return
    end
    rec.plain = rec.plain or self:FormatPlain(rec)
    rec.rich = rec.rich or self:FormatRich(rec)
    self.logs[#self.logs + 1] = rec
    while #self.logs > MAX_LOG do table.remove(self.logs, 1) end
    if self:ShouldShow(rec) then
        self:UI("log", rec)
        self:UI("ticker", rec)
    end
end

function HL:TimeStr(ts)
    ts = ts or time()
    local d = date("*t", math.floor(ts))
    local frac = math.floor((ts - math.floor(ts)) * 100)
    if not d then return "??:??:??" end
    return string.format("%02d:%02d:%02d.%02d", d.hour, d.min, d.sec, frac)
end

function HL:FormatPlain(rec)
    if rec.text then
        return self:TimeStr(rec.t) .. "  " .. rec.text
    end
    local src = rec.hide and "(隐藏)" or self:ShortUnit(rec.sName, rec.sGUID)
    local dst = self:ShortUnit(rec.dName, rec.dGUID)
    local id = rec.spellId
    local extra = {}
    if rec.amount then extra[#extra + 1] = tostring(rec.amount) end
    if rec.school then extra[#extra + 1] = self:SchoolName(rec.school) end
    if rec.critical then extra[#extra + 1] = "暴击" end
    if rec.miss then extra[#extra + 1] = tostring(rec.miss) end
    if rec.stacks then extra[#extra + 1] = "层" .. rec.stacks end
    if rec.absorbed and rec.absorbed > 0 then extra[#extra + 1] = "吸收" .. rec.absorbed end
    if rec.fail then extra[#extra + 1] = tostring(rec.fail) end
    return string.format("%s  %s  %s -> %s  id=%s %s  %s",
        self:TimeStr(rec.t),
        self:EventName(rec.ev),
        src, dst,
        id and tostring(id) or "-",
        rec.spellName or self:SpellName(id),
        table.concat(extra, " "))
end

function HL:FormatRich(rec)
    if rec.text then
        local col = rec.ev == "LAB" and "ffffd100" or "ffaaaaaa"
        return "|cff8fb8e8" .. self:TimeStr(rec.t) .. "|r  |c" .. col .. rec.text .. "|r"
    end
    local ev = rec.ev
    local evCol = "ffcccccc"
    if rec.isDamage then evCol = rec.miss and "ff888888" or "ffff6b6b" end
    if rec.isAura then evCol = "ff7dff7d" end
    if rec.isCast then evCol = "ffffd27a" end
    if ev == "UNIT_DIED" then evCol = "ffff4444" end
    local src = rec.hide and "|cff888888(隐藏)|r" or self:ShortUnit(rec.sName, rec.sGUID)
    local dst = self:ShortUnit(rec.dName, rec.dGUID)
    local idPart = "-"
    if rec.spellId and rec.spellId > 0 then
        local idCol = self:IsWatched(rec.spellId) and "ffffd100" or "ffc0c0c0"
        idPart = string.format("|Hspell:%d|h|c%s[%d]|r|h", rec.spellId, idCol, rec.spellId)
        if self:IsWatched(rec.spellId) then
            idPart = "|cffffd100★|r" .. idPart
        end
    end
    local extra = {}
    if rec.amount then extra[#extra + 1] = "|cffffffff" .. rec.amount .. "|r" end
    if rec.school then extra[#extra + 1] = self:SchoolName(rec.school) end
    if rec.critical then extra[#extra + 1] = "|cffff8040暴击|r" end
    if rec.miss then extra[#extra + 1] = "|cffaaaaaa" .. tostring(rec.miss) .. "|r" end
    if rec.stacks then extra[#extra + 1] = "层" .. rec.stacks end
    if rec.absorbed and rec.absorbed > 0 then extra[#extra + 1] = "吸收" .. rec.absorbed end
    if rec.fail then extra[#extra + 1] = "|cffff6666" .. tostring(rec.fail) .. "|r" end
    return string.format("|cff888888%s|r  |c%s%s|r  %s -> %s  %s %s  %s",
        self:TimeStr(rec.t),
        evCol, self:EventName(ev),
        src, dst,
        idPart,
        rec.spellName or self:SpellName(rec.spellId),
        table.concat(extra, " "))
end

function HL:ClearLog()
    wipe(self.logs)
    self:ResetStats()
    self:UI("rebuild")
end

function HL:CollectAuras(unit)
    local list = {}
    if type(UnitAura) ~= "function" then
        return list
    end
    local filters = { "HELPFUL", "HARMFUL" }
    for fi = 1, #filters do
        local filter = filters[fi]
        for i = 1, 40 do
            local name, _, count, _, duration, expiration, source, _, _, spellId = UnitAura(unit, i, filter)
            if not name then break end
            list[#list + 1] = {
                name = name,
                count = count or 0,
                duration = duration or 0,
                expiration = expiration or 0,
                source = source,
                spellId = spellId or 0,
                filter = filter,
                watched = self:IsWatched(spellId),
            }
        end
    end
    table.sort(list, function(a, b)
        if a.watched ~= b.watched then return a.watched end
        return (a.spellId or 0) < (b.spellId or 0)
    end)
    return list
end

function HL:FindAura(unit, spellId)
    if type(UnitAura) ~= "function" then
        return
    end
    local filters = { "HELPFUL", "HARMFUL" }
    for fi = 1, #filters do
        for i = 1, 40 do
            local name, _, count, _, duration, expiration, source, _, _, id = UnitAura(unit, i, filters[fi])
            if not name then break end
            if id == spellId then
                return name, count or 0, duration, expiration, source, filters[fi]
            end
        end
    end
end

function HL:OnCLEU(...)
    local timestamp, subevent, hideCaster, sourceGUID, sourceName, _, _, destGUID, destName = ...
    if not subevent then return end
    local rec = {
        t = timestamp,
        ev = subevent,
        hide = hideCaster and true or false,
        sGUID = sourceGUID,
        sName = sourceName,
        dGUID = destGUID,
        dName = destName,
        mine = (sourceGUID == self.playerGUID) or (destGUID == self.playerGUID),
    }
    local p1, p2, p3, p4, p5, p6, p7, p8, p9, p10 = select(12, ...)

    if subevent:sub(1, 6) == "SPELL_" or subevent:sub(1, 6) == "RANGE_" or subevent == "DAMAGE_SHIELD" then
        rec.spellId = p1
        rec.spellName = p2
        rec.spellSchool = p3
        if subevent:find("_DAMAGE", 1, true) then
            rec.isDamage = true
            rec.amount = p4
            rec.overkill = p5
            rec.school = p6
            rec.absorbed = p9
            rec.critical = p10 and true or false
        elseif subevent:find("_MISSED", 1, true) then
            rec.isDamage = true
            rec.miss = p4
            rec.amount = p6
        elseif subevent:find("_HEAL", 1, true) then
            rec.isHeal = true
            rec.amount = p4
            rec.critical = p7 and true or false
        elseif subevent:find("AURA_APPLIED_DOSE", 1, true) or subevent:find("AURA_REMOVED_DOSE", 1, true) then
            rec.isAura = true
            rec.stacks = p5
        elseif subevent:find("AURA_", 1, true) then
            rec.isAura = true
            if p5 then rec.stacks = p5 end
        elseif subevent:find("CAST_", 1, true) then
            rec.isCast = true
            rec.fail = p4
        elseif subevent:find("_SUMMON", 1, true) then
            rec.isCast = true
        else
            if not rec.spellId or rec.spellId == 0 then return end
        end
    elseif subevent == "SWING_DAMAGE" then
        rec.spellId = 0
        rec.spellName = "普攻"
        rec.isDamage = true
        rec.amount = p1
        rec.school = p3
        rec.critical = p7 and true or false
    elseif subevent == "SWING_MISSED" then
        rec.spellId = 0
        rec.spellName = "普攻"
        rec.isDamage = true
        rec.miss = p1
    elseif subevent == "UNIT_DIED" then
        -- dest only
    else
        return
    end

    if self.OnTrackCLEU then
        self:OnTrackCLEU(rec)
    end
    self:NoteStats(rec)
    self:PushLog(rec)
end

function HL:OnClientCast(unit, spellId)
    if unit ~= "player" then return end
    spellId = tonumber(spellId)
    if not spellId then return end
    if not self:IsWatched(spellId) then return end
    local rec = {
        t = time(),
        ev = "CLIENT_CAST",
        isCast = true,
        spellId = spellId,
        spellName = self:SpellName(spellId),
        sGUID = self.playerGUID,
        sName = UnitName("player"),
        dGUID = UnitGUID("target"),
        dName = UnitName("target"),
        mine = true,
    }
    self:NoteStats(rec)
    self:PushLog(rec)
end

function HL:OnLabSystemMessage(message)
    if not self.ParseLabMessage then
        return false
    end
    local labType, kv = self:ParseLabMessage(message)
    if not labType then
        return false
    end
    self:AddLabMessage(labType, kv, time())
    local rec = {
        t = time(),
        ev = "LAB",
        labType = labType,
        kv = kv,
        text = message,
        mine = true,
        spellId = kv and kv.spell or nil,
    }
    self:PushLog(rec)
    local pack = self:CurrentPack()
    if pack and pack.snapshotOnLab == labType and self.StatSnapshot then
        local after = self:StatSnapshot()
        local sid = pack.snapshotSpell
        if sid then
            local s = self:Stat(sid)
            local before = self.packBaseline or self.lastSnapshot
            if before then
                s.statDelta = self:DiffSnapshots(before, after)
                s.statBefore = before
                s.statAfter = after
            end
            if kv then
                s.ritualStacks = kv.stacks
                s.ritualRating = kv.rating
            end
            self:UI("statsnap")
        end
    end
    self:UI("chain")
    return true
end

function HL:UI(name, a, b)
    local fn = self.ui and self.ui[name]
    if fn then fn(a, b) end
end

function HL:Toggle()
    self:UI("toggle")
end

function HL:FocusCommand()
    self:UI("focus")
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
events:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
events:RegisterEvent("UNIT_AURA")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name ~= ADDON then return end
        HL:InitDB()
        HL:UI("build")
        if HL.db.showSpeed and HL.SetSpeedWatch then
            HL:SetSpeedWatch(true)
        end
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        HL.playerGUID = UnitGUID("player")
        if HL.StatSnapshot then HL:StatSnapshot() end
        if HL.NoteCorruptionChange then HL:NoteCorruptionChange() end
        HL:UI("auras")
        HL:UI("chain")
        HL:UI("corr")
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        HL:OnCLEU(CombatLogGetCurrentEventInfo())
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellId = ...
        HL:OnClientCast(unit, spellId)
    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" or unit == "target" then
            HL:UI("auras")
            HL:UI("chain")
            if unit == "player" and HL.NoteCorruptionChange then
                HL:NoteCorruptionChange()
            end
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        HL:UI("auras")
        HL:UI("chain")
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        HL:UI("chain")
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        local slot = ...
        if HL.OnEquipmentChanged then
            HL:OnEquipmentChanged(slot)
        end
    end
end)

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(_, _, message)
    if HL and HL.OnLabSystemMessage and HL:OnLabSystemMessage(message) then
        return false
    end
    if HL and HL.PushLog then
        HL:PushLog({ t = time(), ev = "SYSTEM", text = message, mine = true })
    end
    return false
end)

SLASH_HAVENLAB1 = "/lab"
SLASH_HAVENLAB2 = "/havenlab"
SlashCmdList.HAVENLAB = function(msg)
    msg = strtrim(msg or "")
    if msg == "" or msg == "toggle" then
        HL:Toggle()
        return
    end
    local cmd, rest = msg:match("^(%S+)%s*(.*)$")
    cmd = strlower(cmd or "")
    if cmd == "cmd" then
        HL:FocusCommand()
    elseif cmd == "start" then
        HL:StartPackTest(rest ~= "" and rest or nil)
    elseif cmd == "watch" then
        local id = tonumber(rest)
        if id then HL:AddWatch(id); HL:Print("监视 " .. id) else HL:Print("用法: /lab watch 317265") end
    elseif cmd == "unwatch" then
        local id = tonumber(rest)
        if id then HL:RemoveWatch(id) else HL:Print("用法: /lab unwatch 317265") end
    elseif cmd == "clear" then
        HL:ClearLog()
    elseif cmd == "report" then
        HL:UI("copy")
    elseif cmd == "stars" or cmd == "twilight" or cmd == "echo" or cmd == "tentacle" or cmd == "ritual" then
        HL:StartPackTest(cmd)
    elseif cmd == "corr" then
        local a, b = rest:match("(%S+)%s*(%S*)")
        HL.db.manualCorruption = tonumber(a)
        HL.db.manualResist = tonumber(b) or 0
        if HL.NoteCorruptionChange then HL:NoteCorruptionChange() end
        HL:Print("手输腐蚀 " .. tostring(HL.db.manualCorruption) .. " 抵抗 " .. tostring(HL.db.manualResist))
    elseif cmd == "help" then
        HL:Print("/lab 打开  /lab start [stars|twilight|echo|tentacle|ritual]  /lab watch <id>  /lab report  /lab corr <值>")
    else
        HL:Send(msg)
    end
end
