from pathlib import Path

p=Path('docs/SPECFORGE_FEEDBACK_RESPONSE.md')
s=p.read_text()
old='''  unexpanded `cond` in inline procedures; those repairs are owned, with procedure
  normalization scheduled next. Use explicit activation before conditional
  shorthand and keep `cond` at the procedure call site for now. No new macro
'''
new='''  unexpanded `cond` in inline procedures. The normalization candidate would
  newly admit a first sample-only procedure `cond` as activation, so production
  stays unchanged and that source stays refused. Explicit source intent (`.5.2`)
  now precedes safe procedure normalization (`.5.4.2`) and branch integration
  (`.5.3`). [Safety qualification](audits/procedure-cond-normalization-20261002/scope.txt)
  retains the complete actual candidate admission and restored refusal.
  Use explicit activation before conditional shorthand and keep `cond` at the
  procedure call site for now. No new macro
'''
assert old in s
p.write_text(s.replace(old,new))

p=Path('docs/isf-spec/11-downstream-actor-transactions.md')
s=p.read_text()
old='''refuses even after activation. Its normalization repair is scheduled before
explicit macro source intent and production read integration. This qualification
adds no macro language/framework or record-output routes.
'''
new='''refuses even after activation. A normalization candidate newly admitted a first
sample-only procedure `cond` as activation instead of branching; the committed
parser is restored and that source stays refused. Explicit macro source intent
must qualify before safe procedure normalization and branch integration, then
production read integration. This safety qualification adds no macro
language/framework or record-output routes.
Procedure safety evidence: `docs/audits/procedure-cond-normalization-20261002/scope.txt`.
'''
assert old in s
p.write_text(s.replace(old,new))

p=Path('docs/book/src/13l-procedures.md')
s=p.read_text()
old='''until the repair qualifies. Other first-operation conditional shorthand can
also select entry activation; use an explicit `(on start)` before it. An
'''
new='''until the repair qualifies. Standalone normalization would newly admit a first
sample-only procedure `cond` as activation rather than an ordinary branch, so
the explicit source-intent prerequisite must qualify before integration.
[Procedure safety qualification](../../../docs/audits/procedure-cond-normalization-20261002/scope.txt)
retains that candidate and the restored current refusal. Other first-operation
conditional shorthand can also select entry activation; use an explicit `(on start)` before it. An
'''
assert old in s
p.write_text(s.replace(old,new))

p=Path('docs/book/src/13d-control-flow.md')
s=p.read_text()
needle='An inline procedure body containing `cond` currently retains an unexpanded'
assert needle in s
start=s.index(needle)
end=s.index('\n\n',start)
s=s[:end]+''' A normalization candidate would newly admit a first
sample-only procedure `cond` as an activation gate; it is not integrated.
Explicit source intent must qualify first, with production keeping this source
refused.''' +s[end:]
p.write_text(s)

p=Path('docs/TASK_TREE.md')
s=p.read_text()
old='with inline-procedure cond normalization .5.4 next before explicit source-intent propagation and integration'
new='with inline-procedure cond safety qualification .5.4.1 active; explicit source intent .5.2 precedes safe normalization .5.4.2 and branch integration'
assert old in s
p.write_text(s.replace(old,new))

p=Path('docs/knowledge/isf-conditional-macro-source-intent.md')
s=p.read_text()
s=s.replace('  t/2041-isf-conditional-macro-intent-qualification.t;',
 '''  docs/audits/procedure-cond-normalization-20261002/scope.txt;
  docs/audits/procedure-cond-normalization-20261002/verify.py;
  t/2041-isf-conditional-macro-intent-qualification.t;
  t/2042-isf-procedure-cond-normalization.t;''')
old='''normalization qualifies. SEM `.60.4.3.3.5.2.1.5.4` owns that P2 repair next,
before `.5.2` explicit source intent and `.5.3` integration; scalar literal and
record-output read/write prerequisites follow separately.
'''
new='''normalization qualifies. SEM `.60.4.3.3.5.2.1.5.4.1` demonstrates why a
standalone normalization is unsafe: first sample-only procedure cond was
refused, but the candidate newly admits it as activation with one later branch.
Complete actual check/semantic/schedule native/API/newline admission and the
independent desired-branch RED establish the gap. Exact committed production
is restored and public refusal requalified; `.5.2` explicit source intent is
now next, then `.5.4.2` safe normalization and `.5.3` branch integration.
Scalar literal and record-output read/write prerequisites follow separately.
'''
assert old in s
p.write_text(s.replace(old,new))
