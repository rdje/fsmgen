"""Retain genuine Boolean/float substitutions at the exact saved-proof boundary."""
from pathlib import Path

import rollover as r


if __name__ == '__main__':
    outcomes = {}
    programmes = {}
    for label, name in (('source', 'proof.json.gz'), ('delivery', 'delivered-proof.json.gz')):
        original = r.load(name)
        assert type(original['independent']['status']) is int and original['independent']['status'] == 0
        for kind, value in (('boolean', False), ('float', 0.0)):
            candidate = dict(original, independent=dict(original['independent'], status=value))
            assert candidate == original, 'original saved-proof equality aliases the changed primitive kind'
            assert not r.exact(candidate, original), 'strict saved-proof comparison must separate it'
            filename = 'kind-' + label + '-' + kind + '.json.gz'
            r.save(filename, candidate)
            outcomes[label + '-' + kind] = dict(original_equality=True, strict_equality=False,
                candidate=r.retained.pin(r.retained.local(r.BASE / filename).read_bytes()),
                scope='Actual saved-proof candidate and original comparison predicate; not a semantic/native cohort replay.')
        filename = 'rollover.py' if label == 'source' else 'delivery.py'
        programmes[filename] = dict(before=original['programme'], after=r.retained.local(r.BASE / filename).read_text())
    r.save('typed-proof-repair.json.gz', dict(outcomes=outcomes, programmes=programmes,
        programme=r.retained.local(r.BASE / 'strict_controls.py').read_text(),
        scope='Original first proofs/programmes retain unchanged. Exact canonical JSON separates status kind substitutions; '
              'this repairs saved metadata equality only, not any original semantic/native result.'))
    print('Original saved-proof primitive aliases reproduce; strict full JSON comparisons reject Boolean and float candidates.')
