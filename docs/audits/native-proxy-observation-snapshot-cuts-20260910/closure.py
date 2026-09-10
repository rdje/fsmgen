"""Join current snapshot evidence with unchanged acquisition regressions."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from audit import BASE, ROOT, LOG, FRESH, PLAN, equal, module, validate


def main() -> None:
    primary = json.loads((LOG/'qualification.json').read_bytes())
    validate(primary,PLAN.build())
    paths = [entry['path'] for entry in primary['allocated']]
    regressions = {}
    for short,directory,count in [('fresh','native-proxy-observation-acquisition-20260910',59),
                                  ('reuse','native-proxy-observation-reuse-20260910',81)]:
        oracle = module('snapshot_'+short+'_regression',BASE.parent/directory/'audit.py')
        oracle.LOG = LOG/(short+'-regression')
        result = json.loads((oracle.LOG/'qualification.json').read_bytes())
        oracle.validate(result,json.loads((oracle.BASE/'plan.json').read_bytes()))
        assert FRESH.RUNTIME.tap_count((oracle.LOG/'qualify.tap').read_text()) == count
        equal(json.loads((oracle.LOG/'execution.json').read_bytes()),dict(exit_code=0))
        paths.extend(entry['path'] for entry in result['allocated'])
        regressions[short] = dict(assertions=count,allocations=len(result['allocated']))
    assert len(paths) == len(set(paths))
    assert all(not (ROOT/path).exists() and not (ROOT/path).is_symlink() for path in paths)
    pins = json.loads((LOG/'preflight-pins.json').read_bytes())
    for pin in pins:
        raw = (ROOT/pin['path']).read_bytes()
        assert len(raw) == pin['bytes'] and hashlib.sha256(raw).hexdigest() == pin['sha256']
    restoration = json.loads((LOG/'regression-restoration.json').read_bytes())
    assert restoration['all_byte_exact'] is True and len(restoration['restored']) == 4
    for entry in restoration['restored']:
        path = ROOT/entry['path']
        raw = path.read_bytes()
        assert len(raw) == entry['bytes'] and hashlib.sha256(raw).hexdigest() == entry['sha256']
        assert path.stat().st_mode & 0o7777 == entry['mode']
        canonical = ROOT/'docs/audits'/path.parent.name/'result'/path.name
        assert raw == canonical.read_bytes()
    complete = [row for row in primary['cases'] if row['id'].endswith(':complete')]
    counts = {row['route']:{kind:sum(h['kind']==kind for h in row['handles'])
        for kind in ('source','lock','writer')} for row in complete}
    equal(counts,dict(fresh=dict(source=83,lock=1,writer=1),reuse=dict(source=89,lock=1,writer=0)))
    report = dict(schema='fsmgen.inactive_observation_snapshot_cut_closure.v1',success=True,
        regressions=regressions,complete_route_handles=counts,unchanged_prospective_inputs=len(pins),
        restored_prior_outputs=4,all_rosters_disjoint_and_absent=True,total_allocations=len(paths),
        limits='Independent inert snapshot and focused regression closure only; no publication/coordinator matrix, archive settlement, native ownership or product activation.')
    (LOG/'closure.json').write_text(json.dumps(report,sort_keys=True,indent=2)+'\n')
    print(json.dumps(report,sort_keys=True))


if __name__ == '__main__':
    main()
