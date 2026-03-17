# CHANGES
This is the persistent technical change history for FSMGen.
## 2026-03-17
### declared connect-by-name failures now say when the declared match is blocked
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so declared `=name` connect-by-name failures now say the declared match is blocked when direction, width, ambiguity, or missing-endpoint evidence prevents the `C4` rule from applying.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the same-name endpoint detail remains in the exception text,
  - and the wording now aligns better with the already-shipped `Convention Blocks` reporting surface.
- Updated [t/24-composition-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/24-composition-connect-by-name.t) and [t/95-composition-connect-by-name-input-fanout.t](/Users/richarddje/Documents/github/fsmgen/t/95-composition-connect-by-name-input-fanout.t) to lock blocked-wording diagnostics across the declared connect-by-name family.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path blocked-wording slice under `R11`.

### explicit-toplink top-port inference failures now say when inference is blocked
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so explicit-toplink-driven undeclared top-port inference failures now say the inference path is blocked when direction, width, or type evidence disagrees.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the explicit-link evidence remains in the exception text,
  - and the wording now aligns better with the already-shipped `Convention Blocks` reporting surface.
- Updated [t/101-composition-explicit-link-implicit-ports.t](/Users/richarddje/Documents/github/fsmgen/t/101-composition-explicit-link-implicit-ports.t) to lock mixed-role, width-mismatch, and type-mismatch blocked diagnostics for explicit-toplink-driven undeclared top-port inference.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path blocked-wording slice under `R11`.

### undeclared inference failure diagnostics now say when convention is blocked
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so undeclared top-input, undeclared top-output, and undeclared same-name internal-carrier inference failures now say those convention-first paths are blocked instead of only saying they cannot choose a width/type/driver.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the conflicting endpoint detail remains in the exception text,
  - and the wording now aligns better with the already-shipped `Convention Blocks` reporting surface.
- Updated [t/97-composition-implicit-multi-child-inputs.t](/Users/richarddje/Documents/github/fsmgen/t/97-composition-implicit-multi-child-inputs.t), [t/98-composition-implicit-multi-child-outputs.t](/Users/richarddje/Documents/github/fsmgen/t/98-composition-implicit-multi-child-outputs.t), and [t/99-composition-implicit-internal-carriers.t](/Users/richarddje/Documents/github/fsmgen/t/99-composition-implicit-internal-carriers.t) to lock blocked-wording failure diagnostics across those three undeclared inference families.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path blocked-wording slice under `R11`.

### plain explicit top-port failure diagnostics now say when convention is blocked
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the plain explicit top-port same-name convention failure paths now say the convention is blocked instead of only implying it.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the existing concrete child-endpoint detail remains in the exception text,
  - and the wording now aligns better with the already-shipped `Convention Blocks` reporting surface.
- Added [t/107-composition-blocked-failure-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/107-composition-blocked-failure-diagnostics.t) to lock blocked-wording failure diagnostics for plain explicit top-input and top-output convention.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the first bounded failure-path blocked-wording slice under `R11`.

### composition provenance now reports blocked convention cases too
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `composition_report` now surfaces the first shipped blocked convention events:
  - explicit child links blocking undeclared top-input inference,
  - explicit child links blocking undeclared top-output inference,
  - and inferred internal carriers staying internal by default.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so non-quiet composition runs now print a `Convention Blocks` section when those blocked events are present.
- This shipped slice stays additive:
  - it builds on the earlier provenance summary plus override summary,
  - it also flows the block count through composition `module_info` and `statistics`,
  - and it leaves the next diagnostics gap mainly on the failure-path wording side.
- Added [t/106-composition-blocked-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/106-composition-blocked-reporting.t) to lock:
  - pipeline-side blocked reporting for explicit child links consuming otherwise-inferable top-interface families,
  - pipeline-side blocked reporting for inferred internal carriers kept internal by default,
  - and CLI blocked-summary output.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the first shipped blocked-case reporting slice under `R11`.

### composition provenance now reports local override events too
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `composition_report` now surfaces the first shipped override events:
  - explicit toplinks overriding same-name top-input convention,
  - explicit toplinks overriding same-name top-output convention,
  - and explicit top outputs re-exporting inferred internal carriers.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so non-quiet composition runs now print a `Convention Overrides` section when those override events are present.
- This shipped slice stays additive:
  - it builds on the earlier provenance summary instead of replacing it,
  - it also flows the override count through composition `module_info` and `statistics`,
  - and it leaves the next diagnostics gap clearly on the “blocked” side.
- Added [t/105-composition-override-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/105-composition-override-reporting.t) to lock:
  - pipeline-side override reporting for explicit toplinks overriding same-name convention,
  - pipeline-side override reporting for explicit top-output re-export of inferred internal carriers,
  - and CLI override-summary output.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this is tracked as a deliberate `R11` reporting slice.

### composition provenance now reaches the result hash and CLI summary
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition runs now produce `composition_report`, including top-port and resolved-link provenance counts grouped from the earlier `origin_kind` metadata.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so non-quiet composition runs now print:
  - the active composition lane,
  - child/top-port/resolved-link/internal-net counts,
  - and top-port / resolved-link provenance counts.
- This shipped slice is intentionally layered on top of the earlier metadata:
  - it does not replace `composition_plan`,
  - it keeps `origin_kind` / `resolved_links` as the lower-level typed source of truth,
  - and it makes that same information visible to both embedding callers and CLI users.
- Added [t/104-composition-provenance-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/104-composition-provenance-reporting.t) to lock:
  - pipeline-facing `composition_report` counts,
  - and CLI-facing provenance summary output.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as a deliberate user-facing transparency slice instead of an incidental print change.

### typed composition plans now surface first-pass provenance metadata
- Updated [perl/FSM/Composition/Port.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Port.pm), [perl/FSM/Composition/Link.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Link.pm), and [perl/FSM/Composition/Plan.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Plan.pm) so typed composition results can now expose provenance explicitly.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm), [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm), and [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) so:
  - top ports expose `origin_kind`,
  - links expose `origin_kind`,
  - and composition plans expose `resolved_links` as the full resolved link set used by planning.
- This shipped slice is intentionally additive:
  - the existing `links` field remains as-is for compatibility,
  - `resolved_links` is the new full planned-link view,
  - and the new provenance values now cover declared explicit ports/links, declared `=name`, inferred passthrough ports/links, explicit-toplink-driven inferred top ports, plain-explicit-port convention links, internal-carrier links/re-exports, and auto system-port links.
- Added [t/103-composition-provenance-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/103-composition-provenance-metadata.t) to lock:
  - parser-side declared provenance,
  - `C1` inferred passthrough provenance,
  - explicit-toplink inferred top-port provenance,
  - and resolved-link provenance for convention and override paths.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as a deliberate transparency contract, not just extra fields.

### explicit-link `C2` / `C3` plain explicit top ports can now reuse same-name convention
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so explicit-link `C2` / `C3` tops may now keep ordinary explicit top-port declarations such as `payload_in<8` or `result_data>8` while still reusing the same-name convention when the child-side evidence stays exact.
- This shipped slice is intentionally bounded:
  - plain explicit top inputs may fan out by same name when compatible child inputs keep one direction plus exact width/type agreement,
  - plain explicit top outputs may adopt one unique same-name top-facing child output when that child-side evidence stays exact,
  - mixed input/output same-name families still flow through the already-shipped internal-carrier rule instead of this new slice,
  - explicit top-boundary links still override that convention locally,
  - mixed-direction plain-input families now fail explicitly,
  - and multi-output plain-output families now fail explicitly.
- Added [t/102-composition-explicit-port-convention.t](/Users/richarddje/Documents/github/fsmgen/t/102-composition-explicit-port-convention.t) to lock:
  - generated-child `C2` success for plain explicit top-input fanout and plain explicit top-output adoption,
  - mixed generated-plus-`?rtl` `C3` success for the same plain-explicit-port convention,
  - mixed-direction rejection for plain explicit top-input convention,
  - and ambiguous same-name output rejection for plain explicit top-output convention.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this now reads as shipped convention-first behavior rather than a future question.

### recorded the current architecture hotspot set for future bounded refactor work
- Saved the current hotspot/refactor snapshot into the live roadmap/continuity docs instead of leaving it as one-off analysis only.
- The recorded future seams are:
  - `FSM::Pipeline::HDLGenerator` still carrying too much composition policy/orchestration/planning surface,
  - `FSM::Synthesis::EnableGraph` still acting as the largest synthesis gravity well,
  - `FSM::HDL::FlattenedDT::Backend::SystemVerilog` still owning too much planning/normalization for a “backend” boundary,
  - the still-implicit bridge between `FSM::CoreAST::*` and `FSM::AST::*`,
  - the unresolved status of `FSM::ExpressionNamer` as either live surface or residue,
  - stale compatibility wording in `bin/fsmgen`,
  - and the global-state shape in `FSM::Debug` ahead of future embedding/API work.
