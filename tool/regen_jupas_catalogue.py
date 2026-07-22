#!/usr/bin/env python3
"""從 JUPAS 官方課程頁解析 Programme Entrance Requirements，重生 lib/data/jupas/catalogue/*.dart。

用法:
  python3 tool/regen_jupas_catalogue.py          # 用 cache，缺則抓網
  python3 tool/regen_jupas_catalogue.py --fresh  # 清 cache 全量重抓
"""

from __future__ import annotations

import argparse
import json
import re
import time
import urllib.request
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = Path.home() / (
    ".cursor/projects/Users-antonli-Desktop-HKsimlife/agent-tools/"
    "9f8977b2-12fb-427e-a580-9adf57e43df1.txt"
)
CACHE = ROOT / "tool" / "jupas_cache"
OUT = ROOT / "lib" / "data" / "jupas" / "catalogue"

SLUG = {
    "CityUHK": "cityuhk",
    "HKBU": "hkbu",
    "LingnanU": "lingnanu",
    "CUHK": "cuhk",
    "EdUHK": "eduhk",
    "PolyU": "polyu",
    "HKUST": "hkust",
    "HKU": "hku",
    "HKMU": "hkmu",
    "SSSDP": "sssdp",
}
INST_ZH = {
    "CityUHK": "城大",
    "HKBU": "浸大",
    "LingnanU": "嶺大",
    "CUHK": "中大",
    "EdUHK": "教大",
    "PolyU": "理大",
    "HKUST": "科大",
    "HKU": "港大",
    "HKMU": "都會",
    "SSSDP": "SSSDP",
}
SSSDP_OFFERER = {
    "SFU": "聖方濟各",
    "HKCHC": "珠海學院",
    "HSUHK": "恒大",
    "TWC": "東華學院",
    "HKMU": "都會",
    "VTC-THEi": "THEi",
    "UOWCHK": "伍倫貢學院",
    "HKSYU": "樹仁",
}
FILE_MAP = {
    "CityUHK": ("cityu.dart", "cityuProgrammes"),
    "HKBU": ("hkbu.dart", "hkbuProgrammes"),
    "LingnanU": ("lingnan.dart", "lingnanProgrammes"),
    "CUHK": ("cuhk.dart", "cuhkProgrammes"),
    "EdUHK": ("eduhk.dart", "eduhkProgrammes"),
    "PolyU": ("polyu.dart", "polyuProgrammes"),
    "HKUST": ("hkust.dart", "hkustProgrammes"),
    "HKU": ("hku.dart", "hkuProgrammes"),
    "HKMU": ("hkmu.dart", "hkmuProgrammes"),
    "SSSDP": ("sssdp.dart", "sssdpProgrammes"),
}

CORE_PATS = [
    (r"CHINESE LANGUAGE", "chin"),
    (r"ENGLISH LANGUAGE", "eng"),
    (r"MATHEMATICS COMPULSORY PART", "math"),
    (r"CITIZENSHIP AND SOCIAL DEVELOPMENT", "csd"),
]
NAMED_PATS = [
    (r"BIOLOGY", "bio"),
    (r"CHEMISTRY", "chem"),
    (r"PHYSICS", "phy"),
    (r"INFORMATION AND COMMUNICATION TECHNOLOGY", "ict"),
    (r"BUSINESS,\s*ACCOUNTING AND FINANCIAL STUDIES", "bafs"),
    (r"ECONOMICS", "econ"),
    (r"CHINESE HISTORY", "chist"),
    (r"CHINESE LITERATURE", "chinlit"),
    (r"LITERATURE IN ENGLISH", "englit"),
    (r"HISTORY", "hist"),
    (r"GEOGRAPHY", "geog"),
    (r"TOURISM AND HOSPITALITY STUDIES", "ths"),
    (r"HEALTH MANAGEMENT AND SOCIAL CARE", "hmsc"),
    (r"VISUAL ARTS", "va"),
    (r"PHYSICAL EDUCATION", "pe"),
    (r"DESIGN AND APPLIED TECHNOLOGY", "dat"),
    (r"MATHEMATICS EXTENDED MODULE 1 OR 2", "m1_m2"),
    (r"MATHEMATICS EXTENDED PART MODULE 1 OR 2", "m1_m2"),
]

