# 分类 — BFA 地下城全面修复

初稿已按分类审查 R1 的 Issues Found 改过。分类审查 R2 报告 `_tmp_grok/dungeon-loop-20260930/classify-r2.md` 为 Approved。文件头原先写的「R2 未做。本文不标 Approved」已过时，这里只更正该审查状态。正文其余原子本次不重写，原子边界不改。完成度仍只认写表时的源码和当时活库查询，不认旧百分比，不认「文件在 / AddSC 在」。

底本 `BFA-HavenCore`（8.3.7.35662）。范围地图：1594 暴富矿区、1754 自由镇、1762 诸王之眠、1763 阿塔达萨、1771 托尔达戈、1822 围攻伯拉勒斯、1841 地渊孢林、1862 维克雷斯庄园、1864 风暴神殿、1877 塞塔里斯神庙、2097 麦卡贡行动（垃圾场+车间，史诗 8 遭遇）。旧资料片地下城不扩。本执笔没有看战报录像。视频由 Codex 看；本轮只覆盖冈克若干窗口，其余 10 本没有视频核验。

证据：`_tmp_grok/dungeon-loop-20260930/scan-summary.txt`、`scan-classify-raw.json`、`wire-query.json`。2097 冈克身份另以同目录 `activation-live-db.json` 为准。查询不含连接串。生成加载器 `build/src/server/scripts/gen_scriptloader/static/ScriptLoader.cpp` 第 87 行 `AddKulTirasScripts()`、第 99 行 `AddZandalarScripts()`。这只证明该构建树会链进两个加载器，不证明正在跑的 worldserver 就是这次构建。

## 子系统

1. 进度 / 门 / 传送 / 前置（`instance_*.cpp`，`SetBossNumber` 与遭遇下标一致；禁止用「一王 DONE 就传走全员」冒充进度）。
2. 逐遭遇战斗：进战、事件、阶段、召唤、区域触发、重置、灭团、击杀 `DONE`。双王/议会/红钩与班布里奇按遭遇归并，不按函数拆。
3. 区域小怪与支持 NPC。静态刷点、召唤、召唤组分开。某 entry 静态为 0 不等于要插入 NPC。
4. 物品、机关、GO、载具。
5. 光环、吸收、控制、净化，以及难度分支。枚举里有法术 ID，或 `DoCast` 了，都不证明效果生效。
6. 掉落与奖励（含挑战模式奖励分档，分档存在不等于能打完）。
7. 共享接线：加载器、`instance_template.script`、`creature_template.ScriptName` / 刷点 `creature.ScriptName`、`spell_script_names`、SAI。`AIName=SmartAI` 与 C++ 脚本并存时，`CreatureAISelector.cpp` 先走 `GetCreatureAI`，脚本工厂失败才用 SmartAI。
8. 词缀依赖（单独，不替代 1–6）：`scripts/World/challenge_scripts.cpp` 与 `CastChallengeCreatureSpell`。见 `方案-C-大秘境.md`。

## 管道（11 本共用）

`instance_template` 11 行 script 均对上：`instance_the_motherlode`、`instance_free_hold`、`instance_kings_rest`、`instance_atal_dazar`、`instance_tol_dagor`、`instance_siege_of_boralus`、`instance_the_underrot`、`instance_waycrest_manor`、`instance_shrine_of_the_storm`、`instance_temple_of_sethraliss`、`instance_operation_mechagon`。

库尔提拉斯、赞达拉加载器里，这 11 本的 `AddSC_*` 都有调用。空函数仍被调用的有 `AddSC_freehold`、`AddSC_siege_of_boralus`、`AddSC_tol_dagor`（对应 cpp 扫描 `emptyAdd`）。`operation_mechagon.cpp` 的 `AddSC_mechagon` 是空函数，加载器片段里没有它的调用，不当架构。达萨罗的吉安娜/风暴之墙注释不在本范围。

活库 `creature` / `gameobject` 计数（`wire-query.json` 的 `map_counts`）：

| 地图 | 生物 | GO | 地图 | 生物 | GO |
|---|---:|---:|---|---:|---:|
| 1594 | 591 | 22 | 1841 | 317 | 7 |
| 1754 | 431 | 23 | 1862 | 335 | 33 |
| 1762 | 69 | 6 | 1864 | 415 | 40 |
| 1763 | 368 | 17 | 1877 | 378 | 7 |
| 1771 | 359 | 67 | 2097 | 557 | 3 |
| 1822 | 0 | 0 | | | |

`creature` 有 `spawnDifficulties` 列。本轮落地查询没有 `GROUP BY` 这个字段，不能用它宣布某本有普通/英雄。各本头文件里的 `Is*HeroicPlus` 把难度 2 和 23 当成一组，并写明不是 8。围攻、诸王也用了同一写法。这是脚本分支，不是地图允许难度。`MapDifficulty` 未打开。验收不要给诸王补普通，不要给围攻、麦卡贡补未证实的普通/英雄。麦卡贡按史诗全本 8 遭遇，大秘两翼仍是地图 2097。

`script_coverage`：上述有刷点的图里，模板 `AIName=SmartAI` 的行数等于刷点行数。模板 `ScriptName` 非空的行少得多。刷点自身 `ScriptName` 非空：1754 为 5 行，2097 为 3 行，其余这些图为 0。2097 这 3 行由活库 `activation-live-db.json` 对上：154741、154746、154759 的刷点 ScriptName 都是 `npc_mechagon_squirt_bot`。活库以该文件为准。SQL `2026_09_24_70` / `71` 只是文件名，不代表活库内容。

`boss_` 前缀刷点查询覆盖不到孢林、风暴、阿德里斯/阿斯匹克斯：它们用 `new bfa_boss_*`（`CreatureScript("bfa_...")`）。不能把「查询结果里没有」写成「图上没有王」。

`RegisterSpellScript` / `RegisterAuraScript` 46 个符号里，库缺 `spell_freehold_rat_traps`、`spell_freehold_rummy_brew`。`bfa_spell_*` 旧式 `new` 不在这 46 个里，库绑定未查。挑战模式 `ChallengeModeMgr::GetCAForLoot` 的 `switch` 含全部 11 个 map，只说明奖励分档表写了这些图。

扫描里的 `cases=0` 且 `ScheduleEvent>0`，多半是 `ExecuteEvent` 没被解析到（`DoCastSelf` / `DoCastRandom` 也不计成 `DoCast(`）。只有亲自打开的文件才写具体函数。扫描写出的 `NOJUSTDIED` / `NORESET` 只表示该结构没 override 这两个函数，须查继承，不能据此写成基类没有收尾。

## 原子表

列：已核 = 当前文件或活库能直接对上的事。不足 = 还不能当 blizzlike。证据 = 下一阶段用本地 DB2 / 战报能继续、且本轮没做完的项。缺证 = 要进客户端或另查的项。模块只建议顺序。`*-TRASH` 里的 SAI 抽样桶不是一条实施原子。

### 1594 暴富矿区