- Updated [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so those seams are now tracked as deliberate future work instead of ambient debt.

### explicit-link `C2` / `C3` can now infer top ports directly from explicit `?toplink`
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so explicit-link tops may now omit `?ports` entirely, or use an empty `(?ports)`, when the missing top boundary can be realized honestly from explicit `?toplink` endpoints themselves.
- This shipped slice is intentionally bounded:
  - it applies to explicit-link `C2` / `C3`,
  - undeclared top endpoints may now be renamed because the explicit links themselves supply the top-boundary names,
  - each undeclared top endpoint still has to keep one consistent direction plus exact width/type agreement across the explicit links that mention it,
  - same-name explicit top-input links still infer the top port declaration without duplicating the already-declared child bindings,
  - and mixed-role undeclared top endpoints still fail explicitly instead of being guessed through.
- Added [t/101-composition-explicit-link-implicit-ports.t](/Users/richarddje/Documents/github/fsmgen/t/101-composition-explicit-link-implicit-ports.t) to lock:
  - generated-child `C2` success with omitted `?ports` and renamed top endpoints,
  - RTL-backed `C3` success with an empty `(?ports)` block and renamed top endpoints,
  - and mixed-role undeclared top-endpoint rejection.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane records this explicit-link omitted/empty-`?ports` slice as shipped behavior.

### explicit-link `C2` / `C3` can now re-export inferred same-name internal carriers through explicit top outputs
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so explicit-link tops can now keep convention-first same-name internal-carrier inference while letting a matching explicit top output adopt and expose that carrier.
- This shipped override is intentionally bounded:
  - it applies only to same-name internal-carrier families that already qualify for inference,
  - the top override must be an output with exact width/type agreement,
  - the carrier still stays internal by default when no such top output is declared,
  - and several same-name child outputs still fail explicitly instead of being guessed through.
- Added [t/100-composition-internal-carrier-top-reexport.t](/Users/richarddje/Documents/github/fsmgen/t/100-composition-internal-carrier-top-reexport.t) to lock:
  - generated-child internal-carrier re-export success in explicit-link `C2`,
  - mixed generated-plus-`?rtl` internal-carrier re-export success in explicit-link `C3`,
  - same-name output ambiguity rejection even with an explicit re-export request,
  - and explicit top-output type-mismatch rejection for re-export.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane records this local-override slice as shipped behavior rather than future intent.

### explicit-link `C2` / `C3` can now infer same-name internal carriers
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so explicit-link tops can now infer internal same-name child-to-child carriers when:
  - no explicit top port of that name exists,
  - no explicit link already touches that name family,
  - exactly one same-name child output remains available,
  - and one or more same-name child inputs remain available.
- This shipped slice is intentionally bounded:
  - it applies to explicit-link `C2` / `C3` tops,
  - inferred carriers stay internal by default instead of being re-exported automatically,
  - and several same-name child outputs still fail explicitly instead of being guessed through.
- Added [t/99-composition-implicit-internal-carriers.t](/Users/richarddje/Documents/github/fsmgen/t/99-composition-implicit-internal-carriers.t) to lock:
  - generated-child internal-carrier fanout success in explicit-link `C2`,
  - mixed generated-plus-`?rtl` internal-carrier success in explicit-link `C3`,
  - and ambiguity rejection for several same-name child outputs feeding the same-name input family.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records this bounded internal-carrier slice honestly.

### explicit-link `C2` / `C3` can now infer undeclared unique top outputs
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so explicit-link tops can now infer undeclared top outputs when:
  - exactly one same-name child output remains top-facing,
  - that child output is not already consumed by explicit child-to-child wiring,
  - and the planner can therefore bind it deterministically back to a generated top output.
- This shipped slice is intentionally bounded:
  - it applies to explicit-link `C2` / `C3` tops,
  - it still does not create internal same-name producer-to-consumer carriers automatically,
  - and several same-name top-facing child outputs still fail explicitly instead of being guessed through.
- Added [t/98-composition-implicit-multi-child-outputs.t](/Users/richarddje/Documents/github/fsmgen/t/98-composition-implicit-multi-child-outputs.t) to lock:
  - inferred undeclared unique top-output success in explicit-link `C2`,
  - inferred undeclared unique top-output success in explicit-link `C3`,
  - and ambiguity rejection for several same-name top-facing child outputs.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records this bounded top-output inference slice honestly.

### future `R11` now records convention-first inference plus local override control
- Updated [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so future composition work is now governed by an explicit convention-over-configuration rule:
  - convention should remain the primary integration path,
  - explicit port/link declarations should override inference locally rather than forcing full parent-interface restatement,
  - and ambiguity diagnostics should say whether a connection was inferred, blocked, or overridden.
- Updated [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this policy is preserved as continuity guidance for future `R11` work rather than left as conversational context only.

### explicit-link `C2` / `C3` can now infer undeclared top inputs
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so explicit-link multi-child tops can now infer undeclared top inputs when:
  - the same-name child ports are all inputs,
  - they agree exactly on width and type metadata,
  - and they are not already consumed by explicit child-to-child links.
- This shipped slice is intentionally bounded:
  - it infers top inputs only,
  - it applies to explicit-link `C2` / `C3` tops,
  - and it does not yet create undeclared top outputs or internal same-name carriers.
- Added [t/97-composition-implicit-multi-child-inputs.t](/Users/richarddje/Documents/github/fsmgen/t/97-composition-implicit-multi-child-inputs.t) to lock:
  - inferred undeclared shared top-input success in explicit-link `C2`,
  - and width-mismatch rejection for undeclared shared top-input inference.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records this bounded multi-child inference slice honestly.

### single-child `C1` can now infer the top interface when `?ports` is omitted or empty
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the single-child `C1` composition lane now accepts either:
  - no `?ports` block at all,
  - or an empty `(?ports)` block,
  - and in that bounded case infers the top interface directly from the lone realized child interface.
- The shipped inference is intentionally narrow:
  - it works only for single-child passthrough,
  - it covers generated children and external `?rtl` children,
  - and it does not yet widen into multi-child inferred carriers or broader undeclared top-interface inference.
- Added [t/96-composition-implicit-single-child-ports.t](/Users/richarddje/Documents/github/fsmgen/t/96-composition-implicit-single-child-ports.t) to lock:
  - omitted-`?ports` single-child `?fsmc` passthrough inference,
  - and empty-`?ports` single-child `?rtl` passthrough inference.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records this first undeclared-top-interface slice honestly.

### future `R11` now includes a portable synthesizable-type and inference-first lane
- Updated [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) so `R11` now carries a concrete future sub-lane for portable synthesizable scalar/aggregate types instead of leaving that topic as informal brainstorming.
- The saved future contract now records:
  - a portable type core built around bits/vectors, enums, records, fixed-size arrays, arrays of records, and aliases/subtypes,
  - a strong convention-over-configuration preference for inferring scalar versus aggregate signal and port types from LHS/RHS/member/index usage,
  - a future explicit syntax centered on `(+types ...)`,
  - and phased implementation boundaries from type AST and explicit declarations through inference, member access, exact-type aggregate assignment, and backend-specific conversion helpers.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the future type/inference lane is tracked as explicit `R11` work rather than remembered conversationally only.

### declared top-input `=name` now fans out across matching child inputs
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so declared connect-by-name is now direction-asymmetric at the top boundary:
  - `=name` top outputs still require exactly one matching child output,
  - `=name` top inputs now fan out to all matching child inputs with the same name and width,
  - and mixed-direction or width-mismatched same-name candidates now fail explicitly instead of being ignored.
- Added [t/95-composition-connect-by-name-input-fanout.t](/Users/richarddje/Documents/github/fsmgen/t/95-composition-connect-by-name-input-fanout.t) to lock:
  - top-input fanout success across multiple same-name child inputs,
  - and mixed-direction same-name rejection for declared top-input connect-by-name.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now describes the asymmetric by-name rule honestly.

### declared connect-by-name `C4` now covers multi-generated-plus-`?rtl` tops too
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `C4` no longer stops after one generated child when external RTL already participates in the by-name plan. The active `C4` contract now accepts one or more generated children, one or more `?rtl` children, or any mixture of those generated and external RTL children under the same exact-match rule.
- Added [t/94-composition-multi-generated-plus-rtl-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/94-composition-multi-generated-plus-rtl-connect-by-name.t) to lock the first multi-generated-plus-`?rtl` declared connect-by-name `C4` success path.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records the broader `C4` truthfully.

### explicit-link `C3` now covers multi-generated-plus-`?rtl` tops too
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `C3` no longer stops after one generated child whenever external RTL already participates in the explicit-link plan. The active `C3` contract now requires at least one `?rtl` child and otherwise allows any number of generated children (`?fsmc` / `?dtc`) beside those RTL children.
- Added [t/93-composition-multi-generated-plus-rtl-children.t](/Users/richarddje/Documents/github/fsmgen/t/93-composition-multi-generated-plus-rtl-children.t) to lock the first multi-generated-plus-`?rtl` explicit-link `C3` success path.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records the broader `C3` truthfully.

## 2026-03-16
### declared connect-by-name `C4` now covers multi-`?rtl` tops too
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `C4` no longer stops at one external RTL child. The active declared-by-name contract now accepts either:
  - one or more `?rtl` children,
  - or exactly one generated child (`?fsmc` or `?dtc`) plus one or more `?rtl` children.
- Added [t/92-composition-multi-rtl-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/92-composition-multi-rtl-connect-by-name.t) to lock:
  - pure multi-`?rtl` declared connect-by-name success,
  - one-generated-plus-multi-`?rtl` declared connect-by-name success,
  - and ambiguous multi-`?rtl` by-name rejection.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records the broadened `C4` truthfully.

### explicit-link `C3` now covers multi-`?rtl` tops too
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `C3` no longer stops at one external RTL child. The active explicit-link contract now accepts either:
  - one or more `?rtl` children,
  - or exactly one generated child (`?fsmc` or `?dtc`) plus one or more `?rtl` children.
- Added [t/91-composition-multi-rtl-children.t](/Users/richarddje/Documents/github/fsmgen/t/91-composition-multi-rtl-children.t) to lock:
  - pure multi-`?rtl` explicit-link success,
  - and one-generated-plus-multi-`?rtl` explicit-link success.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records the broadened `C3` truthfully.

### single external `?rtl` child composition now has a first shipped `R11` slice
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so a lone `?rtl` child is no longer rejected as “not enough generated children”.
- Shipped behavior now includes:
  - `C1` passthrough tops with one external `?rtl` child and exact same-name top exposure,
  - `C3` explicit-toplink tops with one external `?rtl` child and renamed top ports,
  - and `C4` declared connect-by-name tops with one external `?rtl` child.
- Added [t/90-composition-single-rtl-child.t](/Users/richarddje/Documents/github/fsmgen/t/90-composition-single-rtl-child.t) to lock the single-`?rtl` `C1`, `C3`, and `C4` success paths, and updated [t/13-composition-source-classification.t](/Users/richarddje/Documents/github/fsmgen/t/13-composition-source-classification.t) so the “no children” boundary now names `?rtl` honestly too.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records this bounded single-RTL broadening explicitly.

### embedded `?rtlif` roots now have a first shipped `R11` slice
- Updated [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so external RTL children can realize their interface from an embedded `(?rtlif:module_name ...)` companion root in the same composition source.
- Shipped behavior now includes:
  - embedded same-file `?rtlif` metadata taking precedence over sidecar `<module>.rtlif` files,
  - mixed generated-child plus `?rtl` composition succeeding without a separate sidecar file when that local interface root exists,
  - and explicit rejection of duplicate embedded `?rtlif` roots for the same RTL module name.
- Added [t/89-composition-embedded-rtlif-roots.t](/Users/richarddje/Documents/github/fsmgen/t/89-composition-embedded-rtlif-roots.t) to lock embedded-root precedence, no-sidecar mixed composition success, and duplicate embedded-root rejection.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records embedded `.rtlif` interface roots as shipped behavior.

### typed `.rtlif` ports now have a first deliberate `R11` contract slice
- Updated [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) so sidecar RTL metadata now accepts typed default-input tokens such as `core_clk:clock` and `rst_async_n:reset` in addition to the earlier compact forms.
- The shipped `.rtlif` contract now includes:
  - one flat `(?rtlif:module_name ...)` root,
  - declaration-ordered port tokens,
  - compact tokens like `clk`, `data_in<8`, and `txd>`,
  - typed tokens like `core_clk:clock`, `rst_async_n:reset`, and `data_in<8:data`,
  - and explicit type annotations limited to `data`, `clock`, and `reset`.
- Mixed generated-child plus external RTL composition now auto-wires custom-named RTL system ports honestly when their `.rtlif` metadata marks them as `:clock` or `:reset`.
- Added [t/88-rtlif-typed-port-contract.t](/Users/richarddje/Documents/github/fsmgen/t/88-rtlif-typed-port-contract.t) to lock:
  - direct typed-token parsing,
  - custom named RTL system-port auto-wiring,
  - and rejection of unsupported explicit `.rtlif` type names.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records the `.rtlif` mini-contract as shipped behavior instead of only a future note.

### mixed generated-child plus external RTL declared connect-by-name now has a first shipped `R11` slice
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition-facing child interface direction now prefers semantic `signal_role` over the older name-based output heuristic when building realized child interfaces.
- Shipped behavior now includes:
  - declared `=name` success for mixed one-generated-child plus one-`?rtl` tops,
  - mixed `C4` tops that combine explicit child-to-child `?toplink` wiring with by-name top exposure,
  - and correct standalone-DT child input classification for RHS-only signals such as `payload_in`.
- Added [t/87-composition-mixed-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/87-composition-mixed-connect-by-name.t) to lock mixed `?fsmc` + `?rtl` success, mixed `?dtc` + `?rtl` success, and cross-kind same-name ambiguity rejection.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records that mixed `C4` slice explicitly.

### single-child declared connect-by-name now has a first shipped `R11` slice
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so declared `=name` connect-by-name no longer starts only beyond the single-child passthrough case.
- Shipped behavior now includes:
  - one generated child (`?fsmc` or `?dtc`) with declared by-name top input/output binding,
  - the same exact same-name, same-direction, same-width matching rule as the broader `C4` lane,
  - and honest non-system interfaces for combinational standalone-DT children in that single-child by-name lane too.
- Added [t/86-composition-single-child-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/86-composition-single-child-connect-by-name.t) to lock single-child `?fsmc` and `?dtc` declared connect-by-name success through pipeline and CLI.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records that bounded `C4` extension explicitly.

### composition-facing standalone-DT children now have a first shipped `R11` slice
- Updated [perl/FSM/Composition/Spec.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Spec.pm), [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm), and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition now accepts `?dtc:instance child_source` as a generated-child kind beside `?fsmc`.
- Shipped behavior now includes:
  - embedded `?dt:name` child realization,
  - external searchable `.fsm` standalone-DT child realization,
  - mixed generated-child composition across `?fsmc` / `?dtc`,
  - mixed `?dtc` plus `?rtl` composition,
  - and honest realized child interfaces for purely combinational DT modules without fake `clk` / `rst_n` ports.
- Added [t/85-composition-standalone-dt-children.t](/Users/richarddje/Documents/github/fsmgen/t/85-composition-standalone-dt-children.t) and extended [t/14-composition-parser.t](/Users/richarddje/Documents/github/fsmgen/t/14-composition-parser.t) to lock:
  - typed `?dtc` parsing,
  - embedded combinational `?dtc` success,
  - mixed `?fsmc` + `?dtc` success,
  - and external `?dtc` plus `?rtl` success through `--path`.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records the first composition-facing standalone-DT child slice.
### external composition child FSM reuse now has a first shipped `R11` slice
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `?top:name` now realizes `?fsmc` children from either:
  - embedded child FSM sources in the same file,
  - or external searchable `.fsm` child sources.
- External `?fsmc` child lookup now checks beside the composition source first, then repeated `--path DIR` roots, then `FSMLIB`, then the current directory.
- Added [t/84-composition-external-fsm-child-sources.t](/Users/richarddje/Documents/github/fsmgen/t/84-composition-external-fsm-child-sources.t) to lock:
  - sibling external child-source realization,
  - `--path`-driven multi-file child realization,
  - and `--path` precedence over `FSMLIB` for `?fsmc` child lookup.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records the first broader reusable-root/reference follow-up beyond bare top-level inputs and `.rtlif`.
### reusable-source lookup now has a first shipped `R11` slice
- Added [perl/FSM/SourcePathResolver.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/SourcePathResolver.pm) so explicit search-root handling is no longer hardcoded independently in the CLI and composition metadata loader.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen), [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm), and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so:
  - the CLI now accepts repeatable `--path DIR`,
  - bare `.fsm` input lookup searches explicit `--path` roots before `FSMLIB`,
  - and external `.rtlif` metadata lookup now uses the same explicit roots ahead of `FSMLIB`.
- Added [t/83-reusable-source-path-resolution.t](/Users/richarddje/Documents/github/fsmgen/t/83-reusable-source-path-resolution.t) to lock:
  - bare standalone-DT input lookup through `--path`,
  - `--path` precedence over `FSMLIB`,
  - and `--path`-driven external RTL metadata lookup for the current composition lane.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so `R11` now records the first shipped reusable-source lookup slice instead of leaving lookup as roadmap-only intent.
### first `R11` standalone `?dt:name` slice is now shipped
- Updated [perl/FSM/SourceClassifier.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/SourceClassifier.pm), [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm), [perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm), [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm), [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm), and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the live toolchain now recognizes and generates standalone `?dt:name` roots end to end.
- The active shipped `?dt:name` contract now includes:
  - top-level general DT blocks such as `(-foo ...)`,
  - directive sections `(+size ...)`, `(+constants ...)`, `(+enums ...)`, `(+define ...)`, and `(+params ...)`,
  - compact top-level `(:= signal=value)` directives,
  - implicit `clk` / `rst_n` only when the `?dt:name` source contains sequential assignments,
  - default output exposure for driven non-intermediate targets,
  - and no encoded `current_state` / `next_state` plan.
- Added [t/82-standalone-dt-root-support.t](/Users/richarddje/Documents/github/fsmgen/t/82-standalone-dt-root-support.t) to lock both combinational and sequential `?dt:name` generation paths.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so `R11` now tracks a live shipped slice instead of pure future notes.
### malformed `:=` directive shapes now have explicit end-to-end coverage
- Added [t/81-language-contract-init-directive-shape-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/81-language-contract-init-directive-shape-boundary.t) so the malformed-shape side of the active top-level `:=` family is now locked explicitly:
  - malformed non-scalar payloads such as `(:= (tester_reset=1 extra))`,
  - malformed compact directives such as `(:= BROKEN)`,
  - and parser, pipeline, and CLI entry points all fail without emitting HDL for those malformed forms.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live contract now says the `:=` family is bounded on both the malformed-RHS side and the malformed-payload/shape side.
### reset-naming continuity now distinguishes current `?fsm` residue from future/default convention
- Refined [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), and [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) so the wording now says this explicitly:
  - current shipped explicit `(?fsm:name ... (+system ...))` compatibility residue still spells `rstn`,
  - but the forward/default async-reset convention remains `rst_n`,
  - including the implicit no-`+system` path and the planned `?top:name` / sequential `?dt:name` lanes.
- Updated [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) to preserve that distinction in continuity notes too.
### non-conventional `+system` reset names now have explicit coverage
- Added [t/80-language-contract-system-reset-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/80-language-contract-system-reset-name-boundary.t) to lock the reset-name side of the conventional `+system` family:
  - `(sreset reset)`,
  - and `(asreset reset_async_n)`.
- The same file also locks pipeline and CLI no-output behavior for those malformed reset-name cases, and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now names both rejected reset-name variants explicitly.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live contract accounting stays aligned.
### malformed `+system` entry structures now have explicit coverage
- Added [t/79-language-contract-system-section-structure-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/79-language-contract-system-section-structure-boundary.t) to lock the malformed-entry-structure side of the conventional `+system` family:
  - scalar entries like `BROKEN` inside `(+system ...)`,
  - and wrong-arity entries like `(clock clk extra)`.
- The same file also locks pipeline and CLI no-output behavior for those malformed `+system` structures, and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents that malformed-entry-structure rule explicitly too.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live contract accounting stays aligned.
### malformed symbol-definition identifier and scalar-token cases now have full coverage
- Added [t/78-language-contract-symbol-definition-token-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/78-language-contract-symbol-definition-token-boundary.t) to lock the token-validity side of the symbol-definition family:
  - bad identifiers in `+constants`, `+define`, and `+params`,
  - and non-scalar member values in `+enums`.
- The same file also locks pipeline and CLI no-output behavior for those malformed token cases, so the symbol-definition family is no longer fully end-to-end only for malformed shapes while leaving identifier/scalar-token validation implicit.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) to keep the live contract accounting aligned.
### malformed ordinary RHS expression forms now have full entrypoint coverage
- Added [t/77-language-contract-expression-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/77-language-contract-expression-entrypoints.t) to lock pipeline and CLI no-output behavior for the malformed side of ordinary RHS expressions:
  - unsupported operators such as `(bogus B C)`,
  - malformed active-operator arity such as `(== B)`,
  - and guard-only tokens such as `<start` in ordinary RHS expression position.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the malformed ordinary-expression family is now tracked as end-to-end across parser, pipeline, and CLI instead of parser-covered only.
### malformed symbol-definition sections now have full entrypoint coverage
- Added [t/76-language-contract-symbol-definition-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/76-language-contract-symbol-definition-entrypoints.t) to lock pipeline and CLI no-output behavior for the malformed side of:
  - `+constants`,
  - `+define`,
  - and `+params`.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the symbol-definition family is now tracked as end-to-end across parser, pipeline, and CLI instead of having that deeper coverage only for malformed `+enums`.
### inline compound modifiers now have an explicit active boundary
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so the inline compound-modifier family is now explicit instead of partly accidental:
  - bare inline `(+=)` and `(-=)` remain supported as delta-`1` variants,
  - malformed payloads such as `(+= 2 3)` now fail explicitly instead of silently truncating,
  - and duplicate inline modifiers such as `(+= 2) (-= 1)` now fail through a targeted duplicate-modifier boundary instead of falling through a bare-suffix error.
- Added [t/75-language-contract-inline-compound-modifier-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/75-language-contract-inline-compound-modifier-boundary.t) to lock supported bare inline modifiers plus parser/pipeline/CLI rejection for malformed and duplicate inline modifier forms.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active contract and continuity notes now describe both the supported and malformed sides of that family.
### future `R11` conflict-detection note now records the naming split from the saved response
- Refined [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the saved future `R11` conflict-detection direction now also records the naming/reporting split:
  - per-value-source overlap signals such as `P_Q_multi_src_conflict`,
  - and whole-target overlap signals such as `P_multi_value_conflict`.
### future `R11` shared-drive notes now prefer assertion bits over default arbitration
- Refined [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the future shared-datapath lane now says:
  - do not auto-resolve or auto-prioritize same-target conflicts by default,
  - generate per-`(P, Q)` onehot0-style assertion bits over source enables such as `A_P_Q_en`, `B_P_Q_en`, and `C_P_Q_en`,
  - and generate whole-target `P` assertion bits that detect multiple value families becoming active in the same cycle.
- Updated [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the saved `R11` direction now preserves “detect/report through assertions” instead of “prevent/resolve by default”.
### future `R11` reusable-DT and shared-drive notes were refined again
- Refined [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the future reusable standalone-DT lane now also says:
  - `?dt:name` may contain any number of internal general DT blocks such as `(-foo ...)`,
  - `?fsm:name` keeps implicit `clk` / `rst_n`,
  - `?dt:name` gets implicit `clk` / `rst_n` only when at least one sequential assignment exists,
  - and standalone DT arbitration should be expressed through generated enable families rather than a blanket structural conflict ban.
- Refined the same roadmap notes so the future shared-datapath lane now distinguishes:
  - same-target/same-value aggregation,
  - from same-target/different-value conflicts,
  - and records that multiple FSMs must not drive different values to the same target `P` in the same cycle unless a later explicit priority contract is added.
- Updated [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so those refined `R11` rules are preserved in continuity notes too.
### roadmap v2 now includes a reusable standalone-DT/module-library sub-lane under `R11`
- Updated [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) so `R11` now also carries one concrete bounded future lane for reusable standalone module roots:
  - `?dt:name` as the smallest standalone module description,
  - standalone DT modules allowed to mix combinational and sequential outputs,
  - root-family naming follow-up around `?top:name`, `?mod:name`, and `?module:name`,
  - and reusable-source lookup through `FSMLIB` plus repeatable `--path DIR` CLI roots.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so that future lane is now tracked as explicit `R11` contract work instead of loose brainstorming only.
### implicit no-`+system` generation now uses one centralized `clk` / `rst_n` contract
- Added an explicit module-level effective-system accessor in [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm) so clock/reset naming is defined once and referenced by generation paths instead of being hardcoded independently.
- Updated [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm), [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm), and [perl/FSM/Backend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Backend.pm) so:
  - FSMs without `+system` now generate with implicit `clk` / `rst_n`,
  - explicit conventional `+system` still keeps the declared `clk` / `rstn` pair,
  - and composition child realization/auto-wiring now follows the effective child system ports instead of assuming `rstn`.
- Added [t/74-language-contract-implicit-system-defaults.t](/Users/richarddje/Documents/github/fsmgen/t/74-language-contract-implicit-system-defaults.t) to lock:
  - standalone implicit default generation,
  - explicit `+system` override behavior,
  - and single-child composition realization with implicit `rst_n`.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the contract and continuity notes now say plainly that the implicit default is `clk` / `rst_n`.
### duplicate `+system` declarations are now regression-backed explicitly
- Added [t/73-language-contract-system-section-duplicate-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/73-language-contract-system-section-duplicate-boundary.t) to lock the duplicate-declaration side of the conventional `+system` family:
  - duplicate `(clock clk)` entries are rejected explicitly,
  - duplicate reset declarations are rejected explicitly,
  - and mixed `(sreset rstn)` plus `(asreset rstn)` is also rejected as a duplicate reset declaration.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the conventional `+system` contract now states “exactly one clock declaration and exactly one reset declaration” explicitly.
### shared-datapath `R11` note now captures default top-export versus peer-read internalization
- Refined [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the future shared-datapath lane now says:
  - outputs from child FSMs or the shared datapath block are top-level outputs by default,
  - peer-read registered outputs become top-internal by default,
  - explicit user direction is needed to re-export those now-internal registered signals,
  - and combinational outputs remain illegal as peer-FSM read sources, which keeps that rule consistent with the new internalization rule.
- Updated [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the same refined export/internalization rule is preserved in the continuity notes.
### shared-datapath `R11` note now uses the “written by at least two FSMs” rule
- Refined [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the future shared-datapath lane is now explicit about the ownership split:
  - outputs assigned in at least two child FSMs are the shared-datapath candidates,
  - outputs assigned in only one child FSM are not shared and remain directly child-owned.
- Updated [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the same rule is preserved in the continuity notes.
### roadmap v2 now includes a concrete shared-datapath composition sub-lane under `R11`
- Updated [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) so `R11` now includes one concrete bounded future composition lane:
  - multi-FSM top generation from one `.fsm` source or several `.fsm` sources,
  - optional lifting of selected child-owned targets into one shared datapath block,
  - deterministic per-child drive-intent enable families such as `A_P_Q_en`,
  - registered-output loopback rules,
  - and the saved rule that combinational outputs must not become cross-FSM read sources.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this direction is now tracked as an explicit future `R11` contract lane instead of loose brainstorming only.
## 2026-03-15
### malformed `+system` boundaries now have pipeline and CLI coverage too
- Added [t/72-language-contract-system-section-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/72-language-contract-system-section-entrypoints.t) to lock pipeline and CLI no-output behavior for:
  - non-conventional `+system` clock names like `(clock core_clk)`,
  - unsupported `+system` entries like `(areset rstn)`,
  - and incomplete `+system` sections.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the malformed side of the conventional `+system` family is now tracked as an end-to-end entrypoint boundary instead of parser-only coverage.
### legacy generic/template placeholder boundaries now have pipeline and CLI coverage too
- Added [t/71-language-contract-generic-placeholder-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/71-language-contract-generic-placeholder-entrypoints.t) to lock pipeline and CLI no-output behavior for:
  - legacy placeholder selectors such as `?[READ]`,
  - legacy repeat macros such as `?repeat:[MAX_COUNT]`,
  - and legacy placeholder tokens such as `[DATAIN]`.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the legacy generic/template placeholder family is now tracked as an end-to-end entrypoint boundary instead of parser-only coverage.
### unsupported top-level `+...` directive boundaries now have pipeline and CLI coverage too
- Added [t/70-language-contract-top-level-directive-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/70-language-contract-top-level-directive-entrypoints.t) to lock pipeline and CLI no-output behavior for:
  - unknown top-level `+` directives like `(+bogus ...)`,
  - and unsupported future-style top-level directives like `(+clock clk)`.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the unsupported top-level `+...` directive family is now tracked as an end-to-end entrypoint boundary instead of parser-only coverage.
### malformed test-selector boundaries now have pipeline and CLI coverage too
- Added [t/69-language-contract-test-selector-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/69-language-contract-test-selector-entrypoints.t) to lock pipeline and CLI no-output behavior for:
  - bare symbolic test selectors like `(BUSY ...)`,
  - and bare numeric test selectors like `(0 ...)`.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the malformed test-selector family is now tracked as an end-to-end entrypoint boundary instead of parser-only coverage.
### malformed test-branch boundaries now have pipeline and CLI coverage too
- Added [t/68-language-contract-test-branch-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/68-language-contract-test-branch-entrypoints.t) to lock pipeline and CLI no-output behavior for:
  - empty test-node branches like `(?MODE (=0))`,
  - and single malformed test-branch bodies that still omit a nested action.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the malformed test-branch family is now tracked as an end-to-end entrypoint boundary instead of parser-only coverage.
### bare condition-suffix boundaries now have pipeline and CLI coverage too
- Added [t/67-language-contract-condition-suffix-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/67-language-contract-condition-suffix-entrypoints.t) to lock pipeline and CLI no-output behavior for:
  - bare assignment condition suffixes like `(A <= B start)`,
  - and bare transition condition suffixes like `(-> busy full)`.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the malformed bare-suffix family is now tracked as an end-to-end entrypoint boundary instead of parser-only coverage.
### malformed action-family boundaries now have pipeline and CLI coverage too
- Added [t/66-language-contract-malformed-action-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/66-language-contract-malformed-action-entrypoints.t) to lock pipeline and CLI no-output behavior for:
  - single-token malformed DT actions like `(BROKEN)`,
  - and empty guarded blocks like `(<req)`.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the malformed-action family is now tracked as an end-to-end entrypoint boundary instead of parser-only coverage.
### malformed legacy `+fsm` root bodies are now regression-backed explicitly
- Added [t/65-language-contract-plus-fsm-body-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/65-language-contract-plus-fsm-body-boundary.t) to lock the malformed-body side of the already-shipped legacy `+fsm` root family:
  - explicit rejection of empty `(+fsm plus_empty)` roots,
  - explicit rejection of scalar body items like `(+fsm plus_scalar BROKEN)`,
  - and pipeline/CLI no-output behavior for those malformed legacy roots.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the live top-level source contract now calls out the legacy `+fsm` body boundary explicitly too.
### malformed structured `?fsm` root bodies now fail through an explicit boundary
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so structured `?fsm:name` roots now require a non-empty top-level item list and reject scalar top-level body items explicitly instead of relying on incidental later-stage fallout.
- Added [t/64-language-contract-fsm-root-body-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/64-language-contract-fsm-root-body-boundary.t) to lock:
  - explicit rejection of empty structured roots like `(?fsm:empty_root)`,
  - explicit rejection of scalar top-level items like `(?fsm:scalar_root BROKEN)`,
  - and pipeline/CLI no-output behavior for those malformed structured roots.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the top-level source contract now documents the structured-root body boundary explicitly.
### bare top-level FSM content now fails through an explicit source-root boundary
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so unwrapped top-level FSM content now fails through a dedicated source-root diagnostic instead of the old generic “expected `?fsm:name` or `+fsm`” parser error.
- Added [t/63-language-contract-source-root-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/63-language-contract-source-root-boundary.t) to lock:
  - explicit rejection of bare top-level forms like `(+system ...)` and `(idle ...)`,
  - classifier truth for files that stay outside the active source-root family,
  - and pipeline/CLI no-output behavior for those malformed roots.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the top-level source contract now documents the unwrapped-root boundary explicitly.
### malformed update-shorthand tails now fail through an explicit boundary
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so update shorthand now rejects stray extra positional tail payloads through a dedicated update-shorthand-tail diagnostic instead of leaking them through the generic suffix-guard boundary.
- Added [t/62-language-contract-update-shorthand-tail-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/62-language-contract-update-shorthand-tail-boundary.t) to lock:
  - continued support for valid guarded forms like `(+= counter 4 <start)`,
  - explicit rejection of malformed tails like `(+= counter 4 3)` and `(+= counter 4 3 2)`,
  - and pipeline/CLI no-output behavior for those malformed forms.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the update-shorthand family now documents its trailing-tail boundary explicitly.
### malformed update-shorthand targets now fail explicitly instead of disappearing silently
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so recognized update-shorthand forms now reject malformed non-scalar targets through a dedicated update-shorthand diagnostic instead of returning `undef` and disappearing from the DT body.
- Added [t/61-language-contract-update-shorthand-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/61-language-contract-update-shorthand-boundary.t) to lock:
  - malformed targets such as `(++ (counter))` and `(+= (byte_count) 4)`,
  - and pipeline/CLI no-output behavior for malformed update-shorthand forms.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the update-shorthand family now documents its malformed-target boundary explicitly.
### alternate compound-update shorthand spellings are now part of the active contract
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) so the active update-shorthand family now documents the already-supported separated spellings:
  - `(+= sig)` / `(-= sig)` as delta-`1` forms,
  - `(+= sig N)` / `(-= sig N)` as separated delta-carrying forms,
  - alongside the previously documented `++`, `--`, `+=N`, and `-=N` spellings.
- Added [t/60-language-contract-update-shorthand-variants.t](/Users/richarddje/Documents/github/fsmgen/t/60-language-contract-update-shorthand-variants.t) to lock:
  - separated delta-`1` update forms,
  - separated delta-carrying update forms,
  - and end-to-end HDL generation for those alternate spellings.
- Updated the support snapshot in [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) and continuity notes in [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live contract now matches the shipped parser truthfully.
### unsupported assignment operators now fail through an explicit contract boundary
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so unsupported assignment operators now surface through a dedicated user-facing assignment-operator diagnostic instead of a raw internal parser `confess`.
- Added [t/59-language-contract-assignment-operator-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/59-language-contract-assignment-operator-boundary.t) to lock:
  - explicit rejection of unsupported operators such as `?=` and `=>`,
  - and pipeline/CLI no-output behavior for malformed assignment forms.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the active assignment-operator family and its malformed boundary are now documented explicitly.
### malformed guard shorthand and inline comparison tokens now fail through explicit boundaries
- Updated [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) so malformed guard shorthand payloads and malformed inline comparison tokens now surface through their dedicated contract diagnostics instead of falling through to generic unsupported-expression-token errors.
- Added [t/58-language-contract-condition-expression-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/58-language-contract-condition-expression-boundary.t) to lock:
  - malformed guard shorthand payloads such as `mode=` and `==3`,
  - malformed inline comparison tokens such as `cnt[2:1]!=` and `=3`,
  - and pipeline/CLI no-output behavior for both malformed families.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the active contract now documents both malformed boundaries explicitly.
### delayed-pulse `<N` RHS values now fail through an explicit contract boundary
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so malformed delayed-pulse RHS values now surface through a clean user-facing contract diagnostic instead of raw internal parser messages.
- Added [t/57-language-contract-pulse-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/57-language-contract-pulse-boundary.t) to lock:
  - explicit rejection of malformed delayed-pulse RHS values such as `B` and `2'0`,
  - and pipeline/CLI no-output behavior for malformed delayed-pulse assignments.
- Updated [t/04-assignment-edge-cases.t](/Users/richarddje/Documents/github/fsmgen/t/04-assignment-edge-cases.t), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the active pulse boundary is described and checked consistently.
### `:=` reset/default RHS values now fail through the dedicated init contract
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so malformed `:=` RHS values now surface through the dedicated init/reset boundary instead of leaking raw expression-parser failures.
- Added [t/56-language-contract-init-directive-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/56-language-contract-init-directive-boundary.t) to lock:
  - explicit rejection of unsupported RHS reset/default values such as `[DATAIN]` and `<start`,
  - and pipeline/CLI no-output behavior for malformed `:=` RHS values.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the active `:=` contract now documents the malformed-RHS boundary explicitly.
### computed test selectors now have an explicit malformed-boundary contract
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so computed test selectors must start with a real selector expression and include at least one branch instead of falling through to incidental parser/expression failures.
- Added [t/55-language-contract-computed-test-selector-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/55-language-contract-computed-test-selector-boundary.t) to lock:
  - rejection of missing-expression computed selectors such as `(? (=0 ...))`,
  - rejection of branchless computed selectors such as `(?(| A B))`,
  - and pipeline/CLI no-output behavior for those malformed forms.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the active `?(expr)` boundary is documented explicitly on both the success and malformed sides.
### plain `?SIG` test-node signal names now have an explicit boundary
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so plain test nodes now require `?signal_name` with an HDL-identifier-compatible signal name, while keeping computed selectors `?(expr)` on their existing supported path.
- Added focused regression coverage in [t/54-language-contract-test-signal-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/54-language-contract-test-signal-name-boundary.t) for:
  - successful parsing/generation of a conventional `?SIG` test node,
  - explicit rejection of malformed plain test-node signal names like `?bad-name` and `?0`,
  - and pipeline/CLI confirmation that malformed plain test-node signal names do not emit HDL.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the live contract now states the plain-`?SIG` naming rule explicitly.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### transition targets now have an explicit active boundary
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so state transitions are now validated explicitly:
  - target names must be HDL-identifier-compatible,
  - target names must refer to a declared regular FSM-state DT block inside the same FSM source,
  - and malformed/unknown transition targets now fail before they can leak into `STATE_*` HDL generation.
- Added focused regression coverage in [t/53-language-contract-transition-target-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/53-language-contract-transition-target-boundary.t) for:
  - successful parsing/generation with declared forward transition targets,
  - explicit rejection of malformed target names like `bad-name`,
  - explicit rejection of non-state targets like `-comb`,
  - explicit rejection of unknown targets like `missing_state`,
  - and pipeline/CLI confirmation that unknown targets do not emit HDL.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the live contract now states the transition-target rule explicitly.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### state and DT block names now have an explicit active boundary
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so state/DT names are now validated explicitly:
  - regular FSM-state DT names must be HDL-identifier-compatible,
  - general/combinational DT names must use exactly one leading `-` plus an HDL-identifier-compatible base name,
  - and reset-state names remain limited to the existing supported reset spellings.
- Added focused regression coverage in [t/52-language-contract-state-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/52-language-contract-state-name-boundary.t) for:
  - successful parsing/generation with valid regular and standalone DT names,
  - explicit rejection of malformed regular state names like `bad-name`,
  - explicit rejection of malformed standalone DT names like `-bad-name` and `--bad`,
  - and pipeline/CLI confirmation that malformed state names do not emit HDL.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the live contract now states the state/DT naming rule explicitly.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### malformed symbol-definition sections now fail explicitly
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so the symbol-definition family no longer relies on loose Perl list unpacking for malformed input:
  - `+constants` now requires a non-empty list of `(NAME scalar_value)` entries,
  - `+define` now requires exactly one `(NAME scalar_value)` pair,
  - `+params` now requires a non-empty list of `(NAME scalar_value)` entries,
  - and `+enums` now requires a non-empty list of `(enum_name (MEMBER value) ...)` definitions with at least one member per enum.
- Added focused regression coverage in [t/51-language-contract-symbol-definition-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/51-language-contract-symbol-definition-boundary.t) for:
  - empty symbol-definition sections,
  - malformed section payloads and malformed entry/member shapes,
  - and pipeline/CLI confirmation that malformed symbol-definition sections do not emit HDL.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the live contract now states the malformed-boundary rules explicitly.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### `+size` now has an explicit active contract
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so `+size` is now parsed through an explicit contract helper instead of being partially ignored:
  - the legacy empty form `(+size)` remains supported as a no-op,
  - valid `(signal width)` entries still register widths,
  - malformed payloads and malformed entries now fail with targeted diagnostics.
- Added focused regression coverage in [t/50-language-contract-size-section-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/50-language-contract-size-section-boundary.t) for:
  - successful parsing/generation with legacy empty `(+size)`,
  - explicit rejection of malformed `+size` payloads like `(+size BROKEN)`,
  - explicit rejection of malformed entries like `(A)`,
  - explicit rejection of non-positive widths like `(A 0)`,
  - and pipeline/CLI confirmation that malformed `+size` sections do not emit HDL.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the live contract now states the `+size` boundary explicitly.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### empty or scalar-only state/DT bodies now fail explicitly
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so state/DT blocks must contain at least one real nested decision-tree body or action form instead of being accepted as empty pseudo-states.
- Added focused regression coverage in [t/49-language-contract-state-body-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/49-language-contract-state-body-boundary.t) for:
  - empty FSM-state DT blocks like `(idle)`,
  - empty general/combinational DT blocks like `(-misc)`,
  - and pipeline/CLI confirmation that these malformed blocks no longer emit HDL.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the live language contract now states that state/DT blocks need a real body.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### general/combinational DT blocks now have an explicit standalone contract
- Updated [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm) so `FSM::CoreAST::State` now exposes `is_standalone_dt` and treats standalone DTs through explicit state-role semantics instead of only inferring them from the leading hyphen in the name.
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so hyphen-prefixed non-reset DT blocks now parse with `state_type => standalone_dt`.
- Added focused regression coverage in [t/48-language-contract-standalone-dt-classification.t](/Users/richarddje/Documents/github/fsmgen/t/48-language-contract-standalone-dt-classification.t) for:
  - explicit `standalone_dt` AST classification,
  - exclusion of general/combinational DT blocks from the encoded-state plan,
  - and DT-style enable emission for those blocks.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the live language contract now states that general/combinational DT blocks are explicitly standalone DTs, not accidental pseudo-states.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### tagged source names now have an explicit whole-name boundary
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so top-level `?fsm:module_name` roots now validate the whole source name and reject malformed names like `?fsm:bad-name` explicitly instead of truncating to `bad`.
- Updated [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm) so top-level `?top:top_name` roots and embedded composition child sources like `?fsm:source_name` now also validate the whole source name instead of truncating malformed names silently.
- Added focused regression coverage in [t/47-language-contract-source-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/47-language-contract-source-name-boundary.t) for:
  - malformed top-level `?fsm:bad-name` roots,
  - malformed top-level `?top:bad-name` roots,
  - and malformed embedded composition child sources like `?fsm:bad-name`.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the live contract now states the tagged source-name rule explicitly.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### legacy `+fsm` roots now have an explicit contract boundary
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so the legacy `+fsm` source family is now validated explicitly before module-name decoding:
  - accepted:
    - the flattened sibling layout with a first top-level `(+fsm module_name)` entry followed by sibling sections and state/DT blocks
    - the nested legacy root layout `(+fsm module_name ...)`
  - rejected: malformed `+fsm` roots without a scalar module name
- Added focused regression coverage in [t/46-language-contract-flat-plus-fsm-root.t](/Users/richarddje/Documents/github/fsmgen/t/46-language-contract-flat-plus-fsm-root.t) for:
  - source classification of `+fsm`,
  - direct adapter parsing of both shipped legacy layouts,
  - pipeline and CLI generation for both valid paths,
  - and explicit parser/pipeline/CLI rejection of malformed `+fsm` roots.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the live language contract now describes the real legacy `+fsm` family truthfully.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### user-facing DT-versus-state terminology is now sharper
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) so the supported-language section now uses the more precise user-facing distinction:
  - both `(aState ...)` and `(-foobar ...)` are decision trees,
  - `(aState ...)` is an FSM-state DT,
  - `(-foobar ...)` is a general/combinational DT block.
- Updated [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this terminology choice is preserved for future wording and roadmap work.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task.
### reset-state spellings now have a real supported contract
- Updated [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm) so `FSM::CoreAST::State` now preserves `state_type` and exposes `state_type`, `is_reset_state`, and `is_regular_state`, instead of silently dropping reset-state classification metadata.
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so:
  - `-syncrst` and `-syncreset` now normalize to the same `syncreset` reset-state identity,
  - `-asyncrst` and `-asyncreset` now normalize to the same `asyncreset` reset-state identity,
  - and the top-level FSM parser now accepts those legacy long spellings as part of the same reset-state family.
- Updated [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm), [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm), and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so reset-state blocks are treated as DT-like blocks instead of regular encoded states.
- Added focused regression coverage in [t/45-language-contract-reset-state-spellings.t](/Users/richarddje/Documents/github/fsmgen/t/45-language-contract-reset-state-spellings.t) for:
  - canonical and legacy reset-state spelling normalization,
  - exclusion of reset-state blocks from the encoded-state plan,
  - and DT-style enable emission for reset-state blocks.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the live language contract now describes the reset-state family truthfully.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### n-ary relational operators are now part of the active contract
- Updated [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) so the active operator family now executes the previously saved broader contract instead of documenting only part of it:
  - n-ary relational operators such as `(< low mid high)` and `(== a b c d)` now lower as adjacent-pair comparison chains,
  - relational aliases such as `eq`, `ne`, `lt`, `le`, `gt`, and `ge` now lower to their canonical comparison operators,
  - unary alias `not` now lowers to `!`,
  - and malformed supported-operator arity is now checked against the new contract (`!` requires exactly one operand; the infix-style families require at least two).
- Updated [perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm) so parser-created intermediate expression signals now contribute their driving-AST source signals to interface-role analysis, which keeps inputs like `low`, `mid`, and `high` live in generated modules instead of hiding them behind the intermediate name alone.
- Added focused regression coverage in [t/44-language-contract-relational-operators.t](/Users/richarddje/Documents/github/fsmgen/t/44-language-contract-relational-operators.t) for:
  - n-ary relational chains,
  - relational aliases,
  - unary alias `not`,
  - guarded-block use of chained relational expressions,
  - and emitted HDL input visibility for parser-generated relational intermediates.
- Updated [t/40-language-contract-expression-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/40-language-contract-expression-boundary.t) so malformed comparison arity is still locked now that `(== a b c)` is a supported form; the active rejection case is now `(== a)`.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the live contract and continuity notes now match the executable operator-arity boundary truthfully.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### unsupported top-level bare forms now fail explicitly
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so unsupported top-level bare forms inside `(?fsm:name ...)` now fail explicitly instead of being skipped silently.
- Added focused regression coverage in [t/43-language-contract-top-level-form-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/43-language-contract-top-level-form-boundary.t) for:
  - future-looking bare init syntax like `(tester_reset := 1)`,
  - malformed bare scalar forms like `(BROKEN 1)`,
  - and pipeline/CLI confirmation that these forms do not disappear silently or emit HDL output.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the active contract now states that directive sections, `:=` init/reset directives, and state/DT blocks are the only supported top-level forms inside `(?fsm:name ...)`.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### test-node selectors now require explicit operator prefixes
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so test-node branches now require explicit operator-prefixed selector tokens such as `=0`, `=OTHER`, `!=8'0`, or `>8'3`, instead of accepting malformed bare selectors implicitly.
- Updated [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) so runtime lowering enforces the same selector boundary for direct AST callers.
- Added focused regression coverage in [t/42-language-contract-test-selector-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/42-language-contract-test-selector-boundary.t) for:
  - explicit rejection of bare symbolic selectors like `BUSY`,
  - explicit rejection of bare numeric selectors like `0`,
  - and continued support for explicit symbolic equality selectors like `=OTHER`.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the active test-node contract now states the explicit-selector rule plainly.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### unsupported tagged top-level sources now fail explicitly
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so unsupported tagged top-level source kinds such as `?define:legacy_template` now fail explicitly before the nested-`?fsm` fallback can parse inner FSM content accidentally.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the active pipeline and CLI reject the same tagged-source boundary directly instead of relying on later parser fallout.
- Added focused regression coverage in [t/41-language-contract-top-level-source-kind-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/41-language-contract-top-level-source-kind-boundary.t) for:
  - source classification,
  - direct adapter rejection,
  - pipeline rejection,
  - and CLI rejection without emitted HDL output.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the active contract now calls out unsupported tagged top-level source roots explicitly.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### unsupported expression forms now fail explicitly
- Updated [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) so unsupported expression forms no longer drift through soft parser fallthrough:
  - real inline scalar comparison tokens such as `cnt[2:1]!=2'2` now parse as comparison ASTs explicitly instead of relying on accidental fallback behavior,
  - unknown operators such as `(bogus B C)` now fail explicitly,
  - malformed active-operator arity such as `(== B C D)` now fails explicitly,
  - empty expression lists and unsupported expression payload types now fail explicitly,
  - and guard-only tokens like `<start` now fail when used in ordinary RHS expression position.
- Added focused regression coverage in [t/40-language-contract-expression-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/40-language-contract-expression-boundary.t) for:
  - supported inline scalar comparison tokens,
  - unsupported RHS operators,
  - malformed RHS operator arity,
  - and invalid RHS scalar tokens.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the active contract now documents this as an explicit rejection boundary instead of leaving it implicit.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### shorthand guard comparisons are now active and regression-backed
- Updated [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) so guarded blocks and suffix guards now lower the shorthand family explicitly instead of treating only the old equality form as special:
  - `(<foo ...)` now means `foo != 0`
  - `(<!foo ...)` now means `foo == 0`
  - `(<foo=value ...)` and `(<foo==value ...)` mean equality
  - `(<foo!=value ...)`, `(<foo<value ...)`, `(<foo<=value ...)`, `(<foo>value ...)`, and `(<foo>=value ...)` now lower to their matching comparison ASTs
- Added focused regression coverage in [t/39-language-contract-guard-shorthand.t](/Users/richarddje/Documents/github/fsmgen/t/39-language-contract-guard-shorthand.t) for shorthand guarded blocks, shorthand suffix guards, and emitted HDL comparisons.
- Updated [t/29-language-contract-core-forms.t](/Users/richarddje/Documents/github/fsmgen/t/29-language-contract-core-forms.t) so the existing core guard/suffix regression now expects explicit comparison ASTs for `<foo` and `<!foo`.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the active contract now treats the shorthand guard family as supported instead of future-only.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### future placeholder syntax direction was saved
- Updated [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) to preserve the current design conclusion for any future generic/template lane:
  - prefer `$(VAR)` as the canonical placeholder syntax,
  - allow `$VAR` only as optional sugar if that lane is ever implemented,
  - and do not reuse `<VAR>` because `<...` is already reserved for guarded-block and suffix-guard syntax.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`.
### legacy generic placeholder forms now fail explicitly
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so legacy generic/template placeholder selectors such as `?[READ]` and repeat macros such as `?repeat:[MAX_COUNT]` now fail with targeted diagnostics instead of drifting into ordinary `?sig` parsing.
- Updated [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) so placeholder tokens such as `[DATAIN]` or `[?size: ...]` now fail explicitly instead of being registered as ordinary signal names in the active parser.
- Added focused regression coverage in [t/38-language-contract-generic-placeholder-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/38-language-contract-generic-placeholder-boundary.t) for:
  - placeholder selectors like `?[READ]`,
  - repeat macros like `?repeat:[MAX_COUNT]`,
  - and placeholder tokens like `[DATAIN]`.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) so the legacy generic/template placeholder family is now called out explicitly in the out-of-support bucket.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so `R8` tracking reflects that one more parser-visible legacy family is now explicitly rejected instead of ambiguously accepted.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
- Validation:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm` (pass)
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm` (pass)
  - `perl -I perl -c t/38-language-contract-generic-placeholder-boundary.t` (pass)
  - `prove -I perl t/38-language-contract-generic-placeholder-boundary.t` (pass)
### computed test selectors now synthesize real intermediate wires end to end
- Updated [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) so parser-created computed-selector signals marked as intermediate remain visible to later dependency and filtering passes instead of being dropped by AST-factorization heuristics.
- Updated [perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm) so `?(expr)` test nodes now analyze the selector signal's driving AST as well as the synthetic selector signal itself, which keeps the underlying selector inputs live in the generated interface.
- Added focused regression coverage in [t/37-language-contract-computed-test-selector.t](/Users/richarddje/Documents/github/fsmgen/t/37-language-contract-computed-test-selector.t) for:
  - the computed-selector form `(?(| A B) ...)`,
  - intermediate condition-signal capture in phase 1,
  - live input exposure for the selector source signals,
  - and emitted HDL that declares and drives the computed-selector wire before branch comparisons reuse it.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) so the active test-node contract now includes the computed-selector form `?(expr)` explicitly instead of describing only `?SIG`.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so `R8` tracking reflects that one more real parser/runtime-visible construct family is now both documented and regression-backed.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
- Validation:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm` (pass)
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c t/37-language-contract-computed-test-selector.t` (pass)
  - `prove -I perl t/12-enablegraph-capture-registry.t t/37-language-contract-computed-test-selector.t` (pass)
### relational test-node selectors are now explicit and regression-backed
- Updated [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) so `?sig` selector branches now lower relational selectors with their actual comparison operators instead of collapsing the active selector family to equality-only behavior.
- Added focused regression coverage in [t/36-language-contract-test-branch-selectors.t](/Users/richarddje/Documents/github/fsmgen/t/36-language-contract-test-branch-selectors.t) for:
  - `!=` selector lowering,
  - `>` selector lowering,
  - `<=` selector lowering,
  - both captured condition ASTs and emitted HDL text.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) so the active test-node contract now documents the broader shipped selector family explicitly instead of describing only equality selectors.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so `R8` done/left tracking reflects that the selector family is now both truthfully documented and regression-backed.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c t/36-language-contract-test-branch-selectors.t` (pass)
  - `prove -I perl t/36-language-contract-test-branch-selectors.t` (pass)
### malformed empty test-node branches now fail explicitly
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so malformed empty `?sig` / case-style test branches now fail with a targeted diagnostic instead of leaking through a generic internal `undef` action path.
- Added focused regression coverage in [t/35-language-contract-test-branch-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/35-language-contract-test-branch-boundary.t) for:
  - empty branches such as `(?MODE (=0))`,
  - and mixed test nodes where one branch is valid and another branch is empty.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) so the active test-node contract now says explicitly that each branch requires a selector plus at least one nested action, and malformed empty branches are now called out in the out-of-support bucket.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so `R8` done/left tracking reflects the removal of this generic parser-failure path from the test-node family.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
- Validation:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm` (pass)
  - `perl -I perl -c t/35-language-contract-test-branch-boundary.t` (pass)
  - `prove -I perl t/35-language-contract-test-branch-boundary.t` (pass)
### top-level `:=` is now explicit, and malformed DT actions now fail explicitly
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so top-level `:=` is now an explicit init/reset directive that records reset/default metadata for the target signal, while malformed decision-tree actions and empty guarded blocks no longer disappear silently during parsing.
- Added focused regression coverage in [t/34-language-contract-malformed-actions.t](/Users/richarddje/Documents/github/fsmgen/t/34-language-contract-malformed-actions.t) for:
  - supported top-level `:=` directive parsing,
  - malformed single-token DT action rejection,
  - malformed `:=` directive rejection,
  - and empty guarded-block rejection.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) so the active `:=` boundary is documented explicitly, malformed action forms and empty guarded blocks are now explicitly called out in the out-of-support bucket, and the guarded-block contract now says plainly that a guarded block must contain at least one action.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so `R8` done/left tracking reflects both the explicit `:=` support slice and the removal of this silent parser-drop path. [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) also now preserves the future-syntax discussion for `(:= (lhs value))` and `(lhs := value)`.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
- Validation:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm` (pass)
  - `perl -I perl -c t/34-language-contract-malformed-actions.t` (pass)
  - `prove -I perl t/34-language-contract-malformed-actions.t` (pass)
### bare condition suffixes now fail explicitly
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so bare suffix tails no longer slip through as implicit positive conditions in assignment or transition suffix positions.
- Added focused regression coverage in [t/33-language-contract-condition-suffix-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/33-language-contract-condition-suffix-boundary.t) for:
  - bare assignment suffix rejection,
  - and bare transition suffix rejection.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) so the suffix-guard contract now says plainly that active suffix guards must use explicit `<...` / `<!...` forms and that bare tails such as `(A <= B start)` are out of support.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so `R8` done/left tracking reflects the removal of this implicit legacy guard path.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
- Validation:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm` (pass)
  - `perl -I perl -c t/33-language-contract-condition-suffix-boundary.t` (pass)
  - `prove -I perl t/33-language-contract-condition-suffix-boundary.t` (pass)
### unsupported top-level `+...` directives now fail explicitly
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so unsupported top-level `+...` directive sections no longer drift into fake state parsing and now fail with a targeted diagnostic that lists the supported top-level directive family.
- Added focused regression coverage in [t/32-language-contract-top-level-directive-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/32-language-contract-top-level-directive-boundary.t) for:
  - unknown directive sections such as `(+bogus ...)`,
  - and future-looking but currently unsupported directive spellings such as `(+clock clk)`.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) so unsupported top-level directive sections are now explicitly called out in the out-of-support bucket instead of being left implicit.
- Updated [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) to preserve the syntax-namespace rationale from the latest language discussion:
  - why `(?foo:...)` exists,
  - why the `+...` family exists,
  - and why any future redesign should be treated as a family-level syntax decision rather than as a one-off `+system` rename.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so `R8` done/left tracking reflects the landed explicit-rejection slice.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
- Validation:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm` (pass)
  - `perl -I perl -c t/32-language-contract-top-level-directive-boundary.t` (pass)
  - `prove -I perl t/32-language-contract-top-level-directive-boundary.t` (pass)
### conventional `+system` contract slice is now live and regression-backed
- Promoted the conventional `+system` declaration into the active supported-language boundary in [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md):
  - `(+system (clock clk) (sreset rstn))`
  - `(+system (clock clk) (asreset rstn))`
- Added focused regression coverage in [t/31-language-contract-system-section.t](/Users/richarddje/Documents/github/fsmgen/t/31-language-contract-system-section.t) for:
  - accepted conventional `+system` parsing,
  - explicit rejection of non-conventional clock names,
  - explicit rejection of unsupported system directives,
  - and explicit rejection of incomplete `+system` sections.
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so the parser now validates the current `+system` contract explicitly instead of silently ignoring `+system`, and now records:
  - default clock domain `clk`,
  - default reset domain `rstn`,
  - and typed system signals for `clk` and `rstn`.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so `R8` done/left tracking reflects the landed `+system` slice.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
- Validation:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm` (pass)
  - `perl -I perl -c t/31-language-contract-system-section.t` (pass)
  - `prove -I perl t/31-language-contract-system-section.t` (pass)
### `R8` symbol-definition contract slice is now live and regression-backed
- Promoted the symbol-definition families into the active supported-language boundary in [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md):
  - `(+constants ...)`,
  - `(+enums ...)`,
  - `(+define ...)`,
  - `(+params ...)`.
- Added focused regression coverage in [t/30-language-contract-symbol-definitions.t](/Users/richarddje/Documents/github/fsmgen/t/30-language-contract-symbol-definitions.t) for:
  - symbol-summary counts,
  - RHS literal resolution,
  - and guard equality resolution through the active parser/generator path.
- Fixed the parser-side scalar-unwrapping bug in [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so the current Lispish AST packing for `+constants`, `+define`, `+params`, and enum member values is handled consistently instead of leaking `undef` into scalar-expression parsing.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so `R8` done/left tracking reflects the landed symbol-definition slice.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
- Validation:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm` (pass)
  - `perl -I perl -c t/30-language-contract-symbol-definitions.t` (pass)
  - `prove -I perl t/30-language-contract-symbol-definitions.t` (pass)
## 2026-03-14
### first `R8` language-contract slice is now live and regression-backed
- Promoted the first `R8` draft normative language-contract slice into [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md).
- The live supported-language boundary now explicitly includes:
  - nested guarded blocks,
  - condition suffixes,
  - compound update shorthand,
  - inline compound modifiers,
  - and the currently regression-backed broader operator-expression families.
- Added focused regression coverage in [t/29-language-contract-core-forms.t](/Users/richarddje/Documents/github/fsmgen/t/29-language-contract-core-forms.t) for:
  - guarded blocks and suffix guards,
  - shorthand and inline updates,
  - and broader operator lowering.
- Hardened two small warning paths exposed by the new regression:
  - [perl/FSM/ExpressionNamer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/ExpressionNamer.pm) now guards undefined legacy expression/signal strings,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) now debug-renders driving ASTs without avoidable warning noise.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so `R8` done/left tracking reflects the landed first contract slice.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
- Validation:
  - `perl -I perl -c perl/FSM/ExpressionNamer.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/29-language-contract-core-forms.t` (pass)
### long-term horizon goals are now captured in roadmap v2
- Extended [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) with an explicit long-term horizon section.
- The roadmap now records two long-term goals:
  - `H1` Rust FSMGen,
  - `H2` a beautiful, dynamic public project website.
- The saved gating rule is explicit:
  - first make FSMGen state-of-the-art, rock solid, and really stable through the active `R8`..`R13` work,
  - only then treat the Rust implementation or public website as serious execution lanes.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so this horizon is visible in both live roadmap context and continuity docs.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task.
- Validation:
  - `git diff --check` (pass)
### roadmap v2 is now opened and `R8` is the active lane
- Added [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) as the detailed companion roadmap for the post-`R0`..`R7` workstreams.
- Refreshed [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so roadmap generation `v2` is now active, while `R0` through `R7` remain the closed foundation workstreams from the completed first roadmap.
- The live board now defines and tracks:
  - `R8` language-contract hardening,
  - `R9` strict mode and support-tier enforcement,
  - `R10` source provenance and diagnostics,
  - `R11` composition contract strengthening,
  - `R12` regression corpus and support accounting,
  - `R13` public embedding/API stabilization,
  - `R14` VHDL backend, if still wanted.
- Updated [README.md](/Users/richarddje/Documents/github/fsmgen/README.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so onboarding and continuity now point at the new roadmap structure directly.
- Live roadmap status change:
  - the current active lane moved from `none` to `R8`,
  - `R8` is now `in progress`,
  - `R9` through `R14` are now explicit roadmap workstreams and currently `not started`.
- Validation:
  - `git diff --check` (pass)
### future operator-form RHS design direction is now preserved
- Extended [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) with the current working direction for `(6)` operator-form RHS expressions.
- The saved direction now states:
  - combinational and sequential assignments should share the same RHS expression grammar,
  - operator aliases should lower to canonical operators,
  - infix-style operator families should be treated as unlimited-ary wherever their semantics can be explained deterministically,
  - unlimited-ary `+`, `*`, `&`, `|`, and `^` use explicit fold semantics,
  - unlimited-ary `-`, `/`, and `%` use left-associative left-fold semantics,
  - chained relational operators use adjacent-pair conjunction, for example `(< a b c)` means `((a < b) && (b < c))`,
  - and any allowed operator form must have an explicit unambiguous interpretation with examples.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task.
- Validation:
  - `git diff --check` (pass)
### future language-design agreements for `(3)`, `(4)`, and `(5)` are now preserved
- Saved the current design agreements in [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) for:
  - guarded blocks `(3)`,
  - condition suffixes `(4)`,
  - and update shorthand `(5)`.
- The saved agreement set now states:
  - guarded blocks are first-class,
  - nesting is unlimited,
  - nested guards compose by logical `AND`,
  - `<foo` and `<!foo` are shorthand for non-zero and zero tests,
  - relational shorthand such as `<foo==3` lowers to the same guarded-block semantics,
  - condition suffixes have exactly the same semantics as guarded blocks and desugar to a single guarded action,
  - and update shorthand captures increment/decrement semantics for multi-bit register/flop targets.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task.
- Validation:
  - `git diff --check` (pass)
### post-roadmap improvement priorities are now preserved in engineering notes
- Saved the suggested post-`R0`..`R7` improvement order in [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) as candidate future workstreams rather than as live roadmap items.
- The saved recommendation order is:
  - language-contract hardening,
  - strict mode/support-tier enforcement,
  - diagnostics/provenance,
  - composition-contract strengthening,
  - regression corpus/support accounting,
  - public embedding/API stabilization,
  - and VHDL only after the contract work above.
- The notes also preserve the specific gray-zone cluster that should be resolved first in any future roadmap.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task.
- Validation:
  - `git diff --check` (pass)
### user guide now contains a live supported-constructs boundary for `.fsm`
- Expanded [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) with a new live section, `Currently supported .fsm constructs (live reference)`.
- The new section distinguishes three things explicitly:
  - what is fully supported right now,
  - what is implemented but not yet strong enough to present as fully regression-backed,
  - and what is explicitly out of active support.
- The guide now calls out standalone decision-tree blocks such as `(-alpha_dt ...)`, `(-misc ...)`, and `(-mycombit ...)` as part of the active supported surface, with the current runtime behavior stated plainly:
  - DT-only inputs are supported,
  - and they generate without a state-register plan.
- Tightened the top-level composition wording in the guide so it now says composition is implemented in a deliberately narrow shipped model rather than "partially implemented", which better matches the closed scoped `R6` boundary.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task.
- Validation:
  - `git diff --check` (pass)
### `R7` closed with the shipped source-frontier hook
- Extended [perl/FSM/Extension/Context.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Context.pm) so hook contexts now carry:
  - `stage`,
  - and `raw_ast` when the hook runs at the parsed-source frontier.
- Extended [perl/FSM/Extension/Registry.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Registry.pm) so the shipped typed hook set now includes:
  - `after_parse_source($context)`,
  - and `after_generate_result($context)`.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `after_parse_source($context)` runs:
  - after source parsing and classification for normal FSM inputs,
  - and after source parsing/classification plus typed composition-IR parsing for top-level composition inputs.
- Updated [t/26-extension-mechanism.t](/Users/richarddje/Documents/github/fsmgen/t/26-extension-mechanism.t), [t/lib/FSM/TestExtension/Marker.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/TestExtension/Marker.pm), and [t/27-extension-loading.t](/Users/richarddje/Documents/github/fsmgen/t/27-extension-loading.t) so the new hook boundary is now locked across:
  - direct object injection,
  - explicit module-name loading,
  - and CLI loading.
- Updated [docs/EXTENSION_MODEL.md](/Users/richarddje/Documents/github/fsmgen/docs/EXTENSION_MODEL.md), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the now-complete `R7` boundary is described truthfully.
- Live roadmap status change:
  - `R7` moved from `mostly done` to `done`,
  - the current active lane moved from `R7` to `none`,
  - all currently defined roadmap workstreams `R0` through `R7` are now complete.
- Validation:
  - `perl -I perl -I t/lib -c perl/FSM/Extension/Context.pm` (pass)
  - `perl -I perl -I t/lib -c perl/FSM/Extension/Registry.pm` (pass)
  - `perl -I perl -I t/lib -c perl/FSM/Pipeline/HDLGenerator.pm` (pass)
  - `perl -I perl -I t/lib -c t/26-extension-mechanism.t` (pass)
  - `prove -I perl -I t/lib t/26-extension-mechanism.t t/27-extension-loading.t t/28-extension-config-loading.t` (pass)
  - `git diff --check` (pass)
### `R7` shipped explicit extension-config loading and moved to mostly-done
- Extended [perl/FSM/Extension/Loader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Loader.pm) so it can parse explicit extension-config files, with the current narrow config contract being:
  - blank lines allowed,
  - `# ...` comment lines allowed,
  - and one active `module Module::Name` declaration per extension line.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so callers may now pass `extension_config_files => [ ... ]` in addition to direct objects and explicit module names.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so repeated `--extension-config <file>` flags can load typed extensions from explicit config files.
- Added [t/28-extension-config-loading.t](/Users/richarddje/Documents/github/fsmgen/t/28-extension-config-loading.t) to lock:
  - config-file parsing through the loader,
  - programmatic pipeline loading through `extension_config_files`,
  - CLI loading through `--extension-config`,
  - and malformed-config diagnostics with file/line reporting.
- Updated [docs/EXTENSION_MODEL.md](/Users/richarddje/Documents/github/fsmgen/docs/EXTENSION_MODEL.md), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [README.md](/Users/richarddje/Documents/github/fsmgen/README.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the explicit config-file layer is described truthfully.
- Live roadmap status change:
  - `R7` moved from `in progress` to `mostly done`,
  - the active lane stays `R7`,
  - the next honest `R7` step is now choosing the next typed hook boundary, not finishing extension loading.
- Validation:
  - `perl -I perl -I t/lib -c perl/FSM/Extension/Loader.pm` (pass)
  - `perl -I perl -I t/lib -c perl/FSM/Pipeline/HDLGenerator.pm` (pass)
  - `perl -I perl -I t/lib -c bin/fsmgen` (pass)
  - `perl -I perl -I t/lib -c t/28-extension-config-loading.t` (pass)
  - `prove -I perl -I t/lib t/27-extension-loading.t t/28-extension-config-loading.t` (pass)
  - `git diff --check` (pass)
### `R7` shipped explicit typed extension loading for pipeline and CLI
- Added [perl/FSM/Extension/Loader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Loader.pm) as the explicit typed module loader for the new extension architecture. It:
  - validates module-name syntax before `require`,
  - instantiates extensions through `new()`,
  - and rejects non-object returns with targeted diagnostics.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so callers may now pass `extension_modules => [ 'Module::Name', ... ]` in addition to direct `extensions => [ $object, ... ]`.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so repeated `--extension-module Module::Name` flags can load explicit typed extensions from `@INC` without reviving `.plg` scanning or implicit discovery.
- Added [t/lib/FSM/TestExtension/Marker.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/TestExtension/Marker.pm) and [t/27-extension-loading.t](/Users/richarddje/Documents/github/fsmgen/t/27-extension-loading.t) to lock:
  - explicit module loading through the loader,
  - programmatic pipeline loading through `extension_modules`,
  - CLI loading through `--extension-module`,
  - and targeted failure for missing extension modules.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/EXTENSION_MODEL.md](/Users/richarddje/Documents/github/fsmgen/docs/EXTENSION_MODEL.md), [README.md](/Users/richarddje/Documents/github/fsmgen/README.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the new explicit loading path is described truthfully.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - but `R7` `Done` / `Left` advanced because loading is now explicit programmatic-plus-CLI rather than programmatic-only.
- Validation:
  - `perl -I perl -I t/lib -c perl/FSM/Extension/Loader.pm` (pass)
  - `perl -I perl -I t/lib -c perl/FSM/Pipeline/HDLGenerator.pm` (pass)
  - `perl -I perl -I t/lib -c bin/fsmgen` (pass)
  - `perl -I perl -I t/lib -c t/27-extension-loading.t` (pass)
  - `prove -I perl -I t/lib t/26-extension-mechanism.t t/27-extension-loading.t` (pass)
  - `git diff --check` (pass)
### typed-extension docs now explain the shipped boundary with concrete examples
- Expanded [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) with a new user-facing section explaining what a typed extension is in the current `R7` architecture.
- The guide now makes the current boundary concrete:
  - a typed extension is a normal blessed Perl object,
  - the shipped hook is an explicit method (`after_generate_result($context)`),
  - and the hook receives a typed context object rather than legacy string-dispatch data.
- Added realistic examples in the user guide for:
  - annotating the returned generation result,
  - and collecting post-generation telemetry across multiple runs.
- Tightened [docs/EXTENSION_MODEL.md](/Users/richarddje/Documents/github/fsmgen/docs/EXTENSION_MODEL.md) so it now explains what "typed" means explicitly in this project: object + method + context, not `.plg` scanning plus `AUTOLOAD` / eval lookup.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task.
- Validation:
  - `git diff --check` (pass)
### `R7` started with a typed extension registry and first live hook
- Added [docs/EXTENSION_MODEL.md](/Users/richarddje/Documents/github/fsmgen/docs/EXTENSION_MODEL.md) to define the first modern replacement seam for legacy `.plg` / `PPlugin`, including the deliberately narrow current boundary and explicit non-goals.
- Added [perl/FSM/Extension/Registry.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Registry.pm) and [perl/FSM/Extension/Context.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Context.pm) as the first typed extension primitives for the active architecture.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so callers can pass programmatic `extensions => [ ... ]` objects and the live pipeline now dispatches `after_generate_result($context)` for both FSM and composition results before returning them.
- Added [t/26-extension-mechanism.t](/Users/richarddje/Documents/github/fsmgen/t/26-extension-mechanism.t) to lock:
  - registry rejection of non-object extension entries,
  - hook dispatch for a normal FSM generation result,
  - and hook dispatch for a composition generation result.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [README.md](/Users/richarddje/Documents/github/fsmgen/README.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the first shipped `R7` boundary is stated truthfully in the live board and onboarding docs.
- Live roadmap status change:
  - `R7` moved from `not started` to `in progress`,
  - the active lane stays `R7`,
  - the next honest `R7` decision is now whether loading remains programmatic-only or grows an explicit config/CLI path, and which typed hook boundary comes next.
- Validation:
  - `perl -I perl -c perl/FSM/Extension/Context.pm` (pass)
  - `perl -I perl -c perl/FSM/Extension/Registry.pm` (pass)
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm` (pass)
  - `perl -I perl -c t/26-extension-mechanism.t` (pass)
  - `prove -I perl t/26-extension-mechanism.t` (pass)
  - `git diff --check` (pass)
### `R6` shipped `C6` legacy-scope failures and closed the composition lane
- Tightened [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm) so the remaining reachable legacy composition shapes now fail explicitly and consistently with scope-doc pointers instead of relying on generic parser fallout.
- The tightened explicit-scope failures now cover:
  - legacy macro/plugin children such as `?&name`,
  - nested `?top` blocks,
  - legacy `?ports` mapping directives,
  - and nested `?toplink` structures.
- Added [t/25-composition-legacy-scope-errors.t](/Users/richarddje/Documents/github/fsmgen/t/25-composition-legacy-scope-errors.t) to lock:
  - parser failure for the remaining out-of-scope legacy shapes,
  - and parser/pipeline/CLI failure for legacy macro/plugin composition input.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the shipped `C6` boundary and the resulting roadmap transition are stated truthfully.
- Live roadmap status change:
  - `R6` moved from `mostly done` to `done`,
  - the active lane moved from `R6` to `R7`,
  - `R7` is now the next honest roadmap lane,
  - the `.rtlif` grammar / stronger-interface-contract note remains recorded as a future refinement and is not an `R6` blocker.
- Validation:
  - `perl -I perl -c perl/FSM/Composition/Parser.pm` (pass)
  - `perl -I perl -c t/25-composition-legacy-scope-errors.t` (pass)
  - `prove -I perl t/25-composition-legacy-scope-errors.t` (pass)
  - `prove -I perl t/14-composition-parser.t t/13-composition-source-classification.t` (pass)
  - `prove -I perl t` (pass)
  - `git diff --check` (pass)
### `R6` shipped `C5` width-mismatch diagnostics and moved to mostly-done
- Tightened [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so declared connect-by-name width mismatches now name both endpoints and their conflicting widths directly instead of only reporting an indirect “no compatible endpoint” miss.
- Locked explicit-link width-mismatch behavior in [t/23-composition-errors.t](/Users/richarddje/Documents/github/fsmgen/t/23-composition-errors.t).
- Extended [t/24-composition-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/24-composition-connect-by-name.t) so declared connect-by-name now also locks the width-mismatch case with both endpoints and widths called out directly.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the shipped `C5` boundary and the narrowed remaining `R6` work are stated truthfully.
- Live roadmap status change:
  - `R6` moved from `in progress` to `mostly done`,
  - the active lane stays `R6`,
  - the next honest slice is now `C6` explicit failure for out-of-scope legacy composition constructs,
  - and the `.rtlif` grammar / stronger-interface-contract follow-up remains recorded explicitly on the roadmap board.
- Validation:
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm` (pass)
  - `perl -I perl -c t/23-composition-errors.t` (pass)
  - `perl -I perl -c t/24-composition-connect-by-name.t` (pass)
  - `prove -I perl t/23-composition-errors.t t/24-composition-connect-by-name.t` (pass)
  - `prove -I perl t` (pass)
  - `git diff --check` (pass)
### `R6` user-guide clarification for realistic `=name` usage
- Expanded [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) with realistic `C4` `=name` examples instead of only the minimal synthetic one.
- The guide now shows:
  - direct top-level exposure of child FSM outputs by the same name,
  - pass-through of a top-level control input into one child by the same name,
  - and direct same-name exposure of an external RTL output backed by `.rtlif` metadata.
- Added practical guidance in the user guide for when `=name` is appropriate versus when explicit `?toplink` is still the right tool.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task.
- Validation:
  - `git diff --check` (pass)
### `R6` first shipped `C4` declared connect-by-name lane
- Landed the first active declared connect-by-name runtime slice in [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm).
- The shipped `C4` boundary is intentionally narrow:
  - top ports may be declared as `=name` inside `?ports`,
  - connect-by-name applies only to those explicitly declared top ports,
  - and planning succeeds only when exactly one same-named child endpoint matches by direction and width.
- Updated [perl/FSM/Composition/Port.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Port.pm) and [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm) so `?ports` tokens can now carry explicit connect-by-name intent through a `binding_mode` on typed ports.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the composition path now:
  - recognizes a dedicated `C4` lane when `?ports` contains `=name` declarations,
  - synthesizes typed by-name links for those declarations,
  - and rejects ambiguous or missing matches explicitly instead of widening implicit inference.
- Tightened [t/14-composition-parser.t](/Users/richarddje/Documents/github/fsmgen/t/14-composition-parser.t) so the parser now locks `=port` shape and connect-by-name preservation on typed ports.
- Added [t/24-composition-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/24-composition-connect-by-name.t) to lock:
  - the first `C4` success path,
  - ambiguous same-name match rejection,
  - and missing-child-endpoint rejection.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_LEGACY_MAPPING.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_LEGACY_MAPPING.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the docs now describe the shipped `C4` subset truthfully.
- Live roadmap status change:
  - no phase status changed,
  - `R6` remains `in progress`,
  - but `R6` `Done` / `Left` moved forward because the first `C4` slice is now shipped, the next honest slice is `C5`, and the `.rtlif` grammar/stronger-interface-contract follow-up is now recorded explicitly in the roadmap board.
- Validation:
  - `perl -I perl -c perl/FSM/Composition/Port.pm` (pass)
  - `perl -I perl -c perl/FSM/Composition/Parser.pm` (pass)
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm` (pass)
  - `perl -I perl -c t/14-composition-parser.t` (pass)
  - `perl -I perl -c t/24-composition-connect-by-name.t` (pass)
  - `prove -I perl t/14-composition-parser.t t/20-composition-single-fsm-top.t t/21-composition-two-fsm-linking.t t/22-composition-fsm-plus-rtl.t t/23-composition-errors.t t/24-composition-connect-by-name.t` (pass)
  - `prove -I perl t` (pass)
  - `git diff --check` (pass)
### `R6` first shipped `C3` mixed FSM-plus-RTL lane
- Landed the first active mixed composition runtime slice in [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm).
- The shipped `C3` boundary is intentionally narrow:
  - exactly one embedded `?fsmc` child,
  - exactly one external `?rtl` child,
  - one explicit `?ports` block,
  - explicit `?toplink` wiring using top-port names and `instance.port` child endpoints,
  - and sidecar external-interface metadata loaded from `<module>.rtlif`.
- Added [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) as the first modern external-RTL interface loader. It:
  - searches for `<module>.rtlif` first beside the composition source and then through existing `FSMLIB` roots,
  - parses a typed `?rtlif:<module>` root,
  - and materializes typed composition ports for external RTL validation/wiring.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the composition path now:
  - realizes `?rtl` children through the typed sidecar metadata loader instead of hard-rejecting them,
  - chooses a dedicated `C3` plan when the source contains one `?fsmc` child plus one `?rtl` child,
  - reuses the explicit-link planner across mixed-child wiring,
  - instantiates the external RTL child without regenerating its internals.
- Added [t/22-composition-fsm-plus-rtl.t](/Users/richarddje/Documents/github/fsmgen/t/22-composition-fsm-plus-rtl.t) to lock:
  - the shipped `C3` success path,
  - typed external-interface loading,
  - mixed `?fsmc` + `?rtl` binding plans,
  - generated top HDL,
  - and CLI output generation for the mixed lane.
- Extended [t/23-composition-errors.t](/Users/richarddje/Documents/github/fsmgen/t/23-composition-errors.t) so mixed composition now also locks:
  - unknown external-RTL port rejection,
  - and direction-mismatch rejection for external-RTL endpoints.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [README.md](/Users/richarddje/Documents/github/fsmgen/README.md), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [docs/COMPOSITION_LEGACY_MAPPING.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_LEGACY_MAPPING.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the docs now describe the shipped `C3` subset truthfully.
- Live roadmap status change:
  - no phase status changed,
  - `R6` remains `in progress`,
  - but `R6` `Done` / `Left` moved forward because `C3` is now shipped and the next honest slice is `C4` declared connect-by-name.
- Validation:
  - `perl -I perl -c perl/FSM/Composition/RTLInterfaceLoader.pm` (pass)
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm` (pass)
  - `perl -I perl -c t/22-composition-fsm-plus-rtl.t` (pass)
  - `perl -I perl -c t/23-composition-errors.t` (pass)
  - `prove -I perl t/20-composition-single-fsm-top.t t/21-composition-two-fsm-linking.t t/22-composition-fsm-plus-rtl.t t/23-composition-errors.t` (pass)
  - `prove -I perl t` (pass)
  - `git diff --check` (pass)
### `R6` first shipped `C2` FSM-linking lane
- Landed the first active multi-child composition runtime slice in [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm).
- The shipped `C2` boundary is still intentionally bounded:
  - two or more embedded `?fsmc` children,
  - one explicit `?ports` block,
  - explicit `?toplink` wiring using top-port names and `instance.port` child endpoints,
  - deterministic instance ordering,
  - deterministic internal-net creation for child-to-child links,
  - duplicate-driver rejection before emission.
- Added [perl/FSM/Composition/Net.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Net.pm) and extended the typed runtime plan:
  - [perl/FSM/Composition/Plan.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Plan.pm) now carries typed internal nets,
  - [perl/FSM/Composition/RealizedInstance.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RealizedInstance.pm) now carries per-instance port bindings used during top emission.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the composition path now:
  - supports a `C2` planning lane when multiple embedded `?fsmc` children and explicit `?toplink` blocks are present,
  - resolves explicit link endpoints as either top-port names or `instance.port` child endpoints,
  - validates source/target roles and exact width agreement,
  - auto-wires shared `clk` / `rstn` system inputs across realized children,
  - creates deterministic internal nets for child-to-child links,
  - emits multi-child top modules using planned port bindings rather than recomputing wiring during emission.
- Tightened the parser regression in [t/14-composition-parser.t](/Users/richarddje/Documents/github/fsmgen/t/14-composition-parser.t) so dotted `instance.port` link endpoints are now locked explicitly.
- Added [t/21-composition-two-fsm-linking.t](/Users/richarddje/Documents/github/fsmgen/t/21-composition-two-fsm-linking.t) to lock:
  - the shipped `C2` success path,
  - deterministic internal-net naming,
  - deterministic instance ordering,
  - per-instance binding plans,
  - and CLI output generation for the two-child explicit-link lane.
- Added [t/23-composition-errors.t](/Users/richarddje/Documents/github/fsmgen/t/23-composition-errors.t) to lock duplicate-driver rejection for explicit composition links.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [README.md](/Users/richarddje/Documents/github/fsmgen/README.md), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the docs now describe the shipped `C2` subset truthfully.
- Live roadmap status change:
  - no phase status changed,
  - `R6` remains `in progress`,
  - but `R6` `Done` / `Left` moved forward again because the next honest slice is now `C3` mixed `?fsmc` + `?rtl` realization rather than more FSM-only linking groundwork.
- Validation:
  - `perl -I perl -c perl/FSM/Composition/Net.pm` (pass)
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm` (pass)
  - `perl -I perl -c t/21-composition-two-fsm-linking.t` (pass)
  - `perl -I perl -c t/23-composition-errors.t` (pass)
  - `prove -I perl t/13-composition-source-classification.t t/14-composition-parser.t t/20-composition-single-fsm-top.t t/21-composition-two-fsm-linking.t t/23-composition-errors.t` (pass: `Files=5`, `Tests=120`)
  - `prove -I perl t` (pass)
  - `git diff --check` (pass)
### `R6` first shipped `C1` composition generation lane
- Landed the first active composition runtime slice in [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm).
- The shipped `C1` boundary is intentionally narrow:
  - one `?top:name`,
  - one embedded `?fsmc` child source in the same file,
  - one explicit `?ports` block,
  - deterministic same-name top wiring,
  - generated child HDL plus generated top HDL through `bin/fsmgen`.
- Added typed composition planning objects for this runtime slice:
  - [perl/FSM/Composition/Port.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Port.pm)
  - [perl/FSM/Composition/Link.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Link.pm)
  - [perl/FSM/Composition/Plan.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Plan.pm)
  - [perl/FSM/Composition/RealizedInstance.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RealizedInstance.pm)
- Updated [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm) so:
  - `?ports` are parsed into typed `Port` objects,
  - `?toplink` entries are parsed into typed `Link` objects.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the composition path now:
  - realizes one embedded `?fsmc` child through the active FSM pipeline,
  - captures the realized child interface as typed ports,
  - treats `clk` / `rstn` as the current implicit system-input part of that child interface,
  - validates explicit top-port exposure against the realized child interface,
  - emits the generated top module and returns composition-aware `module_info` / statistics.
- Added [t/20-composition-single-fsm-top.t](/Users/richarddje/Documents/github/fsmgen/t/20-composition-single-fsm-top.t) as the first end-to-end composition acceptance test. It locks:
  - typed composition planning for `C1`,
  - child realization,
  - generated top HDL,
  - deterministic same-name instance wiring,
  - and CLI output generation through `bin/fsmgen`.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [README.md](/Users/richarddje/Documents/github/fsmgen/README.md), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the docs now describe the shipped `C1` boundary truthfully instead of still calling composition entirely unimplemented.
- Live roadmap status change:
  - no phase status changed,
  - `R6` remains `in progress`,
  - but `R6` `Done` / `Left` moved forward to reflect that `C1` is now shipped and the next honest slice is `C2`-oriented multi-child/link planning.
- Validation:
  - `perl -I perl -c perl/FSM/Composition/RealizedInstance.pm` (pass)
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm` (pass)
  - `perl -I perl -c t/20-composition-single-fsm-top.t` (pass)
  - `prove -I perl t/13-composition-source-classification.t t/14-composition-parser.t t/20-composition-single-fsm-top.t` (pass: `Files=3`, `Tests=79`)
  - `prove -I perl t` (pass)
  - `git diff --check` (pass)
### `R6` legacy mapping note and first typed composition parser/IR slice
- Added [docs/COMPOSITION_LEGACY_MAPPING.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_LEGACY_MAPPING.md) as the historical-context note for composition work.
- The note records:
  - the obsolete composition call tree in `fx/bin/fsmgen` / `fx/perl/FSMGen.pm`,
  - the role of legacy `top_exec(...)`,
  - the surviving language concepts (`?top`, `?fsmc`, `?rtl`, `?ports`, `?toplink`),
  - and the mechanisms the active architecture must not revive (`AUTOLOAD`, `PPlugin`, `.plg`, late architecture plugins).
- Added the first typed composition parser/IR packages:
  - [perl/FSM/Composition/Spec.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Spec.pm)
  - [perl/FSM/Composition/Top.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Top.pm)
  - [perl/FSM/Composition/Instance.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Instance.pm)
  - [perl/FSM/Composition/PortsBlock.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/PortsBlock.pm)
  - [perl/FSM/Composition/TopLink.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/TopLink.pm)
  - [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm)
- Behavior change in [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm):
  - `?top:name` inputs are now not only classified, but also parsed through the first typed composition parser/IR boundary before failing at the still-unimplemented child-realization/top-emission stage.
- The typed parser currently supports:
  - `?top:name`
  - `?fsmc`
  - `?rtl`
  - `?ports`
  - `?toplink`
- The typed parser now rejects several legacy-only shapes explicitly instead of silently inheriting them:
  - inline top-port shorthand under `?top:name`
  - multi-source `?fsmc`
  - nested `?top`
  - unknown child kinds
- Updated [t/13-composition-source-classification.t](/Users/richarddje/Documents/github/fsmgen/t/13-composition-source-classification.t) so the pipeline/CLI boundary is now locked after typed composition parsing.
- Added [t/14-composition-parser.t](/Users/richarddje/Documents/github/fsmgen/t/14-composition-parser.t) to cover:
  - typed parsing of a real legacy composition fixture (`fsm/trial_1.fsm`)
  - typed parsing of explicit `?ports` / `?fsmc` / `?rtl` / `?toplink` blocks
  - explicit parser errors for unsupported legacy shorthand
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [README.md](/Users/richarddje/Documents/github/fsmgen/README.md), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the active `R6` state now reflects parser/IR progress rather than only scope-plus-boundary classification.
- Validation:
  - `perl -I perl -c perl/FSM/Composition/Spec.pm` (pass)
  - `perl -I perl -c perl/FSM/Composition/Top.pm` (pass)
  - `perl -I perl -c perl/FSM/Composition/Instance.pm` (pass)
  - `perl -I perl -c perl/FSM/Composition/PortsBlock.pm` (pass)
  - `perl -I perl -c perl/FSM/Composition/TopLink.pm` (pass)
  - `perl -I perl -c perl/FSM/Composition/Parser.pm` (pass)
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm` (pass)
  - `perl -I perl -c t/14-composition-parser.t` (pass)
  - `prove -I perl t/13-composition-source-classification.t t/14-composition-parser.t` (pass: `Files=2`, `Tests=38`)
### Composition source classification at the active pipeline boundary
- Added [perl/FSM/SourceClassifier.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/SourceClassifier.pm) as the shared top-level source-kind classifier for raw Lispish ASTs.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the active pipeline now classifies source kind before invoking the FSM-only adapter path.
- Behavior change:
  - `?fsm:name` / `+fsm` inputs continue through the existing single-FSM pipeline unchanged,
  - `?top:name` inputs are now recognized explicitly and fail at the composition boundary with a deliberate diagnostic pointing to [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md),
  - unsupported composition input no longer falls through to the generic `Expected FSM structure containing '?fsm:name' or '+fsm'` parser error.
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so direct FSM-only parser callers also get a composition-specific boundary error for `?top:name`.
- Added [t/13-composition-source-classification.t](/Users/richarddje/Documents/github/fsmgen/t/13-composition-source-classification.t) to lock:
  - `?fsm:name` vs `?top:name` classification,
  - pipeline rejection of unsupported composition input,
  - direct adapter rejection of composition input at the FSM-only parser boundary,
  - CLI surfacing of the composition-boundary diagnostic.
- Tightened [t/01-regression.t](/Users/richarddje/Documents/github/fsmgen/t/01-regression.t) so the broad sample compile sweep now includes only active FSM-root fixtures according to the new shared classifier, instead of treating top-level composition samples as supported single-FSM inputs.
- Retargeted [t/09-ast-first-intermediate-registry.t](/Users/richarddje/Documents/github/fsmgen/t/09-ast-first-intermediate-registry.t) and [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) from `fsm/trial_1.fsm` to `fsm/lte_dif_pmaster.fsm`, because those architecture tests are supposed to exercise the active single-FSM pipeline rather than a legacy composition fixture.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [README.md](/Users/richarddje/Documents/github/fsmgen/README.md), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), and [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md) so the active boundary now reflects explicit composition source detection even though full composition support is still not implemented.
- Validation:
  - `perl -I perl -c perl/FSM/SourceClassifier.pm` (pass)
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm` (pass)
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm` (pass)
  - `perl -I perl -c t/01-regression.t` (pass)
  - `prove -I perl t/01-regression.t` (pass)
  - `prove -I perl t/13-composition-source-classification.t` (pass: `Files=1`, `Tests=14`)
### Roadmap phase transition (`R6` not started -> in progress)
- Started the first concrete `R6` slice by turning composition work into a scoped active-architecture plan instead of leaving it as roadmap terminology.
- Updated `ROADMAP_STATUS.md` to record the live status change:
  - `R6` moved from `not started` to `in progress`,
  - the active lane remains `R6`,
  - the next decision point is now implementation of the first typed `?top:name` composition classifier/parser slice above the current FSM-only parser boundary.
- Validation:
  - `git diff --check` (pass)
  - `rg -n "COMPOSITION_SCOPE\\.md|\\?top:name|\\?fsmc|\\?rtl|\\?ports|\\?toplink|R6.*in progress|Composition-oriented language" README.md docs/USER_GUIDE.md docs/COMPOSITION_SCOPE.md ROADMAP_STATUS.md MEMORY.md CHANGES.md DEVELOPMENT_NOTES.md` (pass)
### Composition scope definition for active architecture
- Added [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md) as the normative scope and acceptance-boundary document for the first `R6` composition lane.
- Grounded the scope in the active architecture instead of the obsolete legacy flow:
  - current boundary is `bin/fsmgen` -> `FSM::Pipeline::HDLGenerator` -> `FSM::Adapter::FSMGenFull::Parser`,
  - current parser accepts only `?fsm:name` / `+fsm`,
  - first composition lane is defined around a separate `?top:name` path plus typed composition IR and deterministic top emission.
- Defined the first in-scope composition model:
  - `?fsmc` child FSM instances,
  - `?rtl` external RTL instances,
  - `?ports` top interface declarations,
  - `?toplink` explicit wiring,
  - deterministic connect-by-name only when declared and unambiguous.
- Defined the executable acceptance matrix for composition (`C1`..`C6`) and the planned focused test-file split (`t/20`..`t/23`).
- Updated [README.md](/Users/richarddje/Documents/github/fsmgen/README.md) and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) so the scope doc is discoverable and the user guide explicitly states that composition is not yet implemented in the active toolchain.
- Validation:
  - `git diff --check` (pass)
  - `rg -n "COMPOSITION_SCOPE\\.md|\\?top:name|\\?fsmc|\\?rtl|\\?ports|\\?toplink|R6.*in progress|Composition-oriented language" README.md docs/USER_GUIDE.md docs/COMPOSITION_SCOPE.md ROADMAP_STATUS.md MEMORY.md CHANGES.md DEVELOPMENT_NOTES.md` (pass)
### Roadmap snapshot hardening (show `Rj` descriptions)
- Tightened the roadmap board and commit workflow so every live-status snapshot now shows each `Rj` with at least `status + brief description`.
- Added explicit `Description` fields to every workstream in `ROADMAP_STATUS.md`, so the board now answers not only “where are we?” but also “what does this phase do?” without requiring the user to infer it from deliverables.
- Updated `COMMIT.md`, `.agents/workflows/commit.md`, and `MEMORY.md` so commit close-outs must:
  - show `status + description` for every `Rj`,
  - and optionally add brief sub-bullets for the active lane, changed lane, or any phase whose next step matters right now.
- Validation:
  - `git diff --check` (pass)
  - `rg -n '^Description:|status \\+ description|show every' ROADMAP_STATUS.md COMMIT.md .agents/workflows/commit.md MEMORY.md CHANGES.md DEVELOPMENT_NOTES.md` (pass)
### Roadmap phase transition (`R3` done, active lane -> `R6`)
- Audited the remaining runtime-convergence residue after removing direct stored-expression parsing from normal backend runtime-AST resolution.
- Audit result:
  - `resolve_intermediate_signal_runtime_ast(...)` no longer parses stored expressions directly,
  - the remaining compatibility residue is now explicit and narrow: miss-recovery parsing in `recover_runtime_ast_from_dependency_expression(...)` plus the owner-side compatibility parser in `EnableGraph` for legacy registry/global-expression entries,
  - that satisfies the `R3` exit criteria because compatibility parsing is no longer part of the default runtime path.
- Updated `ROADMAP_STATUS.md` to record the live status change:
  - `R3` moved from `mostly done` to `done`,
  - current active lane changed from `R3` to `R6`,
  - `R6` next decision point is now concrete scope definition plus acceptance tests for composition work in the active architecture.
- Validation:
  - `git diff --check` (pass)
  - focused regression `prove -I perl t/07-runtime-ast-miss-dependency-recovery.t` (pass: `Files=1`, `Tests=21`)
  - full regression `prove -I perl t` (pass: `Files=12`, `Tests=413`)
### AST/CoreAST convergence (`R3`: remove direct stored-expression runtime parse)
- Removed the direct stored-expression compatibility parse from `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm::resolve_intermediate_signal_runtime_ast(...)`.
- Behavior change:
  - stored-expression-only runtime-AST resolution now records `runtime_ast_miss_reason = no_ast_source` instead of synthesizing `parsed_expression_ast` / `cleaned_expression_ast`,
  - explicit runtime-AST-miss dependency recovery remains the only backend path that can promote `runtime_ast` from a compatibility expression.
- Extended `t/07-runtime-ast-miss-dependency-recovery.t` so it now proves:
  - direct stored-expression runtime-AST resolution no longer parses compatibility expressions on the normal path,
  - stored-expression-only runtime-AST resolution records a missing state,
  - explicit cleaned-expression miss recovery still works.
- Updated `ROADMAP_STATUS.md` to reflect that `R3` is now complete and `R6` is the next active lane.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `perl -I perl -c t/07-runtime-ast-miss-dependency-recovery.t` (pass)
  - `prove -I perl t/07-runtime-ast-miss-dependency-recovery.t` (pass: `Files=1`, `Tests=21`)
### Commit workflow hardening (always display live-status tracker)
- Tightened the commit workflow so the user-facing close-out must now always display the current live-status snapshot from `ROADMAP_STATUS.md` whenever the commit workflow runs.
- Clarified the expected close-out language:
  - if the task changed live status, the close-out must state how the snapshot changed,
  - if the task did not change live status, the close-out must explicitly say the snapshot is unchanged for that task.
- Updated the authoritative workflow docs in `COMMIT.md`, `.agents/workflows/commit.md`, `ROADMAP_STATUS.md`, and `MEMORY.md` to encode that rule consistently.
- Validation:
  - `git diff --check` (pass)
  - `rg -n "current live status snapshot|snapshot is unchanged|commit workflow runs" COMMIT.md .agents/workflows/commit.md ROADMAP_STATUS.md MEMORY.md CHANGES.md DEVELOPMENT_NOTES.md` (pass)
### AST/CoreAST convergence (`R3`: remove render-time late hydration)
- Removed the render-time “late hydration” retry from `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm::render_intermediate_signal_expression(...)`.
- Behavior change:
  - an intermediate signal that first misses runtime-AST resolution with `runtime_ast_miss_reason = no_ast_source` no longer silently promotes `runtime_ast` during plain expression rendering,
  - the remaining promotion path in this area is the explicit runtime-AST-miss dependency-recovery flow.
- Fixed `resolve_intermediate_signal_width(...)` so the backend’s explicit dependency-recovery path can call it with the shorter live argument list it already uses.
- Extended `t/07-runtime-ast-miss-dependency-recovery.t` so it now proves:
  - render-time expression fallback preserves the original `no_ast_source` miss state,
  - render-time fallback does not silently hydrate `runtime_ast`,
  - explicit dependency recovery can still promote `runtime_ast` from a cleaned compatibility expression and records that source explicitly.
- Updated `ROADMAP_STATUS.md` to narrow the remaining `R3` residue:
  - `R3` status stays `mostly done`,
  - `R3` `Left` now points specifically at the remaining direct raw/cleaned expression parsing inside backend runtime-AST resolution and dependency recovery.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/07-runtime-ast-miss-dependency-recovery.t` (pass: `Files=1`, `Tests=17`)
### Roadmap phase transition (`R2` done, active lane -> `R3`)
- Audited the remaining `FlattenedDT` backend/orchestrator ownership boundary against the explicit `R2` deliverables in `ROADMAP_STATUS.md`.
- Audit result:
  - `Backend::SystemVerilog` no longer directly owns `assignment_analysis` / `lhs_assignments` mutation or owner-side analysis,
  - the remaining backend pocket is runtime AST recovery/filtering, dependency rescue/topological ordering, and emitted-signal rendering flow,
  - that matches the intended post-migration `R2` boundary.
- Updated `ROADMAP_STATUS.md` to record the live status change:
  - `R2` moved from `in progress` to `done`,
  - current active lane changed from `R2` to `R3`,
  - `R3` next decision point is now the remaining runtime-AST-miss / compatibility-parse fallback residue in `Backend::SystemVerilog`.
- Validation:
  - `git diff --check` (pass)
  - `rg -n "resolve_intermediate_signal_runtime_ast|should_filter_ast_based|should_filter_runtime_ast_miss|topologically_sort_signals|generate_consolidated_intermediate_signals" perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - backend audit confirms no remaining `assignment_analysis` / `lhs_assignments` matches in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
### FlattenedDT live ownership (EnableGraph live-usage evidence ownership)
- Moved intermediate-signal live-usage evidence helpers off `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `ast_contains_signal(...)` to `EnableGraph`, so owner-side AST signal-reference inspection now lives with the owner of the enable/capture structures being inspected.
- Added `is_signal_referenced_in_substitutions(...)`, `is_signal_actually_used_in_final_expressions(...)`, and `resolve_intermediate_signal_live_usage(...)` to `EnableGraph`.
- Updated `Backend::SystemVerilog` so consolidated intermediate-signal filtering now consumes owner-provided live-usage metadata instead of exposing those evidence helpers on the backend.
- Extended `t/10-ast-first-enable-structure.t` so:
  - the backend is asserted to stay free of the former live-usage evidence helper pocket,
  - and `EnableGraph` is asserted to own AST signal-reference inspection, substituted-expression/final-expression usage evidence, and cached live-usage metadata derivation on the live path.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=176`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=400`)
### Roadmap deliverables hardening
- Tightened `ROADMAP_STATUS.md` so every `R0`..`R7` workstream now carries explicit deliverables, not just status labels and narrative summaries.
- Updated the board structure so each workstream must state:
  - `Deliverables`
  - `Status`
  - `Done`
  - `Left`
  - `Exit criteria`
- Re-defined the status scale on the live board so `done` now means all listed deliverables are complete and the exit criteria are met.
- Updated `MEMORY.md`, `COMMIT.md`, and `.agents/workflows/commit.md` so roadmap-board refreshes now also cover deliverable changes, not just status/remaining-work/active-lane changes.
- Validation:
  - `git diff --check` (pass)
  - `rg -n "^Deliverables:|roadmap deliverables|All listed `Deliverables`" ROADMAP_STATUS.md MEMORY.md COMMIT.md .agents/workflows/commit.md CHANGES.md DEVELOPMENT_NOTES.md` (pass)
### Live status visibility hardening
- Tightened the roadmap workflow so live-status changes are now both persistent and visible in the task close-out.
- Updated `ROADMAP_STATUS.md` so any workstream-status change or active-lane change now requires:
  - refreshing the live board,
  - logging the change in `CHANGES.md`,
  - and displaying the current live status snapshot in the user-facing close-out.
- Updated `MEMORY.md`, `COMMIT.md`, and `.agents/workflows/commit.md` so the same rule is part of the standard post-task workflow and not just an informal convention.
- Validation:
  - `git diff --check` (pass)
  - `rg -n "live status|status snapshot|ROADMAP_STATUS\\.md|CHANGES\\.md" ROADMAP_STATUS.md MEMORY.md COMMIT.md .agents/workflows/commit.md CHANGES.md DEVELOPMENT_NOTES.md` (pass)
### FlattenedDT live ownership (EnableGraph substitution synchronization ownership)
- Moved substitution-era AST rewrite/debug passes off `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `count_unary_negations_in_original_expressions(...)` to `EnableGraph`, so the same owner that already owns `assignment_analysis` and captured condition ASTs now also owns the unary-negation debug scan around substitution.
- Added `update_original_asts_with_substituted_versions(...)` and `update_original_asts_with_second_pass_substitutions(...)` to `EnableGraph`, plus a shared context-to-AST map helper used by both update passes.
- Updated `Backend::SystemVerilog::run_global_ast_factorization(...)` so first-pass substitution synchronization and the surrounding unary-negation debug scans now go through `EnableGraph`.
- Updated `perl/FSM/HDL/Factorization/Fixpoint.pm` so second-pass substitution synchronization now also goes through `EnableGraph`.
- Extended `t/10-ast-first-enable-structure.t` so:
  - the backend is asserted to stay free of the former substitution-update/debug helper pocket,
  - and `EnableGraph` is asserted to own the unary-negation debug scan plus first-pass and second-pass substitution synchronization on the live path.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/Factorization/Fixpoint.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=168`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=392`)
### FlattenedDT live ownership (EnableGraph factorization AST-feed ownership)
- Moved factorization input feeding off `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `feed_asts_to_factorizer(...)` to `EnableGraph`, so the same owner that already owns `assignment_analysis`, captured condition ASTs, and intermediate-signal semantics now also owns the primary factorization AST feed.
- Added `feed_current_asts_to_second_pass(...)` to `EnableGraph` and moved the supporting second-pass eligibility helpers with it:
  - `ast_contains_intermediate_signals(...)`
  - `ast_has_intermediate_signals_recursive(...)`
- Updated `Backend::SystemVerilog::run_global_ast_factorization(...)` so primary factorization now feeds ASTs through `EnableGraph`.
- Updated `perl/FSM/HDL/Factorization/Fixpoint.pm` so second-pass AST collection now also goes through `EnableGraph`.
- Extended `t/10-ast-first-enable-structure.t` so:
  - the backend is asserted to stay free of the former factorization-feed helper pocket,
  - and `EnableGraph` is asserted to own first-pass AST feeding, second-pass AST feeding, and second-pass intermediate-signal eligibility checks on the live path.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/Factorization/Fixpoint.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=162`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=386`)
### Roadmap tracking infrastructure hardening
- Added new tracked file `ROADMAP_STATUS.md` as the canonical live roadmap/workstream status board.
- Defined the allowed status values explicitly:
  - `done`
  - `mostly done`
  - `in progress`
  - `not started`
- Recorded the current baseline workstreams there with stable IDs, exact `Done` / `Left` summaries, and the current active lane.
- Updated the repo workflow/docs so this board is part of normal operating practice instead of optional narrative reconstruction:
  - `README.md` now points to `ROADMAP_STATUS.md` near the top of the ramp-up order,
  - `MEMORY.md` now treats `ROADMAP_STATUS.md` as the canonical live board for “done vs left” tracking,
  - `COMMIT.md` and `.agents/workflows/commit.md` now require refreshing `ROADMAP_STATUS.md` before commit when a task changes roadmap status, remaining work, or the active lane.
- Validation:
  - `git diff --check` (pass)
  - `rg -n "ROADMAP_STATUS\.md" README.md MEMORY.md COMMIT.md .agents/workflows/commit.md CHANGES.md DEVELOPMENT_NOTES.md` (pass)
### FlattenedDT live ownership (EnableGraph logical-op counting ownership)
- Moved binary logical-operation counting off `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `count_binary_logical_operation_occurrences(...)` to `EnableGraph`, so the same owner that already applies logical factorization policy now also owns the live counting pass that produces `binary_logical_op_counts`.
- Moved the supporting AST collection/traversal helper pocket with it:
  - `collect_all_wen_en_ast_expressions(...)`
  - `_count_logical_ops_in_ast(...)`
  - `_is_factorizable_sub_expression(...)`
- Updated `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` so step 4 now calls `enable_graph->count_binary_logical_operation_occurrences(...)` directly.
- Updated `Backend::SystemVerilog::run_global_ast_factorization(...)` so its defensive recount path now also goes through `EnableGraph`, and removed the former backend-side counting helper pocket.
- Extended `t/10-ast-first-enable-structure.t` so:
  - the backend is asserted to stay free of the former counting helper pocket,
  - and `EnableGraph` is asserted to own binary logical-operation counting on the live path.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=155`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=379`)
### FlattenedDT live ownership (EnableGraph WEN/EN prescan ownership)
- Moved WEN/EN intermediate-signal prescan off `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `prescan_wen_en_for_intermediate_signals(...)` to `EnableGraph`, so the same owner that already owns `assignment_analysis`, DT/LHS enable ASTs, and `track_ast_intermediate_signals(...)` now also owns the live prescan that populates `referenced_intermediate_signals`.
- Updated `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` so step 5 now calls `enable_graph->prescan_wen_en_for_intermediate_signals(...)` directly.
- Removed the former backend-side `prescan_wen_en_for_intermediate_signals(...)` entrypoint from `Backend::SystemVerilog`.
- Extended `t/10-ast-first-enable-structure.t` so:
  - the backend is asserted to stay free of the former prescan entrypoint,
  - and `EnableGraph` is asserted to own WEN/EN intermediate-signal prescan on the live path.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=150`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=374`)
### FlattenedDT live ownership (EnableGraph state register planning)
- Moved state-structure planning off backend-local regular-state scans and under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `build_state_register_plan(...)` to `EnableGraph`, so it now owns:
  - whether the FSM has regular states and therefore dedicated state registers,
  - regular-state encoding order and localparam names,
  - the current state-bit width contract,
  - and the reset-state localparam name used by the dedicated state register.
- Updated `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` so `generate_state_encoding(...)` and `generate_state_register(...)` now render the owner-provided state plan instead of recomputing regular-state structure locally.
- Updated `build_internal_signal_declaration_plan(...)` and `get_fsm_reset_state(...)` in `EnableGraph` to reuse the same state plan, removing duplicate regular-state scans from the live path.
- Extended focused regression coverage:
  - `t/11-flatteneddt-generation-reset.t` now inspects the state plan directly for standalone-DT-only FSMs,
  - `t/12-enablegraph-capture-registry.t` now inspects the state plan directly for regular-state FSMs,
  - `t/10-ast-first-enable-structure.t` now asserts `EnableGraph` owns state register planning on the live path.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t t/11-flatteneddt-generation-reset.t t/12-enablegraph-capture-registry.t` (pass)
  - `prove -I perl t` (pass)
### FlattenedDT live ownership (EnableGraph module declaration planning)
- Moved module/interface declaration planning off backend-local synthesis decisions and under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `build_module_declaration_plan(...)` to `EnableGraph`, so it now owns the live interface plan derived from signal and driven-signal classification, including:
  - base ports (`clk`, `rstn`),
  - input vs output direction,
  - `wire` vs `reg` storage,
  - signal width metadata,
  - and the derived `declared_port_signals` / `port_directions` registries consumed later in generation.
- Updated `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` so `generate_module_declaration(...)` now renders the owner-provided plan instead of recomputing those interface decisions locally.
- Preserved the legacy output-port formatting contract by teaching the backend renderer to keep `output reg  ...` spacing exactly stable.
- Extended focused regression coverage:
  - `t/03-assignment-intent-metadata.t` now inspects the live module declaration plan directly for representative input/output ownership and port-registry metadata,
  - `t/10-ast-first-enable-structure.t` now asserts `EnableGraph` owns module declaration planning on the live path,
  - `t/05-assignment-hdl-snapshots.t` locks that emitted module-port text remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/05-assignment-hdl-snapshots.t` (pass: `Files=1`, `Tests=12`)
  - `prove -I perl t/03-assignment-intent-metadata.t t/10-ast-first-enable-structure.t` (pass: `Files=2`, `Tests=242`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=364`)
### FlattenedDT live ownership (EnableGraph internal declaration planning)
- Moved internal declaration planning off backend-local synthesis decisions and under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `build_internal_signal_declaration_plan(...)` to `EnableGraph`, so it now owns the live declaration plan derived from `assignment_analysis`, including:
  - plain internal reg declarations for non-port driven LHS signals,
  - dual-family helper regs such as `I_next` and `K_q`,
  - and pulse-delay helper declarations such as `P1_pulse_delay_pipe` / `P0_pulse_delay_pipe`.
- Updated `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` so `generate_internal_signal_declarations(...)` now renders the owner-provided declaration plan instead of recomputing those synthesis decisions locally.
- Extended focused regression coverage:
  - `t/03-assignment-intent-metadata.t` now inspects the live declaration plan directly for dual-output and pulse-delay helper declarations and verifies exposed ports like `next_I` / `K_r` are not redeclared internally,
  - `t/10-ast-first-enable-structure.t` now asserts `EnableGraph` owns internal declaration planning on the live path.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/03-assignment-intent-metadata.t t/10-ast-first-enable-structure.t` (pass: `Files=2`, `Tests=224`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=346`)
### FlattenedDT live ownership (EnableGraph unified WEN/EN emission)
- Moved stage-7 unified WEN/EN emission off the backend wrapper path and directly onto `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` so step 7 now calls `enable_graph->generate_unified_wen_en_signals(...)` directly.
- Removed the now-wrapper-only `generate_wen_en_signals(...)` method from `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Extended `t/10-ast-first-enable-structure.t` so:
  - the backend is asserted to stay free of the former wrapper entrypoint,
  - and `EnableGraph` is asserted to own unified WEN/EN emission on the live path.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=145`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=337`)
### FlattenedDT live ownership (EnableGraph top-level enable emission)
- Moved top-level state/DT enable emission off `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `generate_enable_conditions(...)` to `EnableGraph`, so the same owner that initializes and now AST-backs `state_enables` / `dt_enables` also emits their `*_en` assign statements.
- Updated `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` so step 3 of live generation now calls `enable_graph->generate_enable_conditions(...)` instead of the backend entrypoint.
- Removed the now-ownerless `generate_enable_conditions(...)` method from `Backend::SystemVerilog`.
- Extended `t/10-ast-first-enable-structure.t` so:
  - the backend is now asserted to stay free of the former top-level enable-emission helper,
  - and `EnableGraph` is asserted to own that live entrypoint.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t t/12-enablegraph-capture-registry.t` (pass: `Files=2`, `Tests=164`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=335`)
### FlattenedDT AST-first live convergence (AST-backed top-level enable registries)
- Converted the live top-level `state_enables` / `dt_enables` registries from plain strings to AST-backed conditions.
- Added `build_state_enable_condition_ast(...)` and `build_dt_enable_condition_ast(...)` to `perl/FSM/Synthesis/EnableGraph.pm`, so top-level enable-condition construction for regular states and standalone DTs is now owned and produced there as AST.
- Updated `initialize_state_and_dt_enable_conditions(...)` so:
  - regular states now store an AST for `current_state == STATE`,
  - standalone DTs now store an AST for `1'b1`,
  - and downstream logic continues to use the same registry keys while consuming typed values.
- Updated `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` so `generate_enable_conditions(...)` renders those top-level enable conditions from AST objects instead of assuming raw strings.
- Extended regression coverage:
  - `t/10-ast-first-enable-structure.t` now asserts top-level `state_enables` / `dt_enables` are AST-backed,
  - `t/11-flatteneddt-generation-reset.t` now asserts standalone DT enable entries remain AST-backed and semantically `1'b1` across generator reuse.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t t/11-flatteneddt-generation-reset.t` (pass: `Files=2`, `Tests=158`)
  - `prove -I perl t/12-enablegraph-capture-registry.t` (pass: `Files=1`, `Tests=21`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=333`)
## 2026-03-13
### FlattenedDT live ownership (EnableGraph test-condition AST ownership)
- Moved the remaining live test-node condition AST construction off `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` and under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `build_test_condition_ast(...)` to `EnableGraph`, which now owns:
  - extraction/normalization of the test signal name,
  - test-branch literal conversion through the existing `convert_test_value_to_ast(...)` path,
  - and assembly of the `signal == value` AST used for `FSM::CoreAST::TestNode` branches.
- Updated `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` so `flatten_decision_tree(...)` now delegates test-branch equality AST construction to `enable_graph` instead of building it inline.
- Extended `t/12-enablegraph-capture-registry.t` so the focused capture fixture now includes a real `?MODE` test node and asserts:
  - pre-factorization assignment capture preserves `MODE == 1'b1` as the branch condition AST,
  - pre-factorization transition capture preserves the same test-node condition AST,
  - and full generation still emits enable logic containing the test comparison.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `prove -I perl t/12-enablegraph-capture-registry.t` (pass: `Files=1`, `Tests=21`)
  - `prove -I perl t/10-ast-first-enable-structure.t t/12-enablegraph-capture-registry.t` (pass: `Files=2`, `Tests=160`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=327`)
### FlattenedDT live ownership (EnableGraph capture-entrypoint ownership)
- Moved the live assignment/transition capture entrypoints themselves under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `capture_assignment_from_ast(...)` and `capture_transition_from_ast(...)` to `EnableGraph`, so it now owns:
  - condition-stack-to-condition-AST assembly for capture,
  - assignment debug/capture preparation,
  - transition debug/capture preparation,
  - and the final registry writes already localized there in the previous slices.
- Updated `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` so `flatten_decision_tree(...)` now delegates assignment and transition capture directly to `enable_graph`.
- Removed the now-ownerless local `record_assignment_from_ast(...)` and `record_transition_from_ast(...)` methods from `Orchestrator`.
- Extended `t/10-ast-first-enable-structure.t` so the live internal architecture now also asserts the `Orchestrator` object no longer exposes those dead helper names.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t t/12-enablegraph-capture-registry.t` (pass: `Files=2`, `Tests=157`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=324`)
### FlattenedDT live ownership (EnableGraph assignment-metadata normalization)
- Moved live assignment operator/intent/provenance normalization under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `extract_assignment_capture_metadata(...)` to `EnableGraph`, which now owns:
  - `assignment_intent` extraction/copy,
  - operator resolution from `operator_symbol` / intent fallback,
  - pulse-operator derivation from `pulse_cycles`,
  - strict validation of the supported operator set,
  - and capture of `source_provenance` / `output_exposure`.
- Updated `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` so `record_assignment_from_ast(...)` now delegates that normalization to `EnableGraph` before registering the capture.
- Extended `t/03-assignment-intent-metadata.t` so live generation now also asserts the captured assignment registry preserves:
  - ordinary register-style metadata (`A`),
  - explicit output exposure (`G`),
  - dual-output intent metadata (`I`),
  - and pulse operator / delay metadata (`P1`).
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `prove -I perl t/03-assignment-intent-metadata.t t/12-enablegraph-capture-registry.t` (pass: `Files=2`, `Tests=88`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=322`)
### FlattenedDT live ownership (EnableGraph capture-shape normalization)
- Moved the remaining live LHS/RHS capture-shape normalization off `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` and under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `extract_rhs_capture_value(...)` to `EnableGraph` and broadened `extract_signal_name_from_ast(...)` so the owner-local signal-name helper now also handles indexed/reference-style AST renderings by leading identifier.
- Updated `Orchestrator` so:
  - assignment-node debug naming now uses `enable_graph->extract_signal_name_from_ast(...)`,
  - `record_assignment_from_ast(...)` now derives the captured LHS key through `EnableGraph`,
  - and captured RHS text now goes through `enable_graph->extract_rhs_capture_value(...)` instead of the local `extract_rhs_from_expression(...)` helper.
- Removed the now-ownerless local `extract_lhs_name_from_ast(...)` and `extract_rhs_from_expression(...)` helpers from `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `prove -I perl t/12-enablegraph-capture-registry.t t/11-flatteneddt-generation-reset.t` (pass: `Files=2`, `Tests=31`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=314`)
### FlattenedDT live ownership (EnableGraph capture-registry ownership)
- Moved live capture-registry mutation for assignments and state transitions under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `register_assignment_capture(...)` and `register_transition_capture(...)` to `EnableGraph`, so the owner that later analyzes `lhs_assignments`, `all_lhs`, and `lhs_ast_map` now also owns registration of that data.
- Updated `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` so:
  - `record_assignment_from_ast(...)` still performs AST/intent extraction and validation locally,
  - but the actual registry write for captured assignment state now goes through `enable_graph->register_assignment_capture(...)`,
  - and state-transition capture now goes through `enable_graph->register_transition_capture(...)`.
- Added `t/12-enablegraph-capture-registry.t`, which exercises live generation on a small stateful FSM and asserts:
  - normal captured assignments remain AST-backed,
  - `next_state` transition capture is still registered with state-transition metadata,
  - the synthetic `next_state` AST remains available in `lhs_ast_map`,
  - and generated HDL still emits the expected state-enable and assignment-enable logic.
- Root cause / rationale:
  - `Orchestrator` was still directly mutating capture registries that are semantically phase-1 analysis input owned and consumed later by `EnableGraph`,
  - the next truthful structural step after the per-run reset slice was to move those live registry writes under the same owner that builds `assignment_analysis`,
  - this narrows another real ownership seam without changing traversal order or emitted HDL behavior.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `prove -I perl t/12-enablegraph-capture-registry.t` (pass: `Files=1`, `Tests=18`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=314`)
### FlattenedDT live-state reset (per-run generation reset + enable-registry ownership)
- Added `reset_generation_state()` to `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` and now call it at the start of `generate_systemverilog(...)`.
- The reset clears per-run generation registries before each live generation pass, including:
  - `state_enables`, `dt_enables`,
  - `lhs_assignments`, `all_lhs`, `lhs_ast_map`, `assignment_analysis`,
  - `intermediate_signals`, `referenced_intermediate_signals`,
  - `global_expressions`, `expression_usage`,
  - `declared_port_signals`, `port_directions`,
  - and transient scratch like `binary_logical_op_counts`, `ast_factorizer`, and the cached `fsm_module`.
- Moved state/DT enable-registry seeding into `perl/FSM/Synthesis/EnableGraph.pm` via `initialize_state_and_dt_enable_conditions(...)`, so `Orchestrator::flatten_all_decision_trees(...)` now traverses while `EnableGraph` owns the enable-condition registries it later synthesizes.
- Added `t/11-flatteneddt-generation-reset.t`, which reuses one `FSM::HDL::FlattenedDT` object across two distinct FSM generations and asserts the second run does not leak first-run DT enables, assignment captures, assignment analysis, or signal names.
- Root cause / rationale:
  - the live generation path initialized most mutable registries only once in `new(...)`, which left same-object reuse vulnerable to stale per-run state,
  - the state/DT enable maps were also still seeded in `Orchestrator` even though they are consumed as enable-synthesis data by `EnableGraph` and the backend,
  - this slice makes generation re-entrant for the tested live path and narrows one more real ownership seam instead of continuing cleanup-only wrapper pruning.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `prove -I perl t/11-flatteneddt-generation-reset.t` (pass: `Files=1`, `Tests=13`)
  - `prove -I perl t` (pass: `Files=11`, `Tests=296`)
### FlattenedDT cleanup (retire residual analysis/declaration facade delegates)
- Removed the residual analysis/declaration delegate pocket from `perl/FSM/HDL/FlattenedDT.pm`:
  - deleted `generate_internal_signal_declarations(...)`,
  - deleted `get_lhs_width_from_analysis(...)`,
  - deleted `is_register(...)`,
  - deleted `fallback_register_analysis_from_assignments(...)`,
  - deleted `generate_intermediate_signals(...)`,
  - deleted `get_pulse_delay_cycles_for_lhs(...)`,
  - deleted `get_pulse_active_level_for_lhs(...)`,
  - deleted `get_signal_info(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those analysis/declaration helper names on the `FlattenedDT` facade.
- Root cause / rationale:
  - repo-wide call-graph auditing showed these names had no remaining callers on the `FlattenedDT` facade anywhere in the active code or tests,
  - the matching methods remain live on `EnableGraph` or `Backend::SystemVerilog`, and the active flow already reaches them there directly,
  - `get_signal_assignment_type(...)` was intentionally kept because `t/03-assignment-intent-metadata.t` still exercises it as part of the tested `FlattenedDT` surface.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live analysis/declaration behavior is unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=137`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=283`)
### FlattenedDT cleanup (retire dead backend factorization/substitution facade delegates)
- Removed the dead backend factorization/substitution delegate pocket from `perl/FSM/HDL/FlattenedDT.pm`:
  - deleted `prescan_wen_en_for_intermediate_signals(...)`,
  - deleted `feed_asts_to_factorizer(...)`,
  - deleted `count_unary_negations_in_original_expressions(...)`,
  - deleted `ast_contains_signal(...)`,
  - deleted `update_original_asts_with_substituted_versions(...)`,
  - deleted `run_second_pass_factorization(...)`,
  - deleted `feed_current_asts_to_second_pass(...)`,
  - deleted `ast_contains_intermediate_signals(...)`,
  - deleted `ast_has_intermediate_signals_recursive(...)`,
  - deleted `update_original_asts_with_second_pass_substitutions(...)`,
  - deleted `get_substituted_ast_for_signal(...)`,
  - deleted `is_signal_referenced_in_substitutions(...)`,
  - deleted `topologically_sort_signals(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those backend-owned factorization/substitution helper names on the `FlattenedDT` facade.
- Root cause / rationale:
  - repo-wide call-graph auditing showed these names had no remaining callers on the `FlattenedDT` facade anywhere in the active code or tests,
  - the matching methods remain live inside `Backend::SystemVerilog`, and the active flow already reaches them there directly from `Orchestrator`, `FSM::HDL::Factorization::Fixpoint`, or backend-local calls,
  - removing the dead facade delegates is safer than preserving an uncalled compatibility surface for factorization/substitution internals.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live backend factorization/substitution behavior is unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=129`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=275`)
### FlattenedDT cleanup (retire dead utility/rendering facade delegates)
- Removed a dead `EnableGraph` utility/rendering helper delegate pocket from `perl/FSM/HDL/FlattenedDT.pm`:
  - deleted `generate_ast_based_signal_name(...)`,
  - deleted `extract_signal_name_from_ast(...)`,
  - deleted `map_operator_to_name(...)`,
  - deleted `is_arithmetic_operation(...)`,
  - deleted `is_logical_operation(...)`,
  - deleted `should_factor_logical_operation(...)`,
  - deleted `contains_frequently_used_operations(...)`,
  - deleted `get_driven_signals(...)`,
  - deleted `track_ast_intermediate_signals(...)`,
  - deleted `is_intermediate_signal(...)`,
  - deleted `is_signal_ast_based_intermediate(...)`,
  - deleted `_ast_contains_factorizable_operators(...)`,
  - deleted `_signal_name_indicates_ast_operators(...)`,
  - deleted `ast_to_systemverilog(...)`,
  - deleted `_ast_to_systemverilog_internal(...)`,
  - deleted `_render_binary_op(...)`,
  - deleted `_render_unary_op(...)`,
  - deleted `_choose_operator_symbol(...)`,
  - deleted `_operand_is_single_bit(...)`,
  - deleted `_signal_is_single_bit(...)`,
  - deleted `_get_operator_precedence(...)`,
  - deleted `_needs_parentheses(...)`,
  - deleted `_map_binary_operator(...)`,
  - deleted `_map_unary_operator(...)`,
  - deleted `_operand_needs_parens_for_negation(...)`,
  - deleted `get_intermediate_signal_expression(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those utility/rendering helper names on the `FlattenedDT` facade.
- Root cause / rationale:
  - repo-wide call-graph auditing showed these names had no remaining facade callers anywhere in the active code or tests,
  - the matching methods remain live in `EnableGraph`, so the `FlattenedDT` delegates had become dead compatibility surface rather than a real ownership seam,
  - `get_signal_assignment_type(...)` was intentionally kept because `t/03-assignment-intent-metadata.t` still exercises it as part of the tested `FlattenedDT` surface.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live `EnableGraph` utility/rendering behavior is unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t/03-assignment-intent-metadata.t` (pass: `Files=1`, `Tests=62`)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=116`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=262`)
### FlattenedDT cleanup (retire dead orchestrator/backend facade pocket)
- Removed the dead orchestrator/backend helper delegate pocket from `perl/FSM/HDL/FlattenedDT.pm`:
  - deleted `flatten_all_decision_trees(...)`,
  - deleted `extract_lhs_name_from_ast(...)`,
  - deleted `flatten_decision_tree(...)`,
  - deleted `generate_header(...)`,
  - deleted `generate_module_declaration(...)`,
  - deleted `generate_state_encoding(...)`,
  - deleted `generate_state_register(...)`,
  - deleted `generate_enable_conditions(...)`,
  - deleted `generate_consolidated_intermediate_signals(...)`,
  - deleted `generate_wen_en_signals(...)`,
  - deleted `record_assignment_from_ast(...)`,
  - deleted `record_transition_from_ast(...)`,
  - deleted `extract_rhs_from_expression(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those orchestrator/backend-owned helper names on the `FlattenedDT` facade.
- Root cause / rationale:
  - repo-wide call-graph auditing showed these names had no remaining facade callers anywhere in the active code or tests,
  - the matching methods remain live and are now reached directly from `Orchestrator` or `backend_sv`,
  - removing the dead delegates is safer than preserving an uncalled flattening/emission compatibility surface on the facade.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live orchestrator/backend behavior is unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=90`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=236`)
### FlattenedDT cleanup (retire dead EnableGraph facade delegates)
- Removed the dead `EnableGraph`-owned helper delegate pocket from `perl/FSM/HDL/FlattenedDT.pm`:
  - deleted `normalize_rhs_logic_level(...)`,
  - deleted `get_reset_value(...)`,
  - deleted `get_fsm_reset_state(...)`,
  - deleted `get_explicit_reset_value(...)`,
  - deleted `set_fsm_module_reference(...)`,
  - deleted `get_default_value_from_ast(...)`,
  - deleted `get_reset_value_from_ast(...)`,
  - deleted `get_default_value(...)`,
  - deleted `convert_condition_to_ast(...)`,
  - deleted `convert_test_value_to_ast(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those `EnableGraph`-owned helper names on the `FlattenedDT` facade.
- Root cause / rationale:
  - repo-wide call-graph auditing showed these names had no remaining facade callers anywhere in the active code or tests,
  - the matching `EnableGraph` methods remain live and are now reached directly from `EnableGraph` itself or from `Orchestrator`,
  - removing the dead delegates is safer than preserving an uncalled setup/reset/default/AST-conversion compatibility surface on the facade.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live `EnableGraph` behavior is unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=77`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=223`)
### FlattenedDT cleanup (retire dead logical-op facade delegates)
- Removed the dead logical-operation helper delegate pocket from `perl/FSM/HDL/FlattenedDT.pm`:
  - deleted `run_global_ast_factorization(...)`,
  - deleted `collect_all_wen_en_ast_expressions(...)`,
  - deleted `count_binary_logical_operation_occurrences(...)`,
  - deleted `_count_logical_ops_in_ast(...)`,
  - deleted `_is_factorizable_sub_expression(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those backend-internal logical-op helper names on the `FlattenedDT` facade.
- Root cause / rationale:
  - repo-wide call-graph auditing showed these names had no remaining facade callers anywhere in the active code or tests,
  - the matching backend methods remain live and still serve the backend/orchestrator path, so the `FlattenedDT` delegates no longer described a real ownership boundary,
  - removing the dead delegates is safer than preserving an uncalled logical-op compatibility surface on the facade.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live backend logical-op counting/factorization behavior is unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=67`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=213`)
### FlattenedDT cleanup (retire dead filtering facade delegates)
- Removed the dead filtering helper delegate pocket from `perl/FSM/HDL/FlattenedDT.pm`:
  - deleted `should_filter_consolidated_signal(...)`,
  - deleted `should_filter_ast_based(...)`,
  - deleted `is_simple_negation(...)`,
  - deleted `is_simple_comparison(...)`,
  - deleted `is_signal_actually_used_in_final_expressions(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those backend-internal filtering helper names on the `FlattenedDT` facade.
- Root cause / rationale:
  - repo-wide call-graph auditing showed these names had no remaining facade callers anywhere in the active code or tests,
  - the matching backend methods are still live but now serve only as backend-internal helpers, so the `FlattenedDT` delegates no longer represented a real ownership boundary,
  - removing the dead delegates is safer than preserving an uncalled compatibility surface on the facade.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live backend filtering behavior is unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=62`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=208`)
### FlattenedDT/backend cleanup (retire dead mux/simple helper pocket)
- Removed the dead mux/simple helper pocket from `perl/FSM/HDL/FlattenedDT.pm` and `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - deleted the `FlattenedDT` facade delegates `is_simple_ast_expression(...)`, `generate_comb_mux(...)`, and `generate_flop_mux(...)`,
  - deleted the matching backend implementations `is_simple_ast_expression(...)`, `generate_comb_mux(...)`, and `generate_flop_mux(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those dead helper names on either the `FlattenedDT` facade or the backend `SystemVerilog` helper object.
- Root cause / rationale:
  - repo-wide call-graph auditing showed those three helpers had no remaining callers anywhere in the active code or tests,
  - the mux helpers still depended on the long-retired `lhs_to_enable_value_pairs` state, which confirmed they were dead compatibility residue rather than inactive live code,
  - removing both sides together is safer than preserving an uncalled alternate mux/simple-expression surface in the facade or backend.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live AST/CoreAST generation, mux emission, and backend lowering behavior are unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=57`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=203`)
### FlattenedDT/EnableGraph cleanup (retire dead AST helper pocket)
- Removed the dead AST helper pocket from `perl/FSM/HDL/FlattenedDT.pm` and `perl/FSM/Synthesis/EnableGraph.pm`:
  - deleted the `FlattenedDT` facade delegates `get_or_create_ast_signal_name(...)`, `canonicalize_expression(...)`, `is_complex_ast(...)`, `should_factor_ast(...)`, `analyze_ast_complexity(...)`, and `_traverse_ast_for_complexity(...)`,
  - deleted the matching `EnableGraph` owner methods `get_or_create_ast_signal_name(...)`, `canonicalize_expression(...)`, `is_complex_ast(...)`, `should_factor_ast(...)`, `analyze_ast_complexity(...)`, and `_traverse_ast_for_complexity(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those dead helper names on either the `FlattenedDT` facade or the `EnableGraph` helper object.
- Root cause / rationale:
  - repo-wide call-graph auditing showed this entire AST helper pocket had no remaining callers anywhere in the active code or tests,
  - `is_complex_ast(...)` and `_traverse_ast_for_complexity(...)` were only still used by the other already-dead methods in that same pocket, so the slice removes the owner-local chain instead of leaving half of it behind,
  - removing both the owner methods and their matching facade delegates together is safer than preserving an uncalled alternate AST analysis/naming surface.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live AST/CoreAST generation, intermediate naming, factorization, and backend emission behavior are unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=51`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=197`)
### FlattenedDT/backend cleanup (retire dead sub-expression analysis helpers)
- Removed the dead sub-expression analysis pocket from `perl/FSM/HDL/FlattenedDT.pm` and `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - deleted the `FlattenedDT` facade delegates `analyze_ast_sub_expressions(...)` and `find_all_ast_sub_expressions(...)`,
  - deleted the matching backend implementations `analyze_ast_sub_expressions(...)` and `find_all_ast_sub_expressions(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those dead helper names on either the `FlattenedDT` facade or the backend `SystemVerilog` helper object.
- Root cause / rationale:
  - repo-wide call-graph auditing showed `analyze_ast_sub_expressions(...)` had no remaining callers anywhere in the active code or tests,
  - `find_all_ast_sub_expressions(...)` only existed to support that already-dead analysis entrypoint, so the pair formed a self-contained dead helper island,
  - removing both sides together is safer than preserving an uncalled alternate analysis surface in either the facade or backend.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live AST/CoreAST generation, logical-operation counting, and backend emission behavior are unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=185`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=185`)
### EnableGraph cleanup (retire dead owner-only helper pocket)
- Removed the dead owner-only helper pocket from `perl/FSM/Synthesis/EnableGraph.pm`:
  - deleted `get_or_create_global_expression(...)`,
  - deleted `should_factor_condition(...)`,
  - deleted `needs_parentheses(...)`,
  - deleted `signal_uses_register_assignment(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those dead helper names on the `EnableGraph` helper object.
- Root cause / rationale:
  - repo-wide call-graph auditing showed these four helpers had no remaining callers anywhere in the active code or tests,
  - they no longer participated in a live compatibility boundary because the matching facade delegates were already gone or the behavior had already localized elsewhere,
  - removing the owner-only pocket is safer than preserving unused helper implementations that could be mistaken for active supported entrypoints.
- Scope remains behavior-preserving cleanup of dead compatibility residue; live AST/CoreAST generation, enable synthesis, and backend emission behavior are unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=35`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=181`)
### FlattenedDT cleanup (retire dead orphan helper pocket)
- Removed the dead helper pocket shared between `perl/FSM/HDL/FlattenedDT.pm` and `perl/FSM/Synthesis/EnableGraph.pm`:
  - deleted `create_condition_expression_signal_name(...)`,
  - deleted `set_explicit_reset_values(...)`,
  - deleted `parentheses_are_redundant(...)`,
  - deleted `generate_expression_from_signal_name(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those dead helper names on either the `FlattenedDT` facade or the `EnableGraph` helper object.
- Root cause / rationale:
  - repo-wide call-graph auditing showed these four helpers had no remaining callers anywhere in the active code or tests,
  - each helper already represented dead compatibility or dead legacy fallback surface rather than a live ownership boundary,
  - removing the owner methods and their matching facade delegates together is safer than leaving uncalled helper definitions lingering on one side of the boundary.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live AST/CoreAST generation, enable synthesis, and backend emission behavior are unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=31`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=177`)
### FlattenedDT cleanup (retire dead unified helper delegates)
- Removed the dead unified-analysis / unified-emission helper delegate pocket from `perl/FSM/HDL/FlattenedDT.pm`:
  - deleted `build_unified_assignment_analysis(...)`,
  - deleted `group_assignments_by_rhs(...)`,
  - deleted `generate_complete_enable_structure(...)`,
  - deleted `build_multiplexer_config(...)`,
  - deleted `generate_unified_wen_en_signals(...)`,
  - deleted `generate_dt_enables_from_analysis(...)`,
  - deleted `generate_lhs_enables_from_analysis(...)`,
  - deleted `generate_signal_assignments(...)`,
  - deleted `generate_unified_flop_mux(...)`,
  - deleted `generate_unified_pulse_delay_logic(...)`,
  - deleted `signal_uses_register_assignment(...)`,
  - deleted `generate_unified_comb_mux(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes that dead unified helper surface on the `FlattenedDT` facade.
- Root cause / rationale:
  - repo-wide call-graph auditing showed the live phase-1/2/3 flow now runs directly through `Orchestrator -> EnableGraph` and no longer routes through the matching facade delegates,
  - the removed methods were pure compatibility wrappers around helper ownership that had already localized in `EnableGraph`,
  - removing the whole delegate cluster is safer than preserving an untested alternate entry surface for unified analysis and mux/WEN generation.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live assignment analysis, enable generation, and mux emission behavior are unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=23`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=169`)
### FlattenedDT cleanup (retire dead signal-AST facade helper)
- Removed the dead `get_signal_ast_node(...)` helper from `perl/FSM/HDL/FlattenedDT.pm`.
- Removed the now-unused `FSM::GlobalASTManager`, `FSM::AST::Node`, and `FSM::CoreAST` imports from `perl/FSM/HDL/FlattenedDT.pm`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes the dead `get_signal_ast_node(...)` facade helper.
- Root cause / rationale:
  - repo-wide call-graph auditing showed `get_signal_ast_node(...)` had no remaining callers anywhere in the active code or tests,
  - the helper depended on a stale `fsm_module` slot that is not populated on the live AST/CoreAST-first path,
  - removing the helper and its last facade-only imports is safer than preserving an untested alternate signal-lookup surface on `FlattenedDT`.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live signal lookup, enable synthesis, and backend emission behavior are unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=11`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=157`)
### FlattenedDT cleanup (retire dead substituted-AST matching helpers)
- Removed the dead substituted-AST matching helper pocket from `perl/FSM/HDL/FlattenedDT.pm`:
  - deleted `signal_name_matches_operation(...)`,
  - deleted `find_substituted_ast(...)`,
  - deleted `ast_contains_intermediate_signal_references(...)`,
  - deleted `expressions_are_equivalent(...)`,
  - deleted `extract_expression_structure(...)`,
  - deleted `ast_structures_match(...)`.
- Removed the now-unused `Data::Dumper`, `Scalar::Util qw(blessed)`, and `List::Util qw(min max)` imports from `perl/FSM/HDL/FlattenedDT.pm`.
- Root cause / rationale:
  - repo-wide auditing showed that this entire substituted-AST matching pocket had become dead compatibility surface with no remaining code callers,
  - the live substitution/factorization flow already uses backend-owned helpers such as `update_original_asts_with_substituted_versions(...)`, `get_substituted_ast_for_signal(...)`, and `is_signal_referenced_in_substitutions(...)`,
  - removing the dead pocket is safer than preserving dormant AST/string matching heuristics in the `FlattenedDT` facade.
- Scope remains behavior-preserving cleanup of dead compatibility helpers; no live backend emission or factorization path changed.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=10`, `Tests=156`)
### FlattenedDT cleanup (retire dead standalone declaration helpers)
- Removed the dead standalone intermediate-declaration helper lane from `perl/FSM/HDL/FlattenedDT.pm`:
  - deleted `schedule_intermediate_signal_for_declaration(...)`,
  - deleted the compatibility-only `generate_intermediate_signal_declarations(...)` delegate,
  - deleted the adjacent unreferenced combinational-wire helper `get_combinational_lhs_signals(...)`.
- Removed the backend-side `generate_intermediate_signal_declarations(...)` implementation from `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`; the live declaration path already goes through consolidated intermediate emission plus `generate_internal_signal_declarations(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation leaves no legacy `intermediate_signals_to_declare` scratch state behind.
- Root cause / rationale:
  - repo-wide auditing showed the standalone declaration lane had become pure dead compatibility surface after consolidated intermediate emission became the authoritative runtime declaration path,
  - neither the `FlattenedDT` wrappers nor the backend helper had any remaining callsites, and the only scratch state they used was similarly unreferenced,
  - removing the whole lane is safer than leaving an alternate declaration path available for accidental reuse.
- Scope remains behavior-preserving cleanup of dead compatibility state; live intermediate declaration and emission behavior is unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=10`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=156`)
### FlattenedDT cleanup (retire dead LHS/RHS completeness tracking)
- Removed the dormant LHS/RHS completeness-tracking family from `perl/FSM/HDL/FlattenedDT.pm`:
  - deleted the legacy `expected_lhs_rhs`, `actual_lhs_rhs`, and `missing_lhs_rhs` state hashes from object construction,
  - deleted the raw-AST validation helpers `track_expected_lhs_rhs(...)`, `validate_lhs_rhs_completeness(...)`, `extract_lhs_rhs_from_raw_ast(...)`, `_traverse_raw_ast_for_lhs_rhs(...)`, and `_format_raw_rhs(...)`,
  - removed the no-longer-needed `track_actual_lhs_rhs(...)` compatibility delegate from `FlattenedDT`.
- Removed the remaining writes into that dead lane from `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` so live assignment/transition capture no longer records unused `actual_lhs_rhs` entries.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation leaves no legacy LHS/RHS tracking state behind (`expected_lhs_rhs`, `actual_lhs_rhs`, `missing_lhs_rhs`).
- Root cause / rationale:
  - repo-wide auditing showed the LHS/RHS completeness family had become pure dead compatibility/debug surface after the AST-first assignment/transition capture move,
  - the only live writes into the family came from `Orchestrator`, and no active runtime/backend path read that state or invoked the validation helpers,
  - deleting the dead lane is safer than preserving unused instrumentation because it shrinks the `FlattenedDT` facade and reduces the chance of reviving parallel non-semantic bookkeeping.
- Scope remains behavior-preserving cleanup of dead compatibility state; the live AST/CoreAST assignment capture and enable-synthesis path is unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=9`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=155`)
## 2026-03-11
### EnableGraph/SystemVerilog defining-AST metadata for consolidated filtering
- Updated `perl/FSM/Synthesis/EnableGraph.pm` so `track_ast_intermediate_signals()` now records `reference_ast` separately and attaches a native `defining_ast` for referenced intermediate signals when one is already available from AST-backed sources.
- Added `resolve_intermediate_signal_defining_ast()` to `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and updated the consolidated filtering/runtime path to use it before reparsing expressions.
- Updated the live backend flow so:
  - `should_filter_consolidated_signal()` prefers a resolved defining AST on the primary path,
  - prescan-referenced intermediate entries are merged into consolidated generation with cached defining-AST metadata,
  - consolidated dependency-map construction resolves defining ASTs before falling back to expression-only compatibility handling.
- Root cause / rationale:
  - after the AST-first dependency-extraction slice, the remaining live weakness on the same path was that expression-only entries could still force reparsing even when native defining ASTs were already derivable,
  - the next truthful cut was therefore to carry defining-AST metadata forward and centralize AST resolution on the consolidated filtering path rather than introducing another localized parse fallback.
- Scope remains behavior-preserving AST/CoreAST-first convergence on the live consolidated intermediate filtering path; no public backend entrypoint or emitter API changed in this slice.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### EnableGraph/SystemVerilog AST-first intermediate dependency extraction
- Added `extract_intermediate_signals_from_ast()` and `_collect_intermediate_signals_from_ast()` to `perl/FSM/Synthesis/EnableGraph.pm` so the live code can recover referenced intermediate signals by traversing AST nodes instead of scanning rendered SystemVerilog text.
- Updated `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` so:
  - consolidated intermediate-signal dependency-map construction now uses AST traversal whenever a defining AST is available,
  - factorization substitution tracing now extracts referenced intermediate signals directly from substituted ASTs,
  - pre-scan referenced signals are seeded with their defining AST from `get_intermediate_signal_ast()` when available.
- Updated `extract_intermediate_signals_from_expression()` to attempt expression parsing and delegate to AST traversal before falling back to legacy string scanning only when parsing fails.
- Root cause / rationale:
  - a fresh re-scan showed that `get_or_create_global_expression()` was not the strongest live runtime seam after the previous slice,
  - the real active string dependency was in consolidated intermediate-signal dependency extraction, which still identified referenced intermediates by regex over rendered expressions even when ASTs were already present,
  - this slice converts that live dependency-discovery path to AST-first behavior and narrows string scanning to compatibility fallback only.
- Scope remains behavior-preserving AST/CoreAST-first convergence on the live dependency/filtering path; no public backend entrypoint or emitter API changed in this slice.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### EnableGraph AST-backed intermediate-signal registry metadata
- Reworked `perl/FSM/Synthesis/EnableGraph.pm` so the live intermediate-signal registry can store structured entries with `ast`, `expression`, `name`, and `source` metadata instead of only bare expression strings when native ASTs are available.
- Updated `get_or_create_ast_signal_name()` and `get_or_create_global_expression()` to register that structured metadata on intermediate-signal creation/reuse, preserving the canonical expression string only as compatibility data rather than the primary semantic owner.
- Updated `is_signal_ast_based_intermediate()` and `get_intermediate_signal_ast()` so the live detection/lookup path now prefers AST factorizer data, AST-backed intermediate-registry entries, and FSM-module `driving_ast` metadata before any narrow compatibility parsing fallback.
- Updated `get_intermediate_signal_expression()` so intermediate-signal rendering now uses the defining AST when available and otherwise returns stored registry/global-expression text; the previous signal-name reconstruction fallback is no longer part of the live render path.
- Updated `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` so `count_binary_logical_operation_occurrences()` resolves native intermediate-signal ASTs through `EnableGraph` instead of reparsing `ctx->{intermediate_signals}` string payloads.
- Removed the leftover duplicate compatibility-parse line in `get_intermediate_signal_ast()` that was still triggering a Perl redeclaration warning after the registry conversion.
- Root cause / rationale:
  - the live intermediate-signal path still treated registry meaning as strings even when the surrounding pipeline already had defining ASTs,
  - that kept counting, lookup, and render decisions dependent on reparsing or reconstructing expressions instead of carrying AST/CoreAST-native ownership forward,
  - this slice converts the primary ownership path to AST-backed metadata while preserving narrow compatibility parsing only for legacy entries that still lack a stored defining AST.
- Scope remains behavior-preserving AST-first convergence on the live registry/count/render path; no public backend entrypoint or emitter API changed in this slice.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### EnableGraph AST-first logical-operation factor detection
- Reworked `contains_frequently_used_operations()` in `perl/FSM/Synthesis/EnableGraph.pm` so the live logical-operation factoring decision now recursively inspects AST nodes and resolved intermediate-signal ASTs instead of scanning rendered expressions and generated signal strings.
- Added `get_intermediate_signal_ast()` and `_parse_intermediate_expression_to_ast()` so existing registries can provide native ASTs first and only use expression parsing as a narrow compatibility fallback when no defining AST is stored yet.
- Updated `get_intermediate_signal_expression()` to render from the defining AST when one is available.
- Root cause / rationale:
  - the factorization decision path was still using a live string-based algorithm inside `EnableGraph`, even though the surrounding flow already had ASTs,
  - this made the next truthful AST/CoreAST-first slice a decision-path rewrite rather than more helper relocation from `FlattenedDT`,
  - the new implementation makes the reuse check AST-first while preserving behavior through narrow compatibility fallback where the registries still expose expression strings.
- Scope remains behavior-preserving decision-path convergence; no public backend entrypoint or output-stage API changed in this slice.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph redundant-parentheses helper ownership)
- Moved `parentheses_are_redundant()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to the new `enable_graph` helper implementation.
- Root cause / rationale:
  - after the prior `clean_intermediate_expression()` slice, no stronger still-live seam emerged in the same local parenthesis/sanitation pocket,
  - `parentheses_are_redundant()` was the smallest remaining helper in that in-flight lane, so moving it finished the slice cleanly without widening scope,
  - the user has now explicitly directed future convergence toward AST/CoreAST-native algorithms, so this closes the current string-helper cleanup lane rather than setting the default pattern for subsequent work.
- Scope remains behavior-preserving helper convergence only; no public backend entrypoint or live HDL emission call path changed in this slice.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph expression sanitation helper ownership)
- Moved `clean_intermediate_expression()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to the new `enable_graph` helper implementation.
- Root cause / rationale:
  - after re-scanning the nearby formatting and substitution pockets, no stronger still-live seam emerged than the already-moved `needs_parentheses()` helper,
  - `clean_intermediate_expression()` remained the smallest self-contained helper in the same string-expression sanitation lane, so moving it reduced facade ownership without overstating the amount of remaining live boundary there.
- Scope remains behavior-preserving helper convergence only; no public backend entrypoint or live HDL emission call path changed in this slice.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph string parenthesis helper ownership)
- Moved `needs_parentheses()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to the new `enable_graph` helper implementation.
- Root cause / rationale:
  - after the AST factorization-analysis pair moved, `needs_parentheses()` was the smallest remaining nearby helper with a clear live use on the DT-specific enable-generation path,
  - moving just this helper reduced facade ownership without pulling in the broader and less clearly justified legacy string-formatting pocket.
- Scope remains behavior-preserving helper convergence only; no public backend entrypoint or live HDL emission call path changed in this slice.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph AST factorization-analysis helper ownership)
- Moved `is_complex_ast()` and `should_factor_ast()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to the new `enable_graph` helper implementations.
- Root cause / rationale:
  - `EnableGraph::should_factor_condition()` already pointed at `should_factor_ast()` as the preferred AST-native path, but the actual AST factorization-analysis pair still lived in the `FlattenedDT` facade,
  - moving the pair into `EnableGraph` keeps the AST-native factorization decision logic with the adjacent condition-factorization helpers already localized there.
- Scope remains behavior-preserving helper convergence only; no public backend entrypoint or live HDL emission call path changed in this slice.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph legacy condition-factorization helper ownership)
- Moved `should_factor_condition()`, `analyze_ast_complexity()`, and `_traverse_ast_for_complexity()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to the new `enable_graph` helper implementations.
- Root cause / rationale:
  - these legacy condition-factorization helpers remained in the `FlattenedDT` facade immediately next to the registry/naming helpers already moved,
  - they analyze the same enable-expression space and fit `EnableGraph` more naturally than the compatibility shell.
- Scope remains behavior-preserving helper convergence only; no public backend entrypoint or live HDL emission call path changed in this slice.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
## 2026-03-10
### FlattenedDT backend convergence (EnableGraph global-expression registry helper ownership)
- Moved `get_or_create_global_expression()` and `canonicalize_expression()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to the new `enable_graph` helper implementations.
- Root cause / rationale:
  - these helpers still owned shared global-expression registry behavior in the `FlattenedDT` facade immediately next to the AST naming helpers already moved,
  - the underlying state they mutate (`global_expressions`, `expression_usage`, and `intermediate_signals`) already lives on the shared synthesis context that `EnableGraph` manages.
- Scope remains behavior-preserving helper convergence only; no public backend entrypoint or live HDL emission call path changed in this slice.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph AST signal-naming helper ownership)
- Moved `create_condition_expression_signal_name()`, `get_or_create_ast_signal_name()`, `generate_ast_based_signal_name()`, and `map_operator_to_name()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to the new `enable_graph` helper implementations.
- Root cause / rationale:
  - this AST signal-naming cluster still mutated `global_expressions`, `expression_usage`, and `intermediate_signals` from the `FlattenedDT` facade,
  - those registries already sit on the shared synthesis context used by `EnableGraph`, so ownership there is more coherent than leaving the helper pocket in the facade.
- Scope remains behavior-preserving helper convergence only; no public backend entrypoint or live HDL emission call path changed in this slice.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Verilog backend SystemVerilog-entry callsite convergence)
- Localized the live `generate_systemverilog()` call in `perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm` from the `FlattenedDT` facade to direct `orchestrator` ownership.
- Updated `Backend::Verilog::generate_verilog()` so SystemVerilog generation now goes through `$ctx->{orchestrator}->generate_systemverilog(...)`.
- Scope remains behavior-preserving callsite convergence only; no helper ownership or delegate structure changed in `perl/FSM/HDL/FlattenedDT.pm`.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Fixpoint second-pass update callsite convergence)
- Localized the live `update_original_asts_with_second_pass_substitutions()` call in `perl/FSM/HDL/Factorization/Fixpoint.pm` from the `FlattenedDT` facade to direct `backend_sv` ownership.
- Updated `run_post_substitution_factorization()` so second-pass AST updates now go through `$ctx->{backend_sv}->update_original_asts_with_second_pass_substitutions(...)`.
- Scope remains behavior-preserving callsite convergence only; no helper ownership or delegate structure changed in `perl/FSM/HDL/FlattenedDT.pm`.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/Factorization/Fixpoint.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Fixpoint second-pass feed callsite convergence)
- Localized the live `feed_current_asts_to_second_pass()` call in `perl/FSM/HDL/Factorization/Fixpoint.pm` from the `FlattenedDT` facade to direct `backend_sv` ownership.
- Updated `run_post_substitution_factorization()` so second-pass AST feeding now goes through `$ctx->{backend_sv}->feed_current_asts_to_second_pass(...)`.
- Scope remains behavior-preserving callsite convergence only; no helper ownership or delegate structure changed in `perl/FSM/HDL/FlattenedDT.pm`.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/Factorization/Fixpoint.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (SystemVerilog prescan intermediate-tracking callsite convergence)
- Localized the two live `track_ast_intermediate_signals()` callsites in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from the `FlattenedDT` facade to direct `EnableGraph` ownership.
- Updated DT-specific and LHS-level pre-scan tracking inside `prescan_wen_en_for_intermediate_signals()` to use `$ctx->{enable_graph}->track_ast_intermediate_signals(...)`.
- Scope remains behavior-preserving callsite convergence only; no helper ownership or delegate structure changed in `perl/FSM/HDL/FlattenedDT.pm`.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Factorization Fixpoint AST-to-SV callsite convergence)
- Localized the remaining non-local `ast_to_systemverilog()` callsites in `perl/FSM/HDL/Factorization/Fixpoint.pm` from the `FlattenedDT` facade to direct `EnableGraph` entry ownership.
- Updated pass-level debug rendering of new second-pass intermediate signals and `_build_expression_signature()` to use `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- Scope remains behavior-preserving callsite convergence only; no helper ownership or delegate structure changed in `perl/FSM/HDL/FlattenedDT.pm`.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/Factorization/Fixpoint.pm` (pass)
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
## 2026-03-08
### CI workflow unification for local pre-push execution
- Added a shared repo-owned CI entrypoint, `bin/ci-regression`, and updated `.github/workflows/regression.yml` to call it instead of inlining `prove -v t/01-regression.t`.
- The shared CI script now:
  - resolves the repository root automatically,
  - runs the full Perl regression suite with `prove -I perl t`.
- Removed the discarded Rust-specific `bin/check-rust-include-paths` guard after confirming the active CI path is Perl-only.
- Added `README.md` documentation for the local pre-push CI command.
- Validation:
  - `bash -lc 'cd /tmp && /Users/richarddje/Documents/github/fsmgen/bin/ci-regression'` (pass)
  - full regression passed (`Files=6`, `Tests=125`)
  - audited tracked `.github`, `bin`, `perl`, `t`, `README.md`, and `docs` content and found no active references to untracked `fx/`, `plugin/`, `specs/`, or machine-specific `/Users/...` paths
## 2026-03-09
### FlattenedDT backend convergence (EnableGraph binary operator-selection helper ownership)
- Moved `_choose_operator_symbol()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph->_choose_operator_symbol(...)`.
- Added the matching `List::Util::min` import in `EnableGraph.pm` so the copied helper keeps its existing debug-path behavior intact.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph binary operand-width helper ownership)
- Moved `_operand_is_single_bit()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph->_operand_is_single_bit(...)`.
- Scope remains behavior-preserving helper convergence only; binary rendering stays unchanged and `_choose_operator_symbol()` is now the remaining binary-support helper on the operator-selection path.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph binary signal-width helper ownership)
- Moved `_signal_is_single_bit()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph->_signal_is_single_bit(...)`.
- Retargeted FSM-module metadata access inside the moved helper through `EnableGraph`'s existing `flattened_dt` context so behavior stays unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph binary operator-mapping helper ownership)
- Moved `_map_binary_operator()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph->_map_binary_operator(...)`.
- Scope remains behavior-preserving helper convergence only; binary rendering stays unchanged and the remaining binary-support helpers are now concentrated in the bit-width/operator-selection path.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph binary precedence helper ownership)
- Moved `_get_operator_precedence()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph->_get_operator_precedence(...)`.
- Scope remains behavior-preserving helper convergence only; binary rendering stays unchanged and `_choose_operator_symbol()` / `_operand_is_single_bit()` are the remaining binary-support delegates.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph binary parenthesis-decision helper ownership)
- Moved `_needs_parentheses()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph->_needs_parentheses(...)`.
- Scope remains behavior-preserving helper convergence only; binary rendering stays unchanged and `_get_operator_precedence()` is now the smallest remaining isolated binary-support delegate.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph binary AST-to-SV render helper ownership)
- Moved `_render_binary_op()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph->_render_binary_op(...)`.
- Added narrow `EnableGraph` compatibility delegates for `_get_operator_precedence()`, `_choose_operator_symbol()`, `_needs_parentheses()`, and `_operand_is_single_bit()` so binary rendering stays behavior-preserving while the deeper binary-support helper cluster remains in `FlattenedDT`.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph unary negation parenthesization helper ownership)
- Moved `_operand_needs_parens_for_negation()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph->_operand_needs_parens_for_negation(...)`.
- Scope remains behavior-preserving helper convergence only; unary rendering stays unchanged and the unary-support helper lane is now exhausted.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph unary operator mapping helper ownership)
- Moved `_map_unary_operator()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph->_map_unary_operator(...)`.
- Scope remains behavior-preserving helper convergence only; unary rendering stays unchanged and `_operand_needs_parens_for_negation()` remains as the last isolated unary-support delegate.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph unary AST-to-SV render helper ownership)
- Moved `_render_unary_op()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph->_render_unary_op(...)`.
- Added narrow `EnableGraph` compatibility delegates for `_map_unary_operator()` and `_operand_needs_parens_for_negation()` so unary rendering stays behavior-preserving while those smaller support helpers remain in `FlattenedDT`.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph AST-to-SV internal helper ownership)
- Moved `_ast_to_systemverilog_internal()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph->_ast_to_systemverilog_internal(...)`.
- Added temporary `EnableGraph` compatibility delegates for `_render_binary_op()` and `_render_unary_op()` so the recursive render path stays behavior-preserving while the deeper render-helper cluster remains in `FlattenedDT`.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph AST-to-SV internal delegate callsite convergence)
- Localized the `ast_to_systemverilog()` render-internal callsite in `perl/FSM/Synthesis/EnableGraph.pm` so it no longer reaches directly into the `FlattenedDT` object for `_ast_to_systemverilog_internal(...)`.
- Updated `ast_to_systemverilog()` to route through a new `EnableGraph` compatibility delegate, `$self->_ast_to_systemverilog_internal(...)`, which preserves the existing `FlattenedDT` implementation boundary for now.
- Scope remains behavior-preserving callsite convergence only; the deeper render-helper family still lives in `perl/FSM/HDL/FlattenedDT.pm`, and no operator-selection or precedence behavior changed.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph LHS-enable intermediate tracking callsite convergence)
- Localized the `track_ast_intermediate_signals()` callsite in `perl/FSM/Synthesis/EnableGraph.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` self ownership.
- Updated `generate_lhs_enables_from_analysis()` so LHS-enable intermediate-signal tracking now goes through `$self->track_ast_intermediate_signals(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/Synthesis/EnableGraph.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph mux-config callsite convergence)
- Localized the phase-1 `build_multiplexer_config()` callsite in `perl/FSM/Synthesis/EnableGraph.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` self ownership.
- Updated `build_unified_assignment_analysis()` so multiplexer-config assembly now goes through `$self->build_multiplexer_config(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/Synthesis/EnableGraph.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph enable-structure callsite convergence)
- Localized the phase-1 `generate_complete_enable_structure()` callsite in `perl/FSM/Synthesis/EnableGraph.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` self ownership.
- Updated `build_unified_assignment_analysis()` so enable-structure generation now goes through `$self->generate_complete_enable_structure(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/Synthesis/EnableGraph.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph RHS-grouping callsite convergence)
- Localized the phase-1 `group_assignments_by_rhs()` callsite in `perl/FSM/Synthesis/EnableGraph.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` self ownership.
- Updated `build_unified_assignment_analysis()` so RHS grouping now goes through `$self->group_assignments_by_rhs(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/Synthesis/EnableGraph.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator signal-assignment callsite convergence)
- Localized the stage-8 `generate_signal_assignments()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` ownership.
- Updated `generate_systemverilog()` so final signal-assignment emission now goes through `$ctx->{enable_graph}->generate_signal_assignments(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/Synthesis/EnableGraph.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator WEN/EN-signal callsite convergence)
- Localized the stage-7 `generate_wen_en_signals()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Updated `generate_systemverilog()` so WEN/EN signal emission now goes through `$ctx->{backend_sv}->generate_wen_en_signals(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator consolidated-intermediate-signals callsite convergence)
- Localized the stage-6 `generate_consolidated_intermediate_signals()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Updated `generate_systemverilog()` so consolidated intermediate signal emission now goes through `$ctx->{backend_sv}->generate_consolidated_intermediate_signals(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### Repository asset tracking (plugin/ and specs/ now versioned)
- Added the existing `plugin/` and `specs/` trees to version control without changing their contents.
- This records the legacy `.plg` plugin inventory and spec/reference files directly in the repository for continuity and future modernization work.
- Validation:
  - post-commit `git --no-pager status --short` leaves only `?? fx/`
### FlattenedDT backend convergence (Orchestrator WEN/EN prescan callsite convergence)
- Localized the stage-5 `prescan_wen_en_for_intermediate_signals()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Updated `generate_systemverilog()` so the post-count pre-scan step now goes through `$ctx->{backend_sv}->prescan_wen_en_for_intermediate_signals()`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator logical-op-count callsite convergence)
- Localized the stage-4 `count_binary_logical_operation_occurrences()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Updated `generate_systemverilog()` so the pre-prescan logical-op counting step now goes through `$ctx->{backend_sv}->count_binary_logical_operation_occurrences()`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator generate-enable-conditions callsite convergence)
- Localized the stage-3 `generate_enable_conditions()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Updated `generate_systemverilog()` so enable-condition emission now goes through `$ctx->{backend_sv}->generate_enable_conditions(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator generate-internal-signal-declarations callsite convergence)
- Localized the stage-2 `generate_internal_signal_declarations()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Updated `generate_systemverilog()` so internal signal declaration emission now goes through `$ctx->{backend_sv}->generate_internal_signal_declarations(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator generate-state-register callsite convergence)
- Localized the stage-2 `generate_state_register()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Updated `generate_systemverilog()` so state-register emission now goes through `$ctx->{backend_sv}->generate_state_register(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator generate-state-encoding callsite convergence)
- Localized the stage-2 `generate_state_encoding()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Updated `generate_systemverilog()` so state-encoding emission now goes through `$ctx->{backend_sv}->generate_state_encoding(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator generate-module-declaration callsite convergence)
- Localized the stage-2 `generate_module_declaration()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Updated `generate_systemverilog()` so module-declaration emission now goes through `$ctx->{backend_sv}->generate_module_declaration(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator generate-header callsite convergence)
- Localized the stage-2 `generate_header()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Updated `generate_systemverilog()` so initial HDL assembly now goes through `$ctx->{backend_sv}->generate_header(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator unified-assignment-analysis callsite convergence)
- Localized the unified phase-1 `build_unified_assignment_analysis()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` ownership.
- Updated `flatten_all_decision_trees()` so phase-1 analysis now goes through `$ctx->{enable_graph}->build_unified_assignment_analysis(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/Synthesis/EnableGraph.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator stage-0 FSM-module-reference callsite convergence)
- Localized the stage-0 `set_fsm_module_reference()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` ownership.
- Updated `generate_systemverilog()` so FSM-module reference storage now goes through `$ctx->{enable_graph}->set_fsm_module_reference(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/Synthesis/EnableGraph.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator condition-helper callsite convergence)
- Localized the active Orchestrator condition-helper round-trips from `FlattenedDT` facade delegates to direct `EnableGraph` ownership in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`.
- Updated the following runtime callsites:
  - `convert_condition_to_ast()` in conditional-branch traversal,
  - `convert_test_value_to_ast()` in test-node branch construction,
  - `create_condition_expression()` in assignment and transition capture.
- Scope remains behavior-preserving callsite convergence only; helper ownership was already in `perl/FSM/Synthesis/EnableGraph.pm`, and `FlattenedDT` compatibility delegates remain unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (actual LHS/RHS tracking orchestration ownership)
- Moved `track_actual_lhs_rhs()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `orchestrator->track_actual_lhs_rhs(...)`.
- Updated the orchestrator-owned assignment and transition capture paths so actual LHS/RHS validation tracking now stays local to `FlattenedDT::Orchestrator` instead of round-tripping through the façade.
- Scope remains behavior-preserving structural convergence only; the dormant expected/raw-AST completeness helpers were intentionally left in `FlattenedDT` because they are not part of the active runtime path.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### Architecture documentation (frontend parser/input-format decoupling direction)
- Added a living architecture note to `DEVELOPMENT_NOTES.md` describing how FSMGen should decouple source file format / parser concerns from the semantic core.
- Recorded the current validated boundary:
  - `FSM::Pipeline::HDLGenerator` still directly depends on `Lispish`,
  - `FSM::Adapter::FSMGenFull::*` still decodes current `.fsm` / Lispish syntax,
  - downstream analysis and backend code already operate mostly on `FSM::CoreAST`.
- Recorded the architectural rule that future frontends should lower into `FSM::CoreAST` rather than teaching synthesis/backend code multiple parser-specific raw AST shapes.
- Scope is documentation-only; no HDL-generation behavior changed.
### FlattenedDT backend convergence (assignment-capture orchestration ownership)
- Moved `extract_lhs_name_from_ast()`, `record_assignment_from_ast()`, and `extract_rhs_from_expression()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `orchestrator->extract_lhs_name_from_ast(...)`, `orchestrator->record_assignment_from_ast(...)`, and `orchestrator->extract_rhs_from_expression(...)`.
- Updated the orchestrator-owned recursive flattener so assignment handling now stays local to `FlattenedDT::Orchestrator` instead of round-tripping through the façade for LHS-name extraction, assignment capture, and RHS-expression recursion.
- Scope remains behavior-preserving structural convergence only; assignment intent handling, condition capture, LHS/RHS validation tracking, and emitted HDL semantics are unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (state-transition capture orchestration ownership)
- Moved `record_transition_from_ast()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `orchestrator->record_transition_from_ast(...)`.
- Updated the orchestrator-owned recursive flattener so state-transition handling now stays local to `FlattenedDT::Orchestrator` instead of round-tripping through the façade for this capture step.
- Scope remains behavior-preserving structural convergence only; state-transition capture still uses the existing shared condition-construction and tracking helpers and does not change emitted HDL semantics.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (recursive flattener orchestration ownership)
- Moved `flatten_decision_tree()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `orchestrator->flatten_decision_tree(...)`.
- Updated the orchestrator-owned traversal flow so recursion now stays local to `FlattenedDT::Orchestrator` instead of round-tripping through the façade for each nested decision-tree node.
- Scope remains behavior-preserving structural convergence only; the recursive flattener still delegates to the existing `FlattenedDT` AST-capture helpers and does not change emitted HDL semantics.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (flatten-all-decision-trees orchestration ownership)
- Moved `flatten_all_decision_trees()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `orchestrator->flatten_all_decision_trees(...)`.
- Updated `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` so `generate_systemverilog()` now invokes the orchestrator-owned entrypoint directly.
- Scope remains behavior-preserving structural convergence only; this localizes a live flattening step under orchestration ownership without changing downstream enable or backend behavior.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (AST condition-helper ownership)
- Moved `create_condition_expression()`, `convert_condition_to_ast()`, and `convert_test_value_to_ast()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph` for all three helpers.
- Scope remains behavior-preserving structural convergence only; this localizes the live AST condition-construction helper trio beside the existing enable-synthesis helper layer without changing flattening callsites.
- Important implementation note:
  - an explicit `use FSM::AST::Utils;` in `EnableGraph` was intentionally not kept because it exposes an incompatible AST helper load path in this repository; the final slice preserves the existing working runtime path.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
## 2026-03-07
### FlattenedDT backend convergence (WEN/EN prescan entrypoint ownership)
- Moved `prescan_wen_en_for_intermediate_signals()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->prescan_wen_en_for_intermediate_signals()`.
- Scope remains behavior-preserving structural convergence only; this localizes the live WEN/EN intermediate-signal prescan step beside the backend-owned intermediate-signal generation flow without changing Orchestrator call order.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (AST sub-expression analysis helper ownership)
- Moved `analyze_ast_sub_expressions()`, `find_all_ast_sub_expressions()`, and `is_simple_ast_expression()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to the backend for all three helpers.
- Scope remains behavior-preserving structural convergence only; the moved trio is a cohesive AST-analysis seam from the adjacent factorization helper cluster.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (intermediate-signal generation entrypoint ownership)
- Moved `generate_intermediate_signals()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->generate_intermediate_signals(...)`.
- Scope remains behavior-preserving structural convergence only; the moved entrypoint now lives beside its backend-owned `run_global_ast_factorization()` dependency.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (logical-op-count helper-pair ownership)
- Moved `_count_logical_ops_in_ast()` and `_is_factorizable_sub_expression()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->_count_logical_ops_in_ast(...)` and `backend_sv->_is_factorizable_sub_expression(...)`.
- Updated the backend-owned logical-op-count flow to recurse through `$self->_count_logical_ops_in_ast(...)` instead of round-tripping back through `FlattenedDT`.
- Scope remains behavior-preserving structural convergence only; this completes backend-local ownership of the active logical-op-count helper family.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (logical-op-count collector ownership)
- Moved `collect_all_wen_en_ast_expressions()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->collect_all_wen_en_ast_expressions()`.
- Updated the backend-owned logical-op-count flow to collect AST expressions through `$self->collect_all_wen_en_ast_expressions()` instead of round-tripping back through `FlattenedDT`.
- Scope remains behavior-preserving structural convergence only; the remaining logical-op-count helper move is `_count_logical_ops_in_ast()` together with its coupled `_is_factorizable_sub_expression()` policy helper.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (logical-op-count entrypoint ownership)
- Moved `count_binary_logical_operation_occurrences()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->count_binary_logical_operation_occurrences()`.
- The backend-owned entrypoint still calls back into `FlattenedDT` for the currently unmoved helpers `collect_all_wen_en_ast_expressions()` and `_count_logical_ops_in_ast()`, so scope remains a small behavior-preserving ownership step rather than a full family move.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (logical-op-count wrapper callsite)
- Localized the remaining direct `run_global_ast_factorization` backend method-call round-trip in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by routing `count_binary_logical_operation_occurrences()` through a backend-local helper.
- Added backend-local helper `count_binary_logical_operation_occurrences()` and switched the factorization fallback callsite from direct `FlattenedDT` invocation to `$self->count_binary_logical_operation_occurrences()`.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (bare intermediate-signal trace render callsite)
- Localized one remaining backend render/helper round-trip in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_clean_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the bare `FSM::HDL::IntermediateSignalRef` trace render inside `ast_contains_intermediate_signals`, continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (factorizer substituted-AST trace render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the factorizer substituted-AST trace render inside `get_substituted_ast_for_signal`, continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (assignment-condition second-pass substituted-AST debug render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the assignment-condition substituted-AST debug render inside `update_original_asts_with_second_pass_substitutions`, continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (assignment-condition second-pass original-AST debug render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the assignment-condition original-AST debug render inside `update_original_asts_with_second_pass_substitutions`, continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (LHS-level second-pass substituted-AST debug render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the LHS-level substituted-AST debug render inside `update_original_asts_with_second_pass_substitutions`, continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (LHS-level second-pass original-AST debug render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the LHS-level original-AST debug render inside `update_original_asts_with_second_pass_substitutions`, continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (DT-specific second-pass substituted-AST debug render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the DT-specific substituted-AST debug render inside `update_original_asts_with_second_pass_substitutions`, continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (original-AST consolidated fallback render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the original-AST fallback branch of consolidated intermediate-signal assign generation (`generate_consolidated_intermediate_signals`), continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (substituted-AST consolidated render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the substituted-AST branch of consolidated intermediate-signal assign generation (`generate_consolidated_intermediate_signals`), continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
## 2026-03-06
### FlattenedDT backend convergence (final-filtered debug AST render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the final-filtered debug listing of consolidated intermediate-signal generation (`generate_consolidated_intermediate_signals`), continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (rescued-signal debug AST render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the rescued-signal debug listing of consolidated intermediate-signal generation (`generate_consolidated_intermediate_signals`), continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (initial-filtering AST render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the initial filtering pass of consolidated intermediate-signal generation (`generate_consolidated_intermediate_signals`), continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (dependency-map AST render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in consolidated intermediate-signal dependency-map construction (`generate_consolidated_intermediate_signals`), further aligning backend callsites with direct `EnableGraph` ownership.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### README promoted as project single entry point
- Reworked `README.md` into the canonical onboarding hub for the repository.
- Added explicit project objective and ramp-up sequence.
- Added complete markdown index for all repository `.md` files:
  - `README.md`
  - `CHANGES.md`
  - `DEVELOPMENT_NOTES.md`
  - `MEMORY.md`
  - `COMMIT.md`
  - `WARP.md`
  - `docs/USER_GUIDE.md`
  - `.agents/workflows/commit.md`
- Added key project file/path references for core pipeline, backend, synthesis, tests, and support directories.
- Added README maintenance policy clarifying that README is updated when onboarding-critical information changes, not necessarily on every commit.
## 2026-02-28
### FlattenedDT backend decomposition continuation (final-expression usage-check helper)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving final-expression usage-check helper ownership (`is_signal_actually_used_in_final_expressions`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->is_signal_actually_used_in_final_expressions(...)`.
- Updated backend AST/string filtering paths to invoke backend-local usage-check helper (`$self->is_signal_actually_used_in_final_expressions(...)`) while preserving behavior.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend decomposition continuation (string-fallback filtering helper)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving string-fallback filtering helper ownership (`should_filter_string_based`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->should_filter_string_based(...)`.
- Updated backend consolidated-signal filtering fallback path to invoke backend-local helper (`$self->should_filter_string_based(...)`) while preserving behavior.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend decomposition continuation (simple-comparison helper)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving simple-comparison helper ownership (`is_simple_comparison`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->is_simple_comparison(...)`.
- Updated backend AST-based filtering flow to invoke backend-local simple-comparison helper (`$self->is_simple_comparison(...)`) while preserving behavior.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend decomposition continuation (simple-negation helper)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving simple-negation helper ownership (`is_simple_negation`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->is_simple_negation(...)`.
- Updated backend AST-based filtering flow to invoke backend-local simple-negation helper (`$self->is_simple_negation(...)`) while preserving behavior.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend decomposition continuation (AST-based filtering helper)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving AST-based filtering helper ownership (`should_filter_ast_based`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->should_filter_ast_based(...)`.
- Updated backend consolidated-signal filtering flow to invoke backend-local AST filtering helper (`$self->should_filter_ast_based(...)`) while preserving behavior.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend decomposition continuation (consolidated-signal filtering entrypoint)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving consolidated-signal filtering ownership (`should_filter_consolidated_signal`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->should_filter_consolidated_signal(...)`.
- Updated backend consolidated intermediate-signal generation callsite to use backend-local helper invocation (`$self->should_filter_consolidated_signal(...)`) while preserving behavior.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
## 2026-02-27
### FlattenedDT backend decomposition continuation (intermediate-reference extraction helper)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving intermediate-reference extraction ownership (`extract_intermediate_signals_from_expression`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->extract_intermediate_signals_from_expression(...)`.
- Updated backend dependency/trace callsites to use backend-local helper invocation (`$self->extract_intermediate_signals_from_expression(...)`) while preserving behavior.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend decomposition continuation (substituted intermediate AST resolver)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving substituted intermediate AST resolver ownership (`get_substituted_ast_for_signal`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->get_substituted_ast_for_signal(...)`.
- Updated backend consolidated-intermediate emission flow to use backend-local resolver call (`$self->get_substituted_ast_for_signal(...)`) while preserving behavior.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend decomposition continuation (recursive intermediate-signal detector)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving recursive intermediate-signal detector ownership (`ast_has_intermediate_signals_recursive`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->ast_has_intermediate_signals_recursive(...)`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend decomposition continuation (second-pass intermediate-expression filter)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving second-pass intermediate-expression filter ownership (`ast_contains_intermediate_signals`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->ast_contains_intermediate_signals(...)`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend decomposition continuation (second-pass substitution update helper)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving second-pass AST substitution update ownership (`update_original_asts_with_second_pass_substitutions`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->update_original_asts_with_second_pass_substitutions(...)`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend decomposition continuation (second-pass AST feed helper)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving second-pass AST feeding ownership (`feed_current_asts_to_second_pass`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->feed_current_asts_to_second_pass(...)`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### Shared post-substitution factorization package extraction
- Added new backend-neutral package `perl/FSM/HDL/Factorization/Fixpoint.pm` with purpose-specific naming: `FSM::HDL::Factorization::Fixpoint`.
- Moved iterative post-substitution factorization algorithm ownership from `Backend::SystemVerilog` into this shared package so all backends can consume the same convergence engine.
- Updated `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - imports `FSM::HDL::Factorization::Fixpoint`,
  - `run_second_pass_factorization(...)` is now a compatibility delegate that calls the shared package.
- Factorization convergence behavior remains deterministic and bounded by explicit termination guards (no candidates/progress, repeated signature, max-pass cap).
- Validation:
  - `perl -I perl -c perl/FSM/HDL/Factorization/Fixpoint.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend decomposition continuation
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving second-pass factorization orchestration ownership (`run_second_pass_factorization`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->run_second_pass_factorization(...)`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving AST substitution-backpropagation helper ownership (`update_original_asts_with_substituted_versions`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->update_original_asts_with_substituted_versions(...)`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving unary-negation counting helper ownership (`count_unary_negations_in_original_expressions`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->count_unary_negations_in_original_expressions()`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving AST-factorizer input feeding ownership (`feed_asts_to_factorizer`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->feed_asts_to_factorizer(...)`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving global AST-factorization orchestration ownership (`run_global_ast_factorization`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->run_global_ast_factorization()`.
- Added required backend import support for migrated logic (`List::Util::min`) in `Backend::SystemVerilog`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving consolidated intermediate-signal emission ownership (`generate_consolidated_intermediate_signals`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->generate_consolidated_intermediate_signals(...)`.
- Added required backend import support for migrated logic (`Scalar::Util::blessed`) in `Backend::SystemVerilog`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### First-class multi-level tracing rollout
- Implemented first-class tracing core in `perl/FSM/Debug.pm` with named verbosity levels (`none`, `low`, `medium`, `high`, `debug`) mapped to `0..4`.
- Preserved numeric compatibility via existing debug-level flow (`--debug[=N]`), with bare `--debug` treated as max verbosity.
- Added structured trace helpers and formatting primitives for topic/enter/exit/decision tracing with source metadata (`file`, `function`, `line`) and indentation-aware output.
- Added configurable trace output routing:
  - new trace filehandle controls in debug core,
  - trace output now routes to `trace.log` (or selected file) instead of stdout when trace-log routing is enabled.
- Integrated CLI trace controls in `bin/fsmgen`:
  - `--trace-verbosity <none|low|medium|high|debug>`,
  - `--trace-log[=FILE]` (default `trace.log`),
  - `--trace-emojis` / `--notrace-emojis`.
- Removed legacy tee-based debug-log handling from `bin/fsmgen` and aligned run-finalization cleanup with trace-file lifecycle handling.
- Added structured trace hooks across key generation/parsing surfaces:
  - `perl/FSM/Pipeline/HDLGenerator.pm`,
  - `perl/FSM/Adapter/FSMGenFull.pm`,
  - `perl/FSM/Adapter/FSMGenFull/Parser.pm`.
- Updated user-facing docs:
  - `README.md`,
  - `docs/USER_GUIDE.md`.
- Added tracing regression coverage:
  - `t/06-tracing-system.t` validating trace-file capture and trace metadata format.
- Validation:
  - syntax checks for touched Perl modules/scripts: pass,
  - full suite: `prove -I perl t` -> `Files=6, Tests=125, PASS`.
### Commit workflow documentation hardening
- Added new tracked workflow document `COMMIT.md` as the canonical commit-process reference for AI handoff continuity.
- Documented precise commit workflow scope and cadence:
  - run after each completed task/activity,
  - include required file update order and post-commit cleanup.
- Documented exact role of involved files:
  - `COMMIT.md`, `MEMORY.md`, `CHANGES.md`, `DEVELOPMENT_NOTES.md`, `git_message_brief.txt`, and task-touched source/test files.
- Documented exact operational sequence:
  - task completion, ordered doc updates, validation, commit message preparation, staging, commit, message-file truncation, and final status verification.
## 2026-02-26
### FlattenedDT backend decomposition continuation
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving WEN/EN emission entrypoint ownership (`generate_wen_en_signals`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->generate_wen_en_signals(...)`.
- Scope of this slice remains behavior-preserving refactor only (ownership move + delegation), with no intended HDL semantic change.
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving intermediate-signal declaration emission ownership (`generate_intermediate_signal_declarations`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->generate_intermediate_signal_declarations(...)`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving combinational-mux emission ownership (`generate_comb_mux`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->generate_comb_mux(...)`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving flop-mux emission ownership (`generate_flop_mux`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->generate_flop_mux(...)`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
## 2026-02-24
### FlattenedDT decomposition kickoff: explicit orchestrator track
- Recorded and aligned roadmap direction to decompose remaining `FlattenedDT` responsibilities across two direct breakdown tracks:
  - `Orchestrator` for top-level generation sequencing,
  - backend emitter modules for rendering ownership.
- Clarified ownership language: `FSM::Synthesis::EnableGraph` remains a synthesis helper module used by `FlattenedDT`, not a direct `FlattenedDT` submodule breakdown track.
- Added a dedicated orchestrator module:
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`.
- Moved `generate_systemverilog` pipeline sequencing ownership out of `FlattenedDT` into `FlattenedDT::Orchestrator` without changing generated HDL behavior.
- Updated `FlattenedDT` to instantiate the orchestrator and delegate `generate_systemverilog(...)` through a compatibility facade.
- Added dedicated backend module namespace:
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Moved module declaration emission ownership (`generate_module_declaration`) out of `FlattenedDT` into `FlattenedDT::Backend::SystemVerilog` without changing generated HDL behavior.
- Updated `FlattenedDT` to instantiate the backend module and delegate `generate_module_declaration(...)` through a compatibility facade.
- Continued backend decomposition with state-encoding emission ownership (`generate_state_encoding`) moved out of `FlattenedDT` into `FlattenedDT::Backend::SystemVerilog` without changing generated HDL behavior.
- Updated `FlattenedDT` to delegate `generate_state_encoding(...)` through the backend compatibility facade.
- Continued backend decomposition with state-register emission ownership (`generate_state_register`) moved out of `FlattenedDT` into `FlattenedDT::Backend::SystemVerilog` without changing generated HDL behavior.
- Updated `FlattenedDT` to delegate `generate_state_register(...)` through the backend compatibility facade.
- Continued backend decomposition with enable-conditions emission ownership (`generate_enable_conditions`) moved out of `FlattenedDT` into `FlattenedDT::Backend::SystemVerilog` without changing generated HDL behavior.
- Updated `FlattenedDT` to delegate `generate_enable_conditions(...)` through the backend compatibility facade.
- Continued backend decomposition with header emission ownership (`generate_header`) moved out of `FlattenedDT` into `FlattenedDT::Backend::SystemVerilog` without changing generated HDL behavior.
- Updated `FlattenedDT` to delegate `generate_header(...)` through the backend compatibility facade.
- Continued backend decomposition with internal-signal declaration ownership (`generate_internal_signal_declarations`) moved out of `FlattenedDT` into `FlattenedDT::Backend::SystemVerilog` without changing generated HDL behavior.
- Updated `FlattenedDT` to delegate `generate_internal_signal_declarations(...)` through the backend compatibility facade.
- Added dedicated Verilog backend module:
  - `perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm`.
- Moved Verilog generation ownership (`generate_verilog`, `convert_systemverilog_to_verilog`) out of `FlattenedDT` into `FlattenedDT::Backend::Verilog` without changing generated HDL behavior.
- Updated `FlattenedDT` to instantiate `Backend::Verilog` and delegate Verilog-generation entrypoints through the compatibility facade.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm` (pass)
  - `prove -I perl t` (pass: 5 files, 117 tests)

## 2026-02-22
### Phase 1 modernization slice: explicit assignment intent metadata
- Added explicit assignment-intent metadata to CoreAST assignment objects:
  - `assignment_intent` (operator symbol, sequencing mode, register style, assignment family)
  - `source_provenance` (raw operator/signal/value context)
  - `output_exposure` (`auto`/`explicit`)
- Added assignment-level accessors:
  - `assignment_intent`, `source_provenance`, `output_exposure`, `operator_symbol`, `register_style`.

### Parser wiring for intent-first semantics
- Updated `perl/FSM/Adapter/FSMGenFull/Parser.pm` signal-action construction to emit explicit intent for:
  - `<-` => clocked `output_named`, `lhs_binding=flop_q_output`
  - `<=` => clocked `input_named`, `lhs_binding=flop_d_input`, `immediate_visibility=same_cycle_on_d_input`, `hold_policy=q_feedback_when_no_enable`
  - `=`  => combinatorial
- Added parser provenance capture and explicit-output exposure propagation from `>` LHS marker.

### Backend updates
- Updated `perl/FSM/HDL/FlattenedDT.pm` assignment recording to consume assignment-intent metadata directly and fail fast on missing/invalid operator intent.
- Added intent metadata to synthesized state-transition assignment records for uniform downstream handling.
- Tightened assignment-type classification (`register_out` / `register_in` / `mux_out`) to require explicit operator presence in analysis records.

### Tests
- Added `t/03-assignment-intent-metadata.t` to validate:
  - parser metadata emission for `<-`, `<=`, `=`
  - explicit-output exposure from `>` marker
  - backend assignment-type classifier behavior.
- Validation run:
  - `prove -v t/03-assignment-intent-metadata.t t/02-combinational-self-dependency.t t/01-regression.t` (pass).

### Legacy reference documentation and semantic clarification
- Archived the full legacy `fx/perl/FSMGen.pm` analysis in `DEVELOPMENT_NOTES.md` for future modernization work.
- Clarified authoritative `<N` / `pN` semantics from framework intent:
  - `<N` means an exact one-cycle pulse emitted at decision cycle `Q+N` (N is delay, not pulse width).
  - Legacy code has intent markers/comments for pulse behavior but does not implement a dedicated pulse backend yet.

### Assignment-family completion (`c`, `r`, `m`, `rm`, `mr`, `pN`)
- Extended parser/operator handling to cover all requested operator families:
  - `=`, `<-`, `<=`, `<-=`, `<=+`, `<N`.
- Added/normalized intent metadata and backend classification for:
  - `register_out`, `register_in`, `register_out_dual`, `register_in_dual`, `pulse_delayed`, `mux_out`.
- Implemented rm/mr auxiliary exposure behavior in emitted HDL:
  - `<-=` exposes `next_<lhs>`
  - `<=+` exposes `<lhs>_r`
- Implemented delayed pulse backend generation for `<N` with authoritative semantics:
  - exact `Q+N` emission,
  - fixed one-cycle pulse width,
  - polarity from RHS (`<N 1` positive pulse, `<N 0` negative pulse),
  - **delay** semantics (not duration).
- Fixed signal metadata/width propagation issues that affected auxiliary port direction/width:
  - auxiliary outputs now emit as outputs (not inferred inputs),
  - auxiliary widths track parent signal widths even when `+size` appears after assignment actions.
- Validation:
  - `prove -I perl t/03-assignment-intent-metadata.t` (pass)
  - `prove -I perl t/02-combinational-self-dependency.t t/01-regression.t` (pass)
  - `prove -I perl t` (full suite pass)

### Assignment semantics hardening: edge cases + golden snapshots
- Added focused edge-case regression `t/04-assignment-edge-cases.t`:
  - validates `<0 1` / `<0 0` immediate delayed-pulse semantics (`Q+0`, no delay pipeline register),
  - rejects invalid `<N` RHS values (must be literal `0` or `1`),
  - rejects mixed incompatible assignment families on same LHS:
    - combinational + sequential,
    - pulse-delayed + non-pulse sequential,
    - multiple conflicting pulse delays.
- Added golden snapshot regression `t/05-assignment-hdl-snapshots.t` and fixtures under `t/golden/` for:
  - module port exposure/widths (including `next_*` and `*_r`),
  - rm (`<-=`) emitted block shape,
  - mr (`<=+`) emitted block shape,
  - pN delayed pulse blocks for `<2 0` and `<3 1`.

### Architecture slice start: enable synthesis extraction
- Added initial dedicated enable-synthesis layer:
  - `perl/FSM/Synthesis/EnableGraph.pm`
- Refactored `FlattenedDT` to delegate complete enable-structure synthesis via `EnableGraph`:
  - keeps current behavior unchanged while establishing an extraction seam for subsequent slices.
- Follow-up extraction increment:
  - moved RHS grouping orchestration (`group_assignments_by_rhs`) from `FlattenedDT` into `EnableGraph`,
  - `FlattenedDT` now delegates this step to the synthesis layer as part of unified assignment analysis.
- Latest extraction increment:
  - moved multiplexer configuration assembly (`build_multiplexer_config`) from `FlattenedDT` into `EnableGraph`,
  - `FlattenedDT` now delegates this step as well, expanding the synthesis-layer seam while preserving behavior.
- Newest extraction increment:
  - moved unified assignment-analysis orchestration (`build_unified_assignment_analysis`) from `FlattenedDT` into `EnableGraph`,
  - `FlattenedDT` now delegates the top-level per-LHS analysis loop to the synthesis layer.
- Latest extraction increment:
  - moved unified phase-2 WEN/EN generation (`generate_unified_wen_en_signals`) into `EnableGraph`,
  - moved DT-specific and LHS-level enable emission helpers (`generate_dt_enables_from_analysis`, `generate_lhs_enables_from_analysis`) into `EnableGraph`,
  - `FlattenedDT` now delegates these phase-2 enable emission entrypoints to the synthesis layer.
- Newest extraction increment:
  - moved unified phase-3 multiplexer orchestration (`generate_signal_assignments`) into `EnableGraph`,
  - `FlattenedDT` now delegates the phase-3 assignment-emission entrypoint to the synthesis layer while keeping mux-specific emitters behavior-identical.
- Latest extraction increment:
  - moved unified combinational mux emitter (`generate_unified_comb_mux`) into `EnableGraph`,
  - updated phase-3 orchestration in `EnableGraph` to call its local combinational mux emitter,
  - `FlattenedDT` now delegates the combinational mux emitter entrypoint to the synthesis layer.
- Newest extraction increment:
  - moved unified flop mux emitter (`generate_unified_flop_mux`) into `EnableGraph`,
  - updated phase-3 orchestration in `EnableGraph` to call its local flop mux emitter,
  - `FlattenedDT` now delegates the flop mux emitter entrypoint to the synthesis layer.
- Latest continuity increment:
  - added new live recovery document `MEMORY.md` for crash/session-handoff continuity,
  - documented mandatory workflow: update `MEMORY.md` and other live docs before every commit workflow,
  - documented compact resume checklist and current extraction status snapshot for successor agents.
- Newest extraction increment:
  - moved unified pulse-delay emitter (`generate_unified_pulse_delay_logic`) into `EnableGraph`,
  - updated phase-3 orchestration in `EnableGraph` to call its local pulse-delay emitter,
  - `FlattenedDT` now delegates the pulse-delay emitter entrypoint to the synthesis layer.
- Latest extraction increment:
  - moved pulse helper analysis methods (`get_pulse_delay_cycles_for_lhs`, `get_pulse_active_level_for_lhs`, `normalize_rhs_logic_level`) into `EnableGraph`,
  - updated `EnableGraph` pulse-delay emission path to use local helper methods,
  - `FlattenedDT` now keeps compatibility delegations for those helper entrypoints.
- Newest extraction increment:
  - moved enable naming helpers (`clean_signal_name`, `generate_rhs_based_enable_name`) into `EnableGraph`,
  - updated enable-structure generation in `EnableGraph` to use local naming helper ownership,
  - `FlattenedDT` now keeps compatibility delegations for those naming helper entrypoints.
- Latest extraction increment:
  - moved assignment-type helpers (`signal_uses_register_assignment`, `get_signal_assignment_type`) into `EnableGraph`,
  - updated `EnableGraph` phase-3 paths to resolve assignment family through local helper ownership,
  - `FlattenedDT` now keeps compatibility delegations for these assignment-type helper entrypoints.
- Latest extraction increment:
  - moved driven-signal classification (`get_driven_signals`) into `EnableGraph`,
  - module declaration output-direction inference still resolves driven signals through `FlattenedDT` compatibility delegation,
  - `EnableGraph` now owns auxiliary-output driven classification for `rm` (`next_<lhs>`) and `mr` (`<lhs>_r`) using local assignment-type ownership.
- Newest extraction increment:
  - moved reset-value resolution helper (`get_reset_value`) into `EnableGraph`,
  - `FlattenedDT` now delegates reset-value lookup to `EnableGraph` via compatibility shim,
  - `EnableGraph` currently resolves reset-state and signal reset metadata through existing `FlattenedDT` reset-info helpers to preserve behavior during staged extraction.
- Latest extraction increment:
  - moved default-value resolution helper (`get_default_value`) into `EnableGraph`,
  - `FlattenedDT` now delegates default-value lookup to `EnableGraph` via compatibility shim,
  - `get_default_value_from_ast` behavior remains unchanged and now resolves through the delegated default-value ownership path.
- Newest extraction increment:
  - moved signal-info helper (`get_signal_info`) into `EnableGraph`,
  - `FlattenedDT` now delegates signal-info lookup to `EnableGraph` via compatibility shim,
  - reset-value resolution in `EnableGraph` now uses local signal-info ownership while preserving existing reset-state/explicit-reset helper paths.
- Latest extraction increment:
  - moved explicit-reset helper (`get_explicit_reset_value`) into `EnableGraph`,
  - `FlattenedDT` now delegates explicit-reset lookup to `EnableGraph` via compatibility shim,
  - reset-value resolution in `EnableGraph` now uses local explicit-reset ownership while preserving existing reset-state helper path.
- Newest extraction increment:
  - moved FSM reset-state helper (`get_fsm_reset_state`) into `EnableGraph`,
  - `FlattenedDT` now delegates reset-state lookup to `EnableGraph` via compatibility shim,
  - reset-value resolution in `EnableGraph` now uses local reset-state ownership for `next_state` semantics.
- Latest extraction increment:
  - moved AST reset-value helper (`get_reset_value_from_ast`) into `EnableGraph`,
  - updated `EnableGraph` flop-mux emission to call local AST reset-value ownership,
  - `FlattenedDT` now delegates AST reset-value lookup to `EnableGraph` via compatibility shim.
- Newest extraction increment:
  - moved AST default-value helper (`get_default_value_from_ast`) into `EnableGraph`,
  - updated `EnableGraph` multiplexer config assembly to call local AST default-value ownership,
  - `FlattenedDT` now delegates AST default-value lookup to `EnableGraph` via compatibility shim.
- Latest extraction increment:
  - moved explicit-reset configuration setter (`set_explicit_reset_values`) into `EnableGraph`,
  - `FlattenedDT` now delegates explicit-reset configuration to `EnableGraph` via compatibility shim,
  - `EnableGraph` now owns writes to explicit reset-value configuration consumed by reset-resolution helpers.
- Newest extraction increment:
  - moved FSM module-reference setter (`set_fsm_module_reference`) into `EnableGraph`,
  - `FlattenedDT` now delegates FSM module-reference storage to `EnableGraph` via compatibility shim,
  - `EnableGraph` now owns writes to the shared FSM module reference used by signal-info/reset helper paths.
- Latest extraction increment:
  - moved register-classification helpers (`is_register`, `fallback_register_analysis_from_assignments`) into `EnableGraph`,
  - updated `EnableGraph` multiplexer configuration assembly to resolve register-vs-combinational selection through local helper ownership,
  - `FlattenedDT` now delegates register-classification helper entrypoints to `EnableGraph` via compatibility shims.
- Newest extraction increment:
  - moved AST signal-name extraction helper (`extract_signal_name_from_ast`) into `EnableGraph`,
  - updated `EnableGraph` AST reset/default helper paths to resolve signal names through local helper ownership,
  - `FlattenedDT` now delegates AST signal-name extraction to `EnableGraph` via compatibility shim.
- Latest extraction increment:
  - moved LHS-width analysis helper (`get_lhs_width_from_analysis`) into `EnableGraph`,
  - updated `EnableGraph` pulse-delay emission path to resolve target width through local helper ownership,
  - `FlattenedDT` now delegates LHS-width analysis to `EnableGraph` via compatibility shim.
- Newest extraction increment:
  - moved intermediate-signal AST tracker (`track_ast_intermediate_signals`) into `EnableGraph`,
  - updated `EnableGraph` DT/LHS enable emission paths to call local intermediate-signal tracking ownership,
  - `FlattenedDT` now delegates intermediate-signal AST tracking to `EnableGraph` via compatibility shim.
- Latest extraction increment:
  - moved intermediate-signal classification helper (`is_intermediate_signal`) into `EnableGraph`,
  - updated `EnableGraph` intermediate-signal AST tracking path to call local classification ownership,
  - `FlattenedDT` now delegates intermediate-signal classification to `EnableGraph` via compatibility shim.
- Newest extraction increment:
  - moved AST-based intermediate classification helper (`is_signal_ast_based_intermediate`) into `EnableGraph`,
  - updated `EnableGraph` intermediate-signal classification path to call local AST-based classification ownership,
  - `FlattenedDT` now delegates AST-based intermediate classification to `EnableGraph` via compatibility shim.
- Latest extraction increment:
  - moved AST factorization operator helper (`_ast_contains_factorizable_operators`) into `EnableGraph`,
  - updated `EnableGraph` AST-based intermediate classification path to call local operator-analysis ownership,
  - `FlattenedDT` now delegates AST operator-analysis helper entrypoints to `EnableGraph` via compatibility shim.
- Newest extraction increment:
  - moved arithmetic-operation helper (`is_arithmetic_operation`) into `EnableGraph`,
  - updated `EnableGraph` AST factorization operator-analysis path to call local arithmetic-operation ownership,
  - `FlattenedDT` now delegates arithmetic-operation helper entrypoints to `EnableGraph` via compatibility shim.
- Latest extraction increment:
  - moved logical-operation helper (`is_logical_operation`) into `EnableGraph`,
  - updated `EnableGraph` AST factorization operator-analysis path to call local logical-operation ownership,
  - `FlattenedDT` now delegates logical-operation helper entrypoints to `EnableGraph` via compatibility shim.
- Newest extraction increment:
  - moved logical-factorization policy helper (`should_factor_logical_operation`) into `EnableGraph`,
  - updated `EnableGraph` AST factorization operator-analysis path to call local logical-factorization policy ownership,
  - `FlattenedDT` now delegates logical-factorization policy helper entrypoints to `EnableGraph` via compatibility shim.
- Latest extraction increment:
  - moved frequent-logical-usage helper (`contains_frequently_used_operations`) into `EnableGraph`,
  - updated `EnableGraph` logical-factorization policy path to call local frequent-logical-usage ownership,
  - `FlattenedDT` now delegates frequent-logical-usage helper entrypoints to `EnableGraph` via compatibility shim.
- Newest extraction increment:
  - moved intermediate-signal expression resolver (`get_intermediate_signal_expression`) into `EnableGraph`,
  - updated `EnableGraph` frequent-logical-usage helper path to call local intermediate-signal expression ownership,
  - `FlattenedDT` now delegates intermediate-signal expression resolver entrypoints to `EnableGraph` via compatibility shim.
- Latest extraction increment:
  - moved intermediate-signal expression synthesis helper (`generate_expression_from_signal_name`) into `EnableGraph`,
  - updated `EnableGraph` intermediate-signal expression resolver path to call local expression-synthesis ownership,
  - `FlattenedDT` now delegates intermediate-signal expression synthesis helper entrypoints to `EnableGraph` via compatibility shim.
- Newest extraction increment:
  - moved AST-based intermediate-name metadata helper (`_signal_name_indicates_ast_operators`) into `EnableGraph`,
  - updated `EnableGraph` AST intermediate classification path to call local intermediate-name metadata ownership,
  - `FlattenedDT` now delegates AST-based intermediate-name metadata helper entrypoints to `EnableGraph` via compatibility shim.
- Latest extraction increment:
  - moved AST-to-SystemVerilog rendering helper (`ast_to_systemverilog`) into `EnableGraph`,
  - updated `EnableGraph` DT/LHS enable emission paths to call local AST rendering ownership,
  - `FlattenedDT` now delegates AST-to-SystemVerilog rendering helper entrypoints to `EnableGraph` via compatibility shim.
- Newest extraction increment:
  - moved AST signal-reference traversal helper (`ast_contains_signal`) into `Backend::SystemVerilog`,
  - updated backend final-expression usage checks to call local AST signal-reference traversal ownership,
  - `FlattenedDT` now delegates AST signal-reference traversal entrypoints to backend ownership via compatibility shim.
- Latest extraction increment:
  - moved substitution-reference usage helper (`is_signal_referenced_in_substitutions`) into `Backend::SystemVerilog`,
  - updated backend AST/string filtering paths to call local substitution-reference usage ownership,
  - `FlattenedDT` now delegates substitution-reference usage entrypoints to backend ownership via compatibility shim.
- Newest extraction increment:
  - moved intermediate-signal dependency ordering helper (`topologically_sort_signals`) into `Backend::SystemVerilog`,
  - updated backend consolidated intermediate-signal emission to call local dependency ordering ownership,
  - `FlattenedDT` now delegates dependency ordering entrypoints to backend ownership via compatibility shim.
- Latest extraction increment:
  - localized backend factorization/filtering callsites to backend-owned helpers in `Backend::SystemVerilog`,
  - updated backend paths to call local ownership for `is_signal_referenced_in_substitutions`, `run_global_ast_factorization`, `feed_asts_to_factorizer`, `count_unary_negations_in_original_expressions`, `update_original_asts_with_substituted_versions`, and `run_second_pass_factorization`,
  - reduced backend round-trips through `FlattenedDT` compatibility shims without changing behavior.
- Newest extraction increment:
  - localized second-pass AST feed checks to backend-owned intermediate-signal detection in `Backend::SystemVerilog`,
  - updated second-pass DT/LHS/assignment condition gating to call local `ast_contains_intermediate_signals` ownership,
  - removed remaining backend round-trips through `FlattenedDT` for this helper path without behavior changes.
- Latest extraction increment:
  - localized backend unified WEN/EN generation callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated backend WEN/EN emission to call `enable_graph->generate_unified_wen_en_signals(...)` directly,
  - removed the remaining backend round-trip through `FlattenedDT` for this phase-2 generation path.
- Newest extraction increment:
  - localized backend intermediate-signal expression lookup callsites to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated consolidated and declaration emission paths to call `enable_graph->get_intermediate_signal_expression(...)` directly,
  - removed remaining backend round-trips through `FlattenedDT` for intermediate-signal expression resolution.
- Latest extraction increment:
  - localized backend driven-signal classification callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated module-declaration port-direction analysis to call `enable_graph->get_driven_signals(...)` directly,
  - removed the backend round-trip through `FlattenedDT` for driven-signal lookup in this path.
- Newest extraction increment:
  - localized backend assignment-type classification callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated internal-signal declaration analysis to call `enable_graph->get_signal_assignment_type(...)` directly,
  - removed the backend round-trip through `FlattenedDT` for assignment-type lookup in this path.
- Latest extraction increment:
  - localized backend LHS-width analysis callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated internal-signal declaration analysis to call `enable_graph->get_lhs_width_from_analysis(...)` directly,
  - removed the backend round-trip through `FlattenedDT` for LHS-width lookup in this path.
- Newest extraction increment:
  - localized backend pulse-delay-cycle lookup callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated internal-signal declaration analysis to call `enable_graph->get_pulse_delay_cycles_for_lhs(...)` directly,
  - removed the backend round-trip through `FlattenedDT` for pulse-delay-cycle lookup in this path.
- Latest extraction increment:
  - localized backend reset-value lookup callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated flop-mux reset emission to call `enable_graph->get_reset_value(...)` directly,
  - removed the backend round-trip through `FlattenedDT` for reset-value lookup in this path.
- Newest extraction increment:
  - localized backend default-value lookup callsites to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated comb/flop mux default assignment emission to call `enable_graph->get_default_value(...)` directly,
  - removed backend round-trips through `FlattenedDT` for default-value lookup in these paths.
- Latest extraction increment:
  - localized backend intermediate-signal classification callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated recursive intermediate-signal detection to call `enable_graph->is_intermediate_signal(...)` directly,
  - removed the backend round-trip through `FlattenedDT` for this classification path.
- Newest extraction increment:
  - localized backend arithmetic-operation classification callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated AST filtering to call `enable_graph->is_arithmetic_operation(...)` directly,
  - removed the backend round-trip through `FlattenedDT` for this arithmetic classification path.
- Latest extraction increment:
  - localized backend logical-operation classification callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated AST filtering to call `enable_graph->is_logical_operation(...)` directly,
  - removed the backend round-trip through `FlattenedDT` for this logical classification path.
- Newest extraction increment:
  - localized backend logical-factorization policy callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated AST filtering to call `enable_graph->should_factor_logical_operation(...)` directly,
  - removed the backend round-trip through `FlattenedDT` for this logical-factorization policy path.
- Latest extraction increment:
  - localized one backend AST signal-name extraction callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated backend AST signal-reference traversal (`ast_contains_signal`) to call `enable_graph->extract_signal_name_from_ast(...)` directly,
  - removed one backend round-trip through `FlattenedDT` for AST signal-name extraction in this traversal path.
- Newest extraction increment:
  - localized one second-pass bare-signal AST name-extraction callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated second-pass AST intermediate-signal gating (`ast_contains_intermediate_signals`) to call `enable_graph->extract_signal_name_from_ast(...)` directly,
  - removed one backend round-trip through `FlattenedDT` for AST signal-name extraction in this second-pass filtering path.
- Latest extraction increment:
  - localized one recursive AST intermediate-signal name-extraction callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated recursive second-pass AST intermediate detection (`ast_has_intermediate_signals_recursive`) to call `enable_graph->extract_signal_name_from_ast(...)` directly,
  - removed one backend round-trip through `FlattenedDT` for AST signal-name extraction in this recursive detection path.
- Newest extraction increment:
  - localized one second-pass AST render callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated second-pass bare-signal debug rendering (`ast_contains_intermediate_signals`) to call `enable_graph->ast_to_systemverilog(...)` directly,
  - removed one backend round-trip through `FlattenedDT` for AST rendering in this second-pass filtering path.
- Latest extraction increment:
  - localized one second-pass DT-enable AST render callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated second-pass DT-enable debug rendering (`feed_current_asts_to_second_pass`) to call `enable_graph->ast_to_systemverilog(...)` directly,
  - removed one backend round-trip through `FlattenedDT` for AST rendering in this second-pass DT-enable path.
- Newest extraction increment:
  - localized one second-pass LHS-enable AST render callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated second-pass LHS-enable debug rendering (`feed_current_asts_to_second_pass`) to call `enable_graph->ast_to_systemverilog(...)` directly,
  - removed one backend round-trip through `FlattenedDT` for AST rendering in this second-pass LHS-enable path.
- Latest extraction increment:
  - localized one second-pass assignment-condition AST render callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated second-pass assignment-condition debug rendering (`feed_current_asts_to_second_pass`) to call `enable_graph->ast_to_systemverilog(...)` directly,
  - removed one backend round-trip through `FlattenedDT` for AST rendering in this second-pass assignment-condition path.
- Newest extraction increment:
  - localized one DT-specific substituted-AST render callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated DT-specific substitution debug rendering (`update_original_asts_with_substituted_versions`) to call `enable_graph->ast_to_systemverilog(...)` directly for `original_sv`,
  - removed one backend round-trip through `FlattenedDT` for AST rendering in this DT-specific substitution path.
- Latest extraction increment:
  - localized one DT-specific substituted-AST updated-render callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated DT-specific substitution debug rendering (`update_original_asts_with_substituted_versions`) to call `enable_graph->ast_to_systemverilog(...)` directly for `substituted_sv`,
  - removed one backend round-trip through `FlattenedDT` for AST rendering in this DT-specific substitution-update path.
- Newest extraction increment:
  - localized one LHS-level substituted-AST original-render callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated LHS-level substitution debug rendering (`update_original_asts_with_substituted_versions`) to call `enable_graph->ast_to_systemverilog(...)` directly for `original_sv`,
  - removed one backend round-trip through `FlattenedDT` for AST rendering in this LHS-level substitution path.
- Latest extraction increment:
  - localized one LHS-level substituted-AST updated-render callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated LHS-level substitution debug rendering (`update_original_asts_with_substituted_versions`) to call `enable_graph->ast_to_systemverilog(...)` directly for `substituted_sv`,
  - removed one backend round-trip through `FlattenedDT` for AST rendering in this LHS-level substitution-update path.
- Newest extraction increment:
  - localized one assignment-condition substituted-AST original-render callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated assignment-condition substitution debug rendering (`update_original_asts_with_substituted_versions`) to call `enable_graph->ast_to_systemverilog(...)` directly for `original_sv`,
  - removed one backend round-trip through `FlattenedDT` for AST rendering in this assignment-condition substitution path.
- Latest extraction increment:
  - localized one assignment-condition substituted-AST updated-render callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated assignment-condition substitution debug rendering (`update_original_asts_with_substituted_versions`) to call `enable_graph->ast_to_systemverilog(...)` directly for `substituted_sv`,
  - removed one backend round-trip through `FlattenedDT` for AST rendering in this assignment-condition substitution-update path.
- Newest extraction increment:
  - localized one second-pass DT-specific original-render callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated second-pass DT-specific substitution debug rendering (`update_original_asts_with_second_pass_substitutions`) to call `enable_graph->ast_to_systemverilog(...)` directly for `original_sv`,
  - removed one backend round-trip through `FlattenedDT` for AST rendering in this second-pass DT-specific substitution path.
- Avoided loading conflicting legacy `FSM::AST::Utils` implementation in the new module to preserve existing AST utility behavior path.
### Latest AST/CoreAST convergence slice
- Audited `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` and confirmed the live runtime declaration path emits intermediate wires through `generate_consolidated_intermediate_signals(...)`; the older standalone `generate_intermediate_signal_declarations(...)` helper is not on the active path.
- Hardened live consolidated intermediate width handling in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - added backend-local width normalization that prefers native FSM signal metadata from `EnableGraph::get_signal_info(...)`,
  - falls back to defining AST analysis before any parsed-expression compatibility path,
  - normalizes widths across AST-factorization, prescan-reference, and FSMGen-native intermediate-signal sources before filtering/declaration emission.
- Removed the live-path prescan merge placeholder `width => 1` and made consolidated wire declarations resolve width again at emission time so declarations no longer trust stale placeholder metadata.
- Added live backend handling for factorizer-substituted AST node classes during width inference (`FSM::HDL::IntermediateSignalRef`, `FSM::HDL::SubstitutedUnaryOp`, `FSM::HDL::SubstitutedBinaryOp`) without widening dormant compatibility-only declaration helpers.

### Validation (latest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t` (pass: 6 files, 125 tests)
### Newest AST/CoreAST convergence slice
- Further reduced expression-string handling on the live consolidated intermediate path in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by normalizing a per-signal runtime AST before dependency analysis, filtering, and assign emission.
- Added backend-local runtime-AST/render helpers so the active consolidated path now prefers:
  - substituted factorizer ASTs first,
  - resolved defining ASTs second,
  - parsed stored expressions only as a narrow compatibility fallback.
- Updated the live consolidated dependency/filter/emit phases to consume the normalized runtime AST / AST-rendered expression instead of each branching independently on raw `expression` metadata.
- Kept legacy compatibility behavior isolated:
  - `extract_intermediate_signals_from_expression(...)` remains only the dependency fallback when runtime AST resolution still misses,
  - `should_filter_string_based(...)` remains only the compatibility-only last resort when no runtime AST can be resolved.

### Validation (newest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t` (pass: 6 files, 125 tests)
### Latest AST/CoreAST convergence slice
- Normalized consolidated intermediate dependency metadata in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` behind a backend-local helper so the live dependency graph consumes cached per-signal dependency data instead of performing inline fallback branching.
- The active consolidated path now:
  - resolves dependency lists from runtime ASTs first,
  - caches dependency metadata on each consolidated signal entry,
  - keeps expression-based dependency extraction isolated to one compatibility-only helper path when runtime AST resolution still misses.
- Updated the live consolidated dependency-map construction to consume normalized dependency metadata instead of re-running AST/expression selection inline.

### Validation (latest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t` (pass: 6 files, 125 tests)
### Newest AST/CoreAST convergence slice
- Normalized consolidated rendered-expression metadata in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` so the live path now caches and reuses one rendered-expression value per intermediate signal instead of recomputing or re-falling-back at each use site.
- Reduced eager expression-text handling on prescan-backed consolidated entries:
  - when a runtime AST is already available, prescan merge now keeps AST/runtime metadata without also eagerly hydrating `expression` text,
  - expression text is only carried forward at merge time when runtime AST resolution still misses.
- Added an explicit rendered-expression normalization pass before dependency-aware filtering so the active consolidated path consumes cached render metadata.

### Validation (newest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t` (pass: 6 files, 125 tests)
### Latest AST/CoreAST convergence slice
- Normalized and cached consolidated runtime-AST miss state in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` so AST-resolution failures are recorded once per signal instead of being re-discovered at each live-path callsite.
- The active consolidated path now:
  - records whether runtime-AST resolution is `resolved` or `missing`,
  - stores a miss reason for compatibility-only fallback cases,
  - reuses cached miss state on later dependency/filter/render passes instead of retrying the same AST recovery path repeatedly.

### Validation (latest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t` (pass: 6 files, 125 tests)
### Newest AST/CoreAST convergence slice
- Reduced the remaining compatibility-only miss path in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by recovering runtime ASTs after late expression hydration.
- The live consolidated path now:
  - retries runtime-AST resolution when `EnableGraph` provides an expression for a signal that had previously missed only because no expression source was available yet,
  - upgrades those former `no_ast_source` misses into real runtime ASTs when parsing succeeds,
  - lets dependency extraction consume that recovered AST in the same pass instead of immediately falling back to expression-based dependency extraction.

### Validation (newest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t` (pass: 6 files, 125 tests)
### Latest AST/CoreAST convergence slice
- Further narrowed the explicit runtime-AST miss path in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` during dependency extraction.
- The live consolidated path now:
  - routes runtime-AST misses through a dedicated dependency-recovery helper instead of going straight to the legacy compatibility extractor,
  - skips redundant parse retries for the same stored expression when that expression already produced an `expression_parse_failed` runtime-AST miss,
  - tries alternate known expressions from `EnableGraph` before the final identifier-scan fallback,
  - caches any dependency-time AST recovery back onto the signal metadata so later live-path phases can reuse the recovered runtime AST and refreshed width.
- Reduced the true string-era remainder in this lane:
  - the legacy `extract_intermediate_signals_from_expression(...)` entrypoint now delegates to the explicit runtime-AST-miss helper,
  - the final compatibility-only behavior is narrower and centralized in the last-resort identifier scan, which now defers intermediate-signal identity checks to `EnableGraph::is_intermediate_signal(...)`.

### Validation (latest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t` (pass: 6 files, 125 tests)
### Newest AST/CoreAST convergence slice
- Retired the remaining dead string-era condition / WEN helper island from `perl/FSM/HDL/FlattenedDT.pm`.
- Removed the unused legacy helpers that implemented a parallel string-based path for condition formatting, assignment recording, and DT-specific/LHS-level WEN generation:
  - `record_assignment(...)`
  - `record_transition(...)`
  - `create_condition_expression(...)`
  - `format_condition(...)`
  - `format_signal_expression(...)`
  - `invert_condition(...)`
  - `format_test_value(...)`
  - `resolve_rhs_value(...)`
  - `generate_dt_specific_wens(...)`
  - `generate_lhs_level_wens(...)`
  - `extract_condition_string(...)`
- Removed the now-unused delegators that only existed to support that dead string-era path:
  - `clean_signal_name(...)`
  - `generate_rhs_based_enable_name(...)`
  - `is_complex_expression(...)`
  - `get_or_create_global_expression(...)`
  - `should_factor_condition(...)`
  - `needs_parentheses(...)`
- Added focused regression coverage in `t/10-ast-first-enable-structure.t` to assert that live generation:
  - stores DT-specific and LHS-level enable metadata inside `assignment_analysis->{rhs_groups}`,
  - leaves no legacy top-level `dt_specific_enables` or `lhs_to_enable_value_pairs` state behind.
- Backed this cleanup with a repo-wide reference audit showing that the live path already runs through `FlattenedDT::Orchestrator` AST recorders and `EnableGraph` AST-backed enable synthesis, while the retired helper names remained only in docs.

### Validation (newest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
- `prove -I perl t/09-ast-first-intermediate-registry.t t/10-ast-first-enable-structure.t` (pass: 2 files, 9 tests)
- `prove -I perl t` (pass: 10 files, 152 tests)
### Newest AST/CoreAST convergence slice
- Retired a dead string-era intermediate-signal producer cluster from `perl/FSM/HDL/FlattenedDT.pm`.
- Removed the unused legacy factorization helpers that still created plain-string `intermediate_signals` entries:
  - `perform_global_expression_factorization(...)`
  - `is_simple_expression_for_factorization(...)`
  - `extract_sub_expressions_from_ast(...)`
  - `is_leaf_node(...)`
  - `is_redundant_intermediate_signal(...)`
  - `identify_factorization_candidates(...)`
  - `generate_factorized_signals(...)`
- Tightened the remaining registry contract in `FlattenedDT.pm` so `intermediate_signals` is documented as metadata-hash storage rather than raw string-expression storage.
- Added focused regression coverage in `t/09-ast-first-intermediate-registry.t` to assert that live generation leaves no plain-string or `legacy_string_registry` intermediate entries behind.
- Backed this cleanup with a live audit on known-good fixtures (`fsm/trial_0.fsm`, `fsm/trial_1.fsm`, `fsm/trial_2.fsm`, `fsm/mipicsi2_tester_ctrl.fsm`), which showed the runtime generator already finishing with an empty `intermediate_signals` registry; the removed helpers were dead compatibility residue rather than live behavior.

### Validation (newest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
- `prove -I perl t/09-ast-first-intermediate-registry.t` (pass: 1 file, 3 tests)
- `prove -I perl t` (pass: 9 files, 146 tests)
### Newest AST/CoreAST convergence slice
- Retired the last regex identifier-scan dependency fallback from `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- The explicit runtime-AST-miss dependency path now:
  - attempts AST-backed recovery from rendered/registered expressions,
  - attempts cleaned-expression recovery,
  - attempts structured signal-name AST recovery,
  - and otherwise records the miss as `runtime_ast_miss_unresolved` instead of mining identifiers from opaque strings.
- Removed the dead compatibility helper `scan_intermediate_signal_names_in_expression(...)` from the live backend.
- Strengthened `t/07-runtime-ast-miss-dependency-recovery.t` so opaque invalid legacy expressions like `mid @@ aux` no longer infer `mid`/`aux` dependencies via regex identifier scanning.
- Backed this cleanup with a live audit on known-good fixtures (`fsm/trial_0.fsm`, `fsm/trial_1.fsm`, `fsm/trial_2.fsm`, `fsm/mipicsi2_tester_ctrl.fsm`), which produced zero identifier-scan hits before removal.

### Validation (newest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t/07-runtime-ast-miss-dependency-recovery.t` (pass: 1 file, 8 tests)
- `prove -I perl t` (pass: 8 files, 143 tests)
### Newest AST/CoreAST convergence slice
- Narrowed the remaining explicit runtime-AST-miss filtering residue in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- The live consolidated path now:
  - normalizes per-signal AST-derived live-usage metadata (`referenced_in_substitutions`, `used_in_final_expressions`) before filtering,
  - makes both AST-backed filtering and runtime-AST-miss filtering consume that cached usage metadata instead of re-running the same live-usage scans at each branch,
  - routes explicit runtime-AST misses through a dedicated `should_filter_runtime_ast_miss(...)` helper.
- Reduced the legacy-shaped fallback surface:
  - `should_filter_consolidated_signal(...)` no longer uses `should_filter_string_based(...)` as the live explicit-miss decision point,
  - `should_filter_string_based(...)` is now only a compatibility wrapper that delegates to the runtime-AST-miss helper.

### Validation (newest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t` (pass: 6 files, 125 tests)
### Latest AST/CoreAST convergence slice
- Retired unused legacy-named wrapper entrypoints from the repo:
  - removed `should_filter_string_based(...)` from `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and from the `perl/FSM/HDL/FlattenedDT.pm` facade,
  - removed `extract_intermediate_signals_from_expression(...)` from `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and from the `perl/FSM/HDL/FlattenedDT.pm` facade.
- This keeps the live consolidated path aligned with the current AST/CoreAST-first runtime shape:
  - explicit runtime-AST misses are handled through `should_filter_runtime_ast_miss(...)`,
  - dependency fallback is handled through `extract_intermediate_signals_from_runtime_ast_miss(...)`,
  - the remaining compatibility-only residue on this lane is now concentrated in the final identifier scan rather than in legacy wrapper API surface.

### Validation (latest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
- `prove -I perl t` (pass: 6 files, 125 tests)
### Newest AST/CoreAST convergence slice
- Narrowed the last live dependency compatibility fallback in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- The explicit runtime-AST-miss dependency path now:
  - attempts direct compatibility parsing through a dedicated recovery helper,
  - then tries one cleaned-expression AST recovery pass before the final identifier scan,
  - caches any cleaned-expression recovery back onto runtime-AST metadata so later live-path phases can reuse the AST-backed signal.
- Kept this slice behavior-safe:
  - cleaned-expression recovery preserves already-rendered expression text when the AST is recovered from a cleaned variant,
  - the identifier scan remains only as the final compatibility-only fallback when both raw and cleaned AST recovery still fail.

### Validation (newest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t` (pass: 6 files, 125 tests)
### Latest AST/CoreAST convergence slice
- Moved cleaned-expression compatibility recovery earlier in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` so normal runtime-AST resolution can recover more signals before the dependency helper reaches its final identifier scan.
- The live consolidated path now:
  - attempts cleaned-expression parsing during `resolve_intermediate_signal_runtime_ast(...)` after a stored-expression parse miss,
  - records cleaned-expression recovery as runtime-AST metadata,
  - preserves the original stored expression text during rendering when the recovered AST came from a cleaned compatibility expression.
- This narrows the remaining final dependency fallback population:
  - more signals now arrive at dependency extraction with a real runtime AST already resolved,
  - the identifier scan remains only for the subset of signals that still fail both raw and cleaned runtime-AST recovery.

### Validation (latest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t` (pass: 6 files, 125 tests)
### Newest AST/CoreAST convergence slice
- Narrowed the last explicit runtime-AST-miss dependency fallback by inserting an AST-first signal-name recovery step before the final identifier scan.
- `perl/FSM/Synthesis/EnableGraph.pm` now:
  - recognizes AST-generated intermediate signal names backed by factorizer/global-expression metadata,
  - builds a small dependency-recovery AST that preserves direct intermediate-signal operands instead of flattening them transitively,
  - returns that AST only when it recovers at least one direct intermediate dependency.
- `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` now uses that recovered AST before dropping to `scan_intermediate_signal_names_in_expression(...)`, so the remaining raw identifier scan is limited to legacy/non-AST-named hard misses.
- Added focused regression coverage in `t/07-runtime-ast-miss-dependency-recovery.t` for:
  - direct-dependency preservation through the new signal-name AST path,
  - legacy-source signals staying on the final identifier-scan fallback.

### Validation (newest slice)
- `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t` (pass: 7 files, 130 tests)
### Latest AST/CoreAST convergence slice
- Closed a CoreAST-native signal-definition gap that was still forcing some parser-created intermediates onto compatibility recovery paths.
- `perl/FSM/CoreAST.pm` now canonicalizes `driving_ast` through the real signal field even when older code writes it via `set_attribute('driving_ast', ...)`, so backend/native AST lookup sees the same defining AST the signal was created with.
- `perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm` and `perl/FSM/Adapter/FSMGenFull/Parser.pm` now write intermediate-signal defining ASTs through `set_driving_ast(...)` directly instead of storing them only in the attribute bag.
- Added focused regression coverage in `t/08-driving-ast-canonicalization.t` for:
  - canonical `driving_ast` storage through the CoreAST signal API,
  - factored parser/frontend intermediates keeping their defining AST natively,
  - backend runtime-AST recovery resolving those intermediates through the native defining-AST path.

### Validation (latest slice)
- `perl -I perl -c perl/FSM/CoreAST.pm` (pass)
- `perl -I perl -c perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm` (pass)
- `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm` (pass)
- `prove -I perl t` (pass: 8 files, 140 tests)
### Newest AST/CoreAST convergence slice
- Narrowed the remaining regex identifier scan again by extending the existing signal-name AST dependency recovery path to conservative `legacy_string_registry` names.
- `perl/FSM/Synthesis/EnableGraph.pm` now allows legacy registry entries onto the same structured signal-name AST recovery path already used for AST-generated names, instead of forcing all such names directly to regex scanning.
- This keeps the behavior narrow:
  - systematic legacy names like `not_mid_and_aux_legacy` can now recover dependencies through AST construction/traversal,
  - opaque legacy names still fall through to `scan_intermediate_signal_names_in_expression(...)`.
- Updated focused regression coverage in `t/07-runtime-ast-miss-dependency-recovery.t` for:
  - AST-generated signal-name recovery,
  - conservative legacy signal-name recovery,
  - opaque legacy names staying on the final identifier-scan fallback.

### Validation (newest slice)
- `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
- `prove -I perl t` (pass: 8 files, 143 tests)

### Validation (post-hardening + extraction)
- `prove -I perl t/04-assignment-edge-cases.t t/05-assignment-hdl-snapshots.t` (pass)
- `prove -I perl t` (full suite pass: 5 files, 117 tests)

## 2026-02-21
### Parser and expression handling
- Added parser support for compound update shorthand and inline modifiers:
  - `(++ sig)`, `(-- sig)`, `(+=K sig)`, `(-=K sig)`
  - Inline forms in assignments such as `(A <- B (+= 2))` and `(A = B (-= 1))`
- Fixed nested packed conditional parsing for forms encoded as:
  - `['<',  [cond, action1, ...]]`
  - `['<!', [cond, action1, ...]]`
- Improved expression parsing for packed recursive operands and scalar negation tokens (e.g. `!wren`).

### Backend behavior hardening
- Added explicit `generate_verilog()` path in `perl/FSM/HDL/FlattenedDT.pm` with SystemVerilog-to-Verilog conversion (`always_comb`→`always @*`, `always_ff` lowering).
- Added explicit `generate_vhdl()` method that fails with a clear not-implemented error instead of method-missing crashes.
- Fixed indexed-target handling in flattening paths where direct `->name` assumptions caused runtime failures.

### Combinational self-dependency safety rule (`=`)
- Enforced generalized rule: combinational assignment RHS must not depend (directly or transitively) on the same LHS.
- Implemented graph-based dependency tracking for `=` assignments in `perl/FSM/Adapter/FSMGenFull/Parser.pm`:
  - Record `LHS -> RHS signals` for each combinational assignment.
  - Detect cycles per LHS and reject with `Carp::confess`.
- Preserved synchronous legality: loopback forms like `(A <- A)` remain allowed.

### Tests
- Added focused regression file: `t/02-combinational-self-dependency.t`
  - Direct reject: `(A = A)`
  - Indirect reject: `(A = B)` + `(B = A)`
  - Positive allow: `(A <- A)`
- Validated with:
  - `prove -v t/02-combinational-self-dependency.t`
  - `prove -v t/01-regression.t` (20/20 pass).

### Documentation consolidation
- Consolidated and refreshed root docs (`README.md`, `CHANGES.md`, `DEVELOPMENT_NOTES.md`).
- Promoted and renamed user guide to `docs/USER_GUIDE.md`.
- Removed stale/duplicate investigation-era markdown files from `docs/`.

## 2025-08 (consolidated historical highlights)
- Fixed intermediate signal declaration/filtering defects in `FlattenedDT.pm`, including reference-aware and multi-registry dependency tracking.
- Fixed intermediate self-reference generation during multi-pass substitution.
- Fixed conditional transition suffix parsing (`<sig`, `<!sig`) for correct enable differentiation.
- Fixed operator selection and register feedback defaults for cleaner, synthesis-friendly RTL.
- Stabilized width inference behavior and parser/generator robustness across large FSM inputs.

## Earlier foundational changes
- Refactored monolithic FSM adapter flow into modular parser components (`SignalManager`, `ExpressionBuilder`, `Parser`, `SignalAnalyzer`).
- Standardized fatal error reporting with `Carp::confess`.
- Established baseline regression infrastructure (`t/01-regression.t`) and project self-containment.
