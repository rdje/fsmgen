#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use FindBin;
use IPC::Open3 qw(open3);
use JSON::PP;
use Symbol qw(gensym);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::ProjectDataLocality qw(create_project_tempdir);

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $checker = File::Spec->catfile(
    $repo_root, 'live-document-size', 'scripts', 'check_live_document_size.pl',
);
my $contract = File::Spec->catfile(
    $repo_root, 'live-document-size', 'LIVE_DOCUMENT_SIZE_CHECKER.md',
);
my $json = JSON::PP->new->canonical(1)->utf8(1);

subtest 'JSONL fixture covers every lifecycle and retrieval-file descriptor' => sub {
    my $fixture = make_fixture();
    my ($ok, $output) = run_checker($fixture);
    ok($ok, 'complete lifecycle fixture passes') or diag($output);
    like($output, qr/surface bounded_entry: actual files=1,/, 'bounded snapshot is measured');
    like($output, qr/surface partitioned: actual files=2,/, 'partitioned canonical collection is measured');
    like($output, qr/surface maintained: maintained reference actual files=2,/, 'maintained product reference is measured without a fixed aggregate cap');
    like($output, qr/surface projection: actual files=1,/, 'generated projection is measured');
    like($output, qr/surface query_terminal: query terminal/, 'query projection is validated');
    like($output, qr/surface ledger: actual files=1,/, 'rolling ledger is measured');
    like($output, qr/ledger fixture_ledger: 3 ordered whole entries reconstructed across 3 range\(s\)/,
        'bounded ledger ranges reconstruct exactly');
    like($output, qr/surface archive_terminal: archive terminal/, 'archive terminal is validated');
    like($output, qr/surface external_terminal: external terminal declared/, 'external terminal is validated');
    like($output, qr/surface frozen_record: frozen identity checked/, 'frozen identity is validated');
    ok(-f File::Spec->catfile($fixture, 'freshness-ran'), 'core freshness verifier actually ran');
    ok(-f File::Spec->catfile($fixture, 'version-ran'), 'core version retrieval verifier actually ran');
    like($output, qr/all live-document size-containment invariants hold \(10 surfaces\)/,
        'complete graph closes');
};

subtest 'maintained reference bounds reads and parts while authorizing exact aggregate change' => sub {
    my $missing_rationale = make_fixture();
    mutate_record($missing_rationale, 'registry/surfaces.jsonl', 'maintained', sub {
        delete $_[0]{classification};
    });
    my ($rationale_ok, $rationale_output) = run_checker($missing_rationale);
    ok(!$rationale_ok, 'maintained reference without classification rationale is rejected');
    like($rationale_output, qr/requires an auditable classification rationale/,
        'classification failure is explicit');

    my $fixed_total = make_fixture();
    mutate_record($fixed_total, 'registry/surfaces.jsonl', 'maintained', sub {
        $_[0]{enforcement_ceilings}{lines_total} = 10;
    });
    my ($fixed_ok, $fixed_output) = run_checker($fixed_total);
    ok(!$fixed_ok, 'decorative fixed aggregate ceiling is rejected');
    like($fixed_output, qr/must use null lines_total for product-bounded aggregate scope/,
        'aggregate cap misuse is explicit');

    my $aggregate = make_fixture();
    mutate_record($aggregate, 'registry/surfaces.jsonl', 'maintained', sub {
        $_[0]{reference_contract}{aggregate_change}{delta}{lines_total} = 1;
    });
    my ($aggregate_ok, $aggregate_output) = run_checker($aggregate);
    ok(!$aggregate_ok, 'aggregate drift beyond the exact authorization is rejected');
    like($aggregate_output, qr/aggregate lines_total is 2 but contract authorizes 3/,
        'exact aggregate mismatch is named');

    my $mandatory = make_fixture();
    mutate_record($mandatory, 'registry/surfaces.jsonl', 'maintained', sub {
        $_[0]{reference_contract}{mandatory_read}{lines_ceiling} = 1;
    });
    my ($mandatory_ok, $mandatory_output) = run_checker($mandatory);
    ok(!$mandatory_ok, 'oversized mandatory index is rejected');
    like($mandatory_output, qr/mandatory read lines are 2 \(> ceiling 1\)/,
        'mandatory-read pressure is explicit');

    my $navigation = make_fixture();
    mutate_record($navigation, 'registry/surfaces.jsonl', 'maintained', sub {
        $_[0]{reference_contract}{max_navigation_depth} = 0;
    });
    my ($navigation_ok, $navigation_output) = run_checker($navigation);
    ok(!$navigation_ok, 'invalid zero navigation depth is rejected');
    like($navigation_output, qr/max_navigation_depth must be a positive integer/,
        'navigation-depth contract is explicit');
};

subtest 'JSONL schema rejects malformed, blank, missing, and unknown data' => sub {
    my $malformed = make_fixture();
    append_file($malformed, 'registry/surfaces.jsonl', "{not-json}\n");
    my ($malformed_ok, $malformed_output) = run_checker($malformed);
    ok(!$malformed_ok, 'malformed JSON is rejected');
    like($malformed_output, qr/surface registry line 12 is invalid JSON/, 'line is named');

    my $blank = make_fixture();
    append_file($blank, 'registry/routes.jsonl', "\n");
    my ($blank_ok, $blank_output) = run_checker($blank);
    ok(!$blank_ok, 'blank JSONL line is rejected');
    like($blank_output, qr/every JSONL line must be a JSON object/, 'blank-line rule is explicit');

    my $unknown = make_fixture();
    mutate_record($unknown, 'registry/surfaces.jsonl', 'bounded_entry', sub {
        $_[0]{mystery_field} = 1;
    });
    my ($unknown_ok, $unknown_output) = run_checker($unknown);
    ok(!$unknown_ok, 'unknown surface key is rejected');
    like($unknown_output, qr/unknown key: mystery_field/, 'unknown key is named');

    my $missing = make_fixture();
    mutate_record($missing, 'registry/surfaces.jsonl', 'bounded_entry', sub {
        delete $_[0]{health_targets};
    });
    my ($missing_ok, $missing_output) = run_checker($missing);
    ok(!$missing_ok, 'missing required key is rejected');
    like($missing_output, qr/missing required key: health_targets/, 'missing key is named');

    my $obsolete_hard = make_fixture();
    mutate_record($obsolete_hard, 'registry/surfaces.jsonl', 'bounded_entry', sub {
        $_[0]{milestones}{hard_pct} = 100;
    });
    my ($hard_pct_ok, $hard_pct_output) = run_checker($obsolete_hard);
    ok(!$hard_pct_ok, 'obsolete hard_pct is rejected');
    like($hard_pct_output, qr/unknown key: hard_pct/, 'inert hard percentage cannot masquerade as a limit');

    my $currency_shape = make_fixture();
    mutate_record($currency_shape, 'registry/surfaces.jsonl', 'bounded_entry', sub {
        $_[0]{currency} = {
            contract_id => 'bad_portable_date_rule',
            verifier => 'core:bin/freshness',
            newest_date => '2030-01-01',
        };
    });
    my ($currency_shape_ok, $currency_shape_output) = run_checker($currency_shape);
    ok(!$currency_shape_ok, 'undeclared global date field is rejected');
    like($currency_shape_output, qr/unknown key: newest_date/,
        'currency schema admits only a named local contract and verifier');

    my $state = make_fixture();
    mutate_record($state, 'registry/surfaces.jsonl', 'bounded_entry', sub {
        $_[0]{state} = 'terminal';
    });
    my ($state_ok, $state_output) = run_checker($state);
    ok(!$state_ok, 'terminal state on a measured surface is rejected');
    like($state_output, qr/measured locator has invalid state: terminal/,
        'state/measurement mismatch is explicit');

    my $archive_metadata = make_fixture();
    my $archive_path = File::Spec->catfile($archive_metadata, 'registry', 'archive.jsonl');
    my @archive_lines = split /\n/, slurp($archive_path);
    shift @archive_lines;
    write_file($archive_metadata, 'registry/archive.jsonl', join("\n", @archive_lines) . "\n");
    my ($metadata_ok, $metadata_output) = run_checker($archive_metadata);
    ok(!$metadata_ok, 'archive registry without durable metadata is rejected');
    like($metadata_output, qr/must begin with a schema-version 1 registry metadata record/,
        'missing archive metadata is explicit');
};

