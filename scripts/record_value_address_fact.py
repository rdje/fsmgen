"""Authenticate admitted finite address evidence and publish its reviewed facts.

This authenticates a committed complete qualification. It neither recaptures
original executions nor turns native identity and cross-capture gaps into facts.
"""
import hashlib
import json
import re

import book_source_references as plane

PREPARATION = 'docs/audits/address-publication-preparation-20261010'
PROPOSAL = PREPARATION + '/proposal.json'
PROOF = PREPARATION + '/final-proof.json'
QUESTION = 'what qualifies original address roles?'
# Explicit committed admission identities are inserted before first execution.
ADMITTED_MEMBERS = {'docs/audits/address-publication-preparation-20261010/before-book-authority.jsonl.txt': {'bytes': 36494,
                                                                                          'lines': 34,
                                                                                          'sha256': '7fdd55199e35e4c5fdb0ce7336c2b590b84c8f59d316cf22f7b3712569d05586'},
 'docs/audits/address-publication-preparation-20261010/book-addition.md.txt': {'bytes': 2998,
                                                                               'lines': 48,
                                                                               'sha256': '60e6c4285d332aa8ad58b592b21da108a4a4ef150e6fef537d61c40c8fc710ea'},
 'docs/audits/address-publication-preparation-20261010/book-authority.json': {'bytes': 21765,
                                                                              'lines': 664,
                                                                              'sha256': 'c455b5dd99c81b9d637ff8710999281bf4fd7e232643ed44d066a55f8c97c565'},
 'docs/audits/address-publication-preparation-20261010/book-proof.json': {'bytes': 914,
                                                                          'lines': 25,
                                                                          'sha256': '32ba61996c02c647e7d6b77f23e8161fee8d044cd63b8a803d266a255b7c5603'},
 'docs/audits/address-publication-preparation-20261010/book-replacements.json': {'bytes': 3,
                                                                                 'lines': 1,
                                                                                 'sha256': '37517e5f3dc66819f61f5a7bb8ace1921282415f10551d2defa5c3eb0985b570'},
 'docs/audits/address-publication-preparation-20261010/book_authority.py': {'bytes': 4176,
                                                                            'lines': 74,
                                                                            'sha256': '2eee370225d8aea2a7975d4eb4cb949d27ddeeb102ae6bd6403dca04f73579aa'},
 'docs/audits/address-publication-preparation-20261010/book_check.py': {'bytes': 3639,
                                                                        'lines': 79,
                                                                        'sha256': '7bd6751ea57279be4ad944a337a76936fec42646cbfb2d6d3e177911c60668d2'},
 'docs/audits/address-publication-preparation-20261010/checks.json': {'bytes': 87389,
                                                                      'lines': 574,
                                                                      'sha256': '873c4f60669f6233773cada6a8ce4b09e60221cd2ad6104dbfa05dbf67da557c'},
 'docs/audits/address-publication-preparation-20261010/checks.py': {'bytes': 1418,
                                                                    'lines': 31,
                                                                    'sha256': '7a2dd738b697b48b964889080da95048e60b178d26885738794c09f32ff0f349'},
 'docs/audits/address-publication-preparation-20261010/declaration.py': {'bytes': 3078,
                                                                         'lines': 62,
                                                                         'sha256': '395abcf74227e8f346ceeac463a3666dae0f1ad4970b3faa8b0298952b6d4b9b'},
 'docs/audits/address-publication-preparation-20261010/final-proof.json': {'bytes': 10908,
                                                                           'lines': 332,
                                                                           'sha256': '78069c6fcf26d5644dce9cbf20a8751040acc9f87fa18febaa7cead8a82ae52a'},
 'docs/audits/address-publication-preparation-20261010/first-draft.json': {'bytes': 46053,
                                                                           'lines': 28,
                                                                           'sha256': 'dab45ecc1af1ab07b5c9563ed1e680831f98043353498dedb3e4c39468b0fcc2'},
 'docs/audits/address-publication-preparation-20261010/first-model.py.txt': {'bytes': 15975,
                                                                             'lines': 227,
                                                                             'sha256': '73d888a63b3db6f554c31cab58d7a8f4bd8e2fb9e52b5f6c1eba5637380baea1'},
 'docs/audits/address-publication-preparation-20261010/first-prepare.py.txt': {'bytes': 7257,
                                                                               'lines': 94,
                                                                               'sha256': '11e6346cd31a512624755e1ea95799220291681082ac9a05823ccfdea87f7387'},
 'docs/audits/address-publication-preparation-20261010/first-qualified-proof.json.txt': {'bytes': 9603,
                                                                                         'lines': 291,
                                                                                         'sha256': 'adbcbeeb423cfebc63b0e648ae6c3805d0e271a06af68bcbbfae30903c07c2bc'},
 'docs/audits/address-publication-preparation-20261010/first-qualified-verify.py.txt': {'bytes': 15322,
                                                                                        'lines': 185,
                                                                                        'sha256': 'a8c753527867d9712136a5d89799d58a28755085521d3be15ce12be5f221d001'},
 'docs/audits/address-publication-preparation-20261010/first-reproduce_schema.py.txt': {'bytes': 2583,
                                                                                        'lines': 48,
                                                                                        'sha256': '79e3bc6c2bb583481ec37a43645628f6eb7efbe8e1d77d8694c5fc26c0e40db3'},
 'docs/audits/address-publication-preparation-20261010/first-verify.py.txt': {'bytes': 15000,
                                                                              'lines': 182,
                                                                              'sha256': '7a9fe3295c983501662c19e2220a4e7ddcd76af64deb40cdcbf7c27332ca0247'},
 'docs/audits/address-publication-preparation-20261010/fourth-draft.json': {'bytes': 22732,
                                                                            'lines': 12,
                                                                            'sha256': 'b46d5f7b258b79549ec9eeab0eead6dfa83e2c34415b99308b9fdafba2dd4a2f'},
 'docs/audits/address-publication-preparation-20261010/fourth-model.py.txt': {'bytes': 46877,
                                                                              'lines': 508,
                                                                              'sha256': 'b5f274e35c3c119972ccf47a58d00ec6889b2f29ca5255f3cb253194d336cde0'},
 'docs/audits/address-publication-preparation-20261010/guide.md.txt': {'bytes': 3431,
                                                                       'lines': 52,
                                                                       'sha256': 'bf68b1789c0fcbf91891e9045c6de417b35ce6db26a6103482b0a43a3c318b6d'},
 'docs/audits/address-publication-preparation-20261010/harness-import-gap.md.txt': {'bytes': 1123,
                                                                                    'lines': 17,
                                                                                    'sha256': '5bbf64e57dbd93917b1d2706434ca5470c974c9d10cbf7b825bc7e7bb205910e'},
 'docs/audits/address-publication-preparation-20261010/model.py': {'bytes': 46796,
                                                                   'lines': 507,
                                                                   'sha256': 'ab331ad5d3f0c0a1f54317e538525fe7111a816b3efa12c3bd18506f92a55e3f'},
 'docs/audits/address-publication-preparation-20261010/prepare.py': {'bytes': 7466,
                                                                     'lines': 98,
                                                                     'sha256': '12bc467b8a1df1fc47bcfedcfc7b49e9dff9ce4f85b0ffc69397f75a448930f6'},
 'docs/audits/address-publication-preparation-20261010/proof.json': {'bytes': 9603,
                                                                     'lines': 291,
                                                                     'sha256': 'adbcbeeb423cfebc63b0e648ae6c3805d0e271a06af68bcbbfae30903c07c2bc'},
 'docs/audits/address-publication-preparation-20261010/proposal.json': {'bytes': 3046768,
                                                                        'lines': 8869,
                                                                        'sha256': '322949c3bdb3e126e8a735b19a6342600282c172e6056357495c1d2b4eb3b62e'},
 'docs/audits/address-publication-preparation-20261010/reproduce_schema.py': {'bytes': 3057,
                                                                              'lines': 61,
                                                                              'sha256': 'c8990df40a653da16ccb7c99561903f6a362ec42951cea1e61148a34f6b78c1a'},
 'docs/audits/address-publication-preparation-20261010/root-cause.json': {'bytes': 2168,
                                                                          'lines': 17,
                                                                          'sha256': '9a8ab2565a3365d19e25c2355d3a65c79ef909bcf66f9c72db06b16ad348deaa'},
 'docs/audits/address-publication-preparation-20261010/schema-first-admission.md.txt': {'bytes': 2233,
                                                                                        'lines': 34,
                                                                                        'sha256': '76e86ee86ad4c931fa73c4d4359e22e60b03cb2e14b96ad3225cd5d298b6207a'},
 'docs/audits/address-publication-preparation-20261010/schema-first-admission/candidate.json': {'bytes': 3046839,
                                                                                                'lines': 8870,
                                                                                                'sha256': '17ba346d20212739fa4450c71506c08c59f5c2f0bbdb586fdb96e8a00be4c3f6'},
 'docs/audits/address-publication-preparation-20261010/schema-first-admission/produced-proof.json': {'bytes': 9603,
                                                                                                     'lines': 291,
                                                                                                     'sha256': '64843053f3e24916ad0559dd7ce023ef6e185d421045271f39c9306d90db678b'},
 'docs/audits/address-publication-preparation-20261010/schema-first-admission/repair.json': {'bytes': 1736,
                                                                                             'lines': 55,
                                                                                             'sha256': 'f9ec077e83245d5db0d11ced1429caa545c01f7e78ba9abafbad9e993fee1cf9'},
 'docs/audits/address-publication-preparation-20261010/schema-first-admission/reproduction.json': {'bytes': 848,
                                                                                                   'lines': 17,
                                                                                                   'sha256': 'c269d00831b4cbeb950826d67f06abe7075f82fa902da76c7b0075d3d5b4cbb5'},
 'docs/audits/address-publication-preparation-20261010/scope.txt': {'bytes': 107,
                                                                    'lines': 1,
                                                                    'sha256': '68c94b8def860a58c7931c4fa17b5fef10256f94eb0206857c6cb6bc005ef7f0'},
 'docs/audits/address-publication-preparation-20261010/second-draft.json': {'bytes': 23259,
                                                                            'lines': 10,
                                                                            'sha256': 'cefa49d66d1bc45792f7436d934227f2ed1e78074fb7756e4505f520cf3ca97f'},
 'docs/audits/address-publication-preparation-20261010/second-model.py.txt': {'bytes': 47817,
                                                                              'lines': 518,
                                                                              'sha256': '08ac9e1f2a8ab9487273024e440ea4b581c9edcc36b2fefc46ead4340f681f44'},
 'docs/audits/address-publication-preparation-20261010/source/03b50bc2676409da4da469e565b66c5e0b0356a21a91ba17078832162aaa2e83.txt': {'bytes': 257024,
                                                                                                                                      'lines': 3198,
                                                                                                                                      'sha256': '03b50bc2676409da4da469e565b66c5e0b0356a21a91ba17078832162aaa2e83'},
 'docs/audits/address-publication-preparation-20261010/source/27368f4de09823488bc7acda9eeb1d367e6b6398571002af80a06c77d305c3d4.txt': {'bytes': 6318,
                                                                                                                                      'lines': 88,
                                                                                                                                      'sha256': '27368f4de09823488bc7acda9eeb1d367e6b6398571002af80a06c77d305c3d4'},
 'docs/audits/address-publication-preparation-20261010/source/282edfe92b6495383dc708df7a5c90bf0e5ca8481f694e16a124258e4b0bc7ab.txt': {'bytes': 61538,
                                                                                                                                      'lines': 1026,
                                                                                                                                      'sha256': '282edfe92b6495383dc708df7a5c90bf0e5ca8481f694e16a124258e4b0bc7ab'},
 'docs/audits/address-publication-preparation-20261010/source/2960c0bc062fa8e565af2f842e6798c90792add832f70fd06f314ba5139cecac.txt': {'bytes': 6137,
                                                                                                                                      'lines': 79,
                                                                                                                                      'sha256': '2960c0bc062fa8e565af2f842e6798c90792add832f70fd06f314ba5139cecac'},
 'docs/audits/address-publication-preparation-20261010/source/4b96640964c3b94965b324fac724aaae4379e46735b7254121a8e85462d7d793.txt': {'bytes': 14406,
                                                                                                                                      'lines': 247,
                                                                                                                                      'sha256': '4b96640964c3b94965b324fac724aaae4379e46735b7254121a8e85462d7d793'},
 'docs/audits/address-publication-preparation-20261010/source/50f78dfc9ca22af03045988535e00daa11ad378a44098d0f9423800d235ad204.txt': {'bytes': 4820,
                                                                                                                                      'lines': 70,
                                                                                                                                      'sha256': '50f78dfc9ca22af03045988535e00daa11ad378a44098d0f9423800d235ad204'},
 'docs/audits/address-publication-preparation-20261010/source/750bb391f8b6ecf4a6c0bd07cad030a73d45cf26044635f7ada165c644262048.txt': {'bytes': 6122,
                                                                                                                                      'lines': 95,
                                                                                                                                      'sha256': '750bb391f8b6ecf4a6c0bd07cad030a73d45cf26044635f7ada165c644262048'},
 'docs/audits/address-publication-preparation-20261010/source/7fdd55199e35e4c5fdb0ce7336c2b590b84c8f59d316cf22f7b3712569d05586.txt': {'bytes': 36494,
                                                                                                                                      'lines': 34,
                                                                                                                                      'sha256': '7fdd55199e35e4c5fdb0ce7336c2b590b84c8f59d316cf22f7b3712569d05586'},
 'docs/audits/address-publication-preparation-20261010/source/848cc8ce10a3a6de53f266e656988ea6ab07d9c63a5150a47f8807f521b2e41b.txt': {'bytes': 12717,
                                                                                                                                      'lines': 232,
                                                                                                                                      'sha256': '848cc8ce10a3a6de53f266e656988ea6ab07d9c63a5150a47f8807f521b2e41b'},
 'docs/audits/address-publication-preparation-20261010/source/9d8b7daef8b992f8382d488e64d1973ae5b352442bbdad0b88bab9444f58451b.txt': {'bytes': 7833,
                                                                                                                                      'lines': 53,
                                                                                                                                      'sha256': '9d8b7daef8b992f8382d488e64d1973ae5b352442bbdad0b88bab9444f58451b'},
 'docs/audits/address-publication-preparation-20261010/source/b4023a9d92b2b2be86debca037aa01aea3414605b46f52d30df818868775d73a.txt': {'bytes': 4150,
                                                                                                                                      'lines': 65,
                                                                                                                                      'sha256': 'b4023a9d92b2b2be86debca037aa01aea3414605b46f52d30df818868775d73a'},
 'docs/audits/address-publication-preparation-20261010/source/f91ee8a2ed7f79c0c52e9433fb77e5deebf29fb7848af5205ecc61363fb74d21.txt': {'bytes': 4304,
                                                                                                                                      'lines': 59,
                                                                                                                                      'sha256': 'f91ee8a2ed7f79c0c52e9433fb77e5deebf29fb7848af5205ecc61363fb74d21'},
 'docs/audits/address-publication-preparation-20261010/staged-whitespace.json': {'bytes': 616,
                                                                                 'lines': 17,
                                                                                 'sha256': '7dffc85e76613df59cfbb961c40e9cdb62755770fb44ba492b27d180c36b6f09'},
 'docs/audits/address-publication-preparation-20261010/task-metrics.json': {'bytes': 431,
                                                                            'lines': 12,
                                                                            'sha256': 'a8fb844e54d43f6c8f2184f4b4d18d9a7271df43b69d6a758f5a0727ce6d5385'},
 'docs/audits/address-publication-preparation-20261010/task_pressure.py': {'bytes': 1928,
                                                                           'lines': 34,
                                                                           'sha256': '3bbeffbf5e45a0277becb5ccaa394700ff5c6bbcc9973ae80359302c6aecd2a9'},
 'docs/audits/address-publication-preparation-20261010/third-draft.json': {'bytes': 22626,
                                                                           'lines': 10,
                                                                           'sha256': '82c2bdf603d9138767cbcd793981daf1e52f3f798198463fbaf36a110bd49908'},
 'docs/audits/address-publication-preparation-20261010/third-model.py.txt': {'bytes': 46815,
                                                                             'lines': 507,
                                                                             'sha256': 'ef4f16f91050e3bd358de7011d5b116bbd064694b62893ec64dea040b06b47e9'},
 'docs/audits/address-publication-preparation-20261010/verify.py': {'bytes': 17330,
                                                                    'lines': 204,
                                                                    'sha256': '1183b76c5a80ec28688f65e42f0fb87700e9602465de7a0ccfb9742f23927cd3'},
 'docs/audits/address-publication-preparation-20261010/verify_schema_repair.py': {'bytes': 3450,
                                                                                  'lines': 58,
                                                                                  'sha256': '0acccc851cefd6c95b2de8722da842bee3cd5946a81ca901fb87d5f9af791425'}}
