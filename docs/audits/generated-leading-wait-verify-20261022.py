#!/usr/bin/env python3
"""Verify exact retained old/current source identities and separate outcomes."""
import copy
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess


def require(value, message):
    if not value:
        raise ValueError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def verify(receipt):
    revision = "b680e95ac3dad1bd36c4accc8381737e2b56d23d"
    require(receipt["baseline_revision"] == revision == receipt["checkpoint"]["revision"], "exact baseline revision")
    module, test = receipt["module"], receipt["test"]
    for record in (module, test):
        data = record["text"].encode()
        require(len(data) == record["bytes"] and sha(data) == record["sha256"], "complete payload identity")
        require(subprocess.check_output(["git", "cat-file", "blob", record["git_blob"]]) == data,
                "independent stored Git blob join")
    for record in receipt["drafts"].values():
        require(sha(record["text"].encode()) == record["sha256"], "complete retained draft identity")
    require(receipt["before"]["test"]["sha256"] == receipt["drafts"]["pre-clone-oracle-test"]["sha256"],
            "first source regression and clone-oracle draft join")
    checkpoint = receipt["checkpoint"]
    require(test["sha256"] == checkpoint["test_sha256"], "unchanged corrected final regression")
    require(module["sha256"] == checkpoint["repair_sha256"], "exact restored repair")
    old = subprocess.check_output(["git", "show", revision + ":" + module["path"]])
    require(sha(old) == checkpoint["old_sha256"], "exact committed predecessor source")
    old_guard = subprocess.check_output(["git", "show", revision + ":perl/FSM/Scheduler/ISF/ChildActivation.pm"])
    streams = receipt["streams"]

    def text(epoch):
        return streams[".artifacts/generated-leading-wait-" + epoch + "-20261022.log"]["text"]

    for epoch, expected in (("corrected-red", checkpoint["old_sha256"]), ("corrected-green", module["sha256"])):
        result = re.search(r"^# loaded_identity=(.*)$", text(epoch), re.M)
        require(result is not None, "actual loader observation")
        identity = json.loads(result[1])
        require(set(identity) == {"FSM/Scheduler/ISF/LoweringIR.pm", "FSM/Scheduler/ISF/ChildActivation.pm"},
                "complete declared named-module loader census")
        for key, digest in (("FSM/Scheduler/ISF/LoweringIR.pm", expected),
                            ("FSM/Scheduler/ISF/ChildActivation.pm", sha(old_guard))):
            row = identity[key]
            require(row["sha256"] == digest and row["path"] == row["compiled_file"] == "perl/" + key,
                    "actual compiled method/file/hash association")
    require("Tests: 9 Failed: 7" in text("corrected-red") and "Failed tests:  1-7" in text("corrected-red"),
            "genuine semantic RED outcome")
    require("unknown independent oracle signal" not in text("corrected-red") and
            "Parse errors:" not in text("corrected-red"), "corrected RED is not an oracle abort")
    require("All tests successful." in text("corrected-green") and "Files=1, Tests=9" in text("corrected-green"),
            "current complete unchanged GREEN")
    require("unknown independent oracle signal go" in text("red"), "first oracle draft remains distinct")
    require("Failed test:  6" in text("green") and "wrong positive wait target" in text("green"),
            "first repaired sample-clone oracle mismatch remains distinct")
    require("All tests successful." in text("focused") and "Files=6, Tests=57" in text("focused"),
            "focused current preservation cohort")
    require("All tests successful." in text("docs") and "Files=2, Tests=50" in text("docs"),
            "actual complete book/task checks")
    require("syntax OK" in text("syntax"), "current module syntax")
    example = receipt["book_example"]
    require(sha(example["text"].encode()) == example["sha256"], "exact extracted example identity")
    native = json.loads(text("book-example").split("\n", 1)[1])
    require(native["success"] is True, "actual strict book example acceptance")


path = Path("docs/audits/generated-leading-wait-20261022.json.gz")
receipt = json.loads(gzip.decompress(path.read_bytes()))
verify(receipt)
for family in ("swapped_module", "missing_compiled_method", "changed_test"):
    hostile = copy.deepcopy(receipt)
    if family == "changed_test":
        hostile["test"]["text"] += "# unrelated changed oracle\n"
    else:
        key = ".artifacts/generated-leading-wait-corrected-red-20261022.log"
        stream = hostile["streams"][key]
        result = re.search(r"^# loaded_identity=(.*)$", stream["text"], re.M)
        identity = json.loads(result[1])
        if family == "swapped_module":
            identity["FSM/Scheduler/ISF/LoweringIR.pm"]["sha256"] = hostile["module"]["sha256"]
        else:
            del identity["FSM/Scheduler/ISF/LoweringIR.pm"]["compiled_file"]
        stream["text"] = stream["text"][:result.start(1)] + json.dumps(identity) + stream["text"][result.end(1):]
    try:
        verify(hostile)
    except (ValueError, KeyError):
        pass
    else:
        raise ValueError("hostile identity/oracle record accepted: " + family)
print("generated leading wait: exact old/current loaded sources, unchanged oracle, separate epochs and hostile controls pass")
