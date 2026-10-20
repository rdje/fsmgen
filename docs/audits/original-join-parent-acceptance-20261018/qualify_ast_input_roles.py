"""Qualify saved AST-input metadata while retaining every AST and scope field."""
import ast_model_inputs as model
from saved_source_roles import Qualification

LINE = ('Whole fixed model AST inputs reconstruct with typed fields and coordinates; '
        'independent path-patch/source controls agree. Namespace/caller/export contracts '
        'retain without historical execution or complete allocation/runtime authority.\n')
SCOPE = ('AST-input saved programme metadata and its complete original typed-tree, '
         'coordinate, caller/namespace, input/native/Python, control and scope proof only. '
         'Python AST/location/symbol-table semantics and the original source-model '
         'premises remain shared. Concrete exports, complete source/data/default/effect/'
         'runtime/custody/private/HIAL/full-CI qualification remain open. Historical '
         'programme/model/recipe/cohort bodies remain data and never execute.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    Qualification(model, 'qualify_ast_input_roles.py', 'ast-input-source-roles-qualified.json.gz',
                  LINE, SCOPE).main()
