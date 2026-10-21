"""Conserve complete compile-only role controls across a diagnostic-label correction."""
import argparse
import copy
import gzip
import json
import subprocess

import epoch_constraints as epoch
import execute
import prepare
import qualify_compile_only_role_records as checker

BASE = 'e99bd09bb7ab493210bf981b29ef3e0ac5a1c024'
SELF = str(execute.AUDIT / 'verify_compile_only_role_label.py')
TARGET = str(execute.AUDIT / checker.SELF)
PRIOR = str(execute.AUDIT / 'compile-only-role-record-controls.json.gz')
OUTPUT = execute.AUDIT / 'compile-only-role-label-conservation-qualified.json.gz'
LINE = ('Complete compile-only role records reject genuine source/member/primitive/'
        'proof candidates; every existing function body is conserved.\n')
SCOPE = ('Exact current/native source and full role-control product conservation '
         'outside only the unexpected-admission label and exclusive output literal. '
         'The original proof is immutable. Actual saved CLI replay and a controlled '
         'in-process reviewer shim exercise the diagnostic branch; the shim accepts '
         'only the borrowed-target candidate to force the checker refusal. No '
         'historical/candidate source, original model/recipe/cohort or helper runs; '
         'all original source/runtime/private/HIAL/full-CI scopes retain.')


def equal(left, right):
    return checker.model.bounded.strict_equal(left, right)


def core():
    before = epoch.read(BASE, TARGET)
    after = execute.read(TARGET)
    old = b'changed preparation role record admitted: '
    new = b'changed compile-only role record admitted: '
    old_path = b'compile-only-role-record-controls.json.gz'
    new_path = b'compile-only-role-record-controls-label-corrected.json.gz'
    assert before.count(old) == before.count(old_path) == 1
    equal(after, before.replace(old,new,1).replace(old_path,new_path,1))
    original_raw = epoch.read(BASE, PRIOR)
    equal(execute.read(PRIOR), original_raw)
    current_raw = execute.read(checker.PATH)
    original, current = (json.loads(gzip.decompress(raw)) for raw in (original_raw,current_raw))
    equal(original['programmes'][checker.SELF], prepare.blob(before))
    equal(current['programmes'][checker.SELF], prepare.blob(after))
    projected = copy.deepcopy(current)
    projected['programmes'][checker.SELF] = original['programmes'][checker.SELF]
    equal(projected, original)
    assert prepare.encoded(projected) == prepare.encoded(original)
    return dict(schema='fsmgen.compile_only_role_label_conservation.v1', scope=SCOPE,
        revision=BASE, programme=prepare.blob(execute.read(SELF)),
        sources=dict(before=prepare.blob(before),after=prepare.blob(after)),
        original=dict(path=PRIOR,body=prepare.blob(original_raw)),
        corrected=dict(path=str(checker.PATH),body=prepare.blob(current_raw)),
        conserved_product=prepare.identity(prepare.encoded(original)))


def branch():
    review = checker.Qualification.review
    seen = []
    def allow_borrowed(self, value):
        if value.get('reader') == 'qualify_caller_modules.py':
            seen.append(value['reader'])
            return None
        return review(self,value)
    try:
        checker.Qualification.review = allow_borrowed
        try:
            checker.derive()
        except AssertionError as error:
            equal(str(error),'changed compile-only role record admitted: borrowed-target')
            equal(seen,['qualify_caller_modules.py'])
            return dict(in_process=True,simulated_candidate_acceptance=True,
                        candidate_reader=seen[0],refusal=str(error))
        else:
            raise AssertionError('unexpected-admission diagnostic branch did not refuse')
    finally:
        checker.Qualification.review = review


def derive(actual=None):
    value = core()
    value['diagnostic_branch'] = branch()
    if actual is None:
        result = subprocess.run(['python3','-B',TARGET],cwd=prepare.ROOT,
            stdin=subprocess.DEVNULL,capture_output=True)
        actual = dict(command=['python3','-B',TARGET],status=result.returncode,
                      stdout=prepare.blob(result.stdout),stderr=prepare.blob(result.stderr))
    equal(actual,dict(command=['python3','-B',TARGET],status=0,
                      stdout=prepare.blob(LINE.encode()),stderr=prepare.blob(b'')))
    equal(core(),{key:item for key,item in value.items() if key!='diagnostic_branch'})
    value['actual'] = actual
    return value


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write',action='store_true')
    args = parser.parse_args()
    if args.write:
        value = derive()
        execute.save(OUTPUT,value)
    else:
        saved = json.loads(gzip.decompress(execute.read(OUTPUT)))
        equal(saved,derive(saved['actual']))
    print('Exact diagnostic/output changes conserve the complete original compile-only role product; actual saved replay and controlled unexpected-admission label qualify without helper execution.')
