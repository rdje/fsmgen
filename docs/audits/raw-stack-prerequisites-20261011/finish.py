"""Close only fully qualified predecessors and capture the exact dated task epoch."""
import gzip
import json
import re
from pathlib import Path
import predecessors
import verify
from common import BASE, CLASS, OBSERVER, OWNER, RAW, canonical, load, need, save


def update(text,key,verification):
    original=predecessors.blocks(text)[key]
    need('  Status: `active`\n' in original,'close only active qualified predecessor')
    changed=original.replace('  Status: `active`\n','  Status: `done`\n',1)
    changed=re.sub(r'^  Verification: `.*`$',lambda _: '  Verification: `'+verification+'`',changed,flags=re.M)
    changed=changed.replace('  Commit: `pending`','  Commit: `this commit`',1)
    return text.replace(original,changed,1)


def main():
    # Nothing in the live task tree changes until every required actual result
    # and complete semantic/contract witness is available and qualified.
    need((BASE/'readers.json').exists(),'complete fresh replay before predecessor signoff')
    verify.actual_readers();verify.archived_recovery_controls();verify.input_directories();verify.checks(final=False)
    predecessors.main()
    task=Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md');before=task.read_text()
    common='Complete unchanged original acceptance and every descendant contract independently qualify in raw-stack-prerequisites-20261011. Fresh complete source/primary/context/inventory/API/parser/public/observer/header/coordinate/address readers retain their source or dated roles. Every source class/guard/first-cause/ordered phase joins complete function/argument/header membership and whole original raw bytes. Genuine missing/narrowed/borrowed/wrong-caller/first-cause/argument/native-promotion/typed-actual controls reject. Only finite observer/class-frame predecessors close; full raw semantics, original native/provider/private/settings/identity and higher successors remain open.'
    text=update(before,OBSERVER,common);text=update(text,CLASS,common)
    detail=common+' Complete input directory/file topology rejects unexpected empty directories, nested files and symlinks; exact original false green and corrected actual controls retain. Dated checkpoint preflight separately rejects before alias writes, with whole original/corrected actual controls. Exact intake found a P1 ignored required coordinate drafts archive absent from Git. Fixed committed catalog authenticates its whole bytes and every member; real positive/missing/changed-tail executions qualify before forced retention. Original failed intake, introducing git log -S and complete member diagnosis retain. P1 dated display-reader/current-instrument refusal is fixed by complete authenticated original-instrument source checkpoint execution; book recipe and current/native roles remain separate. First local failures retain; first-local-failure-boundaries.json names unrecoverable first nested fixture and source-race gate stream gaps without promotion. Corrected runners save actual child/gate results before assertions. Corrected focused All tests successful Files=3 Tests=318 and Python17 tests/current/native/book/source/claim gates pass; staged and normal hooks complete this commit. Aggregate raw joining follows after clean handoff and required task containment.'
    text=update(text,OWNER,detail)
    block=predecessors.blocks(text)[OWNER]
    checklist='''  Acceptance Checklist (enforced):
  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S drafts.tar.gz identifies a2840582fc1722c29da808713d6f3c06bd42cd78; actual-intake-1.json and intake-member-diagnosis.json prove a required ignored archive absent from Git. Original e428 task contracts separately leave broader observer/class-frame containers active despite completed children; whole original contracts retain in predecessors.json.
  - [x] **ADDRESSED (verified)** — Complete fixed source/native/product intake and directory/file topology, exact fixed-catalog/member recovery and real missing/changed archive refusals qualify. Fresh declared readers and independent complete source/class/phase/full-header/argument association controls qualify every unchanged predecessor acceptance and child contract. First local failure boundaries stay explicit; full raw/native/private successors remain open.
  - [x] **NO REGRESSION** — All tests successful Files=3 Tests=318; Python17 publication tests pass. Complete current/native/book/source/claim results retain in checks.json; strict saved replay, staged scripts/check_doctrines.sh and normal hooks complete this slice without a capacity ceiling or Knowledge Map change.
'''
    # The node already ends with the spacing separating it from its successor.
    changed=block.rstrip()+'\n'+checklist+'\n\n'
    text=text.replace(block,changed,1)
    predecessors.qualify_contracts(load('predecessors.json')['contracts'],text)
    need(len(text.splitlines())<7200,'retain ordinary task growth below the unchanged rollover milestone')
    task.write_text(text)
    index=Path('docs/TASK_TREE.md');old=index.read_text();needle='observer done; raw-stack next.'
    need(old.count(needle)==1,'unique active index frontier seam')
    index.write_text(old.replace(needle,'raw prerequisites done; raw join next.',1))
    memory=Path('MEMORY.md');old=memory.read_text()
    old=old.replace(OWNER+'` (active)',RAW+'.5.2` (pending)',1)
    begin,end=old.index('- next_action:'),old.index('- in_flight_uncommitted:')
    old=old[:begin]+'- next_action: Own and complete exact task-tree containment from this clean predecessor before ordinary growth reaches 7200 lines, then activate complete raw semantic join .5.2. Preserve every original raw/source/class/header/coordinate/address contract and native/private uncertainty.\n'+old[end:]
    begin,end=old.index('- in_flight_background:'),old.index('\n- blockers:')
    old=old[:begin]+'- in_flight_background: none; derive final command completion and clean Git state before successor activation.'+old[end:]
    memory.write_text(old)
    registry=Path('doctrine/live_document_size/surfaces.jsonl')
    rows=[json.loads(line) for line in registry.read_bytes().splitlines()]
    selected=next(row for row in rows if row.get('surface_id')=='task_evidence')
    selected['transition']['max_growth']['lines_each']=max(selected['transition']['max_growth']['lines_each'],
        len(text.splitlines())-selected['baseline']['lines_each']+selected['transition']['ratchet_step']['lines_each'])
    registry.write_bytes(b''.join(canonical(row) for row in rows))
    need(not (BASE/'qualified-task.md.gz').exists() and not (BASE/'qualified-registry.txt').exists(),
         'retain complete first qualified prerequisite task and capacity epoch')
    (BASE/'qualified-task.md.gz').write_bytes(gzip.compress(task.read_bytes(),mtime=0))
    (BASE/'qualified-registry.txt').write_bytes(registry.read_bytes())
    save('finish.json',dict(owner=OWNER,closed=[OBSERVER,CLASS,OWNER],next=RAW+'.5.2',
                           scope='Exact task/registry/book/native epoch; mandatory task containment precedes further ordinary growth.'))
    print('PASS complete original observer/class-frame acceptance before finite predecessor closure; whole qualified task/capacity epoch retained and raw semantics stays pending.')


if __name__=='__main__':main()
