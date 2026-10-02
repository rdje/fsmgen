import hashlib
import json
import shutil
import subprocess
from pathlib import Path

scratch = Path('.artifacts/conditional-origin-documents')
archive = Path('docs/audits/conditional-origin-documents-20261002')
archive.mkdir(exist_ok=False)
for name in ('current-bound','red-bound','first-draft'):
    shutil.copytree(scratch / name, archive / name)
for name in ('first.txt','corrected.txt','formatter-diagnostic.txt','formatter-cohort.txt',
    'current-bound.tap','current-bound-stderr.txt','current-bound-recipe.json',
    'red-bound.tap','red-bound-stderr.txt','red-bound-recipe.json','bound.txt',
    'focused.txt','docs.txt','book.txt','run_bound.py','verify.py','collect.py'):
    shutil.copy2(scratch / name, archive / name)
shutil.copy2('t/2046-isf-library-document-origin-authority.t',archive / 'test-final.t')
shutil.copy2('t/lib/FSM/Test/LibraryDocumentOriginAuthority.pm',archive / 'authority-final.pm')
shutil.copy2(scratch / 'red-lib/FSM/Test/NoDocumentComparison.pm',archive / 'NoDocumentComparison.pm')
normalization = {
    't/2046-isf-library-document-origin-authority.t':str(archive / 'test-final.t'),
    't/lib/FSM/Test/LibraryDocumentOriginAuthority.pm':str(archive / 'authority-final.pm'),
    str(scratch / 'red-lib/FSM/Test/NoDocumentComparison.pm'):str(archive / 'NoDocumentComparison.pm'),
    str(scratch / 'run_bound.py'):str(archive / 'run_bound.py'),
}
(archive / 'normalization.json').write_text(json.dumps(normalization,indent=2,sort_keys=True) + '\n')
paths = subprocess.check_output(['git','ls-files','bin','perl',
    't/2042-isf-procedure-cond-normalization.t','t/2043-isf-conditional-origin-parser.t',
    't/2044-isf-conditional-origin-source-authority.t','t/2045-isf-same-source-library-origins.t',
    't/lib/FSM/Test/ConditionalOriginParser.pm','t/lib/FSM/Test/ConditionalOriginAuthority.pm',
    't/lib/FSM/Test/SameSourceLibraryOriginParser.pm',
    'docs/audits/conditional-origin-parser-20261002','docs/audits/conditional-origin-authority-20261002',
    'docs/audits/conditional-origin-library-20261002']).decode().splitlines()
identities = {}
for path in paths:
    raw = Path(path).read_bytes()
    expected = subprocess.check_output(['git','show','de856cd10c74bc2114076a1d7913e7ca151ec11d:' + path])
    assert raw == expected,path
    identities[path] = {'sha256':hashlib.sha256(raw).hexdigest(),
        'git_blob':hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()}
(archive / 'originals.json').write_text(json.dumps(identities,indent=2,sort_keys=True) + '\n')
render = {}
for chapter, markers in {
    '13d-control-flow.html':['Separate private document-set qualification', 'Packages and ATL remain closed'],
    '13i-downstream-integration.html':['A separate private document-set authority', 'constructor references',
        'Document-set evidence'],
}.items():
    path = Path('docs/book/book') / chapter
    raw = path.read_bytes()
    text = raw.decode()
    for marker in markers: assert marker in text,(chapter,marker)
    shutil.copy2(path,archive / chapter)
    render[chapter] = {'sha256':hashlib.sha256(raw).hexdigest(),'markers':markers}
(archive / 'render.json').write_text(json.dumps(render,indent=2,sort_keys=True) + '\n')
(archive / 'scope.txt').write_text('''Owned SEM .60.4.3.3.5.2.1.5.2.2.2.2.1. Private independent complete
root/library document-set authority; canonical file resolution, actor construction,
export selection and actual cloning run unchanged. Complete 24-source predecessor
membership, same-source precedence, repeated external aliases and identical whole
actors with different original operations are retained. JSON reloads compare both
complete products against independently supplied original bytes. Bound PASS1/29;
actual consumer comparison bypass gives genuine RED1/29/Failed25. Twelve exact
mutations per source reject with submitted originals unchanged. Actor-local source
digests and exact alias-specific constructor references are qualified.

First green PASS1/28 emits undefined fixture serialization warnings. Tools root
these at normalized singleton formal tails; normalized ASTs are not a source
serializer. Preserve complete first products/test/provider/raw streams, then use
original restricted fixture tokens. Warning-free intermediate PASS1/29 precedes
the final bound test's selected-form and alias ordinary-product controls. Only
current-bound is final quantitative evidence. No production defect is inferred
from this fixture formatter. Actual canonical selected-form mutation refuses.

Independent verification reconstructs original full source partition and complete
actors/ledgers/catalogs/targets/call scopes/primitive kinds/graph membership from
the immutable independent predecessor source oracle, then checks every literal
mutation and consistent-digest twin. Five shared corruptions reject. Whole prior
proofs/providers and production authenticate unchanged without replay. Focused
PASS5/195 and docs PASS6/622 with 115 complete examples lowering; mdBook builds
and actual chapter text/canonical inclusion checks pass. No browser visual QA.

Original authoritative source bytes and relative labels persist in each saved
product. Test fixture files were generated only in repository-local temporary
directories and cleaned by their owning test. Bound recipes use repository-relative
argv/cwd/provider locations; normalization points only disposable caller copies
to their exact archive bytes. Guard PID/host readings are historical raw receipts.
Broader receipts describe actual terminal runs; they are not fabricated pre/post
bound products. No HDL/compiler/analyzer/simulation, spent replay, full CI/push,
production metadata adoption, public schema/grammar/admission widening or macro
runtime follows. Packages, ATL and formal/generated/domain propagation/adoption
remain separately owned and closed. Safe normalization/branch integration waits.
''')
print('PASS complete capture, actual rendered text, immutable originals and honest scope archived')
