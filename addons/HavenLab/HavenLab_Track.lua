local _, HL = ...

local MAX_PROC = 200
local SUMMON_EXPIRE = 60

HL.labMsgs = HL.labMsgs or {}
HL.procTimes = HL.procTimes or {}
HL.summons = HL.summons or {}
HL.equipLog = HL.equipLog or {}
HL.snapshots = HL.snapshots or {}
HL.speedLog = HL.speedLog or {}

local SPECIAL_EXPECT = {
    school = true, pctOfMaxHp = true, tolerance = true,
    maxTargets = true, halfFrom = true,
    minCount = true, dealsDamage = true, summonEntries = true,
    stat = true, minDelta = true,
    minGapMs = true, approxPpm = true,
    trimMs = true,
}

function HL:IsSpecialExpect(key)
    return SPECIAL_EXPECT[key] == true
end

function HL:ResetTrack()
    wipe(self.labMsgs)
    wipe(self.procTimes)
    wipe(self.summons)
    wipe(self.equipLog)
    self.lastSnapshot = nil
    self.pendingAuraSnap = nil
    self.lastCorruption = nil
    self.speedState = nil
end

function HL:ParseLabMessage(message)
    if type(message) ~= "string" then
        return nil
    end
    local labType, rest = message:match("^%[HavenLab%] (%S+)%s*(.*)$")
    if not labType then
        return nil
    end
    local kv = {}
    for k, v in string.gmatch(rest or "", "(%S+)=(%S+)") do
        local n = tonumber(v)
        kv[k] = n or v
    end
    return labType, kv
end

