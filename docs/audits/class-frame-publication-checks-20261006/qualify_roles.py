"""Execute distinct current/checkpoint roles and genuine unrelated-book progress."""
import ast
import hashlib
import json
import shlex
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-publication-20261006')
CHECKS = Path('docs/audits/class-frame-publication-checks-20261006')
# Keep only exact lightweight custody utilities resident while child readers run.
# The full native semantic namespace is loaded for the final current check,
# after every child is terminal. No child command or acceptance is narrowed.
UTILITY = Path('docs/audits/record-value-class-frame-admission-20261006/verify.py')
utility_tree = ast.parse(UTILITY.read_bytes())
function_names = {'require','same','identity','load','module','whole'}
functions = [n for n in utility_tree.body if isinstance(n,ast.FunctionDef) and n.name in function_names]
assert {n.name for n in functions} == function_names
exec(compile(ast.Module(body=functions,type_ignores=[]),str(UTILITY),'exec'),globals())

def constant(path,name):
    values = [n.value for n in ast.parse(path.read_bytes()).body if isinstance(n,ast.Assign)
        and any(isinstance(t,ast.Name) and t.id == name for t in n.targets)]
    require(len(values) == 1,'unique literal public role constant: ' + name)
    return ast.literal_eval(values[0])

model = module(BASE / 'model.py')
retention_path = Path('docs/audits/record-value-class-frame-retention-20261006')
ns = dict(PATHS=model['PATHS'],CORE=model['CORE'],TOOLING=model['TOOLING'],model=model,
    CHAPTER=Path('docs/book/src/13k-isf-feature-support-matrix.md'),RETENTION=retention_path,
    SUCCESS=constant(BASE / 'verify.py','SUCCESS'),CURRENT_SUCCESS=constant(BASE / 'verify.py','CURRENT_SUCCESS'),
    retention=dict(SUCCESS=constant(retention_path / 'verify.py','SUCCESS')),module=module,whole=whole,
    binding=lambda:load(BASE / 'binding.json'))
OUT = CHECKS / 'roles.json'
require(sys.argv[1:] in ([],['--resume'],['--resume-crash']),'closed fresh/resume role invocation')
crash_resume = sys.argv[1:] == ['--resume-crash']
resume = sys.argv[1:] in (['--resume'],['--resume-crash'])
require(OUT.exists() == resume,'fresh cannot overwrite and resume requires preserved prefix')
records = load(OUT)['records'] if resume else []
if resume:
    prefix = load(CHECKS / 'first-role-prefix.json')['records']
    if crash_resume:
        restored,crash_prefix = module(CHECKS / 'crash_recovery.py')['check']()
        require(same(records,crash_prefix['records']) and len(records) == 11
            and same(records[:6],prefix) and ns['CHAPTER'].read_bytes() == restored,
            'whole exact crash prefix and restored publication before suffix resume')
    else:
        require(same(records,prefix) and len(prefix) == 6,'whole exact completed original role prefix before resume')
    stopped = load(CHECKS / 'first-role-guard-result.json')
    require(type(stopped['status']) is int and stopped['status'] == 137
        and 'host memory 88.4% reached cutoff 88%' in stopped['stderr'],'actual terminal guard before suffix-only resume')