ACTUAL_CONTRACTS = {'prerequisite': {'command': ['scripts/run_with_ram_guard.sh',
                              '--',
                              'python3',
                              '-B',
                              'docs/audits/address-parent-acceptance-20261010/verify.py'],
                  'instruments': {'docs/audits/address-parent-acceptance-20261010/verify.py': {'bytes': 9987,
                                                                                               'sha256': '4768b6a8368c0a4642ee42d85ebc6aad82f2ab7b27abae2570a68efe0ceee0a7'},
                                  'docs/audits/address-publication-preparation-20261010/checks.py': {'bytes': 1418,
                                                                                                     'sha256': '7a2dd738b697b48b964889080da95048e60b178d26885738794c09f32ff0f349'},
                                  'scripts/run_with_ram_guard.sh': {'bytes': 10663,
                                                                    'sha256': '0af775e059ce409f24b9c853b4cd8b097941472fff70c700d4715adbd0c62541'}},
                  'stdout': 'PASS complete unchanged finite raw/numerical parent acceptance; whole original '
                            'associations and fresh prerequisite readers qualify; address container and '
                            'canonical publication remain open.\n'},
 'schema-repair': {'command': ['scripts/run_with_ram_guard.sh',
                               '--',
                               'python3',
                               '-B',
                               'docs/audits/address-publication-preparation-20261010/verify_schema_repair.py'],
                   'instruments': {'docs/audits/address-publication-preparation-20261010/checks.py': {'bytes': 1418,
                                                                                                      'sha256': '7a2dd738b697b48b964889080da95048e60b178d26885738794c09f32ff0f349'},
                                   'docs/audits/address-publication-preparation-20261010/verify_schema_repair.py': {'bytes': 3450,
                                                                                                                    'sha256': '0acccc851cefd6c95b2de8722da842bee3cd5946a81ca901fb87d5f9af791425'},
                                   'scripts/run_with_ram_guard.sh': {'bytes': 10663,
                                                                     'sha256': '0af775e059ce409f24b9c853b4cd8b097941472fff70c700d4715adbd0c62541'}},
                   'stdout': 'PASS repaired first-admission root/card/scope/review/beforeimage contracts '
                             'reject without a prior seal; all original inputs conserve.\n'},
 'snapshot-closed-schema': {'command': ['scripts/run_with_ram_guard.sh',
                                        '--',
                                        'python3',
                                        '-B',
                                        'docs/audits/address-publication-preparation-20261010/verify.py',
                                        '--snapshot'],
                            'instruments': {'docs/audits/address-publication-preparation-20261010/checks.py': {'bytes': 1418,
                                                                                                               'sha256': '7a2dd738b697b48b964889080da95048e60b178d26885738794c09f32ff0f349'},
                                            'docs/audits/address-publication-preparation-20261010/verify.py': {'bytes': 17330,
                                                                                                               'sha256': '1183b76c5a80ec28688f65e42f0fb87700e9602465de7a0ccfb9742f23927cd3'},
                                            'scripts/run_with_ram_guard.sh': {'bytes': 10663,
                                                                              'sha256': '0af775e059ce409f24b9c853b4cd8b097941472fff70c700d4715adbd0c62541'}},
                            'stdout': 'PASS complete retained source/proposition/question/probe/authority '
                                      'and actual-result preparation; non-growing proposal only, current '
                                      'canonical publication remains pending.\n'},
 'source-model': {'command': ['scripts/run_with_ram_guard.sh',
                              '--',
                              'python3',
                              '-B',
                              'docs/audits/address-source-integration-20261010/verify.py'],
                  'instruments': {'docs/audits/address-publication-preparation-20261010/checks.py': {'bytes': 1418,
                                                                                                     'sha256': '7a2dd738b697b48b964889080da95048e60b178d26885738794c09f32ff0f349'},
                                  'docs/audits/address-source-integration-20261010/verify.py': {'bytes': 17671,
                                                                                                'sha256': '8c5d0e9a0dd31a356695e054c8a0638163346d603ddfa70581e55c48310e59fa'},
                                  'scripts/run_with_ram_guard.sh': {'bytes': 10663,
                                                                    'sha256': '0af775e059ce409f24b9c853b4cd8b097941472fff70c700d4715adbd0c62541'}},
                  'stdout': 'PASS complete source role/graph/lifetime integration; original raw/native and '
                            'governed publication remain open.\n'},
 'verify-closed-schema': {'command': ['scripts/run_with_ram_guard.sh',
                                      '--',
                                      'python3',
                                      '-B',
                                      'docs/audits/address-publication-preparation-20261010/verify.py'],
                          'instruments': {'docs/audits/address-publication-preparation-20261010/checks.py': {'bytes': 1418,
                                                                                                             'sha256': '7a2dd738b697b48b964889080da95048e60b178d26885738794c09f32ff0f349'},
                                          'docs/audits/address-publication-preparation-20261010/verify.py': {'bytes': 17330,
                                                                                                             'sha256': '1183b76c5a80ec28688f65e42f0fb87700e9602465de7a0ccfb9742f23927cd3'},
                                          'scripts/run_with_ram_guard.sh': {'bytes': 10663,
                                                                            'sha256': '0af775e059ce409f24b9c853b4cd8b097941472fff70c700d4715adbd0c62541'}},
                          'stdout': 'PASS complete retained source/proposition/question/probe/authority and '
                                    'actual-result preparation; non-growing proposal only, current canonical '
                                    'publication remains pending.\n'}}

