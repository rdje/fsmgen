#!/usr/bin/env python3
"""Run one admitted genuine witness and retain its complete outcome."""
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
CAPTURE = "generated_input_fixed_oct01"
OBSERVER = "docs/audits/generated-input-observer-20261001"
WORK = ROOT / ".artifacts/generated-input-native-observer" / CAPTURE
OUTPUT = ROOT / ".artifacts/record-input-generated-observation-corrected-20261001"


def digest(data):
    return hashlib.sha256(data).hexdigest()


def write(name, data):
    with (OUTPUT / name).open("xb") as stream:
        stream.write(data)


def save(name, value):
    write(name, (json.dumps(value, indent=2, sort_keys=True) + "\n").encode())


def identities(paths):
    records = {}
    for name in paths:
        path = ROOT / name
        assert path.is_file() and not path.is_symlink()
        assert path.stat().st_dev == ROOT.stat().st_dev
        data = path.read_bytes()
        blob = subprocess.check_output(
            ["git", "rev-parse", "HEAD:" + name], cwd=ROOT, text=True).strip()
        original = subprocess.check_output(["git", "cat-file", "blob", blob], cwd=ROOT)
        assert data == original, name
        records[name] = {"sha256": digest(data), "git_blob": blob}
    return records


def main():
    assert Path.cwd().resolve() == ROOT
    assert os.environ.get("FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME") == "1"
    assert not os.environ.get("PERL5OPT")
    assert not WORK.exists() and not WORK.with_name(CAPTURE + "-admission.json").exists()
    assert not OUTPUT.exists()
    OUTPUT.mkdir()
    assert OUTPUT.stat().st_dev == ROOT.stat().st_dev
    write("observation-command.py.source", Path(__file__).read_bytes())
    baseline = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    subprocess.run(["perl", OBSERVER + "/prepare.pl", CAPTURE, "generated_input", "none", "5", "5"],
                   cwd=ROOT, check=True)
    admission = json.loads(WORK.with_name(CAPTURE + "-admission.json").read_bytes())
    extra = ["perl/FSM/Adapter/ISF.pm", "perl/FSM/Scheduler/ISF.pm",
             "perl/FSM/Scheduler/ISF/RecordSamples.pm",
             "perl/FSM/Backend/GeneratedModuleEmitter.pm",
             "perl/FSM/IR/LoweredRTLIRBuilder.pm",
             "perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm"]
    paths = sorted(set(admission["sha256"]) | set(extra))
    before = identities(paths)
    save("before.json", {"baseline_revision": baseline, "producers": before})
    command = ["prove", "-v", OBSERVER + "/observe.t", "::", CAPTURE]
    result = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    write("prove-stdout.txt", result.stdout)
    write("prove-stderr.txt", result.stderr)
    save("observed-result.json", {"exit_code": result.returncode, "command": command,
         "stdout_sha256": digest(result.stdout), "stderr_sha256": digest(result.stderr),
         "completed_utc": datetime.now(timezone.utc).isoformat()})
    after = identities(paths)
    save("after.json", {"producers": after})
    stages = [json.loads(path.read_bytes()) for path in sorted(WORK.glob("compile_*.json"))]
    workspaces = sorted({str(Path(stage["arguments"][0][10]).parent) for stage in stages})
    for work in workspaces:
        assert work.startswith(".artifacts/tmp/tests/") and ".." not in Path(work).parts
    processes = subprocess.check_output(["/bin/ps", "-axo", "pid=,ppid=,command="], text=True)
    residue = [line.strip() for line in processes.splitlines() if any(work in line for work in workspaces)]
    save("postcheck.json", {"observed_utc": datetime.now(timezone.utc).isoformat(),
         "workspaces": workspaces, "workspace_absent": {work: not (ROOT / work).exists() for work in workspaces},
         "selected_command_residue": residue,
         "native_pid_absence": "not independently measured; successful native calls intentionally produce no context records",
         "stage_cleanup": "complete original supervisor cleanup retained in each stage"})
    assert before == after
    assert not residue and all(not (ROOT / work).exists() for work in workspaces)
    print("Genuine witness completed; original exit:", result.returncode, flush=True)
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
