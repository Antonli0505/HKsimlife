#!/usr/bin/env python3
"""Parse official JUPAS + SSSDP 2025 admissions score PDFs → overlay Dart.

Inputs (tool/jupas_cache/):
  af_2025_JUPAS_fitz.txt   (from PyMuPDF)
  af_2025_SSSDP_fitz.txt
  af_2025_JUPAS.md         (optional CUHK table fallback)

UGC 2025 conversion: 5**=8.5, 5*=7, 5=5.5  (legacyScale=false)
SSSDP / CUHK MBChB:   5**=7, 5*=6, 5=5      (legacyScale=true)
PolyU uses a proprietary high-scale weighted total — skipped for expectedScore.
"""

from __future__ import annotations

import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CACHE = ROOT / "tool" / "jupas_cache"
OUT = ROOT / "lib" / "data" / "jupas" / "official_score_overlay.dart"

MIN_STD, MAX_STD = 12.0, 75.0  # standard Best5/6 scale (8.5 or 7)
CODE_RE = re.compile(r"\b(JS[A-Z]?\d{4}|JS[A-Z]{1,2}\d{2})\b")


def ensure_fitz_text() -> None:
    try:
        import fitz  # PyMuPDF
    except ImportError:
        return
    for name in ("af_2025_JUPAS", "af_2025_SSSDP"):
        pdf = CACHE / f"{name}.pdf"
        out = CACHE / f"{name}_fitz.txt"
        if not pdf.exists():
            continue
        if out.exists() and out.stat().st_mtime >= pdf.stat().st_mtime:
            continue
        doc = fitz.open(pdf)
        out.write_text("\n".join(page.get_text() for page in doc), encoding="utf-8")


def parse_weights(text: str) -> dict[str, float]:
    t = text.lower().replace("\n", " ")
    weights: dict[str, float] = {}
    pairs = [
        ("chin", r"chinese(?:\s+language)?|chi\s*lang"),
        ("eng", r"english(?:\s+language)?|eng\s*lang"),
        ("math", r"mathematics(?:\s+compulsory\s+part)?|(?<![a-z])math(?![a-z0-9])"),
        ("m1", r"m1\s*(?:or|/)\s*m2|m1\s*/\s*m2"),
        ("bio", r"biology"),
        ("chem", r"chemistry"),
        ("phy", r"physics"),
        ("econ", r"economics"),
        ("geog", r"geography"),
        ("ict", r"ict|information and communication"),
        ("bafs", r"bafs|business,\s*accounting"),
        ("hmsc", r"health management"),
    ]
    for sid, pat in pairs:
        m = re.search(
            rf"(?:{pat})\s*\(\s*x\s*([0-9]+(?:\.[0-9]+)?)\s*\)|"
            rf"([0-9]+(?:\.[0-9]+)?)\s*[x×]\s*(?:{pat})",
            t,
            re.I,
        )
        if m:
            weights[sid] = float(m.group(1) or m.group(2))
    # "2: English" CityU style
    for m in re.finditer(
        r"(\d+(?:\.\d+)?)\s*:\s*(english|mathematics|chinese|biology|chemistry|physics)",
        t,
        re.I,
    ):
        name = m.group(2).lower()[:4]
        sid = {
            "engl": "eng",
            "math": "math",
            "chin": "chin",
            "biol": "bio",
            "chem": "chem",
            "phys": "phy",
        }.get(name)
        if sid:
            weights[sid] = float(m.group(1))
    return weights


def detect_formula(text: str) -> str:
    t = text.lower()
    if re.search(r"best\s*4\s*subjects?|best\s*4\b", t):
        return "best4"
    if re.search(r"6\s*graded|best\s*6\s*subjects?|best\s*6\b", t):
        return "best6"
    if re.search(
        r"1\.5\s*[x×]\s*eng.{0,50}1\.5\s*[x×]\s*math|"
        r"1\.5\s*[x×]\s*math.{0,50}1\.5\s*[x×]\s*eng",
        t,
    ):
        return "engMathWeighted"
    if re.search(r"eng\s*\+\s*best\s*5|2\s*[x×]\s*eng\s*\+\s*best", t):
        # Eng included / doubled — still best5 bucket with weight
        return "best5"
    return "best5"


def valid_std(n: float) -> bool:
    return MIN_STD <= n <= MAX_STD


