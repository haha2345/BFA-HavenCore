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
