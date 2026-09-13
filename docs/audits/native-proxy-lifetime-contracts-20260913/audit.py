"""Independently check source spans, guard locations and prospective schedules."""
import copy
import json
import sys

import prepare

HERE, ROOT = prepare.HERE, prepare.ROOT
EVENTS = {"archive_a", "archive_b", "retire_target", "release_a", "release_b", "retire_other", "maintain_target"}


def check_pins():
    rows = json.loads((HERE / "preflight-pins.json").read_bytes())
    for row in rows:
        body = (ROOT / row["path"]).read_bytes()
        assert len(body) == row["size_bytes"] and prepare.digest(body) == row["sha256"]
    return rows


def declarations(raw):
    # Independent line/byte walk, without the producer's regular expression.
    found = []
    offset = 0
    for line in raw.splitlines(keepends=True):
        if line.startswith(b"sub "):
            name = line[4:].split(None, 1)[0].decode()
            assert name.isidentifier()
            found.append((name, offset))
        offset += len(line)
    assert len({name for name, _ in found}) == len(found)
    return {name: (start, found[index + 1][1] if index + 1 < len(found) else len(raw) - len(b"1;\n"))
            for index, (name, start) in enumerate(found)}


def ordered(raw, *markers):
    previous = -1
    for marker in markers:
        position = raw.index(marker.encode("ascii"), previous + 1)
        assert position > previous
        previous = position


def source_rules(bodies):
    census = bodies["census._decode_record"]
    assert b"fsmgen.test.rust_proxy_image_reference.v1" in census
    assert b"fsmgen.test.rust_proxy_image_observation_reference.v1" in census
    assert b"$runtime_only" in census
    retention = bodies["maintenance._referenced"]
    assert b"$_->{record}{image_key} eq $key" in retention and b"->{schema}" not in retention
    ordered(bodies["retirement._retire_locked"], "_reference($plan->{reference}{global})",
            "_reference($plan->{reference}{private})", "::_remove($plan->{workspace})", "::_absent($plan->{workspace}{workspace}{path})")
    ordered(bodies["retirement._release_locked"], "_preserved($plan->{before}, $current)",
            "::_absent($plan->{workspace}{workspace}{path})", "_reference($plan->{reference}{global})",
            "_unlink_global($global)", "::_absent($global)")
    assert b"$_->{source}{identity}{path} ne $global" in bodies["retirement._finish_locked"]
    assert b"retirement changed the released image" in bodies["retirement._finish_locked"]
    observe = bodies["observation._admit_locked"]
    ordered(observe, "observation runtime reference is absent", "_prior_directory($workspace, 'workspace')",
            "_prior_targets_match($previous, \\@snapshots)")
    assert b"_source_closure($plan)" in bodies["observation._acquire_locked"]
    assert b"return $plan->{sealed} if exists($plan->{previous})" in bodies["observation._acquire_locked"]
    assert b"target_sources => [map" in bodies["observation._finish_locked"]
    assert b"$snapshot = $acquired->{target_sources}[$index]" in bodies["archive_record.archive_specification"]
    assert b"$evidence->{path}/retained-sources" in bodies["archive_record.archive_specification"]
    ordered(bodies["archive.archive_retained_sources"], "::archive_specification($case, $request, $acquired)",
            "_prior_directory($evidence, 'archive evidence')", "::_write_payload", "_source_closure($state)",
            "_close_sources($state->{sources})", "return $receipt")
    work = bodies["work.validate_work_settlement"]
    ordered(work, "_validate_selection", "_sealed($settlement->{selection_sealed})", "_complete_order", "_work_match", "_cleanup_settled")
    assert b"(?:completed|failed|cancelled)" in work
    assert b"leader_started" in bodies["cleanup._settled_owner"] and b"group_gone" in bodies["cleanup._settled_owner"]
    ordered(bodies["release._prepare"], "::validate_archive_receipt", "::validate_work_settlement", "::_directory", "_archive_closure")
    ordered(bodies["release._unlink_exact"], "unlink_attempted} = 1", 'unlink("$ROOT/$path")', "unlink_completed} = 1")
    ordered(bodies["release.release_observation_reference"], "_prepare($state", "::_transaction", "_close_owned($state->{owned})", "return {schema")
    assert b"released_reference => $path" in bodies["release._finish_locked"]
    assert b"release changed the retained canonical image" in bodies["release._finish_locked"]
    ordered(bodies["maintenance._admit_locked"], "_all_images", "selected maintenance image is absent", "_referenced($references, $key)")
    assert b"_same_image" in bodies["maintenance._closure_locked"]
    assert b"maintenance changed a retained image" in bodies["maintenance._finish_locked"]
    coordinator = bodies["coordinator._transaction"]
    assert b"only the inactive qualification namespace is admitted" in coordinator
    for family, calls in (
        ("retirement", ["_admit_locked", "_retire_locked", "_release_locked", "_finish_locked"]),
        ("maintenance", ["_admit_locked", "_closure_locked", "_remove_locked", "_finish_locked"]),
        ("release", ["_admit_locked", "_release_locked", "_finish_locked"])):
        module = {"retirement": "NativeProxyRuntimeRetirement", "maintenance": "NativeProxyImageMaintenance", "release": "NativeProxyObservationRelease"}[family]
        # Start at the actual branch body, after the earlier availability checks.
        operation = {"retirement": "retire_runtime_reference", "maintenance": "remove_unreferenced_image", "release": "release_observation_reference"}[family]
        branch = coordinator[coordinator.index(("        if ($operation eq '" + operation + "') {").encode()):]
        ordered(branch, *(module + "::" + call for call in calls))
    return True


