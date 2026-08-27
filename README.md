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

## 本 fork：满级 blizz-like（`endgame/corruption-stars`）

对照正式服 8.3.7.35662。方案正文：[doc/837满级修复/README.md](doc/837满级修复/README.md)。

### 近期任务

当前阶段 **A 腐蚀**：一次一条签名效果的第 1 层。未说开工前不自动开下一条。

| 状态 | 任务 |
|------|------|
| **正在做** | A5 虚空仪式第 1 层（`.labritual` / 316814） |
| **下一步** | A5 进游戏验收；其后真装 2b |
| 未开 | 被动好效果；坏效果 2a（不改 `UpdateCorruption()`）；五人 / 词缀 / 团本 |

### 已完成

| 日期 | 内容 | 说明 |
|------|------|------|
| 2026-08-27 | A5 虚空仪式第 1 层 **打桩中** | `.labritual` 挂 316814。316823 每秒叠全次级。 |
| 2026-08-27 | 满级木桩按职责拆开 | Raider's 123 / 110–120；其余满级桩 120 / 110–120。须重启世界服。 |
| 2026-08-27 | A4 扭曲的附肢第 1 层 **通过** | `.labtentacle` + `.labaoe`：十跳 2379/3568。不写 `spell_proc`。**未做**真装 / ilvl。 |
| 2026-08-26 | A3 虚空回响主路径 **通过** | `.labecho`：平砍不叠；猛击叠层后坍缩；4 层 4 跳 `remain=3/2/1/0`；979/1468（×1.5）；坍缩中不叠。`51cd6a6` |
| 2026-08-26 | A2 光柱主路径 **通过** | 判定走 AT `OnUnitEnter`（模板 23070）；visual=93766。**未测**侧后/拉怪/10 上限 |
| 2026-08-26 | A1 双倍扣血重验 **通过** | 每颗星战报 1 条，不再双倍 |
| 2026-08-25 | A1 数值改读 SpellInfo | 易伤/半径/段数 Dummy（83/208/312）从 SpellInfo 读。进游戏 732→916（×1.25）。**未做**真装 ilvl。 |
| 2026-08-25 | **A1 无尽之星第 1 层** | `.aura 317257`：技能/法术出星，普攻不出；DEST `317262` 落星约 1 秒；`317265` 奥术 + 易伤。实测 visual=93802，980→1225（1.11 打桩，已被 Dummy 83% 取代）。**未做**真装 318274 / ilvl。`ef9573b` |
| 2026-08-24 | MapManager 启动崩溃 | `_freeInstanceIds` 未分配。`58a7a23` |
| 2026-08-24 | MSVC `/utf-8` | GBK 代码页编中文注释。`1b3aa88` |
| 2026-08-24 | 腐蚀基线 | 好效果在 ItemEffect，坏效果在 `CorruptionEffects.db2`（10 行完整） |
