# 方案 — HavenLab 测试台升级(1–11)

服务对象:[方案-A-腐蚀.md](方案-A-腐蚀.md) 后续阶段(A3 虚空回响、A4 扭曲的附肢、被动/次级触发、B 坏效果、2a/2b 真装管道)。
现状底本:插件 `client/.../AddOns/HavenLab/` v1.3.2;服务端 `cs_misc.cpp` 的 `.labstars/.labtwilight/.labaoe/.labgear` + `spell_corruption.cpp` 的 `Notify*` 系统消息。

**为什么要动**:现在的结论判定(`VerdictLines`,约 80 行)对星/暮光硬编码;清单里还有 3 条签名 + 7 条次级触发 + 7 条被动 + 5 条坏效果,一条条硬编码写不完,而且属性、召唤物、多目标、腐蚀值四类观测能力完全没有。

---

## 铁律

- 插件只**观测和判定**,不代替人测:结论引擎说"断在哪一环",话术仍由 pack 数据里的人写文案给出。
- 一键操作**一次只发一条**服务端命令(8.3 禁止插件从定时器发聊天命令,已在代码注释里踩过)。复合动作全部收进服务端 `.lab` 命令。
- 服务端→插件只走 `[HavenLab] <TYPE> k=v ...` 系统消息一条信道,**不开 addon message 新信道**(现有 `Notify*` 已是这个形状,够用)。
- 新增效果 = 服务端表加一行 + 插件 pack 数据加一张表,**不改引擎代码**。改了引擎才能支持的,先改引擎再加效果。
- 旧行为不回退:星/暮光两包迁到新引擎后,报告里现有关键结论(落星计数、visual、平砍数)必须还在。

## 文件布局(目标)

| 文件 | 内容 | 动作 |
|------|------|------|
| `HavenLab.lua` | 核心:CLEU、日志、发送、DB | 改:抽走 pack 数据和结论逻辑 |
| `HavenLab_Packs.lua` | **纯数据**:所有测试包(链路、期望、文案) | 新建 |
| `HavenLab_Verdict.lua` | 链路检查引擎 + 触发率/百分比计算 | 新建 |
| `HavenLab_Track.lua` | 召唤物跟踪、按目标统计、属性快照、腐蚀值、装备事件、移速监控 | 新建 |
| `HavenLab_UI.lua` | 界面 | 改:右栏加腐蚀/属性区,新增总览窗 |
| `HavenLab.toc` | | 改:加三个文件,版本 2.0 |
| 服务端 `cs_misc.cpp` | `.lab test <key>` 表驱动 | 改 |
| 服务端 `spell_corruption.cpp` | `LabNotify` 通用 helper | 改 |

---

## 批次一(A3/A4 开工前必须完成):1、2、3、4、5、11

### 1. 数据驱动测试包引擎

pack 定义从 `HavenLab.lua` 迁到 `HavenLab_Packs.lua`,链路步骤扩展成:

```lua
chain = {
    { id = 324889, role = "外壳1", want = "aura-self" },
    { id = 317257, role = "隐藏proc", want = "aura-self", hidden = true,
      hintFail = "隐藏光环,buff 栏看不见是正常的,以战斗记录为准。" },
    { id = 317262, role = "导弹", want = "labmsg", labType = "STAR_VISUAL",
      expect = { missile = 1 }, procStep = true },
    { id = 317265, role = "伤害/叠层", want = "damage-aura",
      expect = { school = 64 } },
}
```

`want` 枚举(引擎逐环消费对应数据源):

| want | 数据源 | 判定 |
|------|--------|------|
| `aura-self` / `aura-target` | stats 光环计数 + `FindAura` | 挂上过 ≥1 次 |
| `cast` | stats 施法计数 | 施法 ≥1 次 |
| `damage` / `damage-aura` | stats 伤害/叠层 | 伤害 ≥1 次(-aura 另查叠层) |
| `summon` | 召唤跟踪(第 2 条) | 出过召唤物,且召唤物有输出 |
| `stat` | 属性快照(第 6 条) | 快照增量达到 `expect` |
| `labmsg` | LAB 消息解析(第 11 条) | 收到 `labType` 且 kv 满足 `expect` |

