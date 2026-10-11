# scripts/kb_audit/test_build_wp5_mechanisms_kb.py
"""Tests for the WP5 KB v2 builder (spec 2026-10-11 WS-2).
Run: micromamba run -n shiny python -m pytest scripts/kb_audit/test_build_wp5_mechanisms_kb.py -q
"""
import importlib.util
import json
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

def test_clean_cell():
    assert bk.clean_cell("**C_02 improves** \\[6, 15\\] a<br>b  c") == "C_02 improves [6, 15] a b c"


def test_split_row_escaped_pipe():
    assert bk.split_row("| 1 | a \\| b | **c** |") == ["1", "a \\| b", "**c**"]


def test_parse_pipe_table_skips_separator_and_maps_headers():
    sec = "*Table 9. X*\n\n| **Financial mechanism** | **Who pays** |\n|:---|:---|\n| A | B |\n| C | D |\n"
    assert bk.parse_pipe_table(sec) == [{"Financial mechanism": "A", "Who pays": "B"},
                                        {"Financial mechanism": "C", "Who pays": "D"}]


def test_split_name_cost():
    assert bk.split_name_cost("**Blue Corridor coordination & platform resourcing** Recurring (fixed annual / multi-year)") == \
        ("Blue Corridor coordination & platform resourcing", "Recurring (fixed annual / multi-year)")


def test_parse_risks_pairs():
    cell = "**Risk:** platform symbolic. **Guardrail:** publish work programme. **Risk:** fatigue. **Guardrail:** limit plenaries."
    assert bk.parse_risks(cell) == [{"risk": "platform symbolic.", "guardrail": "publish work programme."},
                                    {"risk": "fatigue.", "guardrail": "limit plenaries."}]


def test_find_indicator_codes_flags_noncanonical():
    assert bk.find_indicator_codes("C_02 improves; see M_01/M_02 and F_04 exposure; T_03") == \
        (["C_02", "M_01", "M_02", "T_03"], ["F_04"])


def test_ref_numbers():
    assert bk.ref_numbers("literature **\\[6, 15, 18\\]** and [24]") == [6, 15, 18, 24]


def test_parse_scenarios():
    sec = ("#### Scenario 1: No Agreement\n#### Scenario 2: Partial Agreement\n#### Scenario 3: Full Agreement\n"
           "### 5.4.1 Scenario 1: Business-as-usual (No Corridor)\n### 5.4.2 Scenario 2: Corridor – Light Designation (Voluntary coordination)\n")
    sc = bk.parse_scenarios(sec)
    assert [s["code"] for s in sc["arctic"]] == ["no_agreement", "partial_agreement", "full_agreement"]
    assert sc["macaronesia"][1] == {"code": "S2", "name": "Corridor – Light Designation (Voluntary coordination)",
                                    "source_ref": {"document": bk.DOC_DRAFTV5, "section": "5.4.2"}}
    assert sc["tuscan"] == []


def test_cost_band_parts():
    assert bk.cost_band_parts("€€–€€€*") == (["€€", "€€€"], True)
    assert bk.cost_band_parts("€") == (["€"], False)


def test_code_arctic_applicability():
    assert bk.code_arctic_applicability("Most effective under Full Agreement; fragmented under No/Partial Agreement") == \
        {"full_agreement": "most_effective", "no_agreement": "fragmented", "partial_agreement": "fragmented"}
    assert bk.code_arctic_applicability("an unseen phrase") is None


def test_name_tokens_overlap():
    assert bk.name_tokens_overlap("Blue Corridor coordination & platform resourcing",
                                  "Corridor coordination & platform resourcing (MoU → steering → secretariat)") >= 2
    assert bk.name_tokens_overlap("Seasonal enforcement surge", "Due process & appeals handling capacity") == 0


EXTRACT = APP / "scripts" / "wp5_kb_sources" / "d5.2_v5_mechanism_sources.md"
KB_JSON = APP / "data" / "ses_knowledge_db_wp5_mechanisms.json"
needs_extract = pytest.mark.skipif(not EXTRACT.exists(), reason="extract not generated yet")


@needs_extract
def test_build_kb_counts_ids_scenarios():
    kb = bk.build_kb(bk.read_extract(EXTRACT))
    assert {d: len(v["mechanisms"]) for d, v in kb["demonstration_areas"].items()} == {"arctic": 8, "tuscan": 7, "macaronesia": 16}
    ids = [m["id"] for v in kb["demonstration_areas"].values() for m in v["mechanisms"]]
    assert len(set(ids)) == 31
    assert kb["scenarios"]["tuscan"] == [] and len(kb["scenarios"]["macaronesia"]) == 4 and len(kb["scenarios"]["arctic"]) == 3


@needs_extract
def test_build_kb_spot_values_from_real_tables():
    kb = bk.build_kb(bk.read_extract(EXTRACT))
    by = {m["id"]: m for v in kb["demonstration_areas"].values() for m in v["mechanisms"]}
    assert by["arc_02"]["who_pays"] == "National governments / fisheries authorities"
    assert by["arc_07"]["name"] == "Fisheries research and innovation funds"
    assert by["tus_05"]["applicability_text"] == "Low–Medium (currently limited enabling conditions)"
    assert by["mac_01"]["cost_band"] == "€€" and by["mac_07"]["cost_band"] == "€"
    assert "C_02" in by["mac_01"]["derived"]["success_metrics"]
    assert by["mac_01"]["toolkit"]["provenance"] == "wp5_prefinal"
    assert by["mac_01"]["toolkit"]["source_ref"]["in_final_d52"] is False
    assert all("use_in_impact_assessment" not in m.get("toolkit", {}) for m in by.values())
    assert all("toolkit" not in by[i] for i in by if not i.startswith("mac_"))
    assert all(by[f"arc_0{i}"]["derived"]["scenario_applicability"] for i in range(1, 9))


@needs_extract
def test_every_cost_band_is_in_the_legend():
    kb = bk.build_kb(bk.read_extract(EXTRACT))
    for m in kb["demonstration_areas"]["macaronesia"]["mechanisms"]:
        parts, _ = bk.cost_band_parts(m["cost_band"])
        assert parts and all(p in {"€", "€€", "€€€", "€€€€"} for p in parts), m["id"]


@needs_extract
def test_extract_excludes_superseded_toolkit_draft():
    assert "to be deleted" not in EXTRACT.read_text(encoding="utf-8")


@needs_extract
def test_default_build_is_byte_stable_and_matches_committed_json():
    kb = bk.build_kb(bk.read_extract(EXTRACT))
    assert bk.kb_json_text(kb) == KB_JSON.read_text(encoding="utf-8")
