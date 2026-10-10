"""Lossless original guide content; concise duplicate pointer below warning."""
import copy
import json
from common import BASE, load, need, pin, same, save
import book


def main():
    guide=(BASE/'GUIDE.md').read_text(); pointer='See `gate-repair.json` for the exact containment repair.\n'
    need(guide.endswith(pointer) and guide[:-len(pointer)].split() == (BASE/'before-doctrine-GUIDE.md.txt').read_text().split(),'all original guide words preserved; only duplicated repair pointer shortened')
    measured=dict(files=1,bytes_each=len(guide.encode()),bytes_total=len(guide.encode()),lines_each=guide.count('\n'),lines_total=guide.count('\n'),line_bytes_each=max(map(len,guide.encode().splitlines())))
    first=load('publication-repaired.json'); report=copy.deepcopy(first)
    rows=[json.loads(x) for x in book.REGISTRY.read_bytes().splitlines()]
    need(same(rows,first['registry_after']),'whole prior repaired publication authority')
    own=next(r for r in rows if r.get('surface_id') == 'observer_predicate_values_guide')
    need(all(measured[k]/own['health_targets'][k] < .8 for k in measured if k != 'files'),'all fixed-file content dimensions below warning threshold')
    own['state']='normal'; report['registry_after']=rows
    save('publication-final-qualified.json',report)
    book.REGISTRY.write_text(''.join(json.dumps(r,sort_keys=True)+'\n' for r in rows))
    seal=load('manifest-qualified.json'); changed={}
    for name,identity in seal.items():
        current=pin((BASE/name).read_bytes())
        if current != identity:
            old=BASE/('before-guide-normal-'+name+'.txt')
            need(name in ('GUIDE.md','verify.py','publication_verify.py') and old.is_file() and pin(old.read_bytes()) == identity,'all first qualified-seal before-images retained')
            changed[name]=dict(before=identity,after=current,before_image=str(old))
    need(set(changed) == {'GUIDE.md','verify.py','publication_verify.py'},'closed guide-normal repair source membership')
    save('guide-normal.json',dict(metrics=measured,changed_sealed=changed,
        cause='A warning-debt record requires a positive recorded baseline. Lossless original-word reflow and a concise duplicated repair pointer place the new immutable guide below warning, with the original null baseline and fixed ceilings.',
        first_actual='checks.json:staged-doctrines-repaired',scope='No original word or fact removed; no ceiling, task contract or Knowledge Map allowance change.'))
    print('PASS complete original guide content preserved below every warning threshold; normal state, fixed ceilings and all first epochs retain.')


if __name__ == '__main__': main()
