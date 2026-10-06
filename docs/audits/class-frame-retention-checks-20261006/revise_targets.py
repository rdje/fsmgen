"""Declare reviewed target-only compaction; keep every original source unit."""
import ast
from pathlib import Path

ROOT = Path('docs/audits/record-value-class-frame-retention-20261006')
CHECKS = Path('docs/audits/class-frame-retention-checks-20261006')
REVISIONS = {
 'Original captures retain unchanged-input Storable/alias trials and the full alias run’s downstream mutation/abort.': 'Original Storable/alias trials retain unchanged inputs and the full alias run’s downstream mutation/abort.',
 'Independent copy-intervention models rebuild full input/private typed graphs, readonly copies and detached outputs.': 'Copy-intervention models independently rebuild full input/private typed graphs, readonly copies and detached outputs.',
 'Every copied width joins full raw type, carrier/default/metadata roles, ancestor context and compatible-source set.': 'Every copied width joins full raw type, carrier/default/metadata roles, ancestor context and compatible sources.',
 'The input/private join qualifies whole graph/field/source/context/raw-kind/detachment meanings for captured modes.': 'Input/private joins qualify captured modes’ whole graph/field/source/context/raw-kind/detachment meanings.',
 'Finite source-context models qualify helper/consumer/parser locations, complete parser texts and operation spans, separately from cause/operand truth.': 'Finite context models qualify helper/consumer/parser locations, complete parser texts and operation spans separately from cause/operand truth.',
 'Independent primary models derive each API/helper/parser first cause and acceptance from qualified source inputs.': 'Each API/helper/parser first cause and acceptance derives independently from qualified source inputs.',
 'Direct Value models bind active order and source roles to visible type/scalar footprints.': 'Direct Value active-order/source-role models bind visible type/scalar footprints.',
 'Metadata guard/record-recursion paths qualify, including cycles; list recursion is bound but unexercised.': 'Metadata guards/record recursion, including cycles, qualify; list recursion is bound, unexercised.',
 'Nested Scope/capture/private-root inputs bind the entire source-constructed interface graph, preserving kinds, sharing and cycles.': 'Nested Scope/capture/private-root inputs bind the whole source-built interface graph’s kinds/sharing/cycles.',
 'Source models join nested Value and capture/Scope eval/wrapper paths and visible operand roles.': 'Source models join nested Value/capture/Scope eval/wrapper paths and visible operand roles.',
 'The complete own API join partitions every refusal into source guard/function/visible-role models.': 'Every own API refusal partitions into source guard/function/visible-role models.',
 'Own observer/helper source meanings are canonical in the [observer/helper path card](record-value-original-observer-helper-paths.md).': '[Observer/helper source meanings](record-value-original-observer-helper-paths.md) are canonical.',
 'Full observer/display/private-frame/coordinate/address, consumer, alias/semantic/cold/candidate-parent, hot and host-native meanings remain open; the finite own/public source-frame refinement is below.': 'Full observer/display/private-frame/coordinate/address, consumer, alias/semantic/cold/candidate-parent, hot/host-native meanings stay open.',
 'Reverify retains the complete source chain and separate probe replay.': 'Complete source-chain and separate probe replay remain required.',
 'Observer models join every API/parser operation, eval and installed wrapper with source argument roles.': 'Observer models join every API/parser operation/eval/installed wrapper and source argument roles.',
 'Named helpers preserve complete source graphs and active paths.': 'Named helpers preserve complete source graphs/active paths.',
 'Compiled callback/refuses/helper-wrapper paths bind parameterless operation, source regex-body and label displays; identity and full formatting remain open.': 'Compiled callback/refuses/helper-wrapper paths bind parameterless operation and source regex-body/label displays; identity/full formatting stay open.',
 'The source join binds every helper allocation, full supplied/default inputs, returned argument-building operations and compiled callback/refusal paths through both nested throw phases.': 'Every helper allocation’s full supplied/default inputs, returned argument-building operations and compiled callback/refusal paths join through both nested throw phases.',
 'Source models construct the join before comparing recorded contiguous function order and visible argument roles.': 'Source derivation precedes comparison of recorded contiguous function order and visible argument roles.',
 'Full observer/display/private-frame/native-class/raw-coordinate/address, full subtest/load/framework/quoting/truncation and parser-internal meanings stay open; finite own/public source-frame refinements are separately qualified.': 'Full observer/display/private-frame/native-class/raw-coordinate/address, subtest/load/framework/quoting/truncation and parser-internal meanings stay open.',
 'The complete own source model assigns every original refusal to its authored named subtest body.': 'Complete own source models assign every original refusal to its authored named subtest body.',
 'The observer saves the public Test::More subtest delegate, receives name/body/extra arguments, wraps the callback with the compiled-helper observer and forwards callback arguments to the original body and extra arguments to the saved delegate.': 'The observer saves the public Test::More subtest delegate, receives name/body/extras, wraps the callback with the compiled-helper observer, then forwards callback arguments to the original body and extras to the saved delegate.',
 'Authored original subtests supply no extra arguments.': 'Authored original subtests supply no extras.',
 'Every recorded throw-phase header agrees with empty visible body/own-observer-callback arguments and the authored name/CODE reference kind at the public delegate/own entry.': 'Every recorded throw-phase header agrees with empty visible body/own-observer-callback arguments and authored name/CODE reference kind at public delegate/own entry.',
 'Reference kind does not establish actual callback identity.': 'Reference kind does not prove actual callback identity.',
 'Intervening external framework frames stay opaque observations.': 'External frames between own roles stay opaque observations.',
 'Recorded diagnostic frames contain a require marker with that exact file identifier.': 'Recorded diagnostic frames display a require marker for that exact file identifier.',
 'The marker agrees with the file role; it neither changes the source operator to require nor establishes the formatter.': 'The file marker neither changes the source do operator to require nor proves the formatter.',
 "Necessary installed public POD documents named subtest callbacks/extra arguments, do-file return/error semantics and require's do-file loading mechanism.": "Installed public POD documents named subtest callbacks/extras, do-file returns/errors and require's do-file loading mechanism.",
 'The captured current Perl/Test::More profile is current public-interface evidence; the original framework version remains unmeasured.': 'Captured current Perl/Test::More profile is public-interface evidence; original framework version stays unmeasured.',
 'Original Test::Builder/Test::More headers match authored-name prefixes/CODE kinds and body/delegate/entry/do-load order at every throw phase.': 'Every original Test::Builder/Test::More throw-phase header matches authored-name prefixes/CODE kinds and body/delegate/entry/do-load order.',
 'Custom-output automation must derive an absolute destination from the current root at runtime, check containment/same-volume locality and start with a fresh destination.': 'Custom builds derive a fresh absolute destination from the current root at runtime and check containment/same-volume locality.',
 'Persist repository-relative identity; never change the actual tool argument to avoid recording an absolute path.': 'Persist repository-relative identity; never change the actual argument to avoid recording an absolute path.',
 'The source-view plane links canonical repository files through relative filesystem links and native-safe `.source.txt` addresses.': 'Relative filesystem links connect canonical repository files to native-safe `.source.txt` views.',
 'Terminal `.md` is encoded as `.markdown`: initial `.md.source.txt` served direct asset requests, but native rendered clicks became `.html`.': 'Native clicks rewrote `.md.source.txt` to `.html` despite valid direct requests; encode terminal `.md` as `.markdown`.',
 'Actual href checks qualify the encoding.': 'Actual href checks qualify encoding.',
 'Views preserve complete UTF8 source; embedded Markdown links stay literal text.': 'Views preserve complete UTF8 source with literal Markdown links.',
 'The admitted mdBook0.5.4 prototype serves every selected source and refreshes a controlled visible source outside the book under default native serve.': 'Admitted mdBook0.5.4 serves every selected source; default native serve refreshes a controlled visible source outside the book directory.',
 'Ignored scratch and deliberately parent-ignored visible inputs stay stale, including with extra-watch enabled.': 'Ignored scratch/parent-ignored visible inputs stay stale, even with extra-watch enabled.',
 'Source presence/build success do not prove watcher admission.': 'Presence/build success do not prove watcher admission.',
 'The executed factory checks complete selection, current endpoints/bytes and ignore policy; native output verification also checks every copied source.': 'Executed factory checks complete selection, current endpoints/bytes/ignore policy; native verification checks every copied source.',
 'Published views reflect their latest book build; no universal refresh-time/platform promise applies.': 'Views reflect their latest book build; no universal refresh-time/platform promise applies.',
 '`python3 -B scripts/book_source_references.py --write` regenerates the finite manifest and relative endpoints.': '`python3 -B scripts/book_source_references.py --write` regenerates finite manifest/relative endpoints.',
 'Source/asset paths must stay within this repository and on its volume.': 'Source/asset paths must stay inside this repository on its volume.',
 'No extra chapter or copied prose is added.': 'No extra chapter/copied prose is added.',
 'A source-qualified helper-card extension obstructed original source-plane default replay by invoking the old whole-current helper reader.': 'A source-qualified helper-card extension obstructed original source-plane default’s old whole-current helper call.',
 "The qualified historical adapter changes only that call to the helper reader's existing snapshot mode; every other original predicate/programme/product conserves.": 'The qualified historical adapter changes only that call to existing helper snapshot mode; every other original predicate/programme/product conserves.',
 'The current publication reader checks complete core/helper/tooling meanings and question ownership, unique book guidance, canonical selection/endpoints/bytes/ignore policy, exact current budget and indexed members.': 'Current publication checks complete core/helper/tooling meanings/question ownership, unique book guidance, canonical selection/endpoints/bytes/ignore policy, exact current budget and indexed members.',
 "Native copied bytes need the factory's explicit output check; visual QA remains pending.": 'Explicit factory output checks remain required for native copied bytes; visual QA stays pending.'}
