# BFA-HavenCore

<p align="center">
  <img width="400" height="¨400" src="https://zupimages.net/up/26/28/aj5p.png">
</p>

<p align="center">
 <img width="250" height="30" src="https://www.zupimages.net/up/21/43/drky.jpg">  <img width="250" height="30" src="https://www.zupimages.net/up/21/43/zvg8.jpg">
</p>

<p align="center">
    <a href="https://discord.gg/XbJH5zngk5">
        <img src="https://img.shields.io/badge/Discord-Join%20the%20Community-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Discord">
    </a>
</p>

<p align="center"><b>BFA-HavenCore</b> is a open-source project for World of Warcraft, currently supporting the 8.3.7 (build 35662) game version.</p>

<br>
<br>

## Why Choose HavenCore?
 
- Actively maintained – The project continues to receive updates, fixes, and improvements.
- Community support – Get help, report issues, or discuss development in the official WoW Haven Discord server.
- 100% open source – The entire codebase is freely available for the community to use, learn from, and contribute to.
- The most polished BFA cores available – Focused on stability, scripting quality, and gameplay accuracy.
 
## Project Goals
 
The goal of this project is to recreate the World of Warcraft©: Battle for Azeroth experience as faithfully as possible while maintaining a Blizzlike gameplay experience. At the same time, we aim to encourage the development of World of Warcraft© emulators by providing a high-quality, open-source foundation.
 
Our priorities include:
 
- Fixing bugs and core issues.
- Implementing missing game content.
- Improving scripting accuracy.
- Enhancing database quality and overall stability.
 
## Contributing
 
Everyone is welcome to contribute.
 
Whether you enjoy testing gameplay, reporting bugs, fixing core issues, improving scripts, or working on the database, every contribution helps move the project forward.
 
You can:
 
- Fork the repository and submit pull requests.
- Open issues for bugs or missing content.
- Make extra content (video tutorials for example)

If you want to contribute to the project feel free to join us on our Discord server. Your participation in the project will already be a great help. 

## Community

Join our **Discord** to collaborate with other developers and contributors.

- https://discord.gg/sQYue7Qpqx
 
## Requirements
 
- CMake 3.20+ (Recommended 3.31.5)
- Boost (min: 1.74.0 / max: 1.85.0)
- MySQL ≥ 8.0 (Recommended 8.4)
- OpenSSL 3.x.x
- Microsoft Visual Studio 2022 (Version 17+) with Desktop Development with C++ installed (Preview versions are not recommended.)
 
## License
 
This project is licensed under the GNU General Public License v3.0 (GPL-3.0).
 
License: https://github.com/Hextv/BFA-HavenCore/tree/main?tab=GPL-3.0-1-ov-file#

## 本 Fork 核心修复：8.3.7 满级 Blizz-like 还原工程

本项目分支以官方 8.3.7.35662 版本为基准，专注于将 120 级满级阶段的核心系统还原至官方原版标准。

详细技术方案与各模块完整文档索引请参阅：[doc/837满级修复/README.md](doc/837满级修复/README.md)。

### 已完成修复的核心系统总览

该表格的核心用途是：展示本仓库分支已彻底完成代码实施与技术复核的核心子系统概况。

| 系统分类 | 核心修复模块 | 涉及底层机制与关键技术点 | 当前状态说明 |
| :--- | :--- | :--- | :--- |
| **人物基础属性与换算** | 120 级战斗等级转换与底层基础数值 | 修正 120 级战斗等级转换表（CombatRatings）映射、耐力生命值加成比率（每点耐力提供 20 点生命值）、裸体属性与法力转化公式 | 代码已完成，纸面对齐完毕，待进游戏实测验收 |
| **护甲加成计算引擎** | 光环效果 268 机制底层引擎重构 | 实现 `SPELL_AURA_MOD_ARMOR_PCT_FROM_STAT`（基于主属性百分比提升护甲值），卸除原有重复叠加的脚本旁路 | 代码已完成并编译入库，待进游戏实测验收 |
| **白字物理易伤引擎** | 光环效果 343 机制独立承伤计算 | 实现 `SPELL_AURA_MOD_MELEE_DAMAGE_FROM_CASTER`（特定施法者白字物理承伤增幅），严格隔离普通攻击与法术技能 | 代码已完成并编译入库，待进游戏实测验收 |
| **艾泽拉斯之心联动** | 艾泽拉斯之心项链与特质赋能装联动 | 保证 158075 项链装备状态正确触发核心底层光环 277253，穿脱项链正确控制艾泽里特特质的主动触发与卸除 | 代码已完成，调用链核对完毕，待进游戏实测验收 |
| **腐蚀装备体系** | 8.3.7 全套腐蚀正向特效与阶梯负面惩罚 | 完整重构五大标志性伤害与治疗特效、全套被动次要属性特效、以及五阶负面惩罚机制（触须、眼球、幻象、厄运等） | 代码已完成，测试套件完备，待进游戏实测验收 |
| **职业战斗与天赋** | 十二大职业核心专精循环与特殊机制 | 修复战士、圣骑士、死亡骑士、潜行者、德鲁伊等全部 12 职业专精联动、宠物攻防缩放、特殊精通机制与种族特长 | 代码已完成，各职业复核文档已归档，待进游戏实测验收 |
| **地下城副本机制** | 十一个争霸艾泽拉斯经典史诗地下城 | 完整修复各地下城首领战阶段转换、转阶段无敌逻辑、环境机关控制、战利品掉落索引与技能事件处理 | 代码已完成，各副本复核文档已归档，待进游戏实测验收 |