subtest 'common JSONL and Markdown line pressure are finite on every axis' => sub {
    my $records = make_fixture();
    mutate_record($records, 'registry/surfaces.jsonl', 'registry', sub {
        $_[0]{max_records} = 1;
    }, 'record_type');
    my ($records_ok, $records_output) = run_checker($records);
    ok(!$records_ok, 'registry record-count overflow is rejected');
    like($records_output, qr/record count 10 exceeds declared max_records 1/,
        'record-count bound is explicit');

    my $bytes = make_fixture();
    mutate_record($bytes, 'registry/routes.jsonl', 'registry', sub {
        $_[0]{max_bytes} = 128;
    }, 'record_type');
    my ($bytes_ok, $bytes_output) = run_checker($bytes);
    ok(!$bytes_ok, 'registry byte overflow is rejected');
    like($bytes_output, qr/route registry size .* exceeds declared max_bytes 128/,
        'registry-byte bound is explicit');

    my $record_bytes = make_fixture();
    mutate_record($record_bytes, 'registry/routes.jsonl', 'registry', sub {
        $_[0]{max_record_bytes} = 128;
    }, 'record_type');
    my ($record_ok, $record_output) = run_checker($record_bytes);
    ok(!$record_ok, 'oversized individual JSONL record is rejected');
    like($record_output, qr/route registry line 2 is .* \(> max_record_bytes 128\)/,
        'maximum-record bound is explicit');

    my $array = make_fixture();
    mutate_record($array, 'registry/surfaces.jsonl', 'bounded_entry', sub {
        $_[0]{targets} = [('entry.md') x 129];
    });
    my ($array_ok, $array_output) = run_checker($array);
    ok(!$array_ok, 'identity-list displacement is rejected');
    like($array_output, qr/targets line 2 has 129 entries \(> maximum 128\)/,
        'array cardinality bound is explicit');

    my $scalar = make_fixture();
    mutate_record($scalar, 'registry/surfaces.jsonl', 'bounded_entry', sub {
        $_[0]{owner} = 'x' x 257;
    });
    my ($scalar_ok, $scalar_output) = run_checker($scalar);
    ok(!$scalar_ok, 'oversized scalar is rejected');
    like($scalar_output, qr/invalid string key: owner/,
        'scalar-byte bound is explicit');

    my $line = make_fixture();
    write_file($line, 'destination.md', ('x' x 1025) . "\n");
    my ($line_ok, $line_output) = run_checker($line);
    ok(!$line_ok, 'oversized Markdown line is rejected independently of file bytes');
    like($line_output, qr/max line bytes is 1025 \(> inclusive enforcement ceiling 1024\)/,
        'maximum-line-byte dimension is explicit');

    my $crlf = make_fixture();
    write_file($crlf, 'destination.md', ('x' x 700) . "\r\n");
    my ($crlf_ok, $crlf_output) = run_checker($crlf);
    ok($crlf_ok, 'CRLF terminator bytes do not inflate deterministic content-line width')
        or diag($crlf_output);
    like($crlf_output, qr/bounded_destination: actual .* line_bytes_each=700,/,
        'reported line width excludes CRLF bytes');
};

