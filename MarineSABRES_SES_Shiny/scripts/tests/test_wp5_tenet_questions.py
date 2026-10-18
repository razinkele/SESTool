"""Verify data/wp5_tenet_guiding_questions.json against D5.2 Annex 4 (spec 2026-10-18 WS-10 §3)."""
import json
import os
import re
import unicodedata
from functools import lru_cache
from pathlib import Path

import pytest

APP = Path(__file__).resolve().parents[2]
WP5 = Path(os.environ.get("WP5_DIR", "C:/Users/arturas.baziukas/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/"
                                     "SESToolbox/MarineSABRES_SES_Shiny/WP5"))
D52 = WP5 / "D5.2" / "MarineSABRES_D5.2_Final.pdf"
QS = json.loads((APP / "data" / "wp5_tenet_guiding_questions.json").read_text(encoding="utf-8"))
TENETS = ["ecol_effective", "tech_feasible", "econ_efficient", "econ_viable", "socially_desirable",
          "ethically_defensible", "culturally_inclusive", "legally_permissible", "admin_achievable",
          "communicable", "politically_expedient"]
needs_src = pytest.mark.skipif(not D52.exists(), reason="D5.2 source not available (WP5/ is not in git)")
ANNEX4 = (219, 222)   # printed page = PDF page


def key(s):
    return re.sub(r"[^0-9a-z]", "", unicodedata.normalize("NFKC", s).lower())

@lru_cache(maxsize=None)
def annex_pages():
    """Normalised text of each Annex 4 page, minus the printed page number that opens it."""
    import fitz
    doc = fitz.open(str(D52))
    return [key(re.sub(r"^\s*\d+\s+", "", doc[p - 1].get_text())) for p in range(ANNEX4[0], ANNEX4[1] + 1)]


def in_annex(text):
    """True when text is on one page, or runs over a page break (the form's radio widgets sit between
    the two halves on the first page, so the halves are checked separately: first half anywhere on page
    p, second half at the very start of page p+1)."""
    k = key(text)
    pages = annex_pages()
    if any(k in pg for pg in pages):
        return True
    return any(k[:i] in pages[p] and pages[p + 1].startswith(k[i:])
               for p in range(len(pages) - 1) for i in range(1, len(k)))


def test_eleven_questions_in_tenet_order():
    assert [q["tenet"] for q in QS["questions"]] == TENETS
    assert all(ANNEX4[0] <= q["source_page"] <= ANNEX4[1] for q in QS["questions"])


@needs_src
@pytest.mark.parametrize("q", QS["questions"], ids=lambda q: q["tenet"])
def test_question_text_is_in_annex4(q):
    assert in_annex(q["text_en"]), q["tenet"]


@needs_src
def test_a_made_up_question_is_rejected():
    assert not in_annex("To what extent is this measure loved by everyone?")
