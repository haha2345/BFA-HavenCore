local _, HL = ...

local function StatusLabel(status)
    if status == "pass" then
        return "|cff7dff7d通过|r"
    elseif status == "fail" then
        return "|cffff6666失败|r"
    elseif status == "info" then
        return "|cffaaaaaa说明|r"
    end
    return "|cff888888无数据|r"
end

function HL:CountSwings()
    local n = 0
    for i = 1, #self.logs do
        local rec = self.logs[i]
        if rec.spellId == 0 and rec.isDamage and rec.sGUID == self.playerGUID then
            n = n + 1
        end
    end
    return n
end

function HL:ClickedUnaura()
    for i = 1, #self.logs do
        local rec = self.logs[i]
        if rec.text and (rec.text:find("unaura", 1, true) or rec.text:find("lab clear", 1, true)) then
            return true
        end
    end
    return false
end

function HL:HasCombatActivity()
    if self:CountSwings() > 0 then
        return true
    end
    for _, s in pairs(self.stats) do
        if (s.damageN or 0) > 0 or (s.casts or 0) > 0 then
            return true
        end
    end
    for _, list in pairs(self.labMsgs or {}) do
        if #list > 0 then
            return true
        end
    end
    return false
end

function HL:MatchLabExpect(msgs, expect)
    if not expect then
        return true, ""
    end
    local last = msgs[#msgs]
    if not last then
        return false, "没有消息"
    end
    for k, v in pairs(expect) do
        if not self:IsSpecialExpect(k) then
            local got = last.kv and last.kv[k]
            if tostring(got) ~= tostring(v) then
                return false, string.format("%s=%s 期望 %s", k, tostring(got), tostring(v))
            end
        end
    end
    return true, ""
end

function HL:EvalPctOfMaxHp(spellId, expect)
    local s = self.stats[spellId] or {}
    local maxhp = s.playerMaxHp
    if (not maxhp or maxhp <= 0) and type(UnitHealthMax) == "function" then
        maxhp = UnitHealthMax("player")
    end
    if not maxhp or maxhp <= 0 or (s.damageN or 0) == 0 then
        return nil
    end
    local sample = s.damageMax or 0
    if sample <= 0 then
        return nil
    end
    local pct = sample / maxhp
    local want = expect.pctOfMaxHp
    local tol = expect.tolerance or 0.2
    local ok = math.abs(pct - want) <= (want * tol)
    return {
        pct = pct,
        want = want,
        ok = ok,
        text = string.format("实测 %.2f%% 生命, 期望 %.2f%%", pct * 100, want * 100),
    }
end

function HL:EvalHalfDamage(spellId, expect)
    local list = self:SortedPerTarget(spellId)
    local halfFrom = expect.halfFrom
    if not halfFrom or #list < halfFrom then
        return nil
    end
    local firstN = halfFrom - 1
    local firstSum, restSum, firstHits, restHits = 0, 0, 0, 0
    for i = 1, #list do
        local avg = list[i].hits > 0 and (list[i].sum / list[i].hits) or 0
        if i <= firstN then
            firstSum = firstSum + avg
            firstHits = firstHits + 1
        else
            restSum = restSum + avg
            restHits = restHits + 1
        end
    end
    if firstHits == 0 or restHits == 0 then
        return nil
    end
    local firstMean = firstSum / firstHits
    local restMean = restSum / restHits
    local ratio = firstMean > 0 and (restMean / firstMean) or 0
    local ok = ratio <= 0.5 * 1.15
    return {
        ok = ok,
        text = string.format("第%d个起半伤：前均 %.0f 后均 %.0f（%.0f%%）",
            halfFrom, firstMean, restMean, ratio * 100),
    }
end

function HL:CrossCheckTwilightHp(step, pctInfo)
    if not step or step.labType ~= "TWILIGHT_VISUAL" and not (step.id == 317159) then
        return nil
    end
    local msgs = self:LabMessages("TWILIGHT_VISUAL")
    if #msgs == 0 or not pctInfo then
        return nil
    end
    local dmg = msgs[#msgs].kv and msgs[#msgs].kv.damage
    local maxhp = (self.stats[317159] and self.stats[317159].playerMaxHp)
        or (UnitHealthMax and UnitHealthMax("player"))
    if type(dmg) ~= "number" or not maxhp or maxhp <= 0 then
        return nil
    end
    local labPct = dmg / maxhp
    local cleuPct = pctInfo.pct
    if cleuPct and math.abs(labPct - cleuPct) > 0.02 then
        return string.format("TWILIGHT_VISUAL damage=%.0f（%.2f%%）和战斗记录最大跳（%.2f%%）对不上。",
            dmg, labPct * 100, cleuPct * 100)
    end
    return nil
end

function HL:EvalStep(step)
    local result = { step = step, status = "nodata", detail = "" }
    local s = (step.id and self.stats[step.id]) or {}
    local want = step.want
    local combat = self:HasCombatActivity()

    if want == "aura-self" or want == "aura-target" then
        local unit = want == "aura-self" and "player" or "target"
        local count = want == "aura-self" and (s.auraSelf or 0) or (s.auraTarget or 0)
        local found = step.id and self:FindAura(unit, step.id)
        if count > 0 or found then
            result.status = "pass"
            if s.stacks and s.stacks > 0 then
                result.detail = "层" .. tostring(s.stacks)
            end
        elseif step.hidden then
            result.status = "info"
            result.detail = step.hintFail or "隐藏光环，buff 栏没有是正常的。"
        elseif combat then
            result.status = "fail"
        end
    elseif want == "cast" then
        if (s.casts or 0) > 0 then
            result.status = "pass"
            result.detail = tostring(s.casts) .. "次"
        elseif combat then
            result.status = "fail"
        end
    elseif want == "damage" or want == "damage-aura" then
        if (s.damageN or 0) > 0 then
            result.status = "pass"
            result.detail = string.format("%d次 最大%d", s.damageN, s.damageMax or 0)
            if want == "damage-aura" and (s.auraTarget or 0) == 0 and not self:FindAura("target", step.id) then
                result.detail = result.detail .. " 无叠层"
            end
            if step.expect and step.expect.school and s.school and s.school ~= "-" then
                local wantSchool = self:SchoolName(step.expect.school)
                if s.school ~= wantSchool then
                    result.status = "fail"
                    result.detail = "学派 " .. s.school .. " 期望 " .. wantSchool
                end
            end
        elseif combat then
            result.status = "fail"
        end
    elseif want == "summon" then
        local sum = self:SummonSummary()
        local need = (step.expect and step.expect.minCount) or 1
        if sum.n >= need and (not step.expect or not step.expect.dealsDamage or sum.dealsDamage) then
            result.status = "pass"
            result.detail = string.format("%d只 伤%d", sum.n, sum.damage)
        elseif combat then
            result.status = "fail"
        end
    elseif want == "stat" then
        local key = step.expect and step.expect.stat or "haste"
        local minDelta = step.expect and step.expect.minDelta or 0.01
        local delta = s.statDelta and s.statDelta[key]
        if type(delta) == "number" and math.abs(delta) >= minDelta then
            result.status = "pass"
            result.detail = string.format("%s %+.1f", key, delta)
        elseif combat or (s.statDelta and next(s.statDelta)) then
            result.status = "fail"
        end
    elseif want == "labmsg" then
        local msgs = self:LabMessages(step.labType)
        if #msgs > 0 then
            local ok, why = self:MatchLabExpect(msgs, step.expect)
            if ok then
                result.status = "pass"
                result.detail = tostring(#msgs) .. "次"
            else
                result.status = "fail"
                result.detail = why
            end
        elseif combat then
            result.status = "fail"
        end
    else
        result.status = "info"
        result.detail = "未知 want=" .. tostring(want)
    end
    return result
end

function HL:EvalChain(pack)
    pack = pack or self:CurrentPack()
    local results = {}
    if not pack or not pack.chain then
        return results
    end
    for i = 1, #pack.chain do
        results[i] = self:EvalStep(pack.chain[i])
    end
    return results
end

function HL:FirstFail(results)
    for i = 1, #results do
        if results[i].status == "fail" then
            return results[i], i
        end
    end
end

function HL:ProcRateLine(pack)
    pack = pack or self:CurrentPack()
    if not pack then
        return nil
    end
    local ps = self:ProcStats(pack.key)
    if ps.n == 0 then
        return nil
    end
    local line = string.format("触发 %d 次 / %.1f 分钟 = %.2f 次/分",
        ps.n, (ps.span or 0) / 60, ps.ppm or 0)
    if ps.minGap then
        line = line .. string.format("，最小间隔 %.1fs", ps.minGap)
    end
    if ps.sampleLow then
        line = line .. "（样本不足，PPM 只报数不判死）"
    end
    local minGapMs
    for i = 1, #(pack.chain or {}) do
        local ex = pack.chain[i].expect
        if ex and ex.minGapMs then
            minGapMs = ex.minGapMs
        end
    end
    if minGapMs and ps.minGap and (ps.minGap * 1000) + 0.001 < minGapMs then
        line = line .. string.format("。最短间隔短于 ICD %dms。", minGapMs)
    end
    return line
end

function HL:ExpectExtraLines(step)
    local lines = {}
    if not step or not step.expect then
        return lines
    end
    if step.expect.pctOfMaxHp then
        local info = self:EvalPctOfMaxHp(step.id, step.expect)
        if info then
            lines[#lines + 1] = (info.ok and "" or "偏差较大：") .. info.text
            local cross = self:CrossCheckTwilightHp(step, info)
            if cross then
                lines[#lines + 1] = cross
            end
        end
    end
    if step.expect.maxTargets then
        local list = self:SortedPerTarget(step.id)
        if #list > 0 then
            lines[#lines + 1] = string.format("命中 %d 个目标（上限 %d）。", #list, step.expect.maxTargets)
            if #list > step.expect.maxTargets then
                lines[#lines + 1] = "超过目标上限。"
            end
        end
    end
    if step.expect.halfFrom then
        local half = self:EvalHalfDamage(step.id, step.expect)
        if half then
            lines[#lines + 1] = half.text
        end
    end
    return lines
end

function HL:VerdictLines()
    local pack = self:CurrentPack()
    local lines = {}
    if not pack then
        lines[1] = "没有测试包。"
        return lines
    end

    local results = self:EvalChain(pack)
    local fail = self:FirstFail(results)
    for i = 1, #results do
        local r = results[i]
        local step = r.step
        local idtxt = step.id and tostring(step.id) or (step.labType or "")
        local extra = r.detail ~= "" and ("  " .. r.detail) or ""
        lines[#lines + 1] = string.format("%s  %s %s%s", StatusLabel(r.status), step.role or "?", idtxt, extra)
    end

    if fail then
        local hint = fail.step.hintFail
        if hint and hint ~= "" then
            lines[#lines + 1] = hint
        else
            lines[#lines + 1] = "上一环有、这一环没有，断在这里。"
        end
    end

    for i = 1, #results do
        local extra = self:ExpectExtraLines(results[i].step)
        for j = 1, #extra do
            lines[#lines + 1] = extra[j]
        end
    end

    local procLine = self:ProcRateLine(pack)
    if procLine then
        lines[#lines + 1] = procLine
    end

    if type(pack.extraVerdict) == "function" then
        local more = pack.extraVerdict(self)
        if type(more) == "table" then
            for i = 1, #more do
                lines[#lines + 1] = more[i]
            end
        end
    end
    return lines
end

function HL:ChainText()
    return "|cffffd100白话结论|r\n" .. table.concat(self:VerdictLines(), "\n")
end

function HL:PerTargetReportLines()
    local lines = {}
    local pack = self:CurrentPack()
    if not pack then
        return lines
    end
    local seen = {}
    for i = 1, #(pack.chain or {}) do
        local id = pack.chain[i].id
        if id and not seen[id] then
            seen[id] = true
            local list = self:SortedPerTarget(id)
            if #list > 0 then
                lines[#lines + 1] = string.format("-- 目标表 %d %s --", id, self:LabelOf(id))
                for j = 1, #list do
                    local pt = list[j]
                    lines[#lines + 1] = string.format("%s  命中%d  合计%d  单跳最大%d  首次%.2f",
                        pt.name or "?", pt.hits, pt.sum, pt.max, pt.firstT or 0)
                end
            end
        end
    end
    return lines
end

function HL:TopTargetsText(limit)
    limit = limit or 5
    local pack = self:CurrentPack()
    if not pack then
        return ""
    end
    for i = 1, #pack.chain do
        local step = pack.chain[i]
        if step.id and (step.want == "damage" or step.want == "damage-aura") then
            local list = self:SortedPerTarget(step.id)
            if #list > 0 then
                local lines = { "|cffffd100命中目标|r" }
                for j = 1, math.min(#list, limit) do
                    local pt = list[j]
                    lines[#lines + 1] = string.format("%s  %d跳 最大%d", pt.name or "?", pt.hits, pt.max)
                end
                if #list > limit then
                    lines[#lines + 1] = "|cff888888…共" .. #list .. "个，完整表进报告|r"
                end
                return table.concat(lines, "\n")
            end
        end
    end
    return ""
end

function HL:CorruptionMatrixLines()
    local lines = {}
    local corr, resist, effective = self:EffectiveCorruption()
    if effective == nil then
        lines[1] = "腐蚀 API 不可用。/lab corr <值> 手输。"
        return lines
    end
    lines[1] = string.format("腐蚀 %s − 抵抗 %s = 有效 %s", tostring(corr), tostring(resist), tostring(effective))
    local tipSum = self:SumTooltipCorruption()
    if tipSum and tipSum > 0 then
        lines[#lines + 1] = string.format("tooltip 腐蚀合计 %d%s", tipSum,
            (corr and math.abs(tipSum - corr) > 1) and "（和面板不一致）" or "")
    end
    for i = 1, #self.THRESHOLDS do
        local row = self.THRESHOLDS[i]
        local should = effective >= row.min
        local ids = row.auras or {}
        local have = false
        if #ids == 0 then
            lines[#lines + 1] = string.format("%d %s  应挂:%s  实挂:未登记",
                row.min, row.label, should and "是" or "否")
        else
            for j = 1, #ids do
                if self:FindAura("player", ids[j]) then
                    have = true
                    break
                end
            end
            lines[#lines + 1] = string.format("%d %s  应挂:%s  实挂:%s",
                row.min, row.label, should and "是" or "否", have and "是" or "否")
        end
    end
    return lines
end

function HL:GetReport()
    local pack = self:CurrentPack()
    local lines = {
        "== HavenLab 报告 " .. date("%Y-%m-%d %H:%M:%S") .. " ==",
        "包: " .. (pack and pack.title or "-"),
        "自己: " .. (UnitName and (UnitName("player") or "?") or "?") .. "  " .. tostring(self.playerGUID or ""),
    }
    if type(UnitExists) == "function" and UnitExists("target") then
        local hp, maxhp = UnitHealth("target"), UnitHealthMax("target")
        lines[#lines + 1] = string.format("目标: %s  HP=%d/%d (%.1f%%)",
            UnitName("target") or "?", hp or 0, maxhp or 0,
            maxhp and maxhp > 0 and (100 * hp / maxhp) or 0)
    else
        lines[#lines + 1] = "目标: （无）"
    end

    local corrLines = self:CorruptionMatrixLines()
    lines[#lines + 1] = ""
    lines[#lines + 1] = "【腐蚀】"
    for i = 1, #corrLines do
        lines[#lines + 1] = corrLines[i]
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "【白话结论】"
    local verdict = self:VerdictLines()
    for i = 1, #verdict do
        lines[#lines + 1] = verdict[i]
    end

    local per = self:PerTargetReportLines()
    if #per > 0 then
        lines[#lines + 1] = ""
        for i = 1, #per do
            lines[#lines + 1] = per[i]
        end
    end

    local sum = self:SummonSummary()
    lines[#lines + 1] = ""
    lines[#lines + 1] = "-- 召唤物 --"
    if sum.n == 0 then
        lines[#lines + 1] = "(无。触须/眼若 CLEU 无 SPELL_SUMMON，把 creature entry 填进 pack.summonEntries)"
    else
        lines[#lines + 1] = string.format("召唤 %d 只, 平均存活 %.1fs, 合计伤害 %d%s",
            sum.n, sum.avgLive, sum.damage, sum.skill and ("（技能 " .. sum.skill .. "）") or "")
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "-- 属性快照 --"
    local anySnap = false
    for id, s in pairs(self.stats) do
        if s.statDelta then
            anySnap = true
            local dur = s.statDuration and string.format("，持续 %.1fs", s.statDuration) or ""
            lines[#lines + 1] = string.format("挂 %s 后%s%s",
                tostring(id), self:FormatSnapshotDelta(s.statDelta, s.statBefore, s.statAfter), dur)
        end
    end
    if not anySnap then
        lines[#lines + 1] = "(无)"
    end

    if #self.equipLog > 0 then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "-- 穿脱 --"
        for i = 1, #self.equipLog do
            lines[#lines + 1] = self.equipLog[i]
        end
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "-- 当前光环（点报告这一刻；卸星后会是空的） --"
    local pa = self:CollectAuras("player")
    if #pa == 0 then
        lines[#lines + 1] = "自己: (无)"
    else
        for i = 1, math.min(#pa, 16) do
            local a = pa[i]
            lines[#lines + 1] = string.format("自己 %s%d  %s  x%d",
                a.watched and "★" or "", a.spellId, a.name, a.count)
        end
    end
    if type(UnitExists) == "function" and UnitExists("target") then
        local ta = self:CollectAuras("target")
        if #ta == 0 then
            lines[#lines + 1] = "目标: (无)"
        else
            for i = 1, math.min(#ta, 16) do
                local a = ta[i]
                lines[#lines + 1] = string.format("目标 %s%d  %s  x%d",
                    a.watched and "★" or "", a.spellId, a.name, a.count)
            end
        end
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "-- 战斗记录（从早到晚） --"
    local shown = 0
    for i = 1, #self.logs do
        local rec = self.logs[i]
        if rec.ev == "SYSTEM" or rec.ev == "LAB" or (rec.spellId and self:IsWatched(rec.spellId)) or rec.isDamage then
            local prefix = rec.manual and "[手动] " or ""
            lines[#lines + 1] = prefix .. (rec.plain or rec.text or "")
            shown = shown + 1
        end
    end
    if shown == 0 then
        lines[#lines + 1] = "(空)"
    end
    lines[#lines + 1] = "== 结束 =="
    return table.concat(lines, "\n")
end

function HL:OverviewExport()
    local ov = self.db and self.db.overview or {}
    local lines = { "| 效果 | 第0层 | 第1层 | 第2层 | 最后测试 |" }
    for _, pack in pairs(self.PACKS or {}) do
        if not pack.hidden then
            local row = ov[pack.key] or {}
            lines[#lines + 1] = string.format("| %s | %s | %s | %s | %s |",
                pack.title,
                row.l0 and "通过" or "",
                row.l1 and "通过" or "",
                row.l2 and "通过" or "",
                row.t or "")
        end
    end
    return table.concat(lines, "\n")
end