def put(out: dict, code: str, formula: str, expected: float, weights: dict, legacy: bool, source: str):
    if not valid_std(expected):
        return
    code = code if code.startswith("JS") else f"JS{code}"
    # normalize JSS* already have JS
    prev = out.get(code)
    # Prefer richer weights / explicit sources
    if prev and prev.get("source") in ("hard", "sssdp", "cuhk_m", "hku_block") and source.startswith("auto"):
        return
    out[code] = {
        "formula": formula,
        "expected": float(expected),
        "weights": weights or {},
        "legacyScale": legacy,
        "source": source,
    }


def parse_sssdp(text: str) -> dict[str, dict]:
    out: dict[str, dict] = {}
    # JSSU12 ... 20 19  or JSSU12^ \n 20 \n 19
    for m in re.finditer(
        r"(JS[A-Z]{1,2}\d{2})\^?\s*(?:\n|.).{0,120}?(\d{1,2}(?:\.\d+)?)\s+(\d{1,2}(?:\.\d+)?)",
        text,
        re.S,
    ):
        code, a, b = m.group(1), float(m.group(2)), float(m.group(3))
        # median / LQ — take higher as median-ish if close
        med = a if a >= b else b
        if med > 30:  # SSSDP on 7-scale Best5 rarely >30
            continue
        if med < 10:
            continue
        window = m.group(0)
        put(out, code, "best5", med, parse_weights(window), True, "sssdp")

    # Mean-only lines: JSSA01 ... 16*  / JSSY01 ... 16.95 / JSST01 ... 16.5
    for m in re.finditer(
        r"(JS[A-Z]{1,2}\d{2})\^?\s*[^\n]{0,80}?(\d{2}(?:\.\d+)?)\*?",
        text,
    ):
        code, med = m.group(1), float(m.group(2))
        if code in out:
            continue
        if not (10 <= med <= 30):
            continue
        put(out, code, "best5", med, parse_weights(m.group(0)), True, "sssdp_mean")

    # Hard SSSDP from official PDF (WebFetch verified)
    hard = {
        "JSSC02": 14,  # Chu Hai architecture — UQ16/LQ12 mid~14 total score style; use 14
        "JSSU12": 20, "JSSU14": 16, "JSSU15": 17, "JSSU18": 16,
        "JSSU90": 16, "JSSU93": 16, "JSSU95": 16, "JSSU96": 17, "JSSU97": 17,
        "JSSU40": 21, "JSSU50": 19, "JSSU55": 22, "JSSU67": 19,
        "JSSU61": 17, "JSSU69": 17, "JSSU70": 16, "JSSU72": 17,
        "JSSU77": 17, "JSSU78": 17, "JSSU79": 17,
        "JSSY01": 16.95, "JSSY02": 15.8,
        "JSSA01": 16, "JSSA02": 16, "JSSA03": 21, "JSSA04": 17, "JSSA05": 16, "JSSA06": 16,
        "JSSV01": 14, "JSSV02": 15, "JSSV03": 16, "JSSV04": 15, "JSSV05": 16,
        "JSSV07": 14, "JSSV08": 16, "JSSV09": 14, "JSSV10": 16, "JSSV13": 15,
        "JSSH01": 16.4, "JSSH02": 17.2, "JSSH03": 16.47, "JSSH04": 16.77,
        "JSSH05": 16.34, "JSSH06": 14.93,
        "JSST01": 16.5, "JSST02": 20.0, "JSST03": 23.8, "JSST04": 21.0,
        "JSST05": 22.2, "JSST06": 15.5, "JSST07": 14.9, "JSST08": 23.7,
        "JSSW01": 15.3, "JSSW02": 16.7,
    }
    weights_extra = {
        "JSSU12": {"chin": 1.5, "eng": 1.5},
        "JSSU40": {"bio": 1.2, "chem": 1.2, "phy": 1.2, "hmsc": 1.2},
        "JSSU50": {"bio": 1.2, "chem": 1.2, "phy": 1.2, "hmsc": 1.2},
    }
    for code, med in hard.items():
        put(out, code, "best5", med, weights_extra.get(code, {}), True, "sssdp_hard")
    return out


def _hku_programme_window(text: str, start: int, max_len: int = 550) -> str:
    """Truncate HKU block at the next 4-digit programme code."""
    window = text[start : start + max_len]
    nxt = re.search(r"\n(\d{4})\s*\n", window)
    if nxt:
        window = window[: nxt.start()]
    return window


