"""Propose the complete unchanged finite cause-parent composition."""
from parent_common import *
import context

save_product('candidate.json.gz', context.expected())
print('Built complete unchanged original cause/canonical parent proposal; independent admission remains required.')
