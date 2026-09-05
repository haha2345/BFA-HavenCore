# -*- coding: utf-8 -*-
"""HavenLab 2.0 离线验收：服务端静态核对 + 插件引擎行为。不启动 worldserver。"""
from __future__ import annotations

import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
CORE = ROOT
ADDON = os.path.abspath(os.path.join(
    ROOT, "..", "client", "World of Warcraft", "_retail_", "Interface", "AddOns", "HavenLab"
))
SPELL_CPP = os.path.join(CORE, "src", "server", "scripts", "Spells", "spell_corruption.cpp")
CMD_CPP = os.path.join(CORE, "src", "server", "scripts", "Commands", "cs_misc.cpp")

FAILS = []
PASSES = []


def ok(name: str) -> None:
    PASSES.append(name)
    print("  PASS  " + name)


def fail(name: str, why: str) -> None:
    FAILS.append(name + ": " + why)
    print("  FAIL  " + name + "  —  " + why)


def read(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


# ---------- 服务端静态 ----------
def test_server() -> None:
    print("\n== 服务端 ==")
    spell = read(SPELL_CPP)
    cmd = read(CMD_CPP)

    if "void LabNotify(Unit* caster, char const* type, std::string const& kv)" in spell:
        ok("LabNotify helper 存在")
    else:
        fail("LabNotify helper", "找不到函数签名")

    leftover = []
    for m in re.finditer(r'PSendSysMessage\(\s*"\[HavenLab\]', spell):
        before = spell[max(0, m.start() - 400):m.start()]
        if "void LabNotify(" not in before:
            leftover.append(str(m.start()))
    if leftover:
        fail("HavenLab 只走 LabNotify", "仍有直接 PSendSysMessage [HavenLab] @ " + ",".join(leftover))
    else:
        ok("所有 [HavenLab] 都经 LabNotify")

    for typ in ("STAR_VISUAL", "TWILIGHT_VISUAL", "TWILIGHT_HIT", "ECHO_STACK", "ECHO_COLLAPSE", "ECHO_TICK"):
        if f'LabNotify(caster, "{typ}"' in spell:
            ok(f"LabNotify {typ}")
        else:
            fail(f"LabNotify {typ}", "没有调用")

    star_fmt = "spell=%u visual=%u delay=%.2f missile=%u target=%s"
    tw_fmt = "spell=%u visual=%u hits=%u damage=%d beam=%u"
    if star_fmt in spell:
        ok("STAR_VISUAL 格式未改")
    else:
        fail("STAR_VISUAL 格式", "和旧版不一致")
    if tw_fmt in spell:
        ok("TWILIGHT_VISUAL 格式未改")
    else:
        fail("TWILIGHT_VISUAL 格式", "和旧版不一致")

    if '{ "lab"' in cmd and "labCommandTable" in cmd and "HandleLabTestCommand" in cmd:
        ok(".lab 子命令表")
    else:
        fail(".lab 子命令表", "没有 lab / test 注册")
    if "HandleLabClearCommand" in cmd and '{ "clear"' in cmd:
        ok(".lab clear")
    else:
        fail(".lab clear", "未注册")

    if "ApplyLabTest(handler, \"stars\")" in cmd and "ApplyLabTest(handler, \"twilight\")" in cmd and "ApplyLabTest(handler, \"echo\")" in cmd:
        ok("旧命令是 ApplyLabTest 别名")
    else:
        fail("别名转调", "labstars/labtwilight/labecho 没有走同一张表")

    for key, aura in (("stars", "317257"), ("twilight", "317147"), ("echo", "317014")):
        if re.search(rf'\{{ "{key}",\s*{aura},', cmd):
            ok(f"表 {key} -> {aura}")
        else:
            fail(f"表 {key}", f"没有 {aura}")

    if "RemoveHavenLabCorruptionAuras" in cmd:
        ok("测试前先卸其他腐蚀光环")
    else:
        fail("卸光环", "找不到 RemoveHavenLabCorruptionAuras")


# ---------- 插件静态 ----------
def test_addon_layout() -> None:
    print("\n== 插件文件 ==")
    toc = read(os.path.join(ADDON, "HavenLab.toc"))
    if "## Version: 2.0.0" in toc:
        ok("toc 2.0.0")
    else:
        fail("toc 版本", toc)
    for name in ("HavenLab.lua", "HavenLab_Packs.lua", "HavenLab_Track.lua", "HavenLab_Verdict.lua", "HavenLab_UI.lua"):
        if name in toc and os.path.isfile(os.path.join(ADDON, name)):
            ok("文件 " + name)
        else:
            fail("文件 " + name, "toc 或磁盘缺失")

    core = read(os.path.join(ADDON, "HavenLab.lua"))
    packs = read(os.path.join(ADDON, "HavenLab_Packs.lua"))
    track = read(os.path.join(ADDON, "HavenLab_Track.lua"))
    verdict = read(os.path.join(ADDON, "HavenLab_Verdict.lua"))
    ui = read(os.path.join(ADDON, "HavenLab_UI.lua"))
    all_lua = core + packs + track + verdict + ui

    if "CountStarVisuals" in all_lua or "CountTwilightVisuals" in all_lua:
        fail("删除专用扫描", "CountStarVisuals/CountTwilightVisuals 还在")
    else:
        ok("已删专用 visual 扫描函数")

    if re.search(r'STAR_VISUAL%s\+', all_lua) or re.search(r'TWILIGHT_VISUAL%s\+', all_lua):
        fail("专用正则", "还在用 STAR_VISUAL%s+ / TWILIGHT_VISUAL%s+")
    else:
        ok("无 STAR_VISUAL/TWILIGHT_VISUAL 专用正则")

    if "function HL:ParseLabMessage" in track:
        ok("通用 LAB 解析")
    else:
        fail("ParseLabMessage", "不在 Track.lua")

    if "function HL:VerdictLines" in verdict and "function HL:EvalStep" in verdict:
        ok("结论引擎在 Verdict.lua")
    else:
        fail("结论引擎", "Verdict.lua 缺 EvalStep/VerdictLines")

    if "HL.PACKS =" not in core and "HL.PACKS = {" in packs:
        ok("PACKS 已迁到 Packs.lua")
    else:
        fail("PACKS 迁移", "仍在核心或 Packs 没有表")

    for key in ("stars", "twilight", "echo", "demo"):
        if f"{key} = {{" in packs:
            ok(f"pack {key}")
        else:
            fail(f"pack {key}", "Packs.lua 没有")

    if 'hidden = true' in packs and "demo =" in packs:
        ok("demo 包 hidden")
    else:
        fail("demo hidden", "演示包应 hidden=true")

    for cmd in (".lab test stars", ".lab test twilight", ".lab test echo"):
        if f'serverCmd = "{cmd}"' in packs:
            ok("serverCmd " + cmd)
        else:
            fail("serverCmd", cmd)

    if 'HL:Send(".lab clear")' in ui:
        ok("卸星走 .lab clear")
    else:
        fail("卸星", "UI 还在连发 unaura")

    for needle in ("虚空回响", "总览", "记快照", "移速"):
        if needle in ui:
            ok("UI " + needle)
        else:
            fail("UI " + needle, "按钮/文案缺失")


# ---------- 引擎行为（与 Lua 同一套规则） ----------
SPECIAL = {
    "school", "pctOfMaxHp", "tolerance", "maxTargets", "halfFrom",
    "minCount", "dealsDamage", "summonEntries", "stat", "minDelta",
    "minGapMs", "approxPpm",
}


def parse_lab(message: str):
    m = re.match(r"^\[HavenLab\] (\S+)\s*(.*)$", message)
    if not m:
        return None, None
    kv = {}
    for k, v in re.findall(r"(\S+)=(\S+)", m.group(2) or ""):
        try:
            kv[k] = float(v) if "." in v else int(v)
        except ValueError:
            kv[k] = v
    return m.group(1), kv


class Engine:
    def __init__(self):
        self.stats = {}
        self.logs = []
        self.labMsgs = {}
        self.procTimes = {}
        self.summons = {}
        self.playerGUID = "P1"
        self.auras = {"player": {}, "target": {}}
        self.pack = None
        self.maxhp = 100000

    def stat(self, sid):
        s = self.stats.get(sid)
        if s is None:
            s = {
                "casts": 0, "damageN": 0, "damageSum": 0, "damageMax": 0, "school": "-",
                "stacks": 0, "auraSelf": 0, "auraTarget": 0,
                "perTarget": {}, "playerMaxHp": self.maxhp,
            }
            self.stats[sid] = s
        return s

    def find_aura(self, unit, sid):
        return self.auras.get(unit, {}).get(sid)

    def swings(self):
        return sum(1 for r in self.logs if r.get("spellId") == 0 and r.get("isDamage") and r.get("sGUID") == self.playerGUID)

    def combat(self):
        if self.swings():
            return True
        for s in self.stats.values():
            if s.get("damageN") or s.get("casts"):
                return True
        return any(self.labMsgs.values())

    def add_lab(self, message):
        typ, kv = parse_lab(message)
        if not typ:
            return False
        self.labMsgs.setdefault(typ, []).append({"t": 1, "kv": kv})
        return True

    def add_damage(self, sid, amount, dest="T1", name="桩", school=64):
        s = self.stat(sid)
        s["damageN"] += 1
        s["damageSum"] += amount
        s["damageMax"] = max(s["damageMax"], amount)
        s["school"] = {32: "暗影", 64: "奥术"}.get(school, str(school))
        s["schoolMask"] = school
        pt = s["perTarget"].setdefault(dest, {"name": name, "hits": 0, "sum": 0, "max": 0, "firstT": len(s["perTarget"])})
        pt["hits"] += 1
        pt["sum"] += amount
        pt["max"] = max(pt["max"], amount)

    def add_aura(self, sid, unit="player"):
        s = self.stat(sid)
        if unit == "player":
            s["auraSelf"] += 1
        else:
            s["auraTarget"] += 1
        self.auras[unit][sid] = True

    def add_summon(self, guid, spell_id=99, name="触须"):
        self.summons[guid] = {
            "spellId": spell_id, "name": name, "spawnT": 1, "lastT": 1,
            "hits": 0, "damage": 0, "skills": {}, "dead": False,
        }

    def summon_hit(self, guid, amount, skill=100):
        sm = self.summons[guid]
        sm["hits"] += 1
        sm["damage"] += amount
        sm["skills"][skill] = sm["skills"].get(skill, 0) + 1

    def school_name(self, mask):
        return {32: "暗影", 64: "奥术"}.get(mask, str(mask))

    def eval_step(self, step):
        s = self.stats.get(step.get("id"), {})
        want = step["want"]
        combat = self.combat()
        result = {"step": step, "status": "nodata", "detail": ""}
        if want in ("aura-self", "aura-target"):
            unit = "player" if want == "aura-self" else "target"
            count = s.get("auraSelf", 0) if want == "aura-self" else s.get("auraTarget", 0)
            found = step.get("id") and self.find_aura(unit, step["id"])
            if count or found:
                result["status"] = "pass"
            elif step.get("hidden"):
                result["status"] = "info"
            elif combat:
                result["status"] = "fail"
        elif want == "cast":
            result["status"] = "pass" if s.get("casts") else ("fail" if combat else "nodata")
        elif want in ("damage", "damage-aura"):
            if s.get("damageN", 0) > 0:
                result["status"] = "pass"
                expect = step.get("expect") or {}
                if expect.get("school") and s.get("school") not in ("-", None):
                    if s["school"] != self.school_name(expect["school"]):
                        result["status"] = "fail"
            elif combat:
                result["status"] = "fail"
        elif want == "summon":
            n = len(self.summons)
            dmg = sum(x["damage"] for x in self.summons.values())
            need = (step.get("expect") or {}).get("minCount", 1)
            deals = (step.get("expect") or {}).get("dealsDamage")
            if n >= need and (not deals or dmg > 0):
                result["status"] = "pass"
            elif combat:
                result["status"] = "fail"
        elif want == "stat":
            key = (step.get("expect") or {}).get("stat", "haste")
            mind = (step.get("expect") or {}).get("minDelta", 0.01)
            delta = (s.get("statDelta") or {}).get(key)
            if isinstance(delta, (int, float)) and abs(delta) >= mind:
                result["status"] = "pass"
            elif combat or s.get("statDelta"):
                result["status"] = "fail"
        elif want == "labmsg":
            msgs = self.labMsgs.get(step.get("labType"), [])
            if msgs:
                last = msgs[-1]["kv"]
                result["status"] = "pass"
                for k, v in (step.get("expect") or {}).items():
                    if k in SPECIAL:
                        continue
                    if str(last.get(k)) != str(v):
                        result["status"] = "fail"
                        result["detail"] = f"{k}={last.get(k)} 期望 {v}"
            elif combat:
                result["status"] = "fail"
        return result

    def first_fail(self, results):
        for r in results:
            if r["status"] == "fail":
                return r
        return None

    def pct(self, sid, expect):
        s = self.stats.get(sid, {})
        if not s.get("damageN") or not s.get("playerMaxHp"):
            return None
        sample = s.get("damageMax") or 0
        pct = sample / s["playerMaxHp"]
        want = expect["pctOfMaxHp"]
        tol = expect.get("tolerance", 0.2)
        return {"pct": pct, "ok": abs(pct - want) <= want * tol}

    def half(self, sid, expect):
        s = self.stats.get(sid, {})
        pts = sorted(s.get("perTarget", {}).values(), key=lambda p: p["firstT"])
        hf = expect.get("halfFrom")
        if not hf or len(pts) < hf:
            return None
        first = [p["sum"] / p["hits"] for p in pts[: hf - 1]]
        rest = [p["sum"] / p["hits"] for p in pts[hf - 1 :]]
        fm, rm = sum(first) / len(first), sum(rest) / len(rest)
        return {"ok": (rm / fm) <= 0.5 * 1.15, "ratio": rm / fm}

    def proc_stats(self, times):
        n = len(times)
        if n == 0:
            return {"n": 0}
        span = max(0, times[-1] - times[0])
        gaps = [times[i] - times[i - 1] for i in range(1, n)]
        ppm = n / (span / 60) if span else 0
        return {
            "n": n, "span": span, "ppm": ppm,
            "minGap": min(gaps) if gaps else None,
            "sampleLow": n < 3 or span < 20,
        }


def test_engine() -> None:
    print("\n== 引擎行为 ==")
    typ, kv = parse_lab("[HavenLab] STAR_VISUAL spell=317262 visual=93802 delay=1.00 missile=1 target=Dummy")
    if typ == "STAR_VISUAL" and kv.get("missile") == 1 and kv.get("visual") == 93802:
        ok("解析 STAR_VISUAL")
    else:
        fail("解析 STAR_VISUAL", str((typ, kv)))

    typ, kv = parse_lab("[HavenLab] TWILIGHT_VISUAL spell=317155 visual=93766 hits=0 damage=6000 beam=1")
    if typ == "TWILIGHT_VISUAL" and kv.get("beam") == 1 and kv.get("damage") == 6000:
        ok("解析 TWILIGHT_VISUAL")
    else:
        fail("解析 TWILIGHT_VISUAL", str((typ, kv)))

    typ, kv = parse_lab("[HavenLab] ECHO_COLLAPSE stacks=4")
    if typ == "ECHO_COLLAPSE" and kv.get("stacks") == 4:
        ok("解析 ECHO_COLLAPSE")
    else:
        fail("解析 ECHO_COLLAPSE", str((typ, kv)))

    if parse_lab("labstars: 317257 on Bob")[0] is None:
        ok("非 LAB 系统消息不误解析")
    else:
        fail("误解析", "普通系统消息被当成 LAB")

    # 星：有 visual + 奥术伤
    e = Engine()
    e.add_lab("[HavenLab] STAR_VISUAL spell=317262 visual=93802 delay=1.00 missile=1 target=Dummy")
    e.add_damage(317265, 1200, school=64)
    e.add_aura(317265, "target")
    stars_chain = [
        {"id": 317257, "role": "隐藏proc", "want": "aura-self", "hidden": True},
        {"id": 317262, "role": "导弹", "want": "labmsg", "labType": "STAR_VISUAL", "expect": {"missile": 1}},
        {"id": 317265, "role": "伤害/叠层", "want": "damage-aura", "expect": {"school": 64}},
    ]
    rs = [e.eval_step(s) for s in stars_chain]
    if rs[0]["status"] == "info" and rs[1]["status"] == "pass" and rs[2]["status"] == "pass" and e.first_fail(rs) is None:
        ok("星包：visual+伤害通过，隐藏光环是说明")
    else:
        fail("星包通过路径", str([r["status"] for r in rs]))

    # 星：有平砍无伤害 → 断在伤害环
    e2 = Engine()
    e2.logs.append({"spellId": 0, "isDamage": True, "sGUID": "P1"})
    e2.add_lab("[HavenLab] STAR_VISUAL spell=317262 visual=0 delay=1.00 missile=1 target=Dummy")
    rs2 = [e2.eval_step(s) for s in stars_chain]
    fail_step = e2.first_fail(rs2)
    if fail_step and fail_step["step"]["role"] == "伤害/叠层":
        ok("星包：有 visual 无伤害 → 断在伤害环")
    else:
        fail("星包断环", str([r["status"] for r in rs2]))

    # 暮光：生命% + 半伤
    e3 = Engine()
    e3.maxhp = 100000
    e3.add_lab("[HavenLab] TWILIGHT_VISUAL spell=317155 visual=93766 hits=7 damage=6000 beam=1")
    for i in range(1, 8):
        amt = 6000 if i < 6 else 3000
        e3.add_damage(317159, amt, dest=f"T{i}", name=f"桩{i}", school=32)
        e3.stat(317159)["playerMaxHp"] = 100000
    tw_dmg = {"id": 317159, "role": "暗影伤害", "want": "damage",
              "expect": {"school": 32, "pctOfMaxHp": 0.06, "tolerance": 0.2, "maxTargets": 10, "halfFrom": 6}}
    r = e3.eval_step(tw_dmg)
    pct = e3.pct(317159, tw_dmg["expect"])
    half = e3.half(317159, tw_dmg["expect"])
    if r["status"] == "pass" and pct and pct["ok"] and half and half["ok"]:
        ok("暮光：6% 生命 + 第6个起半伤")
    else:
        fail("暮光半伤/生命%", f"step={r['status']} pct={pct} half={half}")

    # 暮光脸没对准
    e4 = Engine()
    e4.logs.append({"spellId": 0, "isDamage": True, "sGUID": "P1"})
    r4 = e4.eval_step(tw_dmg)
    if r4["status"] == "fail":
        ok("暮光：有平砍无斩击 → 失败")
    else:
        fail("暮光失败", r4["status"])

    # 假 pack 只靠数据
    e5 = Engine()
    e5.add_damage(1, 50, school=1)
    e5.stat(1)["school"] = "-"  # 不验学派
    fake = {"id": 1, "role": "演示伤害", "want": "damage"}
    if e5.eval_step(fake)["status"] == "pass":
        ok("假 pack 零引擎改动可出通过")
    else:
        fail("假 pack", "damage 步骤未通过")

    # 召唤
    e6 = Engine()
    e6.logs.append({"spellId": 0, "isDamage": True, "sGUID": "P1"})
    e6.add_summon("S1")
    e6.summon_hit("S1", 800)
    sm = {"id": 9, "role": "触须", "want": "summon", "expect": {"minCount": 1, "dealsDamage": True}}
    if e6.eval_step(sm)["status"] == "pass":
        ok("召唤跟踪：有输出算通过")
    else:
        fail("召唤跟踪", e6.eval_step(sm)["status"])

    # 触发率
    ps = Engine().proc_stats([0, 4.2, 8.5, 13.0])
    if ps["n"] == 4 and abs(ps["minGap"] - 4.2) < 0.05 and ps["ppm"] > 0:
        ok("触发率：次数/最小间隔/PPM")
    else:
        fail("触发率", str(ps))

    # ICD
    ps2 = Engine().proc_stats([0, 0.4, 1.2])
    if ps2["minGap"] is not None and ps2["minGap"] * 1000 < 700:
        ok("ICD：最小间隔短于 700ms 可检出")
    else:
        fail("ICD", str(ps2))

    # 属性
    e7 = Engine()
    e7.stat(100)["statDelta"] = {"haste": 6.2}
    st = {"id": 100, "role": "权宜", "want": "stat", "expect": {"stat": "haste", "minDelta": 6}}
    if e7.eval_step(st)["status"] == "pass":
        ok("属性快照：急速 +6.2 通过")
    else:
        fail("属性快照", e7.eval_step(st)["status"])

    # 回响生命% 0.4%
    e8 = Engine()
    e8.add_lab("[HavenLab] ECHO_COLLAPSE stacks=3")
    e8.add_damage(317029, 400, school=32)
    e8.stat(317029)["playerMaxHp"] = 100000
    info = e8.pct(317029, {"pctOfMaxHp": 0.004, "tolerance": 0.25})
    if info and info["ok"]:
        ok("回响：0.4% 生命校验")
    else:
        fail("回响生命%", str(info))


def test_lua_braces() -> None:
    print("\n== Lua 括号 ==")
    for name in ("HavenLab.lua", "HavenLab_Packs.lua", "HavenLab_Track.lua", "HavenLab_Verdict.lua", "HavenLab_UI.lua"):
        text = read(os.path.join(ADDON, name))
        text = re.sub(r"--\[\[[\s\S]*?\]\]", "", text)
        text = re.sub(r"--[^\n]*", "", text)
        text = re.sub(r'"(?:\\.|[^"\\])*"', "", text)
        text = re.sub(r"'(?:\\.|[^'\\])*'", "", text)
        bal = 0
        bad = False
        for ch in text:
            if ch == "{":
                bal += 1
            elif ch == "}":
                bal -= 1
            if bal < 0:
                bad = True
        if bad or bal != 0:
            fail("括号 " + name, f"balance={bal} underflow={bad}")
        else:
            ok("括号 " + name)


def test_report_coverage() -> None:
    print("\n== 报告覆盖旧结论关键词 ==")
    packs = read(os.path.join(ADDON, "HavenLab_Packs.lua"))
    verdict = read(os.path.join(ADDON, "HavenLab_Verdict.lua"))
    text = packs + verdict
    for word in (
        "平砍", "STAR_VISUAL", "TWILIGHT_VISUAL", "317265", "317159",
        "隐藏光环", "脸没对准", "手打伤害", "普攻不出星",
    ):
        if word in text:
            ok("文案保留：" + word)
        else:
            fail("文案保留", word)


def main() -> int:
    print("HavenLab 2.0 离线测试")
    print("addon = " + ADDON)
    print("core  = " + CORE)
    if not os.path.isfile(os.path.join(ADDON, "HavenLab.toc")):
        print("找不到插件目录")
        return 2
    test_server()
    test_addon_layout()
    test_lua_braces()
    test_engine()
    test_report_coverage()
    print("\n== 汇总 ==")
    print(f"通过 {len(PASSES)}  失败 {len(FAILS)}")
    for item in FAILS:
        print("  - " + item)
    if FAILS:
        print("\n进游戏（你部署服务端之后）再验：")
        print("  .lab test stars  应等于 .labstars")
        print("  .lab test twilight / echo / .lab clear")
        print("  打桩后报告里要有 LAB 行、目标表、触发率")
        return 1
    print("\n离线项已过。部署 worldserver 后请再打一轮星/暮光，确认报告不丢旧信息。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
