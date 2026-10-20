"""Qualify caller-module metadata without changing its conservative graph."""
import qualify_caller_modules as caller
from saved_source_roles import Qualification

LINE = ('Fixed caller namespaces, finite module paths and conservative imported/wrapper '
        'source closure pass; executable data, default effects and custody remain unqualified.\n')
SCOPE = ('Caller-module saved metadata and its complete original graph/review/control/scope '
         'proof only. Conservative imported/wrapper closure retains its declared grammar, '
         'AST and interpreter premises. Executable data, default effects and custody '
         'remain unqualified; no original source or semantic cohort executes.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    Qualification(caller, 'qualify_caller_roles.py', 'caller-source-roles-qualified.json.gz',
                  LINE, SCOPE).main()
