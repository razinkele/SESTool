"""Verify data/wp5_readiness_items.json text against D5.4 Annexes 5 and 7 (spec 2026-10-17 WS-9b §8)."""
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
D54 = WP5 / "Task 5.4 Governance Measures & Targets" / "Deliverable 5.4" / "final version" / \
    "MarineSABRES_D5.4 Governance Arrangements_29.05.2026.pdf"
BANK = json.loads((APP / "data" / "wp5_readiness_items.json").read_text(encoding="utf-8"))
needs_src = pytest.mark.skipif(not D54.exists(), reason="D5.4 sources not available (WP5/ is not in git)")
ANNEX5_PAGES = range(140, 146)    # PDF pages (printed 139-144)
ANNEX7_PAGES = range(149, 154)


def key(s):
    return re.sub(r"[^0-9a-z]", "", unicodedata.normalize("NFKC", s).lower())


@lru_cache(maxsize=None)
def pages_text(first, last):
    import fitz
    doc = fitz.open(str(D54))
    return key(" ".join(doc[p - 1].get_text() for p in range(first, last + 1)))


@needs_src
@pytest.mark.parametrize("item", BANK["items"], ids=lambda it: it["id"])
def test_item_text_is_in_its_annex(item):
    pages = ANNEX7_PAGES if item["source_ref"].startswith("D5.4 Annex 7") else ANNEX5_PAGES
    assert key(item["text_en"]) in pages_text(pages.start, pages.stop - 1), item["id"]


@needs_src
def test_a_made_up_item_is_rejected():
    assert key("Stakeholders always agree on everything") not in pages_text(140, 145)