GUIDE = '''Original address roles now have a separate complete finite qualification.
Every own visible reference number joins its simultaneous source and holder
domain. Explicit aliases agree; qualified distinctions differ. Active
`main::call_api` retains the saved CODE handle through lexical `$operation`.
CODE/CODE comparisons remain opaque. A consistent renaming can preserve the
finite relation, but still fails the separate original-byte association check.

For example, repeated occurrences of an explicit alias must retain one reference
number within that source domain. Distinct qualified holders must retain distinct
numbers there. Equal-looking CODE displays, regex displays and hidden arguments
provide no missing referent, payload, flag or native identity. The finite join
does not establish cross-call or cross-capture reuse, heap lifetime or cold cost.

The coordinate-era and preparation paragraphs retain their dated checkpoint
roles. Current core, helper, parser and tooling cards now admit the reviewed
address proposal together. Exact beforeimages, every prior question and replay
command remain retrievable under unchanged collection authority. The maintained
reader authenticates the complete admitted preparation, source/holder/numerical
inputs and actual independent results before and after current verification.
Authentication is not a fresh semantic reconstruction or original recapture.

Replay the complete dated raw/source/numerical parent qualification separately:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-parent-acceptance-20261010/verify.py
```

Current verification still derives every canonical source, direct and cached
question allocation, physical capacity and copied source. Its native variant
also checks the rendered current guidance. The original private/provider/
formatter, external/native/CODE/Regexp identity, cross-call/capture reuse, heap,
cold and visual scopes remain separately owned. Full unchanged address-container
acceptance now qualifies through fresh complete semantic readers and independent
whole original/proposed/current reconstruction. Only finite address nodes close;
full raw-stack joining is next. HIAL and full CI/push gates stay open.

'''