| ID | 对象 | 代码家 | 已核 / 不足 / 证据 / 缺证 |
|---|---|---|---|
| DUN-1594-GATE | 进度 | `instance_the_motherlode.cpp`：`SetBossNumber(EncounterCount)`，`OnCreatureCreate` 只存四只 GUID。头文件遭遇 0–3。文件头注释 `//Missing scripts` | 已核：无门表，不传送。不足：进度家是架子。模块 M3，中。证据：门 GO、击杀后的通路。缺证：客户端门与首领框 |
| DUN-1594-PUMM | 投币人群殴打者 | `boss_coin_operated_crowd_pummeler.cpp`；活库 129214，`boss_Coin_operated_crowd_pummeler`，刷点 1 | 已核：有刷点、加载器调用。不足：约 180 行，机制未逐技能对。证据：DB2 与战报技能。缺证：未进游戏、无视频 |
| DUN-1594-AZER | 艾泽洛克 | `boss_azerokk.cpp`；头文件 `NPC_AZEROKK=129227` | 已核：cpp 在，加载器调用。`boss_` 刷点结果里 1594 只有 129214/129231/129232。不足：129227 没有单独计数。证据：按 entry 查刷点与 ScriptName。缺证：是否召唤、客户端 |
| DUN-1594-RIXXA | 里克莎 | `boss_rixxafluxflame.cpp`；129231 刷点 1 | 已核：有刷点。不足：文件约 157 行，扫描不能证明技能生效。证据：DB2/战报。缺证：客户端 |
| DUN-1594-MOGUL | 大亨拉兹敦克 | `boss_mogulrazdunk.cpp`；129232 刷点 1 | 已核：有刷点。扫描 178 行，`cases=0`，cast 计数 0。cast 计数不含 `DoCastSelf`。不足：钻机阶段未在本轮逐函数读，扫描计数不能当成没有技能。证据：阶段与载具法术。缺证：客户端 |
| DUN-1594-TRASH | 小怪 | `the_motherlode.cpp` 约 40 行，1 个 Register | 已核：591 生物里多数只能落到 SmartAI。不足：C++ 小怪家很薄，SAI 质量未读。SAI 抽样桶，不是一条实施原子。证据：抽一条路线的 SAI 与法术。缺证：客户端清怪 |
| DUN-1594-GO | 机关/GO | 活库 GO 22 行、6 个 entry | 已核：有物体。不足：脚本未对到 entry。证据：GO ScriptName。缺证：客户端能否交互 |
| DUN-1594-LOOT | 掉落 | 四王模板不在 `named_entries` 清单 | 不足：本轮没数到 loot 行。证据：`creature_loot_template` 按 129214/129227/129231/129232。缺证：包内物品 |

### 1754 自由镇

| ID | 对象 | 代码家 | 已核 / 不足 / 证据 / 缺证 |
|---|---|---|---|
| DUN-1754-GATE | 进度与入口传送 | `instance_freehold.cpp` 的 `OnPlayerEnter`；`npc_free_hold_entrance_teleporterAI::UpdateAI` | 已核：`SetBossNumber(DataMaxEncounters)`，下标从 `DataSkycapKragg` 起，4 个遭遇。传送只在 8 码内、且是团队或 GM 时，在 1643 与 1754 之间对传。不足：这不是首领进度门。`方案-自由镇.md` 是旧任务单，不证明已做完。模块 M3。证据：普通小队入口。缺证：客户端传送是否误触发 |
| DUN-1754-KRAGG | 克拉格 | `boss_skycapn_kragg.cpp`；126832 刷点 1，`boss_skycap_kragg` | 已核：有刷点。不足：俯冲、鲨鱼 126841（全库刷点 0，属召唤/载具）未重读。证据：座骑与英雄分支法术。缺证：客户端 |
| DUN-1754-COUNCIL | 船长议会 | `boss_council_o_captains.cpp`；126845/126847/126848 各刷点 1，脚本 `boss_council_captain` | 已核：三船长同一遭遇数据槽。不足：友好船长周事件只看到枚举 `FreeholdCrewWeek`，行为未重读。证据：周次与 257821。缺证：客户端谁敌对 |
| DUN-1754-RING | 环赌（特罗萨克） | `boss_ring_of_booty.cpp`；126969 刷点 1 | 已核：文件约 1098 行且加载。不足：扫描标过该结构没有进战函数，大文件不能因此判空，也不能判完成。证据：鱼饵、双龟、抛鲨。缺证：客户端 |
| DUN-1754-HARLAN | 哈兰 | `boss_harlan_sweete.cpp`；126983 刷点 1 | 已核：有刷点。不足：未逐技能读。证据：DB2/战报。缺证：客户端 |
| DUN-1754-TRASH | 小怪 | `freehold.cpp` 的 `AddSC_freehold` 为空且被调用 | 已核：空壳。刷点级 ScriptName 有 5 行（字符串未打出）。不足：小怪不在这个空文件里。SAI 抽样桶，不是一条实施原子。证据：那 5 行 ScriptName 与 SAI。缺证：客户端 |
| DUN-1754-BUFF | 法术脚本接线与三酒/陷阱效果 | `spell_script_names`；`npc_rummy_mancomb`；两类DUMMY脚本 | 2026-10-01增量：注册/loader及仓库09-08绑定SQL存在；14:09只读活库八技能正负绑定均0，指定更新记录0。133219已有模板脚本与刷点；正常挑战实际23可通过2/23谓词，不能仅没8判正常大秘不启动。130404 SAI→274383普通SELF起施已获当前库正向，非缺NPC。DB2三酒光环3码、DUMMY候选100码；当前6码资格后逐目标自施形成多中心且改变归属。独立WCL约3秒读条/5秒cast后apply/8秒开始间隔、来源Rummy；主代理已亲看历史+25高清及Nerftank+28的1080p船长战样本，分别未匹配本地同场WCL，不强行对时。15:06 fresh SELECT仍四模板/四刷点、八绑定0及旧更新记录0；本期不增删NPC、不应用旧绑定SQL。R1数据review通过，R2六题及R3数据/视觉/个人看片已落盘，新增证据独立复核已通过（限定研究范围）；限定三酒施法生命周期架构/总纲/模块各两轮通过，Task0/1真实编译及Task0/1/2各独立复审、单轮静态集成复核已通过；正常读条/按begin约8秒单链/同步停止与状态GUID接线代码完成。纯观察包已镜像，Packs两端691E8AC2…；Runtime及M01–M16全待游戏，不是完整BUFF完成。证据：`codex-freehold-buff-r1-data.md`、`codex-freehold-buff-live-data.json`、`codex-freehold-buff-r3-data.md`、`codex-freehold-buff-r3-video.md`、`codex-freehold-trap-r3-visual.md`。阶段证据：`复核-自由镇三酒施法生命周期.md`、`codex-freehold-cast-integration-review.md`、`codex-freehold-nerftank-wcl-match.md`。仍缺：酒历史点名/锁点/约5秒具体机制、trap部署/触碰/寿命、运行加载及客户端验收；不猜半径、不补NPC |
| DUN-1754-LOOT | 掉落/GO | GO 23 行、19 entry。扫描 NOLOOT：126845、126847、126848 的 `loot_rows=0` | 已核：三船长 loot 为 0 行。不足：议会箱继续缺证。证据：史诗坐骑条件与议会箱 entry。缺证：客户端开箱 |

