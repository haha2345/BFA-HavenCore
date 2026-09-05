# 细节 F4 — 掉落与 Encounter 编号

配套：[方案-自由镇.md](方案-自由镇.md) Task 8、Task 9。对照 8.3.7.35662。地图 **1754**。

---

## 1. 不要拆三张 `creature_loot_template`

表没有难度列。开箱：`Map::GetDifficultyLootItemContext()`（`Map.cpp` 约 3938–3947）先读 MapDifficulty.ItemContext，为 0 再读 Difficulty.ItemContext，再进 `ItemBonusTree`。

克拉格武器 **159633** 在 35662 `ItemSparse` 底装等 **300**，不是赛季说明的 400/415/430。满级装等只能来自加成（选择器 + `ItemBonusListLevelDelta`），禁止改物品 ID。159633 的选择器树 **1545** 仍指向 340/355/370，本阶段不改选择器去凑赛季档。

---

## 2. 4776 不要删

树 **1492** 顶层（grill `ItemBonusTreeNode`）：

| ItemContext | 加成列表 | 自由镇谁用 |
|-------------|----------|------------|
| 1 地下城普通枚举 | 4777 | 本图普通**不用**这条（MapDifficulty 不是 1） |
| 2 英雄 | 4778 | 英雄：MapDifficulty ItemContext=0，回落 Difficulty 2 |
| 23 史诗 | 4779 | 史诗：回落 23 |
| **17 / 18 / 19** 升级地下城 | **4776** | **本图普通 MapDifficulty 行 3794 的 ItemContext 正是 17** |
| 16 / 35 钥石 | 4780 | 本阶段不做 |

ATT 普通块 `bonusID=4776` 与本图普通 ItemContext=17 一致，不是「误标成 Dungeon_Normal=1」。禁止删除 4776，禁止按 ATT 给英雄硬打 4776。

4776 在 `ItemBonus` 里是品质/外观/缩放分布，**不是**「+100 物品等级」。

---

## 3. 脏数据与坐骑条件

从 `creature_loot_template` **DELETE**（不要拆表）：

| Entry | Item | Chance | 名称 | 处理 |
|-------|------|--------|------|------|
| 126832 | 139299 | 53 | Finely-Tailored Red Holiday Hat | 删行 |
| 126983 | 158923 | 5 | 神话钥石 | 删行；不要做钥石系统 |

坐骑 **159842** Sharkbait's Favorite Crackers，Chance **21**，保留 Chance。加 `conditions`：

- `SourceTypeOrReferenceId` = **1**（`CONDITION_SOURCE_TYPE_CREATURE_LOOT_TEMPLATE`）
- `SourceGroup` = 126983
- `SourceEntry` = 159842
- `ConditionTypeOrReference` = **49**（`CONDITION_DIFFICULTY_ID`）
- `ConditionValue1` = **23**

8.0 手册即史诗哈兰才掉坐骑，8.3 未见取消。普通/英雄不应出。

哈兰其余行保持（含 165948、168132、162520、162460）。不要为本阶段清小怪裁缝布。

---

## 4. 议会箱子 288636

模板 type=3；Data0 锁 1634；**Data1=0**（必须改成 **288636**）；Data25=**2094**（议会战斗遭遇，保持）；Data30=86063 指向生物胡拉德，C++ 不读，不要当 loot。

`gameobject_loot_template` 对 288636 与 86063 目前 0 行。三船长 `lootid=0`，保持。

插入 Entry=288636 的装备（ATT 手册遭遇 2093 议会块；Chance 对齐其它王装备量级，不是 ATT 掉率——ATT 无掉率）：

