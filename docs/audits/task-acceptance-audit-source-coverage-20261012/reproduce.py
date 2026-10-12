"""Retain a genuine single-path audit-source false green in the same Git repository."""
from pathlib import Path
import hashlib,json,os,subprocess
BASE=Path('docs/audits/task-acceptance-audit-source-coverage-20261012')
OWNER='TASK-ACCEPTANCE-AUDIT-SOURCE-COVERAGE.1'
PROGRAMMES=('scripts/check_task_acceptance.sh','doctrine/task_acceptance/change_paths.tsv','doctrine/task_acceptance/evidence_signatures.tsv',str(BASE/'reproduce.py'))
def pin(raw):return dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())
def epoch():return {name:dict(body=Path(name).read_text(),identity=pin(Path(name).read_bytes())) for name in PROGRAMMES}
record=dict(owner=OWNER,programmes=epoch(),commands=[])
def native(command,env=None,input=None):
 result=subprocess.run(command,capture_output=True,text=True,env=env,input=input)
 row=dict(command=command,status=result.returncode,stdout=result.stdout,stderr=result.stderr)
 if input is not None:row['input']=input
 record['commands'].append(row)
 return row
path=BASE/'first-source-only-native.json'
assert not path.exists()
index=Path('.artifacts/task-acceptance-audit-source-coverage-20261012/first.index')
index.parent.mkdir(parents=True,exist_ok=True);assert not index.exists()
main_index=Path(subprocess.check_output(['git','rev-parse','--git-path','index'],text=True).strip())
record['main_index_before']=pin(main_index.read_bytes())
env=os.environ.copy();env['GIT_INDEX_FILE']=str(index.resolve())
record['alternate_index']=str(index)
try:
 revision=native(['git','rev-parse','HEAD']);assert revision['status']==0
 record['revision']=revision['stdout'].strip()
 assert native(['git','read-tree','HEAD'],env)['status']==0
 blob=native(['git','hash-object','-w','--stdin'],env,input="print('owned audit fixture')\n");assert blob['status']==0
 candidate='docs/audits/_acceptance_source_probe/reader.py'
 assert native(['git','update-index','--add','--cacheinfo','100644,'+blob['stdout'].strip()+','+candidate],env)['status']==0
 paths=native(['git','diff','--cached','--name-only'],env);assert paths['status']==0 and paths['stdout']==candidate+'\n'
 record['index_before']=pin(index.read_bytes())
 actual=native(['scripts/run_with_ram_guard.sh','--','scripts/check_task_acceptance.sh'],env)
 actual['expected_status']=1
 record['index_after']=pin(index.read_bytes());record['main_index_after']=pin(main_index.read_bytes());record['programmes_after']=epoch()
 assert record['index_before']==record['index_after'] and record['main_index_before']==record['main_index_after'] and record['programmes']==record['programmes_after']
 assert type(actual['status']) is int and actual['status']==0 and actual['stdout']=='[task-acceptance] OK: no configured implementation change staged; checklist not required\n'
 record['outcome']='Confirmed native actual0/declared1 coverage false green; this is failed enforcement, not successful acceptance.'
 record['condition']='The unchanged checker and committed registry see exactly one added audit Python path, no task or co-staged registry change. Only an alternate index and blob objects in this same repository are written; no worktree source or other Git repository is created.'
finally:
 with path.open('x') as out:json.dump(record,out,sort_keys=True,separators=(',',':'));out.write('\n')
print('CONFIRMED first native actual0/declared1 audit-source-only exemption; complete native/source/index custody retained.',flush=True)