def parse_hku_blocks(text: str) -> dict[str, dict]:
    """HKU leaflet: code\\n titles\\n formula lines\\n UQ\\n Med\\n LQ"""
    out: dict[str, dict] = {}
    for m in re.finditer(r"(?:^|\n)\s*(\d{4})\s*\n", text):
        code_num = m.group(1)
        code = f"JS{code_num}"
        window = _hku_programme_window(text, m.end())
        if re.search(r"Insufficient Reference Data", window, re.I) and not re.search(
            r"\n(\d{2}(?:\.\d+)?)\s*\n(\d{2}(?:\.\d+)?)\s*\n(\d{2}(?:\.\d+)?)\b",
            window,
        ):
            continue
        # First UQ/Med/LQ triplet of 2-digit scores
        trip = re.search(
            r"(Best\s*[56]|Eng\s*\+|Math\s*\+|\d(?:\.\d+)?\s*[x×]\s*Eng|"
            r"2\s*[x×]\s*Eng|1\.5\s*[x×]\s*Eng|1\.5\s*[x×]\s*Chin|"
            r"1\.5\s*[x×]\s*Math).{0,280}?"
            r"\n(\d{2}(?:\.\d+)?)\s*\n(\d{2}(?:\.\d+)?)\s*\n(\d{2}(?:\.\d+)?)\b",
            window,
            re.S | re.I,
        )
        if not trip:
            continue
        principle = trip.group(1)
        uq, med, lq = float(trip.group(2)), float(trip.group(3)), float(trip.group(4))
        if not all(valid_std(x) for x in (uq, med, lq)):
            continue
        formula = detect_formula(window[: trip.start() + 80] + " " + principle)
        weights = parse_weights(window[: trip.end()])
        if re.search(r"2\s*[x×]\s*eng", window[: trip.end()], re.I):
            weights["eng"] = max(weights.get("eng", 0), 2.0)
            if re.search(r"best\s*4", window[: trip.end()], re.I):
                formula = "best4"
        if re.search(r"best\s*6", window[: trip.end()], re.I):
            formula = "best6"
        if re.search(r"1\.5\s*[x×]\s*eng.{0,40}1\.5\s*[x×]\s*math", window[: trip.end()], re.I | re.S):
            formula = "engMathWeighted"
            weights.setdefault("eng", 1.5)
            weights.setdefault("math", 1.5)
        put(out, code, formula, med, weights, False, "hku_block")
    return out


def parse_js_score_pairs(text: str) -> dict[str, dict]:
    """JS1112 ... Best 5/4 ... 24.5 \\n 24"""
    out: dict[str, dict] = {}
    for m in re.finditer(
        r"(JS\d{4})\s*\n(.{0,300}?)(Best\s*[456]\s*subjects?[^\n]*|Best\s*[456]\b|"
        r"Any Best 5 Subjects[^\n]*|6\s*Graded[^\n]*|"
        r"1\.5\s*[x×]\s*Eng[^\n]*)\n"
        r"(.{0,200}?)"
        r"(\d{2}(?:\.\d+)?)\s*\n(\d{2}(?:\.\d+)?)",
        text,
        re.S | re.I,
    ):
        code = m.group(1)
        window = m.group(0)
        # skip PolyU-scale
        a, b = float(m.group(5)), float(m.group(6))
        if a > MAX_STD or b > MAX_STD:
            continue
        if not valid_std(a):
            continue
        med = a  # often Median then LQ, or Med LQ
        formula = detect_formula(m.group(3) + " " + window)
        put(out, code, formula, med, parse_weights(window), False, "js_pair")
    return out


def parse_cuhk_md(text: str) -> dict[str, dict]:
    out: dict[str, dict] = {}
    for m in re.finditer(
        r"(JS\d{4})[^|\n]{0,100}\|\s*M\b[^|]*\|\s*([^|]{0,220}?)\s+"
        r"(\d{2}(?:\.\d+)?)\s*\|",
        text,
    ):
        code, principle, med = m.group(1), m.group(2), float(m.group(3))
        if not valid_std(med):
            continue
        put(
            out,
            code,
            detect_formula(principle),
            med,
            parse_weights(principle),
            code in ("JS4501", "JS4502"),
            "cuhk_m",
        )
    # Broken rows without clean trailing pipe (QFIN etc.)
    for m in re.finditer(
        r"(JS\d{4})\s+[^\n|]{0,90}\|\s*M\b.{0,220}?Best\s*[456].{0,140}?"
        r"(\d{2}(?:\.\d+)?)\b",
        text,
        re.S | re.I,
    ):
        code, med = m.group(1), float(m.group(2))
        if code in out or not valid_std(med):
            continue
        window = m.group(0)
        put(
            out,
            code,
            detect_formula(window),
            med,
            parse_weights(window),
            False,
            "cuhk_m_loose",
        )
    # Verified high-weight CUHK medians from official PDF
    for code, (med, weights) in {
        "JS4252": (52.5, {"eng": 2.0, "math": 2.0}),
        "JS4276": (57.75, {"eng": 2.0, "math": 2.0}),
        "JS4412": (42.875, {"math": 1.5, "m1": 1.75}),
        "JS4416": (54.5, {"math": 2.0, "m1": 2.0}),
        "JS4690": (46.75, {"math": 1.5, "m1": 1.5, "phy": 2.0}),
        "JS4238": (41.75, {"eng": 1.25, "math": 1.5, "m1": 1.5}),
    }.items():
        put(out, code, "best5", med, weights, False, "cuhk_hard")
    return out


