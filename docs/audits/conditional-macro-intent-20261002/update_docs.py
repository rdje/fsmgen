from pathlib import Path

p = Path('docs/book/src/13k-isf-feature-support-matrix.md')
s = p.read_text()
old = 'with source-intent repair owned by SEM `.60.4.3.3.5.2.1.5`; a missing register name'
new = ('with source-intent repair owned by SEM `.60.4.3.3.5.2.1.5`. '
       'First sample-only conditional bit/field/cond shorthand can still admit as '
       'activation rather than branching; use explicit activation before it. '
       'Inline procedure `cond` remains unexpanded and refuses, with normalization '
       'owned by `.5.4` next. These are existing ISF/IAL1 parser/scheduler repairs; '
       'a missing register name')
assert s.count(old) == 1
p.write_text(s.replace(old, new))

p = Path('docs/TASK_TREE.md')
s = p.read_text()
old = 'related first-operation macro repair .5.2.1.5 is next, then scalar literal false-operand'
new = ('related macro qualification .5.2.1.5.1 is active, with inline-procedure '
       'cond normalization .5.4 next before explicit source-intent propagation '
       'and integration, then scalar literal false-operand')
assert s.count(old) == 1
p.write_text(s.replace(old, new))