def topological(profile):
    prerequisites = {event: set() for event in EVENTS}
    prerequisites["release_a"] = {"archive_a"}
    prerequisites["release_b"] = {"archive_b"}
    prerequisites["maintain_target"] = {"retire_target", "release_a", "release_b"}
    if profile == "same_image":
        prerequisites["maintain_target"].add("retire_other")
    else:
        assert profile == "different_image"
    rows = []
    def visit(prefix, remaining):
        if not remaining:
            rows.append(tuple(prefix))
            return
        completed = set(prefix)
        for event in sorted(remaining):
            if prerequisites[event] <= completed:
                visit(prefix + [event], remaining - {event})
    visit([], set(EVENTS))
    return rows


def verify(contract, plan):
    assert set(contract) == {"schema", "source_revision", "functions", "invariants", "schedules", "schedule_domain_sha256", "scope"}
    assert contract["schema"] == "fsmgen.inactive_lifetime_source_contract.v1"
    assert contract["source_revision"] == plan["source_revision"] and contract["scope"] == plan["scope"]
    expected_functions, bodies = [], {}
    for module in plan["modules"]:
        raw = (ROOT / module["path"]).read_bytes()
        spans = declarations(raw)
        for name in module["functions"]:
            start, end = spans[name]
            identity = module["id"] + "." + name
            expected_functions.append(dict(id=identity, path=module["path"], name=name, start=start, end=end, sha256=prepare.digest(raw[start:end])))
            bodies[identity] = raw[start:end]
    assert contract["functions"] == expected_functions
    assert contract["invariants"] == plan["invariants"]
    assert len({row["id"] for row in contract["invariants"]}) == len(contract["invariants"])
    assert {name for row in contract["invariants"] for name in row["functions"]} == set(bodies)
    assert source_rules(bodies)
    rows = contract["schedules"]
    expected = {(profile, order) for profile in ("same_image", "different_image") for order in topological(profile)}
    actual = {(row["profile"], tuple(row["order"])) for row in rows}
    assert len(rows) == len(actual) == len(expected) and actual == expected
    assert prepare.digest(prepare.canonical(rows)) == contract["schedule_domain_sha256"]
    counts = {profile: sum(row["profile"] == profile for row in rows) for profile in ("same_image", "different_image")}
    assert any(order.index("maintain_target") < order.index("retire_other") for profile, order in actual if profile == "different_image")
    for observer in ("a", "b"):
        assert any(order.index("archive_" + observer) < order.index("retire_target") for _, order in actual)
        assert any(order.index("retire_target") < order.index("archive_" + observer) for _, order in actual)
        assert any(order.index("release_" + observer) < order.index("retire_target") for _, order in actual)
    return dict(source_functions=len(bodies), source_invariants=len(contract["invariants"]), schedules_by_profile=counts,
                prospective_schedules=len(rows), schedule_domain_sha256=contract["schedule_domain_sha256"])


def main():
    plan = prepare.authenticate()
    pins = check_pins()
    contract = json.loads((HERE / "contracts.json").read_bytes())
    report = verify(contract, plan)
    controls = []
    for label, change in (
        ("missing_function", lambda v: v["functions"].pop()),
        ("changed_source_span", lambda v: v["functions"][0].update(start=0)),
        ("missing_invariant", lambda v: v["invariants"].pop()),
        ("missing_schedule", lambda v: v["schedules"].pop()),
        ("changed_domain_hash", lambda v: v.update(schedule_domain_sha256="0" * 64))):
        changed = copy.deepcopy(contract); change(changed)
        try:
            verify(changed, plan)
        except (AssertionError, KeyError, ValueError):
            controls.append(label)
        else:
            raise AssertionError("contract falsifier survived: " + label)
    for label, edge in (("ignore_target_runtime", ["retire_target", "maintain_target"]),
                        ("ignore_observation_b", ["release_b", "maintain_target"]),
                        ("release_before_archive", ["archive_a", "release_a"])):
        changed_plan = copy.deepcopy(plan); changed_plan["common_edges"].remove(edge)
        changed = copy.deepcopy(contract); changed["schedules"] = prepare.schedules(changed_plan)
        changed["schedule_domain_sha256"] = prepare.digest(prepare.canonical(changed["schedules"]))
        try:
            verify(changed, plan)
        except AssertionError:
            controls.append(label)
        else:
            raise AssertionError("weakened dependency survived")
    changed_plan = copy.deepcopy(plan)
    changed_plan["profiles"][1]["additional_edges"] = [["retire_other", "maintain_target"]]
    changed = copy.deepcopy(contract); changed["schedules"] = prepare.schedules(changed_plan)
    changed["schedule_domain_sha256"] = prepare.digest(prepare.canonical(changed["schedules"]))
    try:
        verify(changed, plan)
    except AssertionError:
        controls.append("unrelated_image_overconstrained")
    else:
        raise AssertionError("unrelated image owner incorrectly pins target")
    report.update(schema="fsmgen.inactive_lifetime_contract_audit.v1", source_revision=plan["source_revision"],
                  source_inputs=len(plan["inputs"]), prospective_pins=len(pins), falsifiers=controls,
                  runtime_qualification=False, scope=plan["scope"])
    if "--verify-saved" in sys.argv:
        assert report == json.loads((HERE / "result/audit.json").read_bytes())
    else:
        with (HERE / "result/audit.json").open("x") as stream:
            json.dump(report, stream, sort_keys=True, indent=2); stream.write("\n")
    print(json.dumps(report, sort_keys=True))


if __name__ == "__main__":
    main()