REFERENCE = '''Current finite address roles are now admitted in all four reviewed facts.
The preceding coordinate publication is a retained checkpoint; its next-address
statement describes that earlier frontier. Source/holder alias and distinction
relations and original reference-number association now qualify together, while
native lifetime, CODE/CODE, regex/hidden/external identity and cross-call/capture
reuse retain their explicit limits.

Use the maintained current reader and native build command above. It preserves
the historical success stream while authenticating every admitted preparation
member, complete dated prerequisite inputs and actual typed successful results.
Whole current canonical sources, global direct/cache question ownership, exact
source history, unchanged capacity and rendered guidance remain distinct checks.
Certificate authentication supplies no fresh semantic recapture. Unrelated
qualified canonical progress remains permitted.

The complete prospective preparation remains replayable in its dated role:

```sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-publication-preparation-20261010/verify.py --snapshot
```

The definitive certificate is `final-proof.json`. The first limited proof,
actual first-admission schema false green and repaired exact-reader refusals are
retained without promotion. Explicit independent schema and fixed-source
authority now reject that challenge before any seal. Full unchanged finite
address-container and publication acceptance now qualify together. Fresh complete
source, class/frame, coordinate, operand, holder, numerical and parent readers
join independent original/proposed/current source, question, history, scope and
native reconstruction. Every descendant is complete before its parent closes.
Earlier address paragraphs describe retained checkpoints; their then-open scopes
do not replace this current frontier. Full raw-stack joining is next;
private/downstream/alias/cold/visual/HIAL and full CI/push retain their owners.

Replay the complete dated closure independently of later current progress:

```sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-current-closure-20261010/verify.py
```

The dated replay authenticates its complete retained actual results. Run the
maintained current reader above to establish current source and native currency.
Neither mode recaptures original executions or supplies native object identity.

'''