### 1762 诸王之眠

允许难度未用 DB2 钉死。头文件助手含难度 2 和 23。不要加普通难度的验收。

| ID | 对象 | 代码家 | 已核 / 不足 / 证据 / 缺证 |
|---|---|---|---|
| DUN-1762-GATE | 进度槽 | `kings_rest.h`：`EncounterCount=5`，`DATA_GOLDEN_SERPENT=1` 起，到 `DATA_DAZAR`。`instance_kings_rest` 只 `LoadObjectData` | 已核：与头文件一致。4 个王用槽 1–4，蛇从 1 起，槽 0 没有王。阿塔达萨头文件写明额外数据禁止 `SetBossState`，诸王没有这种隔离。不足：槽 0 空着。会不会因此无法完成，未查 core 完成算法，保持风险。「永远打不完」未证死。模块 M2，高。证据：完成掩码与宝箱条件。缺证：客户端首领框数量 |
| DUN-1762-SERP | 黄金蛇 | `boss_the_golden_serpent.cpp`；`boss_golden_serpent::EnterCombat`；135322 刷点 1，loot 8 行 | 已核：会排 4 个事件，文件约 104 行。不足：注释写明计时未按 8.3 EventMap 核。`EnterEvade` 未在本轮看完。证据：地面金水 AT。缺证：客户端 |
| DUN-1762-MCH | 穆钦巴 | `boss_mchimba::ExecuteEvent`；`EnterEvadeMode` 只 `MoveTargetedHome`；`aura_drain_fluids`。134993 刷点 1，loot 7 | 已核：埋葬、燃烧、抽干会放；抽干移除时上干燥。`aura_drain_fluids` 不在两个缺失脚本名里。不足：脱战路径本轮只看到 `MoveTargetedHome`。燃烧地面 AT 只在枚举里。证据：267702 与 GO 效果。缺证：客户端棺椁 |
| DUN-1762-COUNCIL | 部族议会 | `boss_council_of_tribe.cpp`；库拉 135475 刷点 1、loot 0；阿卡阿里 135470、赞纳扎尔 135472 刷点 0（后者 loot 也是 0，前者 loot 8） | 已核：静态只有库拉。头文件有三人 entry。一场一条。不足：另外两人是死亡链召唤还是漏刷，本轮没重读 `JustDied`。不要补三只静态。模块 M3。证据：召唤行与 loot 该记在谁身上。缺证：客户端同时存在几人 |
| DUN-1762-DAZAR | 达萨尔 | `boss_dazar.cpp`；`npc_shadow_of_zul::ExecuteEvent`（在 `instance_kings_rest.cpp`）。136160 刷点 1，loot 0 | 已核：有刷点、无 loot 行。祖尔阴影的 `EVENT_SHADOW_BARRAGE` 带 `/* fallthrough */`，会落入黑暗启示并召唤。现象属实。是否删掉这段保持未证。不足：尾王战斗和掉落都未闭合。证据：loot 是否在别的 entry；祖尔 138489 刷点。缺证：客户端 |
| DUN-1762-GO | 宝箱 | `OnGameObjectCreate` 给议会宝箱和首王恩惠加 `GO_FLAG_LOCKED` | 已核：创建时上锁，这个文件里没有开锁。GO 共 6 行。不足：击杀与开箱未接。证据：GO entry 与条件。缺证：客户端锁 |
| DUN-1762-TRASH | 小怪 | 无单独 trash cpp。生物 69 行、29 entry | 已核：数量少，且全是 SmartAI 模板。不足：C++ 家只有祖尔阴影。SAI 抽样桶，不是一条实施原子。证据：SAI 抽样。缺证：客户端 |

### 1763 阿塔达萨

| ID | 对象 | 代码家 | 已核 / 不足 / 证据 / 缺证 |
|---|---|---|---|
| DUN-1763-GATE | 进度 | `atal_dazar.h` 遭遇 0–3，`EncounterCount=4`；成就数据明确禁止 `SetBossState`。`instance_atal_dazar.cpp` 约 234 行，扫描 `door=0`、`tp=0` | 已核：槽位写法是这 11 本里较清楚的一份。扫描 door=0、tp=0。模块 M4，低到中。证据：门 GO 若在数据里。缺证：客户端 |
| DUN-1763-ALUNZA | 阿伦扎 | `boss_priestess_alunza.cpp`；122967 刷点 1 | 已核：有刷点，文件约 667 行。不足：未证明血池/献祭效果。证据：AT 与战报。缺证：客户端 |
| DUN-1763-VOLKAAL | 沃卡尔 | `boss_volkaal.cpp`；122965 刷点 1 | 已核：有刷点。不足：图腾复活未重读。证据：图腾 entry 与脚本。缺证：客户端 |
| DUN-1763-REZAN | 莱赞 | `boss_rezan.cpp`；122963，脚本 `boss_ataldazar_rezan`，刷点 1 | 已核：有刷点。不足：未逐技能读。证据：DB2/战报。缺证：客户端 |
| DUN-1763-YAZMA | 亚兹玛 | `boss_yazma.cpp`；122968，`boss_ataldazar_yazma`，刷点 1 | 已核：有刷点。不足：旧线索里的蓝量事件本轮未重读，不能沿用「非 blizzlike」当结论。证据：能量与蜘蛛召唤。缺证：客户端 |
| DUN-1763-TRASH | 小怪/GO | `atal_dazar.cpp` 约 236 行、3 个 Register。GO 17/16 | 已核：有一份 C++ 小怪文件。不足：内容未读。SAI 抽样桶，不是一条实施原子。证据：SAI 与 GO。缺证：客户端 |
| DUN-1763-LOOT | 掉落 | 四王不在 loot 清单 | 证据：四 entry 的 loot 行。缺证：包 |

### 1771 托尔达戈

