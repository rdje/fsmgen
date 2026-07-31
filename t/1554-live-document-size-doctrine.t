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
    like($output, qr/surface projection: actual files=1,/, 'generated projection is measured');
    like($output, qr/surface query_terminal: query terminal/, 'query projection is validated');
    like($output, qr/surface ledger: actual files=1,/, 'rolling ledger is measured');
    like($output, qr/surface archive_terminal: archive terminal/, 'archive terminal is validated');
    like($output, qr/surface external_terminal: external terminal declared/, 'external terminal is validated');
    like($output, qr/surface frozen_record: frozen identity checked/, 'frozen identity is validated');
    ok(-f File::Spec->catfile($fixture, 'freshness-ran'), 'core freshness verifier actually ran');
    ok(-f File::Spec->catfile($fixture, 'version-ran'), 'core version retrieval verifier actually ran');
    like($output, qr/all live-document size-containment invariants hold \(9 surfaces\)/,
        'complete graph closes');
};

subtest 'JSONL schema rejects malformed, blank, missing, and unknown data' => sub {
    my $malformed = make_fixture();
    append_file($malformed, 'registry/surfaces.jsonl', "{not-json}\n");
    my ($malformed_ok, $malformed_output) = run_checker($malformed);
    ok(!$malformed_ok, 'malformed JSON is rejected');
    like($malformed_output, qr/surface registry line 10 is invalid JSON/, 'line is named');

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
    like($metadata_output, qr/lacks its schema metadata record/,
        'missing archive metadata is explicit');
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
            lines_total => 100, bytes_total => length($equality_contents),
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
            lines_total => 80, bytes_total => 10000,
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
            lines_total => 80, bytes_total => length($allowed_contents),
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
            lines_total => 1, bytes_total => 12,
        };
        $_[0]{transition} = {
            owner => '',
            max_growth => {
                files => 0, lines_each => 1, bytes_each => 1,
                lines_total => 1, bytes_total => 1,
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
            lines_total => 80, bytes_total => 1000,
        };
        $_[0]{transition} = {
            owner => 'containment-program',
            max_growth => {
                files => 0, lines_each => 21, bytes_each => 0,
                lines_total => 21, bytes_total => 0,
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
        route_id => 'return', source_surface_id => 'bounded_destination',
        marker => 'entry.md', target_surface_id => 'bounded_entry',
    }));
    my ($cycle_ok, $cycle_output) = run_checker($cycle);
    ok(!$cycle_ok, 'route cycle is rejected');
    like($cycle_output, qr/surface route cycle:/, 'cycle is explicit');
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
    write_file($digest, 'sealed.md', "changed sealed bytes\n");
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
    write_file($root, 'entry.md', "destination.md\n");
    write_file($root, 'destination.md', "destination\n");
    write_file($root, 'parts/a.md', "part a\n");
    write_file($root, 'parts/b.md', "part b\n");
    write_file($root, 'index.md', "index\n");
    write_file($root, 'canonical/source.md', "canonical\n");
    write_file($root, 'generated.md', "generated\n");
    write_file($root, 'ledger.md', "current entry\n");
    write_file($root, 'frozen.md', "frozen\n");
    write_file($root, 'sealed.md', "sealed bytes\n");
    write_file($root, 'bin/query', "#!/bin/sh\nexit 0\n");
    write_file($root, 'bin/freshness', "#!/bin/sh\nprintf 'freshness\\n' > freshness-ran\n");
    write_file($root, 'bin/version', "#!/bin/sh\nprintf 'version\\n' > version-ran\n");
    chmod 0755, File::Spec->catfile($root, 'bin', 'query'),
        File::Spec->catfile($root, 'bin', 'freshness'),
        File::Spec->catfile($root, 'bin', 'version')
        or die "cannot chmod fixture executables: $!";
    make_path(File::Spec->catdir($root, '.history'));

    my @surfaces = (
        measured('bounded_entry', 'bounded_snapshot', 'file', ['entry.md'], undef, [],
            ['bounded_destination']),
        measured('bounded_destination', 'bounded_snapshot', 'file', ['destination.md'], undef, [], []),
        measured('partitioned', 'partitioned_canonical', 'collection', ['parts/*.md'], 'index.md', [], []),
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
    write_file($root, 'registry/surfaces.jsonl', join('', map { json_line($_) } @surfaces));
    write_file($root, 'registry/routes.jsonl', json_line({
        route_id => 'destination', source_surface_id => 'bounded_entry',
        marker => 'destination.md', target_surface_id => 'bounded_destination',
    }));
    write_file($root, 'registry/archive.jsonl',
        json_line({ record_type => 'registry', schema_version => 1 }) . json_line({
        record_type => 'descriptor', schema_version => 1,
        descriptor_id => 'ledger_0001', surface_id => 'ledger', former_path => 'ledger-old.md',
        range_id => 'entries-1-1', revision => 'fixture-revision', lines => 1,
        bytes => length("sealed bytes\n"), sha256 => sha256_hex("sealed bytes\n"),
        retrieval_kind => 'file', retrieval_locator => 'sealed.md',
        current_pointer => 'ledger.md', sealed_on => '2030-01-01', verifier => 'builtin:file',
    }) . json_line({
        record_type => 'descriptor', schema_version => 1,
        descriptor_id => 'ledger_0002', surface_id => 'ledger', former_path => 'ledger-older.md',
        range_id => 'entries-2-2', revision => 'fixture-revision', lines => 1,
        bytes => length("sealed bytes\n"), sha256 => sha256_hex("sealed bytes\n"),
        retrieval_kind => 'version_object', retrieval_locator => 'fixture-object',
        current_pointer => 'ledger.md', sealed_on => '2030-01-02',
        verifier => 'core:bin/version',
    }));
    return $root;
}

sub measured {
    my ($id, $lifecycle, $locator, $targets, $index, $inputs, $routes, $verifier) = @_;
    return {
        surface_id => $id, lifecycle => $lifecycle, locator => $locator,
        targets => $targets, index => $index, canonical_inputs => $inputs,
        routes_to => $routes, owner => 'fixture-owner',
        health_targets => pressure(8, 100, 4096, 400, 16384),
        enforcement_ceilings => pressure(8, 100, 4096, 400, 16384),
        milestones => { warning_pct => 80, rollover_pct => 90 },
        containment_status => 'steady', state => 'normal', baseline => undef,
        verifier => $verifier // 'builtin:budget',
    };
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
        lines_total => $lines_total, bytes_total => $bytes_total,
    };
}

sub transition {
    my ($files, $lines_each, $bytes_each, $lines_total, $bytes_total) = @_;
    return {
        owner => 'containment-program',
        max_growth => pressure($files, $lines_each, $bytes_each, $lines_total, $bytes_total),
        ratchet_step => pressure(1, 10, 1024, 10, 1024),
    };
}

sub run_checker {
    my ($root, %options) = @_;
    my @command = (
        $^X, $checker, '--root', $root,
        '--registry', 'registry/surfaces.jsonl',
        '--routes', 'registry/routes.jsonl',
        '--archives', 'registry/archive.jsonl',
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
