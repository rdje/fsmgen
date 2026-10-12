"""Produce the complete source-bound unchanged original-consumer parent candidate."""
from parent_common import *
import model

save_product('candidate.json.gz', model.propose(model.inputs()))
print('PASS complete unchanged original-consumer parent candidate; independent acceptance remains separate.')
