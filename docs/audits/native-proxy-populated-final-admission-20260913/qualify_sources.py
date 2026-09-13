"""Model exact Git/source authentication without issuing execution authority."""
import copy
import json
from unittest.mock import patch

import admission
from build_plan import build
from contract import BASE, ROOT, driver_sources, worker_sources
import records


def qualify():
    checks, rejected = [], []
    plan = build()
    prefix = BASE.relative_to(ROOT).as_posix()
    required = sorted(set(driver_sources()) | {row['path'] for row in worker_sources()} | {
        '.gitignore', prefix + '/scope.json', prefix + '/worker-sources.json'})
    source_bytes = {name: (ROOT / name).read_bytes() for name in required}
    pins = [dict(path=name, **records.file_pin(body)) for name, body in sorted(source_bytes.items())]
    encode = lambda value: (json.dumps(value, sort_keys=True, indent=2) + '\n').encode()
    baseline = dict(source_bytes)
    baseline[prefix + '/plan.json'] = encode(plan)
    baseline[prefix + '/execution-source-pins.json'] = encode(pins)
    # Qualification summaries are authenticated as exact committed documents;
    # their contents are independently re-derived by audit.verify_saved.
    baseline[prefix + '/qualification.json'] = encode({'source_only_model': True})
    baseline[prefix + '/review.json'] = encode({'source_only_model': True})
    selected = dict(baseline)

    def read(path, limit, mode=None):
        body = selected[path]
        if len(body) > limit:
            raise ValueError('model input byte bound exceeded')
        return body

    def git(*args):
        if args[0] != 'show' or not args[1].startswith('a' * 40 + ':'):
            raise ValueError('model rejects an undeclared Git request')
        return baseline[args[1].split(':', 1)[1]]

    def check(name, value):
        if not value or name in checks:
            raise AssertionError(name)
        checks.append(name)

    def reject(name, operation):
        try:
            operation()
        except (ValueError, KeyError, TypeError) as error:
            rejected.append(dict(name=name, error=str(error)))
        else:
            raise AssertionError(name + ': unexpectedly accepted')

    with patch.object(admission.files, 'read_bytes', read), patch.object(admission, 'git', git):
        observed, permit = admission.authenticated_sources('a' * 40)
        check('exact source closure reconstructs its committed inactive plan', observed == plan and permit['admission_commit'] == 'a' * 40)
        for revision in ('--output=undeclared', 'a' * 12, 'g' * 40, '', None):
            reject('nonliteral admission revision ' + repr(revision), lambda revision=revision: admission.authenticated_sources(revision))
        path = driver_sources()[0]
        selected[path] += b'\n'
        reject('changed runtime source bytes', lambda: admission.authenticated_sources('a' * 40))
        selected[path] = baseline[path]
        original = baseline[prefix + '/execution-source-pins.json']
        for name, mutate in [
            ('omitted driver source', lambda rows: rows.remove(next(row for row in rows if row['path'] == path))),
            ('duplicate selected source', lambda rows: rows.append(copy.deepcopy(rows[0]))),
            ('absolute project input', lambda rows: rows[0].update(path='/outside/input')),
            ('boolean source size', lambda rows: rows[0].update(size_bytes=True)),
            ('unbounded source size', lambda rows: rows[0].update(size_bytes=4 * 1024 * 1024 + 1)),
            ('changed source digest', lambda rows: rows[0].update(sha256='0' * 64))]:
            rows = copy.deepcopy(pins)
            mutate(rows)
            # Alter both views so this reaches semantic source validation,
            # rather than failing only the outer Git-document comparison.
            selected[prefix + '/execution-source-pins.json'] = baseline[prefix + '/execution-source-pins.json'] = encode(rows)
            reject(name, lambda: admission.authenticated_sources('a' * 40))
        selected[prefix + '/execution-source-pins.json'] = baseline[prefix + '/execution-source-pins.json'] = original
        for name, mutation in [
            ('plan omits fixed driver imports', lambda value: value['driver_sources'].pop()),
            ('plan changes fixed worker count', lambda value: value['cases'].pop()),
            ('plan grants execution authority', lambda value: value.update(execution_authorized=True)),
            ('plan changes an owned root', lambda value: value['roots'].append('.artifacts/undeclared'))]:
            changed = copy.deepcopy(plan)
            mutation(changed)
            selected[prefix + '/plan.json'] = baseline[prefix + '/plan.json'] = encode(changed)
            reject(name, lambda: admission.authenticated_sources('a' * 40))
        selected[prefix + '/plan.json'] = baseline[prefix + '/plan.json'] = encode(plan)
        for name in ('qualification.json', 'review.json'):
            path = prefix + '/' + name
            selected[path] = encode({'changed_model_summary': True})
            reject('changed committed ' + name, lambda: admission.authenticated_sources('a' * 40))
            selected[path] = baseline[path]
        check('rejected source variants do not alter the accepted baseline', admission.authenticated_sources('a' * 40)[0] == plan)
    return dict(schema='fsmgen.inactive_populated_source_authentication_models.v1', checks=checks, rejecting_controls=rejected,
        actual_git_source_admission=False, actual_worker_execution=False, actual_fixture_allocation=False)


if __name__ == '__main__':
    print(json.dumps(qualify(), sort_keys=True, indent=2))
