"""Read-only source inventory; this is not a gameplay test or coverage score.
Run from any directory: python -B collect_inventory.py
Writes only the adjacent evidence JSON and Markdown overview.
"""
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[2]
SIMC = ROOT.parent / 'Data/simc-bfa-dev'
OUT = Path(__file__).resolve().parent
# class, core stem, SimC path, specialization/name/resource/first inspection points
CLASSES = [
 ('战士','warrior','sc_warrior.cpp',[
  ('武器','Arms','怒气','tactician|mortal_strike|execute','压制重置、怒气消耗、斩杀缩放、重伤'),
  ('狂暴','Fury','怒气','rampage|bloodthirst|enrage','暴怒多段、激怒、双持产怒、旋风斩扩散'),
  ('防护','Protection','怒气','shield_block|ignore_pain','盾牌格挡充能、无视苦痛吸收、复仇')]),
 ('圣骑士','paladin','paladin',[
  ('神圣','Holy','法力','holy_shock|beacon','神圣震击、道标转移、黎明之光；治疗模型覆盖另核'),
  ('防护','Protection','法力','shield_of_the_righteous|avenger','正义盾击充能、复仇者之盾、守护之光'),
  ('惩戒','Retribution','神圣能量/法力','templar|divine_storm|holy_power','神圣能量收支、裁决、神圣风暴、免费触发')]),
 ('猎人','hunter','sc_hunter.cpp',[
  ('野兽控制','Beast_Mastery','集中值','kill_command|barbed|beast','宠物杀戮命令、倒刺射击、狂暴层数'),
  ('射击','Marksmanship','集中值','aimed_shot|rapid_fire|precise','瞄准充能、急速射击引导、精准射击'),
  ('生存','Survival','集中值','mongoose|wildfire|raptor','猛禽/猫鼬替换、炸弹、宠物协作')]),
 ('潜行者','rogue','sc_rogue.cpp',[
  ('奇袭','Assassination','能量/连击点','mutilate|envenom|venomous','毒伤、毒液创伤、流血与能量'),
  ('狂徒','Outlaw','能量/连击点','roll_the_bones|sinister|pistol','命运骨骰、邪恶攻击额外攻击、手枪射击'),
  ('敏锐','Subtlety','能量/连击点','shadow_dance|shadowstrike|symbols','暗影之舞充能、潜行技能替换、暗影打击')]),
 ('牧师','priest','priest',[
  ('戒律','Discipline','法力','atonement|penance','救赎伤转疗、苦修、吸收与目标归属'),
  ('神圣','Holy','法力','holy_word|prayer_of_mending','圣言减冷却、愈合祷言跳转、治疗选人'),
  ('暗影','Shadow','狂乱/法力','voidform|void_bolt|insanity','虚空形态狂乱衰减、虚空箭、持续伤害')]),
 ('死亡骑士','dk','sc_death_knight.cpp',[
  ('鲜血','Blood','符文/符能','death_strike|bone_shield','灵界打击近期承伤、骨盾消耗、符文恢复'),
  ('冰霜','Frost','符文/符能','killing_machine|rime|obliterate','杀戮机器、白霜、湮灭、吐息消耗'),
  ('邪恶','Unholy','符文/符能','festering|scourge|dark_transformation','溃烂之伤、天灾打击、宠物与天启')]),
 ('萨满祭司','shaman','sc_shaman.cpp',[
  ('元素','Elemental','漩涡值/法力','lava_burst|overload|earth_shock','元素过载、熔岩爆裂、震击和漩涡值'),
  ('增强','Enhancement','漩涡值/法力','stormstrike|stormbringer|rockbiter','风暴打击重置、石化产能、双持触发'),
  ('恢复','Restoration','法力','riptide|tidal_waves|chain_heal','潮汐奔涌、治疗链、图腾治疗归属')]),
 ('法师','mage','sc_mage.cpp',[
  ('奥术','Arcane','法力/奥术充能','arcane_blast|arcane_missiles|clearcasting','充能增耗增伤、节能施法、唤醒'),
  ('火焰','Fire','法力','hot_streak|heating_up|ignite','热力迸发到炽热连击、点燃、火冲充能'),
  ('冰霜','Frost','法力','brain_freeze|fingers_of_frost|flurry','寒冰指、冰冷智慧、冰风暴与碎冰')]),
 ('术士','warlock','warlock',[
  ('痛苦','Affliction','灵魂碎片/法力','unstable_affliction|agony|deathbolt','痛苦无常、痛楚产片、死亡之箭'),
  ('恶魔学识','Demonology','灵魂碎片/法力','dreadstalker|demonic_core|implosion','恶魔之核、野生小鬼、暴君与内爆'),
  ('毁灭','Destruction','灵魂碎片/法力','chaos_bolt|conflagrate|havoc','碎片小数、混乱箭、浩劫复制')]),
 ('武僧','monk','sc_monk.cpp',[
  ('酒仙','Brewmaster','能量','stagger|purifying|ironskin','醉拳池、清心酒、铁骨酒共享充能'),
  ('织雾','Mistweaver','法力','soothing_mist|renewing_mist|vivify','抚慰引导、复苏之雾转移、活血术'),
  ('踏风','Windwalker','能量/真气','fists_of_fury|storm_earth|combo','真气收支、连击精通、分身和怒雷破')]),
 ('德鲁伊','druid','sc_druid.cpp',[
  ('平衡','Balance','星界能量/法力','starsurge|starfall|solar_wrath','星涌星落、赋能、星界能量'),
  ('野性','Feral','能量/连击点','rip|rake|ferocious_bite','流血快照、凶猛撕咬额外耗能、猛虎之怒'),
  ('守护','Guardian','怒气','ironfur|frenzied_regeneration|mangle','铁鬃叠加、狂暴回复、形态切换'),
  ('恢复','Restoration','法力','lifebloom|wild_growth|swiftmend','生命绽放、野性成长、精通与多目标持续治疗')]),
 ('恶魔猎手','dh','sc_demon_hunter.cpp',[
  ('浩劫','Havoc','恶魔之怒','chaos_strike|eye_beam|demon_bite','混乱打击返还、眼棱、变身技能替换'),
  ('复仇','Vengeance','痛苦','soul_cleave|soul_fragment|demon_spikes','灵魂残片、灵魂裂劈、恶魔尖刺充能')]),
]

