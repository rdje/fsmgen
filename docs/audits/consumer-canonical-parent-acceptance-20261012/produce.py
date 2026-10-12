"""Produce the complete source-bound unchanged canonical-parent candidate."""
from parent_common import *
import model

save_product('candidate.json.gz', model.propose(model.inputs()))
print('PASS complete unchanged canonical-parent candidate; independent acceptance remains separate.')
