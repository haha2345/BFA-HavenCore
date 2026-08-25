# 方案 D — 团本入口

**前置：** 方案 A 可用；B/C 不必全部做完，但建议至少打过孢林。  
本阶段目标：**能进、能打第一王、死后能去下一区域**。其余王保持骨架。  
代码标准：技能 `philosophy.md`「团本」。  
8.2/8.3 团本没有第二开源实现，机制用 WCL 2020 + Wowhead。

---

## D1 永恒王宫 loader

`scripts/Nazjatar/nazjatar_script_loader.cpp`：

- 声明了 `AddSC_eternal_palace()`
- `AddNazjatarScripts()` **没有调用它**
- 各王 `AddSC_boss_*` 和 `AddSC_instance_eternal_palace()` 已调用

先把 `AddSC_eternal_palace()` 加进 `AddNazjatarScripts()`，确认 `creature_template.ScriptName` 对得上，再谈西瓦拉厚度。

第一王：指挥官西瓦拉 `AddSC_boss_commander_sivara()`。可击杀、可重置、死后能去下一场。

---

## D2 尼奥罗萨进度

`scripts/Nyalotha/instance_nyalotha.cpp` 现在约 30 行：`DATA_WRATHION == DONE` 就把玩家 `TeleportTo` 预言附属。这会打断后半。

改成正规 `SetBossState` + 门/电梯。`nyalotha.h` 里 `EncounterCount = 12`，loader 已注册 12 王，不要再复制空文件。

拉希昂 `boss_wrathion.cpp` 是本团最好的一份（`RegisterCreatureAI` + `Talk` + 分阶段）。补到可击杀、可重置；新事件用 `enum Events`，不要再把 `SPELL_*` 当 eventId。

---

## 验收

- [ ] 永恒王宫：loader 调了 `AddSC_eternal_palace()`；能进；西瓦拉可击杀；死后能去下一区域
- [ ] 尼奥罗萨：打完拉希昂**不会**被传到后半平台并卡死；能去玛乌特/预言者所在区域
- [ ] 没把风暴熔炉、吉安娜列入本阶段
---
