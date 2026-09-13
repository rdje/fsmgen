"""Authenticate original source epochs and preserve the conditional reader seam."""
from collections import Counter
import hashlib
import sys

from common import BASE, ROOT, absent, copies, journal, load, module, physical, subset


def joined_epochs(prepare, catalog):
    epochs = []
    for index, name in enumerate(prepare.JOINS):
        directory = BASE.parent / name
        source = module(directory / 'prepare.py')
        plan = load(directory / 'plan.json')
        version = source.tree(source.REVISION)
        assert [row['path'] for row in plan['inputs']] == source.input_paths(version)
        assert plan['source_revision'] == source.REVISION
        assert plan['owner'] == source.OWNER
        for row in plan['inputs']:
            assert row == catalog[row['path']]
            assert version[row['path']]['oid'] == row['git_blob']
        if index == 0:
            names = ['prepare.py', 'prepare-pins.json', 'plan.json', 'audit.py']
            pins = load(directory / 'preflight-pins.json')
        elif index == 1:
            correction = module(directory / 'correction-preflight.py')
            correction.verify_saved()
            names = correction.MAIN_NAMES
            pins = load(directory / 'corrected-preflight-pins.json')
        else:
            names = module(directory / 'audit.py').MAIN_NAMES
            pins = load(directory / 'preflight-pins.json')
        assert pins == [prepare.pin(directory / name) for name in names]
        epochs.append(dict(directory=str(directory.relative_to(ROOT)), source_revision=source.REVISION,
            inputs=len(plan['inputs']), prospective_pins=pins, recovery=copies(directory, prepare)))
    return epochs


def original_contract(prepare, witnesses):
    release = BASE.parent / prepare.RELEASE
    original = module(release / 'audit.py')
    plan = load(release / 'plan.json')
    original.authenticate(plan)
    report = load(release / 'result/qualification.json')
    counts = original.verify(plan, report)
    saved = load(release / 'result/audit.json')
    subset(saved, counts)
    journal(release, report, report['allocated'])
    contract = BASE.parent / prepare.CONTRACT
    model = module(contract / 'audit.py')
    declared = load(contract / 'contract.json')
    model.authenticate(declared)
    symbolic = model.verify(declared, load(contract / 'result/qualification.json'))
    subset(load(contract / 'result/audit.json'), symbolic)
    projections = model.saved_join(declared)
    assert projections == load(contract / 'result/audit.json')['saved_join']
    boundary = BASE.parent / prepare.BOUNDARY
    observer = module(boundary / 'audit.py')
    boundary_plan = load(boundary / 'plan.json')
    observer.authenticate(boundary_plan)
    healthy = load(boundary / 'result/qualification.json')
    baseline_counts, selected = observer.verify(boundary_plan, healthy)
    subset(load(boundary / 'result/audit.json'), baseline_counts)
    journal(boundary, healthy, healthy['allocated'])
    support = module(BASE.parent / 'native-proxy-observation-archive-release-ordinary-before-20260911/audit.py')
    assertions = 0
    for path, expected in [(release, 1 + 8 * len(plan['cases'])), (boundary, 65)]:
        support.tap(path / 'result/qualify.tap', expected)
        assert (path / 'result/qualify.exit').read_bytes() == b'0\n'
        assertions += expected
    physical_counts = Counter()
    for row in report['cases'] + healthy['cases']:
        physical_counts.update(physical(row))
    assert physical_counts['reported_close_failures'] == sum(row['operation']['modeled_close_hits'] for row in report['cases'])
    witnesses['healthy'] = healthy['cases'][0]
    return dict(original_release=counts, symbolic=symbolic, projections=projections,
        baseline=baseline_counts, baseline_domain=selected, assertions=assertions,
        physical=dict(physical_counts), recovery={path.name: copies(path, prepare) for path in (release, contract, boundary)}), report['allocated'] + healthy['allocated']