| ID | 对象 | 代码家 | 已核 / 不足 / 证据 / 缺证 |
|---|---|---|---|
| DUN-1771-GATE | 进度 | `tol_dagor.h` 遭遇 0–3。`instance_tol_dagor.cpp` 约 48 行，扫描 `door=1` | 已核：槽位数是 4。不足：门表内容未摘。模块 M4。证据：门 GO 与解锁。缺证：客户端监狱门 |
| DUN-1771-SAND | 沙后 | `boss_the_sand_queen.cpp`；127479 刷点 1 | 已核：有刷点。扫描旗标 NOJUSTDIED、NORESET。须查继承。证据：流沙 AT。缺证：客户端 |
| DUN-1771-JES | 杰斯 | `boss_jes_howlis.cpp` 约 154 行；127484 刷点 1 | 已核：有刷点。扫描旗标 NOJUSTDIED。须查继承。不足：短文件。证据：囚犯/钥匙。缺证：客户端 |
| DUN-1771-VALYRI | 瓦莉 | `boss_knight_captain_valyri.cpp`；127490 刷点 1 | 已核：有刷点。扫描旗标 NOJUSTDIED、NORESET。须查继承。扫描有 TODO。不足：弹药桶未读。证据：GO 与引信法术。缺证：客户端 |
| DUN-1771-KORGUS | 科格斯 | `boss_overseer_korgus.cpp`；127503 刷点 1 | 已核：有刷点。扫描旗标 NOJUSTDIED、NORESET。须查继承。扫描有 TODO。不足：火炮配置未读。证据：难度分支武器。缺证：客户端 |
| DUN-1771-TRASH | 小怪空壳 | `tol_dagor.cpp` 的 `AddSC_tol_dagor` 为空且被调用 | 已核：空壳，单独成行。 |
| DUN-1771-GO | 狱门、炮台、GO | 活库 GO 67 行、52 entry | 证据行，不是一条实施原子。已核：11 本里 GO 行数最多。不足：狱门、炮台与 GO ScriptName 未摘。证据：GO ScriptName。缺证：客户端开门、炮台 |
| DUN-1771-LOOT | 掉落 | 四王 loot 未计入清单 | 证据：四 entry。缺证：包 |

### 1822 围攻伯拉勒斯

全图生物 0、GO 0（`map_counts` 显式计数）。模板和掉落还在，世界没有落点。这不是「把 MDT 名单插成静态 NPC」。召唤（例如洛克伍德文件里扫描到的召唤次数）和静态世界分开。允许难度未钉死，不要加普通/英雄验收。

| ID | 对象 | 代码家 | 已核 / 不足 / 证据 / 缺证 |
|---|---|---|---|
| DUN-1822-WORLD | 空世界 | 无刷点可对。`siege_of_boralus.cpp` 的 `AddSC_siege_of_boralus` 为空且被调用 | 已核：creature=0，gameobject=0。模块 M1，高。不足：脚本家不能代替坐标。证据：哪几只是静态、哪几只是召唤、阵营各用哪套。缺证：客户端进门看到的空图 |
| DUN-1822-GATE | 进度与阵营 | `EncounterCount=5`：红钩 0、班布里奇 1、洛克伍德 2、哈达尔 3、维克戈斯 4。`OnPlayerEnter` 空。`blood_in_the_water::OnUpdate` 只处理区域 9354 的水中秒杀 | 已核：两个阵营首领占了两个 BossState。进本函数没有选边，也没有把另一边标 DONE。不足：一场若只打一个首任首领，5 个槽如何算打完，未证。水中脚本是玩家脚本，不是门。证据：完成条件与阵营。缺证：客户端阵营路线 |
| DUN-1822-FIRST | 红钩 / 班布里奇 | 同文件 `boss_chopper_redhook.cpp`：`boss_chopper_redhook` 与 `boss_sergeant_bainbridge`（约 216 行注册）。128650 loot 9、128649 loot 10，刷点都是 0 | 已核：两个脚本名都在模板上，全库无刷点。约定一场一条，变体仍是两套 AI。证据：谁召唤谁、坐标从哪来。缺证：客户端 |
| DUN-1822-LOCK | 洛克伍德 | `boss_dread_captain_lockwood.cpp`；129208 loot 10，刷点 0 | 已核：无静态点。扫描有传送计数。不足：甲板上的召唤怪不能在 0 生物的图里对坐标。证据：召唤 entry 与静态需求分开列。缺证：客户端船 |
| DUN-1822-HADAL | 哈达尔 | `boss_hadal_darkfathom::ExecuteEvent` 排了破水、崩潮、潮涌。128651 loot 7，刷点 0 | 已核：三个事件都会 `DoCast`。潮涌的 AT 法术只在枚举（276039 等），本文件没有 `RegisterAreaTriggerAI`。`const Position pos` 是空的。不足：有三个技能 ID，AT 未接；人也没刷出来。证据：AT 脚本该住哪。缺证：客户端水面 |
| DUN-1822-VIQ | 维克戈斯 | `boss_viqgoth.cpp`；128652 loot 9，刷点 0 | 已核：文件约 378 行，无刷点。炮台等脚本名在零刷点清单里（动态候选，不是补静态的理由）。证据：船底遭遇如何生成。缺证：客户端 |
| DUN-1822-LOOT | 掉落 | 上列模板已有 loot 行 | 已核：掉落表不是 0。不足：没有生物就没有击杀。证据：难度条件。缺证：包 |

### 1841 地渊孢林

| ID | 对象 | 代码家 | 已核 / 不足 / 证据 / 缺证 |
|---|---|---|---|
| DUN-1841-GATE | 进度与召唤组 | `instance_the_underrot.cpp`；`SummonCreatureGroup`。活库 `creature_summon_groups`：`summonerType=2,summonerId=1841,groupId=1` 共 4 行。头文件遭遇 0–3；5–8 号数据注明不要 `SetBossState` | 已核：有一组地图召唤，不是静态漏刷。槽位 4 与额外数据分开。不足：门未摘。模块 M4。证据：组内 entry。缺证：客户端这 4 只何时出现 |
| DUN-1841-LEAXA | 利克萨 | `boss_elder_leaxa.cpp`，`new bfa_boss_elder_leaxa()` | 已核：加载器调用，旧式注册，文件约 549 行，含 `bfa_spell_taint_of_ghunn`。不足：`boss_` 查询看不到她的刷点。证据：ScriptName=`bfa_boss_elder_leaxa` 的刷点与 `spell_script_names`。缺证：客户端 |
| DUN-1841-CRAG | 克雷格玛 | `boss_cragmaw_infested.cpp`，含 `bfa_at_cragmaw_charge` | 已核：有 AT 类并 `new`。不足：刷点与法术 ID 绑定未查。证据：同上。缺证：客户端冲锋 |
| DUN-1841-ZANCHA | 赞查 | `boss_sporecaller_zancha.cpp`，豆荚与 `bfa_spell_upheaval` | 同利克萨。证据：豆荚是召唤还是刷点。缺证：客户端 |
| DUN-1841-UNBOUND | 无缚畸变怪 | `boss_unbound_abomination.cpp`，含看守赫兹莱尔 | 已核：赫兹莱尔在数据枚举里禁止当 BossState。不足：剧情 NPC 与战斗未读完。证据：赫兹莱尔刷点。缺证：客户端 |
| DUN-1841-TRASH | 小怪/GO | `the_underrot.cpp` 约 149 行。GO 7 | 已核：有薄 C++。不足：317 个生物的 SAI 未读。SAI 抽样桶，不是一条实施原子。证据：SAI 抽样。缺证：客户端 |
| DUN-1841-LOOT | 掉落 | 本本没有掉落行。王用 `bfa_` 注册，不在 `boss_` 刷点结果里 | 未知。loot 未查，未证。不填行数。 |

### 1862 维克雷斯庄园