function HL:AddLabMessage(labType, kv, t)
    if not labType then
        return
    end
    local list = self.labMsgs[labType]
    if not list then
        list = {}
        self.labMsgs[labType] = list
    end
    list[#list + 1] = { t = t or time(), kv = kv or {} }
    self:NoteProcForLab(labType, t or time())
end

function HL:LabMessages(labType)
    return self.labMsgs[labType] or {}
end

function HL:AddProcTime(packKey, t)
    if not packKey then
        return
    end
    local list = self.procTimes[packKey]
    if not list then
        list = {}
        self.procTimes[packKey] = list
    end
    list[#list + 1] = t or time()
    while #list > MAX_PROC do
        table.remove(list, 1)
    end
end

function HL:NoteProcForLab(labType, t)
    local pack = self.CurrentPack and self:CurrentPack()
    if not pack or not pack.chain then
        return
    end
    for i = 1, #pack.chain do
        local step = pack.chain[i]
        if step.procStep and step.want == "labmsg" and step.labType == labType then
            self:AddProcTime(pack.key, t)
        end
    end
end

function HL:NoteProcForRec(rec)
    local pack = self.CurrentPack and self:CurrentPack()
    if not pack or not pack.chain or not rec then
        return
    end
    for i = 1, #pack.chain do
        local step = pack.chain[i]
        if step.procStep and rec.spellId == step.id then
            local hit = false
            if step.want == "damage" or step.want == "damage-aura" then
                hit = rec.isDamage == true and rec.amount
            elseif step.want == "cast" then
                hit = rec.isCast == true
            elseif step.want == "aura-self" or step.want == "aura-target" or step.want == "stat" then
                hit = rec.isAura == true and rec.ev == "SPELL_AURA_APPLIED"
            end
            if hit then
                self:AddProcTime(pack.key, rec.t)
            end
        end
    end
end

function HL:ProcStats(packKey)
    local list = self.procTimes[packKey or (self.db and self.db.pack)] or {}
    local n = #list
    if n == 0 then
        return { n = 0 }
    end
    local first, last = list[1], list[n]
    local span = math.max(0, last - first)
    local minGap, sumGap = nil, 0
    for i = 2, n do
        local gap = list[i] - list[i - 1]
        sumGap = sumGap + gap
        if not minGap or gap < minGap then
            minGap = gap
        end
    end
    local ppm = 0
    if span > 0 then
        ppm = n / (span / 60)
    end
    return {
        n = n,
        span = span,
        ppm = ppm,
        minGap = minGap,
        avgGap = n > 1 and (sumGap / (n - 1)) or nil,
        sampleLow = n < 3 or span < 20,
    }
end

function HL:NotePerTarget(rec)
    if not rec or not rec.isDamage or not rec.spellId or rec.spellId == 0 then
        return
    end
    if not rec.amount or not rec.dGUID then
        return
    end
    if not self:IsWatched(rec.spellId) then
        return
    end
    local s = self:Stat(rec.spellId)
    s.perTarget = s.perTarget or {}
    local pt = s.perTarget[rec.dGUID]
    if not pt then
        pt = { name = rec.dName, guid = rec.dGUID, hits = 0, sum = 0, max = 0, firstT = rec.t }
        s.perTarget[rec.dGUID] = pt
    end
    pt.hits = pt.hits + 1
    pt.sum = pt.sum + rec.amount
    if rec.amount > pt.max then
        pt.max = rec.amount
    end
    if type(UnitHealthMax) == "function" then
        s.playerMaxHp = UnitHealthMax("player") or s.playerMaxHp
    end
end

function HL:SortedPerTarget(spellId)
    local s = self.stats[spellId]
    if not s or not s.perTarget then
        return {}
    end
    local list = {}
    for _, pt in pairs(s.perTarget) do
        list[#list + 1] = pt
    end
    table.sort(list, function(a, b)
        return (a.firstT or 0) < (b.firstT or 0)
    end)
    return list
end

function HL:CreatureEntryFromGUID(guid)
    if type(guid) ~= "string" then
        return nil
    end
    return tonumber(guid:match("Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)"))
end

function HL:ShouldClaimSummon(rec, pack)
    if rec.sGUID and self.playerGUID and rec.sGUID == self.playerGUID then
        return true
    end
    if rec.spellId and self:IsWatched(rec.spellId) then
        return true
    end
    local entries = pack and pack.summonEntries
    if entries and rec.dGUID then
        local entry = self:CreatureEntryFromGUID(rec.dGUID)
        if entry then
            for i = 1, #entries do
                if entries[i] == entry then
                    return true
                end
            end
        end
    end
    return false
end

function HL:OnTrackCLEU(rec)
    if not rec then
        return
    end
    if rec.ev == "SPELL_SUMMON" then
        local pack = self:CurrentPack()
        if self:ShouldClaimSummon(rec, pack) and rec.dGUID then
            self.summons[rec.dGUID] = {
                spellId = rec.spellId,
                name = rec.dName,
                spawnT = rec.t,
                lastT = rec.t,
                hits = 0,
                damage = 0,
                skills = {},
                targets = {},
                dead = false,
            }
        end
        return
    end

    local summoned = rec.sGUID and self.summons[rec.sGUID]
    if summoned then
        summoned.lastT = rec.t
        if rec.isDamage and rec.amount then
            summoned.hits = summoned.hits + 1
            summoned.damage = summoned.damage + rec.amount
            if rec.spellId then
                summoned.skills[rec.spellId] = (summoned.skills[rec.spellId] or 0) + 1
            end
            if rec.dGUID then
                summoned.targets[rec.dGUID] = rec.dName
            end
        end
    end

    if rec.ev == "UNIT_DIED" and rec.dGUID and self.summons[rec.dGUID] then
        local sm = self.summons[rec.dGUID]
        sm.dead = true
        sm.lastT = rec.t
        sm.lived = (rec.t or 0) - (sm.spawnT or 0)
    end

    local now = rec.t or time()
    for guid, sm in pairs(self.summons) do
        if not sm.dead and sm.lastT and (now - sm.lastT) > SUMMON_EXPIRE then
            sm.dead = true
            sm.lived = (sm.lastT or now) - (sm.spawnT or 0)
        end
    end
end

function HL:SummonSummary()
    local n, dmg, livedSum, skill = 0, 0, 0, nil
    for _, sm in pairs(self.summons) do
        n = n + 1
        dmg = dmg + (sm.damage or 0)
        local lived = sm.lived
        if not lived and sm.spawnT then
            lived = (sm.lastT or time()) - sm.spawnT
        end
        livedSum = livedSum + (lived or 0)
        if not skill then
            for id, _ in pairs(sm.skills) do
                skill = id
                break
            end
        end
    end
    return {
        n = n,
        damage = dmg,
        avgLive = n > 0 and (livedSum / n) or 0,
        skill = skill,
        dealsDamage = dmg > 0,
    }
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then
        return nil
    end
    local ok, a, b, c = pcall(fn, ...)
    if not ok then
        return nil
    end
    return a, b, c
end

function HL:StatSnapshot()
    local apBase, apPos, apNeg = SafeCall(UnitAttackPower, "player")
    local snap = {
        t = (GetTime and GetTime()) or time(),
        haste = SafeCall(GetHaste),
        mastery = SafeCall(GetMasteryEffect),
        crit = SafeCall(GetCritChance),
        vers = (type(CR_VERSATILITY_DAMAGE_DONE) ~= "nil" and SafeCall(GetVersatilityBonus, CR_VERSATILITY_DAMAGE_DONE))
            or SafeCall(GetVersatilityBonus, 29),
        critRating = SafeCall(GetCombatRating, (type(CR_CRIT_MELEE) ~= "nil" and CR_CRIT_MELEE) or 9),
        hasteRating = SafeCall(GetCombatRating, (type(CR_HASTE_MELEE) ~= "nil" and CR_HASTE_MELEE) or 18),
        masteryRating = SafeCall(GetCombatRating, (type(CR_MASTERY) ~= "nil" and CR_MASTERY) or 26),
        versRating = SafeCall(GetCombatRating, (type(CR_VERSATILITY_DAMAGE_DONE) ~= "nil" and CR_VERSATILITY_DAMAGE_DONE) or 29),
        lifesteal = SafeCall(GetLifesteal),
        avoidance = SafeCall(GetAvoidance),
        ap = (apBase or 0) + (apPos or 0) + (apNeg or 0),
        sp = SafeCall(GetSpellBonusDamage, 4) or SafeCall(GetSpellBonusDamage, 1),
    }
    self.lastSnapshot = snap
    self.snapshots[#self.snapshots + 1] = snap
    while #self.snapshots > 20 do
        table.remove(self.snapshots, 1)
    end
    return snap
end

function HL:DiffSnapshots(a, b)
    if not a or not b then
        return {}
    end
    local keys = {
        "haste", "mastery", "crit", "vers",
        "critRating", "hasteRating", "masteryRating", "versRating",
        "lifesteal", "avoidance", "ap", "sp",
    }
    local out = {}
    for i = 1, #keys do
        local k = keys[i]
        if type(a[k]) == "number" and type(b[k]) == "number" then
            out[k] = b[k] - a[k]
        end
    end
    return out
end

function HL:FormatSnapshotDelta(delta, before, after)
    if not delta then
        return ""
    end
    local names = {
        haste = "急速%", mastery = "精通%", crit = "暴击%", vers = "全能%",
        critRating = "暴击rating", hasteRating = "急速rating",
        masteryRating = "精通rating", versRating = "全能rating",
        lifesteal = "吸血", avoidance = "闪避", ap = "攻强", sp = "法强",
    }
    local parts = {}
    for k, label in pairs(names) do
        local d = delta[k]
        if type(d) == "number" and math.abs(d) >= 0.05 then
            local fmt = k:find("Rating", 1, true) and " %s %+.0f(%.0f→%.0f)" or " %s %+.1f(%.1f→%.1f)"
            local fmtShort = k:find("Rating", 1, true) and " %s %+.0f" or " %s %+.1f"
            if before and after and before[k] and after[k] then
                parts[#parts + 1] = string.format(fmt, label, d, before[k], after[k])
            else
                parts[#parts + 1] = string.format(fmtShort, label, d)
            end
        end
    end
    return table.concat(parts, ",")
end

function HL:NoteAuraSnapshot(rec)
    if not rec or not rec.isAura or rec.dGUID ~= self.playerGUID then
        return
    end
    if not rec.spellId or not self:IsWatched(rec.spellId) then
        return
    end
    if rec.ev == "SPELL_AURA_APPLIED" or rec.ev == "SPELL_AURA_APPLIED_DOSE" then
        local before = self.lastSnapshot or self:StatSnapshot()
        local id = rec.spellId
        -- Only APPLIED starts the clock. DOSE used to overwrite statAppliedT,
        -- so "持续 20s" was last-stack→drop, not apply→drop (~41s this log).
        local startClock = rec.ev == "SPELL_AURA_APPLIED"
        if type(C_Timer) == "table" and C_Timer.After then
            C_Timer.After(0.1, function()
                local after = HL:StatSnapshot()
                local s = HL:Stat(id)
                s.statDelta = HL:DiffSnapshots(before, after)
                s.statBefore = before
                s.statAfter = after
                if startClock then
                    s.statAppliedT = (GetTime and GetTime()) or time()
                end
                HL:UI("statsnap")
            end)
        else
            local after = self:StatSnapshot()
            local s = self:Stat(id)
            s.statDelta = self:DiffSnapshots(before, after)
            s.statBefore = before
            s.statAfter = after
            if startClock then
                s.statAppliedT = (GetTime and GetTime()) or time()
            end
        end
    elseif rec.ev == "SPELL_AURA_REMOVED" then
        local s = self.stats[rec.spellId]
        if s and s.statAppliedT then
            local now = (GetTime and GetTime()) or time()
            s.statDuration = now - s.statAppliedT
        end
    end
end

function HL:ReadCorruption()
    local corr = SafeCall(GetCorruption)
    local resist = SafeCall(GetCorruptionResistance)
    if corr == nil and C_PlayerInfo then
        corr = SafeCall(C_PlayerInfo.GetCorruption)
        resist = SafeCall(C_PlayerInfo.GetCorruptionResistance)
    end
    if corr == nil and self.db then
        corr = self.db.manualCorruption
        resist = self.db.manualResist
    end
    return corr, resist or 0
end

function HL:EffectiveCorruption()
    local corr, resist = self:ReadCorruption()
    if corr == nil then
        return nil, nil, nil
    end
    return corr, resist, corr - resist
end

function HL:NoteCorruptionChange()
    local corr, resist, effective = self:EffectiveCorruption()
    if effective == nil then
        return
    end
    if self.lastCorruption ~= effective then
        local prev = self.lastCorruption
        self.lastCorruption = effective
        if prev ~= nil then
            self:PushLog({
                t = time(),
                ev = "SYSTEM",
                text = string.format("CORRUPTION %s → 有效 %s（%s − 抵抗 %s）",
                    tostring(prev), tostring(effective), tostring(corr), tostring(resist)),
                mine = true,
            })
        end
        self:UI("corr")
    end
end

local SLOT_NAMES = {
    [1] = "头", [2] = "颈", [3] = "肩", [5] = "胸", [6] = "腰",
    [7] = "腿", [8] = "脚", [9] = "腕", [10] = "手", [11] = "指1",
    [12] = "指2", [13] = "饰1", [14] = "饰2", [15] = "背", [16] = "主手", [17] = "副手",
}

function HL:ScanSlotCorruption(slot)
    local tip = self.scanTip
    if not tip and type(CreateFrame) == "function" then
        tip = CreateFrame("GameTooltip", "HavenLabScanTip", nil, "GameTooltipTemplate")
        self.scanTip = tip
    end
    if not tip or not tip.SetInventoryItem then
        return 0, nil
    end
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    tip:SetInventoryItem("player", slot)
    local total, link = 0, GetInventoryItemLink and GetInventoryItemLink("player", slot)
    local nlines = tip.NumLines and tip:NumLines() or 0
    for i = 1, nlines do
        local fs = _G["HavenLabScanTipTextLeft" .. i]
        local text = fs and fs.GetText and fs:GetText()
        if text then
            local n = text:match("^%+(%d+)%s*腐蚀") or text:match("腐蚀%s*[：:]?%s*(%d+)")
                or text:match("^%+(%d+)%s*Corruption") or text:match("Corruption%s*[：:]?%s*(%d+)")
            if n then
                total = total + tonumber(n)
            end
        end
    end
    tip:Hide()
    return total, link
end

function HL:SumTooltipCorruption()
    local sum = 0
    for slot = 1, 17 do
        if SLOT_NAMES[slot] then
            sum = sum + (self:ScanSlotCorruption(slot) or 0)
        end
    end
    return sum
end

function HL:ShellAuraSet()
    local set = {}
    local list = self:CollectAuras("player")
    for i = 1, #list do
        local id = list[i].spellId
        if id and (self.SHELL_IDS[id] or (self:CurrentPack() and self:CurrentPack().labels[id])) then
            if self.SHELL_IDS[id] then
                set[id] = true
            end
        end
    end
    return set
end

function HL:OnEquipmentChanged(slot)
    slot = tonumber(slot)
    local beforeCorr, beforeResist, beforeEff = self:EffectiveCorruption()
    local beforeShell = self:ShellAuraSet()
    if type(C_Timer) == "table" and C_Timer.After then
        C_Timer.After(0.2, function()
            HL:FinishEquipNote(slot, beforeCorr, beforeResist, beforeEff, beforeShell)
        end)
    else
        self:FinishEquipNote(slot, beforeCorr, beforeResist, beforeEff, beforeShell)
    end
end

function HL:FinishEquipNote(slot, beforeCorr, beforeResist, beforeEff, beforeShell)
    self:NoteCorruptionChange()
    local afterCorr, afterResist, afterEff = self:EffectiveCorruption()
    local afterShell = self:ShellAuraSet()
    local gained, lost = {}, {}
    for id in pairs(afterShell or {}) do
        if not (beforeShell and beforeShell[id]) then
            gained[#gained + 1] = id
        end
    end
    for id in pairs(beforeShell or {}) do
        if not (afterShell and afterShell[id]) then
            lost[#lost + 1] = id
        end
    end
    local _, link = self:ScanSlotCorruption(slot or 0)
    local line = string.format("EQUIP 槽%s %s 腐蚀 %s→%s 外壳 +[%s] -[%s]",
        SLOT_NAMES[slot] or tostring(slot or "?"),
        link or "-",
        tostring(beforeEff or "-"), tostring(afterEff or "-"),
        table.concat(gained, ","), table.concat(lost, ","))
    self.equipLog[#self.equipLog + 1] = line
    self:PushLog({ t = time(), ev = "SYSTEM", text = line, mine = true })
    self:UI("corr")
    self:UI("auras")
end

function HL:SetSpeedWatch(on)
    if self.db then
        self.db.showSpeed = on and true or false
    end
    if self.speedTicker and self.speedTicker.Cancel then
        self.speedTicker:Cancel()
        self.speedTicker = nil
    end
    if not on then
        return
    end
    local speed = SafeCall(GetUnitSpeed, "player") or 0
    if speed <= 0 then
        speed = 7
    end
    self.speedState = { base = speed, lastPct = 100, since = (GetTime and GetTime()) or time(), lastSpeed = speed }
    if type(C_Timer) == "table" and C_Timer.NewTicker then
        self.speedTicker = C_Timer.NewTicker(0.2, function()
            HL:TickSpeed()
        end)
    end
end

function HL:TickSpeed()
    local st = self.speedState
    if not st then
        return
    end
    local speed = SafeCall(GetUnitSpeed, "player") or 0
    local base = st.base > 0 and st.base or 7
    local pct = (speed / base) * 100
    if speed <= 0.05 then
        return
    end
    if math.abs(pct - st.lastPct) > 3 then
        local now = (GetTime and GetTime()) or time()
        local lasted = now - (st.since or now)
        local line = string.format("SPEED %.0f%%→%.0f%%, 持续 %.1fs", st.lastPct, pct, lasted)
        self.speedLog[#self.speedLog + 1] = line
        self:PushLog({ t = time(), ev = "SYSTEM", text = line, mine = true })
        st.lastPct = pct
        st.since = now
        st.lastSpeed = speed
    end
end