| Item | 35662 英文名 | Chance | MinCount | MaxCount | GroupId |
|------|--------------|--------|----------|----------|---------|
| 159132 | Jolly's Boot Dagger | 8 | 1 | 1 | 1 |
| 159130 | Captain's Diplomacy | 6 | 1 | 1 | 1 |
| 158311 | Concealed Fencing Plates | 4 | 1 | 1 | 1 |
| 159356 | Raoul's Barrelhook Bracers | 4 | 1 | 1 | 1 |
| 158346 | Sailcloth Waistband | 4 | 1 | 1 | 1 |
| 159297 | Silver-Trimmed Breeches | 4 | 1 | 1 | 1 |
| 158351 | Dashing Bilge Rat Shoes | 4 | 1 | 1 | 1 |
| 158314 | Seal of Questionable Loyalties | 3 | 1 | 1 | 1 |

`LootMode=1`，`QuestRequired=0`，`Reference=0`。不要给箱子加 139299 / 158923。

静态刷 288636 本阶段不做（C++ 已在 DONE 时召唤）。

---

## 5. 克拉格 / 托萨克 / 哈兰现表（只删脏行，不重写整表）

克拉格 126832 保留：159633 Chance 28、155884 Chance 11、155862 Chance 3、158360 / 159227 / 159353 Chance 2。

托萨克 126969 整表不动（155889–155892、158302、158305、158356、158361、159634；172954 Chance 0.02 可留）。

哈兰 126983 只删 158923，给 159842 加难度条件。

---

## 6. Encounter 两套编号（Task 9）

| 顺序 | 生物 | 战斗遭遇 `instance_encounters` / CLEU / LittleWigs engageId / DBM SetEncounterID | 手册 Journal / LittleWigs NewBoss 第三参 / ATT e() | Haven `creature_template_journal` | 本阶段 |
|------|------|----------------------------------------------------------------------------------|-----------------------------------------------------|-----------------------------------|--------|
| 1 克拉格 | 126832 | **2093** | **2102** | 126832→2102 正确 | 不动 |
| 2 议会 | 126847 / 126848 / 126845 | **2094**（信用 NPC 尤朵拉 126848） | **2093** | 126848→**2094 错** | 改成 **2093** |
| 3 环赌 | 126969 | **2095** | **2094** | 托萨克缺行 | **INSERT (`entry`, `JournalEncounterID`) (126969, 2094)** |
| 4 哈兰 | 126983 | **2096** | **2095** | 126983→2095 正确 | 不动 |

禁止改 `instance_encounters` 四行。禁止把手册 2102 写入战斗遭遇（同一张 DungeonEncounter 里 2102 是托尔达戈 Jes Howlis）。禁止用 MDT 把克拉格写成 encounterID 2095。GO 288636 Data25=2094 与议会战斗遭遇一致，不要读成手册环赌。

冒险指南实例 **1001**，地图 1754。ATT `maps={936}` 是 UiMap（父地图 895），不是 MapID。LFG 活动 35662 是 **1672 / 1704 / 1773**，不是 RaiderIO 的 516–539；本阶段不补 `lfg_dungeon_template`。

SQL 列名以 dump 为准（`bfa_world.sql` 约 2759533–2759540 行；`ObjectMgr.cpp` 读取语句是 `SELECT entry, JournalEncounterID FROM creature_template_journal`）：

```sql
UPDATE `creature_template_journal` SET `JournalEncounterID`=2093 WHERE `entry`=126848;
INSERT INTO `creature_template_journal` (`entry`, `JournalEncounterID`) VALUES (126969, 2094);
```

禁止写成 `journalEncounterId` / `creatureId`。现存行确为 `(126848, 2094)`，改成手册 **2093**；托萨克补 `(126969, 2094)`。126832→2102、126983→2095 不动。

---

## 7. 地下城成就 SQL — Task 11 明确不做

调研 I：成就名（如 Mythic: Freehold）在 SQL **本源未见**；`achievement_dbc` 只有旧世界成就。ATT 史诗块写过 12548 / 12550 / 12833 / 12998 等编号，本阶段**不** INSERT `achievement` / criteria。不挡能打出装。见主方案 Task 11。