`HavenLab_Verdict.lua` 的 `HL:VerdictLines()` 改为通用:遍历当前 pack 的 chain,每步产出 `通过 / 失败 / 无数据`,第一处失败给出该步 `hintFail`(没写就给通用话术"上一环有、这一环没有,断在这里")。pack 可选 `extraVerdict = function(HL) ... end` 钩子放包特有话术(星的"普攻不出星"提醒、暮光的"脸没对准"提醒迁到这里)。

现有 `stars`/`twilight` 两包按新格式重写,作为引擎的回归样例。`CountStarVisuals`/`CountTwilightVisuals`/`ClickedUnaura` 等专用扫描函数删除,由 labmsg 解析和引擎替代。

**验收**:两包在新引擎下打一轮木桩,报告结论覆盖旧版全部关键信息;新加一个假 pack(只有数据)不改任何引擎代码即可出结论。

### 2. 召唤物跟踪(A4 扭曲的附肢、腐蚀之眼、彼岸之物)

`HavenLab_Track.lua`:

- CLEU `SPELL_SUMMON` 且 source 是自己(或 watch 中的坏效果):记 `summons[destGUID] = { spellId, name, spawnT }`。
- 之后任何 `sourceGUID ∈ summons` 的事件计入该召唤物:输出次数、总伤、施放的技能 ID、打的目标。
- `UNIT_DIED`(destGUID ∈ summons)或 60 秒无事件视为消失,记存活时长。
- 报告输出:`召唤 N 只,平均存活 Xs,合计伤害 Y(技能 <id>)`。
- chain `want="summon"` 通过条件:`expect = { minCount=1, dealsDamage=true }`。

注意:触须/眼是服务端 `SummonCreature`,CLEU 里 summoner 可能是玩家也可能是空——**进游戏抓一次真实事件流再定匹配规则**,匹配不上就退化为"按 creature entry 白名单认领"(pack 里写 `summonEntries = {...}`)。

### 3. 按目标分组命中表(暮光 10 目标/半伤、虚空回响半径)

- `HL.stats[id]` 增加 `perTarget[destGUID] = { hits, sum, max, firstT }`。
- 报告新增小节:每目标一行 `目标名 命中n 合计x 单跳最大y 首次命中t`,按 firstT 排序——正好对上 `.labaoe` 一排桩"先后命中"的验法。
- 引擎判定:`expect = { maxTargets = 10, halfFrom = 6 }` → 第 6 个及以后目标的单跳均值应 ≈ 前 5 个的一半(容差 ±15%)。
- UI 不新开大区域,链路面板下放 top 5,完整表进报告。

### 4. 触发率统计(RPPM / ICD)

- chain 里标 `procStep = true` 的那一步,每次发生记时间戳进 `procTimes[packKey]`(上限 200)。
- 派生指标:次数、跨度、**次/分钟**、**最小间隔**(≈ICD)、平均间隔。
- 报告输出一行:`触发 12 次 / 6.5 分钟 = 1.85 次/分,最小间隔 4.1s`。
- 引擎判定(可选):`expect = { minGapMs = 700 }`(虚空回响 ICD)、`{ approxPpm = 1, tolerance = 0.5 }`(暮光)。PPM 只报数不判死,RPPM 吃急速和运气,样本小时只提示"样本不足"。

### 5. 伤害 = 生命百分比校验(暮光 6/12/18%、虚空回响)

- 伤害事件入 stats 时顺带记当时 `UnitHealthMax("player")`。
- `expect = { pctOfMaxHp = 0.06, tolerance = 0.2 }` → 结论输出 `实测 5.9% 生命,期望 6%`。
- 暮光服务端 `TWILIGHT_VISUAL` 已带 `damage=`,labmsg 路径可直接比,战斗记录路径做交叉验证(两边对不上要在结论里点名)。

### 11. 通用 LAB 消息协议 + `.lab` 命令收敛(服务端,和批次一其余同 PR 或紧前)

**协议**(现状已是雏形,补规范):

```
[HavenLab] <TYPE> key=value key=value ...
```

