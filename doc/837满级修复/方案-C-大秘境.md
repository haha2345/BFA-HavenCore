# 方案 C — 大秘境词缀

**前置：** 方案 B 至少孢林能打通。词缀叠在 Challenge 系统上，不要在每个五人本里 if。  
代码标准：技能 `philosophy.md`「大秘境」。  
捐赠：`735_Core/LegionCore-7.3.5` 的 `Challenge.cpp` / 词缀脚本，**改写成 Haven 8.3 API**。

---

## 已有、被关掉的管道

| 位置 | 现状 |
|------|------|
| `InstanceScript::StartChallengeMode` | 能开钥石、上血伤光环 |
| `CastChallengeCreatureSpell` | BP0/BP1 有血伤倍率；**词缀 BP2–13 全是 0** |
| `CastChallengePlayerSpell` | 重伤/胆怯等 BP 全 0 |
| `scripts/World/challenge_scripts.cpp` | `spell_challengers_might` / burden / bursting / grievous / bolster / volcanic **整段注释**；只注册了爆炸物 NPC 和钥石物品 |
| `ChallengeModeMgr` + `gt/ChallengeModeHealth.txt` 等 | 层数倍率还在 |

---

## 做法

1. 恢复 `challenge_scripts.cpp` 里的 AuraScript，在 `AddSC_challenge_scripts()` 重新 `RegisterAuraScript`。
2. `CalculateAmount` 按当前钥石 `HasAffix` 填对应 BP，**不要**每本五人写一套。
3. 暴君/强韧已经写在被注释的 `spell_challengers_might::CalculateAmount`（Boss vs 小怪倍率）——先接线，再对 8.3 数字。
4. 血伤继续走 `GetHealthMultiplier` / `GetDamageMultiplier` / GameTables。
5. 词缀池用 **BFA 第 4 赛季**，不用现役正式服。
6. 先在孢林钥匙上做出 3 个能看出来的：暴君或强韧、暴怒或血池、震荡或死疽。再铺全表。

改 `CastChallengeCreatureSpell` 的 0 是核心层的合法例外（系统在、数字被关掉）。不要平行再写一个 ChallengeMgr。

---

## 验收

- [ ] 孢林钥匙能开，怪血/伤随层数变
- [ ] 至少 3 个词缀在战斗里可见
- [ ] 倒计时、周箱可以后补，不能用「能开门」冒充词缀完成
---