ROW_RE = re.compile(
    r"\|\s*(CityUHK|HKBU|LingnanU|CUHK|EdUHK|PolyU|HKUST|HKU|HKMU|SSSDP)\s*"
    r"\|\s*(JS[A-Z0-9]+)\s*\|\s*([^|]+)\|\s*([^|]+)\|\s*([^|]+)\|"
)


def load_programmes() -> list[dict]:
    text = SRC.read_text(encoding="utf-8")
    return [
        {
            "inst": a,
            "code": b,
            "funding": c.strip(),
            "short": d.strip(),
            "title": e.strip(),
        }
        for a, b, c, d, e in ROW_RE.findall(text)
    ]


def fetch(url: str) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read().decode("utf-8", "replace")


def table_text(table_html: str) -> str:
    t = re.sub(r"(?is)<[^>]+>", " ", table_html)
    t = re.sub(r"&nbsp;", " ", t)
    return re.sub(r"\s+", " ", t).strip()


def level_from_nums(nums: list[int]) -> int:
    """Prefer HKDSE levels 2–5; ignore footnote markers like 1 before a real level."""
    cands = [n for n in nums if 2 <= n <= 5]
    if cands:
        return cands[-1]
    return nums[-1] if nums else 3


def parse_core(table: str) -> dict[str, int]:
    text = table_text(table)
    out: dict[str, int] = {}
    for pat, sid in CORE_PATS:
        m = re.search(pat + r"(?:Note\d+)?\s*(Attained|\d+)", text, re.I)
        if not m:
            continue
        v = m.group(1)
        out[sid] = 1 if v.lower() == "attained" else int(v)
    return out


# 用於「BIOLOGY or CHEMISTRY or PHYSICS 3」這類同一格 OR
_OR_NAME_ALTS = "|".join(
    f"(?:{pat})" for pat, sid in NAMED_PATS if sid != "m1_m2"
)
_OR_GROUP_RE = re.compile(
    rf"((?:{_OR_NAME_ALTS})(?:\s+or\s+(?:{_OR_NAME_ALTS}))+)\s+(\d+)",
    re.I,
)


def _sid_from_name_token(token: str) -> str | None:
    t = token.strip()
    for pat, sid in NAMED_PATS:
        if sid == "m1_m2":
            continue
        if re.fullmatch(pat, t, re.I):
            return sid
    return None


def parse_branch(branch: str) -> tuple[list[dict], dict[str, int], list[dict]]:
    """回傳 (any_reqs, named_singleton, oneof_groups)。"""
    any_reqs: list[dict] = []
    for m in re.finditer(
        r"ANY\s+(\d+)\s+SUBJECTS?\b(.{0,100}?)(?=ANY\s+\d+\s+SUBJECT|One of the following|Or\b|$)",
        branch,
        re.I,
    ):
        count = int(m.group(1))
        nums = [int(x) for x in re.findall(r"\d+", m.group(0))]
        if nums and nums[0] == count:
            nums = nums[1:]
        any_reqs.append(
            {"oneOf": [], "minLevel": level_from_nums(nums), "count": count}
        )
    if not any_reqs:
        for m in re.finditer(r"ANY\s+1\s+SUBJECT\b([^A-Z]{0,80})", branch, re.I):
            nums = [int(x) for x in re.findall(r"\d+", m.group(0))]
            if nums and nums[0] == 1:
                nums = nums[1:]
            any_reqs.append(
                {
                    "oneOf": [],
                    "minLevel": level_from_nums(nums),
                    "count": 1,
                }
            )

    oneof_groups: list[dict] = []
    covered_spans: list[tuple[int, int]] = []
    for m in _OR_GROUP_RE.finditer(branch):
        lv = int(m.group(2))
        parts = re.split(r"\s+or\s+", m.group(1), flags=re.I)
        ids: list[str] = []
        for part in parts:
            sid = _sid_from_name_token(part)
            if sid:
                ids.append(sid)
        if len(ids) >= 2:
            oneof_groups.append(
                {"oneOf": sorted(set(ids)), "minLevel": lv, "count": 1}
            )
            covered_spans.append(m.span())

    def in_covered(pos: int) -> bool:
        return any(a <= pos < b for a, b in covered_spans)

    named: dict[str, int] = {}
    for pat, sid in NAMED_PATS:
        for m in re.finditer(pat + r"\s+(\d+)", branch, re.I):
            if in_covered(m.start()):
                continue
            lv = int(m.group(1))
            if sid == "m1_m2":
                named["m1"] = max(named.get("m1", 0), lv)
                named["m2"] = max(named.get("m2", 0), lv)
            else:
                named[sid] = max(named.get(sid, 0), lv)
    return any_reqs, named, oneof_groups