def require(ok, cause):
    if not ok:
        raise ValueError(cause)


def pin(raw):
    return {'bytes': len(raw), 'lines': raw.count(b'\n'),
            'sha256': hashlib.sha256(raw).hexdigest()}


def same(left, right):
    return json.dumps(left, sort_keys=True, allow_nan=False) == json.dumps(right, sort_keys=True, allow_nan=False)


def local(path, expected):
    raw = plane.local_read(plane.ROOT / plane.relative(path), expected['bytes'])
    require(same(pin(raw), expected), 'complete admitted address member: ' + path)
    return raw


def proposal():
    return json.loads(local(PROPOSAL, ADMITTED_MEMBERS[PROPOSAL]))


def cards(previous):
    admitted = proposal()
    require(set(previous) == set(admitted['cards']), 'complete predecessor address card population')
    for path, text in previous.items():
        require(same(pin(text.encode()), admitted['cards'][path]['original']['identity']),
                'complete retained predecessor address meanings')
    result = {path: row['text'] for path, row in admitted['cards'].items()}
    require(all(same(pin(text.encode()), admitted['cards'][path]['proposed_identity'])
                for path, text in result.items()), 'complete admitted reviewed address card bytes')
    return result


def guide(previous):
    return previous + GUIDE


def check_actual(actual, role):
    contract = ACTUAL_CONTRACTS[role]
    require(type(actual) is dict and set(actual) == {'command', 'status', 'stdout', 'stderr', 'instruments'},
            'closed complete admitted address actual result')
    require(type(actual['status']) is int and actual['status'] == 0,
            'actual admitted address integer success')
    require(actual['command'] == contract['command'], 'complete admitted address actual command')
    require(type(actual['stdout']) is str and actual['stdout'] == contract['stdout'],
            'complete admitted address actual stdout')
    require(type(actual['stderr']) is str and re.fullmatch(
        r'ram-guard: PID [0-9]+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n',
        actual['stderr']), 'complete admitted address guard stream')
    require(same(actual['instruments'], contract['instruments']),
            'complete admitted address actual instruments')