def execute(name,command,status,stdout=None,cause=None):
    if resume and any(r['name'] == name for r in records):
        require(sum(r['name'] == name for r in records) == 1,'unique completed role before suffix resume')
        row = next(r for r in records if r['name'] == name)
        require(type(row['status']) is int and row['status'] == status and row['command'] == command,'exact completed intended role before suffix resume')
        if stdout is not None: require(row['stdout'] == stdout,'whole completed role output before suffix resume')
        if cause is not None: require(row['stdout'] == '' and row['stderr'].endswith('ValueError: ' + cause + '\n'),'whole completed old-epoch refusal before suffix resume')
        return row
    instruments = {str(CHECKS / 'qualify_roles.py'):identity((CHECKS / 'qualify_roles.py').read_bytes())}
    for item in command:
        p = Path(item)
        if p.is_file() and (item.endswith('.py') or item == 'scripts/run_with_ram_guard.sh'):
            instruments[item] = identity(p.read_bytes())
    result = subprocess.run(command,capture_output=True)
    row = dict(name=name,command=command,status=result.returncode,stdout=result.stdout.decode(),stderr=result.stderr.decode(),instruments=instruments,
        cards={p:identity(Path(p).read_bytes()) for p in ns['PATHS']},chapter=identity(ns['CHAPTER'].read_bytes()))
    records.append(row); OUT.write_text(json.dumps(dict(records=records,role='Actual distinct current, saved checkpoint and original obligations; fresh finite probe is not original raw-error recapture.'),sort_keys=True,indent=2)+'\n')
    require(type(row['status']) is int and row['status'] == status,'actual intended role exit: ' + name + ': ' + row['stderr'])
    if stdout is not None: require(row['stdout'] == stdout,'whole actual intended role stdout: ' + name)
    if cause is not None: require(row['stdout'] == '' and row['stderr'].endswith('ValueError: ' + cause + '\n'),'actual intended old-epoch refusal: ' + name)
    print(name + ': actual status ' + str(status),flush=True)
    return row

if __name__ == '__main__':
    original = {root:ns['whole'](root) for root in map(Path,ns['binding']()['inputs'])}
    execute('new-default',['python3','-B',str(BASE / 'verify.py')],0,ns['SUCCESS'])
    execute('new-current',['python3','-B',str(BASE / 'verify.py'),'--current'],0,ns['CURRENT_SUCCESS'])
    execute('retention-default',['python3','-B',str(ns['RETENTION'] / 'verify.py')],0,ns['retention']['SUCCESS'])
    execute('retention-old-epoch',['python3','-B',str(ns['RETENTION'] / 'verify.py'),'--live-unchanged'],1,cause='whole unchanged live original source facts and decisions')
    tooling = Path('docs/audits/record-value-tooling-current-reader-20261006/verify.py'); old = dict(SUCCESS=constant(tooling,'SUCCESS'))
    execute('tooling-default',['python3','-B',str(tooling)],0,old['SUCCESS'])
    execute('tooling-old-epoch',['python3','-B',str(tooling),'--current'],1,cause='complete current core observer tooling facts questions identity and routes')
    core_commands = [shlex.split(c) for c in ns['model']['replay_value'](Path(ns['CORE']).read_text()).split(' && ')]
    require(len(core_commands) == 4 and core_commands[-1] == shlex.split(ns['model']['COMMAND']),'whole exact core original and current replay chain')
    for index,command in enumerate(core_commands): execute('core-obligation-' + str(index+1),command,0)
    locality = shlex.split(ns['model']['replay_value'](Path(ns['TOOLING']).read_text()).split(' && ')[0])
    execute('original-locality-obligation',locality,0)
    chapter = ns['CHAPTER']; before = chapter.read_bytes(); backup = CHECKS / 'unrelated-book-before.md.txt'
    if crash_resume:
        require(backup.exists() and backup.read_bytes() == before,'exact preserved unrelated progress chapter after crash')
    else:
        require(not backup.exists(),'unrelated progress must retain exact prior chapter'); backup.write_bytes(before)
    progress = b'\nTemporary unrelated book-progress control for the owned current-reader qualification.\n'
    require(progress not in before,'genuine unrelated book progress')
    try:
        chapter.write_bytes(before + progress)
        execute('unrelated-progress-current',['python3','-B',str(BASE / 'verify.py'),'--current'],0,ns['CURRENT_SUCCESS'])
        execute('unrelated-progress-default',['python3','-B',str(BASE / 'verify.py')],0,ns['SUCCESS'])
    finally:
        chapter.write_bytes(before)
        require(chapter.read_bytes() == before,'exact unrelated book progress restoration')
    require(all(same(ns['whole'](root),members) for root,members in original.items()),'every original source/semantic/native/programme/seal byte conserves after actual roles')
    final = module(BASE / 'verify.py'); final['check_current'](final['current_input']())
    print('PASS actual full current/checkpoint/original replay and unrelated-book progress roles with exact restoration; original raw/native captures retained.')