- 插件:`CHAT_MSG_SYSTEM` 过滤器里凡 `^%[HavenLab%] ` 开头的,通用解析成 `rec = { ev="LAB", labType=TYPE, kv={...} }`,进日志并喂给引擎。现有 `STAR_VISUAL` 等专用正则删除。
- 服务端:`spell_corruption.cpp` 把 `NotifyStarVisual/NotifyTwilightVisual/NotifyTwilightHit` 收敛成一个 helper:

```cpp
void LabNotify(Unit* caster, char const* type, std::string const& kv);
// LabNotify(caster, "STAR_VISUAL", Trinity::StringFormat("visual=%u missile=%u", ...));
```

保持只发给 GM 的现有守卫。新效果(回响坍缩、触须出生等)各发一条自己的 TYPE。

**命令收敛**:`cs_misc.cpp` 加 `.lab test <key>`,表驱动:

```cpp
struct LabTestDef { char const* key; std::vector<uint32> removeAuras; uint32 addAura; };
// { "stars", {twilight系+317257}, 317257 }, { "twilight", {stars系+317147}, 317147 },
// 之后 { "echo", ... }, { "appendage", ... } 各加一行
```

`.labstars/.labtwilight` 保留为别名(转调表),插件按钮改发 `.lab test <key>`,pack 数据里带 `serverCmd` 字段。`.labaoe/.labgear` 不动。

**验收**:插件删掉全部专用消息正则后,星/暮光报告不缺信息;`.lab test stars` 与 `.labstars` 行为一致。

---

## 批次二(被动/次级触发、B 坏效果、2a 之前):6、7、8、9

### 6. 属性快照对比

`HavenLab_Track.lua` 增加 `HL:StatSnapshot()`:

| 项 | API(进游戏验证 8.3.7 客户端存在性) |
|----|--------------------------------------|
| 急速 | `GetHaste()` |
| 精通 | `GetMasteryEffect()` |
| 暴击 | `GetCritChance()` |
| 全能 | `GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)` |
| 吸血 | `GetLifesteal()` |
| 闪避(avoidance) | `GetAvoidance()` |
| 攻强/法强 | `UnitAttackPower("player")` / `GetSpellBonusDamage(...)` |

触发时机:

- 手动:UI"记快照"按钮,两次快照出 delta。
- 自动:watch 中光环 `SPELL_AURA_APPLIED`(目标=自己)→ 取事件前最后一次快照 vs 0.1s 后新快照,把 delta 记进该光环的 stats;`REMOVED` 时记实际持续时长。
- chain `want="stat"`:`expect = { stat="haste", minDelta=6 }`(权宜之计 1 = 急速来源 +6%,实测值和来源算法有关,先按"有明显增量"判,数值对齐进各效果的做法文档)。

报告输出:`挂 <id> 后 急速 +6.2%(21.0→27.2),持续 4.0s`。

### 7. 腐蚀值面板(B 系统 / 2a) — **进游戏验收通过**（2026-08-29）

- 数据:`GetCorruption()` / `GetCorruptionResistance()`(8.3 全局 API,**进游戏验证**;不可用则从人物面板 CR 值退化读取,再不行手输)。
- UI:右栏顶部一行 `腐蚀 75 − 抵抗 0 = 有效 75`,变化时写一条日志。
- 阈值矩阵:B 表 5 档(1/20/40/60/80)每档一行 `阈值 | 应挂 | 实挂`。"应挂"= 有效腐蚀 ≥ 阈值;"实挂"= 扫自己光环里对应 aura ID。
- **坏效果 aura ID 现在未知**:pack 数据留 `thresholds = { {1, {光环ID...}}, ... }` 占位,ID 从进游戏 `.lookup spell` + 挂上后 `.debug`/CLEU 抓,抓到填进 [腐蚀特效清单.md](腐蚀特效清单.md) 和这张表。矩阵在 ID 填上前显示"未登记"。

### 8. 穿/脱装备验证(2a/2b 验收核心) — **进游戏验收通过**（2026-08-29）

