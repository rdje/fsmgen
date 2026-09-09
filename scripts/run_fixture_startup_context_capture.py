"""Fixed T1669 kernel capture with complete execution-policy context.

The existing launcher owns the original, collector and helper settlement.
This entrypoint fixes the collector scope; original argv, helper admission,
capture command and all deadlines retain their qualified policies.
"""

import run_fixture_startup_observation as launcher


if __name__ == "__main__":
    raise SystemExit(launcher.main(policy_scope="execution_context"))
