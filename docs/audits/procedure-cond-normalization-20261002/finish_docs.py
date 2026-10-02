from pathlib import Path

p=Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')
s=p.read_text()
owner='SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.4.1'
start=s.index('- ID: `'+owner+'`')
end=s.index('\n- ID:',start+1)
node=s[start:end].replace('Status: `active`','Status: `done`').replace('Commit: `pending`','Commit: `this commit`')
vstart=node.index('  Verification: `')
vend=node.index('\n  Commit:',vstart)
node=node[:vstart]+('  Verification: `Fixed corpus contains 26 complete sources. Exact committed old-parser preloading gives genuine RED Files=1/Tests=27/Failed23; the canonical four-line candidate passes structural Files=1/Tests=27 and complete 43-source actual native/API/newline/carrier Files=1/Tests=44. Independent first_samples branch oracle is genuine RED Files=1/Tests=2/Failed2: candidate entry plus one later branch newly admits a previously refused source through all real public phases. Every saved candidate carrier strictly checks, so syntax/parity is insufficient. Restore exact committed Parser/T2041; fresh permanent current-boundary capture passes Files=1/Tests=27 and actual first_samples check/semantic failures retain status1 complete machine envelopes, schedule empty stdout/status255 and bounded RPC-32000. Literal/source/kind/full-product verification rejects five shared corruptions and authenticates unchanged bin/perl census plus all immutable predecessors. Focused restored checks pass Files=9/Tests=60, six docs checks Files=6/Tests=622 with 115 complete fixtures lowering; syntax/book and actual rendered text/code/links/canonical includes pass without browser visual QA. Complete source/code/counterfactual/drafts/raw receipts are sealed under docs/audits/procedure-cond-normalization-20261002. Initial repeat-body support/generated-params assumptions and static capture label are corrected with exact failed drafts retained; first render marker incorrectly assumed the canonical part was included in standalone Transactions, so preserve failure and inspect actual independent chapter before correction. .5.2 explicit source intent is next, then .5.4.2 safe normalization and .5.3 branch integration. No production widening, macro/handshake execution, HDL invocation, spent replay, record-output route widening or full CI/push.`')+node[vend:]
s=s[:start]+node+s[end:]
s=s.replace('- [ ] **ROOT CAUSE (WHY + WHERE)** — pending exact substituted-body/canonical cond producer, scope/call-recursion controls and genuine baseline RED.',
 '- [x] **ROOT CAUSE (WHY + WHERE)** — git log -S roots procedure expansion at e680f9670257c6d6e9ad0c46d222e96697ea2304 and cond at 368c42812ff7849a7c6aff78b9a2bec527e58ae9. _expand_one_call inserts substituted bodies after the transaction cond pass. Actual four-line canonical normalization produces first_samples entry plus one later branch, losing ordinary first branch intent at _ir_when_activation. Complete actual native/API/newline check/semantic/schedule admit the candidate; independent desired-source branch oracle is terminal RED, Files=1/Tests=2/Failed2. Thus the structural and 43-source classification passes cannot authorize new sample admission.')
s=s.replace('- [ ] **ADDRESSED (verified)** — pending lazy call-site normalization with complete source/actor/private/public products and preserved authored-entry boundaries.',
 '- [x] **ADDRESSED (verified)** — Retain exact candidate, complete 26-source products, original definitions/kinds, genuine committed old-parser RED and full 43-source public capture. Independent safety falsification identifies the newly unsafe source before integration. Restore exact committed Parser/T2041; current-boundary test passes Files=1/Tests=27 and actual public first_samples refusal is requalified. Five shared corruptions reject. Safe normalization .5.4.2 now explicitly requires source intent .5.2; ordinary branch integration .5.3 follows. Book/downstream/feedback/current fact reflect the actual closure and call-site workaround. This is committed diagnosis with production unchanged, not delivered normalization.')
s=s.replace('- [ ] **NO REGRESSION** — pending focused macro/procedure/activation/scope tests, actual public transports, docs/book and immutable predecessor checks.',
 '- [x] **NO REGRESSION** — Guarded restored T2042/macro/procedure/activation cohort reports All tests successful, Files=9, Tests=60. Six docs audits report All tests successful, Files=6, Tests=622 with 115 complete fixtures lowering; syntax and mdBook build pass. Actual rendered text/code/links and canonical includes pass without browser visual QA. Exact bin/perl census proves full production restoration, and every predecessor archive authenticates unchanged without replay. Independent saved-product/full-cohort/hostile verification, regenerated Knowledge Map, measured containment and complete claim reconciliation precede staged doctrines and normal hooks. Failed fixture/render/receipt-label attempts remain honest saved evidence. No HDL execution, feature runtime, record routing/public widening or full CI/push is inferred.')
# Keep the prerequisite explicit in the source-intent node without changing scope.
start=s.index('- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2`')
end=s.index('\n- ID:',start+1)
block=s[start:end].replace('After .1, define', 'After .1 and .4.1, define')
block=block.replace('  Verification: `pending actual family qualification`',
 '  Verification: `Committed .5.1 qualifies family placement; .5.4.1 shows candidate inline normalization newly admits first_samples as activation. This source-intent contract must precede .5.4.2 integration and retain original macro operation/call context through normalization. .5.2 is the next frontier; no admission/parity-only signoff.`')
s=s[:start]+block+s[end:]
s+='''\nThe safety qualification corrects integration order based on actual new-source
admission, not the DBINP discussion. Preserve all failed recipes. Staged
whitespace exceptions are confined to exact archived sources/raw evidence;
maintained code/docs are whitespace-clean. Final prose must precede capacity,
claim census and index gating to avoid the predecessor's stale-census mistake.
'''
p.write_text(s)

p=Path('MEMORY.md')
s=p.read_text()
start=s.index('- active_work_unit:')
end=s.index('- blockers:',start)
s=s[:start]+'''- active_work_unit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2` (pending)
- next_action: From the committed inline-cond safety diagnosis, qualify explicit normalized conditional-macro source intent before safe .5.4.2 normalization and .5.3 branching. Preserve authored activation and closed first sample-procedure cond; no HDL invocation or output widening.
- in_flight_uncommitted: derive with `git status --short`; finish .5.4.1 diagnosis commit workflow before activating .5.2.
- in_flight_background: none.
'''+s[end:]
p.write_text(s)

p=Path('docs/TASK_TREE.md')
s=p.read_text().replace('inline-procedure cond safety qualification .5.4.1 active; explicit source intent .5.2 precedes',
 'inline-procedure cond safety qualification .5.4.1 complete; explicit source intent .5.2 is next before')
p.write_text(s)
