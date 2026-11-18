"""Group Stathopoulou's candidates into rhythms, drop what the library already has,
and build the review page.

    python3 sources/stathopoulou/build_review.py <old_page.html> <out.html>

Writes sources/stathopoulou/review.json (the grouping and the exclusions) and the page.
The handwriting crops come from the first review page (its ITEMS array), so the page
is rebuilt without re-cropping the PDF. Decisions and edits live in the artifact db,
keyed by candidate id: decisions/<id> {status, comment, at}, edits/<id> {rhythm, original, at}.
"""
import base64, glob, json, re, sys
from pathlib import Path

import yaml

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
EDITOR = Path.home() / "git/rythmiko-toxo-editor/tools/editor"

# ---- left out: the library already has them ------------------------------------------
# The 22 the first pass found identical to a library variation, plus the 12 whose only
# difference is an accent the library writes and her notes leave out (or the reverse,
# where she herself wrote it both ways). Reasons are shown on the page.
# Her rolls (⊞ before Α) are written as wahda v2 writes them: the box, Α and the next
# stroke as a triplet of the same value, {3 Α8:[ Α8 (Α)8] } (19 Oct 2026).
SAME = "ίδιο με"
EXCLUDE = {
    "palios-aptalikos": "ίδιο με aptaliko v1",
    "eptasimos": "ίδιο με eptasimos v1",
    "eptasimos-slap": "ίδιο με eptasimos v7",
    "eptasimos-ntaouli": "ίδιο με eptasimos v2 (μόνο οι γραμμές σύνδεσης διαφέρουν)",
    "eptasimos-p-teke-ka": "ίδιο με eptasimos v4 και v5 (μόνο οι γραμμές σύνδεσης διαφέρουν)",
    "eptasimos-p-16-teke": "ίδιο με eptasimos v9",
    "eptasimos-p-16-teletaio": "ίδιο με eptasimos v3",
    "eptasimos-p-16-slap": "ίδιο με eptasimos v8",
    "eptasimos-p-16-tonismena": "ίδιο με eptasimos v10",
    "aptaliko-16": "ίδιο με aptaliko v2",
    "karsilamas-16-v2": "ίδιο με karsilamas v2",
    "karsilamas-16-v4": "ίδιο με karsilamas v4",
    "karsilamas-16-v6": "ίδιο με karsilamas v6",
    "wahda": "ίδιο με wahda v1",
    "syrtobalos": "ίδιο με sofyan v3 και syrtoidi v2",
    "moraitika-toumbeleki": "ίδιο με nim_sofyan v2",
    "syrtos": "ίδιο με syrtoidi v1",
    "sofyan": "ίδιο με sofyan v1",
    "koutalia": "ίδιο με nim_sofyan v6",
    "mantilatos-vasi": "ίδιο με mandilatos v1",
    "neos-balos": "ίδιο με sofyan v4 και syrtoidi v3",
    "sympethera-klisimo-s": "ίδιο με sofyan v5 (εκείνη το γράφει σε 2/4)",
    "semai-eighths": "azeri v2 χωρίς τον τονισμό στο 2ο tek",
    "enniasimos-vasi": "enniasimos v1 χωρίς τους τονισμούς στα tek",
    "karsilamas": "karsilamas v1 χωρίς τον τονισμό στο 2ο tek",
    "aksak": "enniasimos v2 χωρίς τους τονισμούς στα tek",
    "eptasimos-p-16-teke-ka": "eptasimos v10 χωρίς τους τονισμούς (το σημάδι πάνω από το τελευταίο ζεύγος μάλλον είναι τονισμός)",
    "karsilamas-16-v3": "karsilamas v3 χωρίς τον τονισμό στο 3ο tek",
    "karsilamas-16-v5": "karsilamas v5 χωρίς τον τονισμό στο τελευταίο tek",
    "beria-5": "turk_aksagy v1 χωρίς τον τονισμό (Μπέρια είναι το έθιμο, ο ρυθμός ο ίδιος)",
    "baintouska-5": "turk_aksagy v2 χωρίς τον τονισμό",
    "elate-edo": "azeri v1 και semai v1 χωρίς τον τονισμό στο τελευταίο tek",
    "eptasimos-p-teke-teke": "eptasimos v6 με τονισμό στο 3ο tek· στις 05/03/2025 το γράφει κι εκείνη χωρίς τονισμό",
    "wahda-trilia": "ίδιο με wahda v2 (η τρίλια ως τρίηχο ⊞-Α-(Α), όπως το έγραψε ο Νίκος)",
    "vasi-oriental": "duyek v1 («Βάση (oriental)») με τονισμό στο τελευταίο tek",
}