| ID | 对象 | 代码家 | 已核 / 不足 / 证据 / 缺证 |
|---|---|---|---|
| DUN-1862-GATE | 进度 | `waycrest_manor.h` 遭遇 0–4，`EncounterCount=5`。`instance_waycrest_manor.cpp` 约 44 行，扫描 `door=1` | 已核：5 个槽与 5 场对齐。不足：门内容未摘。模块 M4。证据：门与楼层。缺证：客户端 |
| DUN-1862-TRIAD | 毒心三姐妹 | `boss_heartsbane_triad.cpp`；131823/131824/131825 各刷点 1，同一脚本 | 已核：三只都在图上，一场一条。不足：焦点转移未重读。证据：战报同时存活。缺证：客户端 |
| DUN-1862-GOL | 缚魂巨像 | `boss_soulbound_goliath.cpp`；131667 刷点 1 | 已核：有刷点。不足：约 192 行。证据：燃烧荆棘。缺证：客户端 |
| DUN-1862-RAAL | 拉尔 | `boss_raal_the_gluttonous.cpp`；131863 刷点 1 | 已核：有刷点，扫描有传送。不足：宴席/小鸡未读。证据：召唤 entry。缺证：客户端 |
| DUN-1862-LORD | 韦克雷斯夫妇 | `boss_lord_and_lady_waycrest.cpp`；131527 与 131545 各刷点 1，同一脚本 | 已核：两人同一遭遇。不足：阶段未读。证据：战报。缺证：客户端 |
| DUN-1862-GORAK | 高莱克·图尔 | `boss_gorak_tul.cpp` 约 177 行；131864 刷点 1 | 已核：有刷点，会排 3 个事件。不足：短。证据：灵体与仪式。缺证：客户端 |
| DUN-1862-TRASH | 小怪/GO | `waycrest_manor.cpp` 约 316 行、6 个 Register。GO 33/19 | 已核：小怪 C++ 比空文件厚，内容未读。SAI 抽样桶，不是一条实施原子。证据：SAI 与巫术 GO。缺证：客户端 |

### 1864 风暴神殿

| ID | 对象 | 代码家 | 已核 / 不足 / 证据 / 缺证 |
|---|---|---|---|
| DUN-1864-GATE | 进度 | `shrine_of_the_storm.h` 遭遇 0–3；另有 `DATA_INSTANCE_ENTER` 等非首领下标。实例约 68 行，扫描无门 | 已核：首领槽是 4。不足：进本数据与门未读。模块 M4。证据：仪式门。缺证：客户端 |
| DUN-1864-AQUSIRR | 阿库希尔 | `boss_aqusirr.cpp`，`bfa_boss_aqusirr` | 已核：旧式注册，加载器调用，约 541 行。不足：刷点要按 `bfa_` 名再查。文件里有 `Yell` 计数。证据：ScriptName 与水元素召唤。缺证：客户端 |
| DUN-1864-COUNCIL | 海贤议会 | `boss_tidesage_council.cpp`：`bfa_boss_brother_ironhull`、`bfa_boss_galecaller_faye` | 已核：两个脚本、一场一条。不足：同阿库希尔，刷点未在 `boss_` 查询里。证据：两 entry。缺证：客户端 |
| DUN-1864-SONG | 斯托颂勋爵 | `boss_lord_stormsong.cpp`，`bfa_boss_lord_stormsong` | 同议会。证据：虚空唤醒。缺证：客户端 |
| DUN-1864-VOLZ | 沃尔兹斯 | `boss_volzith_the_whisperer.cpp`，含触须/深渊显化 | 已核：约 950 行，仍是旧式 `Yell` 风格。不足：行数多不等于效果对。证据：阶段法术与 `spell_script_names`。缺证：客户端 |
| DUN-1864-TRASH | 小怪/GO | `shrine_of_the_storm.cpp` 约 211 行、4 个 Register。GO 40/10。生物 415 | 已核：有 C++ 小怪注册。不足：未读。SAI 抽样桶，不是一条实施原子。证据：SAI。缺证：客户端 |
| DUN-1864-LOOT | 掉落 | 本本没有掉落行。王用 `bfa_` 注册，不在 `boss_` 刷点结果里 | 未知。loot 未查，未证。不填行数。 |

### 1877 塞塔里斯神庙

| ID | 对象 | 代码家 | 已核 / 不足 / 证据 / 缺证 |
|---|---|---|---|
| DUN-1877-GATE | 进度 | 头文件遭遇 0–3。实例约 77 行，扫描 `door=1` | 已核：4 槽。不足：门未摘。模块 M4。证据：桥与电门。缺证：客户端 |
| DUN-1877-ADDER | 阿德里斯与阿斯匹克斯 | `boss_adderis_and_aspix.cpp`：`bfa_boss_adderis`、`bfa_boss_aspix` | 已核：两个旧式脚本、一场一条。不足：不在 `boss_` 刷点结果里。证据：两 entry 的刷点。缺证：客户端换位 |
| DUN-1877-MEREK | 米利克萨 | `boss_merektha.cpp` 约 166 行；133384 刷点 1 | 已核：有刷点，扫描有传送。不足：短，潜沙/蛋未读。证据：召唤。缺证：客户端 |
| DUN-1877-GALV | 加瓦兹特 | `boss_galvazzt.cpp` 约 185 行；133389 刷点 1 | 已核：有刷点。不足：挡电未在本轮重读，旧结论作废为「未证」。证据：能量与梁。缺证：客户端 |
| DUN-1877-AVATAR | 塞塔里斯的化身 | `boss_avatar_of_sethraliss.cpp`；133392 刷点 1 | 已核：有刷点，约 514 行。不足：治疗/激活阶段未读。证据：战报。缺证：客户端 |
| DUN-1877-TRASH | 小怪/GO | `temple_of_sethraliss.cpp` 约 93 行。GO 7。生物 378 | 已核：薄。SAI 抽样桶，不是一条实施原子。证据：SAI 与蛇群。缺证：客户端 |
| DUN-1877-LOOT | 掉落 | 本本没有掉落行。阿德里斯/阿斯匹克斯用 `bfa_` 注册，不在 `boss_` 刷点结果里 | 未知。loot 未查，未证。不填行数。 |

### 2097 麦卡贡行动（垃圾场 0–3，车间 4–7）

`operation_mechagon.h`：`EncounterCount=8`，与八场下标一致。`instance_mechagon.cpp` 的 `OnPlayerEnter` 只创建介绍对话。扫描 `door=1` 来自整段注释里的空门表，占位为空、未接线。活库 GO 只有 3 行。翼之间没有门数据。垃圾场：戈巴马克、冈克、崔克茜与纳诺、HK-8。车间：斗殴机兵、K.U.-J.0.、机械师乐园（斯帕克斯）、麦卡贡国王。

