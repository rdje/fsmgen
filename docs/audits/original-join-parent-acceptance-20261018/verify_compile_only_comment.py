"""Conserve the complete native admission across one projection-comment correction."""
import argparse
import ast
import copy
import gzip
import json
import subprocess

import epoch_constraints as epoch
import execute
import prepare
import verify_compile_only_route as admission

BASE = 'a7f34261372c6e0a3f0497cadeb5518be1e681a7'
SELF = str(execute.AUDIT / 'verify_compile_only_comment.py')
PRIOR = str(execute.AUDIT / 'compile-only-native-admission-qualified.json.gz')
PATH = execute.AUDIT / 'compile-only-comment-conservation-qualified.json.gz'
SCOPE = ('Exact native source and complete derived admission-product conservation. '
         'Only the projection comment and exclusive output path change; semantic '
         'function bodies and every other product field remain identical. The '
         'original proof stays immutable. Actual saved CLI replay is recorded; '
         'no whole helper, listed reader or historical programme executes. '
         'Original source/default/effect/runtime/private/HIAL/full-CI gaps remain.')
LINE = ('Native compile-only reader/proof admission conserves every prior epoch, '
        'helper protocol, published order and genuine control.\n')


def equal(left, right):
    return admission.route.frozen.equal(left, right)


def core():
    before = epoch.read(BASE, admission.SELF)
    current = execute.read(admission.SELF)
    comment = b'    # admitted AST addition and restoring its authenticated prior reader row.'
    corrected = b'    # admitted compile-only addition and restoring its authenticated prior reader row.'
    old_output = b"OUTPUT = route.AUDIT + 'compile-only-native-admission-qualified.json.gz'"
    new_output = b"OUTPUT = route.AUDIT + 'compile-only-native-admission-comment-corrected.json.gz'"
    assert before.count(comment) == before.count(old_output) == 1
    equal(current, before.replace(comment, corrected, 1).replace(old_output, new_output, 1))
    functions = []
    for raw in (before, current):
        tree = ast.parse(raw)
        functions.append({node.name: ast.dump(node, include_attributes=False)
                          for node in tree.body if isinstance(node, ast.FunctionDef)})
    equal(*functions)
    original_raw = epoch.read(BASE, PRIOR)
    equal(execute.read(PRIOR), original_raw)
    current_raw = execute.read(admission.OUTPUT)
    original = json.loads(gzip.decompress(original_raw))
    corrected_product = json.loads(gzip.decompress(current_raw))
    equal(original['programmes'][admission.SELF], prepare.blob(before))
    equal(corrected_product['programmes'][admission.SELF], prepare.blob(current))
    projected = copy.deepcopy(corrected_product)
    projected['programmes'][admission.SELF] = original['programmes'][admission.SELF]
    equal(projected, original)
    assert prepare.encoded(projected) == prepare.encoded(original)
    return dict(schema='fsmgen.compile_only_comment_conservation.v1', scope=SCOPE,
        native_revision=BASE, programme=prepare.blob(execute.read(SELF)),
        sources=dict(before=prepare.blob(before), current=prepare.blob(current)),
        original=dict(path=PRIOR, revision=BASE, body=prepare.blob(original_raw),
                      retention_contract='fsmgen_required_history'),
        corrected=dict(path=admission.OUTPUT, body=prepare.blob(current_raw)),
        semantic_functions=sorted(functions[0]),
        conserved_product=prepare.identity(prepare.encoded(original)))


def command():
    return ['python3', '-B', admission.SELF]


def collect():
    value = core()
    actual = subprocess.run(command(), cwd=prepare.ROOT, stdin=subprocess.DEVNULL,
                            capture_output=True)
    equal(core(), value)
    value['actual'] = dict(command=command(), status=actual.returncode,
                           stdout=prepare.blob(actual.stdout), stderr=prepare.blob(actual.stderr))
    return value


def review(value):
    assert set(value) == set(core()) | {'actual'}
    equal({key: item for key, item in value.items() if key != 'actual'}, core())
    equal(value['actual'], dict(command=command(), status=0,
                               stdout=prepare.blob(LINE.encode()), stderr=prepare.blob(b'')))
    return True


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = collect() if args.write else json.loads(gzip.decompress(execute.read(PATH)))
    assert review(value)
    if args.write:
        execute.save(PATH, value)
    print('Exact comment/output changes conserve all semantic functions and the whole original admission product; actual saved replay passes and the original proof remains unchanged.')