- 监听 `PLAYER_EQUIPMENT_CHANGED`:记一条 `EQUIP` 日志,内容 = 槽位、物品链接、腐蚀值前后、0.2s 后对比自己光环里 `腐蚀 -` 系(324889 等 pack 登记的外壳 ID)的增减。
- tooltip 扫描:隐藏 tooltip `SetInventoryItem` 逐行找腐蚀字样(全局串 `ITEM_MOD_CORRUPTION` 对应中文"腐蚀"行),显示每件装备的腐蚀值,加总和 `GetCorruption()` 互验。
- 验收即 2a/2b 文档步骤:穿 → 值涨 + 外壳光环上;脱 → 都掉。全程不需要人肉截 buff 栏。

### 9. 移速监控(蔓生触须) — **进游戏验收通过**（2026-08-29）

- 开关式(默认关,面板按钮开):0.2s 轮询 `GetUnitSpeed("player")`,相对基准变化 >3% 记日志 `SPEED 100%→70%,持续 3.4s`。
- 只为 Grasping Tendrils 减速验证;彼岸之物追击不做自动判定(人眼看得见,成本不值)。

---

## 批次三(随时可插,不阻塞任何阶段):10

### 10. 效果总览 / 回归面板 — **进游戏验收通过**（2026-08-29）

- 新窗口(主面板加"总览"按钮):数据源 = `HavenLab_Packs.lua` 注册的全部效果,每行 `效果 | 第0层 | 第1层 | 第2层 | 最后测试时间`。
- 状态**手动勾选**(自动判定不可靠,引擎结论只做参考显示),存 SavedVariables。
- "导出"按钮生成纯文本表,直接贴进 [00-目标.md](00-目标.md) 进度表用。
- 修 A3 前把 A1/A2 重跑一遍勾一遍,就是回归。

---

## 实施顺序与验收

| 步 | 内容 | 验收 |
|----|------|------|
| 1 | 服务端:`LabNotify` helper + `.lab test` 表驱动(11) | `.lab test stars` = `.labstars`;消息格式不变 |
| 2 | 插件:LAB 通用解析(11)+ pack 迁移 + 结论引擎(1) | 星/暮光新引擎报告 ≥ 旧版信息量;假 pack 零代码出结论 |
| 3 | 插件:perTarget(3)+ procTimes(4)+ 生命%(5) | `.labaoe` 打暮光,报告出每桩表和次/分钟 |
| 4 | 插件:召唤跟踪(2) | 先用任意召唤类技能验事件流,规则写死前进游戏抓一次 SPELL_SUMMON 真实参数 |
| 5 | —— A3/A4 开工,用上面能力验收 —— | |
| 6 | 插件:属性快照(6) | `.aura` 权宜之计 1,报告出急速增量 |
| 7 | 插件:腐蚀面板(7)+ 装备验证(8)+ 移速(9) | 2a 测试步骤全程有日志佐证;坏效果 aura ID 回填清单 |
| 8 | 插件:总览面板(10) | 勾选可存档、可导出 |

步 1–4 一起构成"批次一",预计插件侧 2.0 版一次发布;6–9 随被动/B 阶段开工再做,不提前。

## 不做

- 不重写 UI 框架、不换皮;新增区域沿用现有 `Skin/Btn/Label`。
- 不做 DPS 统计(有 Details);不做自动截图;不做 addon message 信道。
- 不做"自动判 PPM 合格":样本量问题,只报数字。
- 不在插件里存任何服务端才有的真相(伤害公式、热修值);期望值全部来自 pack 数据,pack 数据的来源标注在各 `做法-Ax` 文档。

## 风险与待验证

| 项 | 风险 | 兜底 |
|----|------|------|
| `GetCorruption()` 等 API | 8.3.7 客户端可能没有或改名 | 进游戏 `/dump GetCorruption()` 验证;不可用则手输值,矩阵功能保留 |
| SPELL_SUMMON 的 summoner | 触须的 CLEU source 可能不是玩家 | 抓一次真实事件流;退化为 creature entry 白名单 |
| 隐藏光环(317257 系) | `UnitAura` 扫不到,快照/矩阵会误报"没挂" | chain 步骤带 `hidden=true`,判定只信 CLEU 不信 UnitAura |
| 服务端消息节流 | 高频 proc 时每次都发 LAB 消息刷屏 | `LabNotify` 里按 TYPE 做 200ms 合并/计数(需要时再加,先不做) |
---
