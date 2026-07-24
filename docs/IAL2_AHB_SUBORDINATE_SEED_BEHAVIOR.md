# IAL2 AHB Subordinate Seed Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.709`

Date: 2026-06-29

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.709` ships the selected lower-layer
AHB-Lite/common-AHB subordinate direct `.fsm` seed:

```text
fsm/ahb_lite_subordinate.fsm
(?fsm:ahb_lite_subordinate ...)
protocol.ahb_lite_subordinate
```

The seed is a direct IAL0/cycle-level fixture. It is not an IAL2 `.ppif` or
`.ahb` source, does not generate `.isf` review artifacts, and does not add AHB
interconnect/decode, requester/subordinate composition, scoreboards, direct
backend behavior, verification-output generation, backend-language variants,
AXI, APB, or VHDL behavior.

The next exact owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.710`, a
no-behavior readiness audit for IAL2 AHB completer/subordinate source work now
that the lower-layer direct seed exists.

Later status: `.710` selected `.711`, public IAL2 AHB
subordinate/completer contract selection, before any parser/generator/source
behavior changes.

Later `.711` selected the future public source
`ppif/ahb_lite_subordinate.ppif` and `.712`, a no-behavior generated-substrate
audit before implementation.

## Shipped Direct Fixture

The shipped port set is:

| Direction | Signal | Width | Role |
| --- | --- | --- | --- |
| input | `HSEL` | 1 | Local selected-subordinate decode line. |
| input | `HADDR` | 32 | Address phase address. |
| input | `HTRANS` | 2 | Transfer type. |
| input | `HWRITE` | 1 | Write/read direction. |
| input | `HSIZE` | 3 | Transfer size. |
| input | `HREADY` | 1 | Previous transfer completion/selection gate. |
| input | `HWDATA` | 32 | Write data for the selected data phase. |
| input | `wait_cycles` | 4 | Fixture-local bounded wait-state control. |
| output | `HREADYOUT` | 1 | Subordinate completion/wait response. |
| output | `HRESP` | 1 | AHB-Lite/common-AHB OKAY/ERROR status. |
| output | `HRDATA` | 32 | Read data. |

The fixture uses the current direct `.fsm` system convention:

```text
(+system
  (clock clk)
  (areset rst_n)
)
```

## Behavior

`idle` drives:

```text
HREADYOUT = 1
HRESP     = 0
HRDATA    = 32'h00000000
```

The seed accepts a new address/control phase only when `HSEL && HREADY` is
true.

`IDLE` and `BUSY` transfers are ignored with zero-wait OKAY and no storage
change because they do not leave `idle`.

`NONSEQ` transfers sample `HADDR`, `HWRITE`, `HSIZE`, and `wait_cycles`, then
enter `access`. The only successful mapped transfer is `HSIZE == 2` to
address `32'h00000000`.

In `access`, nonzero `wait_ctr` drives pending OKAY wait states:

```text
HREADYOUT = 0
HRESP     = 0
HRDATA    = 32'h00000000
```

When `wait_ctr` reaches zero:

- mapped word reads drive `HRDATA` from `reg_data_q` and complete with OKAY;
- mapped word writes update `reg_data_q` from `HWDATA` and complete with OKAY;
- unsupported sizes and unmapped addresses drive the first ERROR cycle with
  `HRESP=1` and `HREADYOUT=0`, then `error_complete` drives the second ERROR
  completion cycle with `HRESP=1` and `HREADYOUT=1`.

`SEQ` transfers are routed to `unsupported`, which uses the same wait-state
and two-cycle ERROR response policy. The seed performs no write update on
ERROR.

Current phase boundary: generated-HDL t/1520 now proves that this direct seed
samples address/control only in `idle`. A selected active phase accepted on a
successful `access` completion or final `error_complete` ready edge is not
captured before the state returns to `idle`, so the direct seed silently drops
that phase. The success probe records two bus acceptances but one internal
capture/completion and storage `0x11111111`; the final-ERROR probe records two
acceptances, one capture/completion, exactly two ERROR cycles, and zero
storage. This limitation does not apply to the generated public IAL2 family,
which was repaired separately by `.3`. See
`docs/IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_RUNTIME_AUDIT.md`;
`.5` owns no-behavior direct-seed contract selection and `.6` owns later
implementation.

## Support Accounting

`perl/FSM/Support/RegressionCorpus.pm` now includes:

```text
id: protocol.ahb_lite_subordinate
relpath: fsm/ahb_lite_subordinate.fsm
family: protocol_fixture
classification: supported_smoke
coverage: direct_root_pipeline_cli
source_kind: fsm
strict_supported: true
expected_module_name: ahb_lite_subordinate
```