def parse_cuhk_fitz_weights(text: str) -> dict[str, dict]:
    """Formula cards without scores — merge weights onto existing later."""
    out: dict[str, dict] = {}
    for m in re.finditer(
        r"(JS\d{4})\s*\n([^\n]{0,80}\n)?(Best\s*[456]|6\s*Graded)[^\n]*\n((?:•[^\n]*\n){0,6})",
        text,
    ):
        code = m.group(1)
        blob = m.group(0)
        put(out, code, detect_formula(blob), 22.0, parse_weights(blob), False, "cuhk_weights_only")
        # mark expected as placeholder — will not overwrite real medians due to source priority
        out[code]["expected_placeholder"] = True
    # Remove placeholders that only have 22
    return {k: v for k, v in out.items() if not v.get("expected_placeholder")}


def hard_ugc() -> dict[str, dict]:
    """Verified from fitz PDF excerpts."""
    return {
        "JS6456": {"formula": "best6", "expected": 44.0, "weights": {}, "legacyScale": False, "source": "hard"},
        "JS6494": {"formula": "best6", "expected": 39.0, "weights": {}, "legacyScale": False, "source": "hard"},
        "JS6949": {"formula": "best6", "expected": 40.0, "weights": {}, "legacyScale": False, "source": "hard"},
        "JS6107": {"formula": "best6", "expected": 41.0, "weights": {}, "legacyScale": False, "source": "hard"},
        "JS4501": {"formula": "best6", "expected": 41.0, "weights": {}, "legacyScale": True, "source": "hard"},
        "JS4502": {"formula": "best6", "expected": 41.0, "weights": {}, "legacyScale": True, "source": "hard"},
        "JS6406": {"formula": "best5", "expected": 35.0, "weights": {"eng": 1.0}, "legacyScale": False, "source": "hard"},
        "JS6078": {"formula": "best5", "expected": 38.0, "weights": {"eng": 1.0}, "legacyScale": False, "source": "hard"},
        "JS1061": {"formula": "best5", "expected": 23.0, "weights": {"eng": 1.0}, "legacyScale": False, "source": "hard"},
        "JS1112": {"formula": "best4", "expected": 24.5, "weights": {"eng": 2.0}, "legacyScale": False, "source": "hard"},
        "JS6755": {
            "formula": "engMathWeighted",
            "expected": 37.0,
            "weights": {"eng": 1.5, "math": 1.5},
            "legacyScale": False,
            "source": "hard",
        },
        "JS6767": {
            "formula": "engMathWeighted",
            "expected": 40.0,
            "weights": {"eng": 1.5, "math": 1.5},
            "legacyScale": False,
            "source": "hard",
        },
        "JS6781": {
            "formula": "engMathWeighted",
            "expected": 35.0,
            "weights": {"eng": 1.5, "math": 1.5},
            "legacyScale": False,
            "source": "hard",
        },
        "JS6808": {
            "formula": "engMathWeighted",
            "expected": 46.0,
            "weights": {"eng": 1.5, "math": 1.5},
            "legacyScale": False,
            "source": "hard",
        },
        "JS1801": {"formula": "best6", "expected": 41.0, "weights": {}, "legacyScale": False, "source": "hard"},
    }


