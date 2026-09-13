"""Workers require the fixed execution permit before opening a fixture."""

import hashlib
import json

from contract import BASE, ROOT, OUTPUT, EXECUTION_OWNER, cases
from local_files import read_bytes


def worker_admission():
    plan_bytes = read_bytes((BASE / 'plan.json').relative_to(ROOT).as_posix(), 65536)
    permit = json.loads(read_bytes(OUTPUT + '/execution-admission.json', 4096))
    if (permit.get('schema') != 'fsmgen.language_coordination_execution_admission.v1'
            or permit.get('execution_owner') != EXECUTION_OWNER
            or permit.get('plan_sha256') != hashlib.sha256(plan_bytes).hexdigest()):
        raise ValueError('worker lacks the current fixed execution permit')
    plan = json.loads(plan_bytes)
    if plan['cases'] != cases():
        raise ValueError('worker domain differs from admitted plan')
    return plan
