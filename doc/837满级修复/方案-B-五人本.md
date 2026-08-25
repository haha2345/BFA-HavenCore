# 方案 B — 五人本

**前置：** 方案 A 至少 A0+A1 验收过。本阶段第一遍**不接词缀**。  
代码标准：技能 `philosophy.md`「五人本」。

选 Haven 已经有肉的本，按这个顺序，一次一本：

1. 地渊孢林
2. 塞塔里斯神庙 **或** 维克雷斯庄园（做完孢林再选一本更差的）
3. 自由镇（前两本稳定之后）

---

## 一本「能打通」的最低集合

缺一不可：instance（BossState / 门，不用传送冒充进度）、每个王可击杀且主要技能会放、`AddSC` 被调用、ScriptName 对得上、重置不残留、能出装。

---

## B1 地渊孢林（map 1841）

五人里最厚，loader 已挂：

```
scripts/Zandalar/TheUnderrot/
  instance_the_underrot.cpp   AddSC_instance_underrot
  the_underrot.cpp            AddSC_the_underrot
  boss_elder_leaxa.cpp
  boss_cragmaw_infested.cpp
  boss_sporecaller_zancha.cpp
  boss_unbound_abomination.cpp
  the_underrot.h              EncounterCount = 8（含事件，不只 4 王）
```

`zandalar_script_loader.cpp` 里上述 `AddSC_*` 都有调用。工作是**打通机制和重置**，不是新建文件。

建议顺序：进本 → 四王各打一次 → 灭团重置 → 史诗再走一遍。对照 Wowhead 8.3 战术，缺的机制补在现有 `boss_*.cpp`。憎恶仍是 `CreatureScript` + `me->Yell`，新代码用 `RegisterCreatureAI` + `Talk`，不要把整文件改风格。

**完成：** 普通/英雄/史诗能从门口打到憎恶；主要 AT / 分身类机制在；能出装。

---

## B2 塞塔里斯或维克雷斯

都在 Haven 且不是空 `AddSC`。孢林通了再选缺口更大的那本。

| 本 | 路径 | 调研要点 |
|----|------|----------|
| 塞塔里斯 | `scripts/Zandalar/TempleOfSethraliss/` | 阿德里斯/阿斯匹克斯相对好；加瓦兹特挡电不完整 |
| 维克雷斯 | `scripts/KulTiras/WaycrestManor/` | 三姐妹最好；instance 几乎无门 |

---

## B3 自由镇

`scripts/KulTiras/FreeHold/`。本系列相对最好（环赌最满）。当作「巩固」，不要当成第一本。

---

## 不要在 B 做

- 诸王之眠（五人里最差，往后）
- 麦卡贡后半、围攻伯拉勒斯阵营镜像
- 词缀（那是方案 C）
- 从 AshamaneBFA 抄空 `AddSC` 的 cpp
---