def parse_hkust(text: str) -> dict[str, dict]:
    """HKUST: JS#### \\n title(s) \\n UQ \\n Median \\n LQ"""
    out: dict[str, dict] = {}
    for m in re.finditer(
        r"(JS\d{4})\s*\n(?:[^\n]{0,90}\n){1,4}"
        r"(\d{2}(?:\.\d+)?)\s*\n(\d{2}(?:\.\d+)?)\s*\n(\d{2}(?:\.\d+)?)\s*\n",
        text,
    ):
        code = m.group(1)
        uq, med, lq = float(m.group(2)), float(m.group(3)), float(m.group(4))
        if not (uq + 0.05 >= med >= lq - 0.05):
            continue
        if not (20 <= med <= 70):
            continue
        window = m.group(0)
        put(out, code, detect_formula(window), med, parse_weights(window), False, "hkust")
    return out


def parse_eduhk(text: str) -> dict[str, dict]:
    """EdUHK: JS#### \\n titles \\n (weights) \\n Med \\n LQ"""
    out: dict[str, dict] = {}
    for m in re.finditer(
        r"(JS\d{4})\s*\n(?:[^\n]{0,60}\n){1,8}"
        r"(?:\(No subject\s*\nweighting\)\s*\n)?"
        r"(\d{2}(?:\.\d+)?)\s*\n(\d{2}(?:\.\d+)?|-)",
        text,
    ):
        code, a, b = m.group(1), float(m.group(2)), m.group(3)
        if not (12 <= a <= 45):
            continue
        start = max(0, m.start() - 50)
        window = text[start : m.end() + 80]
        put(out, code, "best5", a, parse_weights(window), False, "eduhk")
    return out


def parse_eduhk_table(text: str) -> dict[str, dict]:
    """EdUHK wide tables: Mean \\n Median \\n - after long weight rows."""
    out: dict[str, dict] = {}
    markers = list(re.finditer(r"JS8\d{3}", text))
    for i, m in enumerate(markers):
        code = m.group(0)
        block_end = markers[i + 1].start() if i + 1 < len(markers) else m.start() + 700
        block = text[m.start() : block_end]
        mm = re.search(
            r"(\d{2}(?:\.\d+)?)\s*\n(\d{2}(?:\.\d+)?)\s*\n-\s*\n",
            block,
        )
        if not mm:
            continue
        med = float(mm.group(2))
        if not valid_std(med):
            continue
        put(out, code, detect_formula(block), med, parse_weights(block), False, "eduhk_table")
    return out


def _cityu_text_blob(text: str) -> str:
    chunks: list[str] = []
    for m in re.finditer(r"City University of Hong Kong[^\n]*", text):
        start = m.start()
        rest = text[m.end() : m.end() + 14000]
        nxt = re.search(
            r"\n(?:The Chinese University of|Hong Kong Baptist University|"
            r"Hong Kong Polytechnic University|The Education University of|"
            r"Hong Kong Metropolitan University|Lingnan University|"
            r"The Hong Kong University of Science and Technology|"
            r"Faculty of Architecture,|University of Hong Kong –)",
            rest,
        )
        end = m.end() + (nxt.start() if nxt else len(rest))
        chunks.append(text[start:end])
    return "\n".join(chunks)


def parse_cityu_median_lq(text: str) -> dict[str, dict]:
    """CityU admissions table: last Median/LQ pair within each JS#### block."""
    out: dict[str, dict] = {}
    blob = _cityu_text_blob(text)
    markers = list(re.finditer(r"JS\d{4}", blob))
    for i, m in enumerate(markers):
        code = m.group(0)
        block_end = markers[i + 1].start() if i + 1 < len(markers) else min(len(blob), m.start() + 900)
        block = blob[m.start() : block_end]
        if not re.search(r"Best\s*[456]|3\s*core\s*\+\s*2\s*elective", block, re.I):
            continue
        med = None
        for a_s, b_s in reversed(re.findall(r"(?:^|\n)(\d{2}(?:\.\d+)?)\s*\n(\d{2}(?:\.\d+)?)\s*(?:\n|$)", block)):
            a, b = float(a_s), float(b_s)
            if valid_std(a) and valid_std(b) and a >= b - 0.5:
                med = a
                break
        if med is None:
            for mm in reversed(list(re.finditer(r"\n(\d{2}(?:\.\d+)?)\s+(\d{2}(?:\.\d+)?)\s*\n", block))):
                a, b = float(mm.group(1)), float(mm.group(2))
                if valid_std(a) and valid_std(b) and a >= b - 0.5:
                    med = a
                    break
        if med is None:
            continue
        put(out, code, detect_formula(block), med, parse_weights(block), False, "cityu_median_lq")
    return out


