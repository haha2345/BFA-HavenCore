local _, HL = ...

-- 纯数据 + 包特有话术。新效果只加一张表，不改引擎。

HL.THRESHOLDS = {
    { min = 1,  label = "蔓生触须", auras = {} },
    { min = 20, label = "腐蚀之眼", auras = {} },
    { min = 40, label = "宏伟妄想", auras = {} },
    { min = 60, label = "层叠灾难", auras = {} },
    { min = 80, label = "不可避免的厄运", auras = {} },
}

HL.SHELL_IDS = {
    [324889] = true, [324890] = true, [324891] = true,
    [318276] = true, [318477] = true, [318478] = true,
    [318280] = true, [318485] = true, [318486] = true,
    [318286] = true, [318479] = true, [318480] = true,
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
        hint = "用带 GCD 的技能打。叠 317020，有几率坍缩。\nICD 700ms。坍缩写成 ECHO_COLLAPSE。",
        startText = "【回响测试】已挂 317014。用带 GCD 的技能打木桩。叠层看 317020，坍缩看 ECHO_COLLAPSE / 317029。",
        startPrint = "已对你挂 317014 并卸星/暮光。用带 GCD 的技能打，普攻不叠。",
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
              hintFail = "没有 317020 叠层。只用带 GCD 的技能；普攻不叠。" },
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