| ID | 对象 | 代码家 | 已核 / 不足 / 证据 / 缺证 |
|---|---|---|---|
| DUN-2097-GATE | 两翼进度 | `instance_operation_mechagon`，地图 2097 | 已核：8 个槽都有名字。扫描 door=1 是注释空门表，占位为空、未接线。不足：几何上能否直接走到车间，未进游戏。模块 M3，高。证据：翼入口 GO/载具。缺证：客户端两翼 |
| DUN-2097-GOBBA | 戈巴马克 | `boss_king_gobbamak.cpp`；150159 刷点 1，loot 18 | 已核：有刷点。不足：未逐技能读。「它是冈克解除免疫的前置」已删除。余下技能仍未逐条核实。证据：战报。缺证：客户端 |
| DUN-2097-GUNKER-BIND | 冈克身份、激活、重置 | 状态只跟踪，方案由另一作者写。代码：`boss_gunker.cpp`、`squirt_lifecycle.h`。账本：`进度-BFA地下城全面修复.md`。已有复核：`复核-冈克机器人生命周期-20260924.md`。账本预定产物 `调研-BFA地下城-冈克完整机制.md`（本文件不代写、也不判断它是否写完）。SQL 文件只留名：`sql/updates/world/2026_09_24_70_world_guid26_isolate_squirt_scriptname.sql`、`2026_09_24_71_world_gunker_squirt_static_ai.sql`。活库不从这两份 SQL 推断 | 已核：活库 `activation-live-db.json` 的身份是 6 行，不加 NPC。三对为 154741 与 154744、154746 与 150168、154759 与 154758。三只机器人刷点 ScriptName=`npc_mechagon_squirt_bot`，模板 ScriptName 为空。三对身份和 SAI 已确定；该查询中的 SAI 在毒体 150168、154744、154758。150222 刷点 1，模板 ScriptName=`boss_gunker`，不计入这 6 行。`AddSC_boss_gunker` 注册王和 `npc_mechagon_squirt_bot`，没有把机器人再召唤一份。戈巴马克 DONE 前置已删除：现行 `MoveInLineOfSight` 不再因戈巴马克摘 300859。本阶段代码、构建与 Task1/2/3 独立审查通过，待进游戏验收，见 `复核-冈克机器人释放与激活.md`。已 DONE 则脱战直接返回。不足：P0 只验收绑定、召唤次数、激活、重置。模块 M0，高。证据与方案走另一作者。缺证：本执笔无录像 |
| DUN-2097-GUNKER-FX | 冈克 Goop、喷雾、路径 | 当前填现有boss_gunker.cpp；既有298124机器人精确救援代码/构建/独立静态集成通过，完整FX仍未完成 | 最新2026-10-01：原WCL两缓存仅1独立样本，2026-10-01新会话追加5真实events窗口共71684条、玩家298259正向施加已见，独立事实核查中；天然过滤器/玩家双Aura仍未定；主代理亲看击杀后30连续帧仍活Goop，不支持全图强清。默认同summoner两次回收在drain前可重复选已排队A而漏B，玩家逐Aura捕获/refresh的R3源码边界已查明，精确关联架构原稿R1 Approved、R2唯一登出时序I1纠正后定点Approved；总纲两独立轮Approved，唯一玩家关联模块正在执笔，模块审查/实施尚未开始；本地EJ与Spell原文补证基本玩家击破救援，未证dual/multi-last/timeout。16:03活库三bot刷点AI已有，153377模板ScriptName空、7法术正负映射0；无SQL应用/部署/运行验收，本波不加删NPC。R2仅接受限定研究，非实施批准；新证据与未决见调研-冈克喷雾与粘液效果.md增量及codex-gunker-lifecycle-research-r2.md。喷雾保护、官方路径、完整重置/能量/生命/奖励继续未修或未决 |
| DUN-2097-TRIXIE | 崔克茜与纳诺 | `boss_trixie_naeno.cpp`；150712 loot 0 刷点 1，153755 loot 18 刷点 1，153756 机车 loot 0 刷点 1 | 已核：两人一车都有静态点，同一脚本。不足：载具阶段未读。证据：谁该有 loot。缺证：客户端车 |
| DUN-2097-HK8 | HK-8 | `boss_hk_8_aerial_opression_unit.cpp`。150190 脚本 `boss_hk_8`，刷点 0，loot 19 | 已核：空中单位无静态行。文件里另一个结构有 `ScheduleEvent`，名为 `boss_hk_8` 的进战扫描未排事件。不足：静态 0 是召唤候选，不是补一只 150190 的指令。证据：中心桩谁召唤它。缺证：客户端 |
| DUN-2097-TONKS | 斗殴机兵 | `boss_tusle_tonks.cpp`；144244 与 145185 各刷点 1，脚本 `boss_tusle_tonks` | 已核：两只都在图上，一场一条。145185 的 `loot_rows=0`。144244 不在 NOLOOT 清单里，本行不补它的行数。不足：约 226 行，扫描有 TODO。证据：载具与电击。缺证：客户端 |
| DUN-2097-KUJO | K.U.-J.0. | `boss_kujo.cpp` 约 137 行；144246 刷点 1 | 已核：有刷点，扫描有 4 个事件。不足：短。证据：坦克杀手是否召唤（150295 在零刷点清单，属动态）。缺证：客户端 |
| DUN-2097-SPARK | 斯帕克斯 | `boss_head_machinist_sparkflux::EnterCombat/ExecuteEvent`；144248 刷点 1，loot 21。注册名与模板 ScriptName 一致 | 已核：进战 `DoCastSelf(295065)` 上能量。火炮要能量 100 才排程。同文件 `JustDied` 有 `DoModifyPlayerCurrencies(1553, 35)`。植物、修剪、DISCOM 会排进事件。不足：能量、火炮、货币效果未证。AT/植物 NPC 是否激活未证。证据：152033 与 AT。缺证：客户端草 |
| DUN-2097-KING | 麦卡贡国王 | `boss_king_of_mechagon.cpp`；150397 刷点 1 | 已核：文件约 432 行；同文件另有结构在进战时 `ScheduleEvent`。名为 `boss_king_mechagon` 的那一个结构扫描为 0 次 `ScheduleEvent`。不足：阶段拆在多个结构里，未读完，不能写成整场没技能，也不能写成已完成。证据：战报阶段。缺证：客户端 |
| DUN-2097-GO | 机关 | GO 3 行。`npc_transport_mechagon` 等在零刷点清单 | 已核：物体极少。不足：翼间载具/传送未接成进度。证据：3 个 GO entry。缺证：客户端 |
| DUN-2097-TRASH | 小怪 | 557 生物、118 entry；模板脚本行只有 20 | 已核：多数是 SmartAI。不足：SAI 未读。SAI 抽样桶，不是一条实施原子。证据：抽样。缺证：客户端 |

## 类似修复（线索，不是完成证明）

- `方案-自由镇.md`、`方案-B-五人本.md`：旧任务单。B 的顺序是孢林/塞塔里斯/自由镇，盖不住 11 本，也不能证明现状。
- `复核-11五人本NPC-战报修复-20260924.md`：刷点线索。1822 为 0 已由本轮 `map_counts` 再次数到。
- `复核-冈克机器人生命周期-20260924.md`：只说明当时做了局部生命周期。
- 腐蚀 `做法-A*`、尼奥罗萨传送反例：风格参照，不是五人捐赠。