subtest 'currency contracts are opt-in, lifecycle-scoped, and locally calibrated' => sub {
    my $positive = make_fixture();
    write_file(
        $positive,
        'bin/currency',
        "#!/bin/sh\nprintf 'currency-ran\\n' > currency-ran\n",
    );
    chmod 0755, File::Spec->catfile($positive, 'bin', 'currency')
        or die "cannot chmod positive currency verifier: $!";
    mutate_record($positive, 'registry/surfaces.jsonl', 'bounded_entry', sub {
        $_[0]{currency} = {
            contract_id => 'fixture_current_marker',
            verifier => 'core:bin/currency',
        };
    });
    my ($positive_ok, $positive_output) = run_checker($positive);
    ok($positive_ok, 'declared local currency verifier passes') or diag($positive_output);
    ok(-f File::Spec->catfile($positive, 'currency-ran'),
        'currency verifier side effect proves actual execution');
    like(
        $positive_output,
        qr/surface bounded_entry currency fixture_current_marker core verifier executed/,
        'currency contract and execution are reported independently from size',
    );

    my $self_refuting = make_fixture();
    write_file(
        $self_refuting,
        'entry.md',
        "destination.md\n- Last updated: `2026-01-01`\nlanded 2026-02-03\n",
    );
    write_file($self_refuting, 'bin/currency', <<'SCRIPT');
#!/usr/bin/env perl
use strict;
use warnings;
open my $fh, '<', 'entry.md' or exit 11;
local $/;
my $text = <$fh>;
my ($declared) = $text =~ /Last updated:\s*`?([0-9]{4}-[0-9]{2}-[0-9]{2})/;
my @dates = sort($text =~ /([0-9]{4}-[0-9]{2}-[0-9]{2})/g);
exit(!defined($declared) || !@dates || $declared lt $dates[-1] ? 12 : 0);
SCRIPT
    chmod 0755, File::Spec->catfile($self_refuting, 'bin', 'currency')
        or die "cannot chmod self-refutation verifier: $!";
    mutate_record($self_refuting, 'registry/surfaces.jsonl', 'bounded_entry', sub {
        $_[0]{currency} = {
            contract_id => 'self_declared_last_updated',
            verifier => 'core:bin/currency',
        };
    });
    my ($refuting_ok, $refuting_output) = run_checker($self_refuting);
    ok(!$refuting_ok, 'declared self-refutation fails its calibrated verifier');
    like($refuting_output, qr/currency self_declared_last_updated core verifier failed \(exit 12\)/,
        'self-refutation failure names the local contract and status');

    my $closure = make_fixture();
    write_file(
        $closure,
        'entry.md',
        "destination.md\nCurrent status: active\nphase closed 2021-03-04\nlane landed 2022-05-06\n",
    );
    write_file($closure, 'bin/currency', <<'SCRIPT');
#!/usr/bin/env perl
use strict;
use warnings;
open my $fh, '<', 'entry.md' or exit 13;
local $/;
my $text = <$fh>;
exit(index($text, "Current status: active\n") >= 0 ? 0 : 14);
SCRIPT
    chmod 0755, File::Spec->catfile($closure, 'bin', 'currency')
        or die "cannot chmod closure-date verifier: $!";
    mutate_record($closure, 'registry/surfaces.jsonl', 'bounded_entry', sub {
        $_[0]{currency} = {
            contract_id => 'current_status_marker',
            verifier => 'core:bin/currency',
        };
    });
    my ($closure_ok, $closure_output) = run_checker($closure);
    ok($closure_ok, 'legitimate closure dates pass a non-date local contract')
        or diag($closure_output);

    my $frozen = make_fixture();
    my $frozen_text = "- Last updated: 2020-01-01\nclosed 2030-12-31\n";
    write_file($frozen, 'frozen.md', $frozen_text);
    mutate_record($frozen, 'registry/surfaces.jsonl', 'frozen_record', sub {
        $_[0]{verifier} = 'sha256:' . sha256_hex($frozen_text);
    });
    my ($frozen_ok, $frozen_output) = run_checker($frozen);
    ok($frozen_ok, 'frozen dates remain exempt when exact identity holds')
        or diag($frozen_output);
    mutate_record($frozen, 'registry/surfaces.jsonl', 'frozen_record', sub {
        $_[0]{currency} = {
            contract_id => 'forbidden_frozen_currency',
            verifier => 'core:bin/currency',
        };
    });
    my ($frozen_contract_ok, $frozen_contract_output) = run_checker($frozen);
    ok(!$frozen_contract_ok, 'frozen lifecycle cannot opt into a current-state contract');
    like($frozen_contract_output, qr/historical or frozen lifecycle must not declare currency/,
        'frozen/history exemption is structural');

    my $absent = make_fixture();
    write_file(
        $absent,
        'entry.md',
        "destination.md\n- Last updated: 2020-01-01\nlanded 2030-12-31\n",
    );
    write_file($absent, 'bin/currency', "#!/bin/sh\nexit 23\n");
    chmod 0755, File::Spec->catfile($absent, 'bin', 'currency')
        or die "cannot chmod absent-contract sentinel: $!";
    my ($absent_ok, $absent_output) = run_checker($absent);
    ok($absent_ok, 'an undeclared currency heuristic is never run') or diag($absent_output);

    my $adapter = make_fixture();
    write_file($adapter, 'bin/currency', "#!/bin/sh\nexit 0\n");
    chmod 0755, File::Spec->catfile($adapter, 'bin', 'currency')
        or die "cannot chmod adapter currency verifier: $!";
    mutate_record($adapter, 'registry/surfaces.jsonl', 'bounded_entry', sub {
        $_[0]{currency} = {
            contract_id => 'adapter_currency',
            verifier => 'adapter:bin/currency',
        };
    });
    my ($adapter_missing_ok, $adapter_missing_output) = run_checker($adapter);
    ok(!$adapter_missing_ok, 'adapter currency requires execution proof');
    like($adapter_missing_output, qr/lacks executed proof: currency:bounded_entry/,
        'missing currency proof uses its own namespace');
    my ($adapter_ok, $adapter_output) = run_checker(
        $adapter, adapter_proofs => ['currency:bounded_entry'],
    );
    ok($adapter_ok, 'exact adapter currency proof passes') or diag($adapter_output);
};

subtest 'lifecycle, locality, index, and same-tree file rules fail closed' => sub {
    my $mismatch = make_fixture();
    mutate_record($mismatch, 'registry/surfaces.jsonl', 'bounded_entry', sub {
        $_[0]{lifecycle} = 'archive_terminal';
    });
    my ($mismatch_ok, $mismatch_output) = run_checker($mismatch);
    ok(!$mismatch_ok, 'lifecycle/locator mismatch is rejected');
    like($mismatch_output, qr/lifecycle archive_terminal is incompatible with locator file/,
        'mismatch is explicit');

    my $absolute = make_fixture();
    mutate_record($absolute, 'registry/surfaces.jsonl', 'bounded_entry', sub {
        $_[0]{targets} = [$repo_root . '/README.md'];
    });
    my ($absolute_ok, $absolute_output) = run_checker($absolute);
    ok(!$absolute_ok, 'absolute project path is rejected');
    like($absolute_output, qr/target must stay project-relative/, 'relative-path rule is explicit');

    my $symlink = make_fixture();
    symlink 'entry.md', File::Spec->catfile($symlink, 'linked.md')
        or die "cannot create fixture symlink: $!";
    mutate_record($symlink, 'registry/surfaces.jsonl', 'bounded_entry', sub {
        $_[0]{targets} = ['linked.md'];
    });
    my ($symlink_ok, $symlink_output) = run_checker($symlink);
    ok(!$symlink_ok, 'symlink target is rejected');
    like($symlink_output, qr/target is a symlink: linked\.md/, 'symlink is named');

    my $index = make_fixture();
    mutate_record($index, 'registry/surfaces.jsonl', 'partitioned', sub {
        $_[0]{index} = undef;
        $_[0]{state} = 'normal';
    });
    my ($index_ok, $index_output) = run_checker($index);
    ok(!$index_ok, 'unindexed healthy collection is rejected');
    like($index_output, qr/lacks a bounded index without structural debt/, 'index requirement is explicit');
};

subtest 'targets, ceilings, pressure states, ownership, and debt ratchets fail closed' => sub {
    my $hard = make_fixture();
    write_file($hard, 'destination.md', join('', map { "line $_\n" } 1 .. 101));
    my ($hard_ok, $hard_output) = run_checker($hard);
    ok(!$hard_ok, 'hard budget overflow is rejected');
    like($hard_output, qr/surface bounded_destination max lines is 101 \(> inclusive enforcement ceiling 100\)/,
        'overflow dimension is named');

    my $equality = make_fixture();
    my $equality_contents = join('', map { "line $_\n" } 1 .. 100);
    write_file($equality, 'destination.md', $equality_contents);
    mutate_record($equality, 'registry/surfaces.jsonl', 'bounded_destination', sub {
        $_[0]{state} = 'rollover_debt';
        $_[0]{containment_status} = 'pinned_deferred';
        $_[0]{baseline} = {
            files => 1, lines_each => 100, bytes_each => length($equality_contents),
            line_bytes_each => 8, lines_total => 100,
            bytes_total => length($equality_contents),
        };
        $_[0]{transition} = transition(0, 0, 0, 0, 0);
    });
    my ($equality_ok, $equality_output) = run_checker($equality);
    ok($equality_ok, 'actual equal to the inclusive enforcement ceiling passes')
        or diag($equality_output);

    my $warning = make_fixture();
    write_file($warning, 'destination.md', join('', map { "line $_\n" } 1 .. 81));
    my ($warning_ok, $warning_output) = run_checker($warning);
    ok(!$warning_ok, 'undeclared warning pressure is rejected');
    like($warning_output, qr/must declare warning_debt/, 'warning state is required');

    my $debt = make_fixture();
    write_file($debt, 'destination.md', join('', map { "line $_\n" } 1 .. 81));
    mutate_record($debt, 'registry/surfaces.jsonl', 'bounded_destination', sub {
        $_[0]{state} = 'warning_debt';
        $_[0]{containment_status} = 'pinned_deferred';
        $_[0]{baseline} = {
            files => 1, lines_each => 80, bytes_each => 10000,
            line_bytes_each => 1024, lines_total => 80, bytes_total => 10000,
        };
    });
    my ($debt_ok, $debt_output) = run_checker($debt);
    ok(!$debt_ok, 'worsened transition debt is rejected');
    like($debt_output, qr/transition debt exceeded its owned allowance: max lines is 81 \(> baseline 80 \+ growth 0\)/,
        'baseline regression is explicit');

    my $allowed = make_fixture();
    my $allowed_contents = join('', map { "line $_\n" } 1 .. 81);
    write_file($allowed, 'destination.md', $allowed_contents);
    mutate_record($allowed, 'registry/surfaces.jsonl', 'bounded_destination', sub {
        $_[0]{state} = 'warning_debt';
        $_[0]{containment_status} = 'pinned_deferred';
        $_[0]{baseline} = {
            files => 1, lines_each => 80, bytes_each => length($allowed_contents),
            line_bytes_each => 8, lines_total => 80,
            bytes_total => length($allowed_contents),
        };
        $_[0]{transition} = transition(0, 1, 0, 1, 0);
    });
    my ($allowed_ok, $allowed_output) = run_checker($allowed);
    ok($allowed_ok, 'bounded owned transition growth passes') or diag($allowed_output);

    my $unowned = make_fixture();
    mutate_record($unowned, 'registry/surfaces.jsonl', 'bounded_destination', sub {
        $_[0]{state} = 'warning_debt';
        $_[0]{containment_status} = 'pinned_deferred';
        $_[0]{baseline} = {
            files => 1, lines_each => 1, bytes_each => 12,
            line_bytes_each => 12, lines_total => 1, bytes_total => 12,
        };
        $_[0]{transition} = {
            owner => '',
            max_growth => {
                files => 0, lines_each => 1, bytes_each => 1,
                line_bytes_each => 1, lines_total => 1, bytes_total => 1,
            },
            ratchet_step => pressure(1, 10, 1024, 10, 1024),
        };
    });
    my ($unowned_ok, $unowned_output) = run_checker($unowned);
    ok(!$unowned_ok, 'ownerless transition allowance is rejected');
    like($unowned_output, qr/transition must declare a non-empty owner/,
        'transition owner failure is explicit');

    my $oversized_allowance = make_fixture();
    write_file($oversized_allowance, 'destination.md', join('', map { "line $_\n" } 1 .. 81));
    mutate_record($oversized_allowance, 'registry/surfaces.jsonl', 'bounded_destination', sub {
        $_[0]{state} = 'warning_debt';
        $_[0]{containment_status} = 'pinned_deferred';
        $_[0]{baseline} = {
            files => 1, lines_each => 80, bytes_each => 1000,
            line_bytes_each => 1024, lines_total => 80, bytes_total => 1000,
        };
        $_[0]{transition} = {
            owner => 'containment-program',
            max_growth => {
                files => 0, lines_each => 21, bytes_each => 0,
                line_bytes_each => 0, lines_total => 21, bytes_total => 0,
            },
            ratchet_step => pressure(1, 10, 1024, 10, 1024),
        };
    });
    my ($allowance_ok, $allowance_output) = run_checker($oversized_allowance);
    ok(!$allowance_ok, 'transition allowance beyond the hard budget is rejected');
    like($allowance_output, qr/transition baseline plus growth exceeds ceiling_lines_each/,
        'allowance/ceiling conflict is explicit');

    my $stale = make_fixture();
    write_file($stale, 'destination.md', join('', map { "line $_\n" } 1 .. 50));
    mutate_record($stale, 'registry/surfaces.jsonl', 'bounded_destination', sub {
        $_[0]{health_targets} = pressure(1, 40, 4096, 40, 16384);
        $_[0]{state} = 'rollover_debt';
        $_[0]{containment_status} = 'pinned_deferred';
        $_[0]{baseline} = pressure(1, 50, 1000, 50, 1000);
        $_[0]{transition} = {
            owner => 'containment-program',
            max_growth => pressure(0, 0, 0, 0, 0),
            ratchet_step => pressure(1, 10, 1024, 10, 1024),
        };
    });
    my ($stale_ok, $stale_output) = run_checker($stale);
    ok(!$stale_ok, 'stale excess ceiling headroom is rejected');
    like($stale_output, qr/ceiling 100 retains stale excess headroom/,
        'downward ratchet failure is explicit');

    my $owner = make_fixture();
    mutate_record($owner, 'registry/surfaces.jsonl', 'ledger', sub {
        $_[0]{owner} = '';
    });
    my ($owner_ok, $owner_output) = run_checker($owner);
    ok(!$owner_ok, 'empty owner is rejected');
    like($owner_output, qr/invalid string key: owner|must declare an owner/, 'owner requirement is explicit');
};

subtest 'route graph rejects missing markers, missing edges, unknown targets, and cycles' => sub {
    my $marker = make_fixture();
    write_file($marker, 'entry.md', "no destination marker\n");
    my ($marker_ok, $marker_output) = run_checker($marker);
    ok(!$marker_ok, 'stale source marker is rejected');
    like($marker_output, qr/route destination marker is absent from entry\.md/,
        'missing marker is explicit');

    my $edge = make_fixture();
    write_file($edge, 'registry/routes.jsonl', '');
    my ($edge_ok, $edge_output) = run_checker($edge);
    ok(!$edge_ok, 'declared edge without route record is rejected');
    like($edge_output, qr/surface edge bounded_entry -> bounded_destination lacks a route-registry row/,
        'missing route record is explicit');

    my $unknown = make_fixture();
    mutate_record($unknown, 'registry/routes.jsonl', 'destination', sub {
        $_[0]{target_surface_id} = 'absent';
    }, 'route_id');
    my ($unknown_ok, $unknown_output) = run_checker($unknown);
    ok(!$unknown_ok, 'unknown route endpoint is rejected');
    like($unknown_output, qr/route destination has unknown target surface: absent/,
        'unknown endpoint is named');

    my $cycle = make_fixture();
    write_file($cycle, 'destination.md', "entry.md\n");
    mutate_record($cycle, 'registry/surfaces.jsonl', 'bounded_destination', sub {
        $_[0]{routes_to} = ['bounded_entry'];
    });
    append_file($cycle, 'registry/routes.jsonl', json_line({
        route_id => 'return', route_kind => 'reader_navigation',
        source_path => 'destination.md', source_surface_id => 'bounded_destination',
        marker => 'entry.md', target_surface_id => 'bounded_entry',
    }));
    my ($cycle_ok, $cycle_output) = run_checker($cycle);
    ok(!$cycle_ok, 'route cycle is rejected');
    like($cycle_output, qr/surface route cycle:/, 'cycle is explicit');
};

subtest 'typed routes, collection indexes, and evidence maps fail closed' => sub {
    my $route_kind = make_fixture();
    mutate_record($route_kind, 'registry/routes.jsonl', 'destination', sub {
        $_[0]{route_kind} = 'content_route';
    }, 'route_id');
    my ($kind_ok, $kind_output) = run_checker($route_kind);
    ok(!$kind_ok, 'unknown route kind is rejected');
    like($kind_output, qr/invalid route_kind/, 'wrong route kind is explicit');

    my $membership = make_fixture();
    write_file($membership, 'index.md', "[Part A](parts/a.md)\n");
    my ($membership_ok, $membership_output) = run_checker($membership);
    ok(!$membership_ok, 'omitted collection member is rejected');
    like($membership_output, qr/collection index omits member: parts\/b\.md/,
        'missing collection member is named');

    my $evidence = make_fixture();
    write_file(
        $evidence,
        'evidence.md',
        "<!-- EVIDENCE:BEGIN -->\n| Concern | Evidence |\n| --- | --- |\n"
            . "| Missing | `absent.md` |\n<!-- EVIDENCE:END -->\n",
    );
    my ($evidence_ok, $evidence_output) = run_checker($evidence);
    ok(!$evidence_ok, 'missing evidence-map path is rejected');
    like($evidence_output, qr/evidence map fixture path is absent or unsafe: absent\.md/,
        'missing evidence path names its map and path');
};

subtest 'projection and terminal verifiers fail closed' => sub {
    my $freshness = make_fixture();
    chmod 0644, File::Spec->catfile($freshness, 'bin', 'freshness')
        or die "cannot remove fixture execute bit: $!";
    my ($fresh_ok, $fresh_output) = run_checker($freshness);
    ok(!$fresh_ok, 'non-executable freshness verifier is rejected');
    like($fresh_output, qr/core verifier is absent or not executable/, 'freshness failure is explicit');

    my $failed = make_fixture();
    write_file($failed, 'bin/freshness', "#!/bin/sh\nexit 7\n");
    chmod 0755, File::Spec->catfile($failed, 'bin', 'freshness')
        or die "cannot chmod failing verifier: $!";
    my ($failed_ok, $failed_output) = run_checker($failed);
    ok(!$failed_ok, 'nonzero core freshness verifier is rejected');
    like($failed_output, qr/core verifier failed \(exit 7\)/,
        'executed failure status is explicit');

    my $adapter = make_fixture();
    mutate_record($adapter, 'registry/surfaces.jsonl', 'projection', sub {
        $_[0]{verifier} = 'adapter:bin/freshness';
    });
    my ($missing_proof_ok, $missing_proof_output) = run_checker($adapter);
    ok(!$missing_proof_ok, 'adapter declaration without executed proof is rejected');
    like($missing_proof_output, qr/adapter verifier lacks executed proof: surface:projection/,
        'missing adapter proof is explicit');
    my ($proof_ok, $proof_output) = run_checker(
        $adapter, adapter_proofs => ['surface:projection'],
    );
    ok($proof_ok, 'matching adapter execution proof passes') or diag($proof_output);

    my $degraded = make_fixture();
    mutate_record($degraded, 'registry/surfaces.jsonl', 'projection', sub {
        $_[0]{verifier} = 'external:remote-freshness-contract';
    });
    my ($degraded_ok, $degraded_output) = run_checker($degraded);
    ok(!$degraded_ok, 'external verification cannot produce a local green result');
    like($degraded_output, qr/external verification is declared but not locally proven; degraded result/,
        'external degradation is visible and fail-closed');

    my $unused = make_fixture();
    my ($unused_ok, $unused_output) = run_checker(
        $unused, adapter_proofs => ['surface:projection'],
    );
    ok(!$unused_ok, 'proof without an adapter declaration is rejected');
    like($unused_output, qr/adapter proof does not match a declared adapter verifier/,
        'vacuous stale proof is explicit');

    my $query = make_fixture();
    chmod 0644, File::Spec->catfile($query, 'bin', 'query')
        or die "cannot remove query execute bit: $!";
    my ($query_ok, $query_output) = run_checker($query);
    ok(!$query_ok, 'non-executable query is rejected');
    like($query_output, qr/query target is absent or not executable/, 'query failure is explicit');

    my $archive = make_fixture();
    mutate_record($archive, 'registry/surfaces.jsonl', 'archive_terminal', sub {
        $_[0]{targets} = ['missing-archive'];
        $_[0]{verifier} = 'archive:missing-archive';
    });
    my ($archive_ok, $archive_output) = run_checker($archive);
    ok(!$archive_ok, 'missing archive terminal is rejected');
    like($archive_output, qr/target directory is absent: missing-archive/, 'archive failure is explicit');

    my $external = make_fixture();
    mutate_record($external, 'registry/surfaces.jsonl', 'external_terminal', sub {
        $_[0]{verifier} = 'builtin:none';
    });
    my ($external_ok, $external_output) = run_checker($external);
    ok(!$external_ok, 'undeclared external verifier is rejected');
    like($external_output, qr/external verifier must start with external:/, 'external failure is explicit');

    my $frozen = make_fixture();
    write_file($frozen, 'frozen.md', "changed\n");
    my ($frozen_ok, $frozen_output) = run_checker($frozen);
    ok(!$frozen_ok, 'frozen content drift is rejected');
    like($frozen_output, qr/frozen identity changed/, 'identity failure is explicit');
};

subtest 'archive descriptors reject digest drift and unsafe former paths' => sub {
    my $digest = make_fixture();
    write_file($digest, 'archived-range.md', "# Entry 2\nchanged archived bytes\n");
    my ($digest_ok, $digest_output) = run_checker($digest);
    ok(!$digest_ok, 'archive retrieval digest drift is rejected');
    like($digest_output, qr/archive descriptor ledger_0001 retrieval digest changed/,
        'descriptor identity failure is explicit');

    my $path = make_fixture();
    mutate_record($path, 'registry/archive.jsonl', 'ledger_0001', sub {
        $_[0]{former_path} = '../outside.md';
    }, 'descriptor_id');
    my ($path_ok, $path_output) = run_checker($path);
    ok(!$path_ok, 'unsafe former path is rejected');
    like($path_output, qr/former_path must stay project-relative/, 'unsafe descriptor path is explicit');

    my $version = make_fixture();
    mutate_record($version, 'registry/archive.jsonl', 'ledger_0001', sub {
        $_[0]{schema_version} = 2;
    }, 'descriptor_id');
    my ($version_ok, $version_output) = run_checker($version);
    ok(!$version_ok, 'unknown descriptor schema version is rejected');
    like($version_output, qr/unsupported schema_version: 2/, 'schema version is explicit');
};

subtest 'ledger manifests reject split entries, order gaps, reconstruction drift, and live aggregate overflow' => sub {
    my $split = make_fixture();
    my $sealed = first_sealed_range_path($split);
    write_file($split, $sealed, "bytes before entry\n# Entry 1\nold one\n");
    mutate_record($split, 'registry/ledgers.jsonl', 'fixture_range_0001', sub {
        my $contents = slurp(File::Spec->catfile($split, split m{/}, $sealed));
        $_[0]{lines} = ($contents =~ tr/\n//);
        $_[0]{bytes} = length($contents);
        $_[0]{sha256} = sha256_hex($contents);
    }, 'range_id');
    my ($split_ok, $split_output) = run_checker($split);
    ok(!$split_ok, 'bytes before a sealed whole entry are rejected');
    like($split_output, qr/sealed range has bytes before its first whole entry/,
        'whole-entry boundary failure is explicit');

    my $order = make_fixture();
    mutate_record($order, 'registry/ledgers.jsonl', 'fixture_range_0002', sub {
        $_[0]{first_ordinal} = 3;
        $_[0]{last_ordinal} = 3;
    }, 'range_id');
    my ($order_ok, $order_output) = run_checker($order);
    ok(!$order_ok, 'an ordinal gap is rejected');
    like($order_output, qr/ordinal range is not contiguous/,
        'order failure is explicit');

    my $reconstruction = make_fixture();
    mutate_record($reconstruction, 'registry/ledgers.jsonl', 'fixture_ledger', sub {
        return if ($_[0]{record_type} // '') ne 'ledger';
        $_[0]{entries_sha256} = '0' x 64;
    }, 'ledger_id');
    my ($reconstruction_ok, $reconstruction_output) = run_checker($reconstruction);
    ok(!$reconstruction_ok, 'aggregate reconstruction digest drift is rejected');
    like($reconstruction_output, qr/reconstructed digest changed/,
        'reconstruction failure is explicit');

    my $aggregate = make_fixture();
    mutate_record($aggregate, 'registry/ledgers.jsonl', 'fixture_ledger', sub {
        return if ($_[0]{record_type} // '') ne 'ledger';
        $_[0]{archive_transition}{max_live_bytes} = 1;
    }, 'ledger_id');
    my ($aggregate_ok, $aggregate_output) = run_checker($aggregate);
    ok(!$aggregate_ok, 'live sealed history beyond the archive transition is rejected');
    like($aggregate_output, qr/live sealed bytes are .*archive-transition limit 1/,
        'aggregate archive transition failure is explicit');

    my $index = make_fixture();
    write_file($index, 'ledger-index.md', "fixture_range_0001\nfixture_range_0003\n");
    my ($index_ok, $index_output) = run_checker($index);
    ok(!$index_ok, 'bounded ledger index omitting a range is rejected');
    like($index_output, qr/index omits range fixture_range_0002/,
        'index completeness failure is explicit');
};

subtest 'version-backed ledger reconstruction requires executed proof' => sub {
    my $core = make_fixture();
    mutate_record($core, 'registry/archive.jsonl', 'ledger_source', sub {
        $_[0]{retrieval_kind} = 'version_object';
        $_[0]{retrieval_locator} = 'fixture-ledger-source';
        $_[0]{verifier} = 'core:bin/version';
        $_[0]{retention_contract} = 'fixture_history';
    }, 'descriptor_id');
    mutate_record($core, 'registry/ledgers.jsonl', 'fixture_ledger', sub {
        return if ($_[0]{record_type} // '') ne 'ledger';
        $_[0]{reconstruction_verifier} = 'core:bin/reconstruct';
    }, 'ledger_id');
    my ($core_ok, $core_output) = run_checker($core);
    ok($core_ok, 'core reconstruction verifier closes a version-backed source')
        or diag($core_output);
    ok(-f File::Spec->catfile($core, 'reconstruction-ran'),
        'core ledger reconstruction verifier actually ran');

    my $missing = make_fixture();
    mutate_record($missing, 'registry/ledgers.jsonl', 'fixture_ledger', sub {
        return if ($_[0]{record_type} // '') ne 'ledger';
        $_[0]{reconstruction_verifier} = 'adapter:bin/reconstruct';
    }, 'ledger_id');
    my ($missing_ok, $missing_output) = run_checker($missing);
    ok(!$missing_ok, 'adapter reconstruction without an executed proof is rejected');
    like($missing_output, qr/adapter verifier lacks executed proof: ledger:fixture_ledger/,
        'missing ledger proof is explicit');

    my $proved = make_fixture();
    mutate_record($proved, 'registry/ledgers.jsonl', 'fixture_ledger', sub {
        return if ($_[0]{record_type} // '') ne 'ledger';
        $_[0]{reconstruction_verifier} = 'adapter:bin/reconstruct';
    }, 'ledger_id');
    my ($proved_ok, $proved_output) = run_checker(
        $proved, adapter_proofs => ['ledger:fixture_ledger'],
    );
    ok($proved_ok, 'exact one-use adapter reconstruction proof passes')
        or diag($proved_output);
};

subtest 'version-object descriptors require bounded named retention contracts' => sub {
    my $missing = make_fixture();
    mutate_record($missing, 'registry/archive.jsonl', 'ledger_0002', sub {
        delete $_[0]{retention_contract};
    }, 'descriptor_id');
    my ($missing_ok, $missing_output) = run_checker($missing);
    ok(!$missing_ok, 'missing retention contract is rejected');
    like($missing_output, qr/invalid or missing retention_contract/,
        'missing contract diagnostic is explicit');

    my $unknown = make_fixture();
    mutate_record($unknown, 'registry/archive.jsonl', 'ledger_0002', sub {
        $_[0]{retention_contract} = 'missing_history';
    }, 'descriptor_id');
    my ($unknown_ok, $unknown_output) = run_checker($unknown);
    ok(!$unknown_ok, 'unknown retention contract is rejected');
    like($unknown_output, qr/names unknown retention contract: missing_history/,
        'unknown contract diagnostic is explicit');

    my $failed_retrieval = make_fixture();
    write_file($failed_retrieval, 'bin/version', "#!/bin/sh\nexit 1\n");
    chmod 0755, File::Spec->catfile($failed_retrieval, 'bin', 'version')
        or die "cannot chmod failing version fixture: $!";
    my ($failed_ok, $failed_output) = run_checker($failed_retrieval);
    ok(!$failed_ok, 'failed version-object retrieval is rejected');
    like(
        $failed_output,
        qr/retention contract fixture_history owner fixture-maintainers requires recovery: Fetch complete fixture history/,
        'failed retrieval names the contract owner and recovery action',
    );

    my $unbounded = make_fixture();
    mutate_record($unbounded, 'registry/retention.jsonl', '', sub {
        $_[0]{max_records} = 0;
    }, 'contract_id');
    my ($unbounded_ok, $unbounded_output) = run_checker($unbounded);
    ok(!$unbounded_ok, 'unbounded retention registry is rejected');
    like($unbounded_output, qr/metadata has invalid positive max_records/,
        'retention control-plane bound is explicit');
};

subtest 'optional NUL coverage rejects undeclared documents' => sub {
    my $covered = make_fixture();
    my ($covered_ok, $covered_output) = run_checker(
        $covered, coverage => [qw(entry.md destination.md parts/a.md generated.md ledger.md frozen.md)],
    );
    ok($covered_ok, 'declared coverage paths pass') or diag($covered_output);
    like($covered_output, qr/coverage: 6\/6 declared document path\(s\)/, 'coverage count is exact');

    my $missing = make_fixture();
    my ($missing_ok, $missing_output) = run_checker(
        $missing, coverage => ['entry.md', 'unregistered.md'],
    );
    ok(!$missing_ok, 'unregistered document is rejected');
    like($missing_output, qr/tracked document is not covered by any surface: unregistered\.md/,
        'uncovered path is named');
};

subtest 'neutral package contains no adopting-project or harness identity' => sub {
    my $contents = slurp($checker) . slurp($contract);
    unlike(
        $contents,
        qr/(?:FSMGen|ANVIL|PGEN|Claude|Codex|Cursor|Gemini|Windsurf|GitHub|\/Volumes\/|AGENTS\.md|\.cursorrules)/i,
        'neutral checker and contract contain no local project or harness identity',
    );
    like($contents, qr/project-neutral, project-agnostic, and harness-neutral/,
        'neutrality promise is explicit');
    like($contents, qr/JSON Lines \(JSONL\)/, 'serialization contract is explicit');
};

done_testing();

sub make_fixture {
    my $root = create_project_tempdir(purpose => 'live-document-size-tests');
    my @ledger_entries = (
        "# Entry 1\nold one\n",
        "# Entry 2\nold two\n",
        "# Entry 3\ncurrent entry\n",
    );
    my $ledger_source = join('', @ledger_entries);
    my $sealed_digest = sha256_hex($ledger_entries[0]);
    my $sealed_path = "ledger-segments/$sealed_digest.md";
    write_file($root, 'entry.md', "destination.md\n");
    write_file($root, 'destination.md', "destination\n");
    write_file($root, 'parts/a.md', "part a\n");
    write_file($root, 'parts/b.md', "part b\n");
    write_file($root, 'index.md', "[Part A](parts/a.md)\n[Part B](parts/b.md)\n");
    write_file($root, 'reference/a.md', "reference a\n");
    write_file($root, 'reference/b.md', "reference b\n");
    write_file($root, 'reference-index.md',
        "[Reference A](reference/a.md)\n[Reference B](reference/b.md)\n");
    write_file($root, 'canonical/source.md', "canonical\n");
    write_file($root, 'generated.md', "generated\n");
    write_file($root, 'ledger.md',
        "# Ledger\nHistory: ledger-index.md\n" . $ledger_entries[2]);
    write_file($root, 'ledger-index.md',
        "fixture_range_0001\nfixture_range_0002\nfixture_range_0003\n");
    write_file($root, 'ledger-source.md', $ledger_source);
    write_file($root, $sealed_path, $ledger_entries[0]);
    write_file($root, 'archived-range.md', $ledger_entries[1]);
    write_file($root, 'frozen.md', "frozen\n");
    write_file($root, 'proof.md', "proof\n");
    write_file(
        $root,
        'evidence.md',
        "<!-- EVIDENCE:BEGIN -->\n| Concern | Evidence |\n| --- | --- |\n"
            . "| Fixture | `proof.md` |\n<!-- EVIDENCE:END -->\n",
    );
    write_file($root, 'bin/query', "#!/bin/sh\nexit 0\n");
    write_file($root, 'bin/freshness', "#!/bin/sh\nprintf 'freshness\\n' > freshness-ran\n");
    write_file($root, 'bin/version', "#!/bin/sh\nprintf 'version\\n' > version-ran\n");
    write_file($root, 'bin/reconstruct',
        "#!/bin/sh\nprintf 'reconstruction\\n' > reconstruction-ran\n");
    chmod 0755, File::Spec->catfile($root, 'bin', 'query'),
        File::Spec->catfile($root, 'bin', 'freshness'),
        File::Spec->catfile($root, 'bin', 'version'),
        File::Spec->catfile($root, 'bin', 'reconstruct')
        or die "cannot chmod fixture executables: $!";
    make_path(File::Spec->catdir($root, '.history'));

    my @surfaces = (
        measured('bounded_entry', 'bounded_snapshot', 'file', ['entry.md'], undef, [],
            ['bounded_destination']),
        measured('bounded_destination', 'bounded_snapshot', 'file', ['destination.md'], undef, [], []),
        measured('partitioned', 'partitioned_canonical', 'collection', ['parts/*.md'], 'index.md', [], []),
        maintained_reference(),
        measured('projection', 'generated_projection', 'generated_file', ['generated.md'], undef,
            ['canonical/*.md'], [], 'core:bin/freshness'),
        terminal('query_terminal', 'generated_projection', 'query', 'bin/query',
            'executable:bin/query'),
        measured('ledger', 'rolling_ledger', 'file', ['ledger.md'], undef, [], []),
        terminal('archive_terminal', 'archive_terminal', 'archive', '.history',
            'archive:.history'),
        terminal('external_terminal', 'external_terminal', 'external', 'records:remote',
            'external:documented-contract'),
        frozen('frozen_record', 'frozen.md', sha256_hex("frozen\n")),
    );
    write_file($root, 'registry/surfaces.jsonl', registry_header(16, 32768, 4096)
        . join('', map { json_line($_) } @surfaces));
    write_file($root, 'registry/routes.jsonl', registry_header(8, 4096, 1024) . json_line({
        route_id => 'destination', route_kind => 'reader_navigation',
        source_path => 'entry.md', source_surface_id => 'bounded_entry',
        marker => 'destination.md', target_surface_id => 'bounded_destination',
    }));
    write_file($root, 'registry/evidence.jsonl', registry_header(8, 4096, 1024) . json_line({
        map_id => 'fixture', source_path => 'evidence.md',
        begin_marker => '<!-- EVIDENCE:BEGIN -->',
        end_marker => '<!-- EVIDENCE:END -->',
    }));
    write_file($root, 'registry/archive.jsonl',
        registry_header(8, 8192, 2048) . json_line({
        record_type => 'descriptor', schema_version => 1,
        descriptor_id => 'ledger_0001', surface_id => 'ledger', former_path => 'ledger-old.md',
        range_id => 'fixture_range_0002', revision => 'fixture-revision', lines => 2,
        bytes => length($ledger_entries[1]), sha256 => sha256_hex($ledger_entries[1]),
        retrieval_kind => 'file', retrieval_locator => 'archived-range.md',
        current_pointer => 'ledger.md', sealed_on => '2030-01-01', verifier => 'builtin:file',
    }) . json_line({
        record_type => 'descriptor', schema_version => 1,
        descriptor_id => 'ledger_source', surface_id => 'ledger', former_path => 'ledger.md',
        range_id => 'complete-source', revision => 'fixture-revision', lines => 6,
        bytes => length($ledger_source), sha256 => sha256_hex($ledger_source),
        retrieval_kind => 'file', retrieval_locator => 'ledger-source.md',
        current_pointer => 'ledger.md', sealed_on => '2030-01-01', verifier => 'builtin:file',
    }) . json_line({
        record_type => 'descriptor', schema_version => 1,
        descriptor_id => 'ledger_0002', surface_id => 'ledger', former_path => 'ledger-older.md',
        range_id => 'unrelated-version-object', revision => 'fixture-revision', lines => 2,
        bytes => length($ledger_entries[1]), sha256 => sha256_hex($ledger_entries[1]),
        retrieval_kind => 'version_object', retrieval_locator => 'fixture-object',
        current_pointer => 'ledger.md', sealed_on => '2030-01-02',
        verifier => 'core:bin/version', retention_contract => 'fixture_history',
    }));
    write_file($root, 'registry/retention.jsonl',
        json_line({
            record_type => 'registry', schema_version => 1,
            max_records => 4, max_bytes => 4096, max_record_bytes => 2048,
        }) . json_line({
            record_type => 'contract', schema_version => 1,
            contract_id => 'fixture_history', owner => 'fixture-maintainers',
            guarantee => 'Fixture version objects remain reachable.',
            recovery => 'Fetch complete fixture history, restore the object, and rerun the gate.',
        }));
    my @ranges = (
        ledger_range(
            'fixture_range_0001', 1, 1, $ledger_entries[0], 'fixture-revision',
            'sealed_file', $sealed_path, 'builtin:file',
        ),
        ledger_range(
            'fixture_range_0002', 2, 2, $ledger_entries[1], 'fixture-revision',
            'archive_descriptor', 'ledger_0001', 'builtin:archive_descriptor',
        ),
        ledger_range(
            'fixture_range_0003', 3, 3, $ledger_entries[2], 'worktree',
            'current', 'ledger.md', 'builtin:current',
        ),
    );
    write_file($root, 'registry/ledgers.jsonl',
        registry_header(16, 16384, 4096) . json_line({
            record_type => 'ledger', schema_version => 1,
            ledger_id => 'fixture_ledger', surface_id => 'ledger',
            current_path => 'ledger.md', index_path => 'ledger-index.md',
            entry_start_prefix => '# Entry ', ordering => 'append_only',
            source_descriptor_id => 'ledger_source', total_entries => 3,
            entries_lines => 6, entries_bytes => length($ledger_source),
            entries_sha256 => sha256_hex($ledger_source), current_entry_limit => 2,
            index_lines_ceiling => 8, index_bytes_ceiling => 512,
            reconstruction_verifier => 'builtin:concatenate',
            archive_transition => {
                archive_surface_id => 'archive_terminal', max_live_ranges => 1,
                max_live_lines => 4, max_live_bytes => 128,
            },
        }) . join('', map { json_line($_) } @ranges));
    return $root;
}

sub ledger_range {
    my ($range_id, $sequence, $ordinal, $contents, $revision,
        $storage_kind, $storage_locator, $verifier) = @_;
    return {
        record_type => 'range', schema_version => 1,
        range_id => $range_id, ledger_id => 'fixture_ledger', sequence => $sequence,
        first_ordinal => $ordinal, last_ordinal => $ordinal, entry_count => 1,
        revision => $revision, lines => ($contents =~ tr/\n//), bytes => length($contents),
        sha256 => sha256_hex($contents), first_entry_sha256 => sha256_hex($contents),
        last_entry_sha256 => sha256_hex($contents), storage_kind => $storage_kind,
        storage_locator => $storage_locator, verifier => $verifier,
    };
}

sub first_sealed_range_path {
    my ($root) = @_;
    my @records = map { decode_json($_) } grep { $_ ne '' }
        split /\n/, slurp(File::Spec->catfile($root, 'registry', 'ledgers.jsonl'));
    for my $record (@records) {
        return $record->{storage_locator}
            if ($record->{range_id} // '') eq 'fixture_range_0001';
    }
    die 'fixture sealed ledger range not found';
}

sub measured {
    my ($id, $lifecycle, $locator, $targets, $index, $inputs, $routes, $verifier) = @_;
    my $record = {
        surface_id => $id, lifecycle => $lifecycle, locator => $locator,
        targets => $targets, index => $index, canonical_inputs => $inputs,
        routes_to => $routes, owner => 'fixture-owner',
        health_targets => pressure(8, 100, 4096, 400, 16384),
        enforcement_ceilings => pressure(8, 100, 4096, 400, 16384),
        milestones => { warning_pct => 80, rollover_pct => 90 },
        containment_status => 'steady', state => 'normal', baseline => undef,
        verifier => $verifier // 'builtin:budget',
    };
    $record->{index_contract} = {
        kind => 'membership', verifier => 'builtin:markdown_links',
    } if $locator eq 'collection' && defined $index;
    return $record;
}

sub maintained_reference {
    my $record = measured(
        'maintained', 'maintained_reference', 'collection',
        ['reference/*.md'], 'reference-index.md', [], [],
        'builtin:maintained_reference',
    );
    $record->{health_targets} = reference_pressure(100, 4096);
    $record->{enforcement_ceilings} = reference_pressure(100, 4096);
    $record->{classification} = {
        audience => 'fixture readers', role => 'unique_product_reference',
        rationale => 'Unique maintained prose grows only when the fixture product grows.',
    };
    $record->{reference_contract} = {
        mandatory_read => {
            path => 'reference-index.md', lines_ceiling => 10, bytes_ceiling => 1024,
        },
        max_navigation_depth => 1,
        aggregate_change => {
            authority_id => 'REFERENCE-FIXTURE.1', owner => 'fixture-owner',
            rationale => 'Initial exact fixture classification.',
            baseline => {
                files => 2, lines_total => 2,
                bytes_total => length("reference a\nreference b\n"),
            },
            delta => { files => 0, lines_total => 0, bytes_total => 0 },
        },
    };
    return $record;
}

sub terminal {
    my ($id, $lifecycle, $locator, $target, $verifier) = @_;
    return {
        surface_id => $id, lifecycle => $lifecycle, locator => $locator,
        targets => [$target], index => undef, canonical_inputs => [], routes_to => [],
        owner => 'fixture-owner', health_targets => undef,
        enforcement_ceilings => undef, milestones => undef,
        containment_status => 'not_applicable', state => 'terminal',
        baseline => undef, verifier => $verifier,
    };
}

sub frozen {
    my ($id, $target, $digest) = @_;
    return {
        surface_id => $id, lifecycle => 'frozen_legacy', locator => 'frozen',
        targets => [$target], index => undef, canonical_inputs => [], routes_to => [],
        owner => 'fixture-owner', health_targets => undef,
        enforcement_ceilings => undef, milestones => undef,
        containment_status => 'not_applicable', state => 'frozen',
        baseline => undef, verifier => "sha256:$digest",
    };
}

sub pressure {
    my ($files, $lines_each, $bytes_each, $lines_total, $bytes_total) = @_;
    return {
        files => $files, lines_each => $lines_each, bytes_each => $bytes_each,
        line_bytes_each => 1024, lines_total => $lines_total, bytes_total => $bytes_total,
    };
}

sub reference_pressure {
    my ($lines_each, $bytes_each) = @_;
    return {
        files => undef, lines_each => $lines_each, bytes_each => $bytes_each,
        line_bytes_each => 1024, lines_total => undef, bytes_total => undef,
    };
}

sub transition {
    my ($files, $lines_each, $bytes_each, $lines_total, $bytes_total) = @_;
    return {
        owner => 'containment-program',
        max_growth => {
            %{pressure($files, $lines_each, $bytes_each, $lines_total, $bytes_total)},
            line_bytes_each => 0,
        },
        ratchet_step => {
            %{pressure(1, 10, 1024, 10, 1024)},
            line_bytes_each => 128,
        },
    };
}

sub run_checker {
    my ($root, %options) = @_;
    my @command = (
        $^X, $checker, '--root', $root,
        '--registry', 'registry/surfaces.jsonl',
        '--routes', 'registry/routes.jsonl',
        '--archives', 'registry/archive.jsonl',
        '--ledgers', 'registry/ledgers.jsonl',
        '--evidence-maps', 'registry/evidence.jsonl',
        '--retention-contracts', 'registry/retention.jsonl',
    );
    my $input = '';
    if ($options{coverage}) {
        push @command, '--coverage-stdin';
        $input = join("\0", @{$options{coverage}}) . "\0";
    }
    for my $proof (@{$options{adapter_proofs} || []}) {
        push @command, '--adapter-proof', $proof;
    }
    my $stderr = gensym;
    my $pid = open3(my $stdin, my $stdout, $stderr, @command);
    print {$stdin} $input;
    close $stdin;
    local $/;
    my $out = <$stdout> // '';
    my $err = <$stderr> // '';
    waitpid($pid, 0);
    return ($? == 0 ? 1 : 0, $out . $err);
}

sub mutate_record {
    my ($root, $relative, $id, $mutator, $id_key) = @_;
    $id_key //= 'surface_id';
    my $path = File::Spec->catfile($root, split m{/}, $relative);
    my @records = map { decode_json($_) } grep { $_ ne '' } split /\n/, slurp($path);
    my $found = 0;
    for my $record (@records) {
        next if ($record->{$id_key} // '') ne $id;
        $mutator->($record);
        $found++;
    }
    die "fixture record $id not found in $relative" if !$found;
    write_file($root, $relative, join('', map { json_line($_) } @records));
}

sub json_line {
    my ($record) = @_;
    return $json->encode($record) . "\n";
}

sub registry_header {
    my ($max_records, $max_bytes, $max_record_bytes) = @_;
    return json_line({
        record_type => 'registry', schema_version => 1,
        max_records => $max_records, max_bytes => $max_bytes,
        max_record_bytes => $max_record_bytes,
    });
}

sub write_file {
    my ($root, $relative, $contents) = @_;
    my $path = File::Spec->catfile($root, split m{/}, $relative);
    make_path(dirname($path));
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    print {$fh} $contents;
    close $fh or die "cannot close $path: $!";
}

sub append_file {
    my ($root, $relative, $contents) = @_;
    my $path = File::Spec->catfile($root, split m{/}, $relative);
    open my $fh, '>>:raw', $path or die "cannot append $path: $!";
    print {$fh} $contents;
    close $fh or die "cannot close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $contents = <$fh>;
    close $fh or die "cannot close $path: $!";
    return $contents;
}