def merge_or_electives(
    branch_data: list[tuple[list[dict], dict[str, int], list[dict]]],
) -> list[dict]:
    """合併如 Bio+Any OR Chem+Any → oneOf(bio,chem)+any；保留同格 OR 群組。"""
    # 若任一 branch 已有同格 OR（bio|chem|phy），優先用該 branch
    for any_reqs, named, groups in branch_data:
        if groups:
            result = [dict(g) for g in groups]
            # 同科 singleton 不再重複
            group_ids = {i for g in groups for i in g["oneOf"]}
            real_named = {
                k: v
                for k, v in named.items()
                if k not in ("m1", "m2") and k not in group_ids
            }
            for k, lv in real_named.items():
                result.append({"oneOf": [k], "minLevel": lv, "count": 1})
            if any_reqs:
                lv = max(a["minLevel"] for a in any_reqs)
                result.append({"oneOf": [], "minLevel": max(2, lv), "count": 1})
            elif not any(not g["oneOf"] for g in result):
                # 通常還要一科 unspecified；若已有 any 就唔加
                pass
            return result

    alt_named: list[tuple[str, int]] = []
    alt_any_lv: list[int] = []
    for any_reqs, named, _groups in branch_data:
        real = {k: v for k, v in named.items() if k not in ("m1", "m2")}
        if len(real) == 1 and sum(a["count"] for a in any_reqs) >= 1:
            sid, lv = next(iter(real.items()))
            alt_named.append((sid, lv))
            alt_any_lv.append(max(a["minLevel"] for a in any_reqs))
    if len(alt_named) >= 2 and len({s for s, _ in alt_named}) >= 2:
        subjects = sorted({s for s, _ in alt_named})
        subj_lv = min(lv for _, lv in alt_named)
        any_lv = max(2, min(alt_any_lv) if alt_any_lv else 3)
        return [
            {"oneOf": subjects, "minLevel": subj_lv, "count": 1},
            {"oneOf": [], "minLevel": any_lv, "count": 1},
        ]

    def score(any_reqs: list[dict], named: dict[str, int], _g: list) -> tuple:
        real_named = {k: v for k, v in named.items() if k not in ("m1", "m2")}
        return (len(real_named), sum(a["count"] for a in any_reqs), -len(named))

    any_reqs, named, groups = max(branch_data, key=lambda x: score(*x))
    real_named = {k: v for k, v in named.items() if k not in ("m1", "m2")}
    result: list[dict] = []
    if real_named:
        by_lv: dict[int, list[str]] = defaultdict(list)
        for k, lv in real_named.items():
            by_lv[lv].append(k)
        for lv, ids in sorted(by_lv.items(), reverse=True):
            result.append(
                {"oneOf": sorted(set(ids)), "minLevel": lv, "count": 1}
            )
        lv = max((a["minLevel"] for a in any_reqs), default=3)
        result.append({"oneOf": [], "minLevel": max(2, lv), "count": 1})
    else:
        total = sum(a["count"] for a in any_reqs)
        lv = max((a["minLevel"] for a in any_reqs), default=3)
        if total >= 2:
            result.append({"oneOf": [], "minLevel": max(2, lv), "count": 2})
        elif total == 1:
            result.append(
                {
                    "oneOf": [],
                    "minLevel": max(2, lv),
                    "count": 2 if named else 1,
                }
            )
        else:
            result.append({"oneOf": [], "minLevel": 3, "count": 2})
    return result