## 捐赠与不要去

总览没有第二套更满的 8.3 五人脚本。家在 Haven 现有文件里补。

| 用途 | 主源 | 不要去 |
|---|---|---|
| 这 11 本战斗 | Haven 已有 cpp | 把 Reforged 当另一套实现（扫描体积同构） |
| 空 `AddSC` | 标空壳 | AshamaneBFA：43 个抽样 cpp 里 35 个空壳。孢林有肉，但短于 Haven，不覆盖 |
| 麦卡贡后半 | 没有做完的开源端 | Boralus/MTT 只有戈巴马克+冈克薄文件。不要指望脚本 |
| 8.3 数字 | 35662 DB2、活库、战报 | 12x 里虽有神殿/庄园/阿塔/诸王/孢林文件，只可对存在性，不作 8.3 战斗源 |
| 4.x–7.x、TrinityCore837 | 这些根下没有这 11 本目录 | 不要去找 BFA 地下城脚本 |
| 词缀 | 军团挑战框架 + Haven 已注释的 `challenge_scripts.cpp` | 不要把词缀写进每个王 |

## P0 顺序

1. `DUN-2097-GUNKER-BIND`：第一批只保留这一原子。验收只到绑定、召唤次数、激活、重置。`DUN-2097-GUNKER-FX` 不进第一批。实施与方案归另一作者；本表只留状态和链接。
2. `DUN-1822-WORLD` 然后 `DUN-1822-GATE`：图是空的，且 5 个 BossState 含两个阵营首任。先分清静态/召唤/阵营，再谈技能。
3. `DUN-1762-GATE`：槽 0 与 `EncounterCount=5`。这是风险，未查 core 算法，未证死。
4. `DUN-2097-GATE`：8 槽在。扫描 door=1 是注释空门表，占位为空、未接线。
5. 已有刷点、文件短或实例写了 Missing 的遭遇：暴富实例、诸王四王、托尔达戈空壳、哈达尔的 AT（在围攻世界有点之后）。
6. 词缀整表不插入上述竖切。

## 不做

- 用词缀代替小怪、门、光环。
- 扩到旧资料片地下城；只在误接线碰到时再看。
- 给诸王加普通；给围攻、麦卡贡加未证实的普通或英雄。
- 1822 按 MDT 全量插入静态 NPC；把召唤单位补成常驻。
- 冈克再写一份调研或方案；改 `squirt_lifecycle.h`、SQL 70/71、以及 `baseline-tracked.json` 里那 13 个已跟踪脏文件。
- 把冈克 6 行身份之外再加 NPC；用 SQL 文件宣布活库。
- 把 AddSC、行数、SmartAI、法术枚举、扫描旗标 NOJUSTDIED/NORESET 写成已完成或基类未修。
- 把 SAI 抽样桶当成一条实施原子。
- 声称本执笔看过逐帧录像。

## 未知

- 35662 `MapDifficulty` / LFG 上，诸王、围攻、麦卡贡究竟允许哪些难度。`spawnDifficulties` 的取值未分组。诸王脚本分支仍是已写明的 2 与 23。围攻和麦卡贡的普通/英雄未钉死。
- 孢林、风暴、阿德里斯/阿斯匹克斯的 `bfa_` ScriptName 刷点与 `bfa_spell_*` 的 `spell_script_names`。
- 艾泽洛克 129227 的刷点行。
- 各本门 GO 的 entry 与击杀解锁。麦卡贡注释空门表的占位未接线。
- 首领能量条、AT、对话、掉落包的客户端表现（除账本所称冈克窗口由 Codex 看过之外）。冈克 FX 效果未证。
- 实例「全部槽 DONE」才算打完的核心判定位置。诸王槽 0 对完成的影响未查该算法，保持风险。
- 托尔达戈四名首领的 JustDied/Reset 继承链。扫描旗标只说明本类未 override。
- 1841、1864、1877 的 loot 行数。144244 的 loot 行数。自由镇议会箱。
- 1822 静态、召唤、阵营坐标。技能是否 blizzlike，各本仍缺客户端或战报。

## 约定

审查已授权的归并，不再征求切分意见。

1. 红钩与班布里奇：一场一条，两套 AI。
2. 诸王议会、三姐妹、船长议会、斗殴机兵：一场一条。
3. 麦卡贡：同一地图 2097，八条遭遇，另加一条门/翼进度。不拆成两本。
4. 冈克：`DUN-2097-GUNKER-BIND` 是 P0，只含身份、激活、重置。`DUN-2097-GUNKER-FX`（Goop、喷雾、路径）拆到后续，效果未证。
5. 1822：先世界与进度，后技能。

## 分类审查 R1 修正清单

R1 原文 Status 为 Issues Found，在 `_tmp_grok/dungeon-loop-20260930/classify-r1.md`。本清单只记文档改动。不标 Approved。R2 另派，不沿用本执笔。

- Critical：原 `DUN-2097-GUNKER` 拆成 `DUN-2097-GUNKER-BIND`（P0：绑定、召唤次数、激活、重置）和 `DUN-2097-GUNKER-FX`（Goop、喷雾、路径；不进第一批；效果未证）。P0 第 1 条与原争议 4 按此落地。SQL 70/71 仍只是文件名。
- 活库 `activation-live-db.json` 取代原未知：三只机器人刷点 ScriptName=`npc_mechagon_squirt_bot`。三对为 154741/154744、154746/150168、154759/154758。身份保留这 6 行，不加 NPC。三对身份和 SAI 已确定。
- Important：杰斯补 NOJUSTDIED；瓦莉、科格斯补 NOJUSTDIED 与 NORESET。沙后扫描同为这两旗，一并写上。四处都写须查继承。
- Important：126845、126847、126848 改为已核 loot 0 行。议会箱仍缺证。145185 补为 0 行。144244 不补行数。
- Important：`DUN-1771-TRASH` 只留空 `AddSC_tol_dagor`。GO、狱门、炮台另起 `DUN-1771-GO` 证据行。其余 `*-TRASH` 标明 SAI 抽样桶，不是一条实施原子。
- Important：新增 `DUN-1841-LOOT`、`DUN-1864-LOOT`、`DUN-1877-LOOT`，标未知，loot 未查、未证，不填行数。
- Minor：拉兹敦克改为扫描 178 行、cases=0、cast 计数 0。达萨尔 Barrage 的 `/* fallthrough */` 属实，是否删除未证，函数在 `instance_kings_rest.cpp`。黄金蛇补 `boss_the_golden_serpent.cpp`。诸王槽 0 保持风险，未证死。斯帕克斯补进战 `DoCastSelf(295065)`、火炮能量 100、`JustDied` 的 `DoModifyPlayerCurrencies(1553, 35)`，效果未证。阿塔达萨按扫描 door=0、tp=0。麦卡贡 door=1 维持为注释空门表，占位为空、未接线。
- 原切分争议 1、2、3、5 改为约定。争议 4 改为 BIND / FX。

