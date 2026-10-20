"""Qualify saved operand metadata while preserving the whole syntax inventory."""
import operand_inventory as operands
from saved_source_roles import Qualification

LINE = ('Complete compile/exec syntax operands, token allocation and saved rejection '
        'candidates agree; source/data bindings and runtime remain unqualified.\n')
SCOPE = ('Operand-inventory saved programme metadata and its complete original syntax, '
         'independent token, control and scope proof only. CPython lexical grammar and '
         'the conservative fixed source graph remain shared premises. Source/data '
         'bindings, default effects and runtime custody remain unqualified; no '
         'historical source, recipe or semantic cohort executes.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    Qualification(operands, 'qualify_operand_roles.py', 'operand-source-roles-qualified.json.gz',
                  LINE, SCOPE).main()