def parse_electives(table: str | None) -> list[dict]:
    if not table:
        return [{"oneOf": [], "minLevel": 3, "count": 2}]
    text = table_text(table)
    # 只切官方表格的分支列「Or」（大寫）；唔好切 "BIOLOGY or CHEMISTRY"
    branches = re.split(r"\s+Or\s+", text)
    branch_data = [parse_branch(b) for b in branches]
    return merge_or_electives(branch_data)


def parse_html(html: str) -> dict:
    tables = re.findall(r"(?is)<table[^>]*>.*?</table>", html)
    core_t = elec_t = None
    for t in tables:
        tt = table_text(t).upper()
        if "BAND A" in tt:
            continue
        if core_t is None and "CHINESE LANGUAGE" in tt and "ENGLISH LANGUAGE" in tt:
            core_t = t
            continue
        if (
            core_t is not None
            and elec_t is None
            and (
                "ELECTIVE" in tt
                or "ANY 1 SUBJECT" in tt
                or "ANY 2 SUBJECT" in tt
                or "BIOLOGY" in tt
            )
        ):
            elec_t = t
            break
    if not core_t:
        return {"ok": False, "error": "no_core"}
    core = parse_core(core_t)
    return {
        "ok": True,
        "chin": core.get("chin", 3),
        "eng": core.get("eng", 3),
        "math": core.get("math", 2),
        "csd": core.get("csd", 1),
        "electives": parse_electives(elec_t),
        "elec_preview": table_text(elec_t)[:220] if elec_t else "",
    }


def cache_paths(inst: str, code: str) -> tuple[Path, Path]:
    return CACHE / f"{inst}_{code}.json", CACHE / f"{inst}_{code}.html"


def load_or_fetch(inst: str, code: str, force: bool = False) -> dict:
    jpath, hpath = cache_paths(inst, code)
    url = f"https://www.jupas.edu.hk/en/programme/{SLUG[inst]}/{code}/"
    if not force and hpath.exists():
        html = hpath.read_text(encoding="utf-8")
        data = (
            {"ok": False, "error": "404", "url": url}
            if "Page Not Found" in html
            else {**parse_html(html), "url": url}
        )
        jpath.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
        return data
    if not force and jpath.exists() and not hpath.exists():
        # 舊 cache 無 HTML：仍可用 JSON，但無法用新 parser 重解選修
        return json.loads(jpath.read_text(encoding="utf-8"))
    try:
        html = fetch(url)
        hpath.write_text(html, encoding="utf-8")
        data = (
            {"ok": False, "error": "404", "url": url}
            if "Page Not Found" in html
            else {**parse_html(html), "url": url}
        )
    except Exception as e:  # noqa: BLE001
        data = {"ok": False, "error": str(e), "url": url}
    jpath.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
    return data


