"""Qualify saved preparation metadata without promoting the retained no-op."""
import preparation_correction as correction
from saved_source_roles import Qualification

LINE = ('Retained preparation correction is explicitly qualified as a no-op: whole '
        'first/corrected bodies agree and no replacement site exists. Archived '
        'explanation is superseded, native failures and historical attribution gaps '
        'retain; no original execution or compile-input qualification follows.\n')
SCOPE = ('Preparation-correction saved programme metadata and its complete original '
         'source-pair, native-receipt, custody-descriptor, edit-oracle, control and scope '
         'proof only. Python AST/byte/hash/Git/stdlib semantics and archived receipt '
         'authenticity remain shared premises. The retained correction stays a no-op; '
         'actual original stdin, prelaunch custody, compile-only binding, complete '
         'source/default/effect/runtime/private/HIAL/full-CI qualification remain open. '
         'Historical programme/recipe/cohort bodies remain data and never execute.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    Qualification(correction, 'qualify_preparation_roles.py',
                  'preparation-source-roles-qualified.json.gz', LINE, SCOPE).main()
