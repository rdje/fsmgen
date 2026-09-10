"""One normal-user T1669 observation with passive fixtures and daemon context.

The shared policy-only lifecycle owns the original, collector and fixture
settlement. This fixed entrypoint requires no authenticated kernel helper;
raw daemon output remains private and kernel evidence is not collected.
"""

import run_fixture_startup_policy_observation as observation


if __name__ == "__main__":
    raise SystemExit(observation.main(policy_scope="daemon_context"))