ADDITIONS = {
 'record-value-finite-copy-probe-reader.md': 'Every original nonempty error joins source-inferred class/guard family to complete own/public phase/function/visible-argument roles; empty allocations, contexts and opaque raw bytes conserve. Nested Metadata and new outer Value keep separate class/phase roles, conserving the entire inner operand through catch/interpolation/new throw. Source associations precede new raw intake. Native/private/formatter/encoding/hidden-argument/identity/coordinate/address meanings stay unmeasured or separately owned.',
 'record-value-original-observer-helper-paths.md': 'This finite source-class/frame join binds every operation/helper/authored-body/public/entry/load and visible operand role at each original throw phase. Inherited inner operands stay opaque retained evidence, not formatter/coordinate/address oracles. Class/family/phase/order/argument/population/native-promotion controls preserve predecessor meanings; opaque inner-frame byte changes pass prior own/public predicates but break whole forwarding.'}


def expected_programme():
    raw = (CHECKS / 'first-prepare.py.txt').read_bytes()
    tree = ast.parse(raw); lines = raw.splitlines(keepends=True)
    offsets = [0]
    for line in lines:
        offsets.append(offsets[-1] + len(line))
    replacements, used = [], set()
    for node in ast.walk(tree):
        if isinstance(node,ast.Tuple) and len(node.elts) == 2 and all(isinstance(n,ast.Constant) and type(n.value) is str for n in node.elts):
            value = node.elts[1]
            if value.value in REVISIONS:
                replacements.append((offsets[value.lineno-1] + value.col_offset,offsets[value.end_lineno-1] + value.end_col_offset,repr(REVISIONS[value.value]).encode()))
                used.add(value.value)
        if isinstance(node,ast.Assign) and any(isinstance(n,ast.Name) and n.id == 'ADDITIONS' for n in node.targets):
            for key,value in zip(node.value.keys,node.value.values,strict=True):
                replacements.append((offsets[value.lineno-1] + value.col_offset,offsets[value.end_lineno-1] + value.end_col_offset,repr(ADDITIONS[key.value]).encode()))
    assert used == set(REVISIONS), 'every declared compaction target is genuine'
    for start,end,value in sorted(replacements,reverse=True):
        raw = raw[:start] + value + raw[end:]
    assert raw.count(b'width=78,') == 2, 'only declared prose-wrap widths change'
    raw = raw.replace(b'width=78,',b'width=90,')
    ast.parse(raw)
    return raw


if __name__ == '__main__':
    print(expected_programme().decode(),end='')