def infer_meta(title: str, short: str, req: dict) -> tuple[str, str, int, list[str]]:
    t = (title + " " + short).lower()
    tags: list[str] = []
    formula = "best5"
    # expected／formula 最終以 OfficialScoreOverlay（JUPAS 官方 PDF）為準；
    # 呢度只俾未覆蓋課程一個保守 fallback，避免估出「best5 但 41 分」死門。
    expected = 22
    award = "bachelor"
    if "higher diploma" in t or short.strip().startswith("HD("):
        award = "higherDiploma"
        tags.append("hd")
        expected = 12
    if any(
        k in t
        for k in ["mbbs", "mbchb", "medicine", "veterinary", "bvm", "dental", "bds"]
    ):
        tags += ["med", "elite"]
        formula = "best6"
        expected = max(expected, 38)
    elif any(k in t for k in ["pharmacy", "bpharm"]):
        tags += ["pharmacy", "stem"]
        formula = "best6"
        expected = max(expected, 34)
    elif "llb" in t or short.upper() == "LLB" or "bachelor of laws" in t:
        tags += ["law", "elite"]
        expected = max(expected, 32)
    elif "nursing" in t:
        tags += ["nursing"]
        expected = max(expected, 22)
    elif any(
        k in t
        for k in [
            "physiotherapy",
            "occupational therapy",
            "radiography",
            "optometry",
            "speech",
        ]
    ):
        tags += ["health", "elite"]
        expected = max(expected, 30)
    elif "engineering" in t or "beng" in t:
        tags += ["engineering", "stem"]
        expected = max(expected, 24)
    elif any(
        k in t
        for k in [
            "computer science",
            "data science",
            "artificial intelligence",
            "fintech",
        ]
    ):
        tags += ["stem"]
        expected = max(expected, 25)
    elif any(
        k in t
        for k in [
            "business",
            "bba",
            "finance",
            "account",
            "marketing",
            "economics",
        ]
    ):
        tags += ["business"]
        formula = "engMathWeighted"
        expected = max(expected, 22)
    elif "education" in t or "bed" in t:
        tags += ["education"]
        expected = max(expected, 16)
    elif any(
        k in t
        for k in ["social", "psychology", "sociology", "social work"]
    ):
        tags += ["social"]
        expected = max(expected, 20)
    elif any(
        k in t
        for k in [
            "arts",
            "history",
            "philosophy",
            "chinese",
            "english",
            "translation",
        ]
    ):
        tags += ["arts"]
        expected = max(expected, 18)
    else:
        tags += ["general"]
    expected += (
        max(0, req.get("eng", 3) - 3) * 2
        + max(0, req.get("math", 2) - 2)
        + max(0, req.get("chin", 3) - 3)
    )
    return award, formula, max(10, expected), tags


def esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace("'", "\\'")


def elec_dart(elecs: list[dict]) -> str:
    if len(elecs) == 1 and not elecs[0]["oneOf"]:
        e = elecs[0]
        if e["count"] == 2 and e["minLevel"] == 3:
            return "const [ElectiveRequirement.anyTwoAt3]"
        if e["count"] == 2 and e["minLevel"] == 2:
            return "const [ElectiveRequirement.anyTwoAt2]"
        if e["count"] == 1 and e["minLevel"] == 2:
            return "const [ElectiveRequirement.anyOneAt2]"
        if e["count"] == 1 and e["minLevel"] == 3:
            return "const [ElectiveRequirement.anyOneAt3]"
    parts = []
    for e in elecs:
        if e["oneOf"]:
            ids = ", ".join(f"'{x}'" for x in e["oneOf"])
            parts.append(
                "ElectiveRequirement("
                f"oneOf: [{ids}], minLevel: {e['minLevel']}, count: {e['count']})"
            )
        else:
            parts.append(
                f"ElectiveRequirement(minLevel: {e['minLevel']}, count: {e['count']})"
            )
    return "[\n          " + ",\n          ".join(parts) + ",\n        ]"