def lower_reader(prepare):
    directory = BASE.parent / prepare.LOWER
    sys.path.insert(0, str(directory))
    joined = module(directory / 'audit.py')
    plan = load(directory / 'plan.json')
    joined.domain(plan)
    saved = load(directory / 'result/audit.json')
    texts = [prepare.safe_bytes(ROOT / path).decode() for path in
        (joined.READER, joined.CUSTODY, joined.PUBLICATION, joined.ARCHIVE,
         joined.BOUNDARY + '/ArchiveTrace.pm', plan['matrices'][0]['source'] + '/qualify.t')]
    joined.source_contract(texts)
    bodies = []
    for path, name in [(joined.READER, '_read_file'), (joined.CUSTODY, '_source'), (joined.PUBLICATION, '_write_payload')]:
        historical = joined.I.historical(joined.HANDOFF_REVISION, path).decode()
        body = joined.body(prepare.safe_bytes(ROOT / path).decode(), name)
        assert body == joined.body(historical, name)
        bodies.append(dict(path=path, function=name, source_epoch=joined.HANDOFF_REVISION,
            size_bytes=len(body.encode()), sha256=hashlib.sha256(body.encode()).hexdigest()))
    assert bodies == saved['exact_handoff_function_bodies']
    counts, roots, source_proofs = {}, [], []
    for index, label in [(5, 'observer'), (6, 'failures')]:
        matrix = plan['matrices'][index]
        path = ROOT / matrix['source']
        oracle = module(path / 'audit.py')
        child, report = load(path / 'plan.json'), load(path / 'result/qualification.json')
        oracle.domain(child)
        values = oracle.verify(child, report)
        assert values == saved['child_counts'][label]
        journal(path, report, report['allocated'])
        roots.extend(report['allocated'])
        copies(path, prepare)
        source_args = [texts[0], prepare.safe_bytes(ROOT / plan['matrices'][5]['source'] / 'LowerReaderTrace.pm').decode()]
        if label == 'failures':
            source_args.append(prepare.safe_bytes(path / 'LowerReadControls.pm').decode())
        oracle.source_proof(*source_args)
        source_proofs.append(label)
        count = joined.tap((path / 'result/qualify.tap').read_text())
        assert count == load(path / 'result/audit.json')['tap_assertions']
        counts[label] = dict(values, assertions=count)
    baseline = load(ROOT / joined.BOUNDARY / 'result/qualification.json')
    selections, caller_counts = {}, Counter()
    for matrix in plan['matrices'][1:5]:
        path = ROOT / matrix['source']
        oracle = module(path / 'audit.py')
        child, report = load(path / 'plan.json'), load(path / 'result/qualification.json')
        domain = oracle.domain(child, baseline)
        healthy = domain[0] if child['route'] == 'existing' else domain
        selected, values, allocated = joined.select_archive(child, report, healthy)
        selections[matrix['name']] = selected
        caller_counts.update(values)
        roots.extend(allocated)
    assert selections == saved['selections'] and dict(caller_counts) == saved['selected_archive_counts']
    absent(roots)
    assert len(roots) == saved['selected_archive_and_direct_roots']
    return dict(direct=counts, caller_cleanup=dict(caller_counts), body_applicability=bodies,
        source_proofs=source_proofs, roots_absent=len(roots), recovery=copies(directory, prepare),
        scope='Conditional callee closure and selected archive caller unwind only; no every-release-site execution or reachability claim.'), roots


def retained_failures(prepare, catalog):
    """Keep failed first evidence visible; never relabel its outcome as green."""
    exits = []
    for path in catalog:
        if path.endswith('.exit'):
            raw = prepare.safe_bytes(ROOT / path)
            if raw.strip().isdigit() and int(raw) != 0:
                exits.append(dict(path=path, exit_code=int(raw), **{key: catalog[path][key] for key in ('sha256', 'size_bytes')}))
    for name in (prepare.RELEASE, prepare.CONTRACT):
        required = 'docs/audits/' + name + '/result/first-audit/audit.exit'
        assert any(row['path'] == required for row in exits)
    correction = load(BASE.parent / prepare.JOINS[1] / 'first-failure/review.json')
    for record in correction['outputs']:
        raw = bytes.fromhex(record['raw_hex'])
        assert hashlib.sha256(raw).hexdigest() == record['sha256'] and len(raw) == record['size_bytes']
    assert any(row['path'].endswith('/join.exit') and int(bytes.fromhex(row['raw_hex'])) != 0 for row in correction['outputs'])
    return dict(nonzero_saved_exits=exits, close_join_first_failure=correction,
        scope='Raw original failure evidence is authenticated; corrections have distinct pins. Old main routines are not executed.')