# ---- rhythms: (slug, display, meter, member candidate ids in notebook order) -----------
# A slug that exists in rhythms/ means the variations would join that rhythm, numbered
# after its last vN. 2/4 and 4/8 count as the same meter (same length and pulse).
GROUPS = [
    ("semai", None, None, ["semai-base", "elate-edo-bendir", "semai-bendir"]),
    ("rythmos_4_4", "Ρυθμός σε 4/4", "4/4", ["rythmos-4-4"]),
    ("zeibekiko", "Ζεϊμπέκικο 9/4", "9/4", ["palio-zeibekiko", "zeibekiko-9-4-b", "neo-zeibekiko"]),
    ("kamilierikos", "Καμηλιέρικο (παλιός καρσιλαμάς 9/4)", "9/4",
     ["palios-karsilamas-9-4", "kamilierikos", "kamilierikos-trilia", "kamilierikos-mesos", "kamilierikos-mesos-trilia"]),
    ("aptaliko", None, None, ["palio-aptaliko", "aptaliko-parallagi", "aptaliko-trilia", "neo-aptaliko", "aptaliko-16-trilia"]),
    ("enniasimos", None, None, ["aksak-slap", "enniasimos-hek"]),
    ("karsilamas", None, None, ["karsilamas-trilia", "karsilamas-16a", "karsilamas-16b"]),
    ("eptasimos", None, None,
     ["eptasimos-syrtos-ntaouli", "eptasimos-ntaouli-dipli", "eptasimos-vasi", "eptasimos-trilia",
      "eptasimos-ntaouli-plousios-1", "eptasimos-ntaouli-plousios-2", "eptasimos-p-argos", "eptasimos-p-16-trilia",
      "eptasimos-mesos", "kalamatianos-mesos", "eptasimos-trilia-mesos", "eptasimos-16-mesos-slap",
      "thrakis-bendir", "syrtos-makedonias"]),
    ("raiko", "Ράικο", "7/8", ["raiko-1", "raiko-2", "raiko-3", "raiko-3-2-2"]),
    ("wahda_forma", "Φόρμα 4/4 πάνω στο wahda", "4/4",
     ["forma-rythmou", "forma-mesos", "forma-mesos-teke", "wahda-vasi-slap", "wahda-vasi-slap-2",
      "wahda-vasi-slap-mesos", "wahda-pafsi-16", "livisiani-b-telos", "forma-pafsi", "forma-pafsi-2",
      "forma-pafsi-3", "wahda-forma-trilia", "wahda-forma-slap-trilia"]),
    ("mikrasiatikos", "Αργός μικρασιάτικος (Sofian στα περσικά)", "4/4",
     ["sofian-persiko", "argos-mikrasiatikos-a", "argos-mikrasiatikos-b"]),
    ("wahda", None, None,
     ["wahda-proseggisi", "wahda-teke", "wahda-slap-trilia", "wahda-s-trilia", "wahda-k-16",
      "wahda-k", "wahda-k-teke", "wahda-mia", "wahda-4s-trilia", "wahda-dyo-trilies"]),
    ("aksak_semai", "Aksak semai", "10/4", ["aksak-semai"]),
    ("yuruk_semai", "Yürük semai", "6/4", ["yuruk-semai"]),
    ("tsifteteli_enniari", "Τσιφτετελοειδές εννιάρι (Αν. Θράκη)", "9/8", ["tsifteteli-enniari"]),
    ("arabesk", "Arabesk", "4/4",
     ["arabesk", "oriental-arabesk", "arabesk-p-16", "arabesk-p-pafsi", "arabesk-p1-trilia", "arabesk-s-trilia",
      "arabesk-s", "arabesk-ii", "arabesk-ii-trilia", "arabesk-k"]),
    ("duyek", None, None, ["vasi-oriental-s"]),
    ("nim_sofyan", None, None, ["bendir-4-8", "ikarias"]),
    ("kritis", "Κρήτης", "10/4", ["kritis", "kritis-bendir"]),
    ("syrtoidi", None, None,
     ["syrtos-tonismenos", "syrtos-4metro-klisimo", "syrtos-trilia-2o", "syrtos-trilia-16", "syrtos-nisia-trilia",
      "syrtos-klisimo-tete", "syrtos-klisimo-k", "syrtos-klisimo-kkk", "syrtos-4metro-trilia-k", "syrtos-trilia-tek",
      "syrtos-2o-ekeke", "syrtos-trilia-16-aldaa"]),
    ("sofyan", None, None,
     ["sofyan-trilia", "sympethera", "sympethera-klisimo-2", "sympethera-klisimo-3", "sofyan-p-sss", "sofyan-p-ss",
      "sofyan-p-dum", "sofyan-p-s-dum", "sofyan-p-dumdum"]),
    ("mandilatos", None, None,
     ["thrakiotikos-ka", "perperouna", "mantilatos-fraseis", "orthia-1", "orthia-2", "orthia-3", "kathisti-2",
      "mantilatos-devri-turan"]),
    ("turk_aksagy", None, None, ["pentasimo-hek"]),
    ("nisiotiko", "Τετράσημος για νησιώτικα", "4/8",
     ["nisiotiko-a", "nisiotiko-b", "beria-4", "nisiotiko-d", "nisiotiko-e", "samothraki"]),
    ("kasik_havasi", None, None, ["kasik-havasi", "kasik-havasi-kofto"]),
    ("argilamas", "Αργιλαμάς (2+3+2+2)", "9/8", ["argilamas"]),
]
EQUIV = {"2/4": "4/8", "4/8": "4/8"}