def write_catalogues(programmes: list[dict], results: dict) -> int:
    by_inst: dict[str, list] = defaultdict(list)
    for p in programmes:
        by_inst[p["inst"]].append(p)
    header = """import '../jupas_models.dart';

/// 由 JUPAS 官方課程頁「Programme Entrance Requirements」table 解析（非 GER）。
/// 重生：python3 tool/regen_jupas_catalogue.py
"""
    fallback = 0
    for inst, (fname, fn) in FILE_MAP.items():
        lines = [header, f"List<JupasProgramme> {fn}() => ["]
        for p in by_inst[inst]:
            req = results[(p["inst"], p["code"])]
            if not req.get("ok"):
                fallback += 1
                req = {
                    "chin": 3,
                    "eng": 3,
                    "math": 2,
                    "csd": 1,
                    "electives": [{"oneOf": [], "minLevel": 3, "count": 2}],
                }
            award, formula, expected, tags = infer_meta(
                p["title"], p["short"], req
            )
            inst_zh = INST_ZH[inst]
            name_zh = p["title"]
            if inst == "SSSDP":
                om = re.search(r"Offered by ([^:]+):", p["title"])
                offerer = om.group(1).strip() if om else "SSSDP"
                inst_zh = SSSDP_OFFERER.get(offerer, offerer)
                name_zh = re.sub(r"^Offered by [^:]+:\s*", "", p["title"])
                if "sssdp" not in tags:
                    tags = ["sssdp", *tags]
                expected = max(10, expected - 6)
            chin, eng, math = int(req["chin"]), int(req["eng"]), int(req["math"])
            elecs = req.get("electives") or [
                {"oneOf": [], "minLevel": 3, "count": 2}
            ]
            award_s = (
                "" if award == "bachelor" else f"\n        award: JupasAward.{award},"
            )
            formula_s = (
                ""
                if formula == "best5"
                else f"\n        formula: JupasScoreFormula.{formula},"
            )
            ger = []
            if chin != 3:
                ger.append(f"chinMin: {chin}")
            if eng != 3:
                ger.append(f"engMin: {eng}")
            if math != 2:
                ger.append(f"mathMin: {math}")
            ger_s = "".join(f"\n        {g}," for g in ger)
            tags_s = ", ".join(f"'{t}'" for t in tags)
            lines.append(
                f"""      JupasProgramme(
        code: '{p['code']}',
        nameZh: '{esc(name_zh)}',
        nameEn: '{esc(p['short'])}',
        institution: '{esc(inst_zh)}',{award_s}{ger_s}
        electiveRequirements: {elec_dart(elecs)},{formula_s}
        expectedScore: {expected},
        tags: [{tags_s}],
      ),"""
            )
        lines.append("];\n")
        (OUT / fname).write_text("\n".join(lines), encoding="utf-8")
    return fallback


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--fresh",
        action="store_true",
        help="清除 cache 並全量重抓",
    )
    ap.add_argument(
        "--reparse",
        action="store_true",
        help="只用已有 HTML 重解析（不抓網）",
    )
    args = ap.parse_args()
    CACHE.mkdir(parents=True, exist_ok=True)
    if args.fresh:
        for p in CACHE.glob("*"):
            p.unlink()

    programmes = load_programmes()
    print(f"programmes={len(programmes)}")

    results: dict[tuple[str, str], dict] = {}
    ok = fail = 0
    batch = 10

    def one(p: dict) -> tuple[tuple[str, str], dict]:
        key = (p["inst"], p["code"])
        if args.reparse:
            _, hpath = cache_paths(p["inst"], p["code"])
            if hpath.exists():
                html = hpath.read_text(encoding="utf-8")
                url = f"https://www.jupas.edu.hk/en/programme/{SLUG[p['inst']]}/{p['code']}/"
                data = (
                    {"ok": False, "error": "404", "url": url}
                    if "Page Not Found" in html
                    else {**parse_html(html), "url": url}
                )
                cache_paths(p["inst"], p["code"])[0].write_text(
                    json.dumps(data, ensure_ascii=False), encoding="utf-8"
                )
                return key, data
        return key, load_or_fetch(p["inst"], p["code"], force=args.fresh)

    for i in range(0, len(programmes), batch):
        chunk = programmes[i : i + batch]
        with ThreadPoolExecutor(max_workers=batch) as ex:
            futs = [ex.submit(one, p) for p in chunk]
            for fut in as_completed(futs):
                key, data = fut.result()
                results[key] = data
                if data.get("ok"):
                    ok += 1
                else:
                    fail += 1
        done = min(i + batch, len(programmes))
        if done % 50 == 0 or done == len(programmes):
            print(f"{done}/{len(programmes)} ok={ok} fail={fail}")
        if not args.reparse:
            time.sleep(0.15)

    # spot checks
    for k in [
        ("HKU", "JS6456"),
        ("HKU", "JS6406"),
        ("CUHK", "JS4501"),
        ("HKU", "JS6494"),
    ]:
        r = results[k]
        print(k, r.get("chin"), r.get("eng"), r.get("math"), r.get("electives"))

    fallback = write_catalogues(programmes, results)
    named = sum(
        1
        for v in results.values()
        if v.get("ok")
        and any(e.get("oneOf") for e in v.get("electives", []))
    )
    print(f"fallback={fallback} named_gates={named}")


if __name__ == "__main__":
    main()