def authenticate():
    # Fixed code declarations, never a proposed input's schema or locators,
    # authorize parsing and the complete admitted namespace first.
    admitted = {path: local(path, expected) for path, expected in ADMITTED_MEMBERS.items()}
    prepared = json.loads(admitted[PROPOSAL])
    proof = json.loads(admitted[PROOF])
    require(same(proof['proposal'], pin(admitted[PROPOSAL])),
            'definitive complete address preparation proof')
    for name, expected in proof['programmes'].items():
        require(same(pin(admitted[PREPARATION + '/' + name]), expected),
                'complete admitted address qualification programmes')
    for path, expected in prepared['fixed_members'].items():
        retained = prepared['beforeimages'].get(path)
        locator = retained['locator'] if retained else path
        require(not retained or same(retained['identity'], expected),
                'complete original address beforeimage identity')
        local(locator, expected)
    checks = json.loads(admitted[PREPARATION + '/checks.json'])
    for role in ACTUAL_CONTRACTS:
        actual = checks[role]
        check_actual(actual, role)
        if role in prepared['actual_readers']:
            require(same(prepared['actual_readers'][role], actual),
                    'whole admitted address semantic actual result')
    return {'proposal': pin(admitted[PROPOSAL]), 'definitive_proof': pin(admitted[PROOF]),
            'complete_members': {path: pin(raw) for path, raw in admitted.items()},
            'dated_inputs': prepared['fixed_members'],
            'scope': 'Authenticate complete admitted finite source/holder/numerical preparation and actual results; no fresh semantic recapture or native identity.'}
