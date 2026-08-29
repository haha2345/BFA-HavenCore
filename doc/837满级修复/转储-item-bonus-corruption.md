# 转储：8.3.7.35662 物品加成树（腐蚀掉落）

对照版本：**8.3.7.35662**。  
数据来源：RelWithDebInfo `worldserver` 启动日志（`DataDir` = `ClientData`，zhCN）。脚本加载时 `DB2Manager::LogCorruptionItemBonusDump` 打出标签 `CorruptionBonus.dump`。本机 `ItemBonusTreeNode` 布局哈希仍是 Meta 里的 `0x5F0770E4`（五字段，没有 `ChildItemBonusListGroupID`）。布局对照：

| 表 | 布局哈希 | 记录侧字段 | 与 Meta 是否一致 |
|----|----------|------------|------------------|
| ItemXBonusTree | `0x9C8FF861` | 1 列 + ItemID 父查找 | 是 |
| ItemBonusTreeNode | `0x5F0770E4` | 4 列 + ParentItemBonusTreeID 父查找 | 是；**没有**第六字段 `ChildItemBonusListGroupID` |
| ItemBonus | `0xE119360C` | Value[3] / ParentList / Type / Order | 是 |

启动日志里十四件都有 `CorruptionBonus.dump:` 行。下面表格从这些行抄出，不是从 Wago 网页手填。

类型对照：类型 23 = `ITEM_BONUS_ITEM_EFFECT_ID`（物品效果编号）；类型 2 = 属性，`Value[0] == 22` 即 `ITEM_MOD_CORRUPTION`（腐蚀点数）；类型 15 = `ITEM_BONUS_RANDOM_ENCHANTMENT`（本转储的十四件上 **零条**）。

`GetDefaultItemBonusTree` 对一棵树只统计**顶层**节点：`ItemContext` 为 0 或等于当前掉落上下文则计入；`matchingNodes != 1` 则整棵跳过。下表「团本英雄是否套上」按 `ItemContext::Raid_Heroic`（5）计算。

---

## 1. 十二把写死武器：专用树

十二把各自另挂一棵 **Context=0、恰好一个节点** 的专用树。顶层 `matchingNodes == 1`，寻找团队 / 普通 / 英雄 / 史诗都会套上同一条 `childList`。热修空树 3025（零节点）会被跳过，不影响专用树。

Shard 是 **6544**（不是 6545）。Vorzz 是 **6541**（不是 6542）。

下表用途：对照「专用树是否为单节点 Context=0」以及「childList 是否等于细节-F2」。

| 物品编号 | 英文名 | 专用树 | 节点 | 上下文 | childList | 类型 23 效果 | 腐蚀点数（类型 2，模组 22） | 与细节-F2 |
|----------|--------|--------|------|--------|-----------|--------------|------------------------------|-----------|
| 172191 | An'zig Vra | 2893 | 11375 | 0 | **6567** | 116812 | 35 | 一致 |
| 172193 | Whispering Eldritch Bow | 2894 | 11376 | 0 | **6568** | 116813 | 25 | 一致 |
| 172197 | Unguent Caress | 2895 | 11377 | 0 | **6569** | 116814 | 25 | 一致 |
| 172198 | Mar'kowa, the Mindpiercer | 2896 | 11378 | 0 | **6570** | 116815 | 20 | 一致 |
| 172199 | Faralos, Empire's Dream | 2897 | 11379 | 0 | **6571** | 116816 | 30 | 一致 |
| 172200 | Sk'shuul Vaz | 2898 | 11380 | 0 | **6572** | 116817 | 50 | 一致 |
| 172187 | Devastation's Hour | 2862 | 11291 | 0 | **6539** | 116784 | 75 | 一致（暮光三段） |
| 172189 | Eyestalk of Il'gynoth | 2871 | 11300 | 0 | **6548** | 116793 | 30 | 一致（真相二段） |
| 174106 | Qwor N'lyeth | 2873 | 11302 | 0 | **6550** | 116795 | 35 | 一致（回响二段） |
| 172227 | Shard of the Black Empire | 2867 | 11296 | 0 | **6544** | 116789 | 35 | 一致（附肢二段，不是 6545） |
| 174108 | Shgla'yos, Astral Malignity | 2876 | 11305 | 0 | **6553** | 116798 | 50 | 一致（无尽之星二段） |
| 172196 | Vorzz Yoq'al | 2864 | 11293 | 0 | **6541** | 116786 | 35 | 一致（仪式二段，不是 6542） |

