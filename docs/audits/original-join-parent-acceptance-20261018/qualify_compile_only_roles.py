"""Qualify compile-only saved metadata without promoting original execution."""
import compile_only_inputs as inputs
from saved_source_roles import Qualification

LINE = ('Complete preparation input bytes and compilation names bind to standalone '
        'discarded compiler results; native source/data joins and genuine controls agree. '
        'Current syntax compilation executes no code; original input/callable/prelaunch '
        'and complete allocation/effect/runtime qualifications remain open.\n')
SCOPE = ('Compile-only saved programme metadata and the complete original source/input '
         'bindings, native references, AST/token/line oracles, current syntax-compilation '
         'records, controls, Python identity and scope only. Current compiler/AST/token/'
         'byte/hash/Git semantics and archived receipt authenticity remain shared '
         'premises. Syntax compilation executes no generated code. Original callable '
         'identity, actual stdin, prelaunch custody, complete source/default/effect/'
         'runtime/private/HIAL/full-CI qualifications remain open. Historical '
         'programme/recipe/cohort bodies remain data and never execute.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    Qualification(inputs, 'qualify_compile_only_roles.py',
                  'compile-only-source-roles-qualified.json.gz', LINE, SCOPE).main()