rows=[]
for cls,stem,simpath,specs in CLASSES:
 core=ROOT / f'src/server/scripts/Spells/spell_{stem}.cpp'
 text=core.read_text(encoding='utf-8')
 lines=text.splitlines()
 reference=SIMC/'engine/class_modules'/simpath
 for name,english,power,pattern,focus in specs:
  anchors=[f'{core.relative_to(ROOT).as_posix()}:{n}' for n,line in enumerate(lines,1)
           if re.search(pattern,line,re.I)][:3]
  profiles=sorted(p.relative_to(SIMC).as_posix() for p in (SIMC/'profiles/Tier25').glob(f'*_{english}*.simc')
                  if stem.replace('dk','Death_Knight').replace('dh','Demon_Hunter').lower() in p.name.lower())
  rows.append(dict(class_name=cls,spec=name,resource=power,source=str(core.relative_to(ROOT)),
    simc=str(reference.relative_to(SIMC)),simc_exists=reference.exists(),
    anchors=anchors,tier25_profiles=profiles,focus=focus,status='待逐项行为核对'))

(OUT/'inventory.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
md=['# 8.3.7 全职业缺口概览（第一批）','',
 '日期：2026-09-05。基线：809928f；目标客户端 8.3.7.35662。第一专精：武器战。',
 '','## 状态与边界','',
 '覆盖 12 职业、36 专精的源码/旧 SimC 入口和优先核对范围。此表是缺口定位概览，不是逐技能完成度审计。',
 '关键词命中可能来自旧脚本或注释，不证明注册、数据库挂名、实际加载或运行正确；未命中也不证明技能缺失，须追踪 DB2 与通用引擎。',
 '其他 35 专精尚未逐技能对比；共同待补的是技能数据→实现→挂载→实际行为证据。没有游戏验收时不标通过。',
 '','## 36 专精工作入口','',
 '| 职业/专精 | 资源 | 当前源码定位线索 | 首批需要核对的行为（不是已确认错误） |',
 '|---|---|---|---|']
for r in rows:
 a='、'.join('`'+p+'`' for p in r['anchors']) or '未命中关键词；先追 DB2/引擎'
 md.append(f"| {r['class_name']}·{r['spec']} | {r['resource']} | {a} | {r['focus']} |")
md += ['', '## 已确认的问题与本批处理','',
 '| 问题 | 证据 | 状态 |','|---|---|---|',
 '| 武器战战术专家仍重置巨人打击/致死打击 | 基线 spell_warr_tactician；35662 184783；旧 SimC tactician() 恢复压制 | 本批改为恢复一个压制充能；系数读 aura。特殊耗怒口径和多目标 proc 仍待核 |',
 '| 武器战愤怒掌控每次有怒气费用的施法固定减 1 秒，且发生在成功扣费之前 | 基线 anger_management::OnSpellCast；35662 152278 EFFECT_0=20 | 本批按本次实际扣除怒气换算毫秒，成功施法后执行；未实机验收 |',
 '| 狂暴/防护愤怒掌控也存在固定减秒的源码路径 | 同一 PlayerScript 的其他分支 | 后续对应专精处理，本批未改 |',
 '| 武器战斩杀倍率由整数除法计算 | spell_warr_execute::HandleTakePower | 已确认源码截断风险；延迟子技能、免费触发和费用数据一起核对后修，不能只改单行即宣布完成 |',
 '', '## 共用路径优先级','',
 '1. Spell::TakePower：区分实际扣除、可选耗能、未命中折扣和免费施法。本批仅记录实际扣怒气，不修改扣费规则。',
 '2. SpellHistory：普通冷却与充能要分别处理；战术专家不能用普通 ResetCooldown 代替恢复充能。',
 '3. Player::Regenerate / Unit::RewardRage：按 PowerType、专精被动和实际武器速度核对，不统一写死。',
 '4. 光环与 proc：按一次施法/每个命中/每个周期区分；避免重复资源、重复伤害。',
 '5. 天赋/专精切换、死亡、穿脱：清理和保存由对应专精批次完成。',
 '', '## 资源与下一批','',
 '本地资源：Data/simc-bfa-dev（含 SpellDataDump 与职业模型）；Data/wago-35662-grill/SpellEffect.csv；客户端 DB2；Data/Addon 旧插件。路径相对工作区。',
 'inventory.json 提供每个专精的核心入口、SimC 入口是否存在与 Tier25 配置定位。配置缺失不等于模型缺失，尤其治疗模型要单独确认。',
 '下一批从武器战斩杀、重伤触发、自动攻击产怒、战术专家特殊耗怒与多目标触发继续。其后完成基础防御/功能和天赋，再接装备。',
 '本批不部署运行端、不导数据库、不改腐蚀脚本、不启动游戏测试；编译结果记录在武器战文档。', '']
(OUT/'全职业缺口概览.md').write_text('\n'.join(md),encoding='utf-8')
print(f'Wrote {len(rows)} specialization entries to {OUT}')
