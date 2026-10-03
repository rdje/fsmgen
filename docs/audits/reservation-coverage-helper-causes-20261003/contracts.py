# Complete causes declared from FormalReservationCoverage's guard clauses and
# the literal coverage/worker DSL, canonical payload allocation and wait ordinal.
EXPECTED = {
 'late register': "Formal reservation coverage: module 'coverage' has unreserved declarations: late_unreserved_helper",
 'implicit assignment declaration': "Formal reservation coverage: module 'coverage' has unreserved declarations: implicit_late_helper",
 'missing parent': 'Formal reservation coverage has incomplete parent/domain modules (missing: coverage; unexpected: )',
 'unexpected module': 'Formal reservation coverage has incomplete parent/domain modules (missing: ; unexpected: extra)',
 'missing child': "Formal reservation coverage has incomplete children of 'coverage' (missing: worker; unexpected: )",
 'unexpected nested child': 'Formal reservation coverage has an unplanned nested child scope',
 'wrong child identity': "Formal reservation coverage has a missing or mismatched module 'worker'",
 'parent private name leaked into child': "Formal reservation coverage: module 'worker' has unreserved declarations: isf_port_main_payload_formal",
 'wrong formal width': "Formal reservation coverage: private formal 'isf_port_main_payload_formal' has wrong width or ownership in 'coverage'",
 'wrong formal role': "Formal reservation coverage: private formal 'isf_port_main_payload_formal' has wrong width or ownership in 'coverage'",
 'formal aliases a late block': "Formal reservation coverage: private formal 'isf_port_main_payload_formal' has wrong width or ownership in 'coverage'",
 'stale or incomplete allocation': 'Formal reservation coverage requires the canonical complete allocation plan',
 'omitted real producer declaration': "Formal reservation coverage: module 'coverage' has unreserved declarations: main_wait_4_cnt",
}
