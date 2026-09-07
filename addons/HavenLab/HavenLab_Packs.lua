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
