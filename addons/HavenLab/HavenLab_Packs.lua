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
        -- 清单：一段 Dummy +6% 急速来源。来源：腐蚀特效清单 / 方案 P2
        expect = { stat = "haste", minDelta = 6 },
        hint = "挂 315544。看急速来源 +6%。API：/dump GetHaste() 待验存在性。",
        startText = "【权宜之计】已挂 315544。对比开测快照，急速应涨约 6 个百分点（来源乘算，先看有明显增量）。",
        startPrint = "已挂 315544 并卸其他腐蚀测包。看急速。",
        ids = { 315544, 315545, 315546, 320257 },
        labels = { [315544] = "一段驱动", [315545] = "二段", [315546] = "三段", [320257] = "hidden急速" },
        chain = {
            { id = 315544, role = "驱动", want = "aura-self", hidden = true,
              hintFail = "没挂上 315544。看 .lab test expedient。" },
            { id = 315544, role = "急速+6%", want = "stat",
              expect = { stat = "haste", minDelta = 6 },
              hintFail = "急速没涨到约 +6。先 /dump GetHaste()；面板没变则 DBC 光环未生效（待验后再决定要不要脚本）。" },
        },
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
              hintFail = "没挂上 315529。" },
            { id = 315529, role = "精通+6%", want = "stat",
              expect = { stat = "mastery", minDelta = 6 },
              hintFail = "精通没涨到约 +6。/dump GetMasteryEffect()。" },
        },
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
              hintFail = "没挂上 315549。" },
            { id = 315549, role = "全能+6%", want = "stat",
              expect = { stat = "vers", minDelta = 6 },
              hintFail = "全能没涨到约 +6。/dump GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)。" },
        },
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
              hintFail = "没挂上 315554。" },
            { id = 315554, role = "暴击+6%", want = "stat",
              expect = { stat = "crit", minDelta = 6 },
              hintFail = "暴击没涨到约 +6。/dump GetCritChance()。" },
        },
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
              hintFail = "没挂上 315590。" },
            { id = 315590, role = "吸血+3%", want = "stat",
              expect = { stat = "lifesteal", minDelta = 3 },
              hintFail = "吸血没涨到约 +3。/dump GetLifesteal()。" },
        },
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
              hintFail = "没挂上 315277。" },
            { id = 320249, role = "hidden暴击伤", want = "aura-self", hidden = true,
              hintFail = "有驱动但没有 320249。触发没挂上 hidden，或脚本没 CastSpell。" },
        },
        extraVerdict = function(self)
            return {
                "击穿不看面板暴击%。待进游戏验收：打桩暴击 CLEU 应比未挂时大约 +2%（一段 Dummy）。",
                "治疗暴击走驱动 EFFECT_1 活 aura（+4/6/8）。320249 治疗 BP 保持 0，脚本不填，避免和驱动叠成双倍。",
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
        hint = "挂 315607。闪避 = 急速的 8%。核心 aura 198 是空壳，先进游戏看面板。",
        startText = "【闪避者】已挂 315607。35662 Dummy 8/12/16，不是 Icy Veins 5/8/10。",
        startPrint = "已挂 315607。看闪避。/dump GetAvoidance()。",
        ids = { 315607, 315608, 315609 },
        labels = { [315607] = "一段驱动", [315608] = "二段", [315609] = "三段" },
        chain = {
            { id = 315607, role = "驱动", want = "aura-self", hidden = true,
              hintFail = "没挂上 315607。" },
            { id = 315607, role = "闪避随急速", want = "stat",
              expect = { stat = "avoidance", minDelta = 0.01 },
              hintFail = "闪避没变。核心 SPELL_AURA_198 是旧武器技能空壳，面板不变则要脚本（待进游戏定案，先不写）。" },
        },
        extraVerdict = function()
            return {
                "待进游戏验收：/dump GetAvoidance()；闪避是否随急速的 8%。",
                "核心未实现 aura 198 的「闪避=急速%」转换。面板不变再写 CalcAmount，禁止写死 8/12/16。",
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
              hintFail = "没挂上 318220。用 .lab test pulse / .labpulse。" },
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
                "待进游戏验收：318227 约 4 秒掉；再 proc 刷新时长、不叠层。",
                "白字能否 proc 信 DBC（含 White Melee）。面板急速% 随等级变，只验 rating。",
                "第 1 层挂 hidden proc，不赌 LINKED 带 318220。真装 P5 再验驱动。",
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
              hintFail = "没挂上 318214。用 .lab test mind / .labmind。" },
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
                "待进游戏验收：318216 约 10 秒掉；再 proc 刷新时长、不叠层。",
                "白字能否 proc 信 DBC（含 White Melee）。面板精通% 随等级变，只验 rating。",
                "第 1 层挂 hidden proc，不赌 LINKED 带 318214。真装 P5 再验驱动。",
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
              hintFail = "没挂上 318218。用 .lab test momentum / .labmomentum。" },
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
                "待进游戏验收：318219 约 30 秒掉（信 35662，不信 SimC 15s）。满层后再 proc 是否整段刷新。",
                "仅暴击进 RPPM（DoCheckProc）。平击不应消耗次数。叠到 5 不做成硬失败。",
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
              hintFail = "没挂上 318212。用 .lab test vitality / .labvitality。" },
            { id = 318212, role = "开涌动", want = "labmsg", labType = "VITAL_PROC", procStep = true,
              hintFail = "没有 VITAL_PROC。木桩打不出；站会还手的怪或自己挨 DoT（RPPM 2，taken）。" },
            { id = 318211, role = "全能buff", want = "aura-self",
              hintFail = "有 VITAL_PROC 但自己没有 318211。脚本 CastSpell 没挂上（taken 目标应是自己）。" },
            { id = 318211, role = "全能rating+343", want = "stat",
              expect = { stat = "versRating", minDelta = 343 },
              hintFail = "有 318211 但全能 rating 没涨到约 +343。一段 Scaled，禁止用 Icy Veins 312。" },
        },
        extraVerdict = function()
            return {
                "待进游戏验收：318211 约 20 秒掉；再 proc 刷新、不叠层。",
                "触发是受伤侧。热修掩码含 heal-taken，先不滤治疗。/dump GetCombatRating 对客户端全能下标。",
                "驱动 Base 热修为 0，数字走 CalcValue Scaled。第 1 层挂 hidden proc。真装 P5。",
            }
        end,
    },

    wound = {
        key = "wound",
        title = "龟裂创伤",
        order = 17,
        serverCmd = ".lab test wound",
        hint = "挂 318179。用黄字打木桩（平砍不开）。\n318187 暗影渗血 7 秒，每跳 Dummy 13% max(AP,SP)，不要 ÷7。",
        startText = "【龟裂创伤】已挂 318179。猛击等黄字打木桩。proc 写成 WOUND_PROC，跳伤写成 WOUND_TICK。",
        startPrint = "已挂 318179。用黄字打。看 318187 暗影跳伤。平砍不开。",
        ids = { 318272, 318179, 318187 },
        labels = {
            [318272] = "一段驱动",
            [318179] = "隐藏proc",
            [318187] = "渗血DoT",
        },
        chain = {
            { id = 318179, role = "隐藏proc", want = "aura-self", hidden = true,
              hintFail = "没挂上 318179。用 .lab test wound / .labwound。" },
            { id = 318179, role = "开渗血", want = "labmsg", labType = "WOUND_PROC", procStep = true,
              hintFail = "没有 WOUND_PROC。用猛击等黄字打（RPPM 4，平砍不开）。" },
            { id = 318187, role = "渗血跳伤", want = "damage",
              expect = { school = 32 },
              hintFail = "有 WOUND_PROC 但没有 318187 暗影跳伤。看 Cast 目标是不是当前敌人。" },
        },
        extraVerdict = function()
            return {
                "待进游戏验收：约 7 秒 / 约 7 跳；刷新是重置满时长（不是 SimC pandemic）。",
                "跳伤 = Dummy 13% × max(AP,SP)，不要 ÷7，不要写死 Icy Veins 70%。驱动系数 2.37 是装等，P5。",
                "DBC 可暴击。CLEU 是否真暴击、跳数 6 还是 7，进游戏再定。",
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
              hintFail = "没挂上 315574。用 .lab test glimpse / .labglimpse。" },
            { id = 315573, role = "Glimpse", want = "aura-self", procStep = true,
              hintFail = "没有 315573。平砍或技能打一会儿（RPPM 2）。DBC Trigger 应自己挂上。" },
            { id = 315573, role = "CD-3s", want = "labmsg", labType = "CD_TRIM",
              expect = { trimMs = 3000 },
              hintFail = "有 315573 但没有 CD_TRIM。放有 CD 的职业技能，不要放物品/腐蚀技能。" },
        },
        extraVerdict = function()
            return {
                "待进游戏验收：315573 约 15 秒；用一次有 CD 技能后减层或消失。",
                "trimMs=3000 溯源 Dummy 3。物品技能和腐蚀技能不应出 CD_TRIM。",
                "6486 vs 6546 第 1 层不选定。真装 P5。不要和法器 Flash of Insight 混。",
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
              hintFail = "没挂上 316799。用 .lab test truth / .labtruth。" },
            { id = 316801, role = "加速buff", want = "aura-self", procStep = true,
              hintFail = "没有 316801。技能打一会儿（RPPM 1，无白字）。DBC Trigger 应自己挂上。" },
            { id = 316801, role = "RECHARGE", want = "labmsg", labType = "RECHARGE",
              expect = { pct = 30 },
              hintFail = "有 316801 但没有 RECHARGE pct=30。核心 143/173 是 NYI，脚本应在 Apply 发消息。" },
        },
        extraVerdict = function()
            return {
                "待进游戏验收：316801 约 10 秒；窗口内新开的职业 CD 按 100/(100+30) 缩短。",
                "pct=30 溯源 318303 Dummy。Lab 只挂 316799 时回退读 SpellInfo Dummy 30。",
                "已有 buff 再 proc：默认刷新 10s（SimC TODO）。已在转的充能剩余、物品充能是否加速，进游戏再定。",
                "职业技能过滤先宽后窄。二段 Dummy 50 用 .aura 318484 再验。",
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
