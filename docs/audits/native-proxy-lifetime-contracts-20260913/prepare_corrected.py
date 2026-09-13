"""Repair one prospective invariant link, preserving the original rejected data."""
import copy
import json

import prepare

HERE, ROOT = prepare.HERE, prepare.ROOT


def main():
    for row in json.loads((HERE / "correction-pins.json").read_bytes()):
        raw = (ROOT / row["path"]).read_bytes()
        assert len(raw) == row["size_bytes"] and prepare.digest(raw) == row["sha256"]
    plan = prepare.authenticate()
    original = json.loads((HERE / "contracts.json").read_bytes())
    assert original == prepare.build(plan)
    declared = {row["id"] for row in original["functions"]}
    linked = {name for row in original["invariants"] for name in row["functions"]}
    assert declared - linked == {"cleanup.cleanup_receipts_settled"} and not linked - declared
    corrected = copy.deepcopy(plan)
    invariant = next(row for row in corrected["invariants"] if row["id"] == "private_before_global")
    invariant["functions"].append("cleanup.cleanup_receipts_settled")
    contract = prepare.build(corrected)
    assert contract["functions"] == original["functions"]
    assert contract["schedules"] == original["schedules"]
    assert contract["schedule_domain_sha256"] == original["schedule_domain_sha256"]
    for filename, value in (("corrected-plan.json", corrected), ("corrected-contracts.json", contract)):
        with (HERE / filename).open("x") as stream:
            json.dump(value, stream, sort_keys=True, indent=2); stream.write("\n")
    print(json.dumps(dict(added_link="cleanup.cleanup_receipts_settled", original_files_unchanged=True,
                          source_functions=len(contract["functions"]), prospective_schedules=len(contract["schedules"]),
                          schedule_domain_sha256=contract["schedule_domain_sha256"])))


if __name__ == "__main__":
    main()