启动日志原文（An'zig Vra 专用树）：

```
INFO  CorruptionBonus.dump: item=172191 tree=2893 node=11375 ctx=0 childTree=0 childList=6567 selector=0
INFO  CorruptionBonus.dump: list=6567 bonus=12473 type=23 v0=116812 v1=0 v2=0
INFO  CorruptionBonus.dump: list=6567 bonus=12474 type=2 v0=22 v1=35 v2=0
INFO  CorruptionBonus.dump: list=6567 bonus=12475 type=24 v0=0 v1=0 v2=0
```

同物品还挂装等树 2748、品质树 2767，以及被 `matchingNodes != 1` 跳过的 1521 / 1522 / 2900。写死列表只来自上表专用树。`.labgear` 使用 `ItemContext::NONE`，**不**走 `GetDefaultItemBonusTree`，必须在命令里写入上表 `childList`。

---

## 2. `174164`（尼奥罗萨板甲胸，随机腐蚀对照件）

启动日志里该物品只有两次 `tree=`：**2748**（装等选择器 1115–1118）和 **2767**（品质列表 4822–4825）。没有第三棵树。

- **没有**类型 15。
- **没有**指向加成组的边（8.3.7 树节点也没有组字段可写）。
- 品质列表是插槽 / 名称描述 / 空列表，不是腐蚀特效。

因此随机腐蚀 **不能** 从默认树展开，必须在 `GetDefaultItemBonusTree` 之后另抽组 158。

---

## 3. `172186`（惊醒梦魇战锤，随机腐蚀武器对照件）

除 1521 / 1522 / 2748 / 2767 外，启动日志另有树 **2819**。转储用 `VisitItemBonusTree(..., visitChildren=true)`，所以会走进子树；`GetDefaultItemBonusTree` 统计匹配时 **不** 走进子树。树 2819 顶层两个 Context=0 节点（11182 → 子树 2758，11183 → 子树 2816），任意团本上下文 `matchingNodes != 1`，**整棵跳过**。不要为功能 4 放宽「恰好一个匹配节点」。

```
INFO  CorruptionBonus.dump: item=172186 tree=2819 node=11182 ctx=0 childTree=2758 childList=0 selector=0
INFO  CorruptionBonus.dump: item=172186 tree=2819 node=11183 ctx=0 childTree=2816 childList=0 selector=0
```

走进子树后看到的 6513 / 6515 是空列表（类型 0），不是腐蚀目录。启动日志十四件上 **没有** `type=15`。

---

## 4. 路径锁定

`RANDOM_PATH=GROUP158`

本机 DB2 与 Wago 8.3.7.35662 一致：写死武器专用树单节点；可随机件没有类型 15、没有组边。禁止改回按类型 15 展开。

`FIXED_PATH=TREE+INSERT`

团本掉落（上下文非空）时默认树已经带上专用 `childList`。展开函数仍「缺失则插入」，覆盖 `.labgear` 的 `ItemContext::NONE`。

组 158 已在任务 1 加载后转储，见第五节。

---

## 5. 组 158（`ItemBonusListGroupEntry`）

加载成功：启动日志 `Initialized 280 DB2 data stores`（原先 279）。布局哈希 `0xCA17B2FF`，五列，无 `PlayerConditionID` / `Flags`。

组 **158** 共 **69** 条。`SequenceValue` **全部是 −1**，不能当权重，也不能把「6474 + 6455」当成同序成对。`ItemExtendedCostID` 与 `ItemLevelSelectorID` 全是 0。

计划要求抄进文档的三行（启动日志原文）：

```
INFO  CorruptionBonus.dump: group=158 list=6474 seq=-1 cost=0 selector=0
INFO  CorruptionBonus.dump: group=158 list=6552 seq=-1 cost=0 selector=0
INFO  CorruptionBonus.dump: group=158 list=6567 seq=-1 cost=0 selector=0
```

组内同时含：签名各段 6537–6554、独特武器 6567–6572、空列表 6516、未对上的 6487–6492 与 6496–6498。任务 4 抽签时过滤后两段，签名段留下。
