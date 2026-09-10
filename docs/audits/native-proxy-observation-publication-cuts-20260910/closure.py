"""Read-only regression evidence join for unchanged inactive prototypes."""
from __future__ import annotations

import hashlib
import json

from audit import BASE, ROOT, LOG, PLAN, SNAPSHOT, FRESH, module, equal, validate


def main() -> None:
    current=json.loads((LOG/'qualification.json').read_bytes())
    validate(current,PLAN.build())
    pins=json.loads((LOG/'preflight-pins.json').read_bytes())
    for pin in pins:
        raw=(ROOT/pin['path']).read_bytes()
        assert len(raw)==pin['bytes'] and hashlib.sha256(raw).hexdigest()==pin['sha256']
    predecessor=json.loads((SNAPSHOT.BASE/'review.json').read_bytes())
    for pin in predecessor['unchanged_inputs']:
        raw=(ROOT/pin['path']).read_bytes()
        assert len(raw)==pin['size_bytes'] and hashlib.sha256(raw).hexdigest()==pin['sha256']
    # Authenticate every archived predecessor receipt before re-deriving it.
    # Do not execute a predecessor harness or rewrite its ignored live results.
    copies=json.loads((SNAPSHOT.BASE/'result/recovery-copies.json').read_bytes())
    for entry in copies['files']:
        raw=(ROOT/entry['destination']).read_bytes()
        assert len(raw)==entry['size_bytes'] and hashlib.sha256(raw).hexdigest()==entry['sha256']
    SNAPSHOT.LOG=SNAPSHOT.BASE/'result'
    prior=json.loads((SNAPSHOT.LOG/'qualification.json').read_bytes())
    SNAPSHOT.validate(prior,SNAPSHOT.PLAN.build())
    assert FRESH.RUNTIME.tap_count((SNAPSHOT.LOG/'qualify.tap').read_text())==345
    paths=[row['path'] for result in (current,prior) for row in result['allocated']]
    regressions={}
    for short,directory,count in [('fresh','native-proxy-observation-acquisition-20260910',59),
                                  ('reuse','native-proxy-observation-reuse-20260910',81)]:
        oracle=module('publication_prior_'+short,BASE.parent/directory/'audit.py')
        oracle.LOG=SNAPSHOT.LOG/(short+'-regression')
        result=json.loads((oracle.LOG/'qualification.json').read_bytes())
        oracle.validate(result,json.loads((oracle.BASE/'plan.json').read_bytes()))
        assert FRESH.RUNTIME.tap_count((oracle.LOG/'qualify.tap').read_text())==count
        paths.extend(row['path'] for row in result['allocated'])
        regressions[short]=dict(archived_assertions=count,allocations=len(result['allocated']),executed=False)
    assert len(paths)==len(set(paths))
    assert all(not (ROOT/path).exists() and not (ROOT/path).is_symlink() for path in paths)
    report=dict(schema='fsmgen.inactive_observation_publication_cuts_closure.v1',success=True,
        current_assertions=41,current_allocations=len(current['allocated']),
        snapshot=dict(archived_assertions=345,allocations=len(prior['allocated']),executed=False),
        regressions=regressions,prospective_inputs_unchanged=len(pins),predecessor_inputs_unchanged=len(predecessor['unchanged_inputs']),
        authenticated_predecessor_copies=len(copies['files']),total_roots=len(paths),all_rosters_disjoint_and_absent=True,
        limits='Predecessor matrices are authenticated and independently rederived from their committed receipts, not rerun. Current healthy fresh/reuse paths and publication faults ran in this leaf; no product/prototype changed. Coordinator and final closure remain unqualified.')
    (LOG/'closure.json').write_text(json.dumps(report,sort_keys=True,indent=2)+'\n')
    print(json.dumps(report,sort_keys=True))


if __name__=='__main__':
    main()
