"""Qualify payload saved metadata without expanding original source/runtime authority."""
import payload_closure as payload
from saved_source_roles import Qualification

LINE = ('Reconstructed lexical payload boundaries, stdlib-name declarations, '
        'namespace/export source contracts and discarded-result input-only exclusions '
        'qualify; token/serialized-tree checks and genuine controls agree. Original '
        'loader/callable/namespace values and source/default/effect/runtime authority '
        'remain open.\n')
SCOPE = ('Payload saved programme metadata and the complete original lexical payload, '
         'namespace/export selector, discarded compiler-result exclusion, source/native '
         'allocation, Python metadata and genuine-control proof only. Frozen allocation '
         'and prior models, Python syntax/symbol/builtin/stdlib APIs and declared '
         'compiler/namespace contracts remain shared premises. Every pre-existing '
         'input/derive/review/control function body remains unchanged. Historical '
         'programme/model/recipe images remain data. Complete source/default/effect/'
         'runtime/custody, concrete namespace/export, original callable/loader, private/'
         'HIAL/full-CI and whole-helper success remain separately owned. Independent '
         'full role-record/module conservation and native route admission remain open.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    Qualification(payload, 'qualify_payload_roles.py',
                  'payload-source-roles-qualified.json.gz', LINE, SCOPE).main()
