local _, HL = ...

-- 纯数据 + 包特有话术。新效果只加一张表，不改引擎。

-- Aura IDs from 35662 CorruptionEffects.db2（清单 B 表启用行）。不是猜的外壳。
HL.THRESHOLDS = {
    { min = 1,   label = "蔓生触须",     auras = { 315175 } },
    { min = 20,  label = "腐蚀之眼",     auras = { 315169 } },
    { min = 40,  label = "宏伟妄想",     auras = { 315184 } },
    { min = 60,  label = "层叠灾难",     auras = { 315857 } },
    { min = 80,  label = "不可避免的厄运", auras = { 315179 } },
    { min = 200, label = "末路恶果",     auras = { 337612 } },
}

HL.SHELL_IDS = {
    [324889] = true, [324890] = true, [324891] = true,
    [318274] = true, [318487] = true, [318488] = true,
    [318276] = true, [318477] = true, [318478] = true,
    [318280] = true, [318485] = true, [318486] = true,
    [318481] = true, [318482] = true, [318483] = true,
    [318286] = true, [318479] = true, [318480] = true,
    [318266] = true, [318492] = true, [318496] = true,
    [318269] = true, [318494] = true, [318498] = true,
    [318268] = true, [318493] = true, [318497] = true,
    [318270] = true, [318495] = true, [318499] = true,
    [318272] = true, [318239] = true, [318303] = true, [318484] = true,
    [315277] = true, [315281] = true, [315282] = true,
}

HL.PACKS = {
    stars = {
        key = "stars",
        title = "无尽之星",
        order = 1,
        serverCmd = ".lab test stars",
        hint = "用技能打木桩。出星看记录里的 STAR_VISUAL，\n不用盯着天。buff 栏没有 317257 是正常的。",
        startText = "【测试开始】光环打在你自己身上。用技能打木桩（普攻不出星）。落星会写成 STAR_VISUAL，不用看天。",
        startPrint = "已对你挂 317257。用猛击等技能打木桩（普攻不出星）。",
        ids = { 324889, 324890, 324891, 318274, 317257, 317260, 317262, 317265 },
        labels = {
            [324889] = "外壳1 腐蚀-无尽之星",
            [324890] = "外壳2",
            [324891] = "外壳3",
            [318274] = "隐藏驱动",
            [317257] = "隐藏proc",
            [317260] = "选目标",
            [317262] = "导弹动画",
            [317265] = "伤害/叠层",
        },
        chain = {
            { id = 317257, role = "隐藏proc", want = "aura-self", hidden = true,
              hintFail = "隐藏光环，buff 栏看不见是正常的，以战斗记录为准。" },
            { id = 317262, role = "导弹", want = "labmsg", labType = "STAR_VISUAL",
              expect = { missile = 1 }, procStep = true,
              hintFail = "没有 STAR_VISUAL。伤害打了但动画包没发出，或还没出星。" },
            { id = 317265, role = "伤害/叠层", want = "damage-aura",
              expect = { school = 64 },
              hintFail = "没有 317265 奥术伤害。白字普攻不会出星，要用猛击等技能。" },
        },
        extraVerdict = function(self)
            local lines = {}
            local swings = self:CountSwings()
            local s265 = self.stats[317265] or {}
            local autoD = s265.autoDmg or 0
            local manD = s265.manDmg or 0
            local autoAura = s265.autoAura or 0
            local _, tStacks = self:FindAura("target", 317265)

            if swings == 0 and autoD == 0 and manD == 0 then
                lines[#lines + 1] = "还没开始。点「无尽之星」，选中木桩用技能打 10 秒，再点「生成报告」。"
                lines[#lines + 1] = "中间不要点「看落星 / 手打伤害 / 卸星」，那些是对照，会把记录搅乱。"
                return lines
            end

            lines[#lines + 1] = string.format("平砍 %d 次。", swings)
            if autoD > 0 then
                lines[#lines + 1] = string.format("技能/法术打出了 %d 次无尽之星伤害（最大 %d %s）。法术 ID 317265，不是普攻。",
                    autoD, s265.damageMax or 0, s265.school or "奥术")
            end
            if autoAura > 0 and autoD == 0 then
                lines[#lines + 1] = "平砍只给木桩叠了层，没有伤害事件 = 默认光环套上了，脚本没把奥术伤打出去。"
            elseif autoAura == 0 and swings > 3 and autoD == 0 then
                lines[#lines + 1] = "平砍也没有叠 317265 层 = 隐藏 proc 没有在自动攻击时触发（普攻本来就不该出星）。"
            end
            if tStacks then
                lines[#lines + 1] = string.format("现在木桩头上 317265 有 %d 层。", tStacks)
            end
            if manD > 0 then
                lines[#lines + 1] = string.format("你点过「手打伤害」：317265 本身能打（%d 次）。技能是好的，断在「技能会不会自动打出星」。", manD)
            end
            if self:ClickedUnaura() then
                lines[#lines + 1] = "你已经点过卸星。现在「自己光环」是空的，不能用来判断刚才挂没挂上，以战斗记录为准。"
            end
            return lines
        end,
    },

    twilight = {
        key = "twilight",
        title = "暮光毁灭",
        order = 2,
        serverCmd = ".lab test twilight",
        hint = "面对木桩打。斩击写成 TWILIGHT_VISUAL，\n伤害 317159 暗影。光柱沿面向飞约 4 秒。",
        startText = "【暮光测试】光环打在你自己身上（不会打到木桩上）。会卸掉无尽之星。面对木桩打，斩击写成 TWILIGHT_VISUAL。",
        startPrint = "已对你挂 317147 并卸星。面对木桩打。出斩看 TWILIGHT_VISUAL 和 317159。",
        ids = { 318276, 318477, 318478, 317147, 317155, 317159 },
        labels = {
            [318276] = "一段驱动",
            [318477] = "二段驱动",
            [318478] = "三段驱动",
            [317147] = "隐藏proc",
            [317155] = "面前光束",
            [317159] = "暗影伤害",
        },
        chain = {
            { id = 317147, role = "隐藏proc", want = "aura-self", hidden = true, procStep = true,
              expect = { approxPpm = 1, tolerance = 0.5 } },
            { id = 317155, role = "面前光束", want = "labmsg", labType = "TWILIGHT_VISUAL",
              expect = { beam = 1 },
              hintFail = "有伤害但没有 TWILIGHT_VISUAL，或还没出斩。" },
            { id = 317159, role = "暗影伤害", want = "damage",
              -- 2020-02 热修：最多 10 目标，第 6–10 半伤。来源：做法-A2 / 设计热修白名单
              expect = { school = 32, pctOfMaxHp = 0.06, tolerance = 0.2, maxTargets = 10, halfFrom = 6 },
              hintFail = "没有 317159 暗影伤害。光柱沿面向飞约 4 秒/28 码，扫到才结算；脸没对准就是 0。" },
        },
        extraVerdict = function(self)
            local lines = {}
            local swings = self:CountSwings()
            local s159 = self.stats[317159] or {}
            local dmgN = s159.damageN or 0
            if swings == 0 and dmgN == 0 then
                lines[#lines + 1] = "还没开始。点「暮光毁灭」，面对木桩打，再点「生成报告」。"
                return lines
            end
            lines[#lines + 1] = string.format("平砍 %d 次。", swings)
            if dmgN > 0 then
                lines[#lines + 1] = string.format("暮光斩击 %d 次（最大 %d %s）。法术 ID 317159 暗影。",
                    dmgN, s159.damageMax or 0, s159.school or "暗影")
            end
            lines[#lines + 1] = "官方约 1 次/分钟（吃急速，4 秒 ICD）。扫到就打，会拉未进战的怪（blizz-like，不当 bug）。"
            lines[#lines + 1] = "待进游戏验收：.labaoe 12 只一线，CLEU 恰好 10 条 317159，第 6–10 约半伤（容差 ±15%），第 11/12 无伤；2 号站路径上无 PvP 不掉血。"
            return lines
        end,
    },

    echo = {
        key = "echo",
        title = "虚空回响",
        order = 3,
        serverCmd = ".lab test echo",
        hint = "用带 GCD 的技能打。叠 317020，有几率坍缩。\nICD 700ms。无 GCD / 平砍叠了层 = 过滤失效。",
        startText = "【回响测试】已挂 317014。用带 GCD 的技能打木桩。叠层看 317020，坍缩看 ECHO_COLLAPSE / 317029。平砍或无 GCD 技能不应叠层。",
        startPrint = "已对你挂 317014 并卸星/暮光。用带 GCD 的技能打；平砍 / 无 GCD 不叠。",
        ids = { 318280, 318485, 318486, 317014, 317020, 317022, 317029 },
        labels = {
            [318280] = "一段驱动",
            [318485] = "二段驱动",
            [318486] = "三段驱动",
            [317014] = "隐藏proc",
            [317020] = "叠层",
            [317022] = "坍缩",
            [317029] = "暗影AoE",
        },
        chain = {
            { id = 317014, role = "隐藏proc", want = "aura-self", hidden = true,
              expect = { minGapMs = 700 } },
            { id = 317020, role = "叠层", want = "aura-self", procStep = true,
              -- 2020-01-27 热修：C++ 滤 StartRecoveryTime==0。来源：做法-A3 / 设计热修白名单
              hintFail = "没有 317020 叠层。只用带 GCD 的技能。若平砍或无 GCD 技能叠了层 = 过滤失效。" },
            { id = 317022, role = "坍缩", want = "labmsg", labType = "ECHO_COLLAPSE",
              hintFail = "有叠层但没有 ECHO_COLLAPSE。坍缩是几率（约 15%），多打一会儿。" },
            { id = 317029, role = "暗影AoE", want = "damage",
              expect = { school = 32, pctOfMaxHp = 0.004, tolerance = 0.25 },
              hintFail = "坍缩了但没有 317029 暗影伤害。" },
        },
        extraVerdict = function(self)
            local lines = {}
            local s020 = self.stats[317020] or {}
            local s029 = self.stats[317029] or {}
            if (s020.auraSelf or 0) == 0 and (s029.damageN or 0) == 0 then
                lines[#lines + 1] = "还没开始。点「虚空回响」，用猛击等带 GCD 的技能打，再点「生成报告」。"
                return lines
            end
            local _, stacks = self:FindAura("player", 317020)
            if stacks then
                lines[#lines + 1] = string.format("现在自己 317020 有 %d 层。", stacks)
            end
            local swings = self:CountSwings()
            if swings > 0 and (s020.auraSelf or 0) > 0 then
                lines[#lines + 1] = string.format(
                    "平砍 %d。若这段时间只用平砍却出了 317020，无 GCD 过滤失效。", swings)
            end
            lines[#lines + 1] = "待进游戏验收：无 GCD 技能（部分爆发饰品）不叠层；坍缩扫到未进战野怪会拉进战斗（blizz-like，不当 bug）。"
            return lines
        end,
    },

    tentacle = {
        key = "tentacle",
        title = "扭曲的附肢",
        order = 4,
        serverCmd = ".lab test tentacle",
        hint = "平砍或技能都会出触须。出触须看 TENTACLE_SPAWN，\n跳伤看 TENTACLE_TICK / 316835。",
        startText = "【触须测试】已挂 316815。平砍或猛击打木桩。出触须写成 TENTACLE_SPAWN，跳伤写成 TENTACLE_TICK。",
        startPrint = "已对你挂 316815 并卸星/暮光/回响。平砍或技能都会出触须。",
        ids = { 318481, 318482, 318483, 316815, 316818, 316835 },
        labels = {
            [318481] = "一段驱动",
            [318482] = "二段驱动",
            [318483] = "三段驱动",
            [316815] = "隐藏proc",
            [316818] = "召唤",
            [316835] = "心灵鞭笞",
        },
        chain = {
            { id = 316815, role = "隐藏proc", want = "aura-self", hidden = true,
              hintFail = "隐藏光环，buff 栏看不见是正常的，以 TENTACLE_SPAWN 为准。" },
            { id = 316818, role = "召唤", want = "labmsg", labType = "TENTACLE_SPAWN",
              hintFail = "没有 TENTACLE_SPAWN。平砍或技能打一会儿（RPPM 1）。" },
            { id = 316835, role = "心灵鞭笞", want = "damage",
              expect = { school = 32 },
              hintFail = "出了触须但没有 316835 暗影跳伤。看触须是否在抽当前目标。" },
        },
    },

    ritual = {
        key = "ritual",
        title = "虚空仪式",
        order = 5,
        serverCmd = ".lab test ritual",
        snapshotOnStart = true,
        snapshotOnLab = "RITUAL_TICK",
        snapshotSpell = 316823,
        -- 方案-腐蚀-剩余修复.md 矩阵 #1；人数 Dummy 见做法-A5 / 316814 EFFECT_2
        expect = {
            allyNeed = 2,
            soloBandLow = 0.08,
            soloBandHigh = 0.28,
            minSoloSample = 60,
        },
        hint = "用技能打（平砍不开）。proc 看 RITUAL_PROC，\n爬坡看 RITUAL_TICK / 316823 层数。面板次级应涨。双端矩阵看报告「多人矩阵」。",
        startText = "【仪式测试】已挂 316814。用猛击等技能打木桩。开仪式写成 RITUAL_PROC，每秒加层写成 RITUAL_TICK。平砍不开。",
        startPrint = "已对你挂 316814 并卸星/暮光/回响/触须。用技能打，平砍不开仪式。",
        ids = { 318286, 318479, 318480, 316814, 316823 },
        labels = {
            [318286] = "一段驱动",
            [318479] = "二段驱动",
            [318480] = "三段驱动",
            [316814] = "隐藏proc",
            [316823] = "末日将至",
        },
        chain = {
            { id = 316814, role = "隐藏proc", want = "aura-self", hidden = true,
              hintFail = "隐藏光环，buff 栏看不见是正常的，以 RITUAL_PROC 为准。" },
            { id = 316814, role = "开仪式", want = "labmsg", labType = "RITUAL_PROC", procStep = true,
              hintFail = "没有 RITUAL_PROC。用猛击等黄字打一会儿（RPPM 1，单人再掷 5/6）。" },
            { id = 316823, role = "末日将至", want = "aura-self",
              hintFail = "有 RITUAL_PROC 但自己没有 316823。看是否被 refresh 跳过。" },
            { id = 316823, role = "爬坡", want = "labmsg", labType = "RITUAL_TICK",
              hintFail = "有 316823 但没有 RITUAL_TICK。应每秒加一层，最多 20。" },
            { id = 316823, role = "次级上涨", want = "stat",
              expect = { stat = "critRating", minDelta = 1 },
              hintFail = "有 316823 但暴击 rating 没涨。看人物面板，或点右侧「记快照」。" },
        },
        extraVerdict = function(self)
            local lines = {}
            local procs = self:LabMessages("RITUAL_PROC")
            local ticks = self:LabMessages("RITUAL_TICK")
            local s823 = self.stats[316823] or {}
            local swings = self:CountSwings()
            if #procs == 0 and #ticks == 0 and (s823.auraSelf or 0) == 0 then
                lines[#lines + 1] = "还没开始。点「虚空仪式」，用猛击打木桩，再点「生成报告」。"
                return lines
            end
            local opened, skipRefresh, skipSolo = 0, 0, 0
            for i = 1, #procs do
                local kv = procs[i].kv or {}
                if kv.skipped == "refresh" then
                    skipRefresh = skipRefresh + 1
                elseif kv.skipped == "solo" then
                    skipSolo = skipSolo + 1
                elseif kv.ok == 1 then
                    opened = opened + 1
                end
            end
            lines[#lines + 1] = string.format(
                "RITUAL_PROC %d（开 %d，skip refresh %d，skip solo %d）。平砍 %d。",
                #procs, opened, skipRefresh, skipSolo, swings)
            if swings > 0 and opened == 0 and #ticks == 0 then
                lines[#lines + 1] = "只有平砍、没有开仪式：白字不在 316814 掩码里，这是对的。改用猛击。"
            end
            local maxStacks, lastRating, bad = 0, 0, 0
            for i = 1, #ticks do
                local kv = ticks[i].kv or {}
                local st = tonumber(kv.stacks) or 0
                local rt = tonumber(kv.rating) or 0
                if st > maxStacks then maxStacks = st end
                lastRating = rt
                if st > 0 and rt > 0 and rt ~= st * 14 then
                    bad = bad + 1
                end
            end
            if #ticks > 0 then
                lines[#lines + 1] = string.format(
                    "RITUAL_TICK %d 次，最高 %d 层，最后 rating=%d（一段期望 层×14）。",
                    #ticks, maxStacks, lastRating)
                local first = ticks[1].kv or {}
                local fs, fr = tonumber(first.stacks) or 0, tonumber(first.rating) or 0
                if fs == 1 and fr == 14 then
                    lines[#lines + 1] = "第一跳 stacks=1 rating=14，一段 Dummy 对得上。"
                elseif fs == 1 then
                    lines[#lines + 1] = string.format("第一跳 stacks=1 rating=%s（一段应为 14）。", tostring(first.rating))
                end
                if bad == 0 and lastRating > 0 then
                    lines[#lines + 1] = "每跳 rating = 层×14。"
                elseif bad > 0 then
                    lines[#lines + 1] = string.format("%d 跳 rating 不是层×14（二段/三段或脚本读错 Dummy）。", bad)
                end
                if maxStacks >= 20 then
                    lines[#lines + 1] = "已到 20 层上限。"
                end
                if #ticks > 25 then
                    lines[#lines + 1] = "TICK 明显超过 20 次：叠层可能刷新了 20 秒，或满层后仍在刷通知。"
                end
            end
            local applyT, removeT
            for i = 1, #self.logs do
                local rec = self.logs[i]
                if rec.spellId == 316823 and rec.dGUID == self.playerGUID then
                    if rec.ev == "SPELL_AURA_APPLIED" and not applyT then
                        applyT = rec.t
                    elseif rec.ev == "SPELL_AURA_REMOVED" then
                        removeT = rec.t
                    end
                end
            end
            if applyT and removeT then
                local dur = removeT - applyT
                if dur >= 18 and dur <= 22 then
                    lines[#lines + 1] = string.format("316823 墙钟 %.1fs（期望约 20s）。", dur)
                elseif dur > 22 then
                    lines[#lines + 1] = string.format(
                        "316823 墙钟 %.1fs，太长（叠层刷新了时长？期望约 20s）。", dur)
                else
                    lines[#lines + 1] = string.format("316823 墙钟 %.1fs，偏短（期望约 20s）。", dur)
                end
            end
            local _, stacks = self:FindAura("player", 316823)
            if stacks then
                lines[#lines + 1] = string.format("现在自己 316823 有 %d 层。", stacks)
            end
            if s823.statDelta then
                local delta = self:FormatSnapshotDelta(s823.statDelta, s823.statBefore, s823.statAfter)
                if delta and delta ~= "" then
                    lines[#lines + 1] = "相对开测快照：" .. delta
                end
            end

            local packExpect = ((self.CurrentPack and self:CurrentPack()) or {}).expect or {}
            local allyNeed = tonumber(packExpect.allyNeed) or 2
            local bandLo = tonumber(packExpect.soloBandLow) or 0.08
            local bandHi = tonumber(packExpect.soloBandHigh) or 0.28
            local minSample = tonumber(packExpect.minSoloSample) or 60
            local byAllies, chanceN, increasedN, leakSolo, maxAllies = {}, 0, 0, 0, 0
            for i = 1, #procs do
                local kv = procs[i].kv or {}
                if kv.skipped ~= "refresh" then
                    chanceN = chanceN + 1
                    local al = tonumber(kv.allies) or 0
                    if al > maxAllies then maxAllies = al end
                    byAllies[al] = (byAllies[al] or 0) + 1
                    if tonumber(kv.increased) == 1 then
                        increasedN = increasedN + 1
                    end
                    if kv.skipped == "solo" and al >= allyNeed then
                        leakSolo = leakSolo + 1
                    end
                end
            end
            lines[#lines + 1] = "—— 多人矩阵 ——"
            lines[#lines + 1] = string.format(
                "非 refresh 样本 %d：increased=1 有 %d，skip solo %d，allies 最大 %d（DBC 需 ≥%d 名友方，不含自己）。",
                chanceN, increasedN, skipSolo, maxAllies, allyNeed)
            local parts = {}
            for al = 0, math.max(maxAllies, 2) do
                parts[#parts + 1] = string.format("allies=%d×%d", al, byAllies[al] or 0)
            end
            lines[#lines + 1] = "按 allies 计数：" .. table.concat(parts, "，")
            if chanceN > 0 and increasedN == 0 and maxAllies == 0 then
                local rate = skipSolo / chanceN
                if chanceN < minSample then
                    lines[#lines + 1] = string.format(
                        "单人基线样本 <%d，solo 占比 %.0f%%，8%%–28%% 区间暂不判（方案矩阵 #1）。",
                        minSample, rate * 100)
                elseif rate >= bandLo and rate <= bandHi then
                    lines[#lines + 1] = string.format(
                        "单人 solo 占比 %.0f%%，落在 8%%–28%% 提示带内。", rate * 100)
                else
                    lines[#lines + 1] = string.format(
                        "单人 solo 占比 %.0f%%，在 8%%–28%% 之外（样本≥%d 才算失败）。",
                        rate * 100, minSample)
                end
            elseif increasedN > 0 then
                lines[#lines + 1] = "已走到 increased=1 多人分支。矩阵 #3：allies≥2 时应零 skip solo。"
            end
            if leakSolo > 0 then
                lines[#lines + 1] = string.format(
                    "异常：allies≥%d 仍 skipped=solo ×%d。", allyNeed, leakSolo)
            end
            lines[#lines + 1] =
                "待进游戏验收：#1 单人≥60；#2 1 名友方（DBC 字面可能 skip）；#3 两名友方应全 increased；#4–9 无光环/超距/死亡/敌对/refresh/跨相位。"
            return lines
        end,
    },

    expedient = {
        key = "expedient",
        title = "权宜之计",
        order = 10,
        serverCmd = ".lab test expedient",
        snapshotOnStart = true,
        snapshotSpell = 315544,
        -- 清单：一段 Dummy ×1.06 急速来源。面板增量≈原急速×0.06，不是 +6 个百分点。
        expect = { stat = "haste", minDelta = 1 },
        hint = "挂 315544。看急速来源 +6%。API：/dump GetHaste() 待验存在性。",
        startText = "【权宜之计】已挂 315544。对比开测快照，急速应涨约 6 个百分点（来源乘算，先看有明显增量）。",
        startPrint = "已挂 315544 并卸其他腐蚀测包。看急速。",
        ids = { 315544, 315545, 315546, 320257 },
        labels = { [315544] = "一段驱动", [315545] = "二段", [315546] = "三段", [320257] = "hidden急速" },
        chain = {
            { id = 315544, role = "驱动", want = "aura-self", hidden = true,
              hintFail = "buff 栏看不到 315544 是正常的（隐藏）。服务器应有 labexpedient: 315544；本包看急速快照。" },
            { id = 315544, role = "急速+6%", want = "stat",
              expect = { stat = "haste", minDelta = 1 },
              hintFail = "急速没涨到约 +6 个百分点。效果是来源×1.06，面板增量可能小于 6。把快照数字贴回来。" },
        },
        extraVerdict = function()
            return {
                "2026-08-28 第 1 层通过（面板）：急速 1945 [+28.60%] → 2061 [+30.31%] = ×1.06。零脚本。",
                "人物面板 29%→30% 是四舍五入。插件 minDelta=6 会误判失败（来源乘算只多约 1.7 个百分点）。真装 P5。",
                "「对当前目标 85%」两张一样，与权宜之计无关。",
            }
        end,
    },

    masterful = {
        key = "masterful",
        title = "娴熟",
        order = 11,
        serverCmd = ".lab test masterful",
        snapshotOnStart = true,
        snapshotSpell = 315529,
        expect = { stat = "mastery", minDelta = 6 },
        hint = "挂 315529。精通来源 +6%。Icy Veins 8/12/16 作废，35662 是 6/9/12。",
        startText = "【娴熟】已挂 315529。精通应涨约 6 个百分点。",
        startPrint = "已挂 315529。看精通。",
        ids = { 315529, 315530, 315531, 320253 },
        labels = { [315529] = "一段驱动", [315530] = "二段", [315531] = "三段", [320253] = "hidden精通" },
        chain = {
            { id = 315529, role = "驱动", want = "aura-self", hidden = true,
              hintFail = "buff 栏看不到 315529 是正常的。服务器应有 labmasterful: 315529；本包看精通快照。" },
            { id = 315529, role = "精通+6%", want = "stat",
              expect = { stat = "mastery", minDelta = 6 },
              hintFail = "精通没涨到约 +6 个百分点。来源×1.06，增量可能小于 6。/dump GetMasteryEffect()。" },
        },
        extraVerdict = function()
            return {
                "2026-08-28 第 1 层通过（玩家确认面板）。一段 Dummy ×1.06 精通来源。零脚本。真装 P5。",
            }
        end,
    },

    versatile = {
        key = "versatile",
        title = "多才多艺",
        order = 12,
        serverCmd = ".lab test versatile",
        snapshotOnStart = true,
        snapshotSpell = 315549,
        expect = { stat = "vers", minDelta = 6 },
        hint = "挂 315549。全能来源 +6%。",
        startText = "【多才多艺】已挂 315549。全能应涨约 6 个百分点。",
        startPrint = "已挂 315549。看全能。",
        ids = { 315549, 315552, 315553, 320259 },
        labels = { [315549] = "一段驱动", [315552] = "二段", [315553] = "三段", [320259] = "hidden全能" },
        chain = {
            { id = 315549, role = "驱动", want = "aura-self", hidden = true,
              hintFail = "buff 栏看不到 315549 是正常的。服务器应有 labversatile: 315549；本包看全能快照。" },
            { id = 315549, role = "全能+6%", want = "stat",
              expect = { stat = "vers", minDelta = 6 },
              hintFail = "全能没涨到约 +6 个百分点。来源×1.06，增量可能小于 6。" },
        },
        extraVerdict = function()
            return {
                "2026-08-28 第 1 层通过（玩家确认面板）。一段 Dummy ×1.06 全能来源。零脚本。真装 P5。",
            }
        end,
    },

    severe = {
        key = "severe",
        title = "暴戾",
        order = 13,
        serverCmd = ".lab test severe",
        snapshotOnStart = true,
        snapshotSpell = 315554,
        expect = { stat = "crit", minDelta = 6 },
        hint = "挂 315554。暴击来源 +6%。",
        startText = "【暴戾】已挂 315554。暴击应涨约 6 个百分点。",
        startPrint = "已挂 315554。看暴击。",
        ids = { 315554, 315557, 315558, 320261 },
        labels = { [315554] = "一段驱动", [315557] = "二段", [315558] = "三段", [320261] = "hidden暴击" },
        chain = {
            { id = 315554, role = "驱动", want = "aura-self", hidden = true,
              hintFail = "buff 栏看不到 315554 是正常的。服务器应有 labsevere: 315554；本包看暴击快照。" },
            { id = 315554, role = "暴击+6%", want = "stat",
              expect = { stat = "crit", minDelta = 6 },
              hintFail = "暴击没涨到约 +6 个百分点。来源×1.06，增量可能小于 6。/dump GetCritChance()。" },
        },
        extraVerdict = function()
            return {
                "2026-08-28 第 1 层通过（玩家确认面板）。一段 Dummy ×1.06 暴击来源。零脚本。真装 P5。",
            }
        end,
    },

    siphoner = {
        key = "siphoner",
        title = "虹吸者",
        order = 14,
        serverCmd = ".lab test siphoner",
        snapshotOnStart = true,
        snapshotSpell = 315590,
        expect = { stat = "lifesteal", minDelta = 3 },
        hint = "挂 315590。吸血 +3%（一段 Dummy，不是 Icy Veins 的 2%）。",
        startText = "【虹吸者】已挂 315590。吸血应涨约 3。",
        startPrint = "已挂 315590。看吸血。",
        ids = { 315590, 315591, 315592 },
        labels = { [315590] = "一段驱动", [315591] = "二段", [315592] = "三段" },
        chain = {
            { id = 315590, role = "驱动", want = "aura-self", hidden = true,
              hintFail = "buff 栏看不到 315590 是正常的。服务器应有 labsiphoner: 315590；本包看吸血快照。" },
            { id = 315590, role = "吸血+3%", want = "stat",
              expect = { stat = "lifesteal", minDelta = 3 },
              hintFail = "吸血没涨到约 +3。一段 Dummy 是 3%，不是 Icy Veins 的 2%。/dump GetLifesteal()。" },
        },
        extraVerdict = function()
            return {
                "核心 443 已接到 UpdateLeechPercentage。/dump GetLifesteal() 一段应约为 3，不是 Icy Veins 的 2。",
                "回血走 DealHeal，战斗记录没有治疗行是预期（2026-08-29 已接受）。看生命值，不要只靠 CLEU。不要写死 3/5/8。",
            }
        end,
    },

    strikethrough = {
        key = "strikethrough",
        title = "击穿",
        order = 15,
        serverCmd = ".lab test strikethrough",
        snapshotOnStart = true,
        snapshotSpell = 320249,
        hint = "挂 315277 → hidden 320249。暴击伤害 +2%（Dummy，禁止写死）。看暴击 CLEU，不是暴击%。",
        startText = "【击穿】已挂 315277。320249 BP 在 DBC 为 0，脚本从驱动 Dummy 填。打桩看暴击伤。",
        startPrint = "已挂 315277。看 320249 与暴击 CLEU。",
        ids = { 315277, 315281, 315282, 320249 },
        labels = { [315277] = "一段驱动", [315281] = "二段", [315282] = "三段", [320249] = "hidden暴击伤" },
        chain = {
            { id = 315277, role = "驱动", want = "aura-self", hidden = true,
              hintFail = "buff 栏看不到 315277 是正常的。服务器应有 labstrikethrough: 315277。" },
            { id = 320249, role = "hidden暴击伤", want = "aura-self", hidden = true,
              hintFail = "buff 栏看不到 320249 是正常的（隐藏）。以剑刃风暴暴击/非暴击是否约 2.04 为准。" },
        },
        extraVerdict = function(self)
            return {
                "2026-08-28 第 1 层通过：剑刃风暴 4211 → 暴击 8590（÷4211=2.040）。无击穿时同技能 4211→8422（恰好 2.00）。8422×1.02=8590。",
                "labstrikethrough: 315277 已挂。插件看不见隐藏 320249 不挡关账。治疗暴击 +4% 未测。真装 P5。",
            }
        end,
    },

    avoidant = {
        key = "avoidant",
        title = "闪避者",
        order = 16,
        serverCmd = ".lab test avoidant",
        snapshotOnStart = true,
        snapshotSpell = 315607,
        expect = { stat = "avoidance", minDelta = 0.01 },
        hint = "挂 315607。闪避 = 急速的 8%（再经 CombatRatings 表换算，面板不是显示 8）。",
        startText = "【闪避者】已挂 315607。35662 Dummy 8/12/16，不是 Icy Veins 5/8/10。",
        startPrint = "已挂 315607。看闪避。/dump GetAvoidance()。",
        ids = { 315607, 315608, 315609 },
        labels = { [315607] = "一段驱动", [315608] = "二段", [315609] = "三段" },
        chain = {
            { id = 315607, role = "驱动", want = "aura-self", hidden = true,
              hintFail = "buff 栏看不到 315607 是正常的。服务器应有 labavoidant: 315607；本包看闪避快照。" },
            { id = 315607, role = "闪避随急速", want = "stat",
              expect = { stat = "avoidance", minDelta = 0.01 },
              hintFail = "闪避没变。不是 0×8%：转换源是急速。/dump GetAvoidance() 应非 0，不要指望显示 8。" },
        },
        extraVerdict = function()
            return {
                "核心 198 已接到 UpdateRating：闪避 rating = 急速 rating × Amount%。不要写死 8/12/16。",
                "/dump GetAvoidance() 是 CombatRatings 换算后的百分比。摘 315607 应回 0；改急速应跟着变。",
            }
        end,
    },

    pulse = {
        key = "pulse",
        title = "急速脉搏",
        order = 6,
        serverCmd = ".lab test pulse",
        snapshotOnStart = true,
        snapshotSpell = 318227,
        expect = { stat = "hasteRating", minDelta = 546 },
        hint = "挂 318220。平砍或技能都能 proc（RPPM 5）。\n318227 急速 rating +546，4 秒，不叠层。",
        startText = "【急速脉搏】已挂 318220。平砍或黄字打木桩。proc 写成 PULSE_PROC，buff 是 318227。",
        startPrint = "已挂 318220。平砍或技能都能开脉搏。看 318227 与急速 rating +546。",
        ids = { 318266, 318492, 318496, 318220, 318227 },
        labels = {
            [318266] = "一段驱动",
            [318492] = "二段驱动",
            [318496] = "三段驱动",
            [318220] = "隐藏proc",
            [318227] = "急速buff",
        },
        chain = {
            { id = 318220, role = "隐藏proc", want = "aura-self", hidden = true,
              hintFail = "buff 栏看不到 318220 是正常的（隐藏光环）。服务器应有 labpulse: 318220；本包看 PULSE_PROC。" },
            { id = 318220, role = "开脉搏", want = "labmsg", labType = "PULSE_PROC", procStep = true,
              hintFail = "没有 PULSE_PROC。平砍或猛击打一会儿（RPPM 5，含白字）。" },
            { id = 318227, role = "急速buff", want = "aura-self",
              hintFail = "有 PULSE_PROC 但自己没有 318227。脚本 CastSpell 没挂上。" },
            { id = 318227, role = "急速rating+546", want = "stat",
              expect = { stat = "hasteRating", minDelta = 546 },
              hintFail = "有 318227 但急速 rating 没涨到约 +546。一段 Dummy，禁止写死主路径。" },
        },
        extraVerdict = function()
            return {
                "2026-08-28 第 1 层通过：PULSE_PROC rating=546；面板 hasteRating +557（过 minDelta 546）。",
                "末次触发到掉约 4s；二次 proc 刷新不叠层。插件「持续」从首次上算，刷新会拉长。",
                "第二次 proc 对齐普攻，白字可触发。真装驱动 P5 再验。",
            }
        end,
    },

    mind = {
        key = "mind",
        title = "磨砺心灵",
        order = 7,
        serverCmd = ".lab test mind",
        snapshotOnStart = true,
        snapshotSpell = 318216,
        expect = { stat = "masteryRating", minDelta = 392 },
        hint = "挂 318214。平砍或技能都能 proc（RPPM 3）。\n318216 精通 rating +392，10 秒，不叠层。",
        startText = "【磨砺心灵】已挂 318214。平砍或黄字打木桩。proc 写成 MIND_PROC，buff 是 318216。",
        startPrint = "已挂 318214。平砍或技能都能开心灵。看 318216 与精通 rating +392。",
        ids = { 318269, 318494, 318498, 318214, 318216 },
        labels = {
            [318269] = "一段驱动",
            [318494] = "二段驱动",
            [318498] = "三段驱动",
            [318214] = "隐藏proc",
            [318216] = "精通buff",
        },
        chain = {
            { id = 318214, role = "隐藏proc", want = "aura-self", hidden = true,
              hintFail = "buff 栏看不到 318214 是正常的（隐藏光环）。服务器应有 labmind: 318214；本包看 MIND_PROC 与 318216。" },
            { id = 318214, role = "开心灵", want = "labmsg", labType = "MIND_PROC", procStep = true,
              hintFail = "没有 MIND_PROC。平砍或猛击打一会儿（RPPM 3，含白字）。" },
            { id = 318216, role = "精通buff", want = "aura-self",
              hintFail = "有 MIND_PROC 但自己没有 318216。脚本 CastSpell 没挂上。" },
            { id = 318216, role = "精通rating+392", want = "stat",
              expect = { stat = "masteryRating", minDelta = 392 },
              hintFail = "有 318216 但精通 rating 没涨到约 +392。一段 Dummy，禁止写死主路径。" },
        },
        extraVerdict = function()
            return {
                "2026-08-28 第 1 层通过：`MIND_PROC rating=392 ok=1`；快照精通 rating 694→1086（+392）。白字可 proc。",
                "第二次 proc 约 3 秒后刷新：34.5s 挂上、47.4s 掉，墙钟 12.8s，从刷新起约 10s。无叠层。真装驱动 P5。",
                "早先 rating 判失败是 HavenLab 掉光后不重拍基线，不是脚本没填精通。",
            }
        end,
    },

    momentum = {
        key = "momentum",
        title = "致命之势",
        order = 8,
        serverCmd = ".lab test momentum",
        snapshotOnStart = true,
        snapshotSpell = 318219,
        expect = { stat = "critRating", minDelta = 31 },
        hint = "挂 318218。只有暴击才 proc（RPPM 5）。\n318219 暴击 rating +31/层，最多 5 层，30 秒。",
        startText = "【致命之势】已挂 318218。打出暴击。proc 写成 MOMENTUM_PROC，buff 是 318219。",
        startPrint = "已挂 318218。只有暴击开致命之势。看 318219 与暴击 rating +31。",
        ids = { 318268, 318493, 318497, 318218, 318219 },
        labels = {
            [318268] = "一段驱动",
            [318493] = "二段驱动",
            [318497] = "三段驱动",
            [318218] = "隐藏proc",
            [318219] = "暴击buff",
        },
        chain = {
            { id = 318218, role = "隐藏proc", want = "aura-self", hidden = true,
              hintFail = "buff 栏看不到 318218 是正常的（隐藏光环）。服务器应有 labmomentum: 318218；本包看 MOMENTUM_PROC。" },
            { id = 318218, role = "开致命", want = "labmsg", labType = "MOMENTUM_PROC", procStep = true,
              hintFail = "没有 MOMENTUM_PROC。打出暴击（平击不应进，也不应吃掉 RPPM）。" },
            { id = 318219, role = "暴击buff", want = "aura-self",
              hintFail = "有 MOMENTUM_PROC 但自己没有 318219。脚本 CastSpell 没挂上。" },
            { id = 318219, role = "暴击rating+31", want = "stat",
              expect = { stat = "critRating", minDelta = 31 },
              hintFail = "有 318219 但暴击 rating 没涨到约 +31。一段 Dummy，禁止写死主路径。" },
        },
        extraVerdict = function(self)
            local lines = {
                "2026-08-28 第 1 层通过：仅暴击进；1→5 层 rating=31/62/93/124/155；满层后再 proc 仍 5。",
                "快照 critRating +32 是第一层 Dummy。满层引擎乘层应为 +155。停手 30s 掉光未测。",
                "CalcAmount 只填每层 Dummy，引擎再乘层。脚本不要自己 Dummy×层。",
            }
            if self and self.LabMessages then
                local procs = self:LabMessages("MOMENTUM_PROC") or {}
                local maxStacks, bad = 0, 0
                for i = 1, #procs do
                    local kv = procs[i].kv or {}
                    local st = tonumber(kv.stacks) or 0
                    local rt = tonumber(kv.rating) or 0
                    if st > maxStacks then maxStacks = st end
                    if st >= 1 and rt ~= st * 31 then
                        bad = bad + 1
                    end
                end
                if #procs > 0 then
                    lines[#lines + 1] = string.format(
                        "MOMENTUM_PROC %d 次，层数最高 %d（DBC 上限 5）。", #procs, maxStacks)
                    if bad > 0 then
                        lines[#lines + 1] = string.format(
                            "%d 次 rating 不是层×31（二段/三段或通知乘层对不上）。", bad)
                    end
                end
            end
            return lines
        end,
    },

    vitality = {
        key = "vitality",
        title = "活力涌动",
        order = 9,
        serverCmd = ".lab test vitality",
        snapshotOnStart = true,
        snapshotSpell = 318211,
        expect = { stat = "versRating", minDelta = 343 },
        hint = "挂 318212。木桩打不出。站会还手的怪或挨 DoT。\n318211 全能 rating +343（Scaled，不是 Icy Veins 312），20 秒。",
        startText = "【活力涌动】已挂 318212。去挨打，不要打木桩。proc 写成 VITAL_PROC，buff 是 318211。",
        startPrint = "已挂 318212。木桩测不出。站怪堆挨打。看 318211 与全能 rating +343。",
        ids = { 318270, 318495, 318499, 318212, 318211 },
        labels = {
            [318270] = "一段驱动",
            [318495] = "二段驱动",
            [318499] = "三段驱动",
            [318212] = "隐藏proc",
            [318211] = "全能buff",
        },
        chain = {
            { id = 318212, role = "隐藏proc", want = "aura-self", hidden = true,
              hintFail = "buff 栏看不到 318212 是正常的（隐藏光环）。服务器应有 labvitality: 318212；本包看 VITAL_PROC 与 318211。" },
            { id = 318212, role = "开涌动", want = "labmsg", labType = "VITAL_PROC", procStep = true,
              hintFail = "没有 VITAL_PROC。木桩打不出；站会还手的怪或自己挨 DoT（RPPM 2，taken）。有 318211 但没有本条时，多半是 DBC 默认 TriggerSpell 挂上的，OnProc 没跑到。" },
            { id = 318211, role = "全能buff", want = "aura-self",
              hintFail = "有 VITAL_PROC 但自己没有 318211。脚本 CastSpell 没挂上（taken 目标应是自己）。" },
            { id = 318211, role = "全能rating+343", want = "stat",
              expect = { stat = "versRating", minDelta = 343 },
              hintFail = "有 318211 但全能 rating 没涨到约 +343。一段 Scaled，禁止用 Icy Veins 312。" },
        },
        extraVerdict = function()
            return {
                "2026-08-28 第 1 层通过：318211 约 20s；首次快照 versRating +350。掉光约 11.5s 后再挂，仍约 20s、不叠层。",
                "没有 VITAL_PROC：buff 更像 DBC 默认 TriggerSpell 打上的。不挡玩法过线。",
                "第二次报告全能 -9 是插件用「增益还在时」的旧快照当基线，不是 buff 没加。增益还在时刷新未测。真装 P5。",
            }
        end,
    },

    wound = {
        key = "wound",
        title = "龟裂创伤",
        order = 17,
        serverCmd = ".lab test wound",
        hint = "挂 318179。用黄字打**活怪**（平砍不开）。\n团本训练假人是机械体，318187 流血会 IMMUNE。\n跳伤 Dummy 13% × max(AP,SP)，不要 ÷7。",
        startText = "【龟裂创伤】已挂 318179。黄字打活怪，不要打团本桩。proc 写成 WOUND_PROC，跳伤写成 WOUND_TICK。",
        startPrint = "已挂 318179。用黄字打活怪。团本桩会对 318187 免疫。平砍不开。",
        ids = { 318272, 318179, 318187 },
        labels = {
            [318272] = "一段驱动",
            [318179] = "隐藏proc",
            [318187] = "渗血DoT",
        },
        chain = {
            { id = 318179, role = "隐藏proc", want = "aura-self", hidden = true,
              hintFail = "buff 栏看不到 318179 是正常的（隐藏光环）。服务器应有 labwound: 318179；本包看 WOUND_PROC 与 318187。" },
            { id = 318179, role = "开渗血", want = "labmsg", labType = "WOUND_PROC", procStep = true,
              hintFail = "没有 WOUND_PROC。用猛击等黄字打活怪（RPPM 4，平砍不开）。CLEU 有 318187 IMMUNE 说明团本桩吃不下流血。" },
            { id = 318187, role = "渗血跳伤", want = "damage",
              expect = { school = 32 },
              hintFail = "没有 318187 暗影跳伤。团本桩会 IMMUNE；换活怪。有施放无跳伤则是目标免疫，不是没 proc。" },
        },
        extraVerdict = function()
            return {
                "2026-08-28 第 1 层通过：活怪上 318187 暗影跳伤。第一段/海盗段约 7s、7 跳；非暴击 1421/1564 = Dummy 13%×攻强，暴击刚好两倍。",
                "平砍不开；团本桩 IMMUNE。上一份 WOUND_PROC 4 次；本份跳伤在、通知可能没进（不挡过线）。",
                "早先同帧上/掉是怪在逃跑清光环，不是时长 0。刷新未单独测。真装系数 2.37 走 P5。",
            }
        end,
    },

    glimpse = {
        key = "glimpse",
        title = "须臾洞察",
        order = 18,
        serverCmd = ".lab test glimpse",
        hint = "挂 315574。平砍或技能开 Glimpse（RPPM 2）。\n出现 315573 后放有 CD 的职业技能，CD −3s，buff 减层。",
        startText = "【须臾洞察】已挂 315574。等 315573 出现后放奥爆等有 CD 技能。减 CD 写成 CD_TRIM。",
        startPrint = "已挂 315574。等 Glimpse 出现后放有 CD 的职业技能。看 CD_TRIM before−after=3000。",
        ids = { 318239, 315574, 315573 },
        labels = {
            [318239] = "物品入口",
            [315574] = "隐藏proc",
            [315573] = "Glimpse",
        },
        chain = {
            { id = 315574, role = "隐藏proc", want = "aura-self", hidden = true,
              hintFail = "buff 栏看不到 315574 是正常的（隐藏光环）。服务器应有 labglimpse: 315574；本包看 315573 与 CD_TRIM。" },
            { id = 315573, role = "Glimpse", want = "aura-self", procStep = true,
              hintFail = "没有 315573。平砍或技能打一会儿（RPPM 2）。DBC Trigger 应自己挂上。" },
            { id = 315573, role = "CD-3s", want = "labmsg", labType = "CD_TRIM",
              expect = { trimMs = 3000 },
              hintFail = "有 315573 但没有 CD_TRIM。能用 .lab 的号会出黄字，不用开 GM。也可看转盘是否 −3s。不要放物品/腐蚀技能。" },
        },
        extraVerdict = function()
            return {
                "2026-08-28 第 1 层通过：315573 会挂、白字可 proc、可叠层。有 CD 技能减层并 −3s（玩家看转盘确认）；无 CD 技能不减层。",
                "能用 .lab 的号会出 CD_TRIM 黄字，不用开 GM。自然 15 秒掉光未测。不要开冷却作弊。真装 P5。",
                "不要和法器 Flash of Insight 混。6486 vs 6546 第 1 层不选定。",
            }
        end,
    },

    truth = {
        key = "truth",
        title = "不可言喻的真相",
        order = 19,
        serverCmd = ".lab test truth",
        hint = "挂 316799。技能/治疗/敌对法术可 proc（RPPM 1，无白字）。\n316801 10 秒，职业技能 CD 恢复 +30%。",
        startText = "【不可言喻的真相】已挂 316799。打桩等 316801。RECHARGE pct=30。",
        startPrint = "已挂 316799。等 316801 后放有 CD 的职业技能，看转盘变快。RECHARGE pct=30。",
        ids = { 318303, 318484, 316799, 316801 },
        labels = {
            [318303] = "一段驱动",
            [318484] = "二段驱动",
            [316799] = "隐藏proc",
            [316801] = "加速buff",
        },
        chain = {
            { id = 316799, role = "隐藏proc", want = "aura-self", hidden = true,
              hintFail = "buff 栏看不到 316799 是正常的（隐藏光环）。服务器应有 labtruth: 316799；本包看 316801 与 RECHARGE。" },
            { id = 316801, role = "加速buff", want = "aura-self", procStep = true,
              hintFail = "没有 316801。技能打一会儿（RPPM 1，无白字）。DBC Trigger 应自己挂上。" },
            { id = 316801, role = "RECHARGE", want = "labmsg", labType = "RECHARGE",
              expect = { pct = 30 },
              hintFail = "有 316801 但没有 RECHARGE pct=30。能用 .lab 的号会出黄字，不用开 GM。也可看转盘是否按 100/(100+30) 变短。" },
        },
        extraVerdict = function()
            return {
                "2026-08-28 第 1 层通过：316801 约 10 秒自然掉；`RECHARGE pct=30 mult=76`（100/130）。Lab 只挂 316799 时回退 Dummy 30。",
                "上一份：黄字可 proc。能用 .lab 的号会出 RECHARGE，不用开 GM。已有 buff 再 proc、二段 Dummy 50（.aura 318484）未测。真装 P5。",
                "不要用剑刃风暴后的巨人打击间隔当证据（怒气管理会砍冷却）。",
            }
        end,
    },

    grasping = {
        key = "grasping",
        title = "蔓生触须",
        order = 20,
        serverCmd = ".lab test grasping",
        hint = "挂 315175。木桩打不出。站会还手的怪挨打（不要 .damage）。\n315176 减速 5 秒。能用 .lab 的号会出 TENDRIL_SLOW，不用开 GM。开「移速」看 SPEED。",
        startText = "【蔓生触须】已挂 315175。去挨打，不要打木桩。减速写成 TENDRIL_SLOW。",
        startPrint = "已挂 315175。木桩测不出。挨打看 315176 与 TENDRIL_SLOW。开移速监控看 SPEED。",
        ids = { 315175, 315176 },
        labels = {
            [315175] = "触须驱动",
            [315176] = "减速",
        },
        chain = {
            { id = 315175, role = "驱动", want = "aura-self",
              hintFail = "没挂上 315175。用 .lab test grasping / .labgrasping。真装要有效腐蚀≥1 才由 UpdateCorruption 挂上。" },
            { id = 315175, role = "开减速", want = "labmsg", labType = "TENDRIL_SLOW", procStep = true,
              hintFail = "没有 TENDRIL_SLOW。能用 .lab 的号会出黄字，不用开 GM。玩法看自己有没有 315176。不要 .damage。" },
            { id = 315176, role = "减速", want = "aura-self",
              hintFail = "有 TENDRIL_SLOW 但自己没有 315176。脚本 CastCustomSpell 没挂上。" },
        },
        extraVerdict = function()
            return {
                "2026-08-28：活怪挨打后 315176 会挂约 5 秒。能用 .lab 的号会出 TENDRIL_SLOW，不用开 GM。",
                "空地、无其他减速时看 SPEED 100%→约 90%（有效腐蚀+10）。铁潮现场移速会被污染。",
                "热修后不是魔法，驱散魔法清不掉。不要在脚本里写腐蚀阈值比较。",
                "GetCorruption /dump 待验。阈值矩阵应挂 315175（DB2 MinCorruption 1）。",
            }
        end,
    },

    eye = {
        key = "eye",
        title = "腐蚀之眼",
        order = 21,
        serverCmd = ".lab test eye",
        hint = "挂 315169。用技能打木桩（不是挨打）。\n走进眼睛等 2 秒看 EYE_PULSE / 315161，不是找生物。315270 是宠物，不要测。",
        startText = "【腐蚀之眼】已挂 315169。用技能打木桩。出眼写成 EYE_PROC，靠近跳写成 EYE_PULSE。",
        startPrint = "已挂 315169。技能打木桩等 EYE_PROC。走进去看 EYE_PULSE inrange=1。",
        ids = { 315169 },
        labels = {
            [315169] = "眼驱动",
        },
        summonEntries = {},
        chain = {
            { id = 315169, role = "驱动", want = "aura-self",
              hintFail = "没挂上 315169。用 .lab test eye / .labeye。真装要有效腐蚀≥20 才由 UpdateCorruption 挂上。" },
            { id = 315169, role = "出眼", want = "labmsg", labType = "EYE_PROC", procStep = true,
              hintFail = "没有 EYE_PROC。用技能打（RPPM 1，黄字）。trigger=0 说明 DBC TriggerSpell 空。" },
            { id = 315169, role = "靠近跳", want = "labmsg", labType = "EYE_PULSE",
              hintFail = "有 EYE_PROC 但没有 EYE_PULSE。走进眼睛等 2 秒看 315161，不是找生物。能用 .lab 的号会出黄字，不用开 GM。" },
        },
        extraVerdict = function()
            return {
                "315154 是区域触发器（模板 22815）。走近才跳 315161，走开停。不要找召唤生物。",
                "约 8 秒、每约 2 秒一跳。不要写 Wowhead 875×腐蚀−1000。驱动隐藏不挡。",
                "阈值矩阵应挂 315169（DB2 MinCorruption 20）。脚本不写阈值比较。",
            }
        end,
    },

    delusion = {
        key = "delusion",
        title = "宏伟妄想",
        order = 22,
        serverCmd = ".lab test delusion",
        hint = "挂 315184。木桩打不出。站会还手的活怪挨打（不要 .damage）。\n彼岸之物约 20 码外生成，追约 8 秒，碰到才结算。能用 .lab 的号会出黄字，不用开 GM。不要测披风 313301。",
        startText = "【宏伟妄想】已挂 315184。去挨活怪，不要打木桩、不要 .damage。出怪写成 DELUSION_PROC，碰到写成 DELUSION_HIT。",
        startPrint = "已挂 315184。活怪挨打。看粉红倒影 / DELUSION_PROC，被追上碰看 DELUSION_HIT。",
        ids = { 315184 },
        labels = {
            [315184] = "妄想驱动",
        },
        summonEntries = {},
        chain = {
            { id = 315184, role = "驱动", want = "aura-self",
              hintFail = "没挂上 315184。用 .lab test delusion / .labdelusion。真装要有效腐蚀≥40 才由 UpdateCorruption 挂上。" },
            { id = 315184, role = "出彼岸之物", want = "labmsg", labType = "DELUSION_PROC", procStep = true,
              hintFail = "没有 DELUSION_PROC。须活怪还手，不要 .damage。能用 .lab 的号会出黄字，不用开 GM。没有通知但看得见倒影仍算第 1 层过。" },
            { id = 315184, role = "碰到结算", want = "labmsg", labType = "DELUSION_HIT",
              hintFail = "有 DELUSION_PROC 但没有 DELUSION_HIT。可能没召唤出生物、entry 待回填，或 8 秒内没被追上。" },
        },
        extraVerdict = function()
            return {
                "待进游戏验收：约 8 秒（DBC duration，缺则 8000ms fallback）。碰到走 melee reach，不射线。",
                "不要用 313301 披风周期召唤。NPC ID 进游戏 .lookup creature 彼岸之物，不要用 158041。",
                "summonEntries / 伤害法术 ID 进游戏 CLEU 回填。速度随腐蚀升：先信 DBC，缩放待验。",
                "可见性「自己+同效果者」当前做不了，全可见并登记偏差。会拉怪。",
                "阈值矩阵应挂 315184（DB2 MinCorruption 40）。脚本不写阈值比较。",
            }
        end,
    },

    cascade = {
        key = "cascade",
        title = "层叠灾难",
        order = 23,
        serverCmd = ".lab test cascade",
        hint = "只挂 315857。不要再 .labdelusion（会清掉 315857）。\n补 .aura 315184 才能出彼岸之物。挨打被碰后看 CASCADE + TENDRIL_SLOW + EYE_PROC。",
        startText = "【层叠灾难】已挂 315857。再 .aura 315184，去挨打。被彼岸之物碰到写成 CASCADE。",
        startPrint = "已挂 315857。再 .aura 315184（不要 .labdelusion）。挨打被碰看 CASCADE。",
        ids = { 315857, 315176, 315169 },
        labels = {
            [315857] = "层叠驱动",
            [315176] = "触须减速",
            [315169] = "眼驱动",
        },
        summonEntries = {},
        chain = {
            { id = 315857, role = "驱动", want = "aura-self",
              hintFail = "没挂上 315857。用 .lab test cascade / .labcascade。真装要有效腐蚀≥60 才由 UpdateCorruption 挂上。" },
            { id = 315857, role = "命中层叠", want = "labmsg", labType = "CASCADE", procStep = true,
              hintFail = "没有 CASCADE。先 .aura 315184，站会还手的怪挨打，被追上碰到才会层叠。不要再打 .labdelusion（会卸 315857）。" },
            { id = 315176, role = "立刻减速", want = "labmsg", labType = "TENDRIL_SLOW",
              hintFail = "有 CASCADE 但没有 TENDRIL_SLOW。命中处应调用 CastGraspingTendrils，不是再套 315175。" },
            { id = 315169, role = "立刻出眼", want = "labmsg", labType = "EYE_PROC",
              hintFail = "有 CASCADE 但没有 EYE_PROC。命中处应调用 CastEyeOfCorruption，不是再套 315169。" },
        },
        extraVerdict = function()
            return {
                "待进游戏验收：被彼岸之物碰到立刻减速 + 出眼。不要再套 315175/315169。",
                "Lab 只挂 315857：必须另 .aura 315184，否则怪会因无妄想光环 despawn。",
                "要看 EYE_PULSE：再 .aura 315169（眼 AI 要 owner 有 315169，不是层叠门槛）。",
                "双端：只有被自己那只怪碰到的人出 CASCADE。脚本不写阈值比较。",
                "阈值矩阵应挂 315857（DB2 MinCorruption 60）。315857 无独立 spell_script_names。",
            }
        end,
    },

    doom = {
        key = "doom",
        title = "不可避免的厄运",
        order = 24,
        serverCmd = ".lab test doom",
        hint = "挂 315179。脚本按 Dummy×(有效腐蚀−50) 填三条 taken，下限 0。\n挂上/腐蚀变化会出 DOOM_PCT 黄字。挨打看伤害放大、治疗看减少、上盾看变薄。",
        startText = "【不可避免的厄运】已挂 315179。看 DOOM_PCT 黄字与三条 taken 幅度是否随有效腐蚀变。",
        startPrint = "已挂 315179。脚本已填幅度：X = 有效腐蚀 − 50（Wowhead 2019-10 实测表，热修白名单）。看 DOOM_PCT。",
        ids = { 315179 },
        labels = {
            [315179] = "厄运驱动",
        },
        chain = {
            { id = 315179, role = "驱动", want = "aura-self",
              hintFail = "没挂上 315179。用 .lab test doom / .labdoom。真装要有效腐蚀≥80 才由 UpdateCorruption 挂上。" },
            { id = 315179, role = "幅度已填", want = "labmsg", labType = "DOOM_PCT",
              hintFail = "没有 DOOM_PCT。脚本 CalcAmount 没跑：查 spell_script_names 是否有 spell_inevitable_doom，或重挂一次光环。" },
        },
        extraVerdict = function()
            return {
                "期望幅度：X = 有效腐蚀 − 50，下限 0。例：有效 80 → 30%，85 → 35%，测试挂 .aura（腐蚀 0）时 X=0 属正常。",
                "受伤放大为 +X%，治疗减少 / 吸收减少为 −X%。三条同值，来源 Wowhead 2019-10 实测表（热修白名单 2026-08-29）。",
                "腐蚀升降后 UpdateCorruption 重挂会重算幅度，DOOM_PCT 只在数值变化时再报一次。",
                "阈值矩阵应挂 315179（DB2 MinCorruption 80）。spell_script_names：spell_inevitable_doom。",
            }
        end,
    },

    consequences = {
        key = "consequences",
        title = "末路恶果",
        order = 25,
        serverCmd = ".lab test consequences",
        hint = "挂 337612。关 .cheat god。337612 周期触发字段为 0，脚本改为战斗中每跳施放 337816（数据里的 25% 最大生命）。\n进战斗立刻跳、每秒一跳并出 CONSEQ_TICK；脱战应停。",
        startText = "【末路恶果】已挂 337612。关无敌，进战斗看 337816 跳伤与 CONSEQ_TICK 黄字。",
        startPrint = "已挂 337612。关 god。进战斗看每秒约 25% 生命跳（337816），脱战应停止。",
        ids = { 337612, 337816 },
        labels = {
            [337612] = "恶果驱动",
            [337816] = "周期跳伤(25%最大生命)",
        },
        chain = {
            { id = 337612, role = "驱动", want = "aura-self",
              hintFail = "没挂上 337612。用 .lab test consequences / .labconsequences。真装要有效腐蚀≥200 才由 UpdateCorruption 挂上。" },
            { id = 337612, role = "战斗跳伤", want = "labmsg", labType = "CONSEQ_TICK", procStep = true,
              hintFail = "没有 CONSEQ_TICK。进战斗了吗？查 spell_script_names 是否有 spell_inescapable_consequences。" },
        },
        extraVerdict = function()
            return {
                "进战斗立刻跳一次，之后每秒一跳；CLEU 应有 337816，约 25% 最大生命（百分比读数据效果 165，脚本不手写 25）。",
                "脱战应停止跳伤；.cheat god 会吞伤害，验收前必须关。",
                "阈值矩阵应挂 337612（DB2 MinCorruption 200）。spell_script_names：spell_inescapable_consequences。",
            }
        end,
    },

    devour = {
        key = "devour",
        title = "吞噬活力",
        order = 30,
        serverCmd = ".lab test devour",
        hint = "只用平砍。技能打桩不应出 DEVOUR_PROC。",
        startText = "【测试开始】已挂 316615。对木桩平砍。看 DEVOUR_PROC 和 316617。",
        startPrint = "已挂 316615。平砍木桩。",
        ids = { 318294, 316615, 316617 },
        labels = {
            [318294] = "物品驱动",
            [316615] = "隐藏proc",
            [316617] = "吸血伤害",
        },
        chain = {
            { id = 316615, role = "隐藏proc", want = "aura-self", hidden = true,
              hintFail = "没挂上 316615。" },
            { id = 316617, role = "吸血", want = "labmsg", labType = "DEVOUR_PROC",
              procStep = true,
              hintFail = "平砍没有 DEVOUR_PROC。技能触发了反而说明掩码过宽。" },
        },
    },

    flash = {
        key = "flash",
        title = "灵光一闪（法器）",
        order = 31,
        serverCmd = ".lab test flash",
        hint = "挂上就该有 316744。施法后层数重滚 1–8，不是 +1。不要和 Glimpse 减 CD 搞混。",
        startText = "【测试开始】已挂 316717。看 316744 层数和面板智力。",
        startPrint = "已挂 316717。身上应立刻有 316744。",
        ids = { 318299, 316717, 316744, 315573 },
        labels = {
            [318299] = "物品驱动",
            [316717] = "隐藏proc",
            [316744] = "智力层",
            [315573] = "随机腐蚀Glimpse（不应出现）",
        },
        chain = {
            { id = 316717, role = "隐藏proc", want = "aura-self", hidden = true,
              hintFail = "没挂 316717。" },
            { id = 316744, role = "智力层", want = "labmsg", labType = "FLASH_ROLL",
              procStep = true,
              hintFail = "没有 FLASH_ROLL。挂上时就该立刻滚一层。" },
        },
    },

    whisper = {
        key = "whisper",
        title = "低语真相",
        order = 32,
        serverCmd = ".lab test whisper",
        hint = "猎人自动射击。先开一个职业技能让转盘转起来。",
        startText = "【测试开始】已挂 316780。自动射击，看 WHISPER_PROC。",
        startPrint = "已挂 316780。用自动射击。非猎人不应减 CD。",
        ids = { 316780, 316782 },
        labels = {
            [316780] = "隐藏proc",
            [316782] = "战斗记录",
        },
        chain = {
            { id = 316780, role = "隐藏proc", want = "aura-self", hidden = true,
              hintFail = "没挂 316780。" },
            { id = 316782, role = "减CD", want = "labmsg", labType = "WHISPER_PROC",
              procStep = true,
              hintFail = "自动射击没有 WHISPER_PROC。先让一个猎人技能在冷却中。" },
        },
    },

    lash = {
        key = "lash",
        title = "虚空之鞭",
        order = 33,
        serverCmd = ".lab test lash",
        hint = "只用平砍。猛击不应出 LASH_PROC。身后木桩不应吃锥伤。锥内第二只桩应吃满额，不均摊。",
        startText = "【测试开始】已挂 317290。对面前木桩平砍。看 LASH_PROC、317291 锥伤和 319241 减速。",
        startPrint = "已挂 317290。平砍面前木桩。猛击不应触发。",
        ids = { 317290, 317291, 319241 },
        labels = {
            [317290] = "隐藏proc",
            [317291] = "锥形暗影伤害",
            [319241] = "减速",
        },
        chain = {
            { id = 317290, role = "隐藏proc", want = "aura-self", hidden = true,
              hintFail = "没挂 317290。" },
            { id = 317291, role = "锥伤", want = "labmsg", labType = "LASH_PROC",
              procStep = true,
              hintFail = "平砍没有 LASH_PROC。猛击触发了反而说明掩码过宽。" },
        },
    },

    searing = {
        key = "searing",
        title = "灼热烈焰",
        order = 34,
        serverCmd = ".lab test searing",
        hint = "用伤害技能打。平砍和治疗不应叠层。第 30 次伤害技能立刻喷（不是第 31 次）。身后木桩不应吃锥伤。",
        startText = "【测试开始】已挂 316698。对面前木桩打伤害技能。看 SEARING_STACK；第 30 次出 SEARING_BREATH / 316704。",
        startPrint = "已挂 316698。打伤害技能叠层。平砍和治疗不应叠。.lab clear 后 316703 应跟着掉。",
        ids = { 318293, 316698, 316703, 316704 },
        labels = {
            [318293] = "物品驱动",
            [316698] = "隐藏proc",
            [316703] = "叠层",
            [316704] = "灼热吐息",
        },
        chain = {
            { id = 316698, role = "隐藏proc", want = "aura-self", hidden = true,
              hintFail = "没挂 316698。" },
            { id = 316703, role = "叠层", want = "labmsg", labType = "SEARING_STACK",
              procStep = true,
              hintFail = "伤害技能没有 SEARING_STACK。平砍或治疗叠了层 = 掩码过宽。" },
            { id = 316704, role = "喷焰", want = "labmsg", labType = "SEARING_BREATH",
              hintFail = "叠满 30 层没有 SEARING_BREATH。第 30 次伤害技能应立刻喷，不是第 31 次。" },
        },
    },

    obsidian = {
        key = "obsidian",
        title = "黑曜石皮肤",
        order = 35,
        serverCmd = ".lab test obsidian",
        hint = "挂 316651（LINKED 会挂上 317420）。进战斗看层涨；到 30 层出 OBSIDIAN_BOOM / 316661。脱战层应还在。20 码外不应吃。",
        startText = "【测试开始】已挂 316651。进战斗看 OBSIDIAN_TICK；满 30 层出 OBSIDIAN_BOOM / 316661。脱战层应保留。",
        startPrint = "已挂 316651。进战斗叠层。脱战不掉层。满层爆炸按当前护甲×Dummy3。",
        ids = { 316651, 317420, 316661 },
        labels = {
            [316651] = "黑曜石皮肤(+5%护甲)",
            [317420] = "毁灭叠层",
            [316661] = "爆炸伤害",
        },
        chain = {
            { id = 316651, role = "驱动", want = "aura-self",
              hintFail = "没挂 316651。" },
            { id = 317420, role = "叠层", want = "labmsg", labType = "OBSIDIAN_TICK",
              procStep = true,
              hintFail = "没有 OBSIDIAN_TICK。进战斗了吗？脱战不会加层，层应还在。" },
            { id = 316661, role = "爆炸", want = "labmsg", labType = "OBSIDIAN_BOOM",
              hintFail = "叠满 30 层没有 OBSIDIAN_BOOM。进战斗时已是 30 层应本跳就炸，不要再 +1。" },
        },
        extraVerdict = function()
            return {
                "进战斗才加层；脱战不摘 317420，层保留。不要和灼热吐息的 15%/6 分摊搞混。",
                "满 30 层本跳爆炸后回 1 层。护甲百分比读 316651 Dummy3（700），+5% 护甲零脚本。",
                "316661 是自身周围敌对（TargetB=15），20 码外不应吃。多人每额外目标 +15%、上限 6 分摊。",
            }
        end,
    },

    war_c_charge = {
        key = "war_c_charge",
        title = "战士共用-冲锋",
        order = 40,
        hint = "120 战士冲向满级假人。不要点腐蚀测试。",
        startText = "【冲锋】选中满级伤害假人，按冲锋 100。插件只观测，不会给你套腐蚀光环。",
        startPrint = "请对假人按冲锋 100。看 CLEU 的 100 与定身 105771。",
        ids = { 100, 105771, 218104, 198337 },
        labels = {
            [100] = "冲锋",
            [105771] = "冲锋定身",
            [218104] = "冲锋效果",
            [198337] = "燃烧轨迹冲锋效果",
        },
        chain = {
            { id = 100, role = "冲锋施法", want = "cast",
              hintFail = "没有 100。动作条没有冲锋，或选错目标。" },
            { id = 105771, role = "定身", want = "aura-target",
              hintFail = "冲锋打了但目标没有 105771。不要为此改 Spell.cpp。" },
        },
        extraVerdict = function()
            return {
                "冲锋 Energize 200 出 SpellEffect，显示为 20 点怒气。不要把 0.5 秒公共冷却写进脚本。",
                "枚举 SPELL_WARRIOR_CHARGE=34846 不是冲锋 100。",
            }
        end,
    },

    war_c_rally = {
        key = "war_c_rally",
        title = "战士共用-集结呐喊",
        order = 41,
        hint = "按 97462。不要找命令怒吼。",
        startText = "【集结呐喊】按 97462。自己或队友应出现 97463（约 10 秒、生命 +15%）。8.3 没有独立命令怒吼。",
        startPrint = "请按集结呐喊 97462。看 97463。不要测命令怒吼。",
        ids = { 97462, 97463 },
        labels = {
            [97462] = "集结呐喊",
            [97463] = "集结生命光环",
        },
        chain = {
            { id = 97462, role = "集结施法", want = "cast",
              hintFail = "没有 97462。运行库若仍把 97462 绑成 commanding_shout，先导入 2026_09_05_60。" },
            { id = 97463, role = "生命光环", want = "aura-self",
              hintFail = "没有 97463。Dummy 15 应由脚本读 GetEffectValue，不要写成现役 10%。" },
        },
        extraVerdict = function()
            return {
                "8.0.1 命令怒吼已改名为集结呐喊。不要再测第三条怒吼。",
                "40 码 / 10 秒 / 180 秒冷却出 DBC，不是 Dummy。",
            }
        end,
    },

    war_c_pummel = {
        key = "war_c_pummel",
        title = "战士共用-拳击",
        order = 42,
        hint = "打断看 SPELL_INTERRUPT。木桩不读条不算脚本坏了。",
        startText = "【拳击】对正在读条的敌对生物按 6552。木桩通常不读条。不要给 6552 写战士脚本。",
        startPrint = "请对读条目标按拳击 6552。无脚本不算失败。",
        ids = { 6552 },
        labels = {
            [6552] = "拳击",
        },
        chain = {
            { id = 6552, role = "拳击施法", want = "cast",
              hintFail = "没有 6552 施法。先确认动作条有拳击。" },
        },
        extraVerdict = function()
            return {
                "6552 在 SpellEffect 上就是打断（Effect=68），本表无 Dummy。无 spell_warr_pummel 不算失败。",
                "人测看 CLEU 的 SPELL_INTERRUPT。4 秒 / 15 秒出 DBC。",
            }
        end,
    },

    war_c_battle_shout = {
        key = "war_c_battle_shout",
        title = "战士共用-战斗怒吼",
        order = 43,
        hint = "6673 是攻强团队增益。不要改名成命令怒吼。",
        startText = "【战斗怒吼】按 6673。自身应有攻强光环。不要把它当成命令怒吼。",
        startPrint = "请按战斗怒吼 6673。",
        ids = { 6673 },
        labels = {
            [6673] = "战斗怒吼",
        },
        chain = {
            { id = 6673, role = "战斗怒吼", want = "aura-self",
              hintFail = "没有 6673。这是数据表光环，不要为此写空脚本。" },
        },
        extraVerdict = function()
            return {
                "6673 近战/远程攻强各 +10%，本表无 Dummy。1 小时 / 100 码出 DBC。",
            }
        end,
    },

    war_arms_vuln = {
        key = "war_arms_vuln",
        title = "武器-易伤窗口",
        order = 44,
        hint = "盯目标 208086。巨人打击与战争破坏者都应挂上同一条。不要派法师。",
        startText = "【易伤】对假人打 167105 或 262161。目标应有 208086。窗口内打致死打击，数字应高于窗口外。不验白字、不验法术伤。",
        startPrint = "请打巨人打击或战争破坏者，看目标 208086。",
        ids = { 167105, 262161, 208086, 12294, 7384, 1464 },
        labels = {
            [167105] = "巨人打击",
            [262161] = "战争破坏者",
            [208086] = "巨人打击易伤",
            [12294] = "致死打击",
            [7384] = "压制",
            [1464] = "猛击",
        },
        chain = {
            { id = 208086, role = "易伤光环", want = "aura-target",
              hintFail = "目标没有 208086。巨人打击不要再 CastCustomSpell 15+精通。" },
        },
        extraVerdict = function()
            return {
                "208086 不是 Dummy。表上 30/30。近战看见的是 Aura 271 已被 MeleeDamageBonusTaken 乘。",
                "不要用本包当 Taken 证据。不要派法师。白字不乘 271。",
                "人测：窗口内 12294 数字高于窗口外。两套技能都必须能挂上同一条 208086。",
            }
        end,
    },

    war_arms_sudden = {
        key = "war_arms_sudden",
        title = "武器-猝死双光环",
        order = 45,
        hint = "29725 触发后自身应同时有 52437 和 280776，然后满血可斩杀。",
        startText = "【猝死】已学 29725。打特殊攻击等到 52437 与 280776 都在，再对满血假人斩杀。打出后两条光环都应消失。",
        startPrint = "请点猝死天赋，打到双光环，再斩满血假人。",
        ids = { 29725, 52437, 280776, 163201, 281000, 260798 },
        labels = {
            [29725] = "猝死被动",
            [52437] = "猝死-耗怒修正",
            [280776] = "猝死-忽略状态",
            [163201] = "斩杀",
            [281000] = "屠杀斩杀",
            [260798] = "斩杀伤害",
        },
        chain = {
            { id = 52437, role = "52437", want = "aura-self",
              hintFail = "没有 52437。武器猝死不要改成只上 280776。" },
            { id = 280776, role = "280776", want = "aura-self",
              hintFail = "没有 280776。拍板是两个都上。" },
            { id = 260798, role = "斩杀伤害", want = "damage",
              hintFail = "没有 260798。满血斩杀应能打出。先确认双光环还在。" },
        },
        extraVerdict = function()
            return {
                "不要读 Dummy 40 当触发率。不要叠 2 层。光环持续以 35662 的 10 秒为准，不是现役 12 秒。",
                "人测：斩杀后 52437 与 280776 都应摘掉。",
            }
        end,
    },

    war_arms_tactician = {
        key = "war_arms_tactician",
        title = "武器-战术家双重置",
        order = 46,
        hint = "耗怒后致死打击与压制都应能立刻再按。只重置压制 = 失败。",
        startText = "【战术家】先把 12294 与 7384 打上冷却，再打一个耗怒技能。两条冷却都应被拉回。这是几率，可能要重复。",
        startPrint = "请把致死打击和压制打上冷却，再打耗怒技能。",
        ids = { 184783, 12294, 7384, 1464, 163201 },
        labels = {
            [184783] = "战术家",
            [12294] = "致死打击",
            [7384] = "压制",
            [1464] = "猛击",
            [163201] = "斩杀",
        },
        chain = {
            { id = 184783, role = "战术家光环", want = "aura-self",
              hintFail = "自身没有 184783。武器专精基线应有战术家。" },
            { id = 12294, role = "致死打击施法", want = "cast",
              hintFail = "没有 12294 施法记录。先打出致死打击。" },
            { id = 7384, role = "压制施法", want = "cast",
              hintFail = "没有 7384 施法记录。先打出压制。" },
        },
        extraVerdict = function()
            return {
                "列值 140 不是 Dummy。不要把 0.90% / 1.4% / 30% 写进脚本。",
                "人测动作条：两条冷却都被拉回。CLEU 上连续两次 12294 与 7384 的间隔短于完整冷却。",
                "只重置压制、致死打击仍在转 = 未按拍板落地。",
            }
        end,
    },

    war_arms_sweep = {
        key = "war_arms_sweep",
        title = "武器-横扫第二目标",
        order = 47,
        hint = "一排假人。Dummy 75 是伤害百分比。第二目标超过 8 码不应吃有效伤害。",
        startText = "【横扫】先确认身上是 260708、没有 12328/18765/35429。开横扫后对当前目标打致死打击。8 码内第二目标应吃约 75% 伤害。旧号打出 12723 记「旧号残留」，不改 CheckProc。",
        startPrint = "请开横扫，对一排假人打单体技能。",
        ids = { 260708, 12294, 1464, 12723, 26654 },
        labels = {
            [260708] = "横扫攻击",
            [12294] = "致死打击",
            [1464] = "猛击",
            [12723] = "旧横扫额外攻击1",
            [26654] = "旧横扫额外攻击2",
        },
        chain = {
            { id = 260708, role = "横扫光环", want = "aura-self",
              hintFail = "没有 260708。先导入 2026_09_05_60，且不要把 CheckProc 改回 true。" },
            { id = 12294, role = "致死打击", want = "damage",
              hintFail = "没有 12294 伤害。先打致死打击。" },
        },
        extraVerdict = function()
            return {
                "CheckProc 对 260708 必须保持 false。身上只有 260708 却出现 12723 / 26654，才是脚本回归。",
                "身上还有 12328 / 18765 / 35429 时出现旧额外攻击：记旧号残留，不 DELETE dump 行，不堵 P0。",
                "Dummy 75 是第二目标伤害百分比，不是 +75 个跳弹目标。8 码是非 DBC 半径列。",
                "持续 12 秒、冷却 30 秒出 DBC。零售「持续 30 秒 / 接下来 12 次」弃用。",
            }
        end,
    },

    war_fury_anger = {
        key = "war_fury_anger",
        title = "狂怒-怒气掌控除数",
        order = 48,
        hint = "152278 Dummy 20/10/20 当除数。禁止每次固定 -1000ms。蓝贴 25 弃用。",
        startText = "【怒气掌控-狂怒】点 152278。把鲁莽 1719、冲锋 100、飞跃 6544 打上冷却，再打耗怒技能。冷却必须随耗怒往下跳，不是每次 1 秒。",
        startPrint = "请点怒气掌控，打上冷却后再耗怒。看鲁莽/冲锋/飞跃剩余时间。",
        ids = { 152278, 1719, 100, 6544 },
        labels = {
            [152278] = "怒气掌控",
            [1719] = "鲁莽",
            [100] = "冲锋",
            [6544] = "英勇飞跃",
        },
        chain = {
            { id = 152278, role = "怒气掌控被动", want = "aura-self",
              hintFail = "没有 152278。天赋怒气掌控未点。" },
            { id = 1719, role = "鲁莽施法", want = "cast",
              hintFail = "没有 1719。先把鲁莽打上冷却再耗怒。" },
        },
        extraVerdict = function()
            return {
                "EFFECT_0 Dummy 20 减冲锋/飞跃。EFFECT_1 Dummy 10 减鲁莽。公式 paidRage*100/Dummy。",
                "禁止 ModifyCooldown(..., -1000)。禁止把蓝贴 25 写进脚本。狂怒不要减化身。",
            }
        end,
    },

    war_fury_rampage = {
        key = "war_fury_rampage",
        title = "狂怒-暴怒上激怒",
        order = 49,
        hint = "120 狂怒按 184367。自身应出现 184362。父技能必须已 INSERT。",
        startText = "【暴怒】选中满级伤害假人，按暴怒 184367。自身应出现激怒 184362。不要点腐蚀测试。",
        startPrint = "请按暴怒 184367。看 CLEU 的 184367 与光环 184362。",
        ids = { 184367, 184362, 184707, 184709, 201363, 201364, 218617 },
        labels = {
            [184367] = "暴怒",
            [184362] = "激怒",
            [184707] = "暴怒伤害1",
            [184709] = "暴怒伤害2",
            [201363] = "暴怒伤害3",
            [201364] = "暴怒伤害4",
            [218617] = "暴怒伤害残留段",
        },
        chain = {
            { id = 184367, role = "暴怒施法", want = "cast",
              hintFail = "没有 184367。先导入 2026_09_06_01。" },
            { id = 184362, role = "激怒", want = "aura-self",
              hintFail = "没有 184362。父技能必须接到 spell_warr_rampage。" },
        },
        extraVerdict = function()
            return {
                "五段伤害脚本保留，不要 DELETE 218617。Dummy 4 不要写成五连击。",
                "零售鲁莽 12 秒、奥丁之怒当基线：弃用。",
            }
        end,
    },

    war_fury_bloodthirst = {
        key = "war_fury_bloodthirst",
        title = "狂怒-嗜血与怒击Dummy",
        order = 50,
        hint = "Dummy 25 是对已激怒目标加伤。Dummy 20 是怒击重置。不要把 15 改成 25。",
        startText = "【嗜血/怒击】先暴怒上 184362，再打嗜血 23881，数字应高于激怒消失之后。怒击重置是几率。治疗走 117313 的 5%，不是 25%。",
        startPrint = "请先上激怒再打嗜血，再打怒击。",
        ids = { 23881, 117313, 184362, 85288, 215568 },
        labels = {
            [23881] = "嗜血",
            [117313] = "嗜血治疗",
            [184362] = "激怒",
            [85288] = "怒击",
            [215568] = "鲜肉",
        },
        chain = {
            { id = 23881, role = "嗜血伤害", want = "damage",
              hintFail = "没有 23881。确认动作条有嗜血。" },
            { id = 85288, role = "怒击施法", want = "cast",
              hintFail = "没有 85288。确认动作条有怒击。" },
        },
        extraVerdict = function()
            return {
                "Dummy 25 不是开服 30%，不要写进激怒几率。鲜肉读 215568 自己的列。",
                "怒击 Dummy 20 必须 GetEffect，禁止 roll_chance_f(20) 写死。",
            }
        end,
    },

    war_fury_siege = {
        key = "war_fury_siege",
        title = "狂怒-攻城者易伤",
        order = 51,
        hint = "盯当前目标 280773。不要做成范围技。不要派法师。",
        startText = "【攻城者】对当前假人打 280772。只有当前目标应有 280773（约 10 秒）。窗口内打暴怒/嗜血数字应更高。不验白字、不验法术伤。",
        startPrint = "请打攻城者 280772，看当前目标 280773。",
        ids = { 280772, 280773, 184367, 23881 },
        labels = {
            [280772] = "攻城者",
            [280773] = "攻城者易伤",
            [184367] = "暴怒",
            [23881] = "嗜血",
        },
        chain = {
            { id = 280772, role = "攻城者施法", want = "cast",
              hintFail = "没有 280772。天赋第 6 层第 2 列。" },
            { id = 280773, role = "易伤光环", want = "aura-target",
              hintFail = "当前目标没有 280773。不要 CastSpell(nullptr)。" },
        },
        extraVerdict = function()
            return {
                "280772 本表无 Dummy。280773 基点 15 不是 Dummy。Aura 343 本波不补。",
                "Icy Veins 多目标减益是非 DBC。旁边假人不应一起挂 280773。",
                "冷却 30 秒、持续 10 秒出 DBC。现役 12 秒 / 120% AP 弃用。",
            }
        end,
    },

    war_fury_cleaver = {
        key = "war_fury_cleaver",
        title = "狂怒-绞肉机与猝死被动",
        order = 52,
        hint = "280392 效果 0 Dummy 1 = 每目标额外怒气，效果 1 Dummy 3 = 上限，效果 2 Dummy 10 = 激怒几率%。斩杀后 280721 必须还在。5308 必须走 spell_warr_execute_fury。不要 DELETE 12950。",
        startText = "【绞肉机/猝死】确认身上是 280392 不是 12950。对一排假人打旋风斩 190411。点 280721 后触发 280776，斩 5308 后 280721 仍在。",
        startPrint = "请开绞肉机打旋风斩，再测猝死斩杀。",
        ids = { 190411, 280392, 184362, 85739, 280721, 280776, 5308, 12950 },
        labels = {
            [190411] = "旋风斩",
            [280392] = "绞肉机",
            [184362] = "激怒",
            [85739] = "旋风斩顺劈",
            [280721] = "狂怒猝死被动",
            [280776] = "猝死触发",
            [5308] = "狂怒斩杀",
            [12950] = "旧绞肉斧",
        },
        chain = {
            { id = 190411, role = "旋风斩施法", want = "cast",
              hintFail = "没有 190411。不要和武器 1680 混。" },
            { id = 280776, role = "猝死触发", want = "aura-self",
              hintFail = "没有 280776。狂怒不要上 52437。" },
        },
        extraVerdict = function()
            return {
                "Dummy 效果 0=1 每目标怒气，效果 1=3 上限，效果 2=10 激怒几率。禁止写死 10，禁止按 hint 把 10 当成效果 0。",
                "9.0 接下来 4 次弃用。旧号 12950 不 DELETE；CheckProc 必须保持 false。",
                "5308 必须是 spell_warr_execute_fury。斩杀后若 280721 消失 = 卸了天赋被动。只许摘 280776。不要绑武器 spell_warr_execute。",
            }
        end,
    },

    war_prot_anger = {
        key = "war_prot_anger",
        title = "防护-怒气掌控除数",
        order = 53,
        hint = "EFFECT_1 Dummy 10 减化身。EFFECT_2 Dummy 20 减最后一搏/盾墙/挫志。禁止 -1000ms。",
        startText = "【怒气掌控-防护】点 152278。把化身 107574、最后一搏 12975、盾墙 871、挫志 1160 打上冷却，再打耗怒技能。冷却随耗怒跳，不是每次 1 秒。",
        startPrint = "请点怒气掌控，打上防护大技能冷却后再耗怒。",
        ids = { 152278, 107574, 12975, 871, 1160 },
        labels = {
            [152278] = "怒气掌控",
            [107574] = "化身",
            [12975] = "最后一搏",
            [871] = "盾墙",
            [1160] = "挫志怒吼",
        },
        chain = {
            { id = 152278, role = "怒气掌控被动", want = "aura-self",
              hintFail = "没有 152278。天赋怒气掌控未点。" },
            { id = 107574, role = "化身施法", want = "cast",
              hintFail = "没有 107574。先把化身打上冷却再耗怒。" },
        },
        extraVerdict = function()
            return {
                "公式与武器 P0 相同：paidRage*100/该列 Dummy。禁止写死 -1000ms。蓝贴 25 弃用。",
            }
        end,
    },

    war_prot_ignore = {
        key = "war_prot_ignore",
        title = "防护-无视苦痛吸收",
        order = 54,
        hint = "删掉 22.3。基础 AP×3.5，Dummy 50 是额外倾泻上限。去坦克假人。",
        startText = "【无视苦痛】在会还手的坦克假人上按 190456。低怒气一层盾，满怒倾泻应更厚。不要用现役 35 怒气 / 55% / 生命% 封顶。",
        startPrint = "请对坦克假人按无视苦痛 190456。",
        ids = { 190456 },
        labels = {
            [190456] = "无视苦痛",
        },
        chain = {
            { id = 190456, role = "无视苦痛光环", want = "aura-self",
              hintFail = "没有 190456。确认专精是防护。" },
        },
        extraVerdict = function()
            return {
                "22.3 不在 35662。读 BonusCoefficientFromAP 与 Dummy 50。0.9 自伤本波不改。",
                "StartRecoveryTime=0 出表。人测：倾泻后盾更厚即可，不要用论坛系数对绝对值。",
            }
        end,
    },

    war_prot_slam = {
        key = "war_prot_slam",
        title = "防护-毁灭重置盾猛",
        order = 55,
        hint = "两处 Dummy 30 都掷骰。ResetCooldown。禁止 -40 秒。",
        startText = "【毁灭重置】不点毁灭者。先把 23922 打上冷却，再打 20243。盾猛冷却应被拉回（几率，可重复）。不要出现只减 40 秒。",
        startPrint = "请把盾猛打上冷却，再打毁灭。",
        ids = { 20243, 23922, 231834 },
        labels = {
            [20243] = "毁灭",
            [23922] = "盾牌猛击",
            [231834] = "盾猛被动",
        },
        chain = {
            { id = 20243, role = "毁灭施法", want = "cast",
              hintFail = "没有 20243。先不要点毁灭者。" },
            { id = 23922, role = "盾猛施法", want = "cast",
              hintFail = "没有 23922。先打出盾猛好记下冷却。" },
        },
        extraVerdict = function()
            return {
                "20243 Dummy 30 与 231834 Dummy 30 两边都读。补篇已知表第 7 行弃用。",
                "现役毁灭者 25% 弃用。本包不测 236279（见下一包）。",
            }
        end,
    },

    war_prot_devastator = {
        key = "war_prot_devastator",
        title = "防护-毁灭者自动触发",
        order = 56,
        hint = "点 236279 后不再按 20243。自动攻击应打出 236282，Dummy 20 重置盾猛。",
        startText = "【毁灭者】学 236279。自动攻击看 236282。盾猛冷却可被自动攻击拉回。先导入 2026_09_06_02。",
        startPrint = "请点毁灭者，站桩自动攻击。",
        ids = { 236279, 236282, 23922 },
        labels = {
            [236279] = "毁灭者",
            [236282] = "毁灭者触发伤",
            [23922] = "盾牌猛击",
        },
        chain = {
            { id = 236279, role = "毁灭者被动", want = "aura-self",
              hintFail = "没有 236279。天赋第 5 层第 2 列，先导入 _02。" },
            { id = 236282, role = "触发伤", want = "damage",
              hintFail = "没有 236282。不要脚本 CastCustomSpell 改基点，Trigger 走 Aura 42。" },
        },
        extraVerdict = function()
            return {
                "覆盖 20243 后不要再按毁灭键。Dummy 20 读表，不是 25%。",
            }
        end,
    },

    war_prot_thunder = {
        key = "war_prot_thunder",
        title = "防护-雷霆一击与格挡",
        order = 57,
        hint = "6343 不应再上 115798。2565 上 132404。不要把 16 秒写进脚本。",
        startText = "【雷霆/格挡】打 6343，目标不应有 115798。按 2565 自身应有 132404。充能间隔只记录，不改 C++。拦截对盟友走 147833。站姿用 71。",
        startPrint = "请打雷霆一击和盾牌格挡。",
        ids = { 6343, 115798, 2565, 132404, 198304, 147833, 71 },
        labels = {
            [6343] = "雷霆一击",
            [115798] = "削弱打击(不应出现)",
            [2565] = "盾牌格挡",
            [132404] = "格挡光环",
            [198304] = "拦截",
            [147833] = "拦截盟友",
            [71] = "防御姿态",
        },
        chain = {
            { id = 6343, role = "雷霆一击", want = "damage",
              hintFail = "没有 6343 伤害。确认动作条有雷霆一击。" },
            { id = 132404, role = "格挡光环", want = "aura-self",
              hintFail = "没有 132404。2565 脚本应 CastSpell 这条。" },
        },
        extraVerdict = function()
            return {
                "35662 SpellName 无 115798，本波删掉这次 CastSpell。CLEU 出现 115798 = 回归。",
                "不要把 16 秒写进脚本。不要给 6572 / 275336 / 204488 加厚。站姿用 71。",
            }
        end,
    },

    dk_c_strike = {
        key = "dk_c_strike",
        title = "DK共用-死亡打击Dummy",
        order = 58,
        hint = "49998 Dummy 25/7/5。删掉 AP*7。效果 0 是伤害。鲜血护盾公式在 Blood 包。",
        startText = "【死亡打击】120 任意专精，去会还手的坦克假人 131992 或 144078。先挨打约 5 秒，再按 49998。治疗应跟近 5 秒承伤走，最低大约最大生命 7%。不要用现役 35% 生命对数字。",
        startPrint = "请先挨打再按死亡打击 49998。看 CLEU 的 45470。",
        ids = { 49998, 45470, 48743 },
        labels = {
            [49998] = "死亡打击",
            [45470] = "死亡打击治疗",
            [48743] = "死亡契约",
        },
        chain = {
            { id = 49998, role = "死亡打击施法", want = "cast",
              hintFail = "没有 49998。确认动作条有死亡打击。" },
        },
        extraVerdict = function()
            return {
                "Dummy 25=近 5 秒承伤百分比，Dummy 7=至少最大生命%，Dummy 5=观察窗口秒。禁止 AP*7。效果 0 不要当生命百分比加伤。",
                "死亡契约 48743 Dummy 30 在效果 2。挂钩必须对 EFFECT_2。本包不测窒息 108194（cpp 无类，不验收）。",
            }
        end,
    },

    dk_c_ams = {
        key = "dk_c_ams",
        title = "DK共用-反魔法护罩上限与回能",
        order = 59,
        hint = "上限读效果 1 基点 30。每吸收最大生命 1% 回可见 2 点符能。先导入 _03。",
        startText = "【反魔法护罩】先导入 2026_09_06_03。按 48707 再吃法术伤。护罩大约是最大生命 30%，不是 40 或 50。符文能量应往上跳。SimC 的 1 点弃用。",
        startPrint = "请开反魔法护罩 48707，再吃法术伤。看 49088 与护罩容量。",
        ids = { 48707, 49088 },
        labels = {
            [48707] = "反魔法护罩",
            [49088] = "符文能量回复",
        },
        chain = {
            { id = 48707, role = "反魔法护罩", want = "aura-self",
              hintFail = "没有 48707。确认动作条有反魔法护罩，且已导入 _03。" },
        },
        extraVerdict = function()
            return {
                "48707 只留 spell_dk_anti_magic_shell。_self 必须已 DELETE。禁止写死 40/50。",
                "2 点符能不是 Dummy。Aura 267 不改引擎。不要用 SimC 的 1 对数字。",
            }
        end,
    },

    dk_c_grip = {
        key = "dk_c_grip",
        title = "DK共用-死亡之握与寒冰锁链",
        order = 60,
        hint = "删对玩家 8 码。鲜血仍嘲讽 57603。锁链命中不要上 55095。",
        startText = "【死亡之握/锁链】对玩家或近身假人按 49576，不应因 8 码失败。120 鲜血应给目标嘲讽 57603。冰霜按 45524 后目标不应有 55095。鲜血不验收锁链。",
        startPrint = "请打死亡之握 49576，冰霜再打寒冰锁链 45524。",
        ids = { 49576, 49575, 57603, 45524, 55095 },
        labels = {
            [49576] = "死亡之握",
            [49575] = "死亡之握拉取",
            [57603] = "死亡之握嘲讽",
            [45524] = "寒冰锁链",
            [55095] = "冰霜疫病(锁链不应上)",
        },
        chain = {
            { id = 49576, role = "死亡之握施法", want = "cast",
              hintFail = "没有 49576。过近失败 = CheckCast 仍有 8 码。" },
            { id = 45524, role = "寒冰锁链施法", want = "cast",
              hintFail = "没有 45524。冰霜测锁链；鲜血本包不验收锁链。" },
        },
        extraVerdict = function()
            return {
                "3.3.3 对玩家 8 码必须删。鲜血嘲讽 57603 必须保留。",
                "45524 双绑 chains+chilblains 都保留。CLEU 出现锁链上 55095 = 回归。Dummy 0 不是上疫病。",
            }
        end,
    },

    dk_c_gate = {
        key = "dk_c_gate",
        title = "DK共用-死亡之门50977",
        order = 61,
        hint = "玩家技能是 50977。保留 52751。120 走过军团传到地图 1220。先导入 _03。",
        startText = "【死亡之门】动作条必须是 50977，不要只靠 52751。开门后点门。走过军团的 120 应落到破碎群岛地图 1220。先导入 2026_09_06_03。",
        startPrint = "请按死亡之门 50977，再点门。看地图 ID。",
        ids = { 50977, 52751 },
        labels = {
            [50977] = "死亡之门",
            [52751] = "点死亡之门",
        },
        chain = {
            { id = 50977, role = "死亡之门施法", want = "cast",
              hintFail = "没有 50977。先导入 _03，不要只绑 52751。" },
        },
        extraVerdict = function()
            return {
                "50977 是 TRANS_DOOR，HandleScript 进不去，靠默认开门 + 点门 52751。不要 PreventHitDefaultEffect 把门掐掉。",
                "dump 孤儿 spell_dk_asphyxiate 不验收、不包空类。心灵冰冻 47528 不包空脚本。",
            }
        end,
    },

    dk_blood_bone = {
        key = "dk_blood_bone",
        title = "鲜血-骨髓骨盾骨风暴赤色天灾",
        order = 62,
        hint = "骨髓加层不是 SetStackAmount。骨盾不是吸收。护甲看人物面板。骨风暴 extraMs=(internalCost/100)*ms，上限内部 1000。赤色 Dummy 30。去坦克假人。",
        startText = "【骨盾循环】120 鲜血，坦克假人 131992 / 144078。打 195182 应叠层，不要把已有层覆盖成刚好 3。骨盾 195181 不是吸收盾。打开人物面板：护甲数值随层数变，不要只看图标。点 81136 后血液沸腾冷却应有几率重置。骨风暴 100 可见符能大约 10 秒，10 可见大约 1 秒，不要变成 11 秒。",
        startPrint = "请打骨髓分裂、看骨盾，再测赤色天灾和骨风暴。",
        ids = { 195182, 195181, 81136, 50842, 194844 },
        labels = {
            [195182] = "骨髓分裂",
            [195181] = "白骨之盾",
            [81136] = "赤色天灾",
            [50842] = "血液沸腾",
            [194844] = "白骨风暴",
        },
        chain = {
            { id = 195182, role = "骨髓分裂施法", want = "cast",
              hintFail = "没有 195182。确认专精是鲜血。" },
            { id = 195181, role = "白骨之盾", want = "aura-self",
              hintFail = "没有 195181。骨髓分裂应 ModStackAmount 加层。" },
        },
        extraVerdict = function()
            return {
                "Dummy 3 = 加 3 层。禁止 SetStackAmount(3)。不要挂 SCHOOL_ABSORB。护甲用 HandleStatModifier 旁路。禁止改 SpellAuraEffects.cpp。耗层观察窗口 2.5 秒，不要写死 2000 ms，2.5 不进 Dummy。",
                "赤色 Dummy 30，禁止 roll_chance_i(40)，网页 25% 弃用。骨风暴只留 extraMs=(internalCost/100)*IN_MILLISECONDS，再 min(10000,max(1000,extraMs))。内部上限 1000。禁止 GetDuration()+(符能/10)。10/100/1000 都不得当 Dummy。",
            }
        end,
    },

    dk_blood_strike = {
        key = "dk_blood_strike",
        title = "鲜血-护盾吸血鬼墓石表已表达",
        order = 63,
        hint = "77535 = 治疗量×精通%。吸血鬼读对列。墓石不要 221699。心脏打击/符文分流不包空脚本。",
        startText = "【鲜血护盾/吸血鬼/墓石】在坦克假人上打死亡打击，自身应出现 77535，厚度跟本次治疗走，不要最大生命×精通%。按 55233 应加治疗且加最大生命。墓石 219809 不应去查 221699。心脏打击 206930、符文分流 194679 能按出来即可，不要为它们加脚本名。",
        startPrint = "请打死亡打击看 77535，再开吸血鬼之血和墓石。",
        ids = { 49998, 45470, 77513, 77535, 55233, 219809, 206930, 194679 },
        labels = {
            [49998] = "死亡打击",
            [45470] = "死亡打击治疗",
            [77513] = "精通鲜血护盾",
            [77535] = "鲜血护盾吸收",
            [55233] = "吸血鬼之血",
            [219809] = "墓石",
            [206930] = "心脏打击",
            [194679] = "符文分流",
        },
        chain = {
            { id = 77535, role = "鲜血护盾", want = "aura-self",
              hintFail = "没有 77535。HandleHeal2 必须按治疗量×精通%，且只给鲜血。" },
            { id = 55233, role = "吸血鬼之血", want = "aura-self",
              hintFail = "没有 55233。效果 1 与效果 3 不要都按最大生命×30%。" },
        },
        extraVerdict = function()
            return {
                "精通家留在 spell_dk.cpp，禁止搬到 spell_mastery.cpp。非鲜血不要上 77535。",
                "心脏打击 Chain 2 出表，不包空脚本，不改 Spell.cpp。符文分流 Aura 87 −30 表已表达。鲜血镜像不加厚。",
            }
        end,
    },

    dk_blood_drw = {
        key = "dk_blood_drw",
        title = "鲜血-符文刃舞复制循环",
        order = 64,
        hint = "不要 2 秒转发白字。复制心脏打击/骨髓分裂/血液沸腾/死亡打击。招架 40%、8 秒出 DBC。",
        startText = "【符文刃舞】120 鲜血，坦克假人。按 49028 后 8 秒窗口内自己打心脏打击/骨髓分裂/血液沸腾/死亡打击，假人 CLEU 应出现镜像同技能，不是无技能白字。招架光环 81256 应在。triggered 要跳过防死循环。",
        startPrint = "请开符文刃舞 49028，再打鲜血循环技能。看镜像 CLEU。",
        ids = { 49028, 81256, 206930, 195182, 50842, 49998 },
        labels = {
            [49028] = "符文刃舞",
            [81256] = "符文刃舞招架",
            [206930] = "心脏打击",
            [195182] = "骨髓分裂",
            [50842] = "血液沸腾",
            [49998] = "死亡打击",
        },
        chain = {
            { id = 49028, role = "符文刃舞施法", want = "cast",
              hintFail = "没有 49028。确认专精是鲜血。" },
            { id = 81256, role = "招架光环", want = "aura-self",
              hintFail = "没有 81256。招架 40% 与 8 秒出 DBC，不要写进脚本常数。" },
        },
        extraVerdict = function()
            return {
                "禁止 GetDamageOverLastSeconds(2)+DealDamage 当循环。复制 206930/195182/50842/49998。不要给心脏打击加 spell_script_names。",
                "creature_template 27893 已是 npc_dk_dancing_rune_weapon。本波没有独立 SQL 文件。",
            }
        end,
    },

    dk_frost_rime = {
        key = "dk_frost_rime",
        title = "冰霜-凛风白霜冰柱巨镰杀戮机器",
        order = 65,
        hint = "49184 只留 howling_blast。白霜 Dummy 45。冰柱每符文 Dummy 1。巨镰 Dummy 列不要绑错。杀戮机器不写 RPPM。81229 Dummy 20 每点可见符能 2%。先导入 _04。",
        startText = "【凛风/白霜】120 冰霜，伤害桩 131989 / 144081 一排。先导入 2026_09_06_04。打 49184 主副目标都应受伤并上 55095。湮灭暴击后应能看到 59052（Dummy 45）。开 51271 后每消耗符文应叠力量。巨镰 207230 读效果 2 的 Dummy 4，不要挂钩效果 0 Dummy 0。自动攻击暴击应能看到 51124，不要写 RPPM。CLEU 不要出现北风 204088。花符能（冰霜打击 / 吐息）时冷却中的符文应有时被点亮（81229）。",
        startPrint = "请打凛风和湮灭，再开冰霜之柱、巨镰。看白霜、杀戮机器，以及花符能是否有时亮符文。",
        ids = { 49184, 237680, 55095, 59057, 59052, 51271, 207230, 51124, 51128, 204088, 81229 },
        labels = {
            [49184] = "凛风冲击",
            [237680] = "凛风副目标",
            [55095] = "冰霜疫病",
            [59057] = "白霜被动",
            [59052] = "白霜触发",
            [51271] = "冰霜之柱",
            [207230] = "冰霜巨镰",
            [51124] = "杀戮机器",
            [51128] = "杀戮机器被动",
            [204088] = "北风(不应出现)",
            [81229] = "符文强化",
        },
        chain = {
            { id = 49184, role = "凛风施法", want = "cast",
              hintFail = "没有 49184。确认已 DELETE icy_touch 双绑。" },
            { id = 59052, role = "白霜触发", want = "aura-self",
              hintFail = "没有 59052。Dummy 45 必须 GetEffect，禁止 roll_chance_f(45) 写死。" },
        },
        extraVerdict = function()
            return {
                "凛风本表无 Dummy。锁链不要上 55095，凛风可以上。北风 204088 不是 8.3 天赋，删残留。",
                "冰柱 Dummy 1 在效果 1。巨镰 Dummy 4 在效果 2。杀戮机器 Aura 42 已在表上，禁止写 RPPM。寒冰帽 Dummy 30÷10。",
                "符文强化 81229 Dummy 20：花符能有时会亮符文。chance = spentVisible * (GetAmount()/10)。禁止 GetAmount()/100，禁止写死 2.0f。不要新建 PlayerScript。",
            }
        end,
    },

    dk_frost_breath = {
        key = "dk_frost_breath",
        title = "冰霜-辛达苟萨之息耗能",
        order = 66,
        hint = "每秒可见 16（内部 -160）。Dummy 10 不覆盖。能量不够则摘 152279。",
        startText = "【吐息】120 冰霜打 152279。每秒大约掉 16 点可见符能。Dummy 10 是 155166 的列，不要拿来当耗能。不要继续 -130。符能见底应自动结束。",
        startPrint = "请开辛达苟萨之息 152279，看每秒符能。",
        ids = { 152279, 155166 },
        labels = {
            [152279] = "辛达苟萨之息",
            [155166] = "吐息子伤害",
        },
        chain = {
            { id = 152279, role = "吐息光环", want = "aura-self",
              hintFail = "没有 152279。确认天赋已点吐息。" },
            { id = 155166, role = "吐息伤害", want = "damage",
              hintFail = "没有 155166。周期 Trigger 应打出子伤害。" },
        },
        extraVerdict = function()
            return {
                "ModifyPower(POWER_RUNIC_POWER, -160)。16/13/130/160 都不得当 Dummy。155166 Dummy 10 保持不覆盖。",
                "内部能量格 ×10：玩家看见 16 = 内部 160。",
            }
        end,
    },

    dk_frost_wyrm = {
        key = "dk_frost_wyrm",
        title = "冰霜-巨龙之怒与符文武器强化",
        order = 67,
        hint = "279302 面前 40 码，AT 14881。47568 不要做成 11.2 两层。先导入 _04。",
        startText = "【巨龙/符文武器】先导入 2026_09_06_04。点 279302，面前约 40 码应出 CLEU 279303。47568 冷却大约 2 分钟、1 层，不要出现两层充能。分类 1614 已是 120000 ms。",
        startPrint = "请打巨龙之怒 279302，再打符文武器强化 47568。",
        ids = { 279302, 279303, 47568 },
        labels = {
            [279302] = "冰霜巨龙之怒",
            [279303] = "巨龙伤害",
            [47568] = "符文武器强化",
        },
        chain = {
            { id = 279302, role = "巨龙之怒施法", want = "cast",
              hintFail = "没有 279302。先导入 _04，脚本名 spell_dk_frostwyrms_fury。" },
            { id = 279303, role = "巨龙伤害", want = "damage",
              hintFail = "没有 279303。AT 14881 必须已 INSERT，不要绑枯萎 26。" },
        },
        extraVerdict = function()
            return {
                "279302 本表无 Dummy。Data0/Data1 的 40 是码数观察窗口。禁止改 9225。",
                "47568 本表无 Dummy。11.2 两层弃用。120 不进 Dummy。现有清符文冷却脚本保留。",
            }
        end,
    },

    dk_unholy_wound = {
        key = "dk_unholy_wound",
        title = "邪恶-脓疮暗影之爪感染之爪传染",
        order = 68,
        hint = "脓疮 Dummy 2.5。暗影之爪减 1 层且 GetHitUnit。感染之爪/传染 Dummy 当上 194310 的概率。枯萎继续 9225。",
        startText = "【伤口循环】120 邪恶，伤害桩 131989 / 144081。脓疮打击 85948 应叠大约 2 或 3 层 194310（Dummy 2.5）。天灾打击或暗影之爪应减 1 层并打 194311。暗影之爪必须打当前法术目标。点感染之爪后食尸鬼平砍有几率给目标加 194310，不是直接打 194311。枯萎+传染进圈应有几率上 194310，圈脚本仍是 9225，禁止绑基点 26。",
        startPrint = "请打脓疮打击、天灾打击或暗影之爪，再测感染之爪和枯萎传染。",
        ids = { 85948, 194310, 194311, 55090, 207311, 207272, 277234, 43265 },
        labels = {
            [85948] = "脓疮打击",
            [194310] = "脓疮伤口",
            [194311] = "爆伤口伤害",
            [55090] = "天灾打击",
            [207311] = "暗影之爪",
            [207272] = "感染之爪",
            [277234] = "传染",
            [43265] = "枯萎凋零",
        },
        chain = {
            { id = 85948, role = "脓疮打击施法", want = "cast",
              hintFail = "没有 85948。确认专精是邪恶。" },
            { id = 194310, role = "脓疮伤口", want = "aura-target",
              hintFail = "目标没有 194310。Dummy 2.5 不要写成固定 2 次或 3 次。" },
        },
        extraVerdict = function()
            return {
                "感染之爪 Dummy 30、传染 Dummy 10 都是上 194310 的概率。禁止打 194311 当上伤口，禁止写死 30/10。",
                "暗影之爪禁止 GetSelectedUnit。枯萎不改 9225 / (4485,9225)。爆发扩散见下一包。不要改 spell_pet.cpp。",
            }
        end,
    },

    dk_unholy_apoc = {
        key = "dk_unholy_apoc",
        title = "邪恶-天启亡者大军全心效忠",
        order = 69,
        hint = "天启 Dummy 4。亡者大军 8 只不是 Dummy。全心效忠射击 212423。先导入 _05。PET 缩放不验收。",
        startText = "【天启/大军/效忠】先导入 2026_09_06_05。目标叠满伤口后按 275699，应出尸鬼 221180 / 111101，最多爆 4 层。亡者大军 42650 引导结束场上大约 8 只 24207。点全心效忠后射手 99541 的 CLEU 必须有 212423。尸鬼打多少伤不验收。",
        startPrint = "请打天启 275699、亡者大军 42650、全心效忠射手。",
        ids = { 275699, 221180, 42650, 42651, 194916, 196910, 212423 },
        labels = {
            [275699] = "天启",
            [221180] = "天启召唤",
            [42650] = "亡者大军",
            [42651] = "亡者大军单只",
            [194916] = "全心效忠",
            [196910] = "全心效忠召唤",
            [212423] = "潜藏者射击",
        },
        chain = {
            { id = 275699, role = "天启施法", want = "cast",
              hintFail = "没有 275699。先导入 _05，脚本名 spell_dk_apocalypse。" },
            { id = 212423, role = "潜藏者射击", want = "cast",
              hintFail = "没有 212423。99541 的 SAI 必须 action 11 打这条，不要改 spell_pet.cpp。" },
        },
        extraVerdict = function()
            return {
                "Dummy 4 不要当成亡者大军人数。8 只是观察窗口。42650 不发明空脚本。",
                "不要给 42650 包空类。召唤物伤害 → PET 批次。淤泥喷射者本波不验收。",
            }
        end,
    },

    dk_unholy_epidemic = {
        key = "dk_unholy_epidemic",
        title = "邪恶-传染瘟疫狂乱灵魂收割爆发",
        order = 70,
        hint = "传染瘟疫不 Remove 191587。邪恶狂乱不要绑 156004。灵魂收割急速 215711。爆发打敌人。",
        startText = "【瘟疫收口】目标有 191587 时打 207317，应出 212739 / 215969，目标仍应有恶性瘟疫。爆发 77575 应把瘟疫铺到附近敌人，不要铺友方。邪恶狂乱 207289 自身约 12 秒 20% 急速，窗口内平砍应上 194310，不要依赖亵渎 156004。灵魂收割目标死亡后自身急速必须是 215711，CLEU 不要出现 69410。Filter 保持 7，不要改成 20。",
        startPrint = "请打传染瘟疫、爆发、邪恶狂乱、灵魂收割。看 191587 还在、急速是 215711。",
        ids = { 207317, 191587, 212739, 215969, 77575, 196782, 207289, 130736, 215711, 156004 },
        labels = {
            [207317] = "传染瘟疫",
            [191587] = "恶性瘟疫",
            [212739] = "传染瘟疫单体",
            [215969] = "传染瘟疫扩散",
            [77575] = "爆发",
            [196782] = "爆发周期",
            [207289] = "邪恶狂乱",
            [130736] = "灵魂收割",
            [215711] = "灵魂收割急速",
            [156004] = "亵渎Dummy(不应驱动狂乱)",
        },
        chain = {
            { id = 207317, role = "传染瘟疫施法", want = "cast",
              hintFail = "没有 207317。目标先要有 191587。" },
            { id = 215711, role = "灵魂收割急速", want = "aura-self",
              hintFail = "没有 215711。枚举必须从 69410 改成 215711。目标需要先被收割再死去。" },
        },
        extraVerdict = function()
            return {
                "禁止 RemoveAura(191587)。禁止把 Filter 改成 20。爆发用 GetAttackableUnitListInRange，禁止 GetFriendlyUnitListInRange。",
                "邪恶狂乱禁止绑 156004 / Unholy Assault。灵魂收割 CLEU 出现 69410 = 回归。",
            }
        end,
    },

    pal_c_judgment = {
        key = "pal_c_judgment",
        title = "圣骑共用-审判三技能号与正义之拳",
        order = 71,
        hint = "20271 惩戒 / 275773 神圣 / 275779 防护。Dummy 10/6/20。防护盾击 CDR 读 231657 Dummy 2。",
        startText = "【审判】先导入 2026_09_07_00。120 神圣 CLEU 必须是 275773，防护必须是 275779，惩戒仍是 20271。点正义之拳后：神圣审判约 −10 秒制裁之锤，防护约 −6 秒。惩戒档不要用裁决/风暴验收：先让 853 进冷却，再执行 .modify power holy_power 3，接着 .modify power holy_power 2（cs_modify.cpp 的 HandleModifyPowerCommand，不是 cs_misc.cpp；PowerType 标签 HOLY_POWER），应约 −2 秒。防护审判后盾击充能约 −2 秒，不是 1 秒。不要用玩家仍按 20271 验收神圣/防护。",
        startPrint = "请按三个专精各打一次审判。看 CLEU 技能号与制裁之锤冷却。",
        ids = { 20271, 275773, 275779, 197277, 214222, 231657, 198054, 234299, 853, 53600 },
        labels = {
            [20271] = "审判(惩戒)",
            [275773] = "审判(神圣)",
            [275779] = "审判(防护)",
            [197277] = "惩戒审判易伤",
            [214222] = "神圣审判减益",
            [231657] = "审判2级Dummy2",
            [198054] = "正义之拳(神圣防护)",
            [234299] = "正义之拳(惩戒)",
            [853] = "制裁之锤",
            [53600] = "正义盾击",
        },
        chain = {
            { id = 275773, role = "神圣审判", want = "cast",
              hintFail = "没有 275773。先导入 _00，不要只绑 20271。" },
            { id = 275779, role = "防护审判", want = "cast",
              hintFail = "没有 275779。防护公开技能不是 20271。" },
            { id = 20271, role = "惩戒审判", want = "cast",
              hintFail = "没有 20271。惩戒仍用这个号。" },
        },
        extraVerdict = function()
            return {
                "三号均无 Dummy。1000 ms 禁止冒充 Dummy 2。网页 2.5 秒弃用。",
                "35395 Energize 基点 0。回 1 圣能出 137027，禁止写成 35395 Dummy。",
                "20271 回能读 220637 Energize 基点 1，禁止魔法数 1。",
            }
        end,
    },

    pal_c_sacrifice = {
        key = "pal_c_sacrifice",
        title = "圣骑共用-牺牲祝福Dummy20",
        order = 72,
        hint = "Dummy 20 是生命下限。分摊 30% 是 Aura 81，不是 Dummy。",
        startText = "【牺牲祝福】给友方挂 6940。转移伤害应在施法者接近 20% 生命时停，并摘光环。不要等到吃满最大生命才停。分摊百分比不要改 Dummy 20。",
        startPrint = "请给友方按牺牲祝福 6940，再让假人打友方。看 20% 生命下限。",
        ids = { 6940 },
        labels = {
            [6940] = "牺牲祝福",
        },
        chain = {
            { id = 6940, role = "牺牲祝福", want = "aura-target",
              hintFail = "没有 6940。确认动作条有牺牲祝福。" },
        },
        extraVerdict = function()
            return {
                "remainingAmount 禁止 GetMaxHealth()。Dummy 20 ≠ 分摊 30%。",
            }
        end,
    },

    pal_c_cleanse_rebuke = {
        key = "pal_c_cleanse_rebuke",
        title = "圣骑共用-清洁术死脚本与责难学会范围",
        order = 73,
        hint = "清洁术只有神圣。责难只有防护/惩戒。4987 不 INSERT 脚本。",
        startText = "【清洁/责难】120 神圣对带魔法或疾病的友方按 4987，驱散应成功，不要依赖 spell_pal_cleanse。防护/惩戒用 213644，不要按 4987 验收。责难 96231 只有防护/惩戒打断；神圣本包不验收责难。圣盾 642、制裁之锤 853 表已表达，无脚本不算失败。不要用 203538 勾 PAL-C。",
        startPrint = "请神圣按 4987，防护或惩戒按 213644 和 96231。",
        ids = { 4987, 213644, 96231, 642, 853, 203538 },
        labels = {
            [4987] = "清洁术(仅神圣)",
            [213644] = "清洁毒素",
            [96231] = "责难(防护惩戒)",
            [642] = "圣盾",
            [853] = "制裁之锤",
            [203538] = "大于王者(PAL-C不验收)",
        },
        chain = {
            { id = 4987, role = "清洁术", want = "cast",
              hintFail = "没有 4987。用 120 神圣。不要启用死脚本才驱散。" },
        },
        extraVerdict = function()
            return {
                "AddSC 里 spell_pal_cleanse 必须仍注释。dump 不要 INSERT 4987。",
                "203538 出现在 CLEU 不能当 PAL-C 完成。PAL-Ret 包才验收它还活。",
            }
        end,
    },

    pal_holy_beacon = {
        key = "pal_holy_beacon",
        title = "神圣-圣光道标Dummy40",
        order = 74,
        hint = "Dummy 40。15 无 Dummy 出处。信仰读 Dummy 50，不要 /2。",
        startText = "【道标】120 神圣给治疗假人挂 53563，自己治疗。假人应吃 53652，比例大约 40%。棱镜/黎明不要再走写死 15%。点信仰道标 156910 时按 Dummy 50，不要再除以 2。",
        startPrint = "请挂圣光道标 53563，再治疗。看 53652。",
        ids = { 53563, 53651, 53652, 156910, 200025 },
        labels = {
            [53563] = "圣光道标",
            [53651] = "道标转移光环",
            [53652] = "道标治疗",
            [156910] = "信仰道标",
            [200025] = "美德道标",
        },
        chain = {
            { id = 53563, role = "圣光道标", want = "aura-target",
              hintFail = "没有 53563。给假人挂道标。" },
            { id = 53652, role = "道标跳治疗", want = "cast",
              hintFail = "没有 53652。GetPctBySpell 不要再读光环自己的 ID，也不要写死 15。CLEU 以 SPELL_HEAL 为准。" },
        },
        extraVerdict = function()
            return {
                "15 禁止写进 Dummy。200025 额外 3 目标见 pal_holy_crusader_virtue。信仰 Dummy 50 禁止再 /2。",
            }
        end,
    },

    pal_holy_dawn = {
        key = "pal_holy_dawn",
        title = "神圣-黎明之光225311",
        order = 75,
        hint = "Dummy 5/1/5 在 85222。治疗弹 225311。删 185984 与 AP*1.8。183998 自伤读 219562 Dummy 50。",
        startText = "【黎明之光】先导入 2026_09_07_01。120 神圣对治疗假人按 85222。CLEU 必须出现 225311，不要出现 185984。最多 Dummy 5 个目标。0.55 是法强系数不是 Dummy。另按 183998：自伤 196917 应约是治疗量的 Dummy 50%，读 219562，禁止 50.0f。",
        startPrint = "请按黎明之光 85222。看 CLEU 的 225311。",
        ids = { 85222, 225311, 185984, 196926, 20473, 25914, 183998, 219562, 196917 },
        labels = {
            [85222] = "黎明之光",
            [225311] = "黎明治疗弹",
            [185984] = "旧治疗弹(不应再打)",
            [196926] = "十字军之力",
            [20473] = "神圣震击",
            [25914] = "神圣震击治疗",
            [183998] = "殉道者之光",
            [219562] = "殉道自伤Dummy50",
            [196917] = "殉道自伤",
        },
        chain = {
            { id = 85222, role = "黎明之光施法", want = "cast",
              hintFail = "没有 85222。" },
            { id = 225311, role = "黎明治疗弹", want = "cast",
              hintFail = "没有 225311。枚举必须从 185984 改成 225311，先导入 _01。CLEU 以 SPELL_HEAL 为准。" },
        },
        extraVerdict = function()
            return {
                "CLEU 出现 185984 = 回归。禁止 AP*1.8。十字军之力 Dummy -1500。",
                "225311 禁止 INSERT 到 spell_script_names。85222 对每个锥形盟友 CastSpell(ally, 225311)，禁止对施法者放范围壳。",
                "183998 自伤读 219562 Dummy 50，禁止 50.0f。",
            }
        end,
    },

    pal_holy_purpose = {
        key = "pal_holy_purpose",
        title = "神圣-神圣意志20与觉醒Dummy10",
        order = 76,
        hint = "197646 Dummy 20。248033 Dummy 15/10，毫秒=Dummy*1000。删黎明 HandleAfterCast 双路径。",
        startText = "【神圣意志/觉醒】点 197646 后打震击与黎明，免费光环 216411/216413 按 Dummy 20，不要按 15。点 248033 后黎明有几率出 31884，持续大约 10 秒。不要叠两次掷骰。禁止把 10000 当 Dummy。",
        startPrint = "请点神圣意志和觉醒，再打震击/黎明。看 216411 与 31884 持续。",
        ids = { 197646, 216411, 216413, 248033, 31884, 85222, 20473 },
        labels = {
            [197646] = "神圣意志(神圣)",
            [216411] = "神圣意志震击免费",
            [216413] = "神圣意志黎明免费",
            [248033] = "觉醒",
            [31884] = "复仇之怒",
            [85222] = "黎明之光",
            [20473] = "神圣震击",
        },
        chain = {
            { id = 20473, role = "神圣震击", want = "cast",
              hintFail = "没有 20473。" },
            { id = 85222, role = "黎明之光", want = "cast",
              hintFail = "没有 85222。觉醒只认黎明。" },
        },
        extraVerdict = function()
            return {
                "wiki 20% 是伤害加成不是触发率。惩戒 Dummy 15 留给 pal_ret_storm_purpose，本包不要改口。",
                "HandleAfterCast 写死 15%/10000 必须已删。",
            }
        end,
    },

    pal_holy_crusader_virtue = {
        key = "pal_holy_crusader_virtue",
        title = "神圣-复仇十字军与美德道标",
        order = 77,
        hint = "216331 Dummy 250/3。治疗半径观察窗口 40 码（非 Dummy）。200025 Dummy 0/3/40。不要包圣洁鸣钟。",
        startText = "【复仇十字军/美德】点 216331 后去伤害桩 131989，旁站治疗假人，打十字军打击/审判应跳治疗：总量约伤害的 Dummy250%，均分最多 3 人。选人半径先 CalcRadius，没有半径则观察窗口约 40 码（216331 半径索引全 0，40 不是 Dummy）。CLEU 治疗技能号是 216331，不要出现 119952/25914。点 200025：8 秒内额外最多 3 个盟友有道标，额外目标必须 AddAura 不能再施放父技能。不要测 Divine Toll。82326 圣光术应能摘 54149。",
        startPrint = "请开复仇十字军打审判，再按美德道标。",
        ids = { 216331, 200025, 35395, 275773, 82326, 54149 },
        labels = {
            [216331] = "复仇十字军",
            [200025] = "美德道标",
            [35395] = "十字军打击",
            [275773] = "神圣审判",
            [82326] = "圣光术",
            [54149] = "圣光灌注",
        },
        chain = {
            { id = 216331, role = "复仇十字军", want = "aura-self",
              hintFail = "没有 216331。先导入 _01 并点天赋。" },
            { id = 200025, role = "美德道标", want = "cast",
              hintFail = "没有 200025。覆盖 53563。" },
        },
        extraVerdict = function()
            return {
                "250/3 不得改 Dummy。圣洁鸣钟 35662 无 ID，出现任何 Divine Toll 脚本 = 越权。",
                "禁止 CastSpell 119952/25914。HealBySpell 的 SpellInfo 是 216331。美德禁止 CastSpell(200025) 递归。",
                "216331 半径索引全 0。40 码是观察窗口，禁止写进 Dummy。",
            }
        end,
    },

    pal_prot_sotr = {
        key = "pal_prot_sotr",
        title = "防护-正义盾击护甲Aura268",
        order = 78,
        hint = "132403 Aura 268 基点 150。不是吸收。站奉献不再加强。",
        startText = "【正义盾击】120 防护去坦克假人 131992。按 53600 后人物面板护甲应上升，身上有 132403。不要再看到自制减伤百分比。站不站奉献都应挂同一条护甲。打开人物面板看护甲数字，不要只看图标。",
        startPrint = "请按正义盾击 53600。看护甲与 132403。",
        ids = { 53600, 132403, 204074, 31884 },
        labels = {
            [53600] = "正义盾击",
            [132403] = "盾击护甲",
            [204074] = "正义保护者",
            [31884] = "复仇之怒",
        },
        chain = {
            { id = 53600, role = "正义盾击施法", want = "cast",
              hintFail = "没有 53600。" },
            { id = 132403, role = "盾击护甲光环", want = "aura-self",
              hintFail = "没有 132403。禁止 CastCustomSpell 自制减伤%。先导入 _02。" },
        },
        extraVerdict = function()
            return {
                "Aura 268 禁止改 SpellAuraEffects.cpp。护甲走 HandleStatModifier。奉献 +20% 必须已删。",
                "正义保护者对 31884 必须 ModifyCooldown，不要 ReduceChargeCooldown。",
            }
        end,
    },

    pal_prot_ardent_lotp = {
        key = "pal_prot_ardent_lotp",
        title = "防护-炽热防御者与守护之光公式",
        order = 79,
        hint = "31850 Dummy 20 致死，Aura 87 不是吸收。184092 Dummy 200 用基础×(1+缺口%×Dummy/100)。",
        startText = "【炽热/守护之光】坦克假人必须会还手。开 31850 应少吃伤害，不是吸收盾。把生命打到致死应出 66235 并摘 31850。残血按 184092：治疗大约最高是基础的三倍。满血接近基础。不要站奉献再 +20%。Icy Veins 12% 与旧 30% 缺口弃用。",
        startPrint = "请开炽热防御者再挨打，残血按守护之光。",
        ids = { 31850, 66235, 184092, 213652 },
        labels = {
            [31850] = "炽热防御者",
            [66235] = "炽热致死治疗",
            [184092] = "守护之光",
            [213652] = "守护者之手",
        },
        chain = {
            { id = 31850, role = "炽热防御者", want = "aura-self",
              hintFail = "没有 31850。" },
            { id = 184092, role = "守护之光施法", want = "cast",
              hintFail = "没有 184092。残血再按。" },
        },
        extraVerdict = function()
            return {
                "Register 禁止 SPELL_AURA_SCHOOL_ABSORB。Dummy 200 不要改。奉献 +20% 本波不另造。",
            }
        end,
    },

    pal_prot_grand_judgment = {
        key = "pal_prot_grand_judgment",
        title = "防护-大十字军与审判Dummy2",
        order = 80,
        hint = "85043 Dummy 0。几率不进 C++。203791 Dummy 8/3。275779 + 231657 Dummy 2。203776 Dummy 50 只打首跳。",
        startText = "【大十字军/审判/最后的防御者】坦克假人还手。多次躲闪或招架后复仇者之盾 31935 冷却应有时重置，不要一次必中。身上可有 85416。锤 AfterCast 不要再单独掷骰，脚本里不要 chance=15 或 roll_chance_i(15)。审判 CLEU 是 275779，盾击充能约 −2 秒。点 203791：附近敌人变多则减伤大约按 Dummy 3% 一档加，不要对 SimC 指数公式。点 203776：对一排假人按 31935，第一个跳弹伤害应按 Dummy 50 加百分，后续跳弹不加；再按一次 31935，新的第一跳仍应加百分，不要整场战斗只第一发吃加成。责难 96231 防护可以验收打断。祝福之锤 Dummy 12 与圣光护盾吸收本波不验收。",
        startPrint = "请挨打看大十字军，再按审判 275779。",
        ids = { 85043, 85416, 31935, 275779, 231657, 53600, 96231, 203776, 203791 },
        labels = {
            [85043] = "大十字军被动",
            [85416] = "大十字军触发",
            [31935] = "复仇者之盾",
            [275779] = "防护审判",
            [231657] = "审判2级Dummy2",
            [53600] = "正义盾击",
            [96231] = "责难",
            [203776] = "首席复仇者",
            [203791] = "最后的防御者",
        },
        chain = {
            { id = 275779, role = "防护审判", want = "cast",
              hintFail = "没有 275779。先导入 _00。" },
            { id = 31935, role = "复仇者之盾", want = "cast",
              hintFail = "没有 31935。多次躲闪招架后应有时能立刻再按，不要一次必中。" },
            { id = 203791, role = "最后的防御者", want = "aura-self",
              hintFail = "没有 203791。点 T100 第 0 列。读 Dummy 8/3，不要抄 SimC 公式。" },
        },
        extraVerdict = function()
            return {
                "15 不得进 Dummy 0，也不得进 C++（禁止 chance=15 / roll_chance_i(15)）。1000 ms 不得进 Dummy 2。不要 CastSpell 204241。",
                "禁止 chance += 10。首席复仇者 Dummy 50 只打复仇者之盾第一个跳弹，后续跳弹不加。每次施法 OnCast 重置 _firstTarget，禁止整场战斗只第一发吃加成。不是大十字军几率。",
                "203791 读 Dummy 8/3 线性人数。禁止 SimC 2-(1-p)^n。祝福之锤 Dummy 12 与圣光护盾吸收基点 0 本波不包。",
            }
        end,
    },

    pal_ret_ashes = {
        key = "pal_ret_ashes",
        title = "惩戒-灰烬觉醒255937",
        order = 81,
        hint = "255937 无 Dummy。卸 205290。减速 5 秒非 DBC。过滤器是学派伤害。",
        startText = "【灰烬觉醒】先导入 2026_09_07_03。120 惩戒对一排假人按 255937。CLEU 必须是 255937 直伤并回 5 圣能。目标减速大约 5 秒。不要出现 205290。不要把 5/9/12 当 Dummy。不要把 198034 当循环。",
        startPrint = "请按灰烬觉醒 255937。看 CLEU 技能号与减速。",
        ids = { 255937, 255941, 205290, 198034 },
        labels = {
            [255937] = "灰烬觉醒",
            [255941] = "灰烬昏迷(恶魔亡灵)",
            [205290] = "军团昏迷号(不应再绑)",
            [198034] = "神圣之锤(不是8.3循环)",
        },
        chain = {
            { id = 255937, role = "灰烬觉醒施法", want = "cast",
              hintFail = "没有 255937。先导入 _03，不要只绑 205290。" },
        },
        extraVerdict = function()
            return {
                "EFFECT_0 必须是 SPELL_EFFECT_SCHOOL_DAMAGE。EFFECT_1 必须是 SPELL_EFFECT_APPLY_AURA 再 SetDuration(5000)。",
                "CLEU 出现 205290 = 回归。DurationIndex 835 缺行。5 秒是观察窗口。",
            }
        end,
    },

    pal_ret_storm_purpose = {
        key = "pal_ret_storm_purpose",
        title = "惩戒-神圣风暴双计与神圣意志15",
        order = 82,
        hint = "53385 不要再打 224239。223817 Dummy 15。184662 Dummy 30。删 TV/风暴/荣耀圣言写死 -7.5 与裁决之怒写死 -10。",
        startText = "【风暴/神圣意志/复仇之盾】对一排假人按 53385。CLEU 不要同一跳全额 53385 再加全额 224239。点 223817 后花圣能，223819 按 Dummy 15，不要按 20。正义之拳惩戒每圣能约 −2 秒，不要再叠 −7.5 或裁决之怒 −10。开 184662：吸收应按攻击强度 × Dummy 30，禁止 ap*20。",
        startPrint = "请打神圣风暴 53385，再点神圣意志花圣能。",
        ids = { 53385, 224239, 223817, 223819, 85256, 224266, 234299, 853, 184662 },
        labels = {
            [53385] = "神圣风暴",
            [224239] = "风暴子技能(不应再打)",
            [223817] = "神圣意志(惩戒)",
            [223819] = "神圣意志免费",
            [85256] = "圣殿骑士的裁决",
            [224266] = "裁决伤害",
            [234299] = "正义之拳(惩戒)",
            [853] = "制裁之锤",
            [184662] = "复仇之盾",
        },
        chain = {
            { id = 53385, role = "神圣风暴", want = "cast",
              hintFail = "没有 53385。" },
            { id = 85256, role = "圣殿骑士的裁决", want = "cast",
              hintFail = "没有 85256。真伤应是 224266。" },
        },
        extraVerdict = function()
            return {
                "HandleDummy 再 CastSpell(224239) 必须已删。wiki 20% 触发率弃用。",
                "justicars -10 与 word_of_glory -7.5 必须已删，只留 fist_of_justice PlayerScript。",
                "184662 CalculateAmount 读 Dummy 30，禁止 ap * 20。",
            }
        end,
    },

    pal_ret_sentence_crusade = {
        key = "pal_ret_sentence_crusade",
        title = "惩戒-处决宣判与征伐",
        order = 83,
        hint = "267798 直伤+267799。231895 基点 30÷10 观察窗口，不是 Dummy。",
        startText = "【处决/征伐】按 267798，目标应立刻受伤并有 267799 约 12 秒，不要等爆炸。开 231895 覆盖 31884，花圣能叠层，每层大约 3%。冷却按 2 分钟观察，不要把 20 秒 RecoveryTime 写成 Dummy。",
        startPrint = "请打处决宣判 267798，再开征伐 231895。",
        ids = { 267798, 267799, 231895, 31884, 84963 },
        labels = {
            [267798] = "处决宣判",
            [267799] = "处决易伤",
            [231895] = "征伐",
            [31884] = "复仇之怒(被覆盖)",
            [84963] = "审讯",
        },
        chain = {
            { id = 267798, role = "处决宣判", want = "cast",
              hintFail = "没有 267798。先导入 _03。" },
            { id = 267799, role = "处决易伤", want = "aura-target",
              hintFail = "没有 267799。形态不是到期爆炸。" },
            { id = 231895, role = "征伐", want = "aura-self",
              hintFail = "没有 231895。应覆盖 31884。" },
        },
        extraVerdict = function()
            return {
                "amount/=10 不是 Dummy。不要包 198034。不要把 24275 20% 写进 Dummy。",
            }
        end,
    },

    pal_ret_greater_kings = {
        key = "pal_ret_greater_kings",
        title = "惩戒-大于王者祝福8.3仍活",
        order = 84,
        hint = "203538 SpellName 有行。PAL-C 不验收。吸收 2.7f*SP 非 Dummy。",
        startText = "【大于王者】120 惩戒给自己或友方挂 203538，光环应在。不要按 Talent 无行拆接线。PAL-C 包即使看见这条也不能勾 PAL-C 完成。wiki 约 44 级弃用。",
        startPrint = "请按大于王者祝福 203538。",
        ids = { 203538, 203539 },
        labels = {
            [203538] = "大于王者祝福",
            [203539] = "大于智慧祝福",
        },
        chain = {
            { id = 203538, role = "大于王者祝福", want = "aura-self",
              hintFail = "没有 203538。禁止 DELETE dump 行。" },
        },
        extraVerdict = function()
            return {
                "2.7f*SP 非 Dummy。Dummy 1 不要拿来改吸收公式。本波不改吸收脚本。",
            }
        end,
    },

    dh_c_glide_hex = {
        key = "dh_c_glide_hex",
        title = "恶魔猎手共用-滑翔与妖术互斥",
        order = 85,
        hint = "131347 无 Dummy。51514 互斥是 8.3.0 补丁句，非 Dummy。",
        startText = "【滑翔】120 恶魔猎手先下落再按 131347，应能滑翔。然后 .aura 51514 再按滑翔应失败。不要把 51514 写成 Dummy。二段跳 196055 Dummy 0 不包脚本。",
        startPrint = "请下落中按滑翔，再上妖术测互斥。",
        ids = { 131347, 196353, 51514, 196055 },
        labels = {
            [131347] = "滑翔",
            [196353] = "滑翔击退",
            [51514] = "萨满妖术",
            [196055] = "二段跳",
        },
        chain = {
            { id = 131347, role = "滑翔", want = "cast",
              hintFail = "没有 131347。确认动作条有滑翔且在下落。" },
        },
        extraVerdict = function()
            return {
                "51514 不是 Dummy。不要包 196055 空脚本。",
            }
        end,
    },

    dh_c_baseline_table = {
        key = "dh_c_baseline_table",
        title = "恶魔猎手共用-吞噬禁闭打断折磨表已表达",
        order = 86,
        hint = "278326/217832/183752/185245/281854 不包空脚本。218903 痛苦列值 300，不要 /10 改 Dummy。",
        startText = "【表已表达】吞噬 278326 驱散魔法并回能（浩劫怒能 20 / 复仇痛苦 200）。禁闭 217832 约 60 秒昏迷、45 秒冷却。打断 183752 能打断；218903 若出现，记 CLEU 实际数，禁止改 300。浩劫嘲讽 281854、复仇嘲讽 185245，不要共用一个号。不要 INSERT 这些号的空脚本。",
        startPrint = "请按吞噬、禁闭、打断、嘲讽各一次。",
        ids = { 278326, 217832, 183752, 218903, 185245, 281854, 255260, 1490 },
        labels = {
            [278326] = "吞噬魔法",
            [217832] = "禁闭",
            [183752] = "打断",
            [218903] = "打断隐藏回能",
            [185245] = "折磨(复仇)",
            [281854] = "折磨(浩劫)",
            [255260] = "混乱烙印学会行",
            [1490] = "混乱烙印减益",
        },
        chain = {
            { id = 278326, role = "吞噬魔法", want = "cast",
              hintFail = "没有 278326。表已表达，不要因此去包空脚本。" },
        },
        extraVerdict = function()
            return {
                "218903 痛苦 300 不是 Dummy。200 是 278326。1490 的 5 不是 Dummy。",
            }
        end,
    },

    dh_c_throw_glaive = {
        key = "dh_c_throw_glaive",
        title = "恶魔猎手共用-投掷利刃两个技能号",
        order = 87,
        hint = "185123 无 Dummy、Chain 3。204157 Dummy 0、Chain 3。利刃大师只认 185123。",
        startText = "【投掷利刃】浩劫 CLEU 必须是 185123，复仇必须是 204157。跳弹最多 3 个目标。不要给 204157 接 203556。10 码跳弹是观察窗口，不是 Dummy。",
        startPrint = "请两个专精各丢一次投掷利刃。",
        ids = { 185123, 204157, 203556 },
        labels = {
            [185123] = "投掷利刃(浩劫)",
            [204157] = "投掷利刃(复仇)",
            [203556] = "利刃大师(仅浩劫)",
        },
        chain = {
            { id = 185123, role = "浩劫投掷利刃", want = "cast",
              hintFail = "没有 185123。不要只用 204157 验收浩劫。" },
            { id = 204157, role = "复仇投掷利刃", want = "cast",
              hintFail = "没有 204157。复仇动作条是这个号，不要只用 185123 验收复仇。" },
        },
        extraVerdict = function()
            return {
                "Chain 3 不是 Dummy。CheckProc 禁止扩到 204157。chain 必须同时能验收 185123 与 204157。",
            }
        end,
    },

    dh_c_felblade = {
        key = "dh_c_felblade",
        title = "恶魔猎手共用-魔刃同名天赋",
        order = 88,
        hint = "232893 Dummy 0。213243 Dummy 1。不是职业基线。",
        startText = "【魔刃】两专精点同一天赋 232893，距离足够应冲锋并打出 213243。15 码是观察窗口，非 Dummy。黑暗 196718 看见了也不要勾 DH-C 完成。",
        startPrint = "请点魔刃天赋后对木桩按 232893。",
        ids = { 232893, 213241, 213243 },
        labels = {
            [232893] = "魔刃",
            [213241] = "魔刃冲锋",
            [213243] = "魔刃伤害",
        },
        chain = {
            { id = 232893, role = "魔刃", want = "cast",
              hintFail = "没有 232893。确认点了天赋。" },
        },
        extraVerdict = function()
            return {
                "196718 不进 DH-C。232893 Dummy 0 不要改成 15。",
            }
        end,
    },

    dh_havoc_chaos_strike = {
        key = "dh_havoc_chaos_strike",
        title = "浩劫-混沌打击40%退还",
        order = 89,
        hint = "162794 Dummy 30 是施法壳。40% 是观察窗口，非 Dummy。",
        startText = "【混沌打击】先导入 2026_09_07_05。120 浩劫对 131989 打 162794。193840 应有时出现，不要施法前必退。毁灭 201427 不要 AP+28.7，不要单独 20%。退还量走 193840 Energize 20。",
        startPrint = "请多次按混沌打击，看 193840 是否有时出现。",
        ids = { 162794, 197125, 193840, 199547, 222031, 201427, 201428 },
        labels = {
            [162794] = "混沌打击",
            [197125] = "退还隐藏光环",
            [193840] = "退还20怒气",
            [199547] = "混沌打击主手",
            [222031] = "混沌打击副手",
            [201427] = "毁灭",
            [201428] = "毁灭主手",
        },
        chain = {
            { id = 162794, role = "混沌打击", want = "cast",
              hintFail = "没有 162794。确认浩劫动作条。" },
        },
        extraVerdict = function()
            return {
                "禁止把 40 写进 Dummy 30。禁止施法前必打 193840。",
            }
        end,
    },

    dh_havoc_eye_beam_demonic = {
        key = "dh_havoc_eye_beam_demonic",
        title = "浩劫-眼棱恶魔8秒与盲目之怒Dummy200",
        order = 90,
        hint = "213410 Dummy 0。8 秒观察窗口。203550 Dummy 200。198013 Dummy 50 不是回复。",
        startText = "【恶魔/盲目之怒】点 213410 放完 198013，162264 大约 8 秒，不要 10 秒。点 203550 后引导回怒气读 Dummy 200，不要用眼棱 Dummy 50 当 /50。",
        startPrint = "请点恶魔与盲目之怒后放眼棱。",
        ids = { 198013, 198030, 213410, 162264, 203550 },
        labels = {
            [198013] = "眼棱",
            [198030] = "眼棱伤害",
            [213410] = "恶魔",
            [162264] = "浩劫变形光环",
            [203550] = "盲目之怒",
        },
        chain = {
            { id = 198013, role = "眼棱", want = "cast",
              hintFail = "没有 198013。" },
        },
        extraVerdict = function()
            return {
                "8 与 Dummy 0 不是同一列。禁止 *2/50 抄眼棱 Dummy。",
            }
        end,
    },

    dh_havoc_fel_rush = {
        key = "dh_havoc_fel_rush",
        title = "浩劫-邪能冲刺伤害192611",
        order = 91,
        hint = "195072 Dummy 25/25 是冲刺壳。伤害号 192611。25.3 非 Dummy。",
        startText = "【邪能冲刺】CLEU 伤害必须是 192611，不要 223107。不要 25.3 公式。半径约 23 码是观察窗口。",
        startPrint = "请对 131989 放邪能冲刺，看 CLEU 技能号。",
        ids = { 195072, 192611, 197922, 197923 },
        labels = {
            [195072] = "邪能冲刺",
            [192611] = "邪能冲刺伤害",
            [197922] = "地面冲刺",
            [197923] = "空中冲刺",
        },
        chain = {
            { id = 192611, role = "冲刺伤害", want = "damage",
              hintFail = "没有 192611。先导入 _05，不要再打 223107。" },
        },
        extraVerdict = function()
            return {
                "223107 是军团残留。25.3 禁止写回。",
            }
        end,
    },

    dh_havoc_first_blood = {
        key = "dh_havoc_first_blood",
        title = "浩劫-第一滴血Dummy135",
        order = 92,
        hint = "Dummy 135。dump 绑 199552/200685/210153/210155。210152 接刃舞主脚本。",
        startText = "【第一滴血】点 206416 放刃舞，主目标应按 Dummy 135 加伤。变形窗死亡扫描 210152 也应记下主目标。8 码是观察窗口。",
        startPrint = "请点第一滴血后对一排桩放刃舞。",
        ids = { 206416, 188499, 199552, 200685, 210152, 210153, 210155 },
        labels = {
            [206416] = "第一滴血",
            [188499] = "刃舞",
            [199552] = "刃舞伤害A",
            [200685] = "刃舞伤害B",
            [210152] = "死亡扫描",
            [210153] = "扫描伤害A",
            [210155] = "扫描伤害B",
        },
        chain = {
            { id = 188499, role = "刃舞", want = "cast",
              hintFail = "没有 188499。" },
        },
        extraVerdict = function()
            return {
                "不要再把脚本绑在 206416 被动号上。135 不得改。",
            }
        end,
    },

    dh_havoc_immolation = {
        key = "dh_havoc_immolation",
        title = "浩劫-献祭光环258920",
        order = 93,
        hint = "无 Dummy。Energize 10 + 258922 每跳 7。不要用 80 造 Dummy。",
        startText = "【献祭】点天赋后 CLEU 必须是 258920，不要 178740。施放 +10 怒气，随后每跳 +7。跳数立即或延迟都算过，不要选边。复仇仍用 178740，本包不要拿复仇键勾完成。",
        startPrint = "请点献祭光环天赋后对木桩按 258920。",
        ids = { 258920, 258921, 258922, 178740 },
        labels = {
            [258920] = "浩劫献祭光环",
            [258921] = "浩劫献祭初爆",
            [258922] = "浩劫献祭跳",
            [178740] = "复仇献祭(不要当浩劫键)",
        },
        chain = {
            { id = 258920, role = "浩劫献祭", want = "aura-self",
              hintFail = "没有 258920。先导入 _05，不要只绑 178740。" },
        },
        extraVerdict = function()
            return {
                "禁止 ModifyPower 写死 80 或 10。跳数两边留。",
            }
        end,
    },

    dh_havoc_fel_barrage = {
        key = "dh_havoc_fel_barrage",
        title = "浩劫-邪能弹幕258925",
        order = 94,
        hint = "无 Dummy。表周期 Trigger 258926。不要接到军团 211053。",
        startText = "【邪能弹幕】点天赋后引导约 3 秒，CLEU 258925/258926。不要 211053，不要吞充能。3 秒/8 码是观察窗口。",
        startPrint = "请点邪能弹幕后对木桩引导。",
        ids = { 258925, 258926, 211053 },
        labels = {
            [258925] = "邪能弹幕",
            [258926] = "弹幕跳伤",
            [211053] = "军团弹幕(不应出现)",
        },
        chain = {
            { id = 258925, role = "邪能弹幕", want = "cast",
              hintFail = "没有 258925。不要再跑 211053 脚本。" },
        },
        extraVerdict = function()
            return {
                "禁止 INSERT 258925 到 spell_dh_fel_barrage。",
            }
        end,
    },

    dh_havoc_cycle_hunger = {
        key = "dh_havoc_cycle_hunger",
        title = "浩劫-仇恨循环Dummy3与无餍饥饿Dummy10",
        order = 95,
        hint = "258887 Dummy 3 减 191427。258876 Dummy 10 加在 162243 上。",
        startText = "【仇恨循环/无餍饥饿】点 258887 后，只有混沌打击真正打出 193840 才约 −3 秒恶魔变形冷却，不要减眼棱。点 258876 打 162243，应额外 +10 怒气。162243 Dummy 是 0。",
        startPrint = "请点仇恨循环与无餍饥饿后打木桩。",
        ids = { 258887, 191427, 193840, 258876, 162243 },
        labels = {
            [258887] = "仇恨循环",
            [191427] = "浩劫恶魔变形",
            [193840] = "退还怒气",
            [258876] = "无餍饥饿",
            [162243] = "恶魔之咬",
        },
        chain = {
            { id = 162243, role = "恶魔之咬", want = "cast",
              hintFail = "没有 162243。无餍饥饿脚本应绑在这个号。" },
        },
        extraVerdict = function()
            return {
                "Dummy 3 不是减眼棱。不要 INSERT 258887 空类。",
            }
        end,
    },

    dh_havoc_darkness = {
        key = "dh_havoc_darkness",
        title = "浩劫-黑暗196718基线",
        order = 96,
        hint = "Dummy 0。不进 DH-C。家 at_dh_darkness。",
        startText = "【黑暗】120 浩劫放 196718，友方进圈应有 209426。Talent 无行因为是基线。DH-C 包看见这条也不能勾 DH-C 完成。不当木桩循环硬门槛，但浩劫收口必须看见。",
        startPrint = "请按黑暗 196718，让友方走进圈。",
        ids = { 196718, 209426 },
        labels = {
            [196718] = "黑暗",
            [209426] = "黑暗吸收",
        },
        chain = {
            { id = 196718, role = "黑暗", want = "cast",
              hintFail = "没有 196718。这是浩劫基线，不是 DH-C。" },
        },
        extraVerdict = function()
            return {
                "Dummy 0 不得改。不要把 196718 INSERT 进 DH-C 脚本名。",
            }
        end,
    },

    dh_veng_soul_cleave = {
        key = "dh_veng_soul_cleave",
        title = "复仇-灵魂裂劈Dummy25与2",
        order = 97,
        hint = "Dummy 25 码 / Dummy 2 个残片。禁止伤害 *2。",
        startText = "【灵魂裂劈】坦克假人 131992。25 码内多于 2 个残片时只吃 2 个。伤害不要大约翻倍。178740 仍是复仇献祭键。",
        startPrint = "请先产残片再按灵魂裂劈 228477。",
        ids = { 228477, 228478, 178740 },
        labels = {
            [228477] = "灵魂裂劈",
            [228478] = "裂劈伤害",
            [178740] = "复仇献祭光环",
        },
        chain = {
            { id = 228477, role = "灵魂裂劈", want = "cast",
              hintFail = "没有 228477。" },
        },
        extraVerdict = function()
            return {
                "Dummy 2 是人数上限。*2 不是 Dummy。",
            }
        end,
    },

    dh_veng_fiery_brand = {
        key = "dh_veng_fiery_brand",
        title = "复仇-烈火烙印Aura269不是吸收",
        order = 98,
        hint = "Dummy 40 保持。207744/207771 Aura 269 −40。卸 204022 吸收。",
        startText = "【烈火烙印】必须用会还手的 131992。目标应有 207744 或 207771。CLEU 不要 204022 吸收。不要吸收叠加 Aura 269。12.0 给自己上烙印弃用。",
        startPrint = "请对坦克假人按烈火烙印，再让假人打你。",
        ids = { 204021, 204022, 207744, 207771, 207739 },
        labels = {
            [204021] = "烈火烙印",
            [204022] = "玩家侧光环(不应吸收)",
            [207744] = "烙印减伤",
            [207771] = "活体烈焰烙印",
            [207739] = "活体烈焰",
        },
        chain = {
            { id = 204021, role = "烈火烙印", want = "cast",
              hintFail = "没有 204021。减伤看 207744；点了活体烈焰看 207771。不要对吸收。" },
        },
        extraVerdict = function()
            return {
                "Dummy 40 不是吸收百分比。AddSC 已注释 absorb 类。",
            }
        end,
    },

    dh_veng_fracture = {
        key = "dh_veng_fracture",
        title = "复仇-裂伤263642Dummy2",
        order = 99,
        hint = "Dummy 2。卸 209795。Energize 250 不是 Dummy。",
        startText = "【裂伤】CLEU 必须是 263642，不要 209795。每次丢 Dummy 2 个残片并产痛苦，不要花 30 痛苦。覆盖剪切。",
        startPrint = "请点裂伤天赋后对假人按 263642。",
        ids = { 263642, 209795, 203782 },
        labels = {
            [263642] = "裂伤",
            [209795] = "军团裂伤(不应出现)",
            [203782] = "剪切",
        },
        chain = {
            { id = 263642, role = "裂伤", want = "cast",
              hintFail = "没有 263642。先导入 _06。" },
        },
        extraVerdict = function()
            return {
                "30 痛苦费用弃用。Dummy 只钉 2。",
            }
        end,
    },

    dh_veng_spirit_bomb = {
        key = "dh_veng_spirit_bomb",
        title = "复仇-灵魂炸弹247455",
        order = 100,
        hint = "Dummy 25/5。伤号 247455。涂 224509。",
        startText = "【灵魂炸弹】先攒至少 2 个残片。CLEU 必须是 247455，不要 218677。最多吃 5 个残片。目标应有脆弱 224509。",
        startPrint = "请点灵魂炸弹天赋，攒残片后按 247454。",
        ids = { 247454, 247455, 224509, 227255, 218677 },
        labels = {
            [247454] = "灵魂炸弹",
            [247455] = "灵魂炸弹伤害",
            [224509] = "脆弱",
            [227255] = "脆弱治疗",
            [218677] = "军团伤号(不应出现)",
        },
        chain = {
            { id = 247455, role = "炸弹伤害", want = "damage",
              hintFail = "没有 247455。枚举必须改掉 218677。" },
        },
        extraVerdict = function()
            return {
                "不要 INSERT 247455 到 spell_script_names。过滤器是 SPELL_EFFECT_APPLY_AURA，不是 Aura Dummy。",
            }
        end,
    },

    dh_veng_shear_souls = {
        key = "dh_veng_shear_souls",
        title = "复仇-剪切Dummy8与残片进屋治疗",
        order = 101,
        hint = "203783 Dummy 8 在效果 1。进屋复仇 210042，必须是残片施法者。击杀 Dummy 15 两处都改。喂食 Dummy 5→500ms。最后的手段 PlayerScript OnDamage。",
        startText = "【剪切/残片】剪切产残片按 Dummy 8（效果 1，效果 0 基点 0），不要 15%。自己走进自己的残片应打 210042，别人走进去不要拆残片。击杀残片几率 Dummy 15，恶魔与非恶魔两处都不要 30%。喂食尖刺 CDR 500 ms。点最后的手段 209258，致死应救：治疗约 Dummy 30% 最大生命，上 209261，摘 209258；活路径是 PlayerScript OnDamage，不要吸收、不要 OnEffectNameAbsorb。恶魔卫士 203513 −15% 表已表达，不要挂 278386。精通 203747 不搬家。",
        startPrint = "请用剪切产残片，再走进残片。",
        ids = { 203782, 203783, 210042, 178963, 178940, 204254, 218612, 203513, 278386, 203747, 209258, 209261 },
        labels = {
            [203782] = "剪切",
            [203783] = "剪切被动Dummy8",
            [210042] = "复仇残片治疗",
            [178963] = "浩劫残片治疗",
            [178940] = "浩劫破碎灵魂Dummy15",
            [204254] = "复仇破碎灵魂Dummy15",
            [218612] = "喂食恶魔Dummy5",
            [203513] = "恶魔卫士复仇",
            [278386] = "恶魔卫士浩劫弱版",
            [203747] = "精通邪能之血",
            [209258] = "最后的手段",
            [209261] = "最后的手段减益",
        },
        chain = {
            { id = 210042, role = "复仇残片治疗", want = "heal",
              hintFail = "没有 210042。进屋不要只给浩劫 178963。" },
        },
        extraVerdict = function()
            return {
                "禁止 procChance=15。禁止只改一处 roll_chance_f(30)。进屋必须是残片施法者。最后的手段走 PlayerScript OnDamage，禁止 SCHOOL_ABSORB / OnEffectNameAbsorb。精通不搬家。",
            }
        end,
    },

    hun_c_disengage_posthaste = {
        key = "hun_c_disengage_posthaste",
        title = "猎人共用-逃脱Posthaste含生存",
        order = 102,
        hint = "781 无 Dummy。109215 Dummy 0。118922 不是 Dummy。RangeIndex 50000 不是后跳码数。公开句 20s 是 Rank 2 显示冷却。",
        startText = "【逃脱】120 猎人（必须含一次生存）点 109215 后按 781，应后跳且有 118922。不要按 50000 码跳。鱼叉上的 118922 保留。分类充能仍是 1×30000 + Rank2 −10000。",
        startPrint = "请三专精各按一次逃脱，生存必须有 118922。",
        ids = { 781, 109215, 118922, 231549, 190925 },
        labels = {
            [781] = "逃脱",
            [109215] = "Posthaste",
            [118922] = "Posthaste加速",
            [231549] = "逃脱Rank2",
            [190925] = "鱼叉",
        },
        chain = {
            { id = 781, role = "逃脱", want = "cast",
              hintFail = "没有 781。确认动作条有逃脱。" },
        },
        extraVerdict = function()
            return {
                "生存也必须有 118922。75/20/50000 都不得进 Dummy。不要写后跳距离脚本。",
            }
        end,
    },

    hun_c_flare = {
        key = "hun_c_flare",
        title = "猎人共用-照明弹1543不是28822",
        order = 103,
        hint = "1543 无 Dummy。Trigger 132950。基点 20 不是 Dummy。28822 是旧号 30 秒。",
        startText = "【照明弹】按 1543。CLEU 不要出现 28822。AT 约 20 秒、约 10 码。潜行目标走进圈应显形（OnUnitEnter 摘 SPELL_AURA_MOD_STEALTH / SPELL_AURA_MOD_INVISIBILITY）。禁止再 Cast 28822，禁止对单位 Cast 132950。",
        startPrint = "请对地面按照明弹 1543。",
        ids = { 1543, 132950, 28822 },
        labels = {
            [1543] = "照明弹",
            [132950] = "照明弹AT",
            [28822] = "旧Flare(不应出现)",
        },
        chain = {
            { id = 1543, role = "照明弹", want = "cast",
              hintFail = "没有 1543。不要用 28822 当玩家键。" },
        },
        extraVerdict = function()
            return {
                "28822 不应出现。20 秒不是 Dummy。显形用 RemoveAurasByType，不要 Cast 28822，不要对单位 Cast 132950。",
            }
        end,
    },

    hun_c_tar_trap = {
        key = "hun_c_tar_trap",
        title = "猎人共用-焦油Dummy8",
        order = 104,
        hint = "187699 Dummy 8 是半径。187700 持续 30 秒。135299 −50% 不是 Dummy。",
        startText = "【焦油】按 187698。油池约 30 秒，不要 60 秒。减速 135299。半径按 Dummy 8。不要把 8 写成持续秒数。",
        startPrint = "请放焦油陷阱并踩上去。",
        ids = { 187698, 187699, 187700, 135299 },
        labels = {
            [187698] = "焦油陷阱",
            [187699] = "焦油AT Dummy8",
            [187700] = "焦油油池",
            [135299] = "焦油减速",
        },
        chain = {
            { id = 187698, role = "焦油陷阱", want = "cast",
              hintFail = "没有 187698。" },
        },
        extraVerdict = function()
            return {
                "Dummy 8 不是 60 秒。激活持续读 187700，不要写死 60000。",
            }
        end,
    },

    hun_c_baseline_table = {
        key = "hun_c_baseline_table",
        title = "猎人共用-宁神打断假死表已表达",
        order = 105,
        hint = "19801/147362/187707/5384 不包空脚本。272651 不 INSERT。53480 是 PvP 不验收。wiki 宁神 9.0 弃用。",
        startText = "【表已表达】宁神 19801 驱散 1 层魔法+1 层激怒，冷却 10 秒。BM/MM 打断 147362，生存 187707，不要写成同一个号。假死 5384 能放。Command Pet 动作条 272651，不要 INSERT 脚本，保持 53271。牺牲咆哮 53480 看见也不要勾完成。",
        startPrint = "请按宁神、打断、假死各一次。生存用 187707。",
        ids = { 19801, 147362, 187707, 5384, 272651, 53271, 53480 },
        labels = {
            [19801] = "宁神射击",
            [147362] = "反制射击(BM/MM)",
            [187707] = "锁喉(SV)",
            [5384] = "假死",
            [272651] = "Command Pet",
            [53271] = "主人的召唤(Cunning)",
            [53480] = "牺牲咆哮(PvP不验收)",
        },
        chain = {
            { id = 19801, role = "宁神", want = "cast",
              hintFail = "没有 19801。8.3 有此技能，不要按 wiki 9.0 删掉。" },
        },
        extraVerdict = function()
            return {
                "不要 INSERT 272651。147362 不是 187707。53480 不验收。",
            }
        end,
    },

    hun_mm_rapid_fire = {
        key = "hun_mm_rapid_fire",
        title = "射击-急速射击257044",
        order = 106,
        hint = "Dummy 10/40 都不当跳数。周期 330ms 打 257045+263585。Energize 1 不是 Dummy。",
        startText = "【急速射击】先导入 _08。120 射击对 131989 引导 257044。CLEU 必须有 257045 与 263585。不要手写 40 跳。9.0 的 2 秒弃用。测弹射必须 3+ 假人：先 257620 上 257622，再引导急速。Apply 时若有 257622 则 _trickShots=true 并 ModStackAmount(-1) 一次。整段引导额外目标都要有 257045。不要只弹首跳。不要后续跳再查 257622。单目标看不见弹射。",
        startPrint = "请引导急速射击 257044。测弹射请站到 3 个以上假人前。",
        ids = { 257044, 257045, 263585, 257622, 257620 },
        labels = {
            [257044] = "急速射击",
            [257045] = "急速射击伤害",
            [263585] = "急速射击集中",
            [257622] = "技巧射击buff",
            [257620] = "射击多重",
        },
        chain = {
            { id = 257045, role = "急速射击伤害", want = "damage",
              hintFail = "没有 257045。确认 _08 已导入且 AuraScript 挂 PERIODIC_DUMMY。" },
        },
        extraVerdict = function()
            return {
                "Dummy 10 不是 SimC 跳数。Dummy 40 不得当 40 跳。3+ 假人整段引导额外目标都要有 257045。不要只弹首跳。不要后续跳再查 257622。只上 257622 不算完成。",
            }
        end,
    },

    hun_mm_aimed_precise = {
        key = "hun_mm_aimed_precise",
        title = "射击-瞄准上260242",
        order = 107,
        hint = "19434 Dummy 50 不得当首次命中。260242 Aura 108 75，无 Dummy。",
        startText = "【瞄准】按 19434。必须 CastSpell(GetCaster(), 260242)，自身应有 260242，最多 2 层。木桩身上不要 260242。不要首次命中 +50%。不要 199522。稳固 56641 应回 Dummy 10 集中。测弹射必须 3+ 假人：先 257620 上 257622，再瞄准，额外目标 CLEU 也要有 19434 伤（半径 10 码，不要抄 199522 的 30 码；最多 EFFECT_0 Dummy 5），然后 257622 掉一层。",
        startPrint = "请按瞄准射击，看自身 260242。测弹射请站到 3 个以上假人前。",
        ids = { 19434, 260242, 199522, 56641, 257622, 257620 },
        labels = {
            [19434] = "瞄准射击",
            [260242] = "精确射击(自身)",
            [199522] = "军团天赋(不应再吃)",
            [56641] = "稳固射击",
            [257622] = "技巧射击buff",
            [257620] = "射击多重",
        },
        chain = {
            { id = 260242, role = "精确射击", want = "aura-self",
              hintFail = "没有 260242。必须 CastSpell(GetCaster(), SPELL_HUNTER_PRECISE_SHOTS, true)。禁止对木桩 Cast 260242。" },
        },
        extraVerdict = function()
            return {
                "Dummy 50 不是首次命中，也不是精确射击层数。75 不是 Dummy。260242 必须在自身。弹射半径写死 10 码，Dummy 5 是额外目标数不是码数。不要抄 199522 的 30 码。3+ 目标才能看见 19434 弹射。只上 257622 不算完成。",
            }
        end,
    },

    hun_mm_trueshot = {
        key = "hun_mm_trueshot",
        title = "射击-百发百中288613",
        order = 108,
        hint = "玩家键 288613 不是 193526。Dummy 1 不读。Aura 286=HandleUnused 不会跳。Aura 148 不是周期。OnAuraUpdate 自管 1000 ms 读效果 2 基点 225。公开句 60% 不写。",
        startText = "【百发百中】CLEU 必须是 288613，不要 193526。开 288613 后立刻打一发瞄准，必须看见第二层充能明显快于平时 12 秒（每秒 ReduceChargeCooldown 1250 ms）。只 want=cast 288613 不算过。不要按 60% 对急速射击冷却。不要改 SpellAuraEffects.cpp。不要 OnEffectPeriodic 挂 EFFECT_0。",
        startPrint = "请开 288613，再打瞄准看充能是否加快。只开技能绿了不算过。",
        ids = { 288613, 193526, 19434, 257044 },
        labels = {
            [288613] = "百发百中",
            [193526] = "旧Trueshot(不应作为玩家键)",
            [19434] = "瞄准射击(看充能加快)",
            [257044] = "急速射击(本波不对60%)",
        },
        chain = {
            { id = 288613, role = "百发百中", want = "aura-self",
              hintFail = "没有 288613 光环。确认 _08 已导入。" },
            { id = 19434, role = "瞄准射击", want = "cast",
              hintFail = "开 288613 后必须打瞄准才能看见充能加快。只 want=cast 288613 不算过。" },
        },
        extraVerdict = function()
            return {
                "必须看见瞄准充能恢复变快。只开 288613 不算过。不要写 60。Dummy 1 不读。Aura 286 不实现。不要改 SpellAuraEffects.cpp。",
            }
        end,
    },

    hun_mm_multishot = {
        key = "hun_mm_multishot",
        title = "射击-多重257620不是2643",
        order = 109,
        hint = "257620 无 Dummy。半径 10 码。257621 EFFECT_1 Dummy 3 门槛、EFFECT_0 Dummy 5 额外目标数（不是码数）。瞄准弹射半径写死 10 码，不要抄 199522 的 30 码。上 257622 不够，瞄准/急速必须弹射。BM 2643 不要当射击键。",
        startText = "【多重】射击动作条 CLEU 必须是 257620，不要 2643。必须 3 个以上假人：应上 257622，然后立刻打瞄准或急速，额外目标 CLEU 要有 19434 或 257045，257622 掉一层。只上 buff 不算 MM AoE 完成。不要打 185365。",
        startPrint = "请对 3 个以上假人按射击多重 257620，再打瞄准或急速看弹射。",
        ids = { 257620, 2643, 257621, 257622, 185365, 19434, 257045 },
        labels = {
            [257620] = "射击多重",
            [2643] = "BM多重(不是射击键)",
            [257621] = "技巧射击被动",
            [257622] = "技巧射击buff",
            [185365] = "已删印记(不应出现)",
            [19434] = "瞄准弹射伤",
            [257045] = "急速弹射伤",
        },
        chain = {
            { id = 257620, role = "射击多重", want = "cast",
              hintFail = "没有 257620。确认 _08 已改绑，不要再用 2643。" },
            { id = 257622, role = "技巧射击buff", want = "aura-self",
              hintFail = "3+ 目标才上 257622。上了还不够，必须再打瞄准或急速看弹射。" },
        },
        extraVerdict = function()
            return {
                "2643 是 BM。不要 DELETE beast_cleave。10 码不是 Dummy。Dummy 3 门槛读 EFFECT_1，Dummy 5 额外目标数读 EFFECT_0。只上 257622 不算完成。3+ 目标才能看见弹射。急速整段引导都要有 257045。",
            }
        end,
    },

    hun_mm_lethal_shots = {
        key = "hun_mm_lethal_shots",
        title = "射击-夺命Dummy50与观察窗口20%",
        order = 110,
        hint = "260393 Dummy 50 = CDR 毫秒×100。20% 是观察窗口，禁止写进 Dummy 50。",
        startText = "【夺命射击】点天赋 260393。多次奥术或多重后，急速射击冷却应有时 −5 秒。不要每次必减。不要把 50 当 50% 触发率。召唤射击 Dummy 2500 减 288613。",
        startPrint = "请点夺命射击，多次按奥术，看 257044 冷却。",
        ids = { 260393, 185358, 257620, 257044, 260404, 288613 },
        labels = {
            [260393] = "夺命射击Dummy50",
            [185358] = "奥术射击",
            [257620] = "射击多重",
            [257044] = "急速射击",
            [260404] = "召唤射击Dummy2500",
            [288613] = "百发百中",
        },
        chain = {
            { id = 185358, role = "奥术射击", want = "cast",
              hintFail = "没有 185358。" },
        },
        extraVerdict = function()
            return {
                "20 不得进 Dummy 50。−5000 必须来自 Dummy×100，不要再写死 20%。",
            }
        end,
    },

    hun_sv_mongoose = {
        key = "hun_sv_mongoose",
        title = "生存-猫鼬259387无充能5层",
        order = 111,
        hint = "259387 无 Dummy、无充能。259388 最大 5 层。不是 190928 / 6 层。",
        startText = "【猫鼬】先导入 _09。CLEU 必须是 259387，不要 190928。怒气 259388 最多 5 层。猛禽不要再打 118253。钉刺玩家键是 259491 不是 1978。",
        startPrint = "请点猫鼬天赋，按 259387。",
        ids = { 259387, 259388, 190928, 190931, 186270, 118253, 259491, 1978 },
        labels = {
            [259387] = "猫鼬撕咬",
            [259388] = "猫鼬怒气5层",
            [190928] = "军团猫鼬(不应出现)",
            [190931] = "军团怒气6层(不应作为8.3)",
            [186270] = "猛禽一击",
            [118253] = "军团钉刺跳(猛禽不应再打)",
            [259491] = "生存钉刺",
            [1978] = "经典钉刺(不应作为玩家键)",
        },
        chain = {
            { id = 259387, role = "猫鼬", want = "cast",
              hintFail = "没有 259387。确认 _09 已改绑。" },
        },
        extraVerdict = function()
            return {
                "不要 3 充能。不要 6 层。补篇 6 层弃用当 Dummy。",
            }
        end,
    },

    hun_sv_wildfire = {
        key = "hun_sv_wildfire",
        title = "生存-野火随机三色",
        order = 112,
        hint = "271014 Dummy 0。271020 BaseF 都是 270335，不要都打榴霰。允许同色连发。网页 10 Focus 弃用。",
        startText = "【野火】无灌注时 CLEU 265157/269747。点 271014 后连扔 259495，应随机出现 270339 / 271049 / 270332。允许同色。不要 Cast 玩家键以免 Aura 332 死循环。削凿 Rank2 每命中减野火 Dummy 1000 ms，最多 Dummy 5。点屠宰 212436 时同一套 ReduceChargeCooldown（分类 1716，毫秒=Dummy 1000，上限 Dummy 5，门 294029）。",
        startPrint = "请点野火灌注，连扔炸弹看三色。削凿或屠宰 Rank2 应减野火充能。",
        ids = { 259495, 271014, 270335, 271045, 270323, 265157, 269747, 270338, 270339, 271048, 271049, 270329, 270332, 187708, 212436, 294029 },
        labels = {
            [259495] = "野火炸弹",
            [271014] = "野火灌注Dummy0",
            [270335] = "榴霰",
            [271045] = "易爆",
            [270323] = "信息素Dummy100",
            [265157] = "基线初爆",
            [269747] = "基线跳",
            [270338] = "榴霰初爆",
            [270339] = "榴霰跳",
            [271048] = "易爆初爆",
            [271049] = "易爆跳",
            [270329] = "信息素初爆",
            [270332] = "信息素跳",
            [187708] = "削凿Dummy1000/5",
            [212436] = "屠宰复用carve",
            [294029] = "削凿Rank2门",
        },
        chain = {
            { id = 259495, role = "野火炸弹", want = "cast",
              hintFail = "没有 259495。确认 _09 已导入。" },
        },
        extraVerdict = function()
            return {
                "禁止用 270335 造 Dummy。Dummy 100 不是重置率。10 Focus 弃用。削凿 Rank2 每命中减野火 Dummy 1000 ms，最多 Dummy 5。屠宰 212436 同一套，不要只验 187708。",
            }
        end,
    },

    hun_sv_kill_command = {
        key = "hun_sv_kill_command",
        title = "生存-杀敌259489不是34026",
        order = 113,
        hint = "Dummy 60/25。Energize 15 不是 Dummy。必须 263186 才掷骰 Dummy 25。",
        startText = "【杀敌命令】CLEU 必须是 259489，不要 34026。没学 263186 不应重置。学了按 Dummy 25 掷骰。宠物伤 259277。回 15 集中。",
        startPrint = "请按生存杀敌 259489。先不点 Rank2 看不重置，再点 Rank2。",
        ids = { 259489, 34026, 259277, 263186, 260286 },
        labels = {
            [259489] = "生存杀敌",
            [34026] = "BM杀戮命令(不是生存键)",
            [259277] = "生存杀敌宠物伤",
            [263186] = "杀敌Rank2 Dummy0",
            [260286] = "杀敌Trigger",
        },
        chain = {
            { id = 259489, role = "生存杀敌", want = "cast",
              hintFail = "没有 259489。不要用 34026 验收生存。" },
        },
        extraVerdict = function()
            return {
                "没 Rank2 = 0%。不要把 270323 Dummy 100 加进重置。",
            }
        end,
    },

    hun_sv_coordinated = {
        key = "hun_sv_coordinated",
        title = "生存-协同Aura4 Dummy25",
        order = 114,
        hint = "266779 效果 3 Aura 4 Dummy 25，不是 Aura 226。不要 INSERT 空类。与 259489 Dummy 25 不要混号。",
        startText = "【协同进攻】开 266779。已学 263186 时重置率再加 Dummy 25（合计 50%）。不要按 PERIODIC_DUMMY 注册。不要独立脚本名。",
        startPrint = "请开协同进攻，再按杀敌看重置变密。",
        ids = { 266779, 259489, 263186, 270323 },
        labels = {
            [266779] = "协同进攻Dummy25",
            [259489] = "生存杀敌Dummy25",
            [263186] = "Rank2门",
            [270323] = "信息素Dummy100(不是重置率)",
        },
        chain = {
            { id = 266779, role = "协同进攻", want = "cast",
              hintFail = "没有 266779。表上 Aura 已表达，不要因此去包空脚本。" },
        },
        extraVerdict = function()
            return {
                "两列 Dummy 25 不要混号。Aura 4 不是 226。Dummy 100 不是重置率。",
            }
        end,
    },

    hun_sv_flanking = {
        key = "hun_sv_flanking",
        title = "生存-侧翼269751 Dummy117只乘宠物",
        order = 115,
        hint = "Dummy 117 是宠物伤系数。猎人 269752 AP 1.17 禁止再乘。3.652f 不得进 Dummy。",
        startText = "【侧翼】CLEU 猎人伤 269752、宠物 259516。不要 202800。不要给猎人伤再乘 117%。冷却 40 秒、无费用。",
        startPrint = "请点侧翼天赋，按 269751。",
        ids = { 269751, 269752, 259516, 202800 },
        labels = {
            [269751] = "侧翼打击Dummy117",
            [269752] = "猎人侧翼伤",
            [259516] = "宠物侧翼",
            [202800] = "军团侧翼(不应出现)",
        },
        chain = {
            { id = 269752, role = "猎人侧翼伤", want = "damage",
              hintFail = "没有 269752。不要再用 202800 / 3.652f。" },
        },
        extraVerdict = function()
            return {
                "禁止双乘。1.17/30/3.652f 都不得进 Dummy。",
            }
        end,
    },

    hun_bm_barbed = {
        key = "hun_bm_barbed",
        title = "野兽控制-倒刺272790与246152",
        order = 116,
        hint = "217200 Dummy 5 不是 3 层。狂乱 272790 无 Dummy。246152 不是 Dummy。不要五次 217207。",
        startText = "【倒刺射击】必须有宠物。按 217200。宠物应有 272790，猎人应有 246152。CLEU 不要 217207 连击。Dummy 5 不要拿去对层数。缩放数字等 PET，本包只验光环与技能号。",
        startPrint = "请召唤宠物后按倒刺 217200。",
        ids = { 217200, 272790, 246152, 217207, 19574, 186254 },
        labels = {
            [217200] = "倒刺射击Dummy5",
            [272790] = "狂乱3层",
            [246152] = "倒刺回能",
            [217207] = "军团连击(不应出现)",
            [19574] = "狂野怒火Dummy12",
            [186254] = "狂野怒火宠物",
        },
        chain = {
            { id = 217200, role = "倒刺射击", want = "cast",
              hintFail = "没有 217200。确认动作条是倒刺不是 Dire Frenzy 连击。" },
        },
        extraVerdict = function()
            return {
                "Dummy 5 不是层数。不要假装缩放已过。Bloodshed 不是 8.3。",
            }
        end,
    },

    hun_bm_kill_command = {
        key = "hun_bm_kill_command",
        title = "野兽控制-杀戮命令Dummy112",
        order = 117,
        hint = "34026 Dummy 1/112。不是 4.5f。无回能。83381 AP 列空。精通 76657 不搬家。缩放等 PET。",
        startText = "【杀戮命令】CLEU 34026 + 83381。花 30 集中，不要退还焦点。不要 4.5f。眼镜蛇 193455 应减 Dummy 1 秒。生存键 259489 不要拿来验收 BM。宠物伤害数字等 PET。",
        startPrint = "请按 BM 杀戮命令 34026。",
        ids = { 34026, 83381, 193455, 259489, 76657 },
        labels = {
            [34026] = "BM杀戮命令Dummy112",
            [83381] = "杀戮命令伤害",
            [193455] = "眼镜蛇射击Dummy1",
            [259489] = "生存杀敌(不是BM键)",
            [76657] = "精通万兽之王",
        },
        chain = {
            { id = 83381, role = "杀戮命令伤害", want = "damage",
              hintFail = "没有 83381。确认宠物在场。不要用 4.5f。" },
        },
        extraVerdict = function()
            return {
                "Dummy 112 不是回能。不要勾缩放完成。精通不搬家。",
            }
        end,
    },

    hun_bm_wild_call = {
        key = "hun_bm_wild_call",
        title = "野兽控制-野性呼唤RestoreCharge",
        order = 118,
        hint = "185789 Dummy 40 不是 20%。20% 是观察窗口。217200 用 RestoreCharge，禁止 ResetCooldown。",
        startText = "【野性呼唤】自动射击暴击后倒刺应有时还一层充能，不是每次，也不是把冷却整条清掉。Dummy 40 不要拿来对触发率。有 199528 再加 Aura 107 基点 20。120679 可以 ResetCooldown。",
        startPrint = "请点野性呼唤，自动射击暴击，看倒刺充能。",
        ids = { 185789, 185791, 217200, 120679, 199528, 75 },
        labels = {
            [185789] = "野性呼唤Dummy40",
            [185791] = "野性呼唤触发光环",
            [217200] = "倒刺射击(充能)",
            [120679] = "恐怖野兽",
            [199528] = "兽群羁绊",
            [75] = "自动射击",
        },
        chain = {
            { id = 185789, role = "野性呼唤", want = "aura-self",
              hintFail = "没有 185789 光环。确认点了天赋。" },
        },
        extraVerdict = function()
            return {
                "禁止 ResetCooldown(217200)。20 不得进 Dummy 40。补篇 20% 弃用当 Dummy。",
            }
        end,
    },

    hun_bm_beast_cleave = {
        key = "hun_bm_beast_cleave",
        title = "野兽控制-顺劈Dummy75读表",
        order = 119,
        hint = "115939 Dummy 75。不要 0.75f。2643 不是射击 257620。溅射基数等 PET。",
        startText = "【野兽顺劈】BM 多重 CLEU 必须是 2643，不要 257620。宠物应有 118455。溅射 118459 按 Dummy 75。伤害数字等 PET，本包只验光环与读表，不要假装缩放已过。",
        startPrint = "请对两只以上假人按 BM 多重 2643。",
        ids = { 2643, 257620, 115939, 118455, 118459 },
        labels = {
            [2643] = "BM多重",
            [257620] = "射击多重(不是BM键)",
            [115939] = "野兽顺劈Dummy75",
            [118455] = "顺劈光环",
            [118459] = "顺劈溅射",
        },
        chain = {
            { id = 2643, role = "BM多重", want = "cast",
              hintFail = "没有 2643。射击键是 257620，不要拿来验收 BM。" },
        },
        extraVerdict = function()
            return {
                "Dummy 75 读表，不要 0.75f。缩放等 PET。",
            }
        end,
    },

    rog_c_stealth_vanish = {
        key = "rog_c_stealth_vanish",
        title = "盗贼共用-潜行消失11327不是18461",
        order = 120,
        hint = "1784 Dummy 0/40/0 不要发明侦测半径。1856 无 Dummy。继续打 11327。不要发明 18461。",
        startText = "【潜行/消失】120 盗贼按 1784 应潜行。按 1856 应有 11327 约 3 秒。CLEU 不要 18461。Vigor 不要 SetPower 170。诡诈形状 115191/115192 保留。",
        startPrint = "请按潜行 1784，再按消失 1856。",
        ids = { 1784, 158185, 158188, 1856, 11327, 18461, 115191, 108208 },
        labels = {
            [1784] = "潜行",
            [158185] = "潜行隐身",
            [158188] = "潜行变形",
            [1856] = "消失",
            [11327] = "消失光环",
            [18461] = "无行Trigger(不应出现)",
            [115191] = "诡诈潜行",
            [108208] = "诡诈",
        },
        chain = {
            { id = 1784, role = "潜行", want = "cast",
              hintFail = "没有 1784。确认动作条有潜行。" },
        },
        extraVerdict = function()
            return {
                "11327 必须出现。18461 不应出现。Dummy 40 不得当侦测半径。",
            }
        end,
    },

    rog_c_cheap_shot_kidney = {
        key = "rog_c_cheap_shot_kidney",
        title = "盗贼共用-偷袭1833不是伏击8676",
        order = 121,
        hint = "1833=Cheap Shot。8676=Ambush 不是 ROG-C。肾击 Amount+1 不改 Spell.cpp。",
        startText = "【偷袭/肾击】潜行按 1833，CLEU 必须是 1833 不是 8676，不要 138106。5 连击肾击 408 昏迷约 6 秒（Amount+1）。不要改 Spell.cpp。",
        startPrint = "请潜行按偷袭 1833，再 5 连击肾击。",
        ids = { 1833, 8676, 408, 138106 },
        labels = {
            [1833] = "偷袭Cheap Shot",
            [8676] = "伏击Ambush(不是本包)",
            [408] = "肾击",
            [138106] = "披风与匕首(不应出现)",
        },
        chain = {
            { id = 1833, role = "偷袭", want = "cast",
              hintFail = "没有 1833。不要用 8676 当偷袭。" },
        },
        extraVerdict = function()
            return {
                "8676 不是偷袭。138106 不应出现。肾击 Amount+1 保持。",
            }
        end,
    },

    rog_c_shadowstep = {
        key = "rog_c_shadowstep",
        title = "盗贼共用-暗影步36554不是敏锐专用",
        order = 122,
        hint = "36554 Dummy 0。充能 1×30000。不要写成敏锐专用。狂徒替换是抓钩 195457。",
        startText = "【暗影步】奇袭或敏锐按 36554，应位移约 25 码。不要当成敏锐专用。不要包空 rogue 脚本。狂徒用 195457，本包不验收抓钩循环。",
        startPrint = "请用奇袭或敏锐按暗影步 36554。",
        ids = { 36554, 36563, 195457 },
        labels = {
            [36554] = "暗影步",
            [36563] = "跳跃子技能",
            [195457] = "抓钩(狂徒替换)",
        },
        chain = {
            { id = 36554, role = "暗影步", want = "cast",
              hintFail = "没有 36554。不要只用敏锐验收，也不要写成敏锐专用。" },
        },
        extraVerdict = function()
            return {
                "Dummy 0 保持。不要包空脚本。不要当敏锐专用。",
            }
        end,
    },

    rog_c_baseline_table = {
        key = "rog_c_baseline_table",
        title = "盗贼共用-脚踢瓶闪避佯攻装死表已表达",
        order = 123,
        hint = "1766/185311/5277/1966/13750 不包空脚本。5277 不是 199754。冲动不重做急速。",
        startText = "【表已表达】脚踢 1766 能打断（5 秒锁 / 15 秒 / 5 码）。猩红之瓶 185311 6 秒每秒 5%。闪避 5277 10 秒 100% 躲闪；狂徒是 199754，不要写成同一个号。佯攻 1966 −40% 5 秒。装死 31230 Dummy 7。冲动 13750 表已表达 20% 急速，不要重做。不要 INSERT 这些号的空脚本。",
        startPrint = "请按脚踢、猩红之瓶、闪避、佯攻、装死各一次。",
        ids = { 1766, 185311, 5277, 199754, 1966, 31230, 13750 },
        labels = {
            [1766] = "脚踢",
            [185311] = "猩红之瓶",
            [5277] = "闪避",
            [199754] = "还击(狂徒不是闪避)",
            [1966] = "佯攻",
            [31230] = "装死Dummy7",
            [13750] = "冲动(不重做)",
        },
        chain = {
            { id = 185311, role = "猩红之瓶", want = "cast",
              hintFail = "没有 185311。表已表达，不要因此去包空脚本。" },
        },
        extraVerdict = function()
            return {
                "不要包空脚本。5277 不是 199754。13750 不要重做 20% 急速。瓶 20%/4s 是零售，弃用。",
            }
        end,
    },

    rog_assa_mutilate = {
        key = "rog_assa_mutilate",
        title = "奇袭-毁伤产2不-3",
        order = 124,
        hint = "1329 Dummy 0。Energize 2 不是 Dummy。删 ModifyPower(-3)。5374/27576 不是施法者光环。",
        startText = "【毁伤】120 奇袭打 1329。应产 2 连击，不要 −3。CLEU 双手伤 5374/27576 打在木桩上。不要把 5374 当自己光环。",
        startPrint = "请对木桩按毁伤 1329。",
        ids = { 1329, 5374, 27576 },
        labels = {
            [1329] = "毁伤Dummy0",
            [5374] = "主手伤",
            [27576] = "副手伤",
        },
        chain = {
            { id = 1329, role = "毁伤", want = "cast",
              hintFail = "没有 1329。不要用 1752。" },
        },
        extraVerdict = function()
            return {
                "必须产 2 连击。−3 不是 Dummy。",
            }
        end,
    },

    rog_assa_poisons_dots = {
        key = "rog_assa_poisons_dots",
        title = "奇袭-毒药自身光环与毒伤割裂锁喉",
        order = 125,
        hint = "2823 Dummy 1 自身光环。2818 无 5 层。32645 Dummy 0。1943 Dummy 1。703 Dummy 50 不是 3 秒。",
        startText = "【毒药/DoT】上 2823 后攻击应有 2818，无需武器附魔。毒伤时长 (1+CP) 秒、直伤 *=CP 保留不要双乘。割裂 4+4×CP 秒。潜行锁喉有 1330 约 3 秒，不要把 Dummy 50 当沉默秒数。刀扇 10 码 1 连击。",
        startPrint = "请上致命药膏，再打毒伤/割裂/锁喉/刀扇。",
        ids = { 2823, 2818, 113780, 32645, 1943, 703, 1330, 51723 },
        labels = {
            [2823] = "致命药膏Dummy1",
            [2818] = "致命跳",
            [113780] = "刷新直伤",
            [32645] = "毒伤Dummy0",
            [1943] = "割裂Dummy1",
            [703] = "锁喉Dummy50",
            [1330] = "潜行沉默3秒",
            [51723] = "刀扇Dummy1",
        },
        chain = {
            { id = 2823, role = "致命药膏", want = "cast",
              hintFail = "没有 2823。8.3 是自身光环不是武器附魔。" },
        },
        extraVerdict = function()
            return {
                "不要 5 层。不要 GetCastItem。Dummy 50 不是 3 秒。AP 0.16 不是 Dummy。",
            }
        end,
    },

    rog_assa_envenom_hidden = {
        key = "rog_assa_envenom_hidden",
        title = "奇袭-毒药炸弹Dummy40/4与隐秘消费层",
        order = 126,
        hint = "255544 Dummy 40/4。禁止 /10*CP。270070 最大 20 出 AuraOptions。刀扇消费层。79140 不写 Energize。",
        startText = "【炸弹/隐秘/宿敌】点毒药炸弹后多次毒伤，CLEU 应有时出现 255546 约 4 跳，不要按 CP/10。隐秘叠层后刀扇应清 270070。开宿敌不要一瞬间 +100 能量。",
        startPrint = "请点毒药炸弹与隐秘刀刃，打毒伤和刀扇，再开宿敌。",
        ids = { 32645, 255544, 255545, 255546, 270061, 270070, 51723, 79140, 256495 },
        labels = {
            [32645] = "毒伤Dummy0",
            [255544] = "毒药炸弹Dummy40/4",
            [255545] = "炸弹AT",
            [255546] = "炸弹跳",
            [270061] = "隐秘刀刃Dummy0",
            [270070] = "隐秘层",
            [51723] = "刀扇",
            [79140] = "宿敌",
            [256495] = "宿敌Aura85(不是瞬间100)",
        },
        chain = {
            { id = 32645, role = "毒伤", want = "cast",
              hintFail = "没有毒伤。炸弹挂在毒伤脚本上，不要给 255544 INSERT 空类。" },
        },
        extraVerdict = function()
            return {
                "Dummy 40 是触发%。Dummy 4 是脉冲。禁止 /10*CP。不要瞬间 +100。",
            }
        end,
    },

    rog_assa_talents = {
        key = "rog_assa_talents",
        title = "奇袭-刺客大师280716疾毒盲目侧击淬毒放血",
        order = 127,
        hint = "255989 Dummy 3 不读成秒。256735 潜行−1、出潜行 3000ms。280716 Dummy 0。152152 Dummy 5 加 VW。111240 Dummy 0/35/25。245388 Dummy 1 是壳。200806 Dummy 100。",
        startText = "【天赋】先潜行再开本包。刺客大师：潜行中有 256735，出潜行约 3 秒仍在，Dummy 3 不是秒、不要与铁丝 Dummy 3 混。280716：2818 跳时自身回血，不要 108211。疾毒加 VW Dummy 5，不要再给毁伤加。盲目侧击血量门 Dummy 35、毁伤触发 Dummy 25。淬毒之刃上 245389。放血后流血剩余约减半。",
        startPrint = "请点刺客大师、吸血毒药、疾毒、盲目侧击、淬毒之刃、放血各测一次。",
        ids = { 255989, 256735, 196861, 280716, 108211, 152152, 111240, 121153, 245388, 245389, 200806 },
        labels = {
            [255989] = "刺客大师Dummy3",
            [256735] = "刺客大师buff",
            [196861] = "铁丝Dummy3(不要混号)",
            [280716] = "吸血毒药Dummy0",
            [108211] = "旧吸血(不应当8.3天赋)",
            [152152] = "疾毒Dummy5",
            [111240] = "盲目侧击Dummy0/35/25",
            [121153] = "盲目侧击免费窗",
            [245388] = "淬毒之刃Dummy1",
            [245389] = "自然易伤",
            [200806] = "放血Dummy100",
        },
        chain = {
            { id = 256735, role = "刺客大师buff", want = "aura-self",
              hintFail = "没有 256735。潜行期间应一直在。Dummy 3 不是秒。" },
        },
        extraVerdict = function()
            return {
                "Dummy 3 不读成秒。3000ms 是观察窗口。不要 108211。疾毒只加 VW。",
            }
        end,
    },

    rog_outlaw_sinister = {
        key = "rog_outlaw_sinister",
        title = "狂徒-影袭Dummy35打197834卸1752",
        order = 128,
        hint = "193315 Dummy 35/100。199603 Aura 107 30 不是 Dummy。65 不得进 Dummy。1752 不是狂徒键。",
        startText = "【影袭】CLEU 必须是 193315，不要 1752。额外一击必须是 197834，不要 DealSpellDamage 抄伤。有 199603 时 chance = Dummy35 + 30。",
        startPrint = "请对木桩按影袭 193315。",
        ids = { 193315, 1752, 197834, 199603, 195627 },
        labels = {
            [193315] = "影袭Dummy35",
            [1752] = "旧影袭(不应出现)",
            [197834] = "额外一击",
            [199603] = "骷髅黑帆Aura107 30",
            [195627] = "可乘之机",
        },
        chain = {
            { id = 193315, role = "影袭", want = "cast",
              hintFail = "没有 193315。不要用 1752。" },
        },
        extraVerdict = function()
            return {
                "197834 必须能出现。65/30 不得进 Dummy 35。1752 不应出现。",
            }
        end,
    },

    rog_outlaw_rtb = {
        key = "rog_outlaw_rtb",
        title = "狂徒-骨骰79/20/1灌铅至少2",
        order = 129,
        hint = "193316 Dummy 40 不当概率。79/20/1 观察窗口非 DBC。256171 Dummy 30 不当 2 枚。不要读 240837。",
        startText = "【骨骰】多次 193316 应 1 枚为主、偶尔 2、极少 6。骰子号 193356/199600/193358/193357/199603/193359。有 256171 时至少 2 枚。不要 15/33/40。冲动不重做急速。",
        startPrint = "请多次掷命运骨骰，再点灌铅+冲动测至少 2 枚。",
        ids = { 193316, 256170, 256171, 240837, 13750, 193356, 199600, 193358, 193357, 199603, 193359 },
        labels = {
            [193316] = "命运骨骰Dummy40",
            [256170] = "灌铅骰子",
            [256171] = "灌铅buff Dummy30",
            [240837] = "艾泽里特残留(不应读)",
            [13750] = "冲动(不重做)",
            [193356] = "Broadside",
            [199600] = "Buried Treasure Aura85",
            [193358] = "Grand Melee",
            [193357] = "Ruthless Precision",
            [199603] = "Skull and Crossbones",
            [193359] = "True Bearing",
        },
        chain = {
            { id = 193316, role = "命运骨骰", want = "cast",
              hintFail = "没有 193316。" },
        },
        extraVerdict = function()
            return {
                "Dummy 40 不是概率。79/20/1 注释非 DBC。不要读 240837。不要重做 13750。",
            }
        end,
    },

    rog_outlaw_true_bearing = {
        key = "rog_outlaw_true_bearing",
        title = "狂徒-TrueBearing认2098与Restless Dummy10",
        order = 130,
        hint = "193359 Aura 107 10 不是 Dummy。毫秒=10×100×CP。CheckProc 必须有 2098。79096 Dummy 10 是另一号。152150 不验收。2098 与 196819 共用 eviscerate 禁止只改一边。",
        startText = "【True Bearing / Restless / 斩击】点 True Bearing 后按斩击 2098，冷却必须减。不要只认刺骨 196819。Restless Blades Dummy 10 减冲动/疾跑等。两专精共用 spell_rog_eviscerate，禁止只改 2098 公式。",
        startPrint = "请点 True Bearing，用斩击 2098 花连击，看冲动冷却。",
        ids = { 193359, 2098, 196819, 79096, 152150, 13750 },
        labels = {
            [193359] = "True Bearing Aura107 10",
            [2098] = "斩击Dispatch",
            [196819] = "刺骨(敏锐键)",
            [79096] = "Restless Blades Dummy10",
            [152150] = "死亡从天而降(不验收)",
            [13750] = "冲动",
        },
        chain = {
            { id = 2098, role = "斩击", want = "cast",
              hintFail = "没有 2098。不要用 196819 验收狂徒。" },
        },
        extraVerdict = function()
            return {
                "2098 必须触发 True Bearing。−2000 已删。152150 不验收。不要只改 eviscerate 一边。",
            }
        end,
    },

    rog_outlaw_flurry_rush = {
        key = "rog_outlaw_flurry_rush",
        title = "狂徒-乱舞Dummy30潜能75刀锋冲刺武器大师200733",
        order = 131,
        hint = "13877 Dummy 30 不是 100%。35551 Aura 42 75 不是 20% 也不是主手 30%。271877 Dummy 100 不当 100% 伤。200733 Aura 107 10。禁止 roll 6。禁止把 193537 的 15 抄来。",
        startText = "【乱舞/潜能/刀锋/武器大师】两只假人开乱舞，溅射约 Dummy 30%。副手平砍约 75% 触发 35546。刀锋冲刺 CLEU 271881。点 200733 约 10% 额外一击，不要 6%，不要 193537。",
        startPrint = "请对两只假人开乱舞，再测副手回能、刀锋冲刺、狂徒武器大师。",
        ids = { 13877, 22482, 35551, 35546, 271877, 271881, 200733, 193537, 86392 },
        labels = {
            [13877] = "剑刃乱舞Dummy30",
            [22482] = "乱舞溅射",
            [35551] = "战斗潜能Aura42 75",
            [35546] = "潜能回能",
            [271877] = "刀锋冲刺Dummy100",
            [271881] = "刀锋伤Dummy200",
            [200733] = "狂徒武器大师Aura107 10",
            [193537] = "敏锐武器大师(不要抄15)",
            [86392] = "Main Gauche(不要用)",
        },
        chain = {
            { id = 13877, role = "剑刃乱舞", want = "cast",
              hintFail = "没有 13877。" },
        },
        extraVerdict = function()
            return {
                "Dummy 30 不是 100%。75 不是 Dummy 也不是 20%。不要 86392。不要把 15 抄到狂徒。",
            }
        end,
    },

    rog_sub_backstab_strike = {
        key = "rog_sub_backstab_strike",
        title = "敏锐-背刺Dummy20暗影打击不打36563",
        order = 132,
        hint = "53 Dummy 1/20。185438 无 Dummy。不要 Cast 36563。91023 必定上 91021。196819 与 2098 共用脚本禁止只改一边。",
        startText = "【背刺/暗影打击】身后加 Dummy 20，不要 +30%。暗影打击 CLEU 不要 36563。有 91023 时目标必有 91021。刺骨键是 196819 不是 2098。",
        startPrint = "请站在木桩身后背刺，再潜行暗影打击。",
        ids = { 53, 185438, 36563, 91023, 91021, 196819, 2098 },
        labels = {
            [53] = "背刺Dummy20",
            [185438] = "暗影打击",
            [36563] = "跳跃子技能(不应出现)",
            [91023] = "弱点洞察",
            [91021] = "Find Weakness",
            [196819] = "刺骨",
            [2098] = "斩击(不是敏锐键)",
        },
        chain = {
            { id = 53, role = "背刺", want = "cast",
              hintFail = "没有 53。不要用 200758 当本包必过（本波不验收暗影刃）。" },
        },
        extraVerdict = function()
            return {
                "Dummy 20 不是 30。36563 不应出现。Find Weakness 必定上。不要只改 eviscerate 一边。",
            }
        end,
    },

    rog_sub_shadow_dance = {
        key = "rog_sub_shadow_dance",
        title = "敏锐-影舞5秒2层笼罩238104 Aura411",
        order = 133,
        hint = "185313 无 Dummy。5 秒 / 2 层是 DBC。185422 Dummy 0/40/0 持续跟 185313。禁止 8 秒。238104 Dummy 1 不读成层。+1 层 Aura 411。卸 206237。",
        startText = "【影舞/笼罩】按 185313 约 5 秒、2 层。185422 与它同时结束。不要 8 秒。不要写死 +30 能量。点 238104 后充能上限 3。CLEU 不要 206237。不要给 238104 包空脚本。",
        startPrint = "请按影舞 185313，再点笼罩之影 238104。",
        ids = { 185313, 185422, 238104, 206237, 196976, 196980 },
        labels = {
            [185313] = "影舞5秒2层",
            [185422] = "影舞潜行形Dummy0/40/0",
            [238104] = "笼罩之影Dummy1 Aura411",
            [206237] = "旧笼罩(不应出现)",
            [196976] = "暗影大师Dummy0",
            [196980] = "暗影大师跳能量",
        },
        chain = {
            { id = 185313, role = "影舞", want = "cast",
              hintFail = "没有 185313。" },
        },
        extraVerdict = function()
            return {
                "禁止 8 秒。Dummy 1 不是 +1 层。206237 不应出现。Aura 411 不要补 Handler。",
            }
        end,
    },

    rog_sub_shuriken_nightblade = {
        key = "rog_sub_shuriken_nightblade",
        title = "敏锐-飞镖Dummy50夜刃与龙卷197835",
        order = 134,
        hint = "197835 Dummy 1/50。删 *2。195452 Periodic Dummy 1 不当秒数。277925 Trigger=0 周期打 197835。",
        startText = "【飞镖/夜刃/龙卷】潜行或影舞中飞镖加 Dummy 50，不要 *2。夜刃时长底 6 秒 + 2 秒×连击，不要再 +1。点飞镖龙卷后每秒 CLEU 197835，表不会自动打。",
        startPrint = "请潜行或影舞中按飞镖，再打夜刃，再开飞镖龙卷。",
        ids = { 197835, 195452, 277925, 185422, 185313 },
        labels = {
            [197835] = "飞镖风暴Dummy1/50",
            [195452] = "夜刃Periodic Dummy1",
            [277925] = "飞镖龙卷Trigger0",
            [185422] = "影舞形",
            [185313] = "影舞",
        },
        chain = {
            { id = 197835, role = "飞镖风暴", want = "cast",
              hintFail = "没有 197835。" },
        },
        extraVerdict = function()
            return {
                "Dummy 50 不是 *2。Dummy 1 不当秒数。龙卷必须周期打 197835。",
            }
        end,
    },

    rog_sub_deepening_secret = {
        key = "rog_sub_deepening_secret",
        title = "敏锐-深邃Dummy15/10武器大师15敏锐手法秘密手法",
        order = 135,
        hint = "185314 Dummy 15。秒=15/10×连击。所有敏锐终结技。193537 Aura 360 15 不是 Dummy。196912 Dummy 0 不是 40%。280719 Dummy 2/50。",
        startText = "【深邃/武器大师/手法/秘密手法】刺骨/夜刃/秘密手法都应减影舞充能，不要只认 196819，不要 *3000，不要把 2098 加进深邃。武器大师读 15 不要 6%。平砍必出 196911 不要 40%。秘密手法 CLEU 280720。两专精共用 eviscerate 禁止只改 196819 公式。",
        startPrint = "请点深邃与武器大师与秘密手法，打刺骨看影舞充能，平砍看 196911。",
        ids = { 185314, 196819, 195452, 280719, 280720, 193537, 200733, 196912, 196911, 2098 },
        labels = {
            [185314] = "深邃暗影Dummy15",
            [196819] = "刺骨",
            [195452] = "夜刃",
            [280719] = "秘密手法Dummy2/50",
            [280720] = "秘密手法伤",
            [193537] = "敏锐武器大师Aura360 15",
            [200733] = "狂徒武器大师(不要抄)",
            [196912] = "敏锐手法Dummy0",
            [196911] = "敏锐手法回能",
            [2098] = "斩击(不要进深邃)",
        },
        chain = {
            { id = 196819, role = "刺骨", want = "cast",
              hintFail = "没有 196819。不要用 2098 验收敏锐。" },
        },
        extraVerdict = function()
            return {
                "Dummy 15/10 不是 3000。不要 40%/6%。不要只改 eviscerate 一边。2098 不要进深邃。",
            }
        end,
    },

    mon_c_roll_charges = {
        key = "mon_c_roll_charges",
        title = "武僧共用-滚地翻Dummy175不是码数",
        order = 136,
        hint = "109132 Dummy 175 不读成码数。充能分类 1365：2×20000。迅疾 Aura 453/411 不是 Dummy。",
        startText = "【滚地翻】120 武僧按 109132 应翻出位移，2 层 / 20 秒。不要按 175 码对位移。点迅疾后 3 层 / 15 秒。Chi Torpedo 115008 覆盖滚地翻时仍走同一充能类。",
        startPrint = "请按滚地翻 109132 两次，再点迅疾 115173。",
        ids = { 109132, 107427, 115173, 115008, 157361 },
        labels = {
            [109132] = "滚地翻Dummy175",
            [107427] = "滚地翻触发",
            [115173] = "迅疾",
            [115008] = "真气突(覆盖滚地翻)",
            [157361] = "EnhancedRoll(不加厚)",
        },
        chain = {
            { id = 109132, role = "滚地翻", want = "cast",
              hintFail = "没有 109132。确认动作条有滚地翻。" },
        },
        extraVerdict = function()
            return {
                "Dummy 175 不得当码数。充能 2×20s 走分类 1365。9.0 Rank2 才 2 层是零售，弃用。",
            }
        end,
    },

    mon_c_spear_peace_transcendence = {
        key = "mon_c_spear_peace_transcendence",
        title = "武僧共用-切喉手不放116709嚎镇142895魂体aura",
        order = 137,
        hint = "116705 只打断。116709 无行。嚎镇卸 140023，击退 142895。aura_monk_transcendence 必须进 AddSC。",
        startText = "【切喉/嚎镇/魂体】酒仙或踏风按 116705 应打断，CLEU 不要 116709。点嚎镇 116844，圈内敌人 CLEU 必须有 142895，不要 140023。按 101643 出灵魂，取消后灵魂消失。织雾没有切喉手。",
        startPrint = "请用酒仙或踏风打断、放嚎镇、放魂体。",
        ids = { 116705, 116709, 116844, 140023, 142895, 101643, 119996, 119051 },
        labels = {
            [116705] = "切喉手SpearHand",
            [116709] = "已删沉默(不应出现)",
            [116844] = "嚎镇八方Dummy1",
            [140023] = "已删嚎镇光环(不应出现)",
            [142895] = "嚎镇击退",
            [101643] = "魂体双分",
            [119996] = "魂体转移",
            [119051] = "灵魂克隆",
        },
        chain = {
            { id = 116844, role = "嚎镇八方", want = "cast",
              hintFail = "没有 116844。确认点了天赋平心之环。" },
        },
        extraVerdict = function()
            return {
                "116709 不应出现。142895 必须出现。140023 不应出现。魂体取消后灵魂应消失。",
            }
        end,
    },

    mon_c_chi_wave_burst_jade = {
        key = "mon_c_chi_wave_burst_jade",
        title = "武僧共用-真气波selector爆裂AT1315碎玉Dummy200",
        order = 138,
        hint = "115098 Dummy 7 第一跳已读。selector 必须进 AddSC。123986 Dummy 2 不是跳数。117952 Dummy 200/10 击退。",
        startText = "【波/爆裂/碎玉】点真气波 115098，应弹约 7 跳。点真气爆裂 123986，直线应有伤 148135 与治疗 130654，Dummy 2 不要当跳数。引导碎玉 117952，近战攻击者有时被 117962 击退，不要 25% 回真气。禁止 WW 第二套真气波。",
        startPrint = "请点真气波、真气爆裂，再引导碎玉。",
        ids = { 115098, 132466, 132463, 132467, 123986, 148135, 130654, 117952, 117962, 123333 },
        labels = {
            [115098] = "真气波Dummy7",
            [132466] = "真气波selector",
            [132463] = "真气波治疗",
            [132467] = "真气波伤害",
            [123986] = "真气爆裂Dummy2",
            [148135] = "爆裂伤害",
            [130654] = "爆裂治疗",
            [117952] = "碎玉Dummy200",
            [117962] = "碎玉击退",
            [123333] = "碎玉回真气(不应靠25%)",
        },
        chain = {
            { id = 115098, role = "真气波", want = "cast",
              hintFail = "没有 115098。确认点了天赋真气波。" },
        },
        extraVerdict = function()
            return {
                "Dummy 7 是跳数。Dummy 2 不是跳数。Dummy 200/10 是击退几率，20 不得进 Dummy。4.125 不是 Dummy。",
            }
        end,
    },

    mon_c_baseline_table = {
        key = "mon_c_baseline_table",
        title = "武僧共用-扫堂腿分筋错骨清创活血表已表达",
        order = 139,
        hint = "119381/115078/115450/218164 不包空脚本。264348 不是扫堂腿。243435 不接 115203。活血不包读条。",
        startText = "【表已表达】扫堂腿 119381 昏迷约 3 秒 / 5 码，不是 264348。分筋错骨 115078 昏迷约 60 秒。织雾清创 115450；酒仙/踏风 218164。活血 116670 能打，不要手写 1.5 秒。迅如猛虎 116841 清减速。酒仙壮胆酒 115203→120954；织雾 243435 不要 120954。禅意修行 115176 只酒仙，本包不勾完成。轮回 115080 本包不勾完成。",
        startPrint = "请按扫堂腿、分筋错骨、清创、活血、迅如猛虎各一次。",
        ids = { 119381, 264348, 115078, 115450, 218164, 116670, 116841, 115203, 120954, 243435, 115176, 115080 },
        labels = {
            [119381] = "扫堂腿LegSweep",
            [264348] = "猛虎扫尾(不是扫堂腿)",
            [115078] = "分筋错骨",
            [115450] = "织雾清创",
            [218164] = "酒仙踏风清创",
            [116670] = "活血(不包读条)",
            [116841] = "迅如猛虎",
            [115203] = "酒仙壮胆酒Dummy10",
            [120954] = "酒仙壮胆酒光环",
            [243435] = "织雾壮胆酒(不接115203)",
            [115176] = "禅意修行(只酒仙)",
            [115080] = "轮回之触(只踏风验收)",
        },
        chain = {
            { id = 119381, role = "扫堂腿", want = "cast",
              hintFail = "没有 119381。不要用 264348 当扫堂腿。" },
        },
        extraVerdict = function()
            return {
                "不要包空脚本。264348 不是扫堂腿。243435 不要接 115203。1.5 秒读条不得进 Dummy。现役 6 码扫堂腿弃用。",
            }
        end,
    },

    mon_brew_stagger_iron = {
        key = "mon_brew_stagger_iron",
        title = "酒仙-醉拳Dummy90/35铁骨215479",
        order = 140,
        hint = "物理 Dummy 90，魔法 Dummy 35。Dummy 1000 不是持续。115308 上 215479。Dummy 75 不进修正。必须挨打桩。",
        startText = "【醉拳/铁骨】120 酒仙站 131992 挨打，应有 124255。按 115308 应有 215479。不要 322507 / 115307。Dummy 75 不要当 +75%。视觉约 10 秒不要写成 Dummy 1000。",
        startPrint = "请站坦克假人挨打，再按铁骨 115308。",
        ids = { 115069, 124255, 124275, 124274, 124273, 115308, 215479, 322507, 115307 },
        labels = {
            [115069] = "醉拳Dummy90/1000/35",
            [124255] = "醉拳跳",
            [124275] = "轻醉拳",
            [124274] = "中醉拳",
            [124273] = "重醉拳",
            [115308] = "铁骨玩家键",
            [215479] = "铁骨光环+270",
            [322507] = "天神酒(不是8.3)",
            [115307] = "Shuffle(不是8.3)",
        },
        chain = {
            { id = 115308, role = "铁骨酒", want = "cast",
              hintFail = "没有 115308。确认是酒仙。" },
        },
        extraVerdict = function()
            return {
                "必须挨打桩。Dummy 1000 不是持续。322507/115307 不应出现。+270 不是 Dummy。",
            }
        end,
    },

    mon_brew_purify_keg_breath = {
        key = "mon_brew_purify_keg_breath",
        title = "酒仙-净化Dummy50酒缸破Dummy4火焰之息",
        order = 141,
        hint = "119582 Dummy 50。121253 Dummy 4 减酒 CD。不要 127796/115798/116330。有酒缸破才跳 123725。必须挨打桩。",
        startText = "【净化/酒缸破/火焰之息】挨打出醉拳后按 119582，124255 应少约一半。按 121253 后铁骨/净化剩余 CD 少 4 秒，CLEU 不要失踪号。目标有 121253 再按 115181 应有 123725。",
        startPrint = "请挨打、净化、酒缸破、火焰之息。",
        ids = { 119582, 121253, 115181, 123725, 127796, 115798, 116330, 115308 },
        labels = {
            [119582] = "净化Dummy50",
            [121253] = "酒缸破Dummy4",
            [115181] = "火焰之息",
            [123725] = "火焰之息跳",
            [127796] = "失踪号(不应出现)",
            [115798] = "失踪号(不应出现)",
            [116330] = "DizzyingHaze(不应出现)",
            [115308] = "铁骨(看CD)",
        },
        chain = {
            { id = 121253, role = "酒缸破", want = "cast",
              hintFail = "没有 121253。" },
        },
        extraVerdict = function()
            return {
                "Dummy 4 是减酒秒数。失踪号不应出现。没酒缸破不要上 123725。",
            }
        end,
    },

    mon_brew_expel_ox = {
        key = "mon_brew_expel_ox",
        title = "酒仙-移花Dummy10赐福Dummy35",
        order = 142,
        hint = "Dummy 10=伤占治疗比。Dummy 30 不读。赐福 Dummy 35。删 50% 与 0.75。必须挨打桩。",
        startText = "【移花/赐福】按 115072 自身治疗，最近一个敌人 CLEU 115129 约 10%，不要 50%、不要一圈。挨打后有时出 124503/124506，几率读 Dummy 35，不要 0.75 公式。",
        startPrint = "请按移花接木，再站桩挨打看赐福球。",
        ids = { 115072, 115129, 124502, 124503, 124506, 124507 },
        labels = {
            [115072] = "移花Dummy30/10",
            [115129] = "移花伤害",
            [124502] = "赐福Dummy35",
            [124503] = "赐福球右",
            [124506] = "赐福球左",
            [124507] = "赐福治疗",
        },
        chain = {
            { id = 115072, role = "移花接木", want = "cast",
              hintFail = "没有 115072。" },
        },
        extraVerdict = function()
            return {
                "Dummy 10 是百分比。Dummy 30 不读。0.75 与 SimC 1.0 不得进 Dummy。必须挨打桩。",
            }
        end,
    },

    mon_brew_mastery_guard_combo = {
        key = "mon_brew_mastery_guard_combo",
        title = "酒仙-精通不搬家金钟罩115295幻灭连击",
        order = 143,
        hint = "117906 留 spell_monk.cpp。115295 不是 202162。196736 Dummy 100/3/2/3。196737 不包空。必须挨打桩。",
        startText = "【精通/金钟罩/天赋】挨打或幻灭打击应叠 195630，火焰之息不要叠。按 115295 有吸收，不要 202162、不要 AP×18。点 196736 后虎掌更痛。点 280515 醉拳更长。点 196737 不要空脚本。不要 Shuffle / 天神酒。",
        startPrint = "请挨打看精通层，再按金钟罩，再点幻灭连击与闪转腾挪。",
        ids = { 117906, 195630, 205523, 115181, 115295, 202162, 196736, 280515, 196737, 115203, 120954 },
        labels = {
            [117906] = "酒仙精通(不搬家)",
            [195630] = "醉拳大师层",
            [205523] = "幻灭打击",
            [115181] = "火焰之息(不应叠精通)",
            [115295] = "金钟罩",
            [202162] = "PvP Guard(不应出现)",
            [196736] = "幻灭连击Dummy100/3/2/3",
            [280515] = "闪转腾挪Dummy30",
            [196737] = "千杯Dummy5",
            [115203] = "酒仙壮胆酒",
            [120954] = "酒仙壮胆酒光环",
        },
        chain = {
            { id = 115295, role = "金钟罩", want = "cast",
              hintFail = "没有 115295。不要用 202162。" },
        },
        extraVerdict = function()
            return {
                "117906 不搬家。18 不得进 Dummy。202162 不应出现。必须挨打桩。",
            }
        end,
    },

    mon_ww_tiger_bok_rsk = {
        key = "mon_ww_tiger_bok_rsk",
        title = "踏风-猛虎掌Dummy5不是5真气幻灭踢旭日115804",
        order = 144,
        hint = "Dummy 5 是酒仙列。Combo Breaker Dummy 8。100784 补家。107428 打 115804。不要 118864。",
        startText = "【掌/踢/旭日】猛虎掌产 2 真气，有时 116768。CLEU 不要 118864。幻灭踢 100784 有伤。旭日目标有 115804。不要第二套旭日脚本。",
        startPrint = "请按猛虎掌、幻灭踢、旭日东升踢。",
        ids = { 100780, 137025, 137384, 116768, 118864, 100784, 107428, 185099, 115804 },
        labels = {
            [100780] = "猛虎掌Dummy1/5",
            [137025] = "踏风专精+2真气",
            [137384] = "ComboBreakerDummy8",
            [116768] = "幻灭踢触发",
            [118864] = "已删jab(不应出现)",
            [100784] = "幻灭踢Dummy0/1000",
            [107428] = "旭日东升踢",
            [185099] = "旭日伤害",
            [115804] = "致死伤口",
        },
        chain = {
            { id = 100784, role = "幻灭踢", want = "cast",
              hintFail = "没有 100784。dump 以前无行，确认已导入 _17。" },
        },
        extraVerdict = function()
            return {
                "Dummy 5 不得当 5 真气。118864 不应出现。不要第二套 107428 脚本。3000 ms 不得进 Dummy。",
            }
        end,
    },

    mon_ww_fof_sef_wdp = {
        key = "mon_ww_fof_sef_wdp",
        title = "踏风-怒雷破删5.25fSEF进AddSC升龙霸113656",
        order = 145,
        hint = "Dummy 50=额外目标%。C++ 不乘 Dummy −55。fistsOfFuryInfo=113656。45% 不得进 Dummy。",
        startText = "【怒雷破/SEF/升龙霸】113656 CLEU 必须有 117418，不要 AP×5.25。开 137639 分身跟打，不要再乘 −55。怒雷破与旭日都在冷却时才能按 152175。",
        startPrint = "请按怒雷破，开风火雷电，再看升龙霸窗口。",
        ids = { 113656, 117418, 120086, 137639, 138121, 138123, 152175, 196742, 158221, 107428 },
        labels = {
            [113656] = "怒雷破Dummy50",
            [117418] = "怒雷破伤害",
            [137639] = "风火雷电Dummy-55",
            [138121] = "土灵魂",
            [138123] = "火灵魂",
            [152175] = "升龙霸",
            [196742] = "升龙霸可按窗口",
            [158221] = "升龙霸伤害",
            [107428] = "旭日(不是FoF信息)",
        },
        chain = {
            { id = 113656, role = "怒雷破", want = "cast",
              hintFail = "没有 113656。" },
        },
        extraVerdict = function()
            return {
                "5.25 不是 Dummy。Dummy −55 不在 C++ 再乘。45/90秒/2层不得互填 Dummy。",
            }
        end,
    },

    mon_ww_tod_karma_sck = {
        key = "mon_ww_tod_karma_sck",
        title = "踏风-轮回Dummy35业报50/70神鹤鹤印",
        order = 146,
        hint = "放大器基点 10 不是 Dummy 0。Dummy 50 吸收、Dummy 70 弹回。+10% 出 220358。",
        startText = "【轮回/业报/神鹤】115080 8 秒 Dummy 35% 最大生命。放大器读 271232 基点 10。122470 吸收约 50% 最大生命，弹回 70%。101546 上 228287，不要把 Dummy 15 当 15% 伤。",
        startPrint = "请按轮回之触、业报之触、神鹤乱舞。",
        ids = { 115080, 229980, 271232, 271233, 122470, 125174, 124280, 280195, 101546, 228287, 220358, 220357 },
        labels = {
            [115080] = "轮回Dummy1/35",
            [229980] = "轮回伤害",
            [271232] = "放大器基点10",
            [271233] = "放大器Dummy0(不读成%)",
            [122470] = "业报Dummy0/50/70",
            [125174] = "业报自身",
            [124280] = "业报弹回",
            [101546] = "神鹤乱舞Dummy0/15",
            [228287] = "鹤印",
            [220358] = "神鹤+10%Aura108",
            [220357] = "CycloneDummy10",
        },
        chain = {
            { id = 115080, role = "轮回之触", want = "cast",
              hintFail = "没有 115080。确认是踏风。" },
        },
        extraVerdict = function()
            return {
                "9.0 斩杀弃用。100% 业报弃用。5 层 50% 不得进 Dummy。10 不是 Dummy。",
            }
        end,
    },

    mon_ww_serenity_talents = {
        key = "mon_ww_serenity_talents",
        title = "踏风-屏气覆盖SEF真气击打碧玉疾风116847Disable",
        order = 147,
        hint = "152173 无 Dummy。116847 不是 196725。Disable Dummy 1 本 Task。115636 不搬家。聚雷茶 Aura 85 不写 Energize。",
        startText = "【屏气/天赋】点 152173 覆盖风火雷电。点 261947 / 116847 / 196740 / 261767 / 280197。白虎 123904 出 63508。Disable 116095 Dummy 1 本包验收。聚雷茶 115288 能量慢慢涨，不要瞬间 +75。精通 115636 换技能加伤，不搬家。真气波不要第二套。286585 只登记。",
        startPrint = "请点屏气凝神与 T90/T100 天赋各打一次，再按 Disable。",
        ids = { 152173, 261947, 116847, 196725, 196740, 261767, 261769, 280197, 123904, 116095, 115288, 115636, 115098, 286585, 205320 },
        labels = {
            [152173] = "屏气凝神",
            [261947] = "真气击打",
            [116847] = "碧玉疾风WWDummy2",
            [196725] = "织雾碧玉疾风(不是本包)",
            [196740] = "疾风乱打Dummy0",
            [261767] = "内力Dummy25",
            [261769] = "内力减伤层",
            [280197] = "灵魂聚焦点Dummy2/1000",
            [123904] = "白虎下凡",
            [116095] = "DisableDummy1",
            [115288] = "聚雷茶Aura85",
            [115636] = "踏风精通(不搬家)",
            [115098] = "真气波(不要第二套)",
            [286585] = "DanceOfChiJi(只登记)",
            [205320] = "风领主之击(不加厚)",
        },
        chain = {
            { id = 152173, role = "屏气凝神", want = "cast",
              hintFail = "没有 152173。确认点了天赋。" },
        },
        extraVerdict = function()
            return {
                "116847 不是 196725。Dummy 25 不是 5×5。75/2 不得进 Dummy。115636 不搬家。",
            }
        end,
    },

    mon_mw_cocoon_renewing = {
        key = "mon_mw_cocoon_renewing",
        title = "织雾-作茧Dummy60复苏不读Dummy4",
        order = 148,
        hint = "吸收=最大生命×Dummy60/100。Dummy 4 不读。跳转 119607。必须治疗假人。",
        startText = "【作茧/复苏】对治疗假人按 116849，吸收约最大生命 60%，不要 SP×11。按 115151 上 119611；满血后 CLEU 119607。Dummy 4 不要当跳数。",
        startPrint = "请对治疗假人按作茧缚命和复苏之雾。",
        ids = { 116849, 115151, 119611, 119607, 231606 },
        labels = {
            [116849] = "作茧Dummy60",
            [115151] = "复苏Dummy0/4",
            [119611] = "复苏HoT",
            [119607] = "复苏跳转",
            [231606] = "无行(不要写)",
        },
        chain = {
            { id = 116849, role = "作茧缚命", want = "cast",
              hintFail = "没有 116849。必须用治疗假人。" },
        },
        extraVerdict = function()
            return {
                "SP×11 与 31.164 弃用。Dummy 4 不是跳数。必须治疗假人。",
            }
        end,
    },

    mon_mw_soothe_font_rising = {
        key = "mon_mw_soothe_font_rising",
        title = "织雾-抚慰瞬发精华之泉基点6升腾迷雾+4秒",
        order = 149,
        hint = "删 116335/193884。人数读基点 6 不是 Dummy。有 274909 才延长。删 100 码 Refresh。必须治疗假人。",
        startText = "【抚慰/泉/升腾迷雾】引导 115175 时按 124682/116670 应瞬发，CLEU 不要 116335。191837 每波约 6 人有 191840，不要空列表。点 274909 再旭日，HoT +4 秒封顶 Dummy 100，不要 100 码全刷。",
        startPrint = "请引导抚慰并瞬发氤氲，再按精华之泉，再点升腾迷雾打旭日。",
        ids = { 115175, 124682, 116670, 116335, 193884, 191837, 191840, 107428, 274909, 274912, 115804 },
        labels = {
            [115175] = "抚慰之雾",
            [124682] = "氤氲之雾",
            [116670] = "活血",
            [116335] = "已删回气(不应出现)",
            [193884] = "已删自动引导(不应出现)",
            [191837] = "精华之泉基点6",
            [191840] = "泉跳",
            [107428] = "旭日(共用函数)",
            [274909] = "升腾迷雾Dummy100",
            [274912] = "升腾迷雾治疗",
            [115804] = "致死伤口(踏风边不是本包)",
        },
        chain = {
            { id = 191837, role = "精华之泉", want = "cast",
              hintFail = "没有 191837。必须用治疗假人。" },
        },
        extraVerdict = function()
            return {
                "基点 6 不是 Dummy。4 秒不是 Dummy。100 码 Refresh 应已删。116335 不应出现。",
            }
        end,
    },

    mon_mw_mana_teachings = {
        key = "mon_mw_mana_teachings",
        title = "织雾-法力茶197908禅院Dummy15生生不息不打132120",
        order = 150,
        hint = "197908 不是 115294。ResetCooldown 不是 RestoreCharge。132120 无行。必须治疗假人。",
        startText = "【法力茶/禅院/生生不息】按 197908 应 −50% 法力约 12 秒，不要层数通道。虎掌叠 202090 最多 3 层；幻灭踢有时重置旭日冷却。活血后 197919；氤氲 124682 后 197916，CLEU 不要 132120。",
        startPrint = "请按法力茶，再打虎掌叠禅院，再测生生不息。",
        ids = { 197908, 115294, 115867, 123766, 116645, 202090, 100780, 100784, 107428, 197915, 197919, 197916, 132120, 124682 },
        labels = {
            [197908] = "法力茶8.3键",
            [115294] = "MoP法力茶(不应当8.3)",
            [115867] = "MoP层数(不应出现)",
            [123766] = "MoP层数脚本(已卸)",
            [116645] = "禅院Dummy15",
            [202090] = "禅院层Dummy1",
            [100780] = "猛虎掌",
            [100784] = "织雾幻灭踢",
            [107428] = "旭日(看重置)",
            [197915] = "生生不息Dummy0",
            [197919] = "活血后减费",
            [197916] = "氤氲后减费",
            [132120] = "已删号(不应出现)",
            [124682] = "氤氲之雾",
        },
        chain = {
            { id = 197908, role = "法力茶", want = "cast",
              hintFail = "没有 197908。不要用 115294。" },
        },
        extraVerdict = function()
            return {
                "115294/123766 不应当 8.3。132120 不应出现。3 层不要写成 Dummy 15。必须治疗假人。",
            }
        end,
    },

    mon_mw_chiji_revival_tft = {
        key = "mon_mw_chiji_revival_tft",
        title = "织雾-朱鹤三人雷茶消耗碧玉疾风196725壮胆酒不接115203",
        order = 151,
        hint = "198756 三人观察窗口非 Dummy。116680 不要只绑 T12。196725 不是 116847。243435 不接 115203。117907 不搬家。必须治疗假人。",
        startText = "【朱鹤/还魂/雷茶/源泉】点 198664 应出朱鹤，198756 最多打 3 个友方。115310 能群疗驱散（表已表达）。116680 下一发治疗技能吃掉；吃氤氲有 274062。274963 Dummy 6。196725 不是 116847。243435 不要 120954。117907 不搬家。205406 不加厚。",
        startPrint = "请点朱鹤、还魂、雷茶、升腾源泉、碧玉疾风 196725、织雾壮胆酒。",
        ids = { 198664, 198756, 115310, 116680, 274062, 197895, 274963, 196725, 116847, 243435, 115203, 120954, 117907, 205406, 286585 },
        labels = {
            [198664] = "朱鹤下凡",
            [198756] = "朱鹤治疗AP0.45",
            [115310] = "还魂术",
            [116680] = "雷光聚神茶",
            [274062] = "雷茶吃氤氲",
            [197895] = "专注雷茶",
            [274963] = "升腾源泉Dummy6",
            [196725] = "织雾碧玉疾风Dummy6",
            [116847] = "踏风碧玉疾风(不是本包)",
            [243435] = "织雾壮胆酒",
            [115203] = "酒仙壮胆酒(不应接到织雾)",
            [120954] = "酒仙壮胆酒光环(不应出现)",
            [117907] = "织雾精通(不搬家)",
            [205406] = "神龙之赐(不加厚)",
            [286585] = "DanceOfChiJi(只登记)",
        },
        chain = {
            { id = 116680, role = "雷光聚神茶", want = "cast",
              hintFail = "没有 116680。不要只靠 T12 4P。" },
        },
        extraVerdict = function()
            return {
                "3 人不得进 Dummy。196725 不是 116847。243435 不要 120954。117907 不搬家。必须治疗假人。",
            }
        end,
    },

    mag_c_blink_shimmer = {
        key = "mag_c_blink_shimmer",
        title = "法师共用-闪现分类1446闪光不抄Aura77",
        order = 152,
        hint = "1953 无 Dummy。充能 1446=1×15000。212653 无 Dummy。1632=2×20000。不要抄 Aura 77。现役 20 秒闪现弃用。",
        startText = "【闪现/闪光】120 法师按 1953 应位移，1 层 / 15 秒，昏迷中应解控。点 212653 覆盖闪现，2 层 / 20 秒，施法中可放，昏迷中不能解控。不要 INSERT 闪光到 spell_mage_blink。",
        startPrint = "请按闪现 1953，再点闪光 212653。",
        ids = { 1953, 212653, 235365, 198064 },
        labels = {
            [1953] = "闪现(无Dummy)",
            [212653] = "闪光(不抄Aura77)",
            [235365] = "炽热灵魂(火焰天赋)",
            [198064] = "PrismaticCloak(本期不验收)",
        },
        chain = {
            { id = 1953, role = "闪现", want = "cast",
              hintFail = "没有 1953。点了闪光则动作条是 212653。" },
        },
        extraVerdict = function()
            return {
                "充能秒数不写进脚本。闪光不要解昏迷。现役 20 秒闪现弃用。",
            }
        end,
    },

    mag_c_table_baseline = {
        key = "mag_c_table_baseline",
        title = "法师共用-反制偷取变形新星缓落隐形66解咒智慧表已表达",
        order = 153,
        hint = "2139/30449/118/122/130/66/475/1459 不包空脚本。不要 Cast 35009。110959 不是三专精。",
        startText = "【表已表达】反制 2139 打断。偷取 30449。变形 118。冰霜新星 122 根。缓落 130。隐形 66 能进，CLEU 不要 35009。解咒 475。奥术智慧 1459。不要包空脚本。不要勾 110959/205025/31589。",
        startPrint = "请按反制、变形、冰霜新星、隐形 66、奥术智慧各一次。",
        ids = { 2139, 30449, 118, 122, 130, 66, 35009, 475, 1459, 110959, 205025, 31589 },
        labels = {
            [2139] = "法术反制",
            [30449] = "法术偷取",
            [118] = "变形术",
            [122] = "冰霜新星",
            [130] = "缓落术",
            [66] = "隐形",
            [35009] = "已删威胁(不应出现)",
            [475] = "解除诅咒",
            [1459] = "奥术智慧",
            [110959] = "强化隐形(只奥术Task2)",
            [205025] = "咒术涌动(只奥术)",
            [31589] = "减速(只奥术)",
        },
        chain = {
            { id = 2139, role = "法术反制", want = "cast",
              hintFail = "没有 2139。确认动作条有法术反制。" },
        },
        extraVerdict = function()
            return {
                "不要包空脚本。35009 不应出现。110959 不是三专精基线。",
            }
        end,
    },

    mag_c_ice_block_timewarp = {
        key = "mag_c_ice_block_timewarp",
        title = "法师共用-寒冰屏障41425时间扭曲80354",
        order = 154,
        hint = "45438 无 Dummy。80353 无 Dummy。11426 Dummy 22 不是本包。108978 无行。",
        startText = "【屏障/时间扭曲】按 45438 应免疫约 10 秒，出 41425。按 80353 团队急速，自身 80354。不要验收 11426（只冰霜）。不要把 108978 当 8.3。",
        startPrint = "请按寒冰屏障 45438 和时间扭曲 80353。",
        ids = { 45438, 41425, 80353, 80354, 11426, 108978, 235297 },
        labels = {
            [45438] = "寒冰屏障",
            [41425] = "低温Dummy0",
            [80353] = "时间扭曲",
            [80354] = "时间位移疲惫",
            [11426] = "寒冰护体(只冰霜)",
            [108978] = "AlterTime(8.3无行)",
            [235297] = "冰川绝缘(冰霜天赋)",
        },
        chain = {
            { id = 45438, role = "寒冰屏障", want = "cast",
              hintFail = "没有 45438。" },
        },
        extraVerdict = function()
            return {
                "108978 不得当 8.3。11426 本包不勾完成。",
            }
        end,
    },

    mag_c_mirror_rune = {
        key = "mag_c_mirror_rune",
        title = "法师共用-镜像Dummy3能量符文Dummy0不读AT304",
        order = 155,
        hint = "55342 Dummy 3=分身个数。116011 Dummy 0 不读。116014 Aura 108 40 不是 Dummy。AT 304→2947。",
        startText = "【镜像/符文】点 55342 应出 3 个分身。点 116011 地上符文，站上去有 116014。不要把 Dummy 0 写成 40%。1463 咒术洪流本包看见也不要当 MAG-C 必过（周期 Dummy 0 已接线）。",
        startPrint = "请点镜像 55342 和能量符文 116011。",
        ids = { 55342, 58831, 58833, 58834, 116011, 116014, 1463, 116267 },
        labels = {
            [55342] = "镜像Dummy3",
            [58831] = "分身前",
            [58833] = "分身右",
            [58834] = "分身左",
            [116011] = "能量符文Dummy0",
            [116014] = "符文光环Aura108_40",
            [1463] = "咒术洪流Dummy0",
            [116267] = "咒术洪流层",
        },
        chain = {
            { id = 55342, role = "镜像", want = "cast",
              hintFail = "没有 55342。确认点了 T45 镜像。" },
        },
        extraVerdict = function()
            return {
                "Dummy 3 是分身个数。Dummy 0 不是 +40%。40 不得进 Dummy。",
            }
        end,
    },

    mag_arc_blast_missiles_barrage = {
        key = "mag_arc_blast_missiles_barrage",
        title = "奥术-冲击飞弹弹幕Dummy40不是跳人数",
        order = 156,
        hint = "30451 无 Dummy。5143 Dummy 0 不是跳数。44425 Dummy 40=次要伤%。231564 Aura 107 +1 不是 Dummy。",
        startText = "【冲击/飞弹/弹幕】120 奥术打 30451 叠充能。节能下 5143 出 7268。4 层 44425 次要约 Dummy 40%，不要对成 40 个目标。共鸣 Dummy 10 可叠。",
        startPrint = "请打奥术冲击、飞弹、弹幕。",
        ids = { 30451, 5143, 7268, 44425, 263725, 264774, 205028, 231564, 36032 },
        labels = {
            [30451] = "奥术冲击",
            [5143] = "奥术飞弹Dummy0",
            [7268] = "飞弹伤害",
            [44425] = "弹幕Dummy40",
            [263725] = "节能效果",
            [264774] = "三法则buff",
            [205028] = "共鸣Dummy10",
            [231564] = "弹幕Rank2(不是Dummy)",
            [36032] = "奥术充能",
        },
        chain = {
            { id = 30451, role = "奥术冲击", want = "cast",
              hintFail = "没有 30451。确认奥术专精。" },
        },
        extraVerdict = function()
            return {
                "Dummy 40 不是跳人数。Dummy 0 不是 4 跳。",
            }
        end,
    },

    mag_arc_explosion_evo_ap_pom = {
        key = "mag_arc_explosion_evo_ap_pom",
        title = "奥术-爆炸回响禁止100减40唤醒强化气定神闲",
        order = 157,
        hint = "281482 Dummy 40/3。禁止 100-40。12051/12042 表已表达不包空。205025 减层。",
        startText = "【爆炸/唤醒/强化/气定】点回响后爆炸打 ≥3 目标有时 +1 充能，约 40% 不是 60%。唤醒 12051 回蓝。奥术强化 12042。气定神闲 205025 两层瞬发冲击后耗尽。过载 155147 不要空脚本。",
        startPrint = "请打奥术爆炸、唤醒、奥术强化、气定神闲。",
        ids = { 1449, 281482, 12051, 12042, 205025, 155147, 231565 },
        labels = {
            [1449] = "奥术爆炸",
            [281482] = "回响Dummy40/3",
            [12051] = "唤醒(不包空)",
            [12042] = "奥术强化(不包空)",
            [205025] = "气定神闲",
            [155147] = "过载(不包空)",
            [231565] = "唤醒Rank2(不是Dummy)",
        },
        chain = {
            { id = 1449, role = "奥术爆炸", want = "cast",
              hintFail = "没有 1449。" },
        },
        extraVerdict = function()
            return {
                "60 不得进 Dummy。10/30 不得进 Dummy。不要空脚本 12042/12051/155147。",
            }
        end,
    },

    mag_arc_clearcast_echo_anomaly = {
        key = "mag_arc_clearcast_echo_anomaly",
        title = "奥术-节能Dummy200时间异常Dummy8/1/4观察窗口1/16节制Dummy1",
        order = 158,
        hint = "79684 Dummy 200。2% 不得进 Dummy。210805 Dummy 8/1/4。1/16 非 Dummy。236628 Dummy 1 额外一发。264354 Dummy 0 PlayerScript。",
        startText = "【节能/时间异常/节制/三法则】耗蓝出 263725，几率走 Dummy 200。点 210805 战斗中偶发强化/唤醒/+4 层，不要每 2 秒。点 236628 飞弹多一发。2→3 层出 264774。",
        startPrint = "请看节能、点时间异常、点节制、叠到 3 层充能。",
        ids = { 79684, 263725, 210805, 236628, 264354, 264774, 205032, 205022, 210126, 225119 },
        labels = {
            [79684] = "节能Dummy200",
            [263725] = "节能效果",
            [210805] = "时间异常Dummy8/1/4",
            [236628] = "节制Dummy1",
            [264354] = "三法则Dummy0",
            [264774] = "三法则buff",
            [205032] = "充能Energize4(不包空)",
            [205022] = "奥术魔宠(无Dummy)",
            [210126] = "魔宠光环+10法力",
            [225119] = "魔宠伤(3秒观察窗口)",
        },
        chain = {
            { id = 30451, role = "奥术冲击(看节能)", want = "cast",
              hintFail = "没有 30451。用冲击耗蓝看 263725。" },
        },
        extraVerdict = function()
            return {
                "2% / 8% / 16 不得进 Dummy。205032 不要空脚本行。225119 的 3 秒不得进 Dummy。魔宠脚本绑 210126 不是 205022。",
            }
        end,
    },

    mag_arc_touch_orb_nova_invis = {
        key = "mag_arc_touch_orb_nova_invis",
        title = "奥术-触碰Aura15虚空风暴Dummy10宝珠AT1612超级新星EFFECT_0强化隐形113862棱光1/20",
        order = 159,
        hint = "210725 Aura 42=15 不是 Dummy。114923 Dummy 10。157980 Dummy 100 在 EFFECT_0。113862 Cast + 3000ms。235450 Dummy 1 与 20 都读。禁止 321507/Erosion。Savant 不搬家。",
        startText = "【触碰/风暴/宝珠/新星/隐形/棱光】点 210725 出 210824 再 210833。点 114923 DoT 溅射 Dummy 10%。点 153626 AT 打 153640。点 157980 主目标 Dummy 100%，不要改 Ice Nova EFFECT_2。点 110959 有 113862，现身后再约 3 秒。棱光 235450 两列都读。190740 不搬家。",
        startPrint = "请点触碰奥术、虚空风暴、奥术宝珠、超级新星、强化隐形、棱光护体。",
        ids = { 210725, 210824, 210833, 114923, 153626, 153640, 157980, 157997, 110959, 110960, 113862, 235450, 190740, 321507, 210134, 224968 },
        labels = {
            [210725] = "触碰奥术Aura15",
            [210824] = "触碰debuffDummy0",
            [210833] = "触碰爆炸",
            [114923] = "虚空风暴Dummy10",
            [153626] = "奥术宝珠AT1612",
            [153640] = "宝珠伤害",
            [157980] = "超级新星Dummy100_EFFECT0",
            [157997] = "IceNova(不要改EFFECT_2)",
            [110959] = "强化隐形",
            [110960] = "强化隐形buff",
            [113862] = "减伤Aura87_-60",
            [235450] = "棱光Dummy1/20",
            [190740] = "Savant(不搬家)",
            [321507] = "SL触碰(不加厚)",
            [210134] = "Erosion(不加厚)",
            [224968] = "MarkOfAluneth(不加厚)",
        },
        chain = {
            { id = 157980, role = "超级新星", want = "cast",
              hintFail = "没有 157980。确认点了 T60 超级新星。" },
        },
        extraVerdict = function()
            return {
                "15 不是 Dummy。3 秒不得进 Dummy。321507/210134/224968 不加厚。Savant 不搬家。不要第二套 nova。",
            }
        end,
    },

    mag_fire_ball_pyro_streak = {
        key = "mag_fire_ball_pyro_streak",
        title = "火焰-火球炎爆冲击充能热力连击Dummy100加热48107",
        order = 160,
        hint = "133/11366/108853 无 Dummy。44448 Dummy 100 不得当 100% 触发率。48108 无 Dummy。充能分类 1500 不是 Dummy。",
        startText = "【火球/炎爆/冲击/热力连击】120 火焰打 133 铺暴击。108853 把加热转成 48108。瞬发 11366 消耗热力连击。Dummy 100 不要写成必触发。",
        startPrint = "请打火球、火焰冲击、炎爆，看 48107/48108。",
        ids = { 133, 11366, 108853, 44448, 48107, 48108, 195283, 231567 },
        labels = {
            [133] = "火球术",
            [11366] = "炎爆术",
            [108853] = "火焰冲击",
            [44448] = "热力连击驱动Dummy100",
            [48107] = "加热Dummy0",
            [48108] = "热力连击",
            [195283] = "热力连击被动Dummy0",
            [231567] = "冲击Rank2 Aura411(不是Dummy)",
        },
        chain = {
            { id = 133, role = "火球术", want = "cast",
              hintFail = "没有 133。确认火焰专精。" },
        },
        extraVerdict = function()
            return {
                "Dummy 100 不得当 100% 触发。411 不是 Dummy。",
            }
        end,
    },

    mag_fire_combust_kindling_flameon = {
        key = "mag_fire_combust_kindling_flameon",
        title = "火焰-燃烧Dummy50引火Dummy1000只减一次火焰冲能禁止ResetCharges",
        order = 161,
        hint = "190319 Periodic Dummy 50。Aura 107 +100 不是 Dummy。155148 Dummy 1000。205029 Dummy 2 禁止 ResetCharges。",
        startText = "【燃烧/引火/火焰冲能】开 190319 暴击提高，精通按 Dummy 50 不是 100。点 155148 暴击减燃烧 1000 ms，不要 2000。点 205029 冲击恢复短 2 秒，不要回满层。",
        startPrint = "请开燃烧、点引火、点火焰冲能。",
        ids = { 190319, 155148, 205029, 12846 },
        labels = {
            [190319] = "燃烧Dummy50",
            [155148] = "引火Dummy1000",
            [205029] = "火焰冲能Dummy2",
            [12846] = "精通点燃Dummy75",
        },
        chain = {
            { id = 190319, role = "燃烧", want = "cast",
              hintFail = "没有 190319。" },
        },
        extraVerdict = function()
            return {
                "50 不得改成 100。不要减两次。不要 ResetCharges。",
            }
        end,
    },

    mag_fire_starter_searing_pyroclasm = {
        key = "mag_fire_starter_searing_pyroclasm",
        title = "火焰-FirestarterDummy90灼烧之触只改烧尽炎爆冲击Dummy15/225",
        order = 162,
        hint = "205026 Dummy 90。269644 Dummy 30/150 只改 2948。269650 Dummy 15。269651 Dummy 225。250% 弃用。",
        startText = "【Firestarter/灼烧/炎爆冲击】高血目标火球/炎爆必爆。烧尽打低血 +Dummy 150% 且必爆，火球不要无条件 +50%。点 269650 消耗热力连击有时 269651，硬读炎爆 ×225，不要 250%。",
        startPrint = "请点 Firestarter、灼烧之触、炎爆冲击。",
        ids = { 205026, 269644, 2948, 269650, 269651, 133, 11366 },
        labels = {
            [205026] = "FirestarterDummy90",
            [269644] = "灼烧之触Dummy30/150",
            [2948] = "烧尽",
            [269650] = "炎爆冲击Dummy15",
            [269651] = "炎爆冲击buffDummy225",
            [133] = "火球(不要走灼烧)",
            [11366] = "炎爆",
        },
        chain = {
            { id = 2948, role = "烧尽", want = "cast",
              hintFail = "没有 2948。" },
        },
        extraVerdict = function()
            return {
                "250% 弃用。31/50 不是 Dummy。只改烧尽。",
            }
        end,
    },

    mag_fire_aoe_phoenix_ignite = {
        key = "mag_fire_aoe_phoenix_ignite",
        title = "火焰-炸弹流星烈焰风暴烈焰补丁凤凰257541必爆点燃Dummy75删0.75",
        order = 163,
        hint = "257541 无 Dummy T60 必爆。194466 不加厚。12846 Dummy 75。蔓延 8 码观察窗口。137019 Dummy 150 删 200。44614 卸点燃。点燃不搬家。",
        startText = "【AoE/凤凰/点燃】44457 能扩散。153561 能砸。2120 能打且上 12654。205037 出 205470。点 257541 必爆，不要 194466 循环。点燃读 Dummy 75，约 8 码蔓延。Flurry 不要点燃。12846 不搬家。",
        startPrint = "请放活动炸弹、流星、烈焰风暴、烈焰补丁、凤凰烈焰，看点燃。",
        ids = { 44457, 217694, 44461, 153561, 153564, 2120, 205037, 205470, 205472, 257541, 257542, 194466, 12846, 12654, 137019, 44614, 205023, 226757 },
        labels = {
            [44457] = "活动炸弹Dummy0",
            [217694] = "炸弹DoT",
            [44461] = "炸弹爆炸",
            [153561] = "流星Dummy0",
            [153564] = "流星伤害",
            [2120] = "烈焰风暴",
            [205037] = "烈焰补丁Dummy1",
            [205470] = "补丁AT",
            [205472] = "补丁伤害",
            [257541] = "凤凰烈焰T60",
            [257542] = "凤凰溅射Dummy0",
            [194466] = "神器凤凰(不加厚)",
            [12846] = "精通点燃Dummy75",
            [12654] = "点燃光环Dummy0",
            [137019] = "火焰法师Dummy15/150",
            [44614] = "Flurry(不应再绑点燃)",
            [205023] = "纵火(无Dummy)",
            [226757] = "纵火DoT",
        },
        chain = {
            { id = 2120, role = "烈焰风暴", want = "cast",
              hintFail = "没有 2120。" },
        },
        extraVerdict = function()
            return {
                "0.75/200/8 不得进 Dummy。194466 不加厚。点燃不搬家。44614 不应上 12654。纵火 226757 火球和炎爆都要能上。",
            }
        end,
    },

    mag_frost_bolt_lance_flurry = {
        key = "mag_frost_bolt_lance_flurry",
        title = "冰霜-寒冰箭Dummy15冰枪FlurryDummy3 WinterChillDummy100",
        order = 164,
        hint = "112965 Dummy 15 给箭。30455 条件不要写反。44614 Dummy 3。228358 Dummy 100。碎冰 3× 走 12982 不是 Dummy 100。44614 不应绑点燃。",
        startText = "【箭/冰枪/Flurry】打 116 出 228597，有时 44544（Dummy 15）有时 190446（Dummy 25）。冰枪打 228598。Flurry Dummy 3 发，脑冻结上 228358。不要点燃。",
        startPrint = "请打寒冰箭、冰枪、Flurry。",
        ids = { 116, 228597, 30455, 228598, 44614, 228358, 190447, 190446, 44544, 12982, 12654 },
        labels = {
            [116] = "寒冰箭",
            [228597] = "寒冰箭伤害",
            [30455] = "冰枪术",
            [228598] = "冰枪伤Dummy100",
            [44614] = "FlurryDummy3",
            [228358] = "WinterChillDummy100",
            [190447] = "脑冻结Dummy25",
            [190446] = "脑冻结光环",
            [44544] = "寒冰指光环",
            [12982] = "碎冰Dummy25",
            [12654] = "点燃(Flurry不应出现)",
        },
        chain = {
            { id = 30455, role = "冰枪术", want = "cast",
              hintFail = "没有 30455。确认冰霜专精。" },
        },
        extraVerdict = function()
            return {
                "碎冰 3× 不是 Dummy 100。Flurry 不应上 12654。",
            }
        end,
    },

    mag_frost_orb_blizzard_comet = {
        key = "mag_frost_orb_blizzard_comet",
        title = "冰霜-宝珠Dummy10暴风雪不出寒冰指Rank2 Dummy50是/100秒彗星Dummy0七颗观察窗口",
        order = 165,
        hint = "112965 第二列 Dummy 10 给宝珠。暴风雪删 15.0f。236662 Dummy 50=/100 秒不是 50 ms。153595 Dummy 0 不是 7。190356 AT 基点 50 不是 Dummy。",
        startText = "【宝珠/暴风雪/彗星】84714 跳 84721 有时出寒冰指 Dummy 10。190356 跳 190357 **不要**出寒冰指。Rank2 每跳减宝珠约 0.5 秒。彗星 7 颗，Dummy 0 不是 7。需要一排桩。",
        startPrint = "请放冰冻宝珠、暴风雪、彗星风暴。",
        ids = { 84714, 84721, 190356, 190357, 236662, 153595, 153596, 242210, 44544, 270233, 270232 },
        labels = {
            [84714] = "冰冻宝珠",
            [84721] = "宝珠伤害",
            [190356] = "暴风雪Dummy0",
            [190357] = "暴风雪伤害",
            [236662] = "暴风雪Rank2 Dummy50",
            [153595] = "彗星Dummy0",
            [153596] = "彗星伤害",
            [242210] = "彗星视觉Dummy2000",
            [44544] = "寒冰指(暴风雪不应出)",
            [270233] = "冰冻之雨(无Dummy)",
            [270232] = "冰冻之雨buff",
        },
        chain = {
            { id = 190356, role = "暴风雪", want = "cast",
              hintFail = "没有 190356。" },
        },
        extraVerdict = function()
            return {
                "Dummy 50 不是 50 ms。7 不得进 Dummy。暴风雪不应出 44544。270232 的 −100/+50 不是 Dummy。",
            }
        end,
    },

    mag_frost_glacial_ray_veins = {
        key = "mag_frost_glacial_ray_veins",
        title = "冰霜-冰川尖刺吃冰刺射线Dummy2冰冷血脉急速冷却",
        order = 166,
        hint = "199786 Dummy 0。76613 Dummy 5。205021 Dummy 2 不读 Dummy -60 第二次。12472 表已表达不包空。235219 已有脚本。冰刺不搬家。",
        startText = "【尖刺/射线/血脉/急速冷却】叠 5 根冰刺后 199786 吃掉。205021 立刻 2 层寒冰指，减速走 Aura 33。12472 能开。235219 重置冰霜新星/冰锥/护盾/屏障。208166 不加厚。",
        startPrint = "请叠冰刺放冰川尖刺，再放射线、冰冷血脉、急速冷却。",
        ids = { 199786, 228600, 76613, 205473, 205021, 44544, 12472, 235219, 122, 120, 11426, 45438, 208166 },
        labels = {
            [199786] = "冰川尖刺Dummy0",
            [228600] = "尖刺伤害",
            [76613] = "冰刺精通Dummy5",
            [205473] = "冰刺层",
            [205021] = "射线Dummy2/-60",
            [44544] = "寒冰指(射线给2层)",
            [12472] = "冰冷血脉(不包空)",
            [235219] = "急速冷却",
            [122] = "冰霜新星(被重置)",
            [120] = "冰锥术(被重置)",
            [11426] = "寒冰护体(被重置)",
            [45438] = "寒冰屏障(被重置)",
            [208166] = "射线buff(不加厚)",
        },
        chain = {
            { id = 205021, role = "冰霜射线", want = "cast",
              hintFail = "没有 205021。确认点了 T100 射线。" },
        },
        extraVerdict = function()
            return {
                "Dummy -60 不读第二次。2.25 不得进 Dummy。冰刺不搬家。12472 不要空脚本行。",
            }
        end,
    },

    mag_frost_fof_split_void_floes = {
        key = "mag_frost_fof_split_void_floes",
        title = "冰霜-寒冰指四列骨寒Aura+1分裂Dummy80热虚空Dummy1 IceNova EFFECT_2浮冰Dummy10连锁反应278309黑檀之箭只脑冻结",
        order = 167,
        hint = "112965 Dummy 15/10/10/25。Freeze Dummy 25。155149 Dummy 1 + Aura 10000。157997 Dummy 400 EFFECT_2。108839 Dummy 10 本条登记。278309 Dummy 0 卸 195419。257537 不加厚神器。135029/112948 不加厚。",
        startText = "【寒冰指/骨寒/分裂/热虚空/IceNova/浮冰/连锁/黑檀】箭 Dummy 15、宝珠 Dummy 10、暴风雪不出、Freeze Dummy 25。骨寒 205766。分裂 Dummy 80。热虚空冰枪 +Dummy 1 秒。Ice Nova 主目标 Dummy 400。浮冰 3 层/20 秒。点 278309 叠 278310，不要 195419。257537 100% 脑冻结。Water Jet/冰霜炸弹不加厚。",
        startPrint = "请测 Freeze、骨寒、分裂寒冰、热虚空、Ice Nova、浮冰、连锁反应、黑檀之箭。",
        ids = { 112965, 44544, 33395, 205027, 205766, 56377, 155149, 157997, 157980, 108839, 278309, 278310, 195419, 257537, 190446, 135029, 112948, 214664, 195615, 214626 },
        labels = {
            [112965] = "寒冰指Dummy15/10/10/25",
            [44544] = "寒冰指光环",
            [33395] = "Freeze Dummy25",
            [205027] = "骨寒",
            [205766] = "骨寒层Aura+1",
            [56377] = "分裂寒冰Dummy80",
            [155149] = "热虚空Dummy1",
            [157997] = "IceNova Dummy400 EFFECT_2",
            [157980] = "超级新星(不要改共享函数家)",
            [108839] = "浮冰Dummy10",
            [278309] = "连锁反应8.3 Dummy0",
            [278310] = "连锁层Aura+3",
            [195419] = "军团连锁(应已卸)",
            [257537] = "黑檀之箭(只脑冻结)",
            [190446] = "脑冻结光环",
            [135029] = "WaterJet(不加厚)",
            [112948] = "冰霜炸弹(不加厚)",
            [214664] = "IceNine(不加厚)",
            [195615] = "BlackIce(不加厚)",
            [214626] = "Jouster(不加厚)",
        },
        chain = {
            { id = 108839, role = "浮冰", want = "cast",
              hintFail = "没有 108839。确认点了冰霜 T30 浮冰。" },
        },
        extraVerdict = function()
            return {
                "暴风雪第三列 Dummy 10 不接到暴风雪。Ice Nova 不要改 EFFECT_0。195419 不应再接线。257537 不加厚神器。浮冰 MAG-C 不验收。冰刺不搬家。",
            }
        end,
    },

    pri_c_fade_scream_leap = {
        key = "pri_c_fade_scream_leap",
        title = "牧师共用-渐隐无Dummy尖啸Aura191基点4飞跃Script77删110726",
        order = 168,
        hint = "586 无 Dummy。8122 无 Dummy。Aura 191 基点 4 不是 Dummy。破控 10% 观察窗口。73325 Dummy 0 在 idx1。110726 无行。",
        startText = "【渐隐/尖啸/飞跃】120 牧师按 586 应倾倒威胁约 10 秒。8122 约 8 码，脚本 FilterTargets 读 EFFECT_2 Aura 191 基点 4（不是核心自动人数），约 10% 血破控。73325 拉友方过来，CLEU 不要 110726。不要 9.0 减仇恨半径。",
        startPrint = "请按渐隐 586、心灵尖啸 8122、信仰飞跃 73325。",
        ids = { 586, 8122, 73325, 110726, 92832, 64129, 65081, 159628, 159630 },
        labels = {
            [586] = "渐隐(无Dummy)",
            [8122] = "心灵尖啸(无Dummy)",
            [73325] = "信仰飞跃Dummy0",
            [110726] = "已删跳转(不应出现)",
            [92832] = "飞跃拉人",
            [64129] = "身心合一(不是三专精)",
            [65081] = "身心合一移速",
            [159628] = "已删雕文(不应出现)",
            [159630] = "已删雕文效果(不应出现)",
        },
        chain = {
            { id = 586, role = "渐隐", want = "cast",
              hintFail = "没有 586。" },
        },
        extraVerdict = function()
            return {
                "110726/159628 不应出现。4/5/10/8 码不得进 Dummy。Dummy 0 不是距离。",
            }
        end,
    },

    pri_c_table_baseline = {
        key = "pri_c_table_baseline",
        title = "牧师共用-驱魔群驱韧复活精控束缚漂浮表已表达",
        order = 169,
        hint = "528/2006/605/9484/21562 无 Dummy。32375 Dummy 5。1706 Dummy 0。不要包空脚本。不要 INSERT 21562 空壳。",
        startText = "【表已表达】528 驱敌对魔法。32375 群驱 Dummy 5。21562 +10% 耐力 1 小时，不应再绑不存在的脚本名。2006 复活。605 精神控制。9484 束缚亡灵。1706 漂浮出 111759。不要包空脚本。",
        startPrint = "请按驱散魔法、群体驱散、真言术：韧、漂浮各一次。",
        ids = { 528, 32375, 21562, 2006, 605, 9484, 1706, 111759, 111758 },
        labels = {
            [528] = "驱散魔法(无Dummy)",
            [32375] = "群体驱散Dummy5",
            [21562] = "真言术韧(无Dummy)",
            [2006] = "复活术",
            [605] = "精神控制",
            [9484] = "束缚亡灵",
            [1706] = "漂浮术Dummy0",
            [111759] = "漂浮光环",
            [111758] = "已删号(不应Cast)",
        },
        chain = {
            { id = 21562, role = "真言术：韧", want = "cast",
              hintFail = "没有 21562。" },
        },
        extraVerdict = function()
            return {
                "不要包空脚本。111758 不应出现。Dummy 5 不是 15 码。",
            }
        end,
    },

    pri_c_purify_not_one_id = {
        key = "pri_c_purify_not_one_id",
        title = "牧师共用-纯净527不是213634禁止528当CureDisease不验收10060",
        order = 170,
        hint = "527 无 Dummy 只 Disc+Holy。213634 无 Dummy 只暗影。528 是驱散魔法。97691 无行。10060 不是 8.3 全职业。",
        startText = "【纯净/净化疾病/PI】Disc/Holy 527 给友方驱魔+病。暗影是 213634 不是 527。敌对用 528。CLEU 不要 97691。10060 看见也不要勾本包完成。9.0 全职业 PI 弃用。",
        startPrint = "请按纯净 527 或净化疾病 213634。不要学 10060。",
        ids = { 527, 213634, 528, 97691, 97690, 10060, 19236 },
        labels = {
            [527] = "纯净术(Disc+Holy)",
            [213634] = "净化疾病(只暗影)",
            [528] = "驱散魔法(不是CureDisease)",
            [97691] = "已删号(不应出现)",
            [97690] = "已删号(不应出现)",
            [10060] = "能量灌注(不验收)",
            [19236] = "绝望祷言(不是三专精)",
        },
        chain = {
            { id = 527, role = "纯净术", want = "cast",
              hintFail = "没有 527。暗影请改测 213634，不要用 527 补。" },
        },
        extraVerdict = function()
            return {
                "禁止 527/213634 互覆盖。10060 本包不勾完成。97691 不应出现。",
            }
        end,
    },

    pri_c_focused_will_scope = {
        key = "pri_c_focused_will_scope",
        title = "牧师共用-专注意志45242盾17羽121536暗影魔34433不是三专精基线",
        order = 171,
        hint = "45243 无 Dummy。45242 Aura 87 -15 不是 Dummy。17 只 Disc+Shadow。121536 Dummy 10 不是移速 40。34433 Dummy 0 缩放 PET。",
        startText = "【专注意志/范围】挨近战应出 45242。17 / 19236 / 121536 / 34433 / 10060 看见也不要当 PRI-C 三专精完成。盾验收留给 Disc。羽不是三专精。暗影魔缩放不在本波。",
        startPrint = "请挨一下近战看 45242。不要用盾/羽/暗影魔勾 PRI-C 完成。",
        ids = { 45243, 45242, 17, 6788, 121536, 121557, 34433, 19236, 108968 },
        labels = {
            [45243] = "专注意志",
            [45242] = "专注意志减伤",
            [17] = "真言术盾(不是三专精)",
            [6788] = "虚弱灵魂(Disc验收)",
            [121536] = "天堂之羽Dummy10",
            [121557] = "羽移速(不是Dummy)",
            [34433] = "暗影魔(缩放PET)",
            [19236] = "绝望祷言(Disc+Holy)",
            [108968] = "VoidShift(本期不验收)",
        },
        chain = {
            { id = 45243, role = "专注意志", want = "aura",
              hintFail = "没有 45243。确认牧师专精学会。" },
        },
        extraVerdict = function()
            return {
                "17/121536/34433/19236/10060 不是 PRI-C 三专精必过。108968 本期不验收。缩放不在本波。",
            }
        end,
    },

    pri_disc_shield_penance = {
        key = "pri_disc_shield_penance",
        title = "戒律-盾Cast6788删1.36留1.54观察窗口苦修Dummy120不是3跳",
        order = 172,
        hint = "17 无 Dummy。6788 Dummy 0。1.54 观察窗口非 Dummy。47540 Dummy 120 不是跳数。47666 Coef 0.40 / 47750 Coef 0.82 禁止再乘 +15。",
        startText = "【盾/苦修】120 戒律给假人 17，应有 6788，吸收随法强变，不要 1.36。苦修敌友分流，Dummy 120 不要当 3 跳。不要再乘蓝贴 +15%。",
        startPrint = "请上盾 17，再打苦修 47540。",
        ids = { 17, 6788, 47536, 47540, 47666, 47750, 47757, 47758, 137033, 271534 },
        labels = {
            [17] = "真言术盾(无Dummy)",
            [6788] = "虚弱灵魂Dummy0",
            [47536] = "狂喜Dummy200",
            [47540] = "苦修Dummy120",
            [47666] = "苦修伤害Coef0.40",
            [47750] = "苦修治疗Coef0.82",
            [47757] = "苦修友方引导",
            [47758] = "苦修敌方引导",
            [137033] = "暗影光环(不要*1.36)",
            [271534] = "精通Grace(不搬家)",
        },
        chain = {
            { id = 17, role = "真言术：盾", want = "cast",
              hintFail = "没有 17。确认戒律专精。" },
        },
        extraVerdict = function()
            return {
                "禁止口径 A 不上 6788。1.54/1.36/3/7.5/+15 不得进 Dummy。Grace 不搬家。",
            }
        end,
    },

    pri_disc_atonement_radiance = {
        key = "pri_disc_atonement_radiance",
        title = "戒律-救赎Dummy50不是60耀Dummy4/60删Plea212100",
        order = 173,
        hint = "81749 Dummy 50/60 读 50。194509 Dummy 0/4/60。186263 无 Dummy。212100 无行。",
        startText = "【救赎/耀/暗影愈合】上赎罪后打惩击/苦修，友方吃 81751 约 Dummy 50%。耀额外 Dummy 4 目标、赎罪持续 Dummy 60%。186263 上赎罪。CLEU 不要 212100。",
        startPrint = "请上盾或暗影愈合铺赎罪，再打耀和惩击。",
        ids = { 81749, 81751, 194384, 194509, 186263, 187464, 585, 208772, 212100, 231682 },
        labels = {
            [81749] = "救赎Dummy50/60",
            [81751] = "救赎治疗",
            [194384] = "赎罪光环Dummy50/15",
            [194509] = "真言术耀Dummy4/60",
            [186263] = "暗影愈合",
            [187464] = "反噬Dummy0",
            [585] = "惩击(无Dummy)",
            [208772] = "惩击吸收壳",
            [212100] = "已删Plea(不应出现)",
            [231682] = "惩击Rank2 Dummy65(不读)",
        },
        chain = {
            { id = 194509, role = "真言术：耀", want = "cast",
              hintFail = "没有 194509。确认戒律专精。" },
        },
        extraVerdict = function()
            return {
                "Dummy 50 不是 60。Dummy 4 不是跳人数以外的码数。212100 不应出现。",
            }
        end,
    },

    pri_disc_covenant_evangelism = {
        key = "pri_disc_covenant_evangelism",
        title = "戒律-暗影盟约Dummy0/5福音Script6不是Dummy禁止314867",
        order = 174,
        hint = "204065 Dummy 0/5。246287 无 Dummy，Script 基点 6。214621 无 Dummy Aura 271 40。314867 无行。197862 不是 8.3 福音。",
        startText = "【盟约/福音/教派分歧】点 204065 最多 Dummy 5 个友方，不要 314867。点 246287 已有赎罪约 +6 秒，6 不是 Dummy。214621 能放，40 不是 Dummy，不要空脚本。",
        startPrint = "请点暗影盟约 204065、福音 246287、教派分歧 214621。",
        ids = { 204065, 246287, 214621, 314867, 197862, 219518, 194384 },
        labels = {
            [204065] = "暗影盟约Dummy0/5",
            [246287] = "福音(Script6不是Dummy)",
            [214621] = "教派分歧(Aura271_40)",
            [314867] = "SL盟约(无行不应出现)",
            [197862] = "7.x Archangel(不加厚)",
            [219518] = "Dummy50(不要盖204065)",
            [194384] = "赎罪(福音应延长)",
        },
        chain = {
            { id = 246287, role = "福音", want = "cast",
              hintFail = "没有 246287。确认点了 T100 福音。" },
        },
        extraVerdict = function()
            return {
                "314867 不应出现。6/40/50 不得进 Dummy。不要空脚本教派分歧。",
            }
        end,
    },

    pri_disc_solace_ptw_barrier = {
        key = "pri_disc_solace_ptw_barrier",
        title = "戒律-慰藉Dummy100黑暗面认204213障AT81782痛苦压制表已表达",
        order = 175,
        hint = "129250 Dummy 100。204197 无 Dummy。198069 Dummy 50。62618 无 Dummy。33206 Periodic Dummy 0。271534 不搬家。34433 Dummy 0 缩放 PET。",
        startText = "【慰藉/净化邪恶/障/压制】129250 回蓝 Dummy 100/100。204197 上 204213，苦修可扩散，黑暗面要认跳。62618 进圈 81782。33206 能开（表 −40）。Grace 不搬家。暗影魔缩放不在本波。Spirit Shell 不加厚。",
        startPrint = "请打慰藉、净化邪恶、真言术：障、痛苦压制。",
        ids = { 129250, 129253, 204197, 204213, 204215, 198068, 198069, 62618, 81782, 33206, 271534, 34433, 123040, 109964 },
        labels = {
            [129250] = "慰藉Dummy100",
            [129253] = "慰藉回蓝",
            [204197] = "净化邪恶",
            [204213] = "净化邪恶跳(黑暗面要认)",
            [204215] = "选择器Dummy0",
            [198068] = "黑暗面的力量",
            [198069] = "黑暗面Dummy50",
            [62618] = "真言术障",
            [81782] = "障减伤(不是Dummy)",
            [33206] = "痛苦压制(表已表达)",
            [271534] = "精通Grace(不搬家)",
            [34433] = "暗影魔(缩放PET)",
            [123040] = "摧心魔Disc(缩放PET)",
            [109964] = "SpiritShell(不加厚)",
        },
        chain = {
            { id = 129250, role = "真言术：慰藉", want = "cast",
              hintFail = "没有 129250。确认点了 T45 慰藉。" },
        },
        extraVerdict = function()
            return {
                "1% 不得进 Dummy。不要 DELETE 81782 永茂林行。Grace 不搬家。缩放不在本波。109964 不加厚。",
            }
        end,
    },

    pri_holy_heal_words_smite = {
        key = "pri_holy_heal_words_smite",
        title = "神圣-快疗读2050 Dummy6惩击只Dummy4删AfterCast-6祷言Dummy5",
        order = 176,
        hint = "2060/2061 无 Dummy。Dummy 6 在 2050。Dummy 4 只在 88625。596 Dummy 5。139 无 Dummy。34861 Dummy 6/6/2。32546 Dummy 3。",
        startText = "【快疗/祷言/惩击】2061/2060 减静 Dummy 6 秒。596 Dummy 5 目标、减灵 Dummy 6。139 减灵 Dummy 2，不要 63544。585 一次只减罚 Dummy 4，不要 −6。束缚 Dummy 3。",
        startPrint = "请打快速治疗、治疗祷言、恢复、惩击、束缚治疗。",
        ids = { 2061, 2060, 2050, 596, 139, 32546, 585, 88625, 34861, 63544, 63733 },
        labels = {
            [2061] = "快速治疗",
            [2060] = "治疗术",
            [2050] = "圣言静Dummy6",
            [596] = "治疗祷言Dummy5",
            [139] = "恢复",
            [32546] = "束缚治疗Dummy3",
            [585] = "惩击(无Dummy)",
            [88625] = "圣言罚Dummy4",
            [34861] = "圣言灵Dummy6/6/2",
            [63544] = "已删DivineTouch(不应出现)",
            [63733] = "HolyWordsDummy0",
        },
        chain = {
            { id = 2061, role = "快速治疗", want = "cast",
              hintFail = "没有 2061。确认神圣专精。" },
        },
        extraVerdict = function()
            return {
                "Dummy 4 不得从 2050 Dummy 6 抄到罚。63544 不应出现。−6 已删。",
            }
        end,
    },

    pri_holy_pom_hymn_guardian = {
        key = "pri_holy_pom_hymn_guardian",
        title = "神圣-愈合祷言Dummy5半径155793赞美诗Dummy12删3守护Dummy40",
        order = 177,
        hint = "33076 Dummy 5。155793 Dummy 0。123262 无行。64843 Dummy 100/0/12。47788 Dummy 40。Aura 118 +60 不是 Dummy。",
        startText = "【愈合祷言/赞美诗/守护之魂】33076 EFFECT_0 Dummy 5 跳，半径 155793 不是 123262。赞美诗读 64843 EFFECT_3 Dummy 12，不要 Dummy 100/0，不要写死 3。47788 EFFECT_1 Dummy 40% 致死治疗，不要读 EFFECT_0 +60，不要 0%。救赎之魂保持 Aura 316 PERIODIC_HASTE。",
        startPrint = "请放愈合祷言、神圣赞美诗、守护之魂。",
        ids = { 33076, 33110, 41635, 155793, 123262, 64843, 64844, 47788, 48153, 20711, 27827 },
        labels = {
            [33076] = "愈合祷言Dummy5",
            [33110] = "愈合祷言治疗",
            [41635] = "愈合祷言层Dummy0",
            [155793] = "跳Dummy0半径20码",
            [123262] = "已删半径号(不应出现)",
            [64843] = "赞美诗Dummy12",
            [64844] = "赞美诗跳(dump绑此号)",
            [47788] = "守护之魂Dummy40",
            [48153] = "守护牺牲治疗",
            [20711] = "救赎之魂(无Dummy)",
            [27827] = "救赎之魂变形",
        },
        chain = {
            { id = 33076, role = "愈合祷言", want = "cast",
              hintFail = "没有 33076。" },
        },
        extraVerdict = function()
            return {
                "123262 不应出现。3/全团/40 码不得改 Dummy 12。healPct 不是 0。",
            }
        end,
    },

    pri_holy_serenity_sanctify_salvation = {
        key = "pri_holy_serenity_sanctify_salvation",
        title = "神圣-静Dummy6灵Dummy6/6/2禁止88685救赎Dummy2/30新星Dummy20",
        order = 178,
        hint = "2050 Dummy 6。34861 Dummy 6/6/2。88685 无行。265202 Dummy 2/30。132157 无 Dummy。231687 Dummy 20。",
        startText = "【三圣言/新星】2050 大疗并减救赎 Dummy 30 秒。34861 人数 Dummy 6，CLEU 不要 88685。265202 Dummy 2 层愈合祷言。132157 有时重置 14914（Dummy 20 在 231687）。",
        startPrint = "请按圣言：静、圣言：灵、圣言：救赎、神圣新星。",
        ids = { 2050, 34861, 88685, 88686, 265202, 132157, 281265, 231687, 14914 },
        labels = {
            [2050] = "圣言静Dummy6",
            [34861] = "圣言灵Dummy6/6/2",
            [88685] = "已删庇护地面(不应出现)",
            [88686] = "已删庇护治疗(不应出现)",
            [265202] = "圣言救赎Dummy2/30",
            [132157] = "神圣新星",
            [281265] = "新星治疗",
            [231687] = "新星Rank2 Dummy20",
            [14914] = "神圣之火",
        },
        chain = {
            { id = 2050, role = "圣言：静", want = "cast",
              hintFail = "没有 2050。" },
        },
        extraVerdict = function()
            return {
                "88685 不应出现。Dummy 2 不是 40 码。20 不得写死而不读 231687。",
            }
        end,
    },

    pri_holy_apoth_naaru_circle = {
        key = "pri_holy_apoth_naaru_circle",
        title = "神圣-化身Dummy300纳鲁Dummy33不是10%环Dummy5光晕AT不搬家Echo",
        order = 179,
        hint = "200183 Dummy 300。196985 Dummy 33。网页 10% 弃用。204883 Dummy 0/5。120517/110744 无 Dummy。77485 Dummy 0/125 不搬家。Archon Halo 弃用。",
        startText = "【化身/纳鲁/环/光晕】点 200183 圣言减冷却按 Dummy 300%。点 196985 再 +Dummy 33%，不要 10%。204883 Dummy 5。120517/110744 AT 能打，不要 Archon。Echo 面板绿字，不搬家。208065 不加厚。",
        startPrint = "请点化身、纳鲁之光、治疗之环、光晕或神圣之星。",
        ids = { 200183, 196985, 204883, 200128, 234946, 238136, 243241, 109186, 114255, 193157, 120517, 110744, 77485, 77489, 208065, 196358 },
        labels = {
            [200183] = "化身Dummy300",
            [196985] = "纳鲁之光Dummy33",
            [204883] = "治疗之环Dummy5",
            [200128] = "光之尾迹Dummy35",
            [234946] = "尾迹治疗",
            [238136] = "宇宙涟漪Dummy5",
            [243241] = "涟漪治疗",
            [109186] = "圣光涌动Dummy8",
            [114255] = "涌动buff",
            [193157] = "祈福Dummy25",
            [120517] = "光晕(AT无Dummy)",
            [110744] = "神圣之星(AT无Dummy)",
            [77485] = "EchoDummy0/125(不搬家)",
            [77489] = "Echo跳",
            [208065] = "神器Tuure(不加厚)",
            [196358] = "神器SayYourPrayers(不加厚)",
        },
        chain = {
            { id = 200183, role = "神圣化身", want = "cast",
              hintFail = "没有 200183。确认点了 T100 化身。" },
        },
        extraVerdict = function()
            return {
                "10 不得覆盖 Dummy 33。Echo 不搬家。Archon Halo 弃用。神器不加厚。",
            }
        end,
    },

    pri_shadow_eruption_voidform_bolt = {
        key = "pri_shadow_eruption_voidform_bolt",
        title = "暗影-虚空爆发Dummy1费用9000不是Dummy形态周期idx4箭Dummy3000",
        order = 180,
        hint = "228260 Dummy 1。SpellPower 9000 不是 Dummy。194249 Dummy 0/25。Aura 85 -3000 不是 Dummy。231688 Dummy 3000/1。234746 无 Dummy。",
        startText = "【爆发/形态/虚空箭】228260 要耗精神错乱，不要免费。上 194249，周期 Dummy 0 在 idx4，抽取走 Aura 85。虚空箭延痛/触 Dummy 3000。Dummy 25 不是抽取。",
        startPrint = "请铺 DoT 放虚空爆发，再打虚空箭。",
        ids = { 228260, 228360, 228361, 194249, 185916, 228264, 205448, 228266, 234746, 231688, 232698 },
        labels = {
            [228260] = "虚空爆发Dummy1",
            [228360] = "爆发伤A",
            [228361] = "爆发伤B",
            [194249] = "虚空形态Dummy0/25",
            [185916] = "虚空形态被动Dummy5",
            [228264] = "Voidform壳Dummy0/5",
            [205448] = "虚空箭(无Dummy)",
            [228266] = "虚空箭学会Dummy0",
            [234746] = "虚空箭脚本号",
            [231688] = "延时Dummy3000/1",
            [232698] = "暗影形态",
        },
        chain = {
            { id = 228260, role = "虚空爆发", want = "cast",
              hintFail = "没有 228260。确认暗影专精且精神错乱够。" },
        },
        extraVerdict = function()
            return {
                "9000/-3000/25 不得进 Dummy。不要 TakePower=0。周期不要挂 EFFECT_0 Aura 108。",
            }
        end,
    },

    pri_shadow_dots_flay_apparitions = {
        key = "pri_shadow_dots_flay_apparitions",
        title = "暗影-痛无Dummy触Dummy2鞭笞Dummy4幻灵Dummy0吉兆+25不是50",
        order = 181,
        hint = "589 无 Dummy。34914 Dummy 2。15407 Dummy 4 不是 300 也不是 4 秒。78203 Dummy 0。155271 无 Dummy Aura +25。50% 弃用。",
        startText = "【DoT/鞭笞/幻灵】589/34914 能打。15407 能引导（表 Energize，不要空脚本行）。痛暴击出幻灵。吉兆是 Aura +25 不是 50%。蓝贴 −8% 不要再乘 Coef。需要一排桩测灼烧 48045。",
        startPrint = "请上痛和触，引导鞭笞，看幻灵。",
        ids = { 589, 34914, 15407, 78203, 147193, 148859, 155271, 48045, 49821, 238558, 8092 },
        labels = {
            [589] = "暗言术痛(无Dummy)",
            [34914] = "吸血鬼之触Dummy2",
            [15407] = "精神鞭笞Dummy4",
            [78203] = "暗影幻灵Dummy0",
            [147193] = "幻灵导弹",
            [148859] = "幻灵伤害",
            [155271] = "吉兆(Aura+25不是Dummy)",
            [48045] = "精神灼烧Dummy4",
            [49821] = "灼烧伤Dummy0",
            [238558] = "MiseryDummy0",
            [8092] = "心灵震爆(无Dummy)",
        },
        chain = {
            { id = 589, role = "暗言术：痛", want = "cast",
              hintFail = "没有 589。" },
        },
        extraVerdict = function()
            return {
                "4/2/50/0.68/−8 不得进 Dummy。不要给 15407/589 包空脚本。",
            }
        end,
    },

    pri_shadow_torrent_ascension = {
        key = "pri_shadow_torrent_ascension",
        title = "暗影-洪流263165 Dummy0删+600走289577神器205065不加厚升华Dummy1/5000",
        order = 182,
        hint = "263165 Dummy 0。289577 Aura 24 600 不是 Dummy。Dummy 5。205065 Dummy 2 不加厚。280711 Dummy 1/5000。15 秒观察窗口。263346 无 Dummy。",
        startText = "【洪流/升华/黑暗虚空】点 263165 回能走 289577，不要写死 +600，不要 205065 循环。点 280711 上 194249，约 15 秒后摘，15 不是 Dummy。263346 上 589。不要 DELETE 205065。",
        startPrint = "请点虚空洪流 263165、黑暗升华 280711、黑暗虚空 263346。",
        ids = { 263165, 289577, 205065, 262173, 280711, 280800, 263346, 194249, 589 },
        labels = {
            [263165] = "虚空洪流Dummy0",
            [289577] = "洪流回能Aura24_600",
            [205065] = "神器洪流Dummy2(不加厚)",
            [262173] = "阻止回能",
            [280711] = "黑暗升华Dummy1/5000",
            [280800] = "升华伤害",
            [263346] = "黑暗虚空",
            [194249] = "虚空形态",
            [589] = "痛(虚空应上)",
        },
        chain = {
            { id = 263165, role = "虚空洪流", want = "cast",
              hintFail = "没有 263165。确认点了 T90 虚空洪流。" },
        },
        extraVerdict = function()
            return {
                "600/15/5000 不得进 Dummy。不要覆盖 205065。不要 DELETE 神器行。",
            }
        end,
    },

    pri_shadow_death_legacy_pet = {
        key = "pri_shadow_death_legacy_pet",
        title = "暗影-死Dummy20/15/30 LegacyDummy60 SurrenderDummy90净化213634缩放PET不搬家Madness",
        order = 183,
        hint = "32379 Dummy 20/15/30。193225 Dummy 60/5。193223 Dummy 90。213634 无 Dummy。34433 Dummy 0 缩放 PET。77486 无 Dummy 不搬家。194248 无行。280752 Dummy 6。",
        startText = "【死/Legacy/Surrender/净化/宠】32379 三列 Dummy 不互填。点 193225 Dummy 60 阈值。点 193223 Dummy 90。213634 给友方，不要 527。暗影魔能招，缩放不在本波。200174 不要和第二套 123040 PetAI 互覆盖。Madness 不搬家。194248 不补脚本。",
        startPrint = "请打暗言术：死，点 Legacy/Surrender，用 213634，招暗影魔。",
        ids = { 32379, 193225, 193223, 213634, 527, 34433, 200174, 123040, 77486, 194248, 280752, 199579, 15286, 47585, 15487, 108968 },
        labels = {
            [32379] = "暗言术死Dummy20/15/30",
            [193225] = "LegacyDummy60/5",
            [193223] = "SurrenderDummy90",
            [213634] = "净化疾病(只暗影)",
            [527] = "纯净(暗影不要用)",
            [34433] = "暗影魔Dummy0(缩放PET)",
            [200174] = "摧心魔Shadow",
            [123040] = "摧心魔Disc(不要互覆盖)",
            [77486] = "Madness(不搬家)",
            [194248] = "空号(不补脚本)",
            [280752] = "HallucinationsDummy6",
            [199579] = "幻觉回能",
            [15286] = "吸血鬼拥抱Dummy85",
            [47585] = "消散Dummy100(表已表达)",
            [15487] = "沉默(表已表达)",
            [108968] = "VoidShift(本期不验收)",
        },
        chain = {
            { id = 32379, role = "暗言术：死", want = "cast",
              hintFail = "没有 32379。确认点了 T75 死，或基线学会。" },
        },
        extraVerdict = function()
            return {
                "194248 不补脚本。527 不要给暗影。缩放不在本波。Madness 不搬家。10060/PI 不验收。108968 本期不验收。",
            }
        end,
    },

    wl_c_drain_fear_resolve = {
        key = "wl_c_drain_fear_resolve",
        title = "术士共用-吸取无Dummy恐惧Dummy0不灭表已表达删204730硬写20秒",
        order = 184,
        hint = "234153 无 Dummy。5782 Dummy 0。118699 Aura 191 基点 7 不是 Dummy。104773 无 Dummy。204730 不应出现。",
        startText = "【吸取/恐惧/不灭】120 术士对桩 234153 应 5 秒吸取。5782 上 118699，持续走表，CLEU 不要 204730，不要硬写 20 秒。104773 能开，−40% 走表。7/1/20 不得进 Dummy。",
        startPrint = "请按吸取生命 234153、恐惧 5782、不灭决心 104773。",
        ids = { 234153, 5782, 118699, 204730, 104773, 221703 },
        labels = {
            [234153] = "吸取生命(无Dummy)",
            [5782] = "恐惧Dummy0",
            [118699] = "恐惧光环",
            [204730] = "错绑号(不应出现)",
            [104773] = "不灭决心(无Dummy)",
            [221703] = "CastingCircle(本期不验收)",
        },
        chain = {
            { id = 234153, role = "吸取生命", want = "cast",
              hintFail = "没有 234153。" },
        },
        extraVerdict = function()
            return {
                "204730 不应出现。7/1/20 不得进 Dummy。221703 本期不验收。",
            }
        end,
    },

    wl_c_soulstone_funnel_leech = {
        key = "wl_c_soulstone_funnel_leech",
        title = "术士共用-灵魂石15分钟通道Dummy5榨取108370 Dummy8/10不是228974",
        order = 185,
        hint = "20707 Dummy 0。15分钟石头/10分钟CD不是Dummy。755 Dummy 5。217979 基点 4/8 不是 Dummy。108370 Dummy 8/10。228974 Dummy 10/15 另一号。219272 Dummy 5/15。",
        startText = "【石/通道/榨取】20707 石头约 15 分钟，不要改成 10 分钟。755 读 Dummy 5% 自身，宠物 217979 基点 8，不要写死 4%。打桩出 108366，玩家键 Dummy 8/10，有皮肤则上限 Dummy 15。不要 228974，不要注释 20%。",
        startPrint = "请放灵魂石 20707、生命通道 755，再打桩看 108366。",
        ids = { 20707, 3026, 231811, 755, 217979, 108370, 108366, 228974, 219272 },
        labels = {
            [20707] = "灵魂石Dummy0",
            [3026] = "使用灵魂石Dummy60",
            [231811] = "灵魂石Rank2 Dummy0",
            [755] = "生命通道Dummy5",
            [217979] = "通道治疗(基点4/8不是Dummy)",
            [108370] = "灵魂榨取Dummy8/10",
            [108366] = "榨取吸收",
            [228974] = "另一号Dummy10/15(不得覆盖)",
            [219272] = "恶魔皮肤Dummy5/15",
        },
        chain = {
            { id = 755, role = "生命通道", want = "cast",
              hintFail = "没有 755。确认有宠物。" },
        },
        extraVerdict = function()
            return {
                "4/8/两倍/15/10/900/20 不得进 Dummy。228974 不得覆盖 108370。",
            }
        end,
    },

    wl_c_circle_breath_kilrogg = {
        key = "wl_c_circle_breath_kilrogg",
        title = "术士共用-法阵48018呼吸删74434眼126指挥暗影之怒放逐表已表达",
        order = 186,
        hint = "268358 Dummy 0。48018 Periodic Dummy 0。5697 无 Dummy。74434 无行。126 无 Dummy。119898 Dummy 0。30283 无 Dummy。710 无 Dummy。",
        startText = "【法阵/呼吸/眼/表已表达】268358 学会 48018/48020 能放能传。5697 水下，CLEU 不要 74434。126 能招。119898/30283/6789/698/1098 能放，不要包空脚本。688/697/712/691 能招，缩放不在本波。",
        startPrint = "请放恶魔法阵、无穷呼吸、基尔罗格之眼、暗影之怒。",
        ids = { 268358, 48018, 48020, 5697, 74434, 126, 119898, 30283, 6789, 698, 710, 1098, 688, 697, 712, 691 },
        labels = {
            [268358] = "恶魔法阵天赋Dummy0",
            [48018] = "法阵召唤Dummy0",
            [48020] = "法阵传送",
            [5697] = "无穷呼吸(无Dummy)",
            [74434] = "已删Soulburn(不应出现)",
            [126] = "基尔罗格(无Dummy)",
            [119898] = "指挥恶魔Dummy0",
            [30283] = "暗影之怒(无Dummy)",
            [6789] = "死亡缠绕Dummy0",
            [698] = "召唤仪式Dummy0",
            [710] = "放逐术",
            [1098] = "奴役恶魔",
            [688] = "召唤小鬼(缩放PET)",
            [697] = "召唤虚空行者(缩放PET)",
            [712] = "召唤魅魔(缩放PET)",
            [691] = "召唤地狱猎犬(缩放PET)",
        },
        chain = {
            { id = 5697, role = "无穷呼吸", want = "cast",
              hintFail = "没有 5697。" },
        },
        extraVerdict = function()
            return {
                "74434 不应出现。不要包空脚本。缩放不在本波。2.5秒不得进 Dummy。",
            }
        end,
    },

    wl_c_pact_skin_gateway_scope = {
        key = "wl_c_pact_skin_gateway_scope",
        title = "术士共用-契约Dummy20/250皮肤Dummy5/15传送门Dummy60不验收5484/108415/1454/324536",
        order = 187,
        hint = "108416 Dummy 20/250。wiki 400% 弃用。219272 Dummy 5/15。111771 Dummy 60。5484 不是 8.3 基线。108415 Dummy 50 只 266。1454 无 Dummy 学会路径空。324536 无行。",
        startText = "【契约/皮肤/门/范围】点 108416 读 Dummy 20/250，不要 400%，不要双脚本。219272 周期 Dummy 5、上限 Dummy 15。111771 能放两门，Dummy 60 不是 200 码。5484/108415/1454/324536 看见也不要勾 WL-C 完成。77220 不搬家、本包不勾 MAS。",
        startPrint = "请点黑暗契约、恶魔皮肤、恶魔传送门。不要学 Howl/Malefic Rapture。",
        ids = { 108416, 219272, 111771, 111400, 5484, 108415, 1454, 324536, 77220, 77215, 196586, 86091, 288843 },
        labels = {
            [108416] = "黑暗契约Dummy20/250",
            [219272] = "恶魔皮肤Dummy5/15",
            [111771] = "恶魔传送门Dummy60",
            [111400] = "燃烧冲刺(无Dummy)",
            [5484] = "恐惧嚎叫(不验收)",
            [108415] = "灵魂链接Dummy50(只Demo)",
            [1454] = "生命分流(不验收)",
            [324536] = "MaleficRapture(无行)",
            [77220] = "混乱能量(不搬家不验收MAS)",
            [77215] = "PotentAfflictions(不搬家)",
            [196586] = "次元裂隙(不加厚)",
            [86091] = "Nethermancy(职业被动)",
            [288843] = "DemonicEmbrace(职业被动)",
        },
        chain = {
            { id = 108416, role = "黑暗契约", want = "cast",
              hintFail = "没有 108416。确认点了 T30 契约。" },
        },
        extraVerdict = function()
            return {
                "400%/5484/108415/1454/324536 本包不勾完成。77220/77215 不搬家。196586 不加厚。",
            }
        end,
    },

    wl_aff_agony_corruption_ua = {
        key = "wl_aff_agony_corruption_ua",
        title = "痛苦-痛楚Dummy0删16.0f腐蚀Dummy4 UA五段点名五个号禁止连续区间",
        order = 188,
        hint = "980 Periodic Dummy 0。16 不是 Dummy。172 Dummy 4。30108 Dummy 400/5/10。五段 233490/233496/233497/233498/233499 无 Dummy。233494 神器不加厚。324536 无行。",
        startText = "【痛楚/腐蚀/UA】980 叠层走 Dummy 0，不要 16.0f。172/146739 能跳，绝对腐蚀 Dummy 24 秒，Dummy 4 不是秒。30108 五段只五个号，CLEU 不要 233491-233495，不要 324536。驱散走 Dummy 400。",
        startPrint = "请上痛楚 980、腐蚀 172、连放痛苦无常 30108 五次。",
        ids = { 980, 172, 146739, 196103, 30108, 233490, 233496, 233497, 233498, 233499, 233494, 324536, 231791, 231792 },
        labels = {
            [980] = "痛楚Dummy0",
            [172] = "腐蚀Dummy4",
            [146739] = "腐蚀跳",
            [196103] = "绝对腐蚀Dummy24",
            [30108] = "痛苦无常Dummy400/5/10",
            [233490] = "UA段1",
            [233496] = "UA段2",
            [233497] = "UA段3",
            [233498] = "UA段4",
            [233499] = "UA段5",
            [233494] = "Contagion神器(不加厚)",
            [324536] = "MaleficRapture(无行不应出现)",
            [231791] = "UA Rank2 Dummy1",
            [231792] = "痛楚Rank2(Aura107 +4不是Dummy)",
        },
        chain = {
            { id = 980, role = "痛楚", want = "cast",
              hintFail = "没有 980。确认痛苦专精。" },
        },
        extraVerdict = function()
            return {
                "16 不得进 Dummy。禁止连续区间。324536 不应出现。233494 不加厚。",
            }
        end,
    },

    wl_aff_bolt_drain_seed = {
        key = "wl_aff_bolt_drain_seed",
        title = "痛苦-暗影箭232670吸取灵魂Dummy100/20删空号种子Dummy50/0播下Dummy1",
        order = 189,
        hint = "232670 无 Dummy。198590 Dummy 100/20。131736/131740/132566/131737 无行。27243 Dummy 50/0。196226 Dummy 1/1。32388 Dummy 0。",
        startText = "【箭/吸取灵魂/种】232670 能打，有 32388 上 32390。198590 能引导，CLEU 不要 131736 四个空号。27243 能种，播下种子额外 Dummy 1 目标，爆炸 27285。Dummy 50 不是目标数。",
        startPrint = "请打暗影箭 232670、吸取灵魂 198590、腐蚀之种 27243。",
        ids = { 232670, 686, 194192, 32388, 32390, 198590, 131736, 131740, 132566, 131737, 27243, 27285, 196226 },
        labels = {
            [232670] = "痛苦暗影箭",
            [686] = "经典暗影箭(不验收为120键)",
            [194192] = "旧碎裂号",
            [32388] = "暗影之拥Dummy0",
            [32390] = "暗影之拥易伤(+3不是Dummy)",
            [198590] = "吸取灵魂Dummy100/20",
            [131736] = "空号(不应出现)",
            [131740] = "空号(不应出现)",
            [132566] = "空号(不应出现)",
            [131737] = "空号(不应出现)",
            [27243] = "腐蚀之种Dummy50/0",
            [27285] = "种子爆炸",
            [196226] = "播下种子Dummy1/1",
        },
        chain = {
            { id = 232670, role = "暗影箭", want = "cast",
              hintFail = "没有 232670。点了吸取灵魂则改测 198590，不要用 686 补。" },
        },
        extraVerdict = function()
            return {
                "四个空号不应出现。Dummy 50 不是目标数。686 不是 120 痛苦键。",
            }
        end,
    },

    wl_aff_deathbolt_nightfall_siphon = {
        key = "wl_aff_deathbolt_nightfall_siphon",
        title = "痛苦-死亡箭Dummy20/14不是30夜幕Dummy0不是RPPM4虹吸是DoT不是雕文",
        order = 190,
        hint = "264106 Dummy 20/14。was 30% 弃用。108558 Dummy 0。264571 Dummy 50。RPPM 4 非 DBC。63106 无 Dummy。196102 Dummy 15 不是 +15 层。264000 无 Dummy 表已表达。",
        startText = "【死亡箭/夜幕/虹吸】264106 约 Dummy 20% 剩余 DoT，腐蚀封顶 Dummy 14 秒，不要 30%。夜幕腐蚀跳可出 264571 Dummy 50 加伤，Dummy 0 不是几率，不要写 RPPM 4。63106 是 DoT 吸血，不要雕文自疗。痛楚翻腾 Dummy 15 不要再加 15 层。蔓延死亡能放（表 −15）。",
        startPrint = "请打死亡箭 264106，点夜幕和生命虹吸。",
        ids = { 264106, 108558, 264571, 63106, 196102, 264000, 196103 },
        labels = {
            [264106] = "死亡箭Dummy20/14",
            [108558] = "夜幕Dummy0",
            [264571] = "夜幕加伤Dummy50",
            [63106] = "生命虹吸(无Dummy DoT)",
            [196102] = "痛楚翻腾Dummy15(不是+15层)",
            [264000] = "蔓延死亡(表已表达)",
            [196103] = "绝对腐蚀Dummy24",
        },
        chain = {
            { id = 264106, role = "死亡箭", want = "cast",
              hintFail = "没有 264106。确认点了 T15 死亡箭。" },
        },
        extraVerdict = function()
            return {
                "30/4/33/15层 不得进 Dummy。不要雕文自疗。不要空脚本蔓延死亡。",
            }
        end,
    },

    wl_aff_darkglare_haunt_singularity = {
        key = "wl_aff_darkglare_haunt_singularity",
        title = "痛苦-凝视Script8不是Dummy10停止筛603鬼影奇点不搬家77215不验收108415",
        order = 191,
        hint = "205180 Dummy 10/20。Script 8 不是 Dummy。603 是 Demo 末日。48181 无 Dummy。205179 Periodic Dummy 0。278350 无 Dummy。113860 无 Dummy。77215 无 Dummy 不搬家。108415 Dummy 50 只 Demo。",
        startText = "【凝视/鬼影/奇点/精通】点 205180，已有痛楚/腐蚀/UA 的桩被延长，眼打 205231，不要只认 603。缩放不在本波。48181 死亡重置。205179 跳 205246。278350/113860 能放（表已表达，悲惨不要当 T14）。77215 面板绿字，不搬家。108415/324536 不要勾完成。",
        startPrint = "请招黑暗凝视 205180，打鬼影缠身和幻影奇点。",
        ids = { 205180, 205231, 103673, 603, 48181, 205179, 205246, 278350, 113860, 77215, 108415, 215941, 324536 },
        labels = {
            [205180] = "黑暗凝视Dummy10/20",
            [205231] = "眼射线",
            [103673] = "黑暗凝视召唤物",
            [603] = "末日(不要当痛苦筛)",
            [48181] = "鬼影缠身",
            [205179] = "幻影奇点Dummy0",
            [205246] = "奇点伤Dummy0",
            [278350] = "邪恶污染(表已表达)",
            [113860] = "黑暗灵魂悲惨(表已表达)",
            [77215] = "精通PotentAfflictions(不搬家)",
            [108415] = "灵魂链接(不验收)",
            [215941] = "灵魂导管Dummy15",
            [324536] = "MaleficRapture(无行)",
        },
        chain = {
            { id = 205180, role = "召唤黑暗凝视", want = "cast",
              hintFail = "没有 205180。确认痛苦专精学会。" },
        },
        extraVerdict = function()
            return {
                "不要筛 603。缩放不在本波。77215 不搬家。108415/324536 不验收。8 不是 Dummy。",
            }
        end,
    },

    wl_destro_immolate_incinerate_conflag = {
        key = "wl_destro_immolate_incinerate_conflag",
        title = "毁灭-献祭Dummy50不是2.5f烧尽Dummy100不读成碎裂燃烧17962不是5740",
        order = 192,
        hint = "348 Dummy 50。193541 Dummy 0。157736 无 Dummy。29722 Dummy 0/100。17962 无 Dummy。5740 是火雨。108685/108686 不是 8.3 硫磺。",
        startText = "【献祭/烧尽/燃烧】348 上 157736，暴击碎裂走 Dummy 50，不要 2.5f。29722 产碎裂，Dummy 100 不是 5。17962 是燃烧，不要当成 5740，打 117828。军团 108685 不要当 8.3 硫磺。",
        startPrint = "请上献祭 348，打烧尽 29722、燃烧 17962。",
        ids = { 348, 157736, 193541, 29722, 17962, 231793, 117828, 196406, 5740, 108685, 108686 },
        labels = {
            [348] = "献祭Dummy50",
            [157736] = "献祭跳",
            [193541] = "献祭碎片Dummy0",
            [29722] = "烧尽Dummy0/100",
            [17962] = "燃烧(无Dummy)",
            [231793] = "燃烧Rank2(Aura411 +1不是Dummy)",
            [117828] = "爆燃",
            [196406] = "爆燃被动Dummy2/4",
            [5740] = "火焰之雨(不是燃烧)",
            [108685] = "军团硫磺(停用)",
            [108686] = "无行号(不应Cast)",
        },
        chain = {
            { id = 17962, role = "燃烧", want = "cast",
              hintFail = "没有 17962。确认毁灭专精。不要按 5740。" },
        },
        extraVerdict = function()
            return {
                "2.5/5/7.5 不得进 Dummy。17962 不是 5740。108686 不应出现。",
            }
        end,
    },

    wl_destro_chaos_havoc_rain = {
        key = "wl_destro_chaos_havoc_rain",
        title = "毁灭-混乱之箭Dummy20不是必爆浩劫必须Dummy60删100%火雨Dummy50不是1000ms",
        order = 193,
        hint = "116858 Dummy 20。SpellPower 20 不是 Dummy。80240 Dummy 60。100/同等/75 不得覆盖。5740 Dummy 50 + Periodic Dummy 0。42223 无 Dummy。215279 神器不加厚。",
        startText = "【混乱之箭/浩劫/火雨】116858 必爆是观察窗口，Dummy 20 不是暴击率也不是碎片。给第二只假人 80240，复制约 Dummy 60%，不要全额 100%。5740 AT 跳 42223，Dummy 50 不是 1000 ms，8 码不是 Dummy。不要 DELETE Halls of Reflection 5740 行。",
        startPrint = "请打混乱之箭 116858，给第二只假人浩劫 80240，放火焰之雨 5740。",
        ids = { 116858, 215279, 80240, 5740, 42223, 266134, 266136 },
        labels = {
            [116858] = "混乱之箭Dummy20",
            [215279] = "神器撕裂(不加厚)",
            [80240] = "浩劫Dummy60",
            [5740] = "火焰之雨Dummy50",
            [42223] = "火雨伤",
            [266134] = "内部燃烧Dummy5",
            [266136] = "内部燃烧伤",
        },
        chain = {
            { id = 80240, role = "浩劫", want = "cast",
              hintFail = "没有 80240。确认毁灭专精，并对第二只假人放。" },
        },
        extraVerdict = function()
            return {
                "必须读 Dummy 60。100/75/1000ms/8码 不得进 Dummy。215279 不加厚。",
            }
        end,
    },

    wl_destro_soulfire_eradication_cdf = {
        key = "wl_destro_soulfire_eradication_cdf",
        title = "毁灭-灵魂之火Dummy2000在4936不要改1949根除修196414 CheckProc false恶魔之火Dummy15不是100码",
        order = 194,
        hint = "6353 Dummy 2000。+40/−2000 不是 Dummy。:1949 是恐惧。196412 无 Dummy。196414 +10 不是 Dummy。196447 Periodic Dummy 15。17877 Dummy 15。152108 无 Dummy。205184 Dummy 0。",
        startText = "【灵魂之火/根除/恶魔之火】6353 冷却按 Dummy 2000 ms 减，不要 +40，不要改恐惧 :1949。点根除后混乱之箭上 196414，修的是 196414 CheckProc false 不是 196412。196447 Dummy 15 是跳数不是 100 码。暗影灼烧 Dummy 15 不读成死亡 +50。大灾变上献祭。咆哮 Dummy 0 不是 25%。",
        startPrint = "请打灵魂之火 6353，点根除和恶魔之火。",
        ids = { 6353, 281490, 196412, 196414, 196447, 196448, 17877, 152108, 205184, 265931, 5782 },
        labels = {
            [6353] = "灵魂之火Dummy2000",
            [281490] = "灵魂之火充能(Energize4不是Dummy)",
            [196412] = "根除(Aura42 无Dummy)",
            [196414] = "根除易伤(+10不是Dummy)",
            [196447] = "恶魔之火Dummy15",
            [196448] = "恶魔之火伤",
            [17877] = "暗影灼烧Dummy15",
            [152108] = "大灾变(无Dummy)",
            [205184] = "咆哮烈焰Dummy0",
            [265931] = "咆哮DoT(Coef0.16不是Dummy)",
            [5782] = "恐惧(不要当灵魂之火改)",
        },
        chain = {
            { id = 6353, role = "灵魂之火", want = "cast",
              hintFail = "没有 6353。确认点了 T15 灵魂之火。不要打开恐惧函数。" },
        },
        extraVerdict = function()
            return {
                "不要改 :1949。40/−2000/100码/25/+10 不得进 Dummy。CheckProc false 在 196414。",
            }
        end,
    },

    wl_destro_fnb_inferno_mastery_artifact = {
        key = "wl_destro_fnb_inferno_mastery_artifact",
        title = "毁灭-硫磺Dummy40/1地狱火Dummy20精通77220不搬家不删一边196586不加厚不验收Demo",
        order = 195,
        hint = "196408 Dummy 40/1。270545 Dummy 20。77220 Dummy 0/0 BonusCoef 2.0/0.666 不是 Dummy。196586 不加厚。267115/205148/266086/113858 表已表达不包空。105174/265187 不验收。",
        startText = "【硫磺/地狱火/精通/神器】点 196408 后烧尽溅射约 Dummy 40%，不要军团 108685。点 270545 火雨跳有时 270548。77220 吸收 Aura 在术士文件、PlayerScript 在 mastery 文件，不搬家、不删一边、本包不勾 MAS。196586 看见也不要加厚。闪燃/逆向熵/至高术/动荡能放。手之卫/暴君不要勾 WL-Demo。",
        startPrint = "请点硫磺烈火、地狱火。不要搬精通，不要加厚次元裂隙。",
        ids = { 196408, 270545, 270548, 77220, 196586, 187394, 215279, 267115, 205148, 266086, 266091, 113858, 105174, 265187, 1122 },
        labels = {
            [196408] = "硫磺烈火Dummy40/1",
            [270545] = "地狱火Dummy20",
            [270548] = "火雨碎裂",
            [77220] = "混乱能量Dummy0/0(不搬家)",
            [196586] = "次元裂隙(不加厚)",
            [187394] = "ChaosBarrage(不加厚)",
            [215279] = "TearChaosBolt(不加厚)",
            [267115] = "闪燃(表已表达)",
            [205148] = "逆向熵(表已表达)",
            [266086] = "至高术Dummy0(表已表达)",
            [266091] = "至高术加伤(+8不是Dummy)",
            [113858] = "黑暗灵魂动荡(表已表达)",
            [105174] = "手之卫(不验收Demo)",
            [265187] = "恶魔暴君(不验收Demo)",
            [1122] = "召唤地狱火",
        },
        chain = {
            { id = 196408, role = "硫磺烈火", want = "cast",
              hintFail = "没有 196408。确认点了 T60 硫磺。" },
        },
        extraVerdict = function()
            return {
                "77220 不搬家不删一边本包不勾 MAS。196586 不加厚。105174/265187 不验收。不要空脚本闪燃。",
            }
        end,
    },

    sha_c_wolf_hex_shift_shear = {
        key = "sha_c_wolf_hex_shift_shear",
        title = "萨满共用-幽魂之狼停查55448妖术星界转移风剪表已表达",
        order = 196,
        hint = "2645 无 Dummy。55448 无行。51514 无 Dummy。108271 无 Dummy。57994 无 Dummy。546 无 Dummy。",
        startText = "【狼/妖术/转移/风剪】2645 能变，CLEU 不要 55448 放 546。51514 变形走表。108271 −40% 走表。57994 打断走表。546/370/556 表已表达不包空。",
        startPrint = "请按幽魂之狼 2645、妖术 51514、星界转移 108271、风剪 57994。",
        ids = { 2645, 55448, 546, 51514, 108271, 57994, 370, 556 },
        labels = {
            [2645] = "幽魂之狼(无Dummy)",
            [55448] = "已删雕文(不应驱动546)",
            [546] = "水上行走(表已表达)",
            [51514] = "妖术(无Dummy)",
            [108271] = "星界转移(无Dummy)",
            [57994] = "风剪(无Dummy)",
            [370] = "净化术(表已表达)",
            [556] = "星界传送(表已表达)",
        },
        chain = {
            { id = 2645, role = "幽魂之狼", want = "cast",
              hintFail = "没有 2645。" },
        },
        extraVerdict = function()
            return {
                "55448 不应再驱动 546。57994/51514/108271 不包空。",
            }
        end,
    },

    sha_c_capacitor_earthbind_tremor = {
        key = "sha_c_capacitor_earthbind_tremor",
        title = "萨满共用-电能Dummy8到期118905延迟读基点2不是Dummy8",
        order = 197,
        hint = "192058 Dummy 8。EFFECT_1 基点 2 不是 Dummy。118905 无 Dummy。2484 Dummy 0。8143 无 Dummy。2 不得进 Dummy 8。",
        startText = "【电能/地缚/战栗】192058 约 2 秒后 CLEU 118905 晕桩，Dummy 8 是半径不是秒。2484 减速。8143 驱散 8146。2/8 不得互填 Dummy。",
        startPrint = "请放电能图腾 192058、地缚 2484、战栗 8143。",
        ids = { 192058, 118905, 2484, 3600, 8143, 8146 },
        labels = {
            [192058] = "电能图腾Dummy8",
            [118905] = "电能爆炸(无Dummy)",
            [2484] = "地缚Dummy0",
            [3600] = "地缚减速(−50不是Dummy)",
            [8143] = "战栗(无Dummy)",
            [8146] = "战栗驱散(无Dummy)",
        },
        chain = {
            { id = 192058, role = "电能图腾", want = "cast",
              hintFail = "没有 192058。确认动作条有电能图腾。" },
        },
        extraVerdict = function()
            return {
                "118905 必须出现。2 不得进 Dummy 8。补篇 2 秒不是 Dummy。",
            }
        end,
    },

    sha_c_reincarnate_lust_earth_elem = {
        key = "sha_c_reincarnate_lust_earth_elem",
        title = "萨满共用-复生Dummy30不是21169基点20嗜血土元素Dummy0",
        order = 198,
        hint = "20608 Dummy 0/30。21169 基点 20 不是 Dummy。2825/32182 无 Dummy。198103 Dummy 0。2008 无 Dummy。20 不得进 Dummy 30。",
        startText = "【复生/嗜血/土元素】20608 CD 约 30 分钟、起来约 20% 血走 21169 基点 20，不要把 20 填进 Dummy 30，不要包空脚本。2825/32182 滤 Sated。198103 能召，缩放不在本波。",
        startPrint = "请看复生 20608、嗜血或英勇、土元素 198103。",
        ids = { 20608, 21169, 2008, 2825, 32182, 57724, 57723, 198103, 188616, 6196 },
        labels = {
            [20608] = "复生Dummy0/30",
            [21169] = "复生生命(基点20不是Dummy)",
            [2008] = "先祖之魂(表已表达)",
            [2825] = "嗜血(无Dummy)",
            [32182] = "英勇(无Dummy)",
            [57724] = "SatedDummy0",
            [57723] = "ExhaustionDummy0",
            [198103] = "土元素Dummy0",
            [188616] = "土元素召唤",
            [6196] = "视界Dummy0",
        },
        chain = {
            { id = 198103, role = "土元素", want = "cast",
              hintFail = "没有 198103。" },
        },
        extraVerdict = function()
            return {
                "20 不得进 Dummy 30。缩放不在本波。不要包空复生脚本。",
            }
        end,
    },

    sha_c_guardian_spiritwolf_scope = {
        key = "sha_c_guardian_spiritwolf_scope",
        title = "萨满共用-自然守护删EFFECT_1读31616基点20不验收192106/77130/108287",
        order = 199,
        hint = "30884 无 Dummy。31616 基点 20 不是 Dummy。260878 Dummy 50。192106 Dummy 30 只 263 不验收。77130 不验收。108287 无行。204945/205495 不加厚。",
        startText = "【守护/狼天赋/范围】点 30884，约 35% 触发 31616 约 20% 最大生命，不要 30%，不要 EFFECT_1。点 260878 叠 260881，Dummy 50 不是每秒 5%。不要勾 192106/77130/108287。神器不加厚。",
        startPrint = "请点自然守护者 30884、幽魂之狼天赋 260878。不要测闪电之盾当共用。",
        ids = { 30884, 31616, 260878, 260881, 265046, 192077, 192106, 324, 77130, 51886, 108287, 204945, 205495, 207354, 195255 },
        labels = {
            [30884] = "自然守护者(无Dummy)",
            [31616] = "自然守护治疗(基点20不是Dummy)",
            [260878] = "幽魂之狼天赋Dummy50",
            [260881] = "狼叠层(5/−5不是Dummy)",
            [265046] = "静电充能Dummy5/20",
            [192077] = "风驰图腾(无Dummy)",
            [192106] = "闪电之盾Dummy30(不验收)",
            [324] = "已删号(不应再绑)",
            [77130] = "净化灵魂恢复(不验收)",
            [51886] = "净化灵魂元素增强",
            [108287] = "图腾投射(无行)",
            [204945] = "DoomWinds(不加厚)",
            [205495] = "神器风暴守护(不加厚)",
            [207354] = "潮汐之抚(不加厚)",
            [195255] = "Stormlash(不加厚)",
        },
        chain = {
            { id = 30884, role = "自然守护者", want = "cast",
              hintFail = "没有 30884。确认点了 T75 自然守护者。" },
        },
        extraVerdict = function()
            return {
                "EFFECT_1 不应再读。192106/77130/108287 不要勾 SHA-C。神器不加厚。45/30/35/20 不得进 Dummy。",
            }
        end,
    },

    sha_ele_lb_lvb_es_eq = {
        key = "sha_ele_lb_lvb_es_eq",
        title = "元素-闪电箭Dummy8熔岩爆裂大地震击删花费缩放地震只跳77478",
        order = 200,
        hint = "190493 Dummy 8/4/3/3 在 idx0/2/3/5。214815 基点 6 不是 Dummy。8042 无 Dummy。61882 Dummy 0+Periodic Dummy 100。0.92/0.3 不是 Dummy。",
        startText = "【箭/爆裂/震击/地震】188196 产 Dummy 8 漩涡，不要 214815 的 6。51505 能打。8042 花 60 不要花费缩放。61882 只跳一次 77478，AT 不再打伤。",
        startPrint = "请打闪电箭 188196、熔岩爆裂 51505、大地震击 8042、地震术 61882。",
        ids = { 188196, 190493, 214815, 45284, 51505, 77451, 8042, 61882, 77478, 77505 },
        labels = {
            [188196] = "闪电箭(无Dummy)",
            [190493] = "积雷Dummy8/4/3/3",
            [214815] = "旧+6(不是8.3键)",
            [45284] = "闪电箭过载",
            [51505] = "熔岩爆裂(无Dummy)",
            [77451] = "熔岩爆裂过载",
            [8042] = "大地震击(无Dummy)",
            [61882] = "地震术Dummy0/100",
            [77478] = "地震跳",
            [77505] = "地震击倒",
        },
        chain = {
            { id = 188196, role = "闪电箭", want = "cast",
              hintFail = "没有 188196。确认元素专精。" },
        },
        extraVerdict = function()
            return {
                "6/10 不得进 Dummy 8。AT 不应再打 77478。花费缩放应已删。",
            }
        end,
    },

    sha_ele_fs_surge_chain_eb = {
        key = "sha_ele_fs_surge_chain_eb",
        title = "元素-烈焰Dummy100残留不读熔岩奔腾Dummy15链Dummy4元素冲击",
        order = 201,
        hint = "188389 Dummy 100 只 idx2 残留不读。20 观察窗口非 Dummy。77756 Dummy 15。188443 Dummy 4。117014 无 Dummy。SS 188389 只 262。",
        startText = "【烈焰/奔腾/链/冲击】188389 Dummy 100 不要当漩涡花费。熔岩奔腾走 Dummy 15。闪电链 Dummy 4。117014 能打出副属性。不要给增强学会 188389。",
        startPrint = "请上烈焰震击 188389、看熔岩奔腾 77756、闪电链 188443、元素冲击 117014。",
        ids = { 188389, 77756, 77762, 188443, 117014, 120588, 196840 },
        labels = {
            [188389] = "烈焰震击Dummy100(残留不读)",
            [77756] = "熔岩奔腾Dummy15",
            [77762] = "熔岩奔腾瞬发",
            [188443] = "闪电链Dummy4",
            [117014] = "元素冲击(无Dummy)",
            [120588] = "元素冲击过载",
            [196840] = "冰霜震击Dummy100",
        },
        chain = {
            { id = 188389, role = "烈焰震击", want = "cast",
              hintFail = "没有 188389。确认元素专精。" },
        },
        extraVerdict = function()
            return {
                "20/10 不得进 Dummy 100。15 在 77756 不是 188389。",
            }
        end,
    },

    sha_ele_overload_icefury_sk_aftershock = {
        key = "sha_ele_overload_icefury_sk_aftershock",
        title = "元素-过载Dummy0/85/75不搬家不勾MAS冰怒无Dummy191634余震Dummy25",
        order = 202,
        hint = "168534 Dummy 0/85/75，Dummy 75 残留不读。禁止 roll 15。过载箭 45284 产 Dummy 3 不是 8、不是 75。45297 不是 51505。210714 无 Dummy 禁止 Energize 25。191634 无 Dummy。273221 Dummy 25。210707 Dummy 30 不是 8.3 键。本包不勾 MAS。",
        startText = "【过载/冰怒/风暴守护/余震】过载第二发 45284/77451/120588/45297，伤约 Dummy 85%，过载箭产 Dummy 3 不是 8、不是 75。闪电链不要 51505。不要勾 MAS。冰怒 4 层 +200，不要 25 漩涡。191634 两层，205495 不加厚。余震 Dummy 25，不要 210707。",
        startPrint = "请打出过载、点冰怒 210714、风暴守护者 191634、余震 273221。不要勾精通完成。",
        ids = { 168534, 45284, 77451, 120588, 45297, 51505, 210714, 219271, 191634, 205495, 273221, 210707 },
        labels = {
            [168534] = "过载Dummy0/85/75(Dummy75残留不读,不搬家)",
            [45284] = "LB过载Dummy3不是8不是75",
            [77451] = "LvB过载",
            [120588] = "EB过载",
            [45297] = "CL过载",
            [51505] = "熔岩爆裂(CL过载不应打出)",
            [210714] = "冰怒(无Dummy)",
            [219271] = "冰怒过载",
            [191634] = "风暴守护者8.3",
            [205495] = "神器风暴守护(不加厚)",
            [273221] = "余震Dummy25",
            [210707] = "军团余震Dummy30(不是8.3键)",
        },
        chain = {
            { id = 191634, role = "风暴守护者", want = "cast",
              hintFail = "没有 191634。确认点了 T100 风暴守护者，不要只看 205495。" },
        },
        extraVerdict = function()
            return {
                "过载箭产 Dummy 3 不是 8、不是 75。禁止 ModifyPower(75)。15/25/1.875 不得进 Dummy。本包不勾 MAS。不要 Energize 25。不要 210707。",
            }
        end,
    },

    sha_ele_static_primal_ascendance_totem = {
        key = "sha_ele_static_primal_ascendance_totem",
        title = "元素-积雷idx0/2/3/5原始元素师Dummy80升腾114050先祖指引Dummy25",
        order = 203,
        hint = "190493 Dummy 8/4/3/3。117013 Dummy 80。114050 无 Dummy。114074 Dummy 10 残留 Dummy 3 跳跃。210652 Dummy 5 加法不是 AddPct。108281 Dummy 25 只 262。260895 Dummy 20 本波不验收。",
        startText = "【积雷/原始/升腾/指引】积雷 Dummy 必须点名 idx0/2/3/5。点 117013 火元素也读 Dummy 80，缩放不在本波。升腾是 114050 不是只留 114052。风暴图腾 Dummy 5 加过载（加法），不要 10。点 108281 后打桩出 114911 约 Dummy 25%。260895 能点不验收脚本。",
        startPrint = "请点原始元素师 117013、升腾 114050、先祖指引 108281。",
        ids = { 190493, 117013, 198067, 188592, 192249, 114050, 114074, 114052, 210643, 210652, 260895, 16166, 262303, 108281, 114911 },
        labels = {
            [190493] = "积雷Dummy8/4/3/3",
            [117013] = "原始元素师Dummy80",
            [198067] = "火元素Dummy0",
            [188592] = "火元素召唤",
            [192249] = "风暴元素Dummy0",
            [114050] = "元素升腾(无Dummy)",
            [114074] = "升腾链Dummy10/3",
            [114052] = "恢复升腾(本包不验收)",
            [210643] = "元素图腾掌握(不验收dump)",
            [210652] = "风暴图腾Dummy5",
            [260895] = "无尽之力Dummy20(不验收)",
            [16166] = "元素掌控(无Dummy)",
            [262303] = "涌动Dummy1/3",
            [108281] = "先祖指引Dummy25(元素验收)",
            [114911] = "先祖指引回馈",
        },
        chain = {
            { id = 114050, role = "元素升腾", want = "cast",
              hintFail = "没有 114050。不要只学会恢复 114052。" },
            { id = 108281, role = "先祖指引", want = "cast",
              hintFail = "没有 108281。确认点了元素 T75 先祖指引，不要当恢复 T90。" },
        },
        extraVerdict = function()
            return {
                "10 不得覆盖 Dummy 5。缩放不在本波。Dummy 10 不是跳跃人数。本包不勾 MAS。108281 应出 114911。260895 不要勾完成。",
            }
        end,
    },

    sha_enh_ss_ll_crash = {
        key = "sha_enh_ss_ll_crash",
        title = "增强-风暴打击熔岩猛击Dummy0禁止12秒崩溃Dummy5需2目标才187878",
        order = 204,
        hint = "17364 无 Dummy。60103 Dummy 0 Rec 0。禁止 12 秒。8050 无行。187874 Dummy 5。187878 仅 ≥2。",
        startText = "【打击/猛击/崩溃】17364 能打。60103 没有 12 秒 CD，CLEU 不要 8050，灼热之手只吃 +100% 伤。崩溃单目标不上 187878，2+ 才上，198300 每目标 Dummy 5%。",
        startPrint = "请打风暴打击 17364、熔岩猛击 60103、崩溃闪电 187874。",
        ids = { 17364, 32175, 32176, 60103, 8050, 215785, 187874, 187878, 198300 },
        labels = {
            [17364] = "风暴打击(无Dummy)",
            [32175] = "风暴打击主手Dummy0",
            [32176] = "风暴打击副手Dummy0",
            [60103] = "熔岩猛击Dummy0",
            [8050] = "已删烈焰(不应出现)",
            [215785] = "灼热之手(+100%伤)",
            [187874] = "崩溃闪电Dummy5",
            [187878] = "崩溃武器(≥2)",
            [198300] = "聚集风暴",
        },
        chain = {
            { id = 17364, role = "风暴打击", want = "cast",
              hintFail = "没有 17364。确认增强专精。" },
        },
        extraVerdict = function()
            return {
                "12 秒不得出现。8050 不应出现。补篇 12 秒熔岩猛击弃用。",
            }
        end,
    },

    sha_enh_ft_fb_wf_mw = {
        key = "sha_enh_ft_fb_wf_mw",
        title = "增强-火舌Dummy326残留风怒Dummy0不读成25%漩涡武器Dummy1残留",
        order = 205,
        hint = "193796 Dummy 0。194084 Dummy 326/7 残留不读。196834 Periodic Dummy 0。210853 Dummy 40 残留不读。33757 Dummy 0 不读成几率。25/5.0f/6.24 不得进 Dummy 0。187880 Dummy 1。",
        startText = "【火舌/冰封/风怒/漩涡】火舌跳 10444，Dummy 326 不读。冰雹有光环就打 210854。风怒可出 25504，不要对成 Dummy 25%。漩涡回 187890 的 5，Dummy 1 不读。强风叠 262652 最多 Dummy 5。",
        startPrint = "请上火舌 193796、冰封 196834、看风怒 33757 与漩涡武器 187880。",
        ids = { 193796, 194084, 10444, 196834, 210853, 210854, 33757, 25504, 187880, 187890, 262647, 262652 },
        labels = {
            [193796] = "火舌Dummy0",
            [194084] = "火舌光环Dummy326(残留不读)",
            [10444] = "火舌攻击",
            [196834] = "冰封PeriodicDummy0",
            [210853] = "冰雹Dummy40(残留不读)",
            [210854] = "冰雹伤",
            [33757] = "风怒Dummy0(不是25%)",
            [25504] = "风怒攻击",
            [187880] = "漩涡武器Dummy1(残留不读)",
            [187890] = "漩涡回能5",
            [262647] = "强风天赋Dummy5",
            [262652] = "强风叠层",
        },
        chain = {
            { id = 193796, role = "火舌", want = "cast",
              hintFail = "没有 193796。" },
        },
        extraVerdict = function()
            return {
                "25 不得进 Dummy 0。禁止暗示 25 是 8.3 Dummy 基线。10 层漩涡武器是零售弃用。",
            }
        end,
    },

    sha_enh_wolves_lb_ls_stormbringer = {
        key = "sha_enh_wolves_lb_ls_stormbringer",
        title = "增强-野性狼魂Dummy0闪电之盾192106只263风暴使者Dummy0删必proc",
        order = 206,
        hint = "51533 Dummy 0 残留不读。228562 召唤。231723 回能。缩放 PET。192106 Dummy 30 只 Spec 263。324 已删。201845 Dummy 0 不读成几率。",
        startText = "【狼/箭/盾/使者】51533 出 228562，缩放不在本波。187837 能打。点 T15 才有 192106，CLEU 不要 324。风暴使者不是每下必出 201846。",
        startPrint = "请点野性狼魂 51533、增强闪电箭 187837、闪电之盾 192106。",
        ids = { 51533, 228562, 231723, 187837, 192106, 324, 192109, 201845, 201846, 17364 },
        labels = {
            [51533] = "野性狼魂Dummy0",
            [228562] = "狼召唤",
            [231723] = "狼回能",
            [187837] = "增强闪电箭(无Dummy)",
            [192106] = "闪电之盾Dummy30",
            [324] = "已删号(不应出现)",
            [192109] = "闪电之盾触发",
            [201845] = "风暴使者Dummy0",
            [201846] = "风暴使者proc",
            [17364] = "风暴打击(重置目标)",
        },
        chain = {
            { id = 51533, role = "野性狼魂", want = "cast",
              hintFail = "没有 51533。" },
        },
        extraVerdict = function()
            return {
                "缩放不在本波。324 不应出现。不要主手必 proc。",
            }
        end,
    },

    sha_enh_overcharge_totem_crashstorm_artifact = {
        key = "sha_enh_overcharge_totem_crashstorm_artifact",
        title = "增强-过载Dummy40/1200禁止12秒图腾掌握262395崩塌8码神器不加厚",
        order = 207,
        hint = "210727 Dummy 40/1200。冷却 Aura +9000。12 秒弃用。262395 无 Dummy。192246 Dummy 4 不读成码。210801 半径 8。204945/195255 不加厚。77223 不搬家。",
        startText = "【过载/图腾/崩塌/神器】210727 读 Dummy 40/1200，不要 12 秒。262395 出增强四图腾，不要用 210643 验收。崩塌打敌人约 8 码，不要 2.5 打玩家。204945 看见不加厚。77223 不搬家。空气之怒每跳 3 不是 5。",
        startPrint = "请点过载 210727、图腾掌握 262395、崩塌风暴 192246。不要勾精通。",
        ids = { 210727, 262395, 262419, 210643, 192246, 210801, 197211, 114051, 204945, 195255, 77223 },
        labels = {
            [210727] = "过载Dummy40/1200",
            [262395] = "增强图腾掌握",
            [262419] = "增强图腾召唤",
            [210643] = "元素图腾掌握(不验收)",
            [192246] = "崩塌风暴Dummy4",
            [210801] = "崩塌伤(8码)",
            [197211] = "空气之怒(SP3不是Dummy)",
            [114051] = "增强升腾(表已表达)",
            [204945] = "DoomWinds(不加厚)",
            [195255] = "Stormlash(不加厚)",
            [77223] = "精通Dummy250(不搬家)",
        },
        chain = {
            { id = 210727, role = "过载", want = "cast",
              hintFail = "没有 210727。确认点了 T60 过载。" },
        },
        extraVerdict = function()
            return {
                "12 秒弃用。25 不得进风怒 Dummy。Ice Strike/风怒图腾零售弃用。77223 不搬家。",
            }
        end,
    },

    sha_resto_riptide_hw_hs_chain = {
        key = "sha_resto_riptide_hw_hs_chain",
        title = "恢复-激流无Dummy治疗波治疗之涌治疗链Dummy30必须治疗假人",
        order = 208,
        hint = "61295 无 Dummy。77472 无 Dummy。8004 无 Dummy。1064 Dummy 30。CastingTimeIndex 20 不得发明 2500。必须治疗假人 131994/132036/144075。",
        startText = "【激流/波/涌/链】必须治疗假人。61295 能跳，不要包空脚本。77472/8004 能治。1064 每跳读 Dummy 30 衰减。2.5 秒不得进 Dummy。188070 不是 8004。",
        startPrint = "请对治疗假人按激流 61295、治疗波 77472、治疗之涌 8004、治疗链 1064。",
        ids = { 61295, 77472, 8004, 1064, 188070, 216251, 51564, 53390 },
        labels = {
            [61295] = "激流(无Dummy)",
            [77472] = "治疗波(无Dummy)",
            [8004] = "治疗之涌(无Dummy)",
            [1064] = "治疗链Dummy30",
            [188070] = "增强治疗之涌(不是8004)",
            [216251] = "波动",
            [51564] = "浪潮汹涌Dummy0",
            [53390] = "浪潮汹涌buff",
        },
        chain = {
            { id = 61295, role = "激流", want = "cast",
              hintFail = "没有 61295。必须用治疗假人。" },
        },
        extraVerdict = function()
            return {
                "必须治疗假人。2.5 不得进 Dummy。Dummy 30 是衰减不是人数。",
            }
        end,
    },

    sha_resto_rain_slt_htt_ascendance = {
        key = "sha_resto_rain_slt_htt_ascendance",
        title = "恢复-治疗之雨Dummy0/6/14灵魂链接Dummy2残留升腾294020不是114083",
        order = 209,
        hint = "73920 Dummy 0/6/14。14 不得改成 6。98008 Dummy 2 残留不读。98007 −10 不是 Dummy。108280 Dummy 1。114052 Periodic Dummy 0。294020 SP 6 不是 Dummy。必须治疗假人。",
        startText = "【雨/链接/潮/升腾】必须治疗假人。73920 跳 73921，Dummy 14 保持。98008 均血，减伤走 98007 −10，Dummy 2 不读。治疗之潮打 114942。升腾 CLEU 294020，不要只靠 114083。",
        startPrint = "请对治疗假人放治疗之雨 73920、灵魂链接 98008、治疗之潮 108280、升腾 114052。",
        ids = { 73920, 73921, 98008, 98007, 98020, 108280, 114942, 114052, 294020, 114083 },
        labels = {
            [73920] = "治疗之雨Dummy0/6/14",
            [73921] = "雨跳",
            [98008] = "灵魂链接Dummy2(残留不读)",
            [98007] = "链接减伤(−10不是Dummy)",
            [98020] = "链接跳Dummy0",
            [108280] = "治疗之潮Dummy1",
            [114942] = "潮跳",
            [114052] = "恢复升腾Dummy0",
            [294020] = "升腾疗(表Trigger)",
            [114083] = "旧升腾疗(停写死)",
        },
        chain = {
            { id = 73920, role = "治疗之雨", want = "cast",
              hintFail = "没有 73920。必须用治疗假人。" },
        },
        extraVerdict = function()
            return {
                "14 不得改成 6。2/−10 不得互填 Dummy。CLEU 应有 294020。必须治疗假人。",
            }
        end,
    },

    sha_resto_es_resurgence_hightide_cloudburst = {
        key = "sha_resto_es_resurgence_hightide_cloudburst",
        title = "恢复-大地之盾Dummy0在idx1 ResurgenceDummy100高潮Dummy200无Idx1",
        order = 210,
        hint = "974 Dummy 0 在 idx1。Aura 283 +10 不是 Dummy。204288 Dummy 4 另一号。16196 Dummy 100。52127 已删。157154 Dummy 200 无 Idx1。157503 Dummy 30。必须治疗假人。",
        startText = "【盾/回能/高潮/暴雨】必须治疗假人。974 挨打出 379，不要挂 EFFECT_0 Dummy，不要 204288。Resurgence 不要水盾。高潮 Dummy 200 触发 288675，不要 EFFECT_1 多跳。暴雨读 Dummy 30 不是 BP 0。",
        startPrint = "请对治疗假人上大地之盾 974、看 Resurgence 16196、点高潮 157154、暴雨图腾 157153。",
        ids = { 974, 379, 204288, 16196, 52127, 157154, 288675, 157153, 157503, 157504 },
        labels = {
            [974] = "大地之盾Dummy0",
            [379] = "大地之盾疗",
            [204288] = "另一号Dummy4(不应绑974脚本)",
            [16196] = "ResurgenceDummy100",
            [52127] = "水盾已删(不应再要)",
            [157154] = "高潮Dummy200",
            [288675] = "高潮不衰减",
            [157153] = "暴雨图腾(无Dummy)",
            [157503] = "暴雨释放Dummy30",
            [157504] = "暴雨储存Dummy0",
        },
        chain = {
            { id = 974, role = "大地之盾", want = "cast",
              hintFail = "没有 974。必须用治疗假人。" },
        },
        extraVerdict = function()
            return {
                "200 不是 +2 跳、不是 200 法力。链疗系数保留 0.33 不是 0.25。Dummy 0 不得写成 379 治疗量 0。必须治疗假人。",
            }
        end,
    },

    sha_resto_flashflood_downpour_mastery_scope = {
        key = "sha_resto_flashflood_downpour_mastery_scope",
        title = "恢复-山洪Dummy0不是倾盆Dummy5精通77226不搬家不验收108281",
        order = 211,
        hint = "280614 Dummy 0 = 山洪。207778 Dummy 5 = 倾盆。禁止疾风骤雨当唯一键。−20/5秒/12码不得互填 Dummy。77226 Dummy 300 只 idx1。不搬家。108281 只 262 不验收。77130 不选边填 8。必须治疗假人。",
        startText = "【山洪/倾盆/精通/范围】必须治疗假人。280614 只有消耗 53390 才出 280615。207778 Dummy 5 是每目标 +5 秒 CD，不要封顶 5 人，不要叫疾风骤雨。77226 绿字在，不搬家，不勾 MAS。不要勾 108281。井泉 Dummy 30。CastIdx 243 不得发明 1.5 秒 Dummy。",
        startPrint = "请对治疗假人点山洪 280614、倾盆 207778。不要勾精通。不要点先祖指引。",
        ids = { 280614, 280615, 207778, 77226, 108281, 197995, 77130, 51886, 108287 },
        labels = {
            [280614] = "山洪Dummy0",
            [280615] = "山洪buff(−20不是Dummy)",
            [207778] = "倾盆Dummy5",
            [77226] = "深愈合Dummy300(不搬家)",
            [108281] = "先祖指引Dummy25(不验收)",
            [197995] = "井泉Dummy30",
            [77130] = "净化灵魂(不选边填8)",
            [51886] = "另一号净化",
            [108287] = "图腾投射(无行)",
        },
        chain = {
            { id = 280614, role = "山洪", want = "cast",
              hintFail = "没有 280614。确认点了 T90 山洪，不要把倾盆 207778 当同一个疾风骤雨。" },
        },
        extraVerdict = function()
            return {
                "山洪≠倾盆。Dummy 5 不是人数。必须先有 53390 才出 280615。77226 不搬家不勾 MAS。108281 不验收。8 不得进 Dummy。必须治疗假人。",
            }
        end,
    },

    dru_c_dash_stealth_travel_cat = {
        key = "dru_c_dash_stealth_travel_cat",
        title = "德鲁伊共用-疾跑停写70潜行Dummy-30旅行形态Dummy0不是40",
        order = 212,
        hint = "1850 无 Dummy。Aura 31 60。70 不得进 Dummy。5215 Dummy −30。783 Dummy 0。159456 Dummy 60 不读进 783。768 无 Dummy。",
        startText = "【疾跑/潜行/旅行/猫】1850 猫形态约 +60% 不是 +70%。5215 切猫，Dummy −30 不是码。783 陆地 165961，Dummy 0 不是 40/60/120。",
        startPrint = "请按疾跑 1850、潜行 5215、旅行形态 783、猎豹 768。",
        ids = { 1850, 5215, 783, 159456, 165961, 1066, 33943, 40120, 768, 113636, 252216 },
        labels = {
            [1850] = "疾跑(无Dummy,Aura31=60)",
            [5215] = "潜行Dummy-30",
            [783] = "旅行形态Dummy0",
            [159456] = "旅行Rank2 Dummy60",
            [165961] = "鹿形态(40不是Dummy)",
            [1066] = "水栖(无Dummy)",
            [33943] = "飞行(无Dummy)",
            [40120] = "迅捷飞行(无Dummy)",
            [768] = "猎豹(无Dummy)",
            [113636] = "豹移速(30不是Dummy)",
            [252216] = "猛虎冲刺Dummy20",
        },
        chain = {
            { id = 1850, role = "疾跑", want = "cast",
              hintFail = "没有 1850。" },
        },
        extraVerdict = function()
            return {
                "70 不得进 Dummy。Dummy −30 不是码。40/60/120 不得进 Dummy 0。",
            }
        end,
    },

    dru_c_rebirth_revive_soothe_roots = {
        key = "dru_c_rebirth_revive_soothe_roots",
        title = "德鲁伊共用-重生Dummy100不是基点20安抚根须表已表达",
        order = 213,
        hint = "20484 Dummy 100。Eff18 基点 20 不是 Dummy。50769 无 Dummy。2908 无 Dummy。2637 无 Dummy。339 无 Dummy。20 不得进 Dummy 100。",
        startText = "【重生/起死/安抚/根须】20484 起来约 20% 血走基点 20，Dummy 100 不要写成生命%，不要包空脚本。50769/2908/2637/339 表已表达。",
        startPrint = "请看重生 20484、起死回生 50769、安抚 2908、根须 339。",
        ids = { 20484, 50769, 2908, 2637, 339, 18960, 193753, 5225 },
        labels = {
            [20484] = "重生Dummy100",
            [50769] = "起死回生(无Dummy,基点35)",
            [2908] = "安抚(无Dummy)",
            [2637] = "休眠(无Dummy)",
            [339] = "纠缠根须(无Dummy)",
            [18960] = "月光林地(无Dummy)",
            [193753] = "梦境漫步(无Dummy)",
            [5225] = "追踪人型(无Dummy)",
        },
        chain = {
            { id = 2908, role = "安抚", want = "cast",
              hintFail = "没有 2908。" },
        },
        extraVerdict = function()
            return {
                "20 不得进 Dummy 100。不要包空重生脚本。表已表达不包空。",
            }
        end,
    },

    dru_c_moonfire_charge_typhoon_bash = {
        key = "dru_c_moonfire_charge_typhoon_bash",
        title = "德鲁伊共用-月火Dummy1打164812停AddPct0台风停查62135",
        order = 214,
        hint = "8921 Dummy 1。164812 无 Dummy。102401 Dummy 0。132469 Dummy 0。61391 无 Dummy。5211 无 Dummy。102359 无 Dummy。252216 Dummy 20。62135 无行。",
        startText = "【月火/冲锋/台风/猛击】8921 出 164812，不要 AddPct BP 0。102401 变体能冲。132469 出 61391，不要 62135。5211 昏迷走表。102359 不要 15.0f 再加一层。",
        startPrint = "请打月火 8921、野性冲锋 102401、台风 132469、蛮力猛击 5211。",
        ids = { 8921, 164812, 102401, 102383, 102417, 132469, 61391, 62135, 5211, 102359, 252216 },
        labels = {
            [8921] = "月火Dummy1",
            [164812] = "月火DoT(无Dummy)",
            [102401] = "野性冲锋Dummy0",
            [102383] = "枭兽冲锋Dummy20",
            [102417] = "旅行冲锋Dummy20",
            [132469] = "台风Dummy0",
            [61391] = "台风击退(无Dummy)",
            [62135] = "已删雕文(不应再查)",
            [5211] = "蛮力猛击(无Dummy)",
            [102359] = "群体缠绕(无Dummy)",
            [252216] = "猛虎冲刺Dummy20",
        },
        chain = {
            { id = 8921, role = "月火", want = "cast",
              hintFail = "没有 8921。" },
        },
        extraVerdict = function()
            return {
                "0.145 不得进 Dummy 1。62135 不应再驱动 PreventHit。15 不得进 Dummy。",
            }
        end,
    },

    dru_c_stampede_cyclone_cleanse_artifact_scope = {
        key = "dru_c_stampede_cyclone_cleanse_artifact_scope",
        title = "德鲁伊共用-狂奔怒吼不是四专精旋风不是基线88423不验收神器不加厚",
        order = 215,
        hint = "106898 无 Dummy 只 103+104。33786 无 Dummy 不 INSERT。88423 无 Dummy 只 105 不验收。2782 无 Dummy 只 102+103+104。202767/210722 家在 spell_artifact.cpp 不加厚。208253 不加厚。77484 无行。",
        startText = "【怒吼/旋风/驱散/神器/范围】不要勾 106898 当四专精。不要 33786 基线。不要勾 88423（恢复号）。2782 是三专精清除。202767/210722/208253 看见不加厚。不要发明 pet_druid.cpp。",
        startPrint = "请确认动作条：不要旋风当基线，不要自然之愈当共用，神器不加厚。",
        ids = { 106898, 33786, 209753, 88423, 2782, 202767, 202768, 202771, 210722, 208253, 202360, 1126, 5185, 77484, 77492, 77493, 155783, 77495 },
        labels = {
            [106898] = "狂奔怒吼(无Dummy,只103+104)",
            [33786] = "旋风(无Dummy,不是基线)",
            [209753] = "平衡PvP旋风(本期不做)",
            [88423] = "自然之愈(不验收)",
            [2782] = "清除腐蚀(102+103+104)",
            [202767] = "神器新月(不加厚)",
            [202768] = "神器半月(不加厚)",
            [202771] = "神器满月(不加厚)",
            [210722] = "阿莎曼狂乱(不加厚)",
            [208253] = "加尼尔精华(不加厚)",
            [202360] = "远古祝福(不加厚)",
            [1126] = "野性印记(无行)",
            [5185] = "治疗之触(无行)",
            [77484] = "已删精通(无行)",
            [77492] = "平衡精通(不搬家)",
            [77493] = "野性精通Dummy200(不搬家)",
            [155783] = "守护精通(不搬家)",
            [77495] = "恢复精通Dummy0(不搬家)",
        },
        chain = {
            { id = 2782, role = "清除腐蚀", want = "cast",
              hintFail = "没有 2782。平衡/野性/守护才有；恢复是 88423，本包不验收 88423。" },
        },
        extraVerdict = function()
            return {
                "106898 不是四专精。33786 不 INSERT。88423 不验收。8 不得进 Dummy。神器不加厚。不要在 spell_druid.cpp 再注册 202767。本包不勾 MAS。",
            }
        end,
    },

    dru_bal_wrath_starfire_ss_starfall = {
        key = "dru_bal_wrath_starfire_ss_starfall",
        title = "平衡-愤怒星火Dummy33星涌星陨Dummy0停打197637",
        order = 216,
        hint = "190984 无 Dummy。194153 Dummy 33 只 idx2。78674 无 Dummy。191034 Dummy 0。191037 无 Dummy。197637 Dummy 20 不学会。850/9482 不是 Dummy。",
        startText = "【愤怒/星火/星涌/星陨】190984 能打。194153 溅射 Dummy 33，idx3 的 20 不是 Dummy。78674 能打。191034 跳 191037，不要 197637。",
        startPrint = "请打愤怒 190984、星火 194153、星涌 78674、星陨 191034。",
        ids = { 190984, 194153, 78674, 191034, 191037, 197637, 24858, 93402, 164815, 8921, 164812 },
        labels = {
            [190984] = "愤怒(无Dummy)",
            [194153] = "星火Dummy33",
            [78674] = "星涌(无Dummy)",
            [191034] = "星陨Dummy0",
            [191037] = "星陨跳",
            [197637] = "星辰强化(不学会,停打)",
            [24858] = "枭兽Dummy150/0",
            [93402] = "阳炎Dummy0/1",
            [164815] = "阳炎DoT(无Dummy)",
            [8921] = "月火Dummy1",
            [164812] = "月火DoT(无Dummy)",
        },
        chain = {
            { id = 190984, role = "愤怒", want = "cast",
              hintFail = "没有 190984。确认平衡专精。" },
        },
        extraVerdict = function()
            return {
                "20 不得进 Dummy 33。850/9482 不得进 Dummy 0。CLEU 不要 197637。",
            }
        end,
    },

    dru_bal_newmoon_natures_balance_starlord = {
        key = "dru_bal_newmoon_natures_balance_starlord",
        title = "平衡-新月274281不是202767自然平衡Dummy50/2/3点名idx星辰领主Dummy4残留",
        order = 217,
        hint = "274281 Dummy 0 残留。274282 Dummy 0 残留。274283 Dummy 202788/202787/0 保持列值不要写成 Dummy 0。分类 1727=3/25000。禁止 AddAura 202787 切回 202767。202767 Dummy 0 不加厚。202430 Dummy idx1/2/3=50/2/3。idx0 Aura24 BP=5 不是 Dummy，须 PreventDefault。脱战一次性补到 Dummy 50。202345 Dummy 4 残留。279709 Aura193 +3 不是 Dummy。6/4/5/15000/20秒/4% 不得进 Dummy。",
        startText = "【新月/自然平衡/星辰领主】点 T100 是 274281→274282→274283→274281 循环约 25 秒，不要变成 202767 15 秒。202430 打桩约每 3 秒 +2，脱战星能回到约 50，不要每 3 秒 +50、不要每 750 ms +5，不要 +6/+4。有 202345 才 279709 +3，Dummy 4 不读成 4%。",
        startPrint = "请点新月 274281、自然平衡 202430、星辰领主 202345。不要用神器 202767。",
        ids = { 274281, 274282, 274283, 202767, 202768, 202771, 202430, 202345, 279709, 202416, 202423 },
        labels = {
            [274281] = "新月8.3 Dummy0残留",
            [274282] = "半月8.3 Dummy0残留",
            [274283] = "满月8.3 Dummy202788/202787/0保持列值",
            [202767] = "神器新月(不加厚)",
            [202768] = "神器半月(不加厚)",
            [202771] = "神器满月(不加厚)",
            [202430] = "自然平衡Dummy50/2/3(idx1/2/3)",
            [202345] = "星辰领主Dummy4(残留不读)",
            [279709] = "星辰领主急速(+3不是Dummy)",
            [202416] = "军团星辰领主日(停打)",
            [202423] = "军团星辰领主月(停打)",
        },
        chain = {
            { id = 274281, role = "新月", want = "cast",
              hintFail = "没有 274281。确认点了 T100 新月，不要只看 202767。" },
        },
        extraVerdict = function()
            return {
                "274281 不是 202767。键须 274281→274282→274283→274281，不要变成 202767。禁止 AddAura 202787。Dummy 50/2/3 必须点名 idx1/2/3。脱战一次性补到 50，不要每 3 秒 +50、不要每 750 ms +5。5/6/4 不得进 Dummy。Dummy 4 不是每层 4%。15000/20秒不得覆盖 25000。满月 Dummy 不要写成 0。",
            }
        end,
    },

    dru_bal_eclipse_woe_fon_celestial = {
        key = "dru_bal_eclipse_woe_fon_celestial",
        title = "平衡-蚀星蔽月Dummy20伊露恩战士3层自然之力Dummy3超凡无Dummy",
        order = 218,
        hint = "279619 Dummy 20/20。禁止 roll 20 反推进 Dummy。202425 无 Dummy。205636 Dummy 3。194223 无 Dummy。102560 Dummy 0。禁止解注释 Cata eclipse。树人缩放 PET。",
        startText = "【蚀星/战士/自然之力/超凡】279619 约 Dummy 20% 出强化。202425 3 层后卸，不要 −102。205636 Dummy 3 个树人，缩放不在本波。194223 表已表达。",
        startPrint = "请点蚀星蔽月 279619、伊露恩的战士 202425、自然之力 205636。",
        ids = { 279619, 164545, 164547, 202425, 205636, 248280, 194223, 102560, 202342, 202354, 279620, 202347, 202770 },
        labels = {
            [279619] = "蚀星蔽月Dummy20/20",
            [164545] = "日能Dummy20",
            [164547] = "月能(Aura108不是Dummy)",
            [202425] = "伊露恩的战士(无Dummy)",
            [205636] = "自然之力Dummy3",
            [248280] = "树人召唤",
            [194223] = "超凡之盟(无Dummy)",
            [102560] = "化身艾露恩Dummy0",
            [202342] = "流星Periodic Dummy10",
            [202354] = "星辰漂流(无Dummy)",
            [279620] = "双子月亮(无Dummy)",
            [202347] = "星辰耀斑(无Dummy)",
            [202770] = "伊露恩之怒Dummy0",
        },
        chain = {
            { id = 205636, role = "自然之力", want = "cast",
              hintFail = "没有 205636。确认点了 T15 自然之力。" },
        },
        extraVerdict = function()
            return {
                "20 不得从 roll 反推进 Dummy。3 不是 103822 缩放。缩放不在本波。不要 Cata 48517。",
            }
        end,
    },

    dru_bal_mastery_empower_artifact_scope = {
        key = "dru_bal_mastery_empower_artifact_scope",
        title = "平衡-77492不搬家不勾MAS星涌给164545Dummy20 Dummy35残留神器不加厚",
        order = 219,
        hint = "77492 无 Dummy。Coef 1.54 不是 Dummy。不搬家。本包不勾 MAS。279708 Dummy 35 残留。164545 Dummy 20。202767 不加厚。CastIdx 295 不得发明 1.5 Dummy。",
        startText = "【精通/强化/神器/范围】77492 绿字在，不搬家，不要勾 MAS。星涌出 164545+164547，不要用 Dummy 35 覆盖 20。202767 看见不加厚。1.5 秒不得进 Dummy。",
        startPrint = "请看精通 77492、打星涌出日能月能。不要勾精通完成。不要加厚神器。",
        ids = { 77492, 78674, 279708, 164545, 164547, 202767, 210722, 208253, 202360, 197911, 197626 },
        labels = {
            [77492] = "精通星光(无Dummy,不搬家)",
            [78674] = "星涌(无Dummy)",
            [279708] = "Empowerments Dummy35(残留不读)",
            [164545] = "日能Dummy20",
            [164547] = "月能",
            [202767] = "神器新月(不加厚)",
            [210722] = "阿莎曼(本包不验收)",
            [208253] = "加尼尔(不加厚)",
            [202360] = "远古祝福(不加厚)",
            [197911] = "星能(Aura107不是Dummy)",
            [197626] = "亲和星涌Trigger(不验收)",
        },
        chain = {
            { id = 78674, role = "星涌", want = "cast",
              hintFail = "没有 78674。确认平衡专精。" },
        },
        extraVerdict = function()
            return {
                "14/2/1.75 不得写成 Dummy。本包不勾 MAS。35 不得覆盖 20。不要在 spell_druid.cpp 再注册 202767。",
            }
        end,
    },

    dru_feral_shred_rake_rip_bite = {
        key = "dru_feral_shred_rake_rip_bite",
        title = "野性-撕碎Dummy30/20斜掠Dummy100割裂Dummy2/6停CP+1",
        order = 220,
        hint = "5221 Dummy 30/20。APCoef 0.460 不是 Dummy。1822 Dummy 100。1079 Dummy 2/6。22568 无 Dummy。202031 Dummy 4。禁止 BP/100。禁止 RefreshDuration 整段。",
        startText = "【撕碎/斜掠/割裂/撕咬】5221 能打不要 0 伤，Dummy 30/20 配 231057/231063。1822 潜行 +Dummy 100%。1079 倍率 Dummy 2/6，不要 CP+1。剑齿 Dummy 4 = +4 秒/CP。",
        startPrint = "请打撕碎 5221、斜掠 1822、割裂 1079、凶猛撕咬 22568。",
        ids = { 5221, 231057, 231063, 1822, 155722, 163505, 1079, 22568, 202031 },
        labels = {
            [5221] = "撕碎Dummy30/20",
            [231057] = "撕碎Rank2 Dummy0开关",
            [231063] = "撕碎流血Dummy0开关",
            [1822] = "斜掠Dummy100",
            [155722] = "斜掠流血",
            [163505] = "斜掠昏迷(只潜行)",
            [1079] = "割裂Dummy2/6",
            [22568] = "凶猛撕咬(无Dummy)",
            [202031] = "剑齿Dummy4",
        },
        chain = {
            { id = 5221, role = "撕碎", want = "cast",
              hintFail = "没有 5221。确认野性专精猎豹形态。" },
        },
        extraVerdict = function()
            return {
                "BP/100 应已删。Dummy 2/6 不是秒数。Dummy 4 不是整段刷新。Dummy 100 不是 100 码。",
            }
        end,
    },

    dru_feral_tf_thrash_swipe_berserk = {
        key = "dru_feral_tf_thrash_swipe_berserk",
        title = "野性-猛虎之怒表已表达痛击横扫Dummy1/20狂暴Dummy0",
        order = 221,
        hint = "5217 无 Dummy。106830 无 Dummy。106785 Dummy 1/20。106951 Dummy 0。202028 Dummy 1。5215 Dummy −30。768 无 Dummy。",
        startText = "【猛虎/痛击/横扫/狂暴】5217 表已表达不包空。106830 +1 连击点。106785 Dummy 1=连击点 Dummy 20=流血+20%。106951 只猫形态。",
        startPrint = "请开猛虎之怒 5217、痛击 106830、横扫 106785、狂暴 106951。",
        ids = { 5217, 231055, 106830, 106785, 106951, 202028, 5215, 768, 22570, 106839 },
        labels = {
            [5217] = "猛虎之怒(无Dummy)",
            [231055] = "猛虎回能+30(不是Dummy)",
            [106830] = "痛击猫(无Dummy)",
            [106785] = "横扫猫Dummy1/20",
            [106951] = "狂暴Dummy0",
            [202028] = "野蛮挥砍Dummy1",
            [5215] = "潜行Dummy-30",
            [768] = "猎豹(无Dummy)",
            [22570] = "割碎Dummy0",
            [106839] = "迎头痛击Dummy0",
        },
        chain = {
            { id = 5217, role = "猛虎之怒", want = "cast",
              hintFail = "没有 5217。确认野性专精。" },
        },
        extraVerdict = function()
            return {
                "Dummy 20 不是 20 码。Dummy 0 不读成几率。5217 不要包空脚本。",
            }
        end,
    },

    dru_feral_bloodtalons_frenzy_primal_wrath = {
        key = "dru_feral_bloodtalons_frenzy_primal_wrath",
        title = "野性-血爪Dummy0在155672禁止三连狂乱Dummy5原始愤怒半径8不是10",
        order = 222,
        hint = "155672 Dummy 0。145152 无 Dummy Aura108 +25。CumulativeAura 1 ProcCharges 2。禁止 SetMaxStack(2)。禁止三连。274837 Dummy 5。285381 无 Dummy 半径 8。10 不得进 Dummy。",
        startText = "【血爪/狂乱/原始愤怒】点 155672 后愈合出 145152，不是两层叠 50%，不是三连。Dummy 0 在 155672 不是 145152。274837 Dummy 5 次后 274838，不要 100/20+AP。285381 半径 8 上 1079，不要 10 码。",
        startPrint = "请点血腥爪击 155672 再愈合、野性狂乱 274837、原始愤怒 285381。",
        ids = { 155672, 145152, 8936, 274837, 274838, 285381, 1079, 16974, 69369 },
        labels = {
            [155672] = "血爪Dummy0",
            [145152] = "血爪buff(无Dummy,+25不是Dummy)",
            [8936] = "愈合(触发血爪)",
            [274837] = "野性狂乱Dummy5/5",
            [274838] = "狂乱流血",
            [285381] = "原始愤怒(无Dummy,半径8)",
            [1079] = "割裂Dummy2/6",
            [16974] = "掠食者的迅捷Dummy50/80/20",
            [69369] = "掠食者迅捷buff",
        },
        chain = {
            { id = 155672, role = "血腥爪击", want = "cast",
              hintFail = "没有 155672。确认点了血腥爪击天赋。" },
        },
        extraVerdict = function()
            return {
                "禁止 SetMaxStack(2)。禁止三连。Dummy 0 在 155672。+25/2/3 不得进 Dummy 0。10 不得进 Dummy。5 不是 +5 连击点。掠食 Dummy 20×CP 挂终结技 AfterHit。禁止 DELETE 16974。禁止只改被动 AfterHit。",
            }
        end,
    },

    dru_feral_mastery_predator_incarn_scope = {
        key = "dru_feral_mastery_predator_incarn_scope",
        title = "野性-77493 Dummy200不搬家掠食者击杀重置化身上猫210722不加厚",
        order = 223,
        hint = "77493 Dummy 200 只 idx2。Coef 2 不是 Dummy。不搬家。本包不勾 MAS。202021 无 Dummy。102543 无 Dummy。210722 不加厚。16864 走 135700 不是 113043。",
        startText = "【精通/掠食者/化身/范围】77493 绿字在，不搬家，不要勾 MAS。点 202021 击杀重置 5217。102543 上猫。210722 看见不加厚。野性清晰预兆是 16864→135700。",
        startPrint = "请看精通 77493、点掠食者 202021、化身 102543。不要勾精通。不要加厚神器。",
        ids = { 77493, 202021, 5217, 102543, 252071, 61336, 50322, 210722, 16864, 135700, 113043, 16870 },
        labels = {
            [77493] = "精通锐爪Dummy200(不搬家)",
            [202021] = "掠食者(无Dummy)",
            [5217] = "猛虎之怒(重置目标)",
            [102543] = "化身丛林之王(无Dummy)",
            [252071] = "丛林之王Trigger",
            [61336] = "生存本能Dummy50/2",
            [50322] = "生存本能-50",
            [210722] = "阿莎曼狂乱(不加厚)",
            [16864] = "清晰预兆野性",
            [135700] = "野性节能",
            [113043] = "恢复清晰预兆(不是野性键)",
            [16870] = "恢复节能(不是野性键)",
        },
        chain = {
            { id = 102543, role = "化身丛林之王", want = "cast",
              hintFail = "没有 102543。确认点了 T75 化身。" },
        },
        extraVerdict = function()
            return {
                "2 不得进 Dummy 200。本包不勾 MAS。德鲁伊击杀才重置，类判断应已改正。不要 113043 当野性键。",
            }
        end,
    },

    dru_guard_mangle_thrash_maul_swipe = {
        key = "dru_guard_mangle_thrash_maul_swipe",
        title = "守护-裂伤Dummy20残留痛击APCoef0.025不是0.605重殴Dummy0熊横扫Dummy20",
        order = 224,
        hint = "33917 Dummy 0/20 残留不读。77758 无 Dummy。192090 APCoef 0.025 不是 Dummy。6807 Dummy 0。213771 Dummy 1/20。0.605 不得进 Dummy。",
        startText = "【裂伤/痛击/重殴/横扫】33917 能打产怒，Dummy 20 不当 +20% 伤。77758 跳 192090 走 0.025×层，不要 0.605f。6807 能打。213771 Dummy 20 流血加成，不要绑猫 106785。",
        startPrint = "请打裂伤 33917、痛击 77758、重殴 6807、熊横扫 213771。",
        ids = { 33917, 77758, 192090, 6807, 213771, 106785, 5487, 106832 },
        labels = {
            [33917] = "裂伤Dummy0/20(残留不读)",
            [77758] = "痛击熊(无Dummy)",
            [192090] = "痛击周期(APCoef0.025)",
            [6807] = "重殴Dummy0",
            [213771] = "熊横扫Dummy1/20",
            [106785] = "猫横扫(本包不验收)",
            [5487] = "熊形态(无Dummy)",
            [106832] = "痛击壳Dummy0(不验收mismatch)",
        },
        chain = {
            { id = 77758, role = "痛击", want = "cast",
              hintFail = "没有 77758。确认守护专精熊形态。" },
        },
        extraVerdict = function()
            return {
                "0.605 不得进 Dummy。Dummy 20 不是 +20% 裂伤。不要用猫横扫验收熊。",
            }
        end,
    },

    dru_guard_ironfur_frenzied_barkskin = {
        key = "dru_guard_ironfur_frenzied_barkskin",
        title = "守护-铁鬃Aura268的75不是Dummy狂暴回复6%/3秒不是50%/5秒",
        order = 225,
        hint = "192081 无 Dummy。Aura 268 75。Register EFFECT_0 SPELL_AURA_268。HandleStatModifier UNIT_MOD_ARMOR。armor=CalculatePct(敏捷,基点75)*层。禁止 DoEffectCalcAmount 当唯一落地。禁止字面 75 点护甲。22842 无 Dummy。Aura 20 6 / 3 秒。18/24/32/50/75/8/112 不得写成 Dummy。22812 Dummy 100。61336 Dummy 50/2。必须会还手的桩 131992/144078。",
        startText = "【铁鬃/狂暴回复/树皮/生存】必须会还手的木桩。192081 绑 spell_dru_ironfur。Register EFFECT_0 SPELL_AURA_268，禁止改挂 MOD_RESISTANCE。HandleStatModifier UNIT_MOD_ARMOR TOTAL_VALUE。armor=CalculatePct(敏捷, Aura 268 基点 75)*GetStackAmount()。熊点铁鬃护甲升，层数加护甲。不要 DoEffectCalcAmount 当唯一落地。不要字面 75 点护甲。不要勾「表已表达所以没脚本」。22842 每秒约 6%×3 秒，不要过去 5 秒 50%。22812 −20%。61336 Dummy 50。",
        startPrint = "请对会还手的桩开铁鬃 192081、狂暴回复 22842、树皮 22812、生存本能 61336。",
        ids = { 192081, 231070, 22842, 273048, 22812, 61336, 50322 },
        labels = {
            [192081] = "铁鬃(无Dummy,Aura268=75,spell_dru_ironfur)",
            [231070] = "铁鬃Rank2(+7不是Dummy)",
            [22842] = "狂暴回复(无Dummy,Aura20=6)",
            [273048] = "狂暴回复+1充能(不是Dummy)",
            [22812] = "树皮Dummy100/0",
            [61336] = "生存本能Dummy50/2",
            [50322] = "生存本能-50",
        },
        chain = {
            { id = 192081, role = "铁鬃", want = "cast",
              hintFail = "没有 192081。确认守护专精。必须会还手的桩。" },
        },
        extraVerdict = function()
            return {
                "75/8/112 不得进 Dummy。18/24/32/50 不得写成 Dummy。不要 50%/5 秒。不要 DoEffectCalcAmount 当唯一落地。不要字面 75 点护甲。层数加护甲。不要勾「表已表达所以没脚本」。必须会还手的桩。",
            }
        end,
    },

    dru_guard_gore_gg_pulverize = {
        key = "dru_guard_gore_gg_pulverize",
        title = "守护-Gore Dummy15打93622星系Dummy0不读成几率粉碎Dummy2层",
        order = 226,
        hint = "210706 Dummy 15。93622 重置裂伤。203964 Dummy 0 不读成几率。213708 Dummy 0/300。80313 Dummy 0/2。观察窗口几率不得进 Dummy 0。",
        startText = "【Gore/星系/粉碎】痛击/横扫/重殴/月火约 Dummy 15% 出 93622。点 203964 必出 213708，Dummy 0 不是几率。粉碎要 2 层 192090。",
        startPrint = "请点 Gore 210706、星系守护者 203964、粉碎 80313。",
        ids = { 210706, 93622, 203964, 213708, 80313, 158790, 158792, 8921 },
        labels = {
            [210706] = "Gore Dummy15",
            [93622] = "Gore重置裂伤",
            [203964] = "星系守护者Dummy0",
            [213708] = "星系月火",
            [80313] = "粉碎Dummy0/2",
            [158790] = "痛击2层标记",
            [158792] = "粉碎减伤",
            [8921] = "月火Dummy1",
        },
        chain = {
            { id = 203964, role = "星系守护者", want = "cast",
              hintFail = "没有 203964。确认点了星系守护者。" },
        },
        extraVerdict = function()
            return {
                "Dummy 15 不是必 proc 且无 93622。Dummy 0 不读成几率。Dummy 2 是层数。",
            }
        end,
    },

    dru_guard_mastery_incarn_bristling_scope = {
        key = "dru_guard_mastery_incarn_bristling_scope",
        title = "守护-155783不搬家鬃毛倒竖Dummy0化身变熊200851不加厚",
        order = 227,
        hint = "155783 无 Dummy。Coef 0.5 不是 Dummy。不搬家。本包不勾 MAS。155835 Dummy 0。102558 无 Dummy。204066 无 Dummy AT 5994。200851 不加厚。",
        startText = "【精通/鬃毛/化身/范围】155783 绿字在，不搬家，不要勾 MAS。155835 能开不崩，Dummy 0 不读。102558 变熊。200851 看见不加厚。月光普照 AT 5994 不是注释 10682。",
        startPrint = "请看精通 155783、点鬃毛倒竖 155835、化身 102558。不要勾精通。不要崩服。",
        ids = { 155783, 155835, 204031, 102558, 204066, 204069, 200851, 200854, 203953, 203974 },
        labels = {
            [155783] = "精通自然守护(无Dummy,不搬家)",
            [155835] = "鬃毛倒竖Dummy0",
            [204031] = "鬃毛回怒",
            [102558] = "化身乌索克(无Dummy)",
            [204066] = "月光普照(无Dummy)",
            [204069] = "月光束跳",
            [200851] = "沉睡者之怒(不加厚)",
            [200854] = "GoryFur(Talent无行,不加厚)",
            [203953] = "荆棘(无Dummy)",
            [203974] = "大地守卫Dummy30",
        },
        chain = {
            { id = 102558, role = "化身乌索克", want = "cast",
              hintFail = "没有 102558。确认点了 T75 化身。" },
        },
        extraVerdict = function()
            return {
                "0.5 不得进 Dummy。本包不勾 MAS。Dummy 0 不读成回怒%。不要发明 pet_druid.cpp。必须会还手的桩测减伤。",
            }
        end,
    },

    dru_resto_rejuv_regrowth_lifebloom_swiftmend = {
        key = "dru_resto_rejuv_regrowth_lifebloom_swiftmend",
        title = "恢复-回春愈合Lifebloom迅捷治愈无Dummy必须治疗假人",
        order = 228,
        hint = "774 无 Dummy。8936 无 Dummy。33763 无 Dummy。18562 无 Dummy。5185 无行不验收。必须治疗假人 131994/132036/144075。",
        startText = "【回春/愈合/绽放/迅捷】必须治疗假人。774 能跳。8936 能治。33763 单层到期 33778。18562 不消耗 HoT。不要按 5185 验收。",
        startPrint = "请对治疗假人按回春 774、愈合 8936、生命绽放 33763、迅捷治愈 18562。",
        ids = { 774, 8936, 33763, 33778, 18562, 5185, 231040, 155675, 155777, 114108 },
        labels = {
            [774] = "回春(无Dummy)",
            [8936] = "愈合(无Dummy)",
            [33763] = "生命绽放(无Dummy)",
            [33778] = "绽放",
            [18562] = "迅捷治愈(无Dummy)",
            [5185] = "治疗之触(无行,不验收)",
            [231040] = "回春Rank2 +3000ms(不是Dummy)",
            [155675] = "萌芽(无Dummy)",
            [155777] = "萌芽第二层",
            [114108] = "丛林之魂恢复",
        },
        chain = {
            { id = 774, role = "回春", want = "cast",
              hintFail = "没有 774。必须用治疗假人。" },
        },
        extraVerdict = function()
            return {
                "必须治疗假人。5185 不要勾完成。0 不是 Dummy。",
            }
        end,
    },

    dru_resto_wildgrowth_efflo_tranq = {
        key = "dru_resto_wildgrowth_efflo_tranq",
        title = "恢复-野性成长人数6不是7百花Dummy5人数6宁静Dummy1/100不是180%",
        order = 229,
        hint = "48438 Dummy 20 只 idx1。人数 Idx2 6。6/7 不得改 Dummy 20。145205 Dummy 5。人数 Idx2 6。resize 3 应已改。740 Dummy 1/100。180 不得进 Dummy。必须治疗假人。",
        startText = "【野性成长/百花/宁静】必须治疗假人。48438 最多 6 人不是 7，Dummy 20 不是人数。145205 Dummy 5 残留，人数 6 不是 3。740 跳 157982，不要 180% 法强。",
        startPrint = "请对一排治疗假人按野性成长 48438、百花 145205、宁静 740。",
        ids = { 48438, 145205, 81262, 81269, 740, 157982, 33891, 117679, 5420 },
        labels = {
            [48438] = "野性成长Dummy20(人数6不是Dummy)",
            [145205] = "百花Dummy5",
            [81262] = "百花周期Dummy0",
            [81269] = "百花疗",
            [740] = "宁静Dummy1/100",
            [157982] = "宁静跳",
            [33891] = "树命Dummy0",
            [117679] = "树命30秒(不是Dummy)",
            [5420] = "树形态增强(不是Dummy)",
        },
        chain = {
            { id = 48438, role = "野性成长", want = "cast",
              hintFail = "没有 48438。必须用治疗假人。" },
        },
        extraVerdict = function()
            return {
                "6/7 不得改 Dummy 20。5/6/3 不得互填 Dummy。180 不得进 Dummy。30/-1 不得进 Dummy 0。必须治疗假人。",
            }
        end,
    },

    dru_resto_photosynthesis_flourish_innervate = {
        key = "dru_resto_photosynthesis_flourish_innervate",
        title = "恢复-光合Dummy20/5繁盛无Dummy激活Aura423不是Dummy结界Dummy100",
        order = 230,
        hint = "274902 Dummy 20/5。停一律 274906。197721 无 Dummy。8 不是 Dummy。29166 无 Dummy。−100 不是 Dummy。102351 Dummy 100。220 不得进 Dummy。必须治疗假人。",
        startText = "【光合/繁盛/激活/结界】必须治疗假人。274902：自己 Lifebloom 才 274906，Dummy 5 是盟友绽放不是 4。197721 延长秒。29166 耗蓝约 0。102351 挨打出 102352，不要 220/4。",
        startPrint = "请对治疗假人点光合作用 274902、繁盛 197721、激活 29166、塞纳里奥结界 102351。",
        ids = { 274902, 274906, 33763, 197721, 29166, 102351, 102352, 207385, 207386, 200390, 207383 },
        labels = {
            [274902] = "光合作用Dummy20/5",
            [274906] = "光合加速(自己HoT)",
            [33763] = "生命绽放",
            [197721] = "繁盛(无Dummy)",
            [29166] = "激活(无Dummy)",
            [102351] = "结界Dummy100",
            [102352] = "结界HoT",
            [207385] = "春暖花开Dummy0",
            [207386] = "春暖花开跳",
            [200390] = "栽培Dummy60",
            [207383] = "丰饶Dummy0",
        },
        chain = {
            { id = 274902, role = "光合作用", want = "cast",
              hintFail = "没有 274902。确认点了 T100 光合作用。必须治疗假人。" },
        },
        extraVerdict = function()
            return {
                "Wowpedia 4 不得覆盖 Dummy 5。−100/12/180 不得进 Dummy。220 不得进 Dummy 100。必须治疗假人。",
            }
        end,
    },

    dru_resto_mastery_ht_cleanse_scope = {
        key = "dru_resto_mastery_ht_cleanse_scope",
        title = "恢复-77495 Dummy0不搬家5185无行88423不选边填8神器不加厚",
        order = 231,
        hint = "77495 Dummy 0 只 idx0。Coef 0.55 不是 Dummy。77484 无行。不搬家。本包不勾 MAS。5185 无行不验收。88423 无 Dummy。8 不得进 Dummy。208253 不加厚。CastIdx 243 不得发明 1.5 Dummy。必须治疗假人。",
        startText = "【精通/治疗之触/自然之愈/范围】必须治疗假人。77495 绿字在，不要把 0.55 填进 Dummy 0，不要勾 MAS。不要按 5185 验收。88423 能驱散，Rec 0 与分类 8000 两边留，8 不得进 Dummy。208253 看见不加厚。",
        startPrint = "请看精通 77495、自然之愈 88423。不要按治疗之触验收。不要勾精通。",
        ids = { 77495, 77484, 5185, 88423, 2782, 208253, 218889, 145108, 102342, 113043, 16870 },
        labels = {
            [77495] = "精通和谐Dummy0(不搬家)",
            [77484] = "已删精通(无行)",
            [5185] = "治疗之触(无行,不验收)",
            [88423] = "自然之愈(无Dummy,不选边填8)",
            [2782] = "另一号清除(本包不验收)",
            [208253] = "加尼尔精华(不加厚)",
            [218889] = "神器繁盛Trigger(不加厚)",
            [145108] = "伊瑟拉的礼物Dummy3",
            [102342] = "铁木树皮Dummy12",
            [113043] = "清晰预兆恢复",
            [16870] = "节能施法Dummy0",
        },
        chain = {
            { id = 88423, role = "自然之愈", want = "cast",
              hintFail = "没有 88423。确认恢复专精。不要用 2782 验收恢复。" },
        },
        extraVerdict = function()
            return {
                "0.55 不得进 Dummy 0。本包不勾 MAS。5185 不要勾完成。8 不得进 Dummy。必须治疗假人。",
            }
        end,
    },

    pet_loader_addsc_35695 = {
        key = "pet_loader_addsc_35695",
        title = "PET接线-pack绿勾只证明883_AddSC与35695INSERT认3307与启动日志",
        order = 232,
        hint = "AddSC_pet_spell_scripts 非空。loader 必须声明并调用。35695 无 Dummy。Aura 57/52 BonusCoef 1 不是 Dummy。禁止 INSERT 19591/61013/61017/61697。",
        startText = "【loader/35695】Call Pet 1（883）。槽 2–5 是 83242–83245，不要只靠槽 2–5。自动判定只证明 883；AddSC 声明调用与 35695 INSERT 只认 3307 SELECT + 启动日志，不要靠 pack 绿勾。禁止 aura-self 盯 35695/34902。LearnPetPassives 不改。已删号不要挂。打 131989，不要小熊猫。",
        startPrint = "请 Call Pet 1（883）打桩。自动判定只证明 883。AddSC/35695 只认 3307 SELECT + 启动日志，不要靠绿勾。不要小熊猫。",
        ids = { 883, 35695, 35697, 34902, 20782, 51906, 76657 },
        labels = {
            [883] = "召唤宠物(无Dummy)",
            [35695] = "PetPassive(DND)无Dummy",
            [35697] = "PetPassive受伤(无Dummy,不INSERT)",
            [34902] = "HunterPet Dummy0(不INSERT)",
            [20782] = "CombatExperience(Aura79=60不是Dummy)",
            [51906] = "符文武器缩放(无Dummy,不INSERT)",
            [76657] = "野兽精通Dummy190(不搬家,不勾MAS)",
        },
        chain = {
            { id = 883, role = "召唤宠物", want = "cast",
              hintFail = "没有 883。必须 Call Pet 1（883）。槽 2–5 是 83242–83245，不要只靠槽 2–5。自动判定只证明 883；AddSC 声明调用与 35695 INSERT 只认 3307 SELECT + 启动日志，不要靠 pack 绿勾。禁止 aura-self 盯 35695/34902。LearnPetPassives 不改。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "自动判定只证明 883。AddSC 声明调用与 35695 INSERT 只认 3307 SELECT + 启动日志，不要靠 pack 绿勾。禁止 aura-self 盯 35695/34902。LearnPetPassives 不改。0.6 不得进 Dummy 0。本包不勾 MAS。不要小熊猫。",
            }
        end,
    },

    pet_deleted_ids_dummy_keep = {
        key = "pet_deleted_ids_dummy_keep",
        title = "PET接线-已删Scaling号不挂_绿勾只证明883不是AddSC",
        order = 233,
        hint = "19591/61013/61017/61697/34903/34904/54566/34947/1964 SpellName 无行。34902 Dummy 0。20782 无 Dummy Aura79 60 不是继承 60% AP。199373 AP 0.111。91776 AP 0.30。51963 AP 0.15。34433 Dummy 0。55342 Dummy 3。",
        startText = "【已删号/Dummy保持】Call Pet 1（883）。槽 2–5 是 83242–83245，不要只靠槽 2–5。自动判定只证明 883；AddSC 声明调用与 35695 INSERT 只认 3307 SELECT + 启动日志，不要靠 pack 绿勾。禁止 aura-self 盯 35695/34902。LearnPetPassives 不改。不要给 19591/61017/54566/34947 INSERT。34902 Dummy 0 残留不读。60 不是 RAP 继承。SimC 0.6/0.5/0.4/1.0/0.55 不得进 Dummy、不得进 InitStats。",
        startPrint = "请 Call Pet 1（883）。自动判定只证明 883。已删号不挂认 3307 SELECT，不要靠 pack 绿勾。Dummy 列保持。",
        ids = { 883, 19591, 61013, 61017, 61697, 34903, 34904, 54566, 34947, 1964, 34902, 20782, 199373, 91776, 51963, 34433, 55342 },
        labels = {
            [883] = "召唤宠物(无Dummy)",
            [19591] = "已删TamedPassive06",
            [61013] = "已删WarlockScaling05",
            [61017] = "已删HunterScaling04",
            [61697] = "已删DKScaling03",
            [34903] = "已删HunterScaling02",
            [34904] = "已删HunterScaling03",
            [54566] = "已删DKScaling01",
            [34947] = "已删WarlockScaling01",
            [1964] = "已删树人旧生物",
            [34902] = "Dummy0残留不读",
            [20782] = "Aura79=60不是继承AP",
            [199373] = "大军爪AP0.111不是Dummy",
            [91776] = "尸鬼爪AP0.30不是Dummy",
            [51963] = "石像鬼AP0.15不是Dummy",
            [34433] = "暗影魔Dummy0",
            [55342] = "镜像Dummy3个数",
        },
        chain = {
            { id = 883, role = "召唤宠物", want = "cast",
              hintFail = "没有 883。必须 Call Pet 1（883）。槽 2–5 是 83242–83245，不要只靠槽 2–5。自动判定只证明 883；AddSC 声明调用与 35695 INSERT 只认 3307 SELECT + 启动日志，不要靠 pack 绿勾。禁止 aura-self 盯 35695/34902。LearnPetPassives 不改。本包盯已删号不挂、Dummy 列保持。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "自动判定只证明 883。AddSC 声明调用与 35695 INSERT 只认 3307 SELECT + 启动日志，不要靠 pack 绿勾。禁止 aura-self 盯 35695/34902。LearnPetPassives 不改。已删号不挂。0.6/0.5/0.4/1.0/0.55/1.15/1.25/0.4x1.06 不得进 Dummy。60 不是继承 AP。不要发明 pet_warlock.cpp。",
            }
        end,
    },

    pet_hun_bm_scale = {
        key = "pet_hun_bm_scale",
        title = "PET缩放-本包必须用打16827的科_0.333不得进Dummy0",
        order = 234,
        hint = "16827/17253/49966 无 Dummy。34902 Dummy 0 残留不读。20782 Aura79 60 不是继承 AP。0.333f 非 DBC 不得进 Dummy。本波不改 spell_hunter.cpp。循环不搬进 spell_pet。不勾 MAS。",
        startText = "【猎人宠物】120 野兽控制 Call Pet 1（883）。本包必须用打 16827 的科。打 131989 出 16827。失败时禁止改 spell_hunter.cpp。0.333/0.6 不得进 Dummy 0。不要把 883 want=summon 当本包完成。不要倒刺/杀戮/眼镜蛇当本包完成。不要小熊猫 36911。",
        startPrint = "请 Call Pet 后用打 16827 的科打伤害桩 131989。本包必须用打 16827 的科。失败时禁止改 spell_hunter.cpp。",
        ids = { 883, 982, 16827, 17253, 49966, 34902, 20782, 35695, 76657, 267116, 36911 },
        labels = {
            [883] = "召唤宠物(无Dummy)",
            [982] = "复活宠物(无Dummy)",
            [16827] = "爪击(无Dummy,AP列0)",
            [17253] = "撕咬(无Dummy)",
            [49966] = "掌击(无Dummy)",
            [34902] = "HunterPet Dummy0",
            [20782] = "CombatExperience(60不是继承AP)",
            [35695] = "PetPassive无Dummy",
            [76657] = "精通Dummy190(不勾MAS)",
            [267116] = "动物伙伴(无Dummy,Aura429-35不是Dummy)",
            [36911] = "小熊猫(不当验收)",
        },
        chain = {
            { id = 16827, role = "爪击", want = "damage",
              hintFail = "宠物没有打出 16827 伤害。本包必须用打 16827 的科。失败时禁止改 spell_hunter.cpp。0.333/0.6 不得进 Dummy 0。不要把 883 want=summon 当本包完成。必须是战斗宠物不是小熊猫。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "本包必须用打 16827 的科。失败时禁止改 spell_hunter.cpp。0.6/0.333 不得进 Dummy 0。不要把 883 want=summon 当本包完成。不要勾 BM 循环。不要勾 MAS。不要小熊猫。",
            }
        end,
    },

    pet_wl_summons_scale = {
        key = "pet_wl_summons_scale",
        title = "PET缩放-术士召唤物能打34947无行不挂Demo循环不验收",
        order = 235,
        hint = "3110 BonusCoef 0.40 不是 Dummy。104318 BonusCoef 0.046。205196 AP 1.0。104316 Dummy 2 是只数。34947 SpellName 无行。SimC 0.5/1.15/1.25 非 DBC。不要发明 pet_warlock.cpp。",
        startText = "【术士宠物】688 小鬼出 3110 或 104316 猎犬出 205196，打 131989。不要勾手之卫/暴君/恶魔箭。不要 34947。InitStats 0.15f 保持不是 SimC 0.5。",
        startPrint = "请召唤小鬼或恐惧猎犬打伤害桩。不要按恶魔学识循环验收。",
        ids = { 688, 697, 691, 712, 30146, 3110, 104316, 104318, 205196, 98035, 34947, 77219, 137044, 265187, 265273 },
        labels = {
            [688] = "召唤小鬼(无Dummy)",
            [697] = "虚空行者(无Dummy)",
            [691] = "地狱猎犬(无Dummy)",
            [712] = "魅魔(无Dummy)",
            [30146] = "恶魔卫士(无Dummy)",
            [3110] = "火箭(BonusCoef0.40不是Dummy)",
            [104316] = "召唤恐惧猎犬Dummy2",
            [104318] = "野性小鬼火箭(Coef0.046)",
            [205196] = "恐惧咬(AP1.0不是Dummy)",
            [98035] = "恐惧猎犬生物",
            [34947] = "已删WarlockScaling(不挂)",
            [77219] = "恶魔学识精通(不搬家)",
            [137044] = "专精Aura429+15不是Dummy",
            [265187] = "暴君(循环不验收)",
            [265273] = "DemonicPower Dummy15/15000(不互填)",
        },
        chain = {
            { id = 3110, role = "小鬼火箭", want = "damage",
              hintFail = "没有 3110 伤害。可改召 104316 看 205196。不要用 Demo 循环当失败理由。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "34947 不挂。0.5/1.15/1.25 不得进 Dummy。不要发明 pet_warlock.cpp。Demo 循环不验收。不勾 MAS。",
            }
        end,
    },

    pet_dk_ghoul_army_gargoyle = {
        key = "pet_dk_ghoul_army_gargoyle",
        title = "PET缩放-尸鬼大军石像鬼AP走表停写死15",
        order = 236,
        hint = "91776 AP 0.30。199373 AP 0.111。51963 AP 0.15。49206 Dummy 30/2。54566 无行。禁止 SetHitDamage AP/100*15。SimC 0.6/0.4x1.06/1/3 非 DBC。循环不搬进 spell_pet。",
        startText = "【DK宠物】46584 尸鬼出 91776；42651 大军出 199373；49206 石像鬼出 51963 且不要主人 AP×15% 写死。不要勾脓疮/天启循环完成。111101 有 case 即可。",
        startPrint = "请邪恶专精召尸鬼、大军、石像鬼打 131989。",
        ids = { 46584, 52150, 26125, 91776, 42651, 24207, 199373, 49206, 27829, 51963, 221180, 111101, 54566, 137007 },
        summonEntries = { 26125, 24207, 27829, 111101 },
        labels = {
            [46584] = "亡者复生Dummy1",
            [52150] = "RaiseDead召唤",
            [26125] = "复活盟友生物",
            [91776] = "尸鬼爪AP0.30",
            [42651] = "亡者大军",
            [24207] = "大军尸鬼生物",
            [199373] = "大军爪AP0.111",
            [49206] = "召唤石像鬼Dummy30/2",
            [27829] = "黑锋石像鬼生物",
            [51963] = "石像鬼打击AP0.15",
            [221180] = "天启大军召唤(循环不验收)",
            [111101] = "天启尸鬼生物",
            [54566] = "已删DKScaling01",
            [137007] = "专精Aura429-3不是Dummy",
        },
        chain = {
            { id = 51963, role = "石像鬼打击", want = "damage",
              hintFail = "没有 51963 伤害。先 49206。不要再是脚本写死 15% 主人 AP。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "0.15 不得另造成 Dummy。0.111 不得被 0.4x1.06 覆盖。不要勾邪恶循环。54566 不挂。",
            }
        end,
    },

    pet_pri_shadowfiend_mindbender = {
        key = "pet_pri_shadowfiend_mindbender",
        title = "PET缩放-暗影魔Dummy0摧心魔62982抄0.3f不是100%SP",
        order = 237,
        hint = "34433 Dummy 0。200174 无 Dummy。19668/62982。SimC 1.0 非 DBC 不得进 Dummy 0。AI 在 pet_priest.cpp 不搬。",
        startText = "【暗影魔】34433 出 19668 打 131989。有摧心魔则 200174 出 62982。自动判定不按 entry / step.id 过滤。人测确认生物 19668 / 62982。Dummy 0 不是 100% 法强。不要改 pet_priest.cpp。不要改 HavenLab_Verdict.lua。",
        startPrint = "请暗影专精放暗影魔打伤害桩。自动判定不按 entry / step.id 过滤。人测确认生物 19668 / 62982。",
        ids = { 34433, 19668, 200174, 62982 },
        labels = {
            [34433] = "暗影魔Dummy0",
            [19668] = "暗影魔生物",
            [200174] = "摧心魔(无Dummy)",
            [62982] = "摧心魔生物",
        },
        summonEntries = { 19668, 62982 },
        chain = {
            { id = 34433, role = "暗影魔", want = "summon",
              expect = { minCount = 1, dealsDamage = true },
              hintFail = "没有 34433 召唤物打桩。自动判定不按 entry / step.id 过滤。人测确认生物 19668。摧心魔走 200174/62982。不要改 HavenLab_Verdict.lua。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "自动判定不按 entry / step.id 过滤。人测确认生物 19668 / 62982。1.0 不得进 Dummy 0。0.3f 是引擎现有不是 Dummy。不要搬 AI。不要改 HavenLab_Verdict.lua。",
            }
        end,
    },

    pet_mage_mirror_image = {
        key = "pet_mage_mirror_image",
        title = "PET缩放-镜像Dummy3是个数不是55%SP生物31216",
        order = 238,
        hint = "55342 Dummy 3。召唤 31216。47243/47244 不是 55342 产物。SimC 0.55 非 DBC 不得进 Dummy 3。case 31216 0.33f 保持。",
        startText = "【镜像】55342 出三个 31216 打 131989。自动判定不按 entry / step.id 过滤。必须人测确认生物 31216，不是 510/47243。Dummy 3 = 个数。0.55 不得进 Dummy 3。不要改 HavenLab_Verdict.lua。",
        startPrint = "请法师放镜像。自动判定不按 entry / step.id 过滤。人测确认三只是 31216，不是 510/47243。",
        ids = { 55342, 58831, 31216, 47243, 47244, 510, 31707 },
        labels = {
            [55342] = "镜像Dummy3",
            [58831] = "镜像召唤31216",
            [31216] = "镜像生物",
            [47243] = "旧镜像(不是55342产物)",
            [47244] = "旧镜像(不是55342产物)",
            [510] = "水元素(表已表达,本包不强制)",
            [31707] = "水元素技能(BonusCoef0.2925不是Dummy)",
        },
        summonEntries = { 31216 },
        chain = {
            { id = 55342, role = "镜像", want = "summon",
              expect = { minCount = 3, dealsDamage = true },
              hintFail = "没有三个 31216 打桩。自动判定不按 entry / step.id 过滤。必须人测确认生物 31216，不是 510/47243。Dummy 3 = 个数。不要改 HavenLab_Verdict.lua。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "自动判定不按 entry / step.id 过滤。必须人测确认生物 31216，不是 510/47243。Dummy 3 是个数。0.55 不得进 Dummy 3。不要改 HavenLab_Verdict.lua。",
            }
        end,
    },

    pet_sha_wolf_ele = {
        key = "pet_sha_wolf_ele",
        title = "PET缩放-狼魂Dummy0火土元素95061/95072不是旧ID",
        order = 239,
        hint = "51533 Dummy 0。228562→29264。198067 Dummy 0→95061。198103 Dummy 0→95072。15438/15352 是旧 ID。不改 pet_shaman.cpp。58877 Dummy 225。",
        startText = "【萨满宠物】51533 出 29264 打桩。自动判定不按 entry / step.id 过滤。火土必须分条确认地上是 95061 / 95072 不是 15438/15352。禁止把 51533 绿勾当 case 95061/95072 已落地。Dummy 0 不读成继承 0%。不要改 HavenLab_Verdict.lua。",
        startPrint = "请萨满放狼魂、火元素、土元素。自动判定不按 entry / step.id 过滤。分条确认地上 95061/95072，禁止把 51533 绿勾当火土 case 已落地。",
        ids = { 51533, 228562, 29264, 58877, 198067, 95061, 198103, 95072, 15438, 15352 },
        labels = {
            [51533] = "野性狼魂Dummy0",
            [228562] = "狼魂召唤29264",
            [29264] = "幽灵狼生物",
            [58877] = "SpiritHunt Dummy225",
            [198067] = "火元素Dummy0",
            [95061] = "8.3火元素生物",
            [198103] = "土元素Dummy0",
            [95072] = "8.3土元素生物",
            [15438] = "旧火元素ID(不验收)",
            [15352] = "旧土元素ID(不验收)",
        },
        summonEntries = { 29264, 95061, 95072 },
        chain = {
            { id = 51533, role = "野性狼魂", want = "summon",
              expect = { minCount = 1, dealsDamage = true },
              hintFail = "没有 29264 打桩。自动判定不按 entry / step.id 过滤。火土必须分条确认地上是 95061 / 95072 不是 15438/15352。禁止把 51533 绿勾当 case 95061/95072 已落地。不要改 HavenLab_Verdict.lua。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "自动判定不按 entry / step.id 过滤。火土必须分条确认地上是 95061 / 95072 不是 15438/15352。禁止把 51533 绿勾当 case 95061/95072 已落地。Dummy 0 不读成继承。不改 pet_shaman.cpp。不要改 HavenLab_Verdict.lua。SimC 0.6/1.0/0.25 不得进 Dummy。",
            }
        end,
    },

    pet_dru_treant = {
        key = "pet_dru_treant",
        title = "PET缩放-树人Dummy3生物103822不是1964不发明pet_druid",
        order = 240,
        hint = "205636 Dummy 3。248280→103822。1964 SpellName 无行。InitStats case 103822 抄 1964 的 0.15f。禁止 SimC 0.6。不要发明 pet_druid.cpp。103822 ScriptName 保持空。",
        startText = "【树人】平衡点 205636，三只 103822 打 131989。自动判定不按 entry / step.id 过滤。必须人测确认生物 103822，不是 1964。Dummy 3 = 只数。不要新建 pet_druid.cpp。0.6 不得进 Dummy 3。不要改 HavenLab_Verdict.lua。",
        startPrint = "请平衡德鲁伊放自然之力。自动判定不按 entry / step.id 过滤。人测确认三只是 103822，不是 1964。",
        ids = { 205636, 248280, 103822, 1964, 77492 },
        labels = {
            [205636] = "自然之力Dummy3",
            [248280] = "树人召唤103822",
            [103822] = "8.3树人生物",
            [1964] = "已删旧树人",
            [77492] = "平衡精通(不搬家,不勾MAS)",
        },
        summonEntries = { 103822 },
        chain = {
            { id = 205636, role = "自然之力", want = "summon",
              expect = { minCount = 3, dealsDamage = true },
              hintFail = "没有三只 103822 打桩。自动判定不按 entry / step.id 过滤。必须人测确认生物 103822，不是 1964。Dummy 3 = 只数。不要改 HavenLab_Verdict.lua。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "自动判定不按 entry / step.id 过滤。必须人测确认生物 103822，不是 1964。Dummy 3 是只数。不要发明 pet_druid.cpp。0.6 不得进 Dummy 3。本包不勾 MAS。不要改 HavenLab_Verdict.lua。",
            }
        end,
    },

    mas_mage_ignite_dummy75_phoenix_meteor = {
        key = "mas_mage_ignite_dummy75_phoenix_meteor",
        title = "MAS点燃-Dummy75在EFFECT1_凤凰257541流星153564必须绑ignite",
        order = 241,
        hint = "12846 Dummy 0/75。Dummy 75 在 EFFECT_1。masteryValue=Mastery*Dummy75/100。禁止 masteryValue=75。BonusCoef 0.75 不是 Dummy。257541/153564 必须绑 spell_mastery_ignite。BFA 贡献点燃不是 9.0 凤凰蔓延。不要改 spell_mage.cpp 当搬家。",
        startText = "【点燃Dummy75/凤凰/流星】120 火焰打 131989。火球 133 上 12654。点 257541 也要上 12654。流星 153561 出 153564 后目标有 12654。Dummy 75 在 EFFECT_1。0.75/8/78 不得进 Dummy 75。不要勾 9.0 凤凰蔓延。",
        startPrint = "请火焰法师打桩上点燃，再放凤凰和流星。Dummy 75 在 EFFECT_1。",
        ids = { 12846, 12654, 133, 257541, 153561, 153564, 194466, 2120 },
        labels = {
            [12846] = "点燃Dummy0/75(EFFECT1是75)",
            [12654] = "点燃光环PeriodicDummy0",
            [133] = "火球(已绑ignite)",
            [257541] = "凤凰必须绑ignite",
            [153561] = "流星施放",
            [153564] = "流星伤必须绑ignite",
            [194466] = "神器凤凰(不加厚)",
            [2120] = "烈焰风暴(已绑ignite)",
        },
        chain = {
            { id = 133, role = "火球", want = "cast",
              hintFail = "没有 133。120 火焰对 131989 打火球。Dummy 75 在 12846 EFFECT_1。禁止 masteryValue=75。禁止 want=aura。" },
            { id = 12654, role = "点燃光环", want = "damage-aura",
              hintFail = "没有 12654。点燃没挂上。257541/153564 必须绑 spell_mastery_ignite。不是 9.0 凤凰蔓延。" },
        },
        extraVerdict = function()
            return {
                "Dummy 75 在 EFFECT_1。0.75/8/78 不得进 Dummy 75。257541/153564 必须绑 ignite。不要 DELETE phoenix_flames。194466 不加厚。本包勾 MAS 点燃。",
            }
        end,
    },

    mas_mage_ignite_spread_8yd_level78 = {
        key = "mas_mage_ignite_spread_8yd_level78",
        title = "MAS点燃-蔓延8码观察窗口_学会78保留不得进Dummy75",
        order = 242,
        hint = "半径列空。脚本保持 8.0f 观察窗口非 Dummy。getLevel()>=78 保留。9.0.1 学会 10 弃用。8/78 不得进 Dummy 75。",
        startText = "【蔓延8码/78级】两只敌对假人约 8 码。主目标 12654 可蔓延到第二只。角色必须 >=78（120 即可）。不要把 8 或 78 写进 Dummy 75。不要 9.0 凤凰蔓延。",
        startPrint = "请两只桩测点燃蔓延。8 码是观察窗口。78 级保留。",
        ids = { 12846, 12654, 133 },
        labels = {
            [12846] = "点燃Dummy75(8码不是Dummy)",
            [12654] = "点燃光环",
            [133] = "火球",
        },
        chain = {
            { id = 12654, role = "点燃光环", want = "damage-aura",
              hintFail = "没有 12654。蔓延 8.0f 是观察窗口不是 Dummy 75。78 级保留。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "8 码 / 78 级不得进 Dummy 75。蔓延保持 8.0f。getLevel()>=78 保留。本包勾 MAS 蔓延观察窗口。",
            }
        end,
    },

    mas_mage_icicles_dummy5_stop_artifact20 = {
        key = "mas_mage_icicles_dummy5_stop_artifact20",
        title = "MAS冰刺-Dummy5槽上限_停神器20不是Dummy5_泻冰刺不搬家",
        order = 243,
        hint = "76613 Dummy 0/5。5=槽上限。Coef 0.019/1.9 走表。Ice Nine 214664 / Black Ice 195615 的 20 不是 Dummy。停 roll_chance_i(20)。泻冰刺 spell_mage_ice_lance 不搬家。",
        startText = "【冰刺Dummy5】120 冰霜寒冰箭存刺，最多 5 根（Dummy 5）。冰枪 30455 泻刺（不搬家）。不要靠 Ice Nine 20% 出第六根。20 不得进 Dummy 5。0.019/1.9 不是 Dummy。",
        startPrint = "请冰霜法师存刺再冰枪泻刺。Dummy 5 是槽上限。不要神器 20%。",
        ids = { 76613, 148022, 148023, 30455, 116, 214664, 195615, 199786 },
        labels = {
            [76613] = "冰刺Dummy0/5槽上限",
            [148022] = "冰刺伤害",
            [148023] = "泻刺周期Dummy0",
            [30455] = "冰枪(泻刺不搬家)",
            [116] = "寒冰箭存刺",
            [214664] = "IceNine(20不是Dummy,停roll)",
            [195615] = "BlackIce(20不是Dummy,停roll)",
            [199786] = "冰川尖刺吃刺",
        },
        chain = {
            { id = 116, role = "寒冰箭", want = "cast",
              hintFail = "没有 116。120 冰霜打寒冰箭存刺。Dummy 5 是槽上限。禁止 want=aura。" },
            { id = 30455, role = "冰枪泻刺", want = "cast",
              hintFail = "没有 30455。泻冰刺家在 spell_mage_ice_lance，不搬家。" },
        },
        extraVerdict = function()
            return {
                "Dummy 5 是槽上限。20 不是 Dummy 5。停神器 roll。0.019/1.9 不得进 Dummy。泻冰刺不搬家。本包勾 MAS 冰刺。",
            }
        end,
    },

    mas_monk_combo_ondamage_include_sck = {
        key = "mas_monk_combo_ondamage_include_sck",
        title = "MAS连击-Dummy0_不扩自动攻击_纳入神鹤乱舞101546_删SpellTaken双乘",
        order = 244,
        hint = "115636 Dummy 0。Coef 1.25 不是 Dummy。OnDamage：spellProto==nullptr 跳过自动攻击；非空含 101546 纳入。删除 ModifySpellDamageTaken 避免双乘。1.25 不得填 Dummy 0。",
        startText = "【连击Dummy0】120 踏风对 131989。虎掌 100780 接旭日 107428，第二下应吃精通。神鹤乱舞 101546 应吃。自动攻击不应因「上一个技能」涨。不要 1.25 当 Dummy。",
        startPrint = "请踏风交替技能打桩，再放神鹤乱舞。不要用自动攻击验收精通。",
        ids = { 115636, 100780, 107428, 101546, 100784 },
        labels = {
            [115636] = "连击Dummy0(1.25不是Dummy)",
            [100780] = "虎掌",
            [107428] = "旭日东升踢",
            [101546] = "神鹤乱舞(纳入)",
            [100784] = "幻灭踢",
        },
        chain = {
            { id = 100780, role = "虎掌", want = "cast",
              hintFail = "没有 100780。120 踏风打桩。连击 Dummy 0。禁止 want=aura。" },
            { id = 107428, role = "旭日", want = "damage",
              hintFail = "没有 107428 伤害。交替技能应吃精通。自动攻击不扩。" },
        },
        extraVerdict = function()
            return {
                "Dummy 0 保持。1.25 不是 Dummy。不扩自动攻击。神鹤乱舞纳入。不要双乘 SpellTaken。本包勾 MAS 连击。",
            }
        end,
    },

    mas_wl_chaotic_two_homes = {
        key = "mas_wl_chaotic_two_homes",
        title = "MAS混乱能量-两处家Dummy0/0_吸收读EFFECT1_PlayerScript非DBC_/2不得进Dummy",
        order = 245,
        hint = "77220 Dummy 0/0。吸收 Aura 在 spell_warlock.cpp。PlayerScript 在 mastery。不搬家不删一边。ceil(EFFECT_0/2)+urand 非 DBC。Coef 2/0.666 不是 Dummy。10.0 删减伤弃用。",
        startText = "【混乱能量两处家】120 毁灭打 131989。77220 在身。直伤浮动。吸收仍在。不要搬家。/2 不得进 Dummy 0/0。不要勾已搬进 mastery。",
        startPrint = "请毁灭术士打桩看伤浮动和吸收。两处家都留。",
        ids = { 77220, 116858, 29722 },
        labels = {
            [77220] = "混乱能量Dummy0/0两处家",
            [116858] = "混乱之箭",
            [29722] = "烧尽",
        },
        chain = {
            { id = 116858, role = "混乱之箭", want = "damage",
              hintFail = "没有 116858 伤害。120 毁灭打桩。77220 两处家都要在。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "Dummy 0/0 保持。/2 rng 不得进 Dummy。不要搬家、不要删一边。10.0 删减伤弃用。本包勾 MAS 混乱能量两处家。",
            }
        end,
    },

    mas_sha_overload_keep_shaman_file = {
        key = "mas_sha_overload_keep_shaman_file",
        title = "MAS过载-Dummy0/85不读75_不搬家_禁止roll15_不勾已搬进mastery",
        order = 246,
        hint = "168534 Dummy 0/85/75。现行读 0/85，不读 75。无 roll_chance_f(15)。家在 spell_shaman.cpp。禁止再改 spell_shaman.cpp。分类旧句 15 不得当 Dummy。15/25/1.875 不得进 Dummy。",
        startText = "【过载不搬家】120 元素打 131989。过载第二发 45284/77451/120588/45297，伤约 Dummy 85%。几率走 EFFECT_0 不是 15。Dummy 75 残留不读。闪电链不要 51505。不要勾过载已搬进 mastery。",
        startPrint = "请元素萨满打出过载。不要搬家。不要 roll 15。",
        ids = { 168534, 188196, 45284, 188443, 45297, 51505, 77451, 280609 },
        labels = {
            [168534] = "过载Dummy0/85/75(不搬家不读75)",
            [188196] = "闪电箭",
            [45284] = "LB过载",
            [188443] = "闪电链",
            [45297] = "CL过载(不是51505)",
            [51505] = "熔岩爆裂(CL过载不应打出)",
            [77451] = "LvB过载",
            [280609] = "过载Rank2 Dummy0",
        },
        chain = {
            { id = 188196, role = "闪电箭", want = "cast",
              hintFail = "没有 188196。120 元素打桩。过载几率不是 15。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "不搬家。不要勾过载已搬进 mastery。禁止 roll 15。Dummy 75 不读。15/25/1.875 不得进 Dummy。本包勾 MAS 过载验收。",
            }
        end,
    },

    mas_monk_brew_elusive_breath = {
        key = "mas_monk_brew_elusive_breath",
        title = "MAS酒仙-无Dummy_CheckProc含115181_家在monk不搬家",
        order = 247,
        hint = "117906 无 Dummy。Trigger 195630。CheckProc：挨打或 205523 或 115181。家在 spell_monk.cpp。不搬家。禁止 spell_mastery_elusive。",
        startText = "【酒仙115181】120 酒仙打 131992。喷火 115181 每目标叠 195630。幻灭 205523 与挨打也叠。无 Dummy。不要搬进 mastery。",
        startPrint = "请酒仙对坦克桩喷火叠躲闪层。必须含 115181。",
        ids = { 117906, 195630, 115181, 205523 },
        labels = {
            [117906] = "酒仙精通(无Dummy)",
            [195630] = "醉拳层Trigger",
            [115181] = "火焰之息(本波CheckProc必含)",
            [205523] = "幻灭打击",
        },
        chain = {
            { id = 115181, role = "火焰之息", want = "cast",
              hintFail = "没有 115181。120 酒仙对 131992 喷火。CheckProc 必须含 115181。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "无 Dummy。CheckProc 含 115181。不搬家。不要 spell_mastery_elusive。本包勾 MAS 酒仙。",
            }
        end,
    },

    mas_dk_blood_shield_death_strike = {
        key = "mas_dk_blood_shield_death_strike",
        title = "MAS鲜血护盾-Dummy0_家在死亡打击_不空INSERT77513",
        order = 248,
        hint = "77513 Dummy 0。Coef 2 不是 Dummy。家在 spell_dk_death_strike_heal HandleHeal2。3307 绑 77535。不要 INSERT 77513 空壳。不搬家。",
        startText = "【鲜血护盾】120 鲜血对 131992 死亡打击。出 77535 吸收。不要给 77513 空 INSERT。Dummy 0。不搬家。",
        startPrint = "请鲜血 DK 死亡打击看护盾。不要 77513 空脚本。",
        ids = { 77513, 77535, 49998 },
        labels = {
            [77513] = "鲜血精通Dummy0(不INSERT)",
            [77535] = "鲜血护盾吸收",
            [49998] = "死亡打击",
        },
        chain = {
            { id = 49998, role = "死亡打击", want = "cast",
              hintFail = "没有 49998。120 鲜血打死亡打击。护盾是 77535。禁止 want=aura。" },
            { id = 77535, role = "鲜血护盾", want = "aura-self",
              hintFail = "没有 77535。家在 HandleHeal2。不要 INSERT 77513。" },
        },
        extraVerdict = function()
            return {
                "Dummy 0 保持。不要 INSERT 77513。不搬家。本包勾 MAS 鲜血护盾。",
            }
        end,
    },

    mas_war_unshackled_aura108 = {
        key = "mas_war_unshackled_aura108",
        title = "MAS狂怒解放-无Dummy_挂钩Aura108不是79_怒气门闩保留_不搬家",
        order = 249,
        hint = "76856 无 Dummy。Register 改 SPELL_AURA_ADD_PCT_MODIFIER。未激怒 amount=0 保留。不搬家。",
        startText = "【狂怒Aura108】120 狂怒激怒后打 131989 伤害涨；没激怒不涨。挂钩 Aura 108 不是 79。不要搬进 mastery。",
        startPrint = "请狂怒战士激怒打桩。挂钩必须是 Aura 108。",
        ids = { 76856, 23881, 184362 },
        labels = {
            [76856] = "狂怒精通(无Dummy,Aura108)",
            [23881] = "嗜血",
            [184362] = "激怒",
        },
        chain = {
            { id = 23881, role = "嗜血", want = "damage",
              hintFail = "没有 23881 伤害。激怒后门闩应打开。挂钩 Aura 108 不是 79。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "无 Dummy。挂钩 Aura 108 不是 79。怒气门闩保留。不搬家。本包勾 MAS 狂怒精通。",
            }
        end,
    },

    mas_rog_main_gauche_30obs = {
        key = "mas_rog_main_gauche_30obs",
        title = "MAS左右开弓-Dummy0_触发30观察窗口非DBC_类在rogue_禁止mastery新类",
        order = 250,
        hint = "76806 Dummy 0。Coef 1.3 不是 Dummy。30% 公开句非 DBC，不得进 Dummy 0。spell_rog_main_gauche 打 86392。禁止 spell_mastery_main_gauche。",
        startText = "【左右开弓Dummy0】120 狂徒主手打 131989。有时出 86392（约 30% 观察窗口）。30 不得进 Dummy 0。类在 spell_rogue.cpp。不要 1.3 当 Dummy。",
        startPrint = "请狂徒打桩看出手 86392。30% 不是 Dummy。",
        ids = { 76806, 86392, 193315 },
        labels = {
            [76806] = "左右开弓Dummy0(30不是Dummy)",
            [86392] = "左右开弓伤害",
            [193315] = "影袭",
        },
        chain = {
            { id = 193315, role = "影袭", want = "cast",
              hintFail = "没有 193315。120 狂徒打桩。76806 Dummy 0。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "Dummy 0 保持。30 不得进 Dummy 0。1.3 不是 Dummy。类在 rogue 文件。禁止 spell_mastery_main_gauche。本包勾 MAS 左右开弓。",
            }
        end,
    },

    mas_pri_echo_dummy125 = {
        key = "mas_pri_echo_dummy125",
        title = "MAS回响-Dummy0/125是比率不是6秒_77489周期3000_家在牧师文件",
        order = 251,
        hint = "77485 Dummy 0/125。echoPct=Mastery*Dummy125/100。77489 周期 3000 ms。125 不得改写成 6 秒。6 秒是持续观察窗口。家在 spell_priest.cpp。",
        startText = "【回响Dummy125】120 神圣牧师治疗 131994。出 77489，约每 3 秒一跳。Dummy 125 是比率不是 6 秒。不要搬进 mastery。",
        startPrint = "请神圣牧师治疗假人看 77489。125 不是 6 秒。",
        ids = { 77485, 77489, 2060 },
        labels = {
            [77485] = "回响Dummy0/125(125不是6秒)",
            [77489] = "回响治疗周期3000",
            [2060] = "治疗术",
        },
        chain = {
            { id = 2060, role = "治疗术", want = "cast",
              hintFail = "没有 2060。120 神圣牧师治疗 131994。禁止 want=aura。" },
            { id = 77489, role = "回响HoT", want = "aura-target",
              hintFail = "没有 77489。Dummy 125 是比率。周期 3000 ms。125 不是 6 秒。" },
        },
        extraVerdict = function()
            return {
                "Dummy 125 是比率不是 6 秒。周期 3000 ms。家在牧师文件。禁止 spell_mastery_echo。本包勾 MAS 回响。",
            }
        end,
    },

    mas_pri_grace_coef135_no_plus12 = {
        key = "mas_pri_grace_coef135_no_plus12",
        title = "MAS恩典-Dummy0_Coef1.35不是Dummy_禁止再乘12%_家在牧师赎罪",
        order = 252,
        hint = "271534 Dummy 0。Coef 1.35 不是 Dummy。8.3 +12% 已进系数。AddPct 81751 GetAmount()。禁止 *1.12。家在 spell_pri_atonement::HandleProc。",
        startText = "【恩典Dummy0】120 戒律先上赎罪再打伤害，目标吃 81751。数字吃 271534 GetAmount()。不要再乘 12%。不要写死 1.35。不要搬进 mastery。",
        startPrint = "请戒律牧师看赎罪治疗吃精通。不要再乘 12%。",
        ids = { 271534, 81751, 194384, 589 },
        labels = {
            [271534] = "恩典Dummy0(1.35不是Dummy)",
            [81751] = "赎罪治疗",
            [194384] = "赎罪光环",
            [589] = "暗言术痛",
        },
        chain = {
            { id = 589, role = "暗言术痛", want = "cast",
              hintFail = "没有 589。120 戒律先上赎罪再打伤害。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "Dummy 0 保持。禁止再乘 +12%。1.35 不是 Dummy。家在牧师文件。禁止 spell_mastery_grace。本包勾 MAS 恩典。",
            }
        end,
    },

    mas_monk_gust_191894 = {
        key = "mas_monk_gust_191894",
        title = "MAS迷雾-Dummy0/0_治疗191894_Coef3不是Dummy_家在武僧文件",
        order = 253,
        hint = "117907 Dummy 0/0。Coef 3 不是 Dummy。键 115151/124682/116670/107428/191837。191840 是 HoT 条件，不是触发键：仅 191837 且目标已有 191840 才第二次 Cast 191894。不要 Effuse。spell_monk_gust_of_mists。禁止 spell_mastery_gust。",
        startText = "【迷雾191894】120 织雾对 131994 活血 116670 / 复苏 115151 出 191894。精华之泉 191837 仅当目标已有 191840 HoT 才两次。191840 是 HoT 条件，不是触发键。Dummy 0/0。3 不是 Dummy。不要 Effuse。不要搬进 mastery。",
        startPrint = "请织雾治疗假人看出 191894。不要 Effuse。",
        ids = { 117907, 191894, 116670, 115151, 124682, 107428, 191837, 191840 },
        labels = {
            [117907] = "迷雾Dummy0/0(3不是Dummy)",
            [191894] = "迷雾治疗",
            [116670] = "活血术",
            [115151] = "复苏之雾",
            [124682] = "氤氲之雾",
            [107428] = "旭日东升踢",
            [191837] = "精华之泉",
            [191840] = "HoT条件不是触发键",
        },
        chain = {
            { id = 116670, role = "活血术", want = "cast",
              hintFail = "没有 116670。120 织雾治疗 131994。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "Dummy 0/0 保持。3 不是 Dummy。不要 Effuse。家在武僧文件。禁止 spell_mastery_gust。本包勾 MAS 迷雾。",
            }
        end,
    },

    mas_pal_lightbringer_falloff = {
        key = "mas_pal_lightbringer_falloff",
        title = "MAS光明使者-Dummy0_10码满40码零观察窗口_PlayerScript在圣骑士文件",
        order = 254,
        hint = "183997 Dummy 0。Coef 1.5 不是 Dummy。Aura 4 无 Handler。10yd=100% 40yd=0% 线性，非 DBC。类名 paladin_lightbringer_mastery，禁止 spell_mastery_*。不 INSERT spell_script_names。",
        startText = "【光明使者距离】120 神圣骑治疗 131994。贴脸数字高于 40 码外。Dummy 0。10/40 不得进 Dummy。家在 spell_paladin.cpp。不要搬进 mastery。",
        startPrint = "请神圣骑贴脸再拉远治疗假人。10/40 是观察窗口。",
        ids = { 183997, 19750, 82326 },
        labels = {
            [183997] = "光明使者Dummy0(10/40不是Dummy)",
            [19750] = "圣光闪现",
            [82326] = "圣光术",
        },
        chain = {
            { id = 19750, role = "圣光闪现", want = "cast",
              hintFail = "没有 19750。120 神圣骑治疗 131994。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "Dummy 0 保持。10/40 不得进 Dummy 0。1.5 不是 Dummy。禁止 spell_mastery_lightbringer。不搬家。本包勾 MAS 光明使者。",
            }
        end,
    },

    mas_dru_harmony_table_only = {
        key = "mas_dru_harmony_table_only",
        title = "MAS和谐-Dummy0_Coef0.55走表_不包空脚本_不要勾脚本已接线",
        order = 255,
        hint = "77495 Dummy 0。Coef 0.55 不是 Dummy。8.3 -9% 已进系数。不写脚本。不 INSERT。不搬家。本包只勾绿字走表，不要勾和谐脚本已接线。77484 无行。",
        startText = "【和谐走表】120 恢复德身上 77495。治疗 131994 看绿字。不要勾「和谐脚本已接线」。不要再乘 -9%。不要搬进 mastery。不要 77484。",
        startPrint = "请恢复德治疗假人看精通绿字。不要勾脚本接线。",
        ids = { 77495, 77484, 5185 },
        labels = {
            [77495] = "和谐Dummy0(0.55不是Dummy,不包空)",
            [77484] = "SpellName无行",
            [5185] = "治疗之触",
        },
        chain = {
            { id = 5185, role = "治疗之触", want = "cast",
              hintFail = "没有 5185。120 恢复德治疗 131994。77495 走表。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "Dummy 0 保持。0.55 不是 Dummy。不要勾和谐脚本已接线。禁止再乘 -9%。不包空进 mastery。本包只勾和谐绿字走表。不要勾 203747。",
            }
        end,
    },

    rac_nightborne_arcane_pulse_obs = {
        key = "rac_nightborne_arcane_pulse_obs",
        title = "RAC奥术脉冲-自动判定只证明出手_0.5/0.25观察窗口只认人测",
        order = 256,
        hint = "260364 本表无 Dummy。删 Haven 2.0/0.75。0.5 AP / 0.25 SP 非 DBC 观察窗口，不得进 Dummy。260369 DurationIndex 29=12秒。50 不是 Dummy。6秒是 256948/291944。分类不读 Dummy 不等于表上有 Dummy 没读。自动判定只证明出手，不要把绿勾当已读 Dummy。",
        startText = "【奥术脉冲无Dummy】120 夜之子对 131989 放 260364。CLEU 有伤。目标 260369 约 12 秒不是 6 秒。自动判定只证明技能出手。0.5/0.25 观察窗口只认人测（读脚本注释），不要靠 pack 绿勾。不要勾读了 Dummy。2.0/0.75/0.5/0.25 不得进 Dummy。",
        startPrint = "请夜之子打桩放奥术脉冲。无 Dummy。减速 12 秒。",
        ids = { 260364, 260369, 256948, 291944 },
        labels = {
            [260364] = "奥术脉冲无Dummy",
            [260369] = "减速Aura33_BP50不是Dummy_12秒",
            [256948] = "裂隙6秒不要和260369互填",
            [291944] = "再生6秒不要和260369互填",
        },
        chain = {
            { id = 260364, role = "奥术脉冲", want = "damage",
              hintFail = "没有 260364 伤害。120 夜之子对 131989 放。本表无 Dummy。自动判定只证明出手。0.5/0.25 观察窗口只认人测，不要靠 pack 绿勾。禁止 want=aura。" },
            { id = 260369, role = "减速12秒", want = "aura-target",
              hintFail = "没有 260369。持续应约 12 秒。禁止以表为准 6 秒。自动判定只证明出手。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "自动判定只证明技能出手。0.5/0.25 观察窗口只认人测（读脚本注释），不要靠 pack 绿勾。不要把绿勾当已读 Dummy。260364 无 Dummy。0.5/0.25 不得进 Dummy。260369 是 12 秒不是 6 秒。本包勾 RAC 奥术脉冲出手。不要勾词缀。",
            }
        end,
    },

    rac_lightforged_lights_judgment_obs = {
        key = "rac_lightforged_lights_judgment_obs",
        title = "RAC圣光裁决-无Dummy_观察窗口max(AP,SP)*3_删6.25",
        order = 257,
        hint = "256893 本表无 Dummy。学会号 255647。删 6.25f*AttackPower。3.0*max(AP,SP) 非 DBC。Rad1=8=5码走表。6.25/3 不得进 Dummy。",
        startText = "【圣光裁决无Dummy】120 光铸对 131989 放 255647。CLEU 有 256893。不要勾读了 Dummy。不要勾 6.25 Dummy。5 码走表。",
        startPrint = "请光铸打桩放圣光裁决。无 Dummy。",
        ids = { 255647, 256893, 255652, 256896 },
        labels = {
            [255647] = "圣光裁决学会号无Dummy",
            [256893] = "圣光裁决伤号无Dummy",
            [255652] = "圣光清算PlayerScript不走ssn",
            [256896] = "清算爆发Coef不是Dummy",
        },
        chain = {
            { id = 255647, role = "圣光裁决学会", want = "cast",
              hintFail = "没有 255647。120 光铸对 131989 放。脚本绑的是 256893。禁止 want=aura。" },
            { id = 256893, role = "圣光裁决伤", want = "damage",
              hintFail = "没有 256893 伤害。6.25 已删。3 不得进 Dummy。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "256893 无 Dummy。6.25/3 不得进 Dummy。本包勾 RAC 圣光裁决。不要勾清算已搬家。",
            }
        end,
    },

    rac_draenei_gift_of_naaru_dummy20 = {
        key = "rac_draenei_gift_of_naaru_dummy20",
        title = "RAC纳鲁之赐-自动判定只证明出手_Dummy20只认人测",
        order = 258,
        hint = "28880 族 Dummy 20。周期 Aura 8 BP=0。删 1.885/1.1。1.885 不得进 Dummy 20。121093 必须 INSERT。自动判定只证明出手，不要把绿勾当已读 Dummy 20。",
        startText = "【纳鲁Dummy20】120 德莱尼对 131994 或自己放 28880。治疗总量约 20% 生命。自动判定只证明技能出手。Dummy 20 只认人测（治疗假人数字 / 读脚本注释），不要靠 pack 绿勾。不要 1.885 SP。武僧德莱尼测 121093。",
        startPrint = "请德莱尼放纳鲁之赐。读 Dummy 20。",
        ids = { 28880, 59542, 59544, 121093, 20578 },
        labels = {
            [28880] = "纳鲁Dummy20",
            [59542] = "纳鲁圣骑号Dummy20",
            [59544] = "纳鲁牧师号Dummy20",
            [121093] = "纳鲁武僧号必须绑",
            [20578] = "食尸BP7不是Dummy",
        },
        chain = {
            { id = 28880, role = "纳鲁之赐", want = "aura-self",
              hintFail = "没有 28880。120 德莱尼放纳鲁。自动判定只证明出手。Dummy 20 只认人测（治疗假人数字），不要靠 pack 绿勾。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "自动判定只证明技能出手。Dummy 20 只认人测（治疗假人数字 / 读脚本注释），不要靠 pack 绿勾。不要把绿勾当已读 Dummy。1.885/1.1 不得进 Dummy 20。121093 必须绑。本包勾 RAC 纳鲁出手。",
            }
        end,
    },

    rac_mechagnomo_emergency_bp20_15 = {
        key = "rac_mechagnomo_emergency_bp20_15",
        title = "RAC应急保险-自动判定只证明出手_20/15只认人测_无Dummy",
        order = 259,
        hint = "312916 无 Dummy。Aura 42 BP 20。313010 BP 15 不是 Dummy。313015 Dummy 0 / 150秒。删 25/25。25 不得进 Dummy。自动判定只证明出手，不要把绿勾当已改 20/15。",
        startText = "【应急20/15】120 机械侏儒在 131992 上把血打到 20% 以下。出 313010，随后 313015。治疗约 15% 生命。自动判定只证明技能出手。20/15 只认人测（治疗假人数字 / 读脚本注释），不要靠 pack 绿勾。不要勾 25。",
        startPrint = "请机械侏儒在会还手的桩上测应急。阈值 20 治疗 15。",
        ids = { 312916, 313010, 313015 },
        labels = {
            [312916] = "应急无Dummy_BP20",
            [313010] = "应急治疗BP15不是Dummy",
            [313015] = "应急ICD_Dummy0_150秒",
        },
        chain = {
            { id = 313010, role = "应急治疗", want = "cast",
              hintFail = "没有 313010。把血打到 20% 以下。自动判定只证明出手。20/15 只认人测，不要靠 pack 绿勾。阈值读 GetAmount()=20。禁止 25。禁止 want=aura。" },
            { id = 313015, role = "应急ICD", want = "aura-self",
              hintFail = "没有 313015。DurationIndex 562=150秒走表。自动判定只证明出手。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "自动判定只证明技能出手。20/15 只认人测（治疗假人数字 / 读脚本注释），不要靠 pack 绿勾。不要把绿勾当已改公式。25 不得进 Dummy。本包勾 RAC 应急出手。不要勾词缀。",
            }
        end,
    },

    rac_dark_iron_fireblood_dummy0 = {
        key = "rac_dark_iron_fireblood_dummy0",
        title = "RAC火焰之血-Dummy0钩子_Coef1和0.5不是Dummy基点",
        order = 260,
        hint = "265221 Dummy BP=0 idx5/6。Coefficient 1/0.5 不是 Dummy 基点。265226 Coef 0.643 不是 Dummy。驱散走表。金额 CalcValue*3 观察窗口。3 不得进 Dummy 0。",
        startText = "【火焰之血Dummy0】120 黑铁放 265221。驱散走表。身上 265226。不要勾 Dummy Coef 1/0.5。不要把 0.643 写成 Dummy。",
        startPrint = "请黑铁放火焰之血。Dummy 0 是钩子。",
        ids = { 265221, 265226 },
        labels = {
            [265221] = "火焰之血Dummy0钩子",
            [265226] = "火焰之血主属性_0.643不是Dummy",
        },
        chain = {
            { id = 265221, role = "火焰之血", want = "cast",
              hintFail = "没有 265221。120 黑铁放。Dummy 0 钩子。禁止 want=aura。" },
            { id = 265226, role = "主属性光环", want = "aura-self",
              hintFail = "没有 265226。金额是 CalcValue*3 观察窗口。1/0.5 不是 Dummy 基点。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "Dummy 0 保持。1/0.5/0.643 不是 Dummy。本包勾 RAC 火焰之血。",
            }
        end,
    },

    rac_kultiran_haymaker_obs075 = {
        key = "rac_kultiran_haymaker_obs075",
        title = "RAC重击-Dummy0_观察窗口max(AP,SP)*0.75_昏迷走表",
        order = 261,
        hint = "287712 Dummy 0。伤 Coef/AP 0。0.75 非 DBC。昏迷 Aura 12 / 击退 BP 60 不是 Dummy。0.75 不得进 Dummy 0。",
        startText = "【重击Dummy0】120 库尔提拉斯对 131989 放 287712。CLEU 有伤。昏迷/击退走表。不要把 0.75 写成 Dummy。",
        startPrint = "请库尔提拉斯打桩放重击。Dummy 0。",
        ids = { 287712 },
        labels = {
            [287712] = "重击Dummy0",
        },
        chain = {
            { id = 287712, role = "重击", want = "damage",
              hintFail = "没有 287712 伤害。0.75 观察窗口不得进 Dummy 0。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "Dummy 0 保持。0.75 不是 Dummy。本包勾 RAC 重击。",
            }
        end,
    },

    rac_vulpera_bag_of_tricks_dummy1000 = {
        key = "rac_vulpera_bag_of_tricks_dummy1000",
        title = "RAC把戏袋-Dummy1000钩子_1.8伤2.7疗观察窗口_翻袋不验收",
        order = 262,
        hint = "312411 Dummy 1000。1.8/2.7 非 DBC 不得改 Dummy 1000。312425 翻袋登记不验收。",
        startText = "【把戏袋Dummy1000】120 狐人对 131989 放 312411 出伤；对 131994 出疗。不要翻袋。不要把 Dummy 1000 改成 1.8。",
        startPrint = "请狐人把戏袋打桩。Dummy 1000 是钩子。",
        ids = { 312411, 312425 },
        labels = {
            [312411] = "把戏袋Dummy1000",
            [312425] = "翻袋不验收",
        },
        chain = {
            { id = 312411, role = "把戏袋", want = "damage",
              hintFail = "没有 312411 伤害。Dummy 1000 是钩子。1.8 不得进 Dummy。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "Dummy 1000 保持。1.8/2.7 不是 Dummy。312425 不要勾完成。本包勾 RAC 把戏袋伤侧。",
            }
        end,
    },

    rac_mechagnomo_combat_analysis = {
        key = "rac_mechagnomo_combat_analysis",
        title = "RAC战斗分析-绿勾只证被动光环在_层数Dummy10与主属性只认人测",
        order = 263,
        hint = "312923 Periodic Dummy 5 是周期 tooltip。Dummy 25 是缩放 tooltip，不得进常数。Dummy 10 是层数。金额只读 EFFECT_0 GetAmount()/CalcValue（Coef 0.080）。50/8 不得覆盖。Variables 键 rac_combat_analysis_stacks。绿勾只证明被动光环在，不要假装已叠 10 层。",
        startText = "【战斗分析】120 机械侏儒被动 312923。绿勾只证明被动光环在。层数 Dummy 10 / 主属性只认人测，不要靠 pack 绿勾。进战约每 5 秒主属性涨，最多 10 层。不要把 Dummy 5 当属性。Dummy 25 不得进常数。不要勾 50/8。",
        startPrint = "请机械侏儒进战看战斗分析叠层。Dummy 10 是上限。",
        ids = { 312923 },
        labels = {
            [312923] = "战斗分析Dummy5/25/10",
        },
        chain = {
            { id = 312923, role = "战斗分析被动", want = "aura-self",
              hintFail = "没有 312923。机械侏儒被动。绿勾只证明被动光环在。层数 Dummy 10 / 主属性只认人测，不要靠 pack 绿勾。金额不是 Dummy 5。Dummy 25 不得进常数。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "绿勾只证明被动光环在。层数 Dummy 10 / 主属性只认人测，不要靠 pack 绿勾。不要假装绿勾=已叠 10 层。Dummy 5 不当属性。Dummy 25 不得进常数。50/8 不得覆盖。本包勾 RAC 战斗分析被动在。",
            }
        end,
    },

    rac_gnome_escape_artist = {
        key = "rac_gnome_escape_artist",
        title = "RAC逃脱大师-自动判定只证明出手_减速被清只认人测",
        order = 264,
        hint = "20589 无 Dummy。Eff=77 服务器脚本。RemoveMovementImpairingAuras(true)。不要从 434/548 覆盖。自动判定只证明出手，不要把绿勾当减速已清。",
        startText = "【逃脱大师】120 侏儒先吃一个减速，再放 20589。自动判定只证明技能出手。减速被清只认人测（动作条减速消失），不要靠 pack 绿勾。无 Dummy。",
        startPrint = "请侏儒先减速再逃脱大师。",
        ids = { 20589 },
        labels = {
            [20589] = "逃脱大师无Dummy",
        },
        chain = {
            { id = 20589, role = "逃脱大师", want = "cast",
              hintFail = "没有 20589。120 侏儒放。自动判定只证明出手。减速被清只认人测（动作条减速消失），不要靠 pack 绿勾。无 Dummy。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "自动判定只证明技能出手。减速被清只认人测（动作条减速消失 / 读脚本注释），不要靠 pack 绿勾。不要把绿勾当已清减速。无 Dummy。不要从 434/548 覆盖。本包勾 RAC 逃脱大师出手。",
            }
        end,
    },

    rac_nightelf_shadowmeld_dummy0 = {
        key = "rac_nightelf_shadowmeld_dummy0",
        title = "RAC影遁-Dummy0脱战钩子_隐身仇恨走表_人测隐身后脱离战斗",
        order = 274,
        hint = "58984 Dummy 0 idx1 只做 CombatStop 脱战钩子。Aura 16 隐身 / Aura 103 仇恨走表。不要 PreventDefault。不要从 12x 整类粘贴。人测隐身后脱离战斗。",
        startText = "【影遁Dummy0】120 暗夜精灵进战（会还手的桩 131992）再放 58984。隐身走表。人测隐身后脱离战斗。自动判定只证明出手/光环在。不要 PreventDefault 隐身/仇恨。不要从 12x 整类粘贴。",
        startPrint = "请暗夜精灵进战放影遁。Dummy 0 脱战钩子。人测脱离战斗。",
        ids = { 58984 },
        labels = {
            [58984] = "影遁Dummy0脱战钩子",
        },
        chain = {
            { id = 58984, role = "影遁", want = "cast",
              hintFail = "没有 58984。120 暗夜精灵放。Dummy 0 脱战钩子。自动判定只证明出手。隐身后脱离战斗只认人测。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "Dummy 0 只做脱战钩子。隐身/仇恨走表。人测隐身后脱离战斗。不要 PreventDefault。不要从 12x 整类粘贴。本包勾 RAC 影遁出手。",
            }
        end,
    },

    rac_voidelf_spatial_rift_dummy0 = {
        key = "rac_voidelf_spatial_rift_dummy0",
        title = "RAC空间裂隙-Dummy0传送钩子_不要编伤_6秒是裂隙不是260369",
        order = 265,
        hint = "257040 Dummy 0。256948 无 Dummy DurationIndex 32=6秒。257034 传送。不要给 Dummy 0 编 AP 伤。",
        startText = "【裂隙Dummy0】120 虚空精灵放 256948 再按 257040 传送。不要勾裂隙有伤。6 秒是裂隙不是奥术脉冲减速。",
        startPrint = "请虚空精灵放空间裂隙再传送。Dummy 0。",
        ids = { 256948, 257040, 257034, 260369 },
        labels = {
            [256948] = "裂隙学会无Dummy_6秒",
            [257040] = "裂隙再激活Dummy0",
            [257034] = "裂隙传送无Dummy",
            [260369] = "奥术脉冲减速12秒不要互填",
        },
        chain = {
            { id = 256948, role = "放裂隙", want = "cast",
              hintFail = "没有 256948。120 虚空精灵先放裂隙。禁止 want=aura。" },
            { id = 257040, role = "再激活传送", want = "cast",
              hintFail = "没有 257040。Dummy 0 是传送钩子。不要编伤。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "Dummy 0 保持传送。不要勾裂隙有伤。6 秒不要写进 260369。本包勾 RAC 裂隙。",
            }
        end,
    },

    rac_maghar_ancestral_call_dummy0 = {
        key = "rac_maghar_ancestral_call_dummy0",
        title = "RAC先祖召唤-Dummy0抽签_1.32走子号不是Dummy基点",
        order = 266,
        hint = "274738 Dummy 0 Coef 1.32 不是 Dummy 基点。urand 四选一。子号 274739-274742 Aura 189 无 Dummy。",
        startText = "【先祖Dummy0】120 玛格汉放 274738。身上出现 274739-274742 之一约 15 秒。不要勾 Dummy 改成 1.32。",
        startPrint = "请玛格汉放先祖召唤。Dummy 0 抽签。",
        ids = { 274738, 274739, 274740, 274741, 274742 },
        labels = {
            [274738] = "先祖Dummy0抽签",
            [274739] = "笑颅暴击_1.32不是Dummy",
            [274740] = "燃刃加速",
            [274741] = "霜狼精通",
            [274742] = "黑石全能",
        },
        chain = {
            { id = 274738, role = "先祖召唤", want = "cast",
              hintFail = "没有 274738。120 玛格汉放。Dummy 0 抽签。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "Dummy 0 保持。1.32 不是 Dummy 基点。本包勾 RAC 先祖召唤。不要勾已搬进 mastery。",
            }
        end,
    },

    rac_lightforged_lights_reckoning = {
        key = "rac_lightforged_lights_reckoning",
        title = "RAC圣光清算-PlayerScript读Trigger_Coef352.53不是Dummy",
        order = 267,
        hint = "255652 Dummy 0 Trigger 256896。PlayerScript 不走 ssn。禁止 INSERT 255652。",
        startText = "【清算PlayerScript】120 光铸在 131989 旁死亡，出 256896。不要给 255652 INSERT。352.53 不是 Dummy。",
        startPrint = "请光铸死亡测圣光清算。PlayerScript。",
        ids = { 255652, 256896 },
        labels = {
            [255652] = "清算Dummy0_PlayerScript",
            [256896] = "清算爆发Coef不是Dummy",
        },
        chain = {
            { id = 256896, role = "清算爆发", want = "damage",
              hintFail = "没有 256896。光铸死亡才放。PlayerScript 不走 ssn。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "不要 INSERT 255652。Coef 不是 Dummy。本包勾 RAC 清算。",
            }
        end,
    },

    rac_undead_cannibalize_dummy0 = {
        key = "rac_undead_cannibalize_dummy0",
        title = "RAC食尸-Dummy0钩子放20578_BP7不是Dummy",
        order = 268,
        hint = "20577 Dummy 0。20578 Aura 20/21 BP 7 不是 Dummy。形状已对，禁止再改 cpp。",
        startText = "【食尸Dummy0】120 亡灵附近有尸体时放 20577，上 20578。7 不是 Dummy。",
        startPrint = "请亡灵食尸。Dummy 0 钩子。",
        ids = { 20577, 20578 },
        labels = {
            [20577] = "食尸Dummy0",
            [20578] = "食尸触发BP7不是Dummy",
        },
        chain = {
            { id = 20577, role = "食尸", want = "cast",
              hintFail = "没有 20577。附近要有尸体。禁止 want=aura。" },
            { id = 20578, role = "食尸回复", want = "aura-self",
              hintFail = "没有 20578。BP 7 不是 Dummy。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "Dummy 0 保持。7 不是 Dummy。禁止再改 cannibalize。本包勾 RAC 食尸。",
            }
        end,
    },

    rac_troll_berserking_table_only = {
        key = "rac_troll_berserking_table_only",
        title = "RAC狂暴-无Dummy走表不包空_Aura193_BP10_12秒",
        order = 269,
        hint = "26297 无 Dummy。Aura 193 BP 10。DurationIndex 29=12秒。Rec=180000。禁止 INSERT。10 不得进 Dummy。wiki 15%/10秒弃用。",
        startText = "【狂暴走表】120 巨魔放 26297。加速约 10% / 12 秒。不要勾已写狂暴脚本。不要 15%/10秒。",
        startPrint = "请巨魔放狂暴。走表不包空。",
        ids = { 26297, 106951 },
        labels = {
            [26297] = "种族狂暴无Dummy走表",
            [106951] = "德鲁伊狂暴不是种族_不要当本条",
        },
        chain = {
            { id = 26297, role = "狂暴", want = "aura-self",
              hintFail = "没有 26297。120 巨魔放。走表不包空。禁止 INSERT。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "无 Dummy。不要勾已写狂暴脚本。106951 不是种族。本包只勾走表。",
            }
        end,
    },

    rac_orc_blood_fury_table_only = {
        key = "rac_orc_blood_fury_table_only",
        title = "RAC血性狂怒-无Dummy走表_三号按职业学会不要合成",
        order = 270,
        hint = "20572/33697/33702 无 Dummy。Coef 1.286 不是 Dummy。禁止 INSERT。不要合成一个号。自动判定只盯 20572；本职业是 33697/33702 时不要当 RAC 失败，也不要 INSERT / 合成一个号。",
        startText = "【血性狂怒走表】120 兽人按职业放 20572 或 33697 或 33702。约 15 秒。自动判定只盯 20572。本职业是 33697/33702 时不要当 RAC 失败，也不要 INSERT / 合成一个号。不要勾已写脚本。",
        startPrint = "请兽人放血性狂怒。走表。三号不要合成。自动判定只盯 20572。",
        ids = { 20572, 33697, 33702 },
        labels = {
            [20572] = "血性狂怒AP_无Dummy",
            [33697] = "血性狂怒双_无Dummy",
            [33702] = "血性狂怒SP_无Dummy",
        },
        chain = {
            { id = 20572, role = "血性狂怒", want = "aura-self",
              hintFail = "自动判定只盯 20572。本职业是 33697/33702 时不要当 RAC 失败，也不要 INSERT / 合成一个号。走表不包空。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "自动判定只盯 20572。本职业是 33697/33702 时不要当 RAC 失败，也不要 INSERT / 合成一个号。无 Dummy。1.286 不是 Dummy。本包只勾走表。",
            }
        end,
    },

    rac_zandalari_regeneratin_table_only = {
        key = "rac_zandalari_regeneratin_table_only",
        title = "RAC再生-Dummy100是tooltip_Aura20_BP16.5走表_6秒不是260369",
        order = 271,
        hint = "291944 Dummy 100 tooltip。Aura 20 BP 16.5 不是 Dummy。DurationIndex 32=6秒。禁止 INSERT。不要和 260369 12秒互填。",
        startText = "【再生走表】120 赞达拉放 291944。约 6 秒回复。不要写脚本。6 秒是再生/裂隙，不是奥术脉冲减速。",
        startPrint = "请赞达拉放再生。走表。Dummy 100 是 tooltip。",
        ids = { 291944, 260369, 256948 },
        labels = {
            [291944] = "再生Dummy100tooltip_6秒",
            [260369] = "奥术脉冲减速12秒不要互填",
            [256948] = "裂隙也是6秒不要互填进260369",
        },
        chain = {
            { id = 291944, role = "再生", want = "aura-self",
              hintFail = "没有 291944。120 赞达拉放。走表不 INSERT。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "Dummy 100 是 tooltip。16.5 不是 Dummy。不要勾已写再生脚本。本包只勾走表。",
            }
        end,
    },

    rac_register_not_accept_lang_prof_mount_hs = {
        key = "rac_register_not_accept_lang_prof_mount_hs",
        title = "RAC语言专业坐骑炉石营地-登记家不验收",
        order = 272,
        hint = "Languages/专业加速/坐骑/炉石/营地/钻探机/翼手龙降落登记家、不验收。spell_make_camp/spell_back_camp 不改。不要勾本包完成当 RAC 收口。空 chain。禁止 want=cast 盯 312370。",
        startText = "【登记不验收】不要测语言、珠宝加工、工程专精、坐骑、炉石、312370/312372 营地、265225 钻探机、281954 翼手龙。本包不要勾完成。",
        startPrint = "本包只登记不验收。不要勾完成。",
        ids = { 312370, 312372, 265225, 281954, 259930, 20593, 28875 },
        labels = {
            [312370] = "扎营不验收",
            [312372] = "回营不验收",
            [265225] = "钻探机不验收",
            [281954] = "翼手龙降落不验收",
            [259930] = "圣光熔炉不验收",
            [20593] = "工程专精不验收",
            [28875] = "宝石切割不验收",
        },
        chain = {
        },
        extraVerdict = function()
            return {
                "语言/专业/坐骑/炉石/营地登记不验收。不要勾本包完成。不要改 make_camp。不要当 RAC 收口。禁止 want=cast 盯 312370。空 chain：没有 312370 不是 RAC 失败。",
            }
        end,
    },

    rac_affix_not_in_rac = {
        key = "rac_affix_not_in_rac",
        title = "RAC词缀不进本条-挑战者之力火山血池禁止勾完成",
        order = 273,
        hint = "spell_challengers_might / npc_volcanic_plume_105877 / challange_player_instance_handler / at_challenge_sanguine_ichor 是大秘境。家碰巧同文件。禁止改、禁止勾 RAC 已修词缀。空 chain。禁止 want=cast 盯 206150。",
        startText = "【词缀不进RAC】不要测挑战者之力、火山、血池。不要勾本包完成。不要改 AddSC 开头四条。",
        startPrint = "词缀不进 RAC。不要勾完成。",
        ids = { 206150 },
        labels = {
            [206150] = "挑战者之力_词缀不进RAC",
        },
        chain = {
        },
        extraVerdict = function()
            return {
                "词缀不进 RAC。不要勾完成。不要改 spell_challengers_might / 火山 / 血池。禁止 want=cast 盯 206150。空 chain：没有 206150 不是 RAC 失败。本包只登记边界。",
            }
        end,
    },

    rac_voidelf_entropic_embrace_dummy5 = {
        key = "rac_voidelf_entropic_embrace_dummy5",
        title = "RAC熵能拥抱-只勾Dummy5光环能挂_不要勾已写复制伤害",
        order = 275,
        hint = "256374 Dummy Aura 5。255669 Aura 42 Trigger 256374 无 Dummy。本波不写复制伤害脚本。不要改 Dummy 5。8.3 是复制 5% Shadowfrost，11.0.7 才改成提高 5%，零售弃用。",
        startText = "【熵能Dummy5】120 虚空精灵进战挂 256374。只勾 Dummy 5 能挂。不要勾已写复制伤害。不要改 Dummy 5。",
        startPrint = "请虚空精灵进战看熵能拥抱。只勾 Dummy 5 光环能挂。",
        ids = { 255669, 256374 },
        labels = {
            [255669] = "熵能拥抱学会_无Dummy",
            [256374] = "熵能拥抱Dummy5",
        },
        chain = {
            { id = 256374, role = "熵能拥抱Dummy5", want = "aura-self",
              hintFail = "没有 256374。120 虚空精灵进战。只勾 Dummy 5 能挂。不要勾已写复制伤害。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "只勾 Dummy 5 能挂。不要勾已写复制伤害。不要改 Dummy 5。本波不写复制伤害脚本。",
            }
        end,
    },

    az_scripts_wired = {
        key = "az_scripts_wired",
        title = "AZ接线-pack绿勾只证明277253仍在_AddSC与_09INSERT认3307与启动日志",
        order = 276,
        hint = "新建 spell_azerite.cpp + AddSC_azerite_spell_scripts 放在 AddSC_pet_spell_scripts 之后。不要改 spell_item.cpp。不要重写 277253 Dummy 0。人测穿脱物品 158075（277253），确认挂上/卸下。不允许 .aura 代替穿脱。277639 不绑脚本。不要 Learn 299349。191837 不是 AZE。自动判定只证明当时 277253 光环仍在，绿勾不能代替穿脱完成定义。AddSC 与 _09 INSERT 只认 3307 SELECT + 启动日志，不要靠 pack 绿勾。",
        startText = "【AZ接线】确认 loader 在 pet 之后调 AddSC_azerite_spell_scripts。3307 已 INSERT 278495/278497/295373/295376。277253 仍是 spell_item_heart_of_azeroth。人测穿脱物品 158075，确认 277253 挂上/卸下。不允许 .aura 代替穿脱。自动判定只证明当时 277253 光环仍在，绿勾不能代替穿脱完成定义。AddSC 声明调用与 _09 INSERT 只认 3307 SELECT + 启动日志，不要靠 pack 绿勾。不要勾地震波/浓缩火焰完成。不要 Learn 299349。191837 不是 AZE。禁止 want=aura。",
        startPrint = "请穿脱物品 158075 确认 277253 挂上/卸下。接线认 3307 SELECT + 启动日志，不要靠绿勾代替穿脱。不要勾地震波完成。",
        ids = { 277253, 277639, 278495, 278497, 295373, 295376, 299349, 191837 },
        labels = {
            [277253] = "项链Dummy0_不要重写",
            [277639] = "地震波Dummy10_不绑脚本",
            [278495] = "地震波隐藏proc_Dummy0",
            [278497] = "地震波伤_Dummy0",
            [295373] = "浓缩火焰学会_Dummy100",
            [295376] = "浓缩火焰导弹_Dummy100",
            [299349] = "Rank2Actual_禁止Learn",
            [191837] = "织雾精华之泉_不是AZE",
        },
        chain = {
            { id = 277253, role = "项链Dummy0", want = "aura-self",
              hintFail = "没有 277253。穿物品 158075（艾泽拉斯之心）确认挂上。自动判定只证明当时 277253 仍在，绿勾不能代替穿脱完成定义。AddSC 与 _09 INSERT 只认 3307 SELECT + 启动日志，不要靠 pack 绿勾。不要重写 277253。不允许 .aura 代替穿脱。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "人测穿脱物品 158075，确认 277253 挂上/卸下。自动判定只证明当时 277253 光环仍在，绿勾不能代替穿脱完成定义。AddSC_azerite_spell_scripts 声明调用与 _09 INSERT 只认 3307 SELECT + 启动日志，不要靠 pack 绿勾。不要勾地震波/浓缩火焰完成。不要重写 277253。不要 Learn 299349。191837 不是 AZE。9.52/16.71/67/30/740/1000/1500 不得进 Dummy。",
            }
        end,
    },

    az_seismic_wave_dummy10 = {
        key = "az_seismic_wave_dummy10",
        title = "AZ地震波-自动判定只证明277639与278497出手_Dummy10不得改成9.52",
        order = 277,
        hint = "277639 Dummy 10 是线宽。Aura 285 Coef 9.52 不是 Dummy。278497 Dummy 0。Rad1=13=10.0码不是 Dummy。脚本禁止再 Cast 278495。压制 7384。9.52/740 不得进 Dummy。人测完成定义是穿带 AzeritePower 433 的头/胸/肩并选出该特质，再测压制打出 278497；卸装后 277639/278495 应掉。.aura 277639 只作调试辅助，不得当闭环、不得写入通过标准。自动判定只证明 277639/278497 出手，绿勾不能代替穿脱，不要把绿勾当已读 Coef。",
        startText = "【地震波Dummy10】120 武器对 131989。先穿带 AzeritePower 433 的头/胸/肩并选出该特质。放压制 7384。CLEU 有 278497。卸装后 277639/278495 应掉。.aura 277639 只作调试辅助，不得当闭环、不得写入通过标准。自动判定只证明 277639 光环在、278497 出手，绿勾不能代替穿脱完成定义。Dummy 10 不得改成 9.52。10 码是半径列。9.52/740 不得进 Dummy。不要勾伤公式。禁止 want=aura。",
        startPrint = "请武器战士穿 AzeritePower 433 赋能件并选出地震波再压制。卸装后 277639/278495 应掉。不要用 .aura 当闭环。只证明出手。Dummy 10 不是 9.52。",
        ids = { 277639, 278495, 278497, 7384, 277253 },
        labels = {
            [277639] = "地震波Dummy10_线宽不是9.52",
            [278495] = "隐藏proc_Dummy0_核心已挂",
            [278497] = "地震波伤_Dummy0_10码是半径列",
            [7384] = "压制触发",
            [277253] = "项链Dummy0_不要重写",
        },
        chain = {
            { id = 277639, role = "地震波特质", want = "aura-self",
              hintFail = "没有 277639。穿带 AzeritePower 433 的头/胸/肩并选出该特质。.aura 277639 只作调试辅助，不得当闭环、不得写入通过标准。自动判定只证明出手/光环，绿勾不能代替穿脱。Dummy 10 不得改成 9.52。禁止 want=aura。" },
            { id = 278497, role = "地震波伤号", want = "cast",
              hintFail = "没有 278497。120 武器对 131989 放 7384。自动判定只证明出手。10 码是半径列。9.52/740 不得进 Dummy。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "人测完成定义是穿带 AzeritePower 433 的头/胸/肩并选出该特质，再测压制打出 278497；卸装后 277639/278495 应掉。.aura 277639 只作调试辅助，不得当闭环、不得写入通过标准。自动判定只证明 277639 光环在、278497 出手，绿勾不能代替穿脱。Dummy 10 不得改成 9.52。10 码是半径列。9.52/740 不是 Dummy。不要把绿勾当已读 Coef。不要勾横扫第二波。不要重写 277253。",
            }
        end,
    },

    az_concentrated_flame_learn_295373 = {
        key = "az_concentrated_flame_learn_295373",
        title = "AZ浓缩火焰-学会295373_Dummy100_30秒是Category1852_不要Learn299349",
        order = 278,
        hint = "EssenceID 12 学会 295373。Dummy 100/100。Coef 16.71 不是 Dummy。30 秒是 Category 1852 不是 Dummy。GCD 列 1500 只登记。禁止 Learn 299349（换号会把 GCD 从 1500 改成 1000）。191837 不是 AZE。自动判定只证明 295373 出手。",
        startText = "【浓缩火焰学会295373】120 任意输出 .learn 295373（或项链 Major EssenceID 12 Rank1）。不要 .learn 299349。对 131989 放 295373。自动判定只证明 295373 出手。Dummy 100 保持。30 秒是 Category 1852 不是 Dummy。16.71/67/30/1500/1000 不得进 Dummy 100。不要勾灼烧。191837 不是 AZE。禁止 want=aura。",
        startPrint = "请 .learn 295373 打桩。不要 Learn 299349。只证明出手。30 秒不是 Dummy。",
        ids = { 295373, 295376, 295374, 299349, 295377, 295368, 191837 },
        labels = {
            [295373] = "浓缩火焰学会_Dummy100",
            [295376] = "导弹Dummy100",
            [295374] = "敌对伤_无Dummy_不INSERT",
            [299349] = "Rank2Actual_禁止Learn_GCD1000",
            [295377] = "Rank2 Dummy75_不验收",
            [295368] = "灼烧6秒不是Dummy_不验收",
            [191837] = "织雾精华之泉_不是AZE",
        },
        chain = {
            { id = 295373, role = "浓缩火焰学会", want = "cast",
              hintFail = "没有 295373。必须 .learn 295373 或镶嵌 EssenceID 12 Rank1。不要 Learn 299349。自动判定只证明出手。Dummy 100。30 秒是 Category 1852 不是 Dummy。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "自动判定只证明 295373 出手。Dummy 100 保持。30 秒是 Category 1852 不是 Dummy。不要 Learn 299349（换号会把 GCD 从 1500 改成 1000）。16.71/67/30/1500/1000 不得进 Dummy 100。不要勾灼烧。191837 不是 AZE。",
            }
        end,
    },

    itm_scripts_wired = {
        key = "itm_scripts_wired",
        title = "ITM接线-pack绿勾不能代替穿脱169311_AddSC与_12INSERT认3307与启动日志",
        order = 279,
        hint = "填 spell_item.cpp。不要改 loader。不要新建 cpp。不要改 CMakeLists。不要重写 277253 Dummy 0。人测穿脱物品 169311，确认挂上/卸下。不允许 .aura 代替穿脱。3307 应有 303564/303565/313948/314040/314042 五行新绑；277253 仍是 spell_item_heart_of_azeroth。AddSC 本波不改 loader，接线认 3307 SELECT + 启动日志仍加载 AddSC_item。自动判定不能代替穿脱。不要勾珊瑚/宣言已修。",
        startText = "【ITM接线】确认 loader 本波无 diff，启动日志仍加载 AddSC_item_spell_scripts。3307 已 INSERT 303564/303565/313948/314040/314042。277253 仍是 spell_item_heart_of_azeroth。人测穿脱物品 169311，确认挂上/卸下。不允许 .aura 代替穿脱。自动判定不能代替穿脱完成定义。AddSC 与 _12 INSERT 只认 3307 SELECT + 启动日志，不要靠 pack 绿勾。不要勾珊瑚/宣言完成。禁止 want=aura。",
        startPrint = "请穿脱物品 169311。接线认 3307 SELECT + 启动日志，不要靠绿勾代替穿脱。不要勾珊瑚/宣言完成。不要重写 277253。",
        ids = { 277253, 303564, 303565, 303573, 304877, 313948, 314040, 314042, 302855 },
        labels = {
            [277253] = "项链Dummy0_AZP一字不改",
            [303564] = "珊瑚ON_USE_Dummy0_本包不勾已修",
            [303565] = "珊瑚proc_Dummy0_本包不勾已修",
            [303573] = "珊瑚ON_EQUIP金额_不绑脚本",
            [304877] = "珊瑚ON_EQUIP金额_不绑脚本",
            [313948] = "宣言ON_USE_Dummy8_5_本包不勾已修",
            [314040] = "宣言第二章_本包不勾已修",
            [314042] = "宣言ON_EQUIP_Dummy1_本包不勾已修",
            [302855] = "regenerative_coral_不是303564",
        },
        chain = {
            { id = 303573, role = "珊瑚ON_EQUIP金额光环_不绑脚本", want = "aura-self",
              hintFail = "没有 303573。穿物品 169311 确认核心挂上 ON_EQUIP 金额光环。自动判定只证明当时 303573 仍在，绿勾不能代替穿脱完成定义。不要勾珊瑚已修。AddSC 与 _12 INSERT 只认 3307 SELECT + 启动日志。不允许 .aura 代替穿脱。禁止 want=aura。" },
        },
        extraVerdict = function()
            return {
                "人测穿脱物品 169311，确认挂上/卸下。自动判定只证明当时 303573 光环仍在，绿勾不能代替穿脱完成定义。不要勾珊瑚/宣言已修。AddSC_item_spell_scripts 本波不改 loader，接线认 3307 SELECT + 启动日志。277253 仍是 spell_item_heart_of_azeroth。不要重写 277253。不要把 302855 当成 303564。6.0/0.265/22.99/2.759/0.551/allies_end=4 不得进 Dummy。",
            }
        end,
    },

    -- 引擎回归用：只靠数据出结论，不改 Verdict.lua。


    demo = {
        key = "demo",
        title = "演示包(引擎回归)",
        hidden = true,
        serverCmd = ".lab test demo",
        hint = "假包，只用于引擎回归。",
        startText = "【演示包】不会向服务端要真实光环。",
        startPrint = "演示包已加载。",
        ids = { 1 },
        labels = { [1] = "演示伤害" },
        chain = {
            { id = 1, role = "演示伤害", want = "damage",
              hintFail = "演示包没有伤害事件。" },
        },
    },
}
