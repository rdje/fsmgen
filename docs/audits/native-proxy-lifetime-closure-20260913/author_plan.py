"""Pin the complete selected lifetime evidence graph; no fixture operations."""
import hashlib
import json
from pathlib import Path
import subprocess

BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[2]
PHASES=[
    ('contracts','native-proxy-lifetime-contracts-20260913','result/audit.json'),
    ('model','native-proxy-lifetime-model-20260913','corrected-audit.json'),
    ('complete_admission','native-proxy-lifetime-files-admission-20260913','review.json'),
    ('complete_actual','native-proxy-lifetime-files-20260913','review.json'),
    ('matrix','native-proxy-lifetime-controls-admission-20260913','review.json'),
    ('harness','native-proxy-lifetime-control-harness-20260913','harness-review.json'),
    ('final_admission','native-proxy-lifetime-controls-final-admission-20260913','review.json'),
    ('controls_actual','native-proxy-lifetime-controls-20260913','review.json'),
]


def pin(relative, body=None):
    if body is None: body=(ROOT/relative).read_bytes()
    return dict(path=relative,size_bytes=len(body),sha256=hashlib.sha256(body).hexdigest())


def main():
    revision=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
    paths=set();phases=[]
    for name,folder,report in PHASES:
        relative='docs/audits/'+folder
        members=subprocess.check_output(['git','ls-tree','-r','--name-only',revision,'--',relative],cwd=ROOT,text=True).splitlines()
        assert members;paths.update(members)
        for filename in ('plan.json','harness-plan.json'):
            path=ROOT/relative/filename
            if path.exists():paths.update(row['path'] for row in json.loads(path.read_bytes()).get('inputs',[]))
        phases.append(dict(name=name,directory=relative,report=relative+'/'+report,members=members))
    actual=json.loads((ROOT/'docs/audits/native-proxy-lifetime-controls-20260913/capture-plan.json').read_bytes())
    owner=actual['owner'].rsplit('.',2)[0]+'.5'
    task='docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md'
    source=subprocess.check_output(['git','show',revision+':'+task],cwd=ROOT)
    parent=owner.rsplit('.',1)[0];custody_parent=parent.rsplit('.',1)[0]
    value=dict(schema='fsmgen.inactive_combined_lifetime_closure_plan.v1',owner=owner,
        source_revision=revision,phases=phases,inputs=[pin(path) for path in sorted(paths)],
        task_source=pin(task,source),parent=parent,custody_parent=custody_parent,
        author=pin((BASE/'author_plan.py').relative_to(ROOT).as_posix()),
        next_owner=custody_parent.rsplit('.',1)[0]+'.4',
        native_integration_owner=custody_parent.rsplit('.',1)[0]+'.5',
        scope='Serialized inactive lifetime applicability; selected isolated-file controls use synthetic process ownership.',
        missing_native_legs=['Native process authentication','Real compiler and returned-stage receipt transport',
            'Late-launch prevention','Live canonical-store/public integration','Historical startup and parent qualification; full CI/push'],
        toolchain_access='Installed Python, Perl, Git and standard modules are required read-only toolchain dependencies. Project-owned outputs are repository-derived on the repository volume; Python bytecode caches are disabled.')
    with (BASE/'plan.json').open('x') as stream:json.dump(value,stream,sort_keys=True,indent=2);stream.write('\n')
    print(json.dumps(dict(source_revision=revision,inputs=len(paths),input_bytes=sum(row['size_bytes'] for row in value['inputs']),fixture_operations=0),sort_keys=True))


if __name__=='__main__':main()
