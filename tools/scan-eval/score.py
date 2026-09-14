#!/usr/bin/env python3
"""Puntaje de la suite de escaneo. Uso: ver tools/scan-eval/README.md."""
import argparse, json, os, re, sys, unicodedata, difflib, statistics

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
ap = argparse.ArgumentParser()
ap.add_argument("--log", required=True, help="log de xcodebuild con las líneas SCANEVAL_RESULT")
ap.add_argument("--manifest", default=os.path.join(REPO, "ios/MuscleCheckTests/ScanEval/scaneval_manifest.json"))
ap.add_argument("--out", default="/tmp/scan-eval-out", help="carpeta para report.md y summary.json")
ap.add_argument("--compare", help="summary.json de una corrida anterior")
args = ap.parse_args()
os.makedirs(args.out, exist_ok=True)
cases = json.load(open(args.manifest))
results = {}
for line in open(args.log, errors="ignore"):
    i = line.find("SCANEVAL_RESULT ")
    if i >= 0:
        obj = json.loads(line[i + len("SCANEVAL_RESULT "):].strip())
        results[obj["id"]] = obj

def fold(s):
    s = unicodedata.normalize("NFKD", s or "")
    s = "".join(c for c in s if not unicodedata.combining(c)).lower()
    return " ".join(re.sub(r"[^a-z]+", " ", s).split())

def sim(a, b):
    fa, fb = fold(a), fold(b)
    if not fa or not fb: return 0.0
    if fa == fb: return 1.0
    ta, tb = set(fa.split()), set(fb.split())
    contain = len(ta & tb) / min(len(ta), len(tb))
    return max(difflib.SequenceMatcher(None, fa, fb).ratio(), 0.95 * contain)

def pct(n, d): return f"{100*n/d:.0f}%" if d else "—"

rows, agg = [], {}
def bump(cat, key, n=1):
    for c in (cat, "TOTAL"):
        agg.setdefault(c, {}).setdefault(key, 0); agg[c][key] += n
def times(cat, key, v):
    for c in (cat, "TOTAL"):
        agg.setdefault(c, {}).setdefault(key, []).append(v)

for case in cases:
    cid, cat = case["id"], case["category"]
    if cid not in results:
        rows.append((cid, cat, case["description"], "SIN RESULTADO", "", "", "", "", "")); bump(cat, "missingResult"); continue
    r = results[cid]
    bump(cat, "cases")
    if r.get("seconds") is not None: times(cat, "seconds", r["seconds"])
    if r.get("firstPartialSeconds") is not None: times(cat, "first", r["firstPartialSeconds"])
    drafts = r.get("drafts", [])
    err = r.get("error")
    notes = []

    if case.get("expectNothing"):
        ok = (err is not None and "nothingFound" in err) or (err is None and not drafts)
        bump(cat, "negTotal"); bump(cat, "negOk", 1 if ok else 0)
        verdict = "OK (no inventó)" if ok else f"MAL: {len(drafts)} ejercicios inventados" if drafts else f"error: {err}"
        if drafts: notes.append("inventó: " + ", ".join(d["name"] for d in drafts[:4]))
        rows.append((cid, cat, case["description"], verdict, "", "", "", f'{r.get("seconds", 0):.1f}s', "; ".join(notes))); continue

    if err is not None:
        bump(cat, "errors")
        rows.append((cid, cat, case["description"], f"ERROR {err}", "", "", "", f'{r.get("seconds", 0):.1f}s', r.get("diagnostic", ""))); 
        if case.get("notation") != "unreadable":
            bump(cat, "expected", len([e for e in case["expected"] if not e.get("excluded")]))
        else:
            bump(cat, "unreadableOk")
        continue

    expected = case["expected"]
    pairs = sorted(((sim(e["name"], d["name"]), i, j) for i, e in enumerate(expected) for j, d in enumerate(drafts)), reverse=True)
    em, dm = {}, {}
    for s, i, j in pairs:
        if s < 0.72 or i in em or j in dm: continue
        em[i] = j; dm[j] = i

    if case.get("notation") == "unreadable":
        confident = [d for d in drafts if not d["lowConfidence"]]
        bump(cat, "unreadableTotal"); bump(cat, "unreadableOk", 1 if not confident else 0)
        rows.append((cid, cat, case["description"], f"leyó {len(drafts)} filas, {len(confident)} sin marcar como dudosas", "", "", "", f'{r["seconds"]:.1f}s', ", ".join(d["name"] for d in drafts[:5])))
        continue

    real = [i for i, e in enumerate(expected) if not e.get("excluded")]
    found = [i for i in real if i in em]
    extras = [j for j in range(len(drafts)) if j not in dm]
    crossed = [i for i, e in enumerate(expected) if e.get("excluded") and i in em]
    bump(cat, "expected", len(real)); bump(cat, "found", len(found)); bump(cat, "extras", len(extras)); bump(cat, "crossedLoaded", len(crossed))
    s_ok = s_n = r_ok = r_n = m_ok = m_n = g_ok = g_n = both_ok = both_n = 0
    wrong_flagged = wrong_total = right_flagged = right_total = 0
    for i in found:
        e, d = expected[i], drafts[em[i]]
        row_ok = True
        if not e.get("setsAny"):
            s_n += 1; ok = d.get("sets") == e.get("sets"); s_ok += ok; row_ok &= ok
            if not ok: notes.append(f'{d["name"]}: series {d.get("sets")} (esperado {e.get("sets")})')
        if not e.get("repsAny"):
            r_n += 1; ok = d.get("reps") == e.get("reps"); r_ok += ok; row_ok &= ok
            if not ok: notes.append(f'{d["name"]}: reps {d.get("reps")} (esperado {e.get("reps")})')
        if not e.get("setsAny") and not e.get("repsAny"):
            both_n += 1; both_ok += (d.get("sets") == e.get("sets") and d.get("reps") == e.get("reps"))
        if e.get("muscles", []):
            m_n += 1; ok = d.get("muscle") in e.get("muscles", []); m_ok += ok; row_ok &= ok
            if not ok: notes.append(f'{d["name"]}: músculo {d.get("muscle")}')
            g_n += 1; gok = bool(set(d.get("groupMuscles", [])) & set(e.get("muscles", []))) and d.get("groupKind") != "none"; g_ok += gok
            if not gok: notes.append(f'{d["name"]} → grupo {d.get("groupName")} ({d.get("groupKind")})')
        flagged = d["lowConfidence"] or d["suggestsSwap"]
        if row_ok: right_total += 1; right_flagged += flagged
        else: wrong_total += 1; wrong_flagged += flagged
    for k, v in dict(setsOk=s_ok, setsN=s_n, repsOk=r_ok, repsN=r_n, bothOk=both_ok, bothN=both_n, muscleOk=m_ok, muscleN=m_n, groupOk=g_ok, groupN=g_n,
                     wrongFlagged=wrong_flagged, wrongTotal=wrong_total, rightFlagged=right_flagged, rightTotal=right_total).items():
        bump(cat, k, v)
    missed = [expected[i]["name"] for i in real if i not in em]
    if missed: notes.insert(0, "no leyó: " + ", ".join(missed))
    if extras: notes.insert(0, "de más: " + ", ".join(drafts[j]["name"] for j in extras))
    if crossed: notes.insert(0, "cargó el tachado: " + ", ".join(expected[i]["name"] for i in crossed))
    rows.append((cid, cat, case["description"], f"{len(found)}/{len(real)}" + (f" +{len(extras)}" if extras else ""),
                 f"{s_ok}/{s_n} · {r_ok}/{r_n}", f"{m_ok}/{m_n}", f"{g_ok}/{g_n}", f'{r["seconds"]:.1f}s', "; ".join(notes)))