def apply_score_aliases(data: dict[str, dict]) -> None:
    """Umbrella / school-based codes that share official scores with listed majors."""
    aliases = {
        # CityU DAO umbrella — majors JS1026/JS1027 both median 21.5 in official PDF
        "JS1025": "JS1026",
    }
    for target, source in aliases.items():
        if target in data or source not in data:
            continue
        alias = dict(data[source])
        alias["source"] = f"alias:{source}"
        data[target] = alias


def parse_hkmu(text: str) -> dict[str, dict]:
    """HKMU: JS9xxx^ \\n long title \\n Med \\n LQ"""
    out: dict[str, dict] = {}
    for m in re.finditer(
        r"(JS\d{4})\^?\s*\n(?:[^\n]{0,120}\n){1,6}(\d{2}(?:\.\d+)?)\s*\n(\d{2}(?:\.\d+)?|-)",
        text,
    ):
        code, a = m.group(1), float(m.group(2))
        if not (10 <= a <= 30):
            continue
        # HKMU uses Category A 5**=7 scale in SSSDP-style tables
        put(out, code, "best5", a, parse_weights(m.group(0)), True, "hkmu")
    return out


def parse_cuhk_weight_then_md_scores(fitz: str, md: str) -> dict[str, dict]:
    """Programmes with weight cards in fitz; fill median from CUHK markdown M-rows."""
    weights_by: dict[str, tuple[str, dict]] = {}
    for m in re.finditer(
        r"(JS\d{4})\s*\n([^\n]{0,80}\n)?(Best\s*[456]|6\s*Graded)[^\n]*\n((?:•[^\n]*\n){0,8})",
        fitz,
    ):
        code, blob = m.group(1), m.group(0)
        weights_by[code] = (detect_formula(blob), parse_weights(blob))

    scores = parse_cuhk_md(md) if md else {}
    out: dict[str, dict] = {}
    for code, (formula, weights) in weights_by.items():
        if code in scores:
            d = dict(scores[code])
            d["weights"] = {**weights, **(d.get("weights") or {})}
            d["formula"] = formula if formula != "best5" else d["formula"]
            d["source"] = "cuhk_weights+md"
            out[code] = d
        elif weights:
            # weight known but no median — skip expected (don't invent)
            continue
    return out


def parse_polyu_skip_scale(text: str) -> dict[str, dict]:
    """PolyU uses ~180–220 weighted totals — record formula/weights only via best5 + tag expected from LQ/200*28 approx? 
    Better: store median converted roughly: polyu_median / 7.5 ≈ DSE-ish. Official note says proprietary.
    We keep Best5 formula + weights; map expected ≈ median/7.5 clamped 18–35 for gameplay reference.
    """
    out: dict[str, dict] = {}
    for m in re.finditer(
        r"(JS\d{4})\s*\n(\d{3}(?:\.\d+)?)\s*\n\(subject weighting[^\n]*\n(?:[^\n]{0,80}\n){0,4}"
        r"(?:Any Best 5 Subjects|Best\s*5)[^\n]*\n(?:[^\n]{0,80}\n){0,2}"
        r"Median\s*\n(\d{3}(?:\.\d+)?)",
        text,
        re.I,
    ):
        code, uq, med = m.group(1), float(m.group(2)), float(m.group(3))
        if med < 100:
            continue
        # Rough bridge to 8.5-scale Best5 for offer thresholds (documented as approx)
        approx = round(med / 7.5, 1)
        if not (15 <= approx <= 40):
            approx = min(40, max(15, approx))
        put(out, code, "best5", approx, parse_weights(m.group(0)), False, "polyu_approx")
    return out


def parse_hkbu_mean(text: str) -> dict[str, dict]:
    out: dict[str, dict] = {}
    for m in re.finditer(
        r"(JS\d{4})\s{1,3}[^\n]{0,220}\nScore Formula:\s*(Best\s*[456])[^\n]*\n"
        r"Mean\b(.{0,160}?)(\d{2}(?:\.\d+)?)",
        text,
        re.S | re.I,
    ):
        code, formula_s, med = m.group(1), m.group(2), float(m.group(4))
        put(out, code, detect_formula(formula_s), med, {}, False, "hkbu_mean")
    return out


def parse_median_label(text: str) -> dict[str, dict]:
    out: dict[str, dict] = {}
    for m in re.finditer(
        r"(JS\d{4})\s*\n(?:[^\n]{0,90}\n){0,4}Median\s*\n(\d{2}(?:\.\d+)?)",
        text,
    ):
        code, med = m.group(1), float(m.group(2))
        window = text[m.start() : m.start() + 400]
        put(out, code, detect_formula(window), med, parse_weights(window), False, "median_label")
    return out


