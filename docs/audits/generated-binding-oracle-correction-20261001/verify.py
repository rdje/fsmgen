"""Authenticate the bounded oracle repair; never compile or execute HDL."""
import hashlib
import json
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def accepted_receipts(focused, regression, red):
    assert "All tests successful." in focused and "Files=2, Tests=23," in focused
    assert "Result: PASS" in focused and "Result: FAIL" not in focused
    assert "All tests successful." in regression and "Files=8, Tests=50," in regression
    assert "Result: PASS" in regression and "Result: FAIL" not in regression
    assert "Result: FAIL" in red and "Files=1, Tests=2," in red
    assert "Failed test:  1" in red and "fixed bench binding token changed" in red
    assert "actual bench requires copied result inside the public copy window" in red
    assert "All tests successful." not in red


def preserves_other_checks(old, new):
    # Independently reverse only the declared binding observation changes.
    # Complete byte equality protects every other original behavioral predicate.
    restored = new.replace(" localparam bit COPY_RESULT_HOLDS = __COPY_RESULT_HOLDS__;\n", "")
    restored = restored.replace(
        "  bit copy_result_observed;\n  logic [4:0] late_copy_result;\n"
        "  copy_result_observed=0;\n"
        "  late_copy_result=COPY_RESULT_HOLDS ? copy_data : 5'b00000;\n", "")
    start = restored.index("  // The blocking binding is valid at child completion, before phase 2.\n")
    end = restored.index("  packet=live_word;\n", start) + len("  packet=live_word;\n")
    window = restored[start:end]
    assert "phase===2'd1 && copy_seen===copy_data" in window
    assert "if (!copy_result_observed)" in window
    assert "@(negedge clk);" in window
    restored = restored[:start] + "  wait(phase===2'd2);\n  @(negedge clk); packet=live_word;\n" + restored[end:]
    restored = restored.replace(
        '  if (copy_seen !== late_copy_result)\n   $fatal(1,"GENERATED_BOUND_RESULT_RETENTION_MISMATCH");\n', "")
    restored = restored.replace(
        '  if (copy_seen !== late_copy_result)\n   $fatal(1,"GENERATED_BOUND_RESULT_IDLE_MISMATCH");\n', "")
    restored = restored.replace("if (stored !== copy_data || copied_tag !== copy_tag",
        "if (stored !== copy_data || copy_seen !== copy_data || copied_tag !== copy_tag")
    restored = restored.replace("if (seen !== live_data || again !== live_data || stored !== copy_data\n",
        "if (seen !== live_data || again !== live_data || stored !== copy_data || copy_seen !== copy_data\n")
    assert restored == old


def main():
    manifest = json.loads((HERE / "manifest.json").read_text())
    assert manifest["schema"] == "fsmgen.generated_binding_oracle_correction.v1"
    assert manifest["baseline_revision"] == "db1fea32a23e712df417b08c3d34aeb0191f42c4"
    paths = {str(p.relative_to(HERE)) for p in HERE.rglob("*") if p.is_file() and p.name != "manifest.json"}
    assert paths == set(manifest["sha256"])
    for name, expected in manifest["sha256"].items():
        assert digest((HERE / name).read_bytes()) == expected, name
    for name, record in manifest["producers"].items():
        current = (ROOT / name).read_bytes()
        data = current if digest(current) == record["sha256"] else subprocess.check_output(
            ["git", "cat-file", "blob", record["git_blob"]], cwd=ROOT)
        assert digest(data) == record["sha256"], name
    for name, expected in manifest["prerequisites"].items():
        assert digest((ROOT / name).read_bytes()) == expected, name
    for path, saved in (("t/2025-isf-record-input-generated-runtime.t", "old-test.t.source"),
                        ("t/data/isf_record_input_generated_runtime_tb.sv", "old-bench.sv.source")):
        original = subprocess.check_output(["git", "show", manifest["baseline_revision"] + ":" + path], cwd=ROOT)
        assert original == (HERE / saved).read_bytes()
    test = (HERE / "test.t.source").read_text()
    assert digest(test.encode()) == manifest["producers"]["t/2025-isf-record-input-generated-runtime.t"]["sha256"]
    control = (HERE / "control-test.t.source").read_text()
    old_line = "my $bench_path = 't/data/isf_record_input_generated_runtime_tb.sv';"
    assert test.count(old_line) == 1
    assert control == test.replace(old_line, "my $bench_path = '.artifacts/generated-binding-old-oracle/bench.sv';")
    old = (HERE / "old-bench.sv.source").read_text()
    new = (HERE / "bench.sv.source").read_text()
    assert digest(new.encode()) == manifest["producers"]["t/data/isf_record_input_generated_runtime_tb.sv"]["sha256"]
    preserves_other_checks(old, new)
    focused, regression, red = [(HERE / name).read_text() for name in ("focused.txt", "regression.txt", "old-oracle-red.txt")]
    accepted_receipts(focused, regression, red)
    for bad in ((red, regression, red), (focused, red, red), (focused, regression, focused)):
        try:
            accepted_receipts(*bad)
        except AssertionError:
            continue
        raise AssertionError("unrelated or weakened oracle receipt accepted")
    for bad in (new.replace("stored !== copy_data", "stored !== live_data"),
                new.replace("negative_seen !== live_negative", "negative_seen !== 0")):
        try:
            preserves_other_checks(old, bad)
        except AssertionError:
            continue
        raise AssertionError("unrelated behavioral weakening accepted")
    assert "complete packed" in manifest["scope"]
    assert manifest["hdl_execution"] == "not_run_in_this_correction"
    assert manifest["observer_scope"] == "unchanged fixed paths/schema/target and five compile/runtime pairs; new committed witness hashes required"
    print("Exact predecessor, corrected bench scope, temporal/packed controls and old-bench RED authenticated. Focused/regression receipts and hostile controls pass; fixed observer unchanged. Complete packed runtime still requires a fresh post-commit observation.")


if __name__ == "__main__":
    main()
