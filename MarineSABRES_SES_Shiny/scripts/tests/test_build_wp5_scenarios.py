"""Tests for scripts/build_wp5_scenarios.py (spec 2026-10-16 WS-8 §3.3)."""
import collections
import importlib.util
import json
import os
from pathlib import Path

import pytest

APP = Path(__file__).resolve().parents[2]
DEFAULT_SRC = Path("C:/Users/arturas.baziukas/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/"
                   "MarineSABRES_SES_Shiny/WP5/Task 5.1 Application of Scenarios")
SRC = Path(os.environ.get("WP5_D51_SRC", DEFAULT_SRC))
needs_src = pytest.mark.skipif(not SRC.exists(), reason="D5.1 sources not available (WP5/ is not in git)")

spec = importlib.util.spec_from_file_location("build", APP / "scripts" / "build_wp5_scenarios.py")
build = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build)


def test_split_slices_and_gap_codes():
    parts = build.split_slices("Intro text\nHABITAT RESTORATION AND MARINE CONSERVATION\nSSP not featured in Future MARES, "
                               "no specific lines in CERES.\nSEAFOOD HARVESTING\nFish\nTOURISM AND LEISURE\nNo specific lines in AFMEC")
    assert parts["general"] == "Intro text"
    assert build.gap_code(parts["hrmc"]) == "ssp_not_in_futuremares"
    assert build.gap_code(parts["sh"]) is None
    assert build.gap_code(parts["lh"]) == "no_afmec_lines"
    assert build.gap_code("No specific lines in AFMEC.") == "no_afmec_lines"
    assert build.gap_code("") == "no_source_text"


@needs_src
def test_build_real_sources(tmp_path):
    scen, matrix = build.build(SRC, tmp_path)
    assert [s["id"] for s in scen["scenarios"]] == build.SSPS
    assert len(matrix["cells"]) == 72
    assert collections.Counter(c["transformation"] for c in matrix["cells"]) == {"none": 39, "europe": 18, "area": 15}
    general = sum(1 for s in scen["scenarios"] for cell in s["cells"].values() if cell["general"]["text"])
    assert general == 12
    for s in scen["scenarios"]:
        for cell in s["cells"].values():
            for v in cell.values():
                assert (v["text"] is None) == (v["gap_note"] is not None)
    assert all(v for w in matrix["worldviews"] for v in w["pestle"].values())
    assert all(c["rationale"] for c in matrix["cells"])
    assert not any(c["rationale"].startswith("*") for c in matrix["cells"])


@needs_src
def test_rerun_is_byte_identical(tmp_path):
    build.build(SRC, tmp_path / "a")
    build.build(SRC, tmp_path / "b")
    for name in ("wp5_scenarios_ssp.json", "wp5_worldview_matrix.json"):
        assert (tmp_path / "a" / name).read_bytes() == (tmp_path / "b" / name).read_bytes()


@needs_src
def test_committed_json_matches_a_fresh_build(tmp_path):
    build.build(SRC, tmp_path)
    for name in ("wp5_scenarios_ssp.json", "wp5_worldview_matrix.json"):
        assert (APP / "data" / name).read_bytes() == (tmp_path / name).read_bytes()


def test_wingdings_and_expected_exceptions():
    assert (build.TICK, build.CROSS) == ("\u00fc", "\u00fd")
    assert build.EXPECTED_X_DIFF == {("hierarchy", "ssp3_70", "political")}
    assert build.EXPECTED_TRANSFORM_DIFF == {("hierarchy", "ssp3_70", "political"),
                                             ("hierarchy", "ssp3_70", "environmental")}


@needs_src
def test_spreadsheet_checks_pass(tmp_path):
    _, matrix = build.build(SRC, tmp_path)
    assert build.check_against_spreadsheet(SRC, matrix) == []


def test_committed_json_shape():
    m = json.loads((APP / "data" / "wp5_worldview_matrix.json").read_text(encoding="utf-8"))
    assert len(m["cells"]) == 72
    assert {c["transformation"] for c in m["cells"]} <= {"area", "europe", "none"}
