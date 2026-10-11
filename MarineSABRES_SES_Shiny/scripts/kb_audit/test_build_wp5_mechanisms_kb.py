# scripts/kb_audit/test_build_wp5_mechanisms_kb.py
"""Tests for the WP5 KB v2 builder (spec 2026-10-11 WS-2).
Run: micromamba run -n shiny python -m pytest scripts/kb_audit/test_build_wp5_mechanisms_kb.py -q
"""
import importlib.util
from pathlib import Path

import pytest

APP = Path(__file__).resolve().parents[2]
_spec = importlib.util.spec_from_file_location("bk", APP / "scripts" / "build_wp5_mechanisms_kb.py")
bk = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(bk)
FIX = APP / "scripts" / "kb_audit" / "fixtures" / "final_table22_region_snippet.txt"
WP5 = Path("C:/Users/arturas.baziukas/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/WP5")


def test_cut_section_returns_lines_between_markers():
    text = "a\n*Table 9. X*\nrow1\nrow2\n\nFinancial feasibility next\nz"
    assert bk.cut_section(text, r"^\*Table 9\.", r"^Financial feasibility").splitlines() == ["*Table 9. X*", "row1", "row2", ""]


def test_cut_section_missing_start_raises():
    with pytest.raises(ValueError):
        bk.cut_section("nothing here", r"^Table 99", r"^end")


def test_normalize_for_match_strips_glyphs_and_case():
    assert bk.normalize_for_match("Corridor coordination (MoU → steering)") == "corridorcoordinationmousteering"


def test_pdf_table_region_skips_toc_and_stops_at_next_caption():
    region = bk.pdf_table_region(FIX.read_text(encoding="utf-8"), "macaronesia")
    assert "Due process" in region and "Blue Corridor Facility" not in region and "........ 112" not in region


def test_name_guard_handles_hyphen_wrap():
    pdf = FIX.read_text(encoding="utf-8")
    names = {"macaronesia": ["Corridor coordination & platform resourcing (MoU → steering → secretariat)",
                             "Due process & appeals handling capacity"]}
    assert bk.verify_names_against_pdf(names, pdf) == []


def test_name_guard_rejects_v1_invented_name():
    pdf = FIX.read_text(encoding="utf-8")
    assert bk.verify_names_against_pdf({"macaronesia": ["Blue Corridor Facility"]}, pdf) == ["Blue Corridor Facility"]


def test_pdftotext_tolerates_cesu_bytes(monkeypatch):
    class R:  # fake CompletedProcess carrying CESU-8 surrogate bytes, as xpdf emits
        stdout = b"ok \xed\xa0\xb5 text"
    monkeypatch.setattr(bk.subprocess, "run", lambda *a, **k: R())
    assert bk.pdftotext(Path("x.pdf"), "pdftotext").startswith("ok ")


def test_check_pins_reports_changed_hashes():
    old = {"draftv5_sha256": "a", "toolkit_sha256": "b", "final_pdf_sha256": "c"}
    assert bk.check_pins(old, dict(old), accept=False) == []
    assert bk.check_pins(old, {**old, "toolkit_sha256": "z"}, accept=False) == ["toolkit_sha256"]
    assert bk.check_pins(old, {**old, "toolkit_sha256": "z"}, accept=True) == []
    assert bk.check_pins({}, {**old}, accept=False) == []   # first generation


def test_extract_roundtrip(tmp_path):
    p = tmp_path / "x.md"
    bk.write_extract({"table9_arctic": "| a | b |\n|---|---|\n| 1 | 2 |"}, {"draftv5_sha256": "abc"}, p)
    secs = bk.read_extract(p)
    assert secs["table9_arctic"].strip().endswith("| 1 | 2 |")
    assert secs["__header__"]["draftv5_sha256"] == "abc"


@pytest.mark.skipif(not (WP5 / "D5.2" / "MarineSABRES_D5.2_Final.pdf").exists(), reason="WP5 sources not present")
def test_name_guard_on_real_final_pdf_rejects_v1_names():
    pdf = bk.pdftotext(WP5 / "D5.2" / "MarineSABRES_D5.2_Final.pdf", bk.find_pdftotext())
    bad = {"macaronesia": ["Blue Corridor Facility", "MPA tourism-levy fund"],
           "arctic": ["National financing of NEAFC governance and enforcement"]}
    assert sorted(bk.verify_names_against_pdf(bad, pdf)) == sorted(sum(bad.values(), []))