def parse_every_js_window(text: str) -> dict[str, dict]:
    out: dict[str, dict] = {}
    for m in re.finditer(r"JS\d{4}", text):
        code = m.group(0)
        w = text[m.start() : m.start() + 600]
        med = None
        mm = re.search(
            r"Score Formula:[^\n]*\nMean\b.{0,160}?(\d{2}(?:\.\d+)?)",
            w,
            re.S | re.I,
        )
        if mm:
            med = float(mm.group(1))
        if med is None:
            mm = re.search(r"\bMean\b\s*\n?(?:\D{0,100})?(\d{2}(?:\.\d+)?)", w)
            if mm and valid_std(float(mm.group(1))):
                med = float(mm.group(1))
        if med is None:
            mm = re.search(r"\bMedian\b\s*\n(\d{2}(?:\.\d+)?)", w)
            if mm:
                med = float(mm.group(1))
        if med is None or not valid_std(med):
            continue
        put(out, code, detect_formula(w), med, parse_weights(w), False, "auto_window")
    return out


def parse_cityu_double_scores(text: str) -> dict[str, dict]:
    out: dict[str, dict] = {}
    for m in re.finditer(
        r"(JS\d{4})\s*\n(?:[^\n]{0,100}\n){1,6}(\d{2}(?:\.\d+)?)\s*\n(\d{2}(?:\.\d+)?)\s*\n(?=JS\d{4}|\n[A-Z])",
        text,
    ):
        code, a, b = m.group(1), float(m.group(2)), float(m.group(3))
        if not valid_std(a) or not valid_std(b) or abs(a - b) > 15:
            continue
        start = max(0, m.start() - 250)
        window = text[start : m.end()]
        put(out, code, detect_formula(window), a, parse_weights(window), False, "cityu_pair")
    return out


def merge_weight_cards(data: dict, text: str) -> None:
    """Attach CUHK/CityU weight lines onto codes that already have medians."""
    for m in re.finditer(
        r"(JS\d{4})\s*\n(?:[^\n]{0,60}\n){0,2}(Best\s*[456][^\n]*\n(?:•[^\n]*\n){0,8})",
        text,
    ):
        code, blob = m.group(1), m.group(0)
        if code not in data:
            continue
        w = parse_weights(blob)
        if not w:
            continue
        merged = dict(data[code]["weights"])
        merged.update(w)
        data[code]["weights"] = merged
        f = detect_formula(blob)
        if f != "best5" or data[code]["formula"] == "best5":
            if f in ("best4", "best6", "engMathWeighted"):
                data[code]["formula"] = f


def emit_dart(data: dict[str, dict]) -> str:
    # Drop weight-only junk
    data = {k: v for k, v in data.items() if valid_std(float(v["expected"]))}
    rows = []
    for code in sorted(data):
        d = data[code]
        w = d.get("weights") or {}
        w_lit = (
            "{" + ", ".join(f"'{k}': {v}" for k, v in sorted(w.items())) + "}"
            if w
            else "const <String, double>{}"
        )
        rows.append(
            "    '{code}': OfficialScoreSpec(\n"
            "      formula: JupasScoreFormula.{formula},\n"
            "      expectedMedian: {expected},\n"
            "      subjectWeights: {weights},\n"
            "      legacyScale: {legacy},\n"
            "    ),".format(
                code=code,
                formula=d["formula"],
                expected=float(d["expected"]),
                weights=w_lit,
                legacy="true" if d.get("legacyScale") else "false",
            )
        )
    body = "\n".join(rows)
    return f"""// GENERATED by tool/parse_jupas_admission_scores.py — DO NOT HAND EDIT
// Sources: af_2025_JUPAS.pdf + af_2025_SSSDP.pdf (JUPAS official)
// UGC: 5**=8.5/5*=7/5=5.5; SSSDP & CUHK MBChB: legacy 7/6/5.
import 'jupas_models.dart';

class OfficialScoreSpec {{
  final JupasScoreFormula formula;
  final double expectedMedian;
  final Map<String, double> subjectWeights;
  final bool legacyScale;
  const OfficialScoreSpec({{
    required this.formula,
    required this.expectedMedian,
    this.subjectWeights = const <String, double>{{}},
    this.legacyScale = false,
  }});
  int get expectedScore => expectedMedian.round();
}}

abstract final class OfficialScoreOverlay {{
  static final Map<String, OfficialScoreSpec> byCode = {{
{body}
  }};

  static OfficialScoreSpec? of(String code) => byCode[code];
  static int get count => byCode.length;
}}
"""


