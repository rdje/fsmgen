"""Declared source inputs and typed, complete finite cause-association products."""
import gzip
import json
from pathlib import Path
import re

from capture import BASE, pin, save

PLAN = json.loads((BASE / 'plan.json').read_bytes())
TASK = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
MODES = ('ordinary', 'storable', 'controls')
DOMAINS = ('api', 'copies', 'parses', 'test_run')
CAPTURE = 'docs/audits/record-value-original-candidate-20261004'
CONTEXT = 'docs/audits/record-value-original-contexts-20261005'
RAW = 'docs/audits/record-value-class-frame-join-20261006/raw-product.json'
INPUTS = {
    **{mode: CAPTURE + '/' + mode + '.json' for mode in MODES},
    'primary': PLAN['primary'] + '/proofs.json',
    'contexts': CONTEXT + '/proofs.json',
    'execution': CAPTURE + '/execution.json',
    'raw': RAW,
    'semantic': PLAN['semantic'] + '/candidate.json.gz',
    'preparation': PLAN['preparation'] + '/proof.json',
}
SCOPE = ('Complete finite independent original primary/raw cause association, including all empty API/parser/private/test-run members, '
         'own source/helper/parser membership, whole raw bodies and qualified coordinate/address and nested roles. '
         'Qualified original source products remain shared assumptions. Native acceptance truth is source-derived only for API/parser calls; '
         'private/test-run observations retain their prerequisite scope. Helpers select their first failed operation, without a separate raw-error domain. '
         'Original native class/provider/settings/flags/encoding/private framework/hidden arguments/CODE-CODE/cross-call/heap identities remain unmeasured. '
         'Canonical/cause-parent/consumer/alias/cold/permanent/host-native/visual/HIAL/full-CI/push remain separately owned.')


def need(condition, cause):
    if not condition:
        raise ValueError(cause)


def canonical(value):
    return (json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True, allow_nan=False) + '\n').encode()


def same(left, right):
    return canonical(left) == canonical(right)


def nodes(body):
    starts = list(re.finditer(rb'^- ID: `([^`]+)`\n', body, re.M))
    result = {row[1].decode(): body[row.start():starts[i + 1].start() if i + 1 < len(starts) else len(body)]
              for i, row in enumerate(starts)}
    need(len(result) == len(starts), 'unique complete cause task graph')
    return result


def field(block, name):
    match = re.search(rb'^  ' + name.encode() + rb': `(.*)`$', block, re.M)
    return match[1].decode() if match else None


def legacy_digest(value):
    return pin(json.dumps(value, sort_keys=True, separators=(',', ':')).encode())


def module(path):
    # Original finite model modules execute no main routine on import and make
    # no sibling sys.path/module-name mutations. They are qualified assumptions.
    namespace = {'__name__': 'qualified_original_cause_model'}
    exec(compile(Path(path).read_bytes(), str(path), 'exec'), namespace)
    return namespace


def inputs():
    source = json.loads((BASE / 'source-roles.json').read_bytes())['publication']['members']
    data, identities = {}, {}
    for role, name in INPUTS.items():
        raw = Path(name).read_bytes()
        identity = pin(raw)
        need(identity == {key: source[name][key] for key in ('bytes', 'sha256')},
             'whole fixed qualified source product: ' + role)
        data[role] = json.loads(gzip.decompress(raw) if name.endswith('.gz') else raw)
        identities[name] = identity
    return data, identities


def product(path):
    raw = gzip.decompress(Path(path).read_bytes())
    value = json.loads(raw)
    need(raw == canonical(value), 'whole canonical compressed cause product')
    return value


def save_product(name, value):
    path = BASE / name
    need(not path.exists() and path.parent == BASE, 'retain first complete cause product')
    path.write_bytes(gzip.compress(canonical(value), mtime=0))


def boundary(data):
    return dict(scope=SCOPE, preparation=data['preparation']['unknowns'],
                raw=data['semantic']['original_unknowns'], semantic=data['semantic']['semantic_links']['original_unknowns'])