### 核心技术点与修复细节

1. **人物属性底层计算与引擎重构**：
   - 彻底修复 120 级战斗等级对表索引，保证爆击（72）、急速（68）、精通（72）、全能（85/170）与耐力（每点耐力 20 点生命值）转换比率与官方完全一致。
   - 实现光环效果 268（`SPELL_AURA_MOD_ARMOR_PCT_FROM_STAT`）的引擎级计算，由底层统一基于力量或敏捷属性提升护甲，并彻底卸除德鲁伊铁鬃、防骑正义盾击、DK白骨之盾在脚本中的历史重复代码，解决护甲异常双倍放大的顽疾。
   - 接入光环效果 343（`SPELL_AURA_MOD_MELEE_DAMAGE_FROM_CASTER`），使巨人打击、仇杀等易伤仅作用于无技能原型的自动物理平砍，杜绝技能近战伤害二次翻倍漏洞。
   - 完善艾泽拉斯之心项链（物品 158075，法术 277253）穿脱管道，确保项链卸下时艾泽里特特质光环立即剥离失效。
2. **8.3.7 腐蚀装备与惩罚系统**：
   - 实现无尽之星、暮光毁灭（5目标后半伤）、虚空回响（需公共冷却时间技能充能）、扭曲的附肢、虚空仪式等核心特效。
   - 建立蔓生触须、腐蚀之眼、宏伟妄想刺客、不可避免的厄运等五阶阶梯式负面惩罚触发机制。
   - 修正满级木桩的世界缩放（Content Tuning）机制，彻底解决未过滤战斗日志（CLEU）中输出数值被异常压缩的问题。
3. **职业循环、特质、精华与满级饰品**：
   - 全 12 职业专精机制校准、全专精宠物攻防属性 8.3 动态缩放、全种族特长修正。
   - 艾泽里特签名特质（如武器战地震波）与艾泽拉斯之心主动精华（如浓缩火焰）机制落地。
   - 永恒王宫与尼奥罗萨核心签名饰品（如能量泉涌、珊瑚等）机制支持。
4. **十一个史诗五人地下城副本**：
   - 自由镇、地渊孢林、塞塔里斯神庙、维克雷斯庄园、风暴神殿、阿塔达萨、托尔达戈、暴富矿区、诸王之眠、围攻伯拉勒斯、麦卡贡行动（垃圾场与车间全八组首领）全量首领战阶段转换、场地锁定与机制修补。
   - 2026-10-01 增量核对：自由镇三酒正常施法、begin约8秒节奏及同步取消三个Task已真实编译和独立静态复核，HavenLab观察包已镜像；新exe未部署、完整酒/陷阱及游戏验收未完成。全11本NPC与机制仍按分类逐项核验，围攻暂缓；见 `doc/837满级修复/复核-自由镇三酒施法生命周期.md`。

### 运行端部署与测试指引

1. **二进制替换**：编译产物 `BFA-HavenCore/build/bin/RelWithDebInfo/worldserver.exe` 包含最新的人物属性与引擎修复。在进入游戏前，须关闭世界服并将该文件覆盖至运行端 `Repacks/HavenCore/` 目录。
2. **测试插件使用**：测试套件 `HavenLab` 已镜像至客户端 `Interface/AddOns/HavenLab/`。游戏内可通过 `/lab start <pack_name>` 进行对应功能验证（如 `/lab start stat_aura268_*` 与 `/lab start stat_aura343_*`）。验证时请结合人物属性面板与自动攻击白字数值进行人工校对。
