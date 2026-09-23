#!/usr/bin/env python3
"""Review the first compiler capture without ever rerunning its producer."""
import argparse
import base64
import datetime
import hashlib
import json
import os
from pathlib import Path
import subprocess
import stat

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
SAVED = HERE / "result"
LIVE = ROOT / ".artifacts/tmp/compiler-receipt-capture-20260923"
RECORDS = ("attempt.json", "launch.json", "first-state.json", "preparation.json", "preflight.json")
if not __debug__:
    raise SystemExit("review requires Python assertions enabled")


def unique_pairs(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate JSON key")
        result[key] = value
    return result


def read(path):
    if path.is_symlink() or not path.is_file() or path.stat().st_size > 131_072:
        raise ValueError("capture input is not a bounded regular file")
    raw = path.read_bytes()
    if str(ROOT).encode() in raw:
        raise ValueError("capture leaks the checkout path")
    return raw, json.loads(raw, object_pairs_hook=unique_pairs)


def command(argv):
    environment = {"PATH": "/usr/bin:/bin", "LC_ALL": "C", "LANG": "C",
                   "TMPDIR": str(ROOT / ".artifacts/tmp"), "GIT_CONFIG_NOSYSTEM": "1",
                   "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_OPTIONAL_LOCKS": "0"}
    result = subprocess.run(argv, cwd=ROOT, env=environment, capture_output=True, timeout=10, check=True)
    if len(result.stdout) + len(result.stderr) > 1_048_576:
        raise ValueError("read-only review command exceeded its output bound")
    return result.stdout


def verify(directory):
    loaded = {name: read(directory / name) for name in RECORDS}
    records = {name: pair[1] for name, pair in loaded.items()}
    attempt, launch, first, prepared, preflight = (records[name] for name in RECORDS)
    revision = attempt["plan"]["source_revision"]
    if len(revision) != 40 or any(c not in "0123456789abcdef" for c in revision):
        raise ValueError("invalid captured source revision")
    assert preflight["source_revision"] == revision and preflight["git_status_porcelain"] == ""
    for path, digest in attempt["source_files"].items():
        assert not Path(path).is_absolute() and ".." not in Path(path).parts
        original = command(["/usr/bin/git", "show", f"{revision}:{path}"])
        assert hashlib.sha256(original).hexdigest() == digest, f"source drift: {path}"
    private, observed, result = (first[k] for k in ("private_state", "observation", "result"))
    assert first["schema"] == "fsmgen.compiler_receipt_capture.v1"
    assert private["phase"] == observed["phase"] == "finished"
    assert private["stage"] == observed["stage"] == result["stage"] == "compile_proxy"
    assert observed["role"] == "compiler"
    assert type(private["pid"]) is int and 0 < private["pid"] <= 2_147_483_647
    assert type(private["birth_sec"]) is int and private["birth_sec"] > 0
    assert type(private["birth_usec"]) is int and 0 <= private["birth_usec"] < 1_000_000
    assert observed["birth"] == observed["group"] == {
        "pid": private["pid"], "start_sec": private["birth_sec"], "start_usec": private["birth_usec"]}
    # waitpid's raw success status must agree with the public classification.
    assert private["leader_status"] == result["exit_code"] == result["signal"] == 0
    assert result["ok"] == 1 and result["status"] == "success"
    assert private["cleanup"] == observed["cleanup"] == result["cleanup"]
    assert private["leader_reaped"] == observed["leader_reaped"] == 1
    cleanup = private["cleanup"]
    assert all(cleanup[k] == 1 for k in ("leader_started", "leader_reaped", "group_gone"))
    assert all(cleanup[k] == 0 for k in ("term_sent", "kill_sent", "surviving_descendants"))
    assert first["review"] == {"original_cleanup_shared": 1, "raw_wait_matches": 1,
                               "finished_job_accepted": 1, "receipt_bound": 1}
    assert prepared["ok"] == 1 and prepared["compilation"] == result
    assert prepared["implementation"] == attempt["selection"]["implementation"] == "native"
    assert attempt["selection"]["compiler"] == preflight["external_dependencies"]["compiler"]
    assert attempt["selection"]["sdk"] == preflight["external_dependencies"]["sdk"]
    request = launch["request"]
    assert request["argv"] == prepared["compilation_argv"]
    assert request["cwd"] == "." and request["stage"] == "compile_proxy"
    assert request["bounds"] == {"timeout_seconds": 10, "capture_limit_bytes": 4096}
    assert request["containment"] == cleanup["containment"] == "rust_proxy_compiler_group"
    assert all(launch["environment"][key].startswith(attempt["workspace"] + "/")
               for key in ("TMPDIR", "TMP", "TEMP", "XDG_CACHE_HOME", "CLANG_MODULE_CACHE_PATH"))
    return {"source_revision": revision, "compiler_pid": private["pid"],
            "record_sha256": {name: hashlib.sha256(pair[0]).hexdigest() for name, pair in loaded.items()},
            "scope": "One dated direct-fork compiler result. In-process cleanup sharing is the driver's retained observation; serialized addresses are not live ownership. No kernel birth, probe, proxy runtime, live collector or startup qualification."}


def archive_workspace():
    _, attempt = read(SAVED / "attempt.json")
    _, prepared = read(SAVED / "preparation.json")
    workspace = ROOT / attempt["workspace"]
    expected_files = {entry["path"]: entry for entry in prepared["sources"]}
    expected_directories = {workspace, workspace / "rust-tools",
                            workspace / "rust-tools/compiler-cache", workspace / "rust-tools/compiler-temp"}
    expected_paths = expected_directories | {ROOT / name for name in expected_files}
    assert {workspace, *workspace.rglob("*")} == expected_paths, "unexpected workspace membership"
    nodes = []
    for path in sorted(expected_paths):
        before = path.lstat()
        assert before.st_uid == os.getuid() and before.st_dev == ROOT.stat().st_dev
        relative = str(path.relative_to(ROOT))
        node = {"path": relative, "device": before.st_dev, "inode": before.st_ino,
                "mode": stat.S_IMODE(before.st_mode), "uid": before.st_uid}
        if path in expected_directories:
            assert stat.S_ISDIR(before.st_mode) and stat.S_IMODE(before.st_mode) == 0o700
            node["kind"] = "directory"
        else:
            assert stat.S_ISREG(before.st_mode) and before.st_size <= 65_536
            fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
            with os.fdopen(fd, "rb") as handle:
                opened = os.fstat(handle.fileno())
                assert (opened.st_dev, opened.st_ino) == (before.st_dev, before.st_ino)
                raw = handle.read(65_537)
            assert len(raw) == before.st_size
            digest = hashlib.sha256(raw).hexdigest()
            source = expected_files[relative]
            assert (before.st_dev, before.st_ino, len(raw), digest) == (
                source["device"], source["inode"], source["size_bytes"], source["sha256"])
            node.update(kind="file", size_bytes=len(raw), sha256=digest,
                        bytes_base64=base64.b64encode(raw).decode())
        assert path.lstat() == before, "workspace changed during archival read"
        nodes.append(node)
    packet = {"schema": "fsmgen.compiler_receipt_artifacts.v1", "workspace": attempt["workspace"],
              "source_revision": attempt["plan"]["source_revision"], "nodes": nodes,
              "scope": "Exact unexecuted compiler output retained for later owned work; archived bytes restore neither inode nor process authority."}
    raw = (json.dumps(packet, indent=2, sort_keys=True) + "\n").encode()
    assert len(raw) <= 131_072
    with (SAVED / "artifacts.json").open("xb") as handle:
        handle.write(raw)


def verify_archive(directory):
    _, packet = read(directory / "artifacts.json")
    _, prepared = read(directory / "preparation.json")
    _, attempt = read(directory / "attempt.json")
    assert packet["source_revision"] == attempt["plan"]["source_revision"]
    assert packet["workspace"] == attempt["workspace"]
    files = {node["path"]: node for node in packet["nodes"] if node["kind"] == "file"}
    assert set(files) == {entry["path"] for entry in prepared["sources"]}
    assert len({node["path"] for node in packet["nodes"]}) == len(packet["nodes"])
    workspace = packet["workspace"]
    directories = {workspace, workspace + "/rust-tools", workspace + "/rust-tools/compiler-cache",
                   workspace + "/rust-tools/compiler-temp"}
    assert {node["path"] for node in packet["nodes"]} == directories | set(files)
    for node in packet["nodes"]:
        if node["path"] in directories:
            assert node["kind"] == "directory" and node["mode"] == 0o700
    for source in prepared["sources"]:
        node = files[source["path"]]
        assert node["mode"] == (0o400 if source["path"].endswith(".c") else 0o500)
        assert (node["device"], node["inode"]) == (source["device"], source["inode"])
        raw = base64.b64decode(node["bytes_base64"], validate=True)
        assert len(raw) == node["size_bytes"] == source["size_bytes"]
        assert hashlib.sha256(raw).hexdigest() == node["sha256"] == source["sha256"]
    generated = next(node for path, node in files.items() if path.endswith("/rustup.c"))
    source = command(["/usr/bin/git", "show", f"{packet['source_revision']}:t/fixtures/rust-tool-proxy.c"])
    assert base64.b64decode(generated["bytes_base64"]) == b"#define PROXY_NONZERO 1\n" + source


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument("--capture", action="store_true")
    modes.add_argument("--verify-saved", action="store_true")
    modes.add_argument("--archive-workspace", action="store_true")
    args = parser.parse_args()
    if args.archive_workspace:
        verify(SAVED)
        archive_workspace()
        verify_archive(SAVED)
        print("compiler artifacts archived without execution or workspace removal")
        return
    capture = args.capture
    if capture:
        SAVED.mkdir(mode=0o700)  # Exclusive; partial evidence is never overwritten.
        for name in RECORDS:
            source = ROOT / ".artifacts/logs/compiler-receipt-preflight.json" if name == "preflight.json" else LIVE / name
            raw, _ = read(source)
            with (SAVED / name).open("xb") as handle:
                handle.write(raw)
        reviewed = verify(SAVED)
        # Independent read-only process-table observation; never signal a PID.
        rows = command(["/bin/ps", "-axo", "pid=,pgid="]).decode().splitlines()
        pid = reviewed["compiler_pid"]
        assert not any(pid in tuple(map(int, row.split())) for row in rows)
        reviewed["absence_observation"] = {"pid_and_group_absent": True,
            "captured_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "oracle": "/bin/ps -axo pid=,pgid=", "meaning": "Dated independent absence, not a reusable identity receipt."}
        with (SAVED / "review.json").open("x") as handle:
            json.dump(reviewed, handle, indent=2, sort_keys=True)
            handle.write("\n")
    else:
        reviewed = verify(SAVED)
        _, saved = read(SAVED / "review.json")
        absence = saved.pop("absence_observation")
        assert absence["pid_and_group_absent"] is True and absence["captured_utc"]
        assert saved == reviewed, "saved review drift"
        verify_archive(SAVED)
    print("compiler receipt review passed; producer was not rerun")


if __name__ == "__main__":
    main()