The support-accounting regression now expects 308 supported-smoke entries and
308 strict-supported entries, and lists `protocol.ahb_lite_subordinate` as a
canonical strict-supported protocol fixture.

## Validation Evidence

Focused validation used:

```bash
./bin/fsmgen --quiet --strict --check --json fsm/ahb_lite_subordinate.fsm
./bin/fsmgen --quiet --output /tmp/fsmgen_ahb_lite_subordinate.sv fsm/ahb_lite_subordinate.fsm
rg -n "size_q_eq|size_q_ne|HRESP <- 1|HREADYOUT <- 1|reg_data_q <- HWDATA|HTRANS == 2'b1" /tmp/fsmgen_ahb_lite_subordinate.sv
perl -Iperl -MFSM::Support::RegressionCorpus=regression_corpus_entries -we '
  my @e = regression_corpus_entries();
  my ($x) = grep { $_->{id} eq q(protocol.ahb_lite_subordinate) } @e;
  die "missing protocol.ahb_lite_subordinate\n" unless $x;
  die "wrong relpath\n" unless $x->{relpath} eq q(fsm/ahb_lite_subordinate.fsm);
  die "wrong module\n" unless $x->{expected_module_name} eq q(ahb_lite_subordinate);
  die "not strict supported\n" unless $x->{strict_supported};
  my $supported = grep { $_->{classification} eq q(supported_smoke) } @e;
  my $strict = grep { $_->{strict_supported} } @e;
  die "supported=$supported strict=$strict\n" unless $supported == 308 && $strict == 308;
  print "protocol.ahb_lite_subordinate catalog OK: supported=$supported strict=$strict\n";
'
```

The strict check passed with `module_name: ahb_lite_subordinate`, `signal_count:
11`, `state_count: 4`, and matched support accounting
`protocol.ahb_lite_subordinate`.

The generated HDL inspection confirmed:

- `HTRANS == 2'b10` routes to `ACCESS`;
- `HTRANS == 2'b11` routes to `UNSUPPORTED`;
- word-size guards lower as `size_q == 2` and `size_q != 2`;
- successful mapped writes are the only path with `reg_data_q <- HWDATA`;
- `HRESP <- 1` is asserted for unsupported size/address/SEQ first ERROR
  cycles and the `error_complete` second ERROR cycle; and
- `HREADYOUT <- 1` is asserted in idle, successful completion, and second
  ERROR completion.

The catalog-only support-accounting probe confirmed
`protocol.ahb_lite_subordinate`, `fsm/ahb_lite_subordinate.fsm`, expected
module `ahb_lite_subordinate`, strict-supported status, 308 supported-smoke
entries, and 308 strict-supported entries.

A guarded broad support-accounting regression was attempted with:

```bash
scripts/run_with_ram_guard.sh -- prove -Iperl t/248-regression-corpus-accounting.t
```

It did not start the test because the host was already at 99.7% memory against
the required 88% guard cutoff, so the RAM guard terminated the command before
`prove` could run. The guard was not bypassed.

Closeout also reruns Knowledge Map, mdBook, memory, diff-hygiene, and doctrine
gates.

Later focused validation adds:

```bash
prove -Iperl t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t
```

That no-behavior audit locks the current completion-edge loss until its
separate direct-seed repair owner ships.

## Explicit Residue

The following remain future task-tree-owned work:

- IAL2 AHB completer/subordinate `.ppif` source vocabulary;
- `.ahb` completer/subordinate profile alias behavior;
- generated `.isf`/`.fsm` review artifacts for IAL2 AHB subordinate behavior;
- AHB interconnect/decode and requester/subordinate composition;
- scoreboards and verification-output generation;
- full AHB manager behavior beyond the existing bounded requester;
- burst `SEQ` support, `HBURST`, wrapping/incrementing bursts, and burst
  address progression;
- `HPROT`, `HMASTLOCK`, AHB5 property-gated signals, user signals,
  parity/check signals, exclusive access, and multi-manager identity signals;
- narrow transfer byte-lane behavior, write strobes, alignment policy, and
  register banks beyond the single selected word register;
- completion-edge retention of one accepted next active address/control phase
  in this direct seed (selected for `.5` contract work and `.6` implementation);
- legacy two-bit `HRESP` RETRY/SPLIT compatibility;
- direct backend behavior, backend-language variants, AXI, APB, and VHDL.

## Rollback

Rollback removes `fsm/ahb_lite_subordinate.fsm`, the
`protocol.ahb_lite_subordinate` corpus entry and accounting expectations, this
behavior record, its Knowledge Map fact card, and the README/ROADMAP/mdBook/
task-tree/Memory sync. No IAL2 parser/generator/source behavior is affected.
