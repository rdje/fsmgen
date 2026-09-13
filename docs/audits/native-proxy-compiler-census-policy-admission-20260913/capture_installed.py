"""Read installed inputs as a named guarded program, never via guarded stdin."""
from datetime import datetime, timezone
import json

from admission import BASE, epoch_now, save


if __name__ == '__main__':
    value = epoch_now()
    save(BASE / 'installed-inputs-first.json', dict(
        captured_utc=datetime.now(timezone.utc).isoformat(),
        scope='Read-only source qualification; execution must revalidate again after its admission commit.',
        compiler_invocations=0, fixture_allocations=0, inputs=value))
    print(json.dumps(dict(installed_inputs_match=True, git_launcher=value['git_launcher']['sha256'],
                         compiler_invocations=0, fixture_allocations=0), sort_keys=True))
