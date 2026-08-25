# 方案 A — 腐蚀

阶段完成定义见 [00-目标.md](00-目标.md)。开工顺序见 [01-从哪里开始.md](01-从哪里开始.md)。  
代码标准：技能 `philosophy.md`「腐蚀」「技能」两节。

**两套系统：** 装备上的好效果（`腐蚀 - 无尽之星` 等 ItemEffect）≠ 总腐蚀坏效果（`CorruptionEffects.db2` + `UpdateCorruption()`）。名单见 [腐蚀特效清单.md](腐蚀特效清单.md)。怎么测见 [方案-A-腐蚀-测试.md](方案-A-腐蚀-测试.md)。

不要重写 `UpdateCorruption()` 循环，不要 hardcode 阈值表。

---

## 已有代码（家在这里）

| 文件 | 现状 |
|------|------|
| `Player::UpdateCorruption()` | **只负责坏效果。** 有效腐蚀 = CR_CORRUPTION − 抵抗；遍历 35662 的 10 行 `CorruptionEffects.db2` |
| `Player.cpp` ApplyRatingMod | `ITEM_MOD_CORRUPTION` 变化时调用 `UpdateCorruption()` |
| `Item.cpp` `ITEM_BONUS_ITEM_EFFECT_ID` (23) | **好效果从这里挂上 ItemEffect** |
| `scripts/Spells/` | **没有** `腐蚀 -` 系列 SpellScript |
| `CorruptionEffects.db2` | 336 字节、10 行，与 35662 客户端一致，**不是空壳** |

---

## A0 — 进游戏基线（不写脚本）

按测试文档「今天就可以做」的 7 步：lookup + `.aura`，记下 ID，确认第 1 层无尽之星**预期不触发**。同时确认坏效果表有 10 行（worldserver 能 load 这份 db2）。

没有 A0 的 ID，A1 不要开写。

---

## A1–A4 — 签名效果（一次一条）

纯属性（急速 / 暴击 / 精通 / 全能 / 吸血）若 DB2 光环已经是 `SPELL_AURA_MOD_RATING` 一类，**不要包 SpellScript**。

要写脚本的是有独特战斗行为的。顺序：

| 顺序 | 效果 | 8.3 行为（用 Wowhead / SimC bfa-dev 核对，ID 以 DB2 为准） |
|------|------|------|
| A1 | 无限之星 | 技能/法术有几率在目标处落星，约 1 秒后**奥术**伤并叠易伤。正确做法见 [做法-A1-无尽之星.md](做法-A1-无尽之星.md) |
| A2 | 暮光毁灭 | 攻击有几率沿面前直线打出一道暗影斩击 |
| A3 | 回响虚空 | 攻击叠层，满层对周围爆发 |
| A4 | 扭曲的附肢 | 有几率在身边召唤触须打当前目标 |

实现约定：

- 新文件：`src/server/scripts/Spells/spell_corruption.cpp`
- 在 `spell_script_loader.cpp` 增加 `AddSC_corruption_spell_scripts()` 并在 `AddSpellsScripts()` 里调用
- 用 `RegisterSpellScript` / `RegisterAuraScript`，不要 `new spell_xxx()`
- `sql/updates/world/YYYY_MM_DD_NN_world_corruption_<effect>.sql` 只插 `spell_script_names`
- 阈值、禁用旗、职业条件留在 DB2，脚本只实现「这条 Aura 挂上之后做什么」
- 一条效果一个提交：`Scripts/Spells: Implement Infinite Stars corruption effect`

ID 在 A0 从 DB2 抄下来，写进 `enum Spells`，禁止在施法处写裸数字。Wowhead 英文名只用来在 Spell.db2 里对名字。

---

## 不在本阶段

- 惊魂幻象、黑帝国披风、恩佐斯突袭、腐蚀抵抗的新公式
- 改 `UpdateCorruption()` 的遍历逻辑（除非发现没在穿脱时调用——那是补调用点，不是重写表）

---

## 验收

- [ ] store 非空
- [ ] 穿上 / 脱掉腐蚀装，Aura 上/下
- [ ] A1–A4 在木桩上能看出与 8.3 同类的行为（差几秒、差系数可以后调）
- [ ] 抗性升高后，低于 MinCorruption 的效果会掉
- [ ] 进度表更新；未进游戏必须写明
---