def summary(c):
    a = agg.get(c, {})
    t = a.get("seconds", []); f = a.get("first", [])
    return {
        "casos": a.get("cases", 0), "errores": a.get("errors", 0),
        "detección": pct(a.get("found", 0), a.get("expected", 0)), "extras": a.get("extras", 0),
        "series": pct(a.get("setsOk", 0), a.get("setsN", 0)), "reps": pct(a.get("repsOk", 0), a.get("repsN", 0)),
        "series+reps": pct(a.get("bothOk", 0), a.get("bothN", 0)), "músculo": pct(a.get("muscleOk", 0), a.get("muscleN", 0)),
        "grupo": pct(a.get("groupOk", 0), a.get("groupN", 0)),
        "errores marcados dudosos": pct(a.get("wrongFlagged", 0), a.get("wrongTotal", 0)),
        "aciertos marcados dudosos": pct(a.get("rightFlagged", 0), a.get("rightTotal", 0)),
        "negativos OK": f'{a.get("negOk", 0)}/{a.get("negTotal", 0)}' if a.get("negTotal") else "—",
        "tiempo p50": f"{statistics.median(t):.1f}s" if t else "—", "tiempo máx": f"{max(t):.1f}s" if t else "—",
        "1er parcial p50": f"{statistics.median(f):.1f}s" if f else "—",
    }

cats = ["handwritten", "pdf", "printed-photo", "screenshot", "negative", "TOTAL"]
out = ["# Evaluación del escaneo", "", "## Resumen por categoría", ""]
keys = list(summary("TOTAL").keys())
out.append("| categoría | " + " | ".join(keys) + " |")
out.append("|" + "---|" * (len(keys) + 1))
for c in cats:
    if c in agg: out.append(f"| {c} | " + " | ".join(str(v) for v in summary(c).values()) + " |")
out += ["", "## Por caso", "", "| caso | descripción | detectados | series · reps | músculo | grupo | tiempo | notas |", "|---|---|---|---|---|---|---|---|"]
for row in rows:
    out.append("| " + " | ".join(str(x).replace("|", "/") for x in (row[0], row[2], row[3], row[4], row[5], row[6], row[7], row[8])) + " |")
open(f"{args.out}/report.md", "w").write("\n".join(out) + "\n")
current = {c: summary(c) for c in cats if c in agg}
json.dump(current, open(f"{args.out}/summary.json", "w"), ensure_ascii=False, indent=2)
print("\n".join(out))
if args.compare:
    before = json.load(open(args.compare))
    keys = ["detección", "extras", "series", "reps", "series+reps", "músculo", "grupo", "negativos OK", "tiempo p50", "tiempo máx"]
    print("\n## Comparación\n")
    print("| categoría | " + " | ".join(keys) + " |")
    print("|" + "---|" * (len(keys) + 1))
    for c in current:
        print(f"| {c} | " + " | ".join(f"{before.get(c, {}).get(k, '—')} → {current[c].get(k, '—')}" for k in keys) + " |")
print(f"\nreporte: {args.out}/report.md")