def vnum(k):
    m = re.match(r"^v(\d+)$", str(k))
    return int(m.group(1)) if m else 0


def main(old_html, out_html):
    cands = {c["id"]: c for c in json.load(open(HERE / "candidates.json"))}
    order = list(cands)
    lib = {}
    for f in sorted(glob.glob(str(REPO / "rhythms/*.yaml"))):
        d = yaml.safe_load(open(f))
        slug, node = next(iter(d.items()))
        lib[slug] = node

    page = Path(old_html).read_text()
    items = json.loads(re.search(r"^const ITEMS=(\[.*\]);$", page, re.M).group(1))
    exercises = json.loads(re.search(r"^const EXERCISES=(\[.*\]);$", page, re.M).group(1))
    old = {it["id"]: it for it in items}

    placed = {}
    groups = []
    for slug, display, meter, members in GROUPS:
        node = lib.get(slug)
        if node:
            display = node["display"]
            meter = str(node["meter"])
            have = sorted(node["variations"], key=vnum)
            nxt = vnum(have[-1]) + 1
            libvars = [{"vid": k, "rhythm": node["variations"][k]["rhythm"],
                        "comment": node["variations"][k].get("comment") or ""} for k in have]
        else:
            nxt, libvars = 1, []
        members = sorted(members, key=order.index)
        vars_ = []
        for i, cid in enumerate(members):
            assert cid in cands, cid
            assert cid not in EXCLUDE, cid
            assert cid not in placed, (cid, placed.get(cid))
            c = cands[cid]
            assert EQUIV.get(c["meter"], c["meter"]) == EQUIV.get(meter, meter), (cid, c["meter"], meter)
            placed[cid] = slug
            o = old[cid]
            vars_.append({
                "vid": f"v{nxt + i}", "id": cid, "title": c["name"], "rhythm": c["rhythm"],
                "written_meter": c["meter"], "conf": c["confidence"], "why": c["confidence_reason"],
                "remarks": c["remarks"], "date": c["date"], "page": c["page_label"],
                "others": o["others"], "lib": o["lib"], "note": o["note"],
            })
        groups.append({"slug": slug, "display": display, "meter": meter, "in_library": bool(node),
                       "comment": (node or {}).get("comment") or "", "library_variations": libvars,
                       "variations": vars_})
    missing = [cid for cid in order if cid not in placed and cid not in EXCLUDE]
    assert not missing, missing
    assert set(EXCLUDE) <= set(cands)

    excluded = [{"id": cid, "title": cands[cid]["name"], "meter": cands[cid]["meter"], "rhythm": cands[cid]["rhythm"],
                 "reason": EXCLUDE[cid], "date": cands[cid]["date"], "page": cands[cid]["page_label"]}
                for cid in order if cid in EXCLUDE]
    review = {
        "about": "Grouping of candidates.json for the review page (19 Oct 2026). Variations of a rhythm that exists "
                 "in rhythms/ are numbered after its last vN, so an approved one joins it under that vid. Decisions are "
                 "in the artifact db at decisions/<candidate id> {status, comment, at}; edited strings at "
                 "edits/<candidate id> {rhythm, original, at}.",
        "counts": {"candidates": len(cands), "rhythms": len(groups), "variations": len(placed),
                   "excluded": len(excluded), "rhythms_in_library": sum(g["in_library"] for g in groups)},
        "groups": [{**{k: g[k] for k in ("slug", "display", "meter", "in_library")},
                    "variations": [{k: v[k] for k in ("vid", "id", "title", "rhythm", "written_meter", "conf")}
                                   for v in g["variations"]]} for g in groups],
        "excluded": [{k: e[k] for k in ("id", "title", "rhythm", "reason")} for e in excluded],
    }
    (HERE / "review.json").write_text(json.dumps(review, ensure_ascii=False, indent=1) + "\n")

    # page data: the review plus the crops
    for g in groups:
        for v in g["variations"]:
            v["img"] = old[v["id"]]["img"]
    man = json.loads((EDITOR / "samples/manifest.json").read_text())
    names = sorted({n for ns in man["strokes"].values() for n in ns})
    samples = {n: base64.b64encode((EDITOR / f"samples/{n}.mp3").read_bytes()).decode() for n in names}
    man = {k: man[k] for k in ("strokes", "gain", "accent_gain", "trill_strokes", "trill_last")}

    tpl = (HERE / "review_template.html").read_text()
    js = lambda o: json.dumps(o, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    out = (tpl.replace("/*GROUPS*/[]", js(groups)).replace("/*EXCLUDED*/[]", js(excluded))
              .replace("/*EXERCISES*/[]", js(exercises)).replace("/*SAMPLES*/{}", js(samples))
              .replace("/*MANIFEST*/{}", js(man)).replace("/*COUNTS*/{}", js(review["counts"]))
              .replace("/*RHYTHM_JS*/", (HERE / "review_rhythm.js").read_text())
              .replace("/*NOTATION_JS*/", (HERE / "review_notation.js").read_text())
              .replace("/*PLAYER_JS*/", (HERE / "review_player.js").read_text()))
    assert "/*" + "GROUPS*/" not in out and "/*PLAYER_JS*/" not in out
    Path(out_html).write_text(out)
    print(json.dumps(review["counts"]), f"{len(out) / 1e6:.2f} MB")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