## 2026-09-30 当前库补证：注册名前缀盲区

仅补证，不改分类原子、既有 R2 边界或官方完成标准。完整 SELECT、源码行号与原始行见 `_tmp_grok/dungeon-loop-20260930/codex-npc-prefix-gap-report.md` 及同前缀 JSON/Python。

按真实 entry 和注册名核对后，孢林四个首领本体、风暴五个首领本体（议会两人分别计）、塞塔里斯五个首领本体（双王分别计）及艾泽洛克，共15个本体 entry 在目标地图均有静态刷点1，模板/刷点有效脚本名正确。其中12个注册名是 `bfa_boss_*`，旧 `boss_` 前缀扫描漏计不能写成缺王；15是本次本体集合，不是官方遭遇数量。

风暴领主的战斗体是134060，139737是序章体；两者当前各有一条刷点和各自正确脚本，不能互相替换。孢林131597有50条静态记录且只含难度23；运行难度覆盖与生成链仍须核 core/DB2/录像，不据此直接补难度或增加刷点。另22个辅助/阶段 entry 目标地图静态为0，必须继续区分召唤、阶段和交互来源，不能据0自动补NPC。

### 2026-10-01 实际挑战难度链补证（不增加修复原子）

`codex-underrot-pod-difficulty-precheck.md/.json` 已核真实网格刷点索引、地图创建、挑战开始/重置及赞查/DB2：网格选刷点本身不做8→23回退；当前`InstanceScript::StartChallengeMode`要求实际地图难度23，函数保持此值，发给客户端的`DifficultyRecID=8`不等于修改地图刷点模式。正常可达链用23加载既有131597，不能将50条仅23记录列为大秘缺NPC。259621的DB2召唤131597正向存在，但赞查源码只找已有pod，不证明那条生成链实际被调用；真实加载数仍未验。

主会话另沿同一通用挑战入口核对自由镇：`freehold.h:131–136`接受实际难度2/23，议会进战`boss_council_o_captains.cpp:326–330`使用它启动133219。因此正常实际保持23的大秘路径可通过这个难度谓词；不能仅因源码没写8而先加8并宣称修复。直接实际模式8的其他入口是否存在、运行NPC/绑定/目标/时序仍待验，四个缺失spell映射证据不受此说明影响。

挑战重置的`Map::isChallenge()`模式8判断与正常保持23之间另有待研究风险；本补证不称重置完整正确，也不在孢林/自由镇擅改通用core。保持既有原子、R2边界与用户“不增不漏NPC”的目标，以上仅排除不成立的缺失推断。

这些证据只关闭该局部的身份/绑定统计盲区，未证明进程已加载、所有NPC人口正确、战斗完整、掉落或全11本已修。


### 2026-10-01共享难度选择未修候选（尚未进入核心实施方案）

| 对象 | 当前已核缺口 | Agent＋本地数据可修性 | 当前边界 |
|---|---|---|---|
| SpellInfo::GetEffectsForDifficulty / GetEffect | fallback循环推进difficultyEntry，但_effects.find一直用原请求difficulty，未按中间fallback难度查覆盖；主代理直接读源码与独立窄review一致 | 可结合本地Difficulty/SpellEffect、加载规则和针对缺省/覆盖/回退的有意义回归验证修复 | 仅未修候选，不是已审核心Task；当前冈克玩家模块不修改core。此缺口不证明NPC缺刷或允许新增NPC，详见调研末章及codex-gunker-player-stack-data-review.md |


### 2026-10-01：新增WCL复核结束，玩家关联模块R2进行中

2026-10-01T19:53:00+08:00。main实际认证下载5场独立report/fight/pull窗口，合计71684条raw events；Hooke新增事实R1已结束，main已读完整报告并逐项点检4组玩家298259 apply/remove、元数据petOwner、153377致死damage/death。4组来自3个report，只支持普通击杀粘液怪救援旁证，未证明世界GUID/源Aura因果；另有8次已有botAura时的点名机会，不认证完整随机filter。原始数组无cursor，分页和全部事件类型完整性未认证；旧1个样本按历史保留。实际297901喷雾cast与当前脚本一致，不因297899缺事件改ID。main已亲看1080p冈克片段，WCL和录像为不同队伍，不强行毫秒对齐。事实报告 `D:/wow837_projects/_tmp_grok/dungeon-loop-20260930/codex-gunker-new-wcl-r1.md`，main点检 `codex-gunker-new-wcl-main-pointcheck.json`。

玩家粘液架构、master已审通过；模块原R1仅Task3不存在的IsDead()一项Important，作者唯一纠正为真实isDead()，原稿与原IssuesFound报告保留。原R1定点复审Approved/C0 I0 M0/I1 Closed，当前模块SHA256 `9e8f14abc76664fd68a55361e9b2fab7877ba2217e04e5d292ed61fa4db516c5`；独立module R2进行中，尚未实施玩家298259 C++、SQL或Lua。旧80绑定仍仅生成未应用；本期不增删静态NPC，围攻伯拉勒斯暂缓；全部运行格runtime_pending。此段更新阶段与证据来源，不追改冻结方案的历史计数或扩写未知双粘液/多怪最后击杀/超时政策。


### 2026-10-01：冈克玩家关联 Task0–2 实施状态更新

玩家关联模块 R2 已 Approved；Task0 基础、Task1 真实施法/返回关联（原I1/I2纠正定点Closed）、Task2 精确移除/刷新/晚回调均真实编译并独立审查通过。当前推进 Task3 单 Goop 击破救援；Task4实例生命周期、Task5注册/SQL、Task6手工验收包尚未完成。上述更新覆盖旧阶段文字的时效，不把整个FX或11本标完成。未增删NPC、未应用SQL/部署，运行验收全部 pending，围攻暂缓。实际材料与逐桶状态见进度文档和 evidence-and-scope-checkpoint.json。


### 2026-10-01：Task3 基础击破救援完成静态闭环

Task3普通单只Goop救援真实构建和新的独立代码R1已通过，C0/I0/M0；累计成功1/执行finished/无失败/精确确死/同源活、earlydead与REAPPLY补判已落代码。当前Task4实施员已开始，Task5脚本/SQL、Task6验收包仍待完成；未部署/游戏验收，完整FX与11本目标仍active。新增五WCL对喷雾保护仅限定本地核对，仍无法据缺事件确定保护或区域形状，详见调研末段。


### 2026-10-01：Task4 静态闭环及最新活库接线补证

Task4生命周期代码、最终构建和独立R1已通过C0/I0/M0，现推进Task5配对注册/SQL文本，Task6与游戏验收仍待。fresh活库仅确认2097七NPC指定entry各1、静态153377零/SAI零、相关三法术正负映射零、实例同名映射存在；不推广成整个11本NPC全部正确。表为MyISAM，后续guard前后/count记账不可省略。未应用旧80/新81、未部署、未增删NPC；11本总目标active、围攻暂缓。