def parse_cityu_inspire_block(text: str) -> dict[str, dict]:
    """CityU long titles then Med/LQ (e.g. JS1050 → 38 36.5; JS1807 → 45.5 43)."""
    out: dict[str, dict] = {}
    for m in re.finditer(
        r"(JS\d{4})\s*\n(?:[^\n]{0,110}\n){2,14}"
        r"(\d{2}(?:\.\d+)?)\s+(?:(\d{2}(?:\.\d+)?)\s*)?\n|"
        r"(JS\d{4})\s*\n(?:[^\n]{0,110}\n){2,14}"
        r"(\d{2}(?:\.\d+)?)\s*\n(\d{2}(?:\.\d+)?)\s*\n",
        text,
    ):
        if m.group(1):
            code, a, b = m.group(1), float(m.group(2)), m.group(3)
            med = float(b) if b else a
            if b:
                med = max(a, float(b))
            else:
                med = a
        else:
            code, a, b = m.group(4), float(m.group(5)), float(m.group(6))
            med = a if a >= b else b
        if not valid_std(med):
            continue
        window = text[max(0, m.start() - 80) : m.end()]
        put(out, code, detect_formula(window), med, parse_weights(window), False, "cityu_inspire")
    # explicit verified
    for code, med, w in (
        ("JS1050", 38.0, {}),
        ("JS1807", 45.5, {}),
        ("JS1805", 38.5, {}),
        ("JS1806", 35.5, {}),
    ):
        put(out, code, "best5", med, w, False, "cityu_hard")
    return out


def catalogue_codes() -> set[str]:
    codes: set[str] = set()
    for p in (ROOT / "lib/data/jupas/catalogue").glob("*.dart"):
        if p.name == "community.dart":
            continue
        codes |= set(re.findall(r"code:\s*'(JS[^']+)'", p.read_text()))
    return codes


def main() -> None:
    ensure_fitz_text()
    ugc = (CACHE / "af_2025_JUPAS_fitz.txt").read_text(encoding="utf-8") if (CACHE / "af_2025_JUPAS_fitz.txt").exists() else ""
    sssdp = (CACHE / "af_2025_SSSDP_fitz.txt").read_text(encoding="utf-8") if (CACHE / "af_2025_SSSDP_fitz.txt").exists() else ""
    md = (CACHE / "af_2025_JUPAS.md").read_text(encoding="utf-8") if (CACHE / "af_2025_JUPAS.md").exists() else ""

    data: dict[str, dict] = {}
    # later layers overwrite earlier (higher priority last)
    for layer in (
        parse_every_js_window(ugc),
        parse_cityu_double_scores(ugc),
        parse_js_score_pairs(ugc),
        parse_median_label(ugc),
        parse_hkbu_mean(ugc),
        parse_polyu_skip_scale(ugc),
        parse_eduhk(ugc),
        parse_eduhk_table(ugc),
        parse_hkmu(ugc),
        parse_hkust(ugc),
        parse_hku_blocks(ugc),
        parse_cuhk_md(md) if md else {},
        parse_cuhk_weight_then_md_scores(ugc, md) if md else {},
        parse_cityu_inspire_block(ugc),
        parse_cityu_median_lq(ugc),
        parse_sssdp(sssdp),
    ):
        data.update(layer)
    data.update(hard_ugc())
    data.update(parse_sssdp(sssdp))
    merge_weight_cards(data, ugc)
    apply_score_aliases(data)

    OUT.write_text(emit_dart(data), encoding="utf-8")
    cat = catalogue_codes()
    covered = set(data) & cat
    missing = sorted(cat - set(data))
    print(f"Wrote {OUT}")
    print(f"overlay={len(data)} catalogue={len(cat)} covered={len(covered)} missing={len(missing)}")
    print("coverage={:.1f}%".format(100 * len(covered) / max(1, len(cat))))
    print("formulas:", dict(Counter(d["formula"] for d in data.values())))
    print("sssdp covered:", sorted(c for c in covered if c.startswith("JSS") or c.startswith("JSSA") or c.startswith("JSSC") or c.startswith("JSSH") or c.startswith("JSST") or c.startswith("JSSU") or c.startswith("JSSV") or c.startswith("JSSW") or c.startswith("JSSY"))[:5], "...")
    print("missing sample:", missing[:25])


if __name__ == "__main__":
    main()
