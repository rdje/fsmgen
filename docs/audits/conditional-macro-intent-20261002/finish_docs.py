from pathlib import Path

p=Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')
s=p.read_text()
identifier='SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.1'
start=s.index('- ID: `'+identifier+'`')
end=s.index('\n- ID:',start+1)
node=s[start:end].replace('Status: `active`','Status: `done`').replace('Commit: `pending`','Commit: `this commit`')
vstart=node.index('  Verification: `')
vend=node.index('\n  Commit:',vstart)
node=node[:vstart]+('  Verification: `T2041 reports All tests successful, Files=1, Tests=44 for 43 actual complete sources. Thirteen first-action expansions refuse at the entry gate; two inline-proc cond sources retain cond and refuse; seven first sample macros admit with wrong activation topology, two authored entries and nineteen later/scheduled contexts admit. Independent desired-intent producer reports genuine terminal RED Files=1/Tests=7/Failed7. Full saved literal/source/private/native/API/newline/carrier verification passes, rejecting five shared corruptions despite parity. Owned parser pickaxe roots select/cond/bit/field/proc producers; pass ordering accounts for unexpanded inline cond. Full bin/perl census proves no production change; all predecessor evidence stays immutable. Initial focused band exposes stale scoped-formal T1390 regexes; exact structural oracle repair passes while the independently owned .32.1.3.3.1.3 local-controller defect remains open. Initial retry hits the unchanged host cutoff and is incomplete; isolated final macro cohort passes Files=6/Tests=28 and activation Files=1/Tests=22. Six docs checks pass Files=6/Tests=622 with all 115 complete fixtures lowering; syntax, book and actual rendered text/code/links pass without browser visual QA. Sealed docs/audits/conditional-macro-intent-20261002 retains all full products, source/code/recipes/history/raw receipts and honest failed drafts. Existing ISF/IAL1 repairs remain the scope: .5.4 inline cond normalization is next, then .5.2/.5.3 explicit intent/integration, before scalar/output prerequisites. No macro delivery, HDL invocation, spent replay or record-output widening.`')+node[vend:]
s=s[:start]+node+s[end:]
s=s.replace('- [ ] **ROOT CAUSE (WHY + WHERE)** — pending exact source/control-flow/history and public phase qualification.',
 '- [x] **ROOT CAUSE (WHY + WHERE)** — git log -S roots select at b6204f00bef9bf5b37cb4f1df661bfb528e48ff1, cond at 368c42812ff7849a7c6aff78b9a2bec527e58ae9 and proc calls at e680f9670257c6d6e9ad0c46d222e96697ea2304. The actual parser emits ordinary when lists without branch-intent association; first scheduled when selects activation. _expand_cond_loops scans transactions before procedure insertion, so actual first/later inline cond remains unexpanded and refuses. Complete real native/API/newline products confirm unsafe sample-macro admission and phase-specific action/proc refusals. T1390 expects unscoped formals although qualified physical names are emitted; retain this genuine FAIL and its separate local-controller witness.')
s=s.replace('- [ ] **ADDRESSED (verified)** — pending independent family-specific baseline and source-intent contract selection; production repair remains separate.',
 '- [x] **ADDRESSED (verified)** — Current T2041 reports All tests successful, Files=1, Tests=44. Complete fixed source/actor/private/lowered/public/carrier products qualify each family/context and original kinds. Independent desired-intent producer is genuine RED for seven unsafe sample entries; five shared product corruptions reject. P2 inline-cond normalization .5.4 is scheduled next, explicit source intent .5.2 and integration .5.3 follow. Small blocking T1390 structural oracle repair checks scoped bindings without a runtime claim; local-call execution stays owned by .32.1.3.3.1.3. Sealed full evidence and synchronized facts/book/integration/feedback establish diagnosis and repair boundaries, not completed macro delivery.')
s=s.replace('- [ ] **NO REGRESSION** — pending focused prior macro/activation/source-contract and documentation checks.',
 '- [x] **NO REGRESSION** — Final guarded macro cohort reports All tests successful, Files=6, Tests=28, and isolated T2040 Files=1, Tests=22. Six docs gates report All tests successful, Files=6, Tests=622 with 115 complete fixtures lowering; syntax and mdBook build pass. Actual rendered text/code/links and canonical includes pass without browser visual QA. Full bin/perl census proves production unchanged at baseline9bf0; immutable archives authenticate without replay. Independent saved verification, Knowledge Map regeneration, measured containment and claim reconciliation precede staged doctrines and normal hooks. The initial stale-oracle FAIL, unsupported guard option and host-memory cutoff are retained as non-success; recovery uses unchanged limits. No HDL execution, full CI/push, public output widening or broader macro signoff is inferred.')
marker='  Goal: `Implement and qualify the selected direct transaction controller contract.`'
start=s.index(marker)
end=s.index('\n- ID:',start)
block=s[start:end].replace('  Verification: `pending`',
 '  Verification: `Additional unchanged-source witness from macro qualification: T1390 hs_demo emits scoped inc_into bindings but main_sample_3 is unreachable and local control is disconnected. Complete actual carrier is retained in docs/audits/conditional-macro-intent-20261002/focused.tap, with exact baseline/current test sources. This is the existing execution defect, not closed by correcting the three stale structural regexes. Implement after the existing selected writer/scoped-identity prerequisites; require fresh HIAL admission before runtime.`')
s=s[:start]+block+s[end:]
p.write_text(s)

p=Path('MEMORY.md')
s=p.read_text().replace(identifier+'` (active)', 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.4` (pending)')
start=s.index('- next_action:')
end=s.index('- in_flight_background:',start)
s=s[:start]+('- next_action: From the committed macro qualification, repair inline procedure cond through the canonical parser normalization producer, preserving first-entry refusals and source scope. No HDL invocation or output widening.\n'
 '- in_flight_uncommitted: derive with `git status --short`; commit workflow owns any remaining .5.1 qualification changes before activating .5.4.\n')+s[end:]
p.write_text(s)

p=Path('docs/TASK_TREE.md')
s=p.read_text().replace('related macro qualification .5.2.1.5.1 is active, with inline-procedure cond normalization .5.4 next',
 'related macro qualification .5.2.1.5.1 is complete, with inline-procedure cond normalization .5.4 next')
p.write_text(s)

p=Path('docs/audits/conditional-macro-intent-20261002/scope.txt')
s=p.read_text()+'''\nInitial focused band terminates FAIL for three stale unscoped-formal regexes in
T1390. Correct only those structural witnesses to canonical scoped names; final
macro cohort passes Files=6/Tests=28, activation separately Files=1/Tests=22.
The hs_demo carrier's unreachable sample/local controller is independently
owned by .32.1.3.3.1.3 and still open; no working handshake call is inferred.
An unsupported --log guard-option attempt never launches a test; retain it.
A retry is stopped at host 89.0% by the unchanged 88% guard and is incomplete.
Isolated recovery keeps all resource limits. The saved-product inspection draft
mistakenly expects an interface key in private IR; preserve that failed read-only
recipe and corrected actual-key diagnosis. Final saved verification succeeds.
'''
p.write_text(s)
