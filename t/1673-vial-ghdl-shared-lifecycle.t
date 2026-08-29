#!/usr/bin/env perl

use strict;
use warnings;

use Config ();
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use JSON::PP ();
use Text::ParseWords qw(shellwords);
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::GHDLLifecycle;
use FSM::VIAL::Backend::ProcessSupervisor;
use FSM::VIAL::Backend::VHDLPortableTraceValidator;

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1);
my $fake_root_rel = ".artifacts/test/vial-ghdl-lifecycle-$$";
my $fake_root_abs = repo_path($fake_root_rel);
my @owned_stage;

END {
    for my $relative (@owned_stage) {
        my $absolute = repo_path($relative);
        remove_tree($absolute) if -d $absolute && !-l $absolute;
        unlink $absolute if -l $absolute;
    }
    remove_tree($fake_root_abs)
        if -d $fake_root_abs && !-l $fake_root_abs;
}

is_deeply(
    FSM::VIAL::Backend::GHDLLifecycle->state_order,
    [qw(
        admitted prepared tool_verified analyzed elaborated ran
        trace_validated result_produced assembled cleaned
    )],
    'GHDL lifecycle publishes the exact closed forward-only state order',
);

my $unsealed = FSM::VIAL::Backend::GHDLLifecycle->begin_session({});
ok(!$unsealed->{ok}, 'unsealed GHDL lifecycle admission rejects');
is(
    $unsealed->{diagnostics}[0]{code},
    'VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
    'unsealed GHDL lifecycle rejection has the stable diagnostic',
);

my $supervisor_unsealed = eval {
    FSM::VIAL::Backend::ProcessSupervisor->capture({});
    1;
};
ok(!$supervisor_unsealed, 'common production process supervisor is caller-sealed');

subtest 'admission is content-addressed, resumable, and abortable' => sub {
    my $request = fake_request('admission');
    my $begin = lifecycle_begin($request);
    diag($json->encode($begin->{diagnostics})) unless $begin->{ok};
    ok($begin->{ok}, 'sealed qualification caller admits one GHDL lifecycle');
    is($begin->{status}, 'admitted', 'admitted state is exact');
    like($begin->{lifecycle_identity}, qr{\Alifecycle/[0-9a-f]{64}\z},
        'lifecycle authority is content-addressed');
    like($begin->{handle}{state_identity}, qr{\Astate/[0-9a-f]{64}\z},
        'admitted state is content-addressed');
    is($begin->{handle}{next_state}, 'prepared',
        'admitted state names only its exact successor');
    is(scalar(@{$begin->{stage_evidence}}), 1,
        'admission reconstructs exactly one state');

    my $prepared = lifecycle_advance($request, $begin->{handle});
    ok($prepared->{ok}, 'fresh request and handle resume through preparation');
    is($prepared->{status}, 'prepared', 'prepared state is exact');
    is(scalar(@{$prepared->{stage_evidence}}), 2,
        'resume reconstructs the exact predecessor chain');

    my $abort = lifecycle_abort($request, $prepared->{handle});
    ok($abort->{ok}, 'prepared GHDL lifecycle aborts');
    is($abort->{status}, 'aborted_cleaned', 'abort is explicit and terminal');
    ok($abort->{cleanup}{removed}, 'abort proves exact removal');
    ok(!-e repo_path($request->{storage_context}{staging_identity}),
        'abort leaves no staging residue');
};

subtest 'collision and mutated handle preserve the proven owner' => sub {
    my $request = fake_request('collision');
    my $begin = lifecycle_begin($request);
    ok($begin->{ok}, 'first lifecycle owner admits');
    my $collision = lifecycle_begin($request);
    ok(!$collision->{ok}, 'second lifecycle owner rejects');
    is($collision->{diagnostics}[0]{code},
        'VIAL_GHDL_LIFECYCLE_COLLISION', 'collision diagnostic is exact');
    ok(-d repo_path($request->{storage_context}{staging_identity}),
        'collision preserves the first owner');

    my $skipped = clone($begin->{handle});
    $skipped->{next_state} = 'analyzed';
    my $rejected = lifecycle_advance($request, $skipped);
    ok(!$rejected->{ok}, 'mutated successor rejects');
    ok(-d repo_path($request->{storage_context}{staging_identity}),
        'unproved handle cannot delete the valid active owner');
    ok(lifecycle_abort($request, $begin->{handle})->{ok},
        'valid owner remains abortable after hostile requests');

    $request = fake_request('symlink-provider');
    my $provider_root = $request->{provider}{root};
    my $linked_root = "$fake_root_rel/provider-link";
    symlink('provider', repo_path($linked_root))
        or die "cannot create provider symlink control: $!";
    $request->{provider}{root} = $linked_root;
    $request->{provider}{archive} =~ s/\Q$provider_root\E/$linked_root/;
    $request->{provider}{binary} =~ s/\Q$provider_root\E/$linked_root/;
    for my $command (values %{$request->{commands}}) {
        $command->[0] = $request->{provider}{binary};
    }
    my $symlink = lifecycle_begin($request);
    ok(!$symlink->{ok}, 'provider symlink component rejects before admission');
    is($symlink->{diagnostics}[0]{code},
        'VIAL_GHDL_LIFECYCLE_PATH_ERROR', 'symlink diagnostic is exact');
    ok(!-e repo_path($request->{storage_context}{staging_identity}),
        'symlink rejection creates no lifecycle root');

    $request = fake_request('command-mutation');
    $begin = lifecycle_begin($request);
    my $changed = clone($request);
    push @{$changed->{commands}{run}}, '--foreign-option';
    my $command_rejected = lifecycle_advance($changed, $begin->{handle});
    ok(!$command_rejected->{ok}, 'command mutation after admission rejects');
    ok(-d repo_path($request->{storage_context}{staging_identity}),
        'foreign command authority cannot delete the valid owner');
    ok(lifecycle_abort($request, $begin->{handle})->{ok},
        'original command authority still cleans its exact owner');
};

subtest 'state, object, replay, source, and provider mutation fail closed' => sub {
    my $request = fake_request('state-mutation');
    my $begin = lifecycle_begin($request);
    append_raw(repo_path($begin->{handle}{state_relpath}), ' ');
    my $state = lifecycle_advance($request, $begin->{handle});
    ok(!$state->{ok}, 'mutated state bytes reject');
    is($state->{diagnostics}[0]{code},
        'VIAL_GHDL_LIFECYCLE_STATE_ERROR', 'state diagnostic is exact');
    ok($state->{cleanup}{removed}, 'mutated state cleans proven ownership');

    $request = fake_request('object-mutation');
    $begin = lifecycle_begin($request);
    my $record = decode_raw(repo_path($begin->{handle}{state_relpath}));
    append_raw(repo_path($record->{objects}[0]{relative_path}), 'x');
    my $object = lifecycle_advance($request, $begin->{handle});
    ok(!$object->{ok}, 'mutated content object rejects');
    is($object->{diagnostics}[0]{code},
        'VIAL_GHDL_LIFECYCLE_OBJECT_ERROR', 'object diagnostic is exact');
    ok($object->{cleanup}{removed}, 'mutated object cleans proven ownership');

    $request = fake_request('extra-object');
    $begin = lifecycle_begin($request);
    write_raw(repo_path($request->{storage_context}{staging_identity}
        . '/objects/extra'), "extra\n");
    my $extra = lifecycle_advance($request, $begin->{handle});
    ok(!$extra->{ok}, 'extra content object rejects');
    ok($extra->{cleanup}{removed}, 'extra object cleans proven ownership');

    $request = fake_request('replay');
    $begin = lifecycle_begin($request);
    my $prepared = lifecycle_advance($request, $begin->{handle});
    my $replay = lifecycle_advance($request, $begin->{handle});
    ok(!$replay->{ok}, 'stale admitted handle cannot replay');
    is($replay->{diagnostics}[0]{code},
        'VIAL_GHDL_LIFECYCLE_STATE_ERROR', 'replay diagnostic is exact');
    ok($replay->{cleanup}{removed}, 'replay cleans the proven stale chain');

    $request = fake_request('source-mutation');
    $begin = lifecycle_begin($request);
    append_raw(repo_path($request->{source_set}[0]{relpath}), 'x');
    my $source = lifecycle_advance($request, $begin->{handle});
    ok(!$source->{ok}, 'source mutation after admission rejects');
    is($source->{diagnostics}[0]{code},
        'VIAL_GHDL_LIFECYCLE_OBJECT_ERROR', 'source mutation is exact');
    ok($source->{cleanup}{removed}, 'source mutation cleans lifecycle state');

    $request = fake_request('provider-mutation');
    $begin = lifecycle_begin($request);
    append_raw(repo_path($request->{provider}{binary}), "\n");
    chmod 0700, repo_path($request->{provider}{binary});
    my $provider = lifecycle_advance($request, $begin->{handle});
    ok(!$provider->{ok}, 'provider mutation after admission rejects');
    is($provider->{diagnostics}[0]{code},
        'VIAL_GHDL_LIFECYCLE_TOOL_ERROR', 'provider mutation is exact');
    ok($provider->{cleanup}{removed}, 'provider mutation cleans lifecycle state');
};

subtest 'sealed process policy and failure cleanup are phase exact' => sub {
    my $request = fake_request('analysis-failure', 1);
    my $current = lifecycle_begin($request);
    for my $state (qw(prepared tool_verified)) {
        $current = lifecycle_advance($request, $current->{handle});
        diag($json->encode($current->{diagnostics})) unless $current->{ok};
        ok($current->{ok}, "fake provider advances through $state");
        return unless $current->{ok};
    }
    my $capture = $current->{stage_evidence}[-1]{evidence}{capture};
    is($capture->{containment}, 'lifecycle_process_group',
        'qualification process owns one sealed process group');
    is($capture->{timeout_seconds}, 10,
        'version phase retains its exact ten-second deadline');
    is($capture->{capture_limit_bytes}, 65_536,
        'version phase retains its exact 64-KiB capture ceiling');
    ok(defined($capture->{spawn_to_exec_ns})
            && defined($capture->{execution_ns}),
        'process evidence separates spawn/exec and execution time');

    my $failed = lifecycle_advance($request, $current->{handle});
    ok(!$failed->{ok}, 'nonzero GHDL analysis rejects');
    is($failed->{diagnostics}[0]{code},
        'VIAL_GHDL_LIFECYCLE_EXECUTION_ERROR',
        'analysis failure diagnostic is exact');
    ok($failed->{cleanup}{removed}, 'analysis failure removes the exact root');
    ok(!-e repo_path($request->{storage_context}{staging_identity}),
        'analysis failure leaves zero lifecycle residue');
};

subtest 'outer worker owns the distinct measurement containment policy' => sub {
    my $request = measurement_request();
    my $current = measurement_begin($request);
    diag($json->encode($current->{diagnostics})) unless $current->{ok};
    ok($current->{ok}, 'sealed measurement caller admits its exact root');
    for my $state (qw(prepared tool_verified)) {
        $current = measurement_advance($request, $current->{handle});
        diag($json->encode($current->{diagnostics})) unless $current->{ok};
        ok($current->{ok}, "measurement lifecycle advances through $state");
        return unless $current->{ok};
    }
    my $capture = $current->{stage_evidence}[-1]{evidence}{capture};
    is($capture->{containment}, 'outer_worker_process_group',
        'measurement process inherits the independently sealed outer worker');
    my $abort = measurement_abort($request, $current->{handle});
    ok($abort->{ok} && $abort->{cleanup}{removed},
        'measurement caller removes its exact lifecycle root');
};

subtest 'exact provider traverses every state and finishes without residue' => sub {
    my $request = exact_request();
    plan skip_all => 'exact repository-local GHDL provider is absent'
        unless defined($request);
    my @states = @{FSM::VIAL::Backend::GHDLLifecycle->state_order};
    my $current = lifecycle_begin($request);
    diag($json->encode($current->{diagnostics})) unless $current->{ok};
    ok($current->{ok}, 'exact GHDL lifecycle admits');
    for my $ordinal (1 .. $#states - 1) {
        $current = lifecycle_advance($request, $current->{handle});
        diag($json->encode($current->{diagnostics})) unless $current->{ok};
        ok($current->{ok}, "exact lifecycle advances through $states[$ordinal]");
        last unless $current->{ok};
        is($current->{status}, $states[$ordinal],
            'state status is exact');
        is($current->{handle}{ordinal}, $ordinal,
            'state ordinal is exact');
        is(scalar(@{$current->{stage_evidence}}), $ordinal + 1,
            'fresh resume reconstructs every predecessor');
        if ($states[$ordinal] =~ /\A(?:tool_verified|analyzed|elaborated)\z/) {
            my $capture = $current->{stage_evidence}[-1]{evidence}{capture};
            ok($capture->{ok}, 'external phase capture succeeded');
            is($capture->{containment}, 'lifecycle_process_group',
                'external phase remains in the sealed lifecycle group');
        }
        if ($states[$ordinal] eq 'ran') {
            my $evidence = $current->{stage_evidence}[-1]{evidence};
            is(scalar(@{$evidence->{captures}}), 2,
                'qualification retains two exact runtime captures');
            ok($evidence->{deterministic},
                'runtime repetitions are byte-identical');
            is($evidence->{captures}[0]{timeout_seconds}, 30,
                'runtime deadline remains exactly 30 seconds');
            is($evidence->{captures}[0]{capture_limit_bytes}, 67_108_864,
                'runtime capture remains exactly 64 MiB');
        }
    }
    return unless $current->{ok} && $current->{status} eq 'assembled';
    my $finished = lifecycle_finish($request, $current->{handle});
    diag($json->encode($finished->{diagnostics})) unless $finished->{ok};
    ok($finished->{ok}, 'assembled exact lifecycle finishes');
    is($finished->{status}, 'cleaned', 'finish reaches cleaned');
    ok($finished->{cleanup}{removed}, 'finish proves exact cleanup');
    is(scalar(@{$finished->{assembled_result}{runtime_outputs}}), 2,
        'assembled result retains both private runtime repetitions');
    is($finished->{assembled_result}{runtime_outputs}[0],
        $finished->{assembled_result}{runtime_outputs}[1],
        'assembled runtime repetitions remain byte-identical');
    ok(!-e repo_path($request->{storage_context}{staging_identity}),
        'exact finish leaves no staging residue');
};

done_testing();

sub fake_request {
    my ($label, $analysis_failure) = @_;
    remove_tree($fake_root_abs)
        if -d $fake_root_abs && !-l $fake_root_abs;
    my $provider_root = "$fake_root_rel/provider";
    my $binary = "$provider_root/bin/ghdl";
    my $archive = "$provider_root/ghdl.tar.gz";
    my $program_source = "$provider_root/fake-ghdl.c";
    my $source = "$fake_root_rel/source/input.vhd";
    write_raw(repo_path($archive), "fake archive\n");
    write_raw(repo_path($program_source), <<'C');
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
    int index;
    if (argc == 2 && strcmp(argv[1], "--version") == 0) {
        fputs("fake GHDL 1\n", stdout);
        return 0;
    }
    for (index = 1; index < argc; index++) {
        if (strcmp(argv[index], "--fail-analysis") == 0) {
            return 7;
        }
    }
    return 0;
}
C
    my $compiler_tmp = repo_path("$fake_root_rel/compiler-tmp");
    make_path($compiler_tmp);
    make_path(dirname(repo_path($binary)));
    local $ENV{TMPDIR} = $compiler_tmp;
    my @compiler = shellwords($Config::Config{cc} // 'cc');
    system @compiler, repo_path($program_source), '-o', repo_path($binary);
    die "cannot compile native fake provider\n" unless $? == 0;
    chmod 0700, repo_path($binary) or die "cannot chmod fake provider: $!";
    write_raw(repo_path($source), "entity input is end entity;\n");
    my $stage = '.artifacts/tmp/vial-ghdl-qualification/'
        . sha256_hex("fsmgen-ghdl-test-$label-$$");
    push @owned_stage, $stage;
    my $source_set = [{
        relpath => $source,
        bytes => 0 + (-s repo_path($source)),
        sha256 => file_sha256(repo_path($source)),
    }];
    my @analyze = ($binary, '-a', '--std=08', '--work=fsmgen_vial',
        "--workdir=$stage/library");
    push @analyze, '--fail-analysis' if $analysis_failure;
    push @analyze, $source;
    my $authority =
        FSM::VIAL::Backend::VHDLPortableTraceValidator
            ->checked_reference_authority;
    return {
        repo_root => $repo_root,
        provider => {
            root => $provider_root,
            archive => $archive,
            archive_bytes => 0 + (-s repo_path($archive)),
            archive_sha256 => file_sha256(repo_path($archive)),
            binary => $binary,
            binary_sha256 => file_sha256(repo_path($binary)),
            version_output => 'fake GHDL 1',
        },
        source_set => $source_set,
        source_identity => 'source/' . sha256_hex($json->encode($source_set)),
        emission_identity => 'emission/' . sha256_hex("emission-$label-$$"),
        commands => {
            version => [$binary, '--version'],
            analyze => \@analyze,
            elaborate => [$binary, '-e', '--std=08', '--work=fsmgen_vial',
                "--workdir=$stage/library", 'input'],
            run => [$binary, '-r', '--std=08', '--work=fsmgen_vial',
                "--workdir=$stage/library", 'input', '--assert-level=error'],
        },
        validation => {
            expected_record_counts => reference_counts(),
            %$authority,
            run_repetitions => 2,
        },
        storage_context => {
            schema => 'fsmgen.vial_ghdl_lifecycle_storage.v1',
            schema_version => 1,
            mode => 'qualification',
            staging_identity => $stage,
            containment => 'lifecycle_process_group',
        },
    };
}

sub exact_request {
    my $checked = repo_path(
        'vial/qualification/vhdl_portable_ghdl/ghdl-6.0.0-qualification.json',
    );
    return undef unless -f $checked;
    my $report = decode_raw($checked);
    return undef unless -x repo_path($report->{provider}{binary})
        && -f repo_path($report->{provider}{archive});
    my $stage = '.artifacts/tmp/vial-ghdl-qualification/'
        . sha256_hex("fsmgen-ghdl-exact-state-proof-$$");
    push @owned_stage, $stage;
    my @source = map { $_->{relpath} } @{$report->{source_set}};
    my $binary = $report->{provider}{binary};
    my @analyze = ($binary, '-a', '--std=08', '--work=fsmgen_vial',
        "--workdir=$stage/library", @source);
    my @elaborate = ($binary, '-e', '--std=08', '--work=fsmgen_vial',
        "--workdir=$stage/library", 'base_output_arbitration_tb');
    my @run = ($binary, '-r', '--std=08', '--work=fsmgen_vial',
        "--workdir=$stage/library", 'base_output_arbitration_tb',
        '--assert-level=error');
    my $source_identity =
        'source/' . sha256_hex($json->encode($report->{source_set}));
    my $authority =
        FSM::VIAL::Backend::VHDLPortableTraceValidator
            ->checked_reference_authority;
    return {
        repo_root => $repo_root,
        provider => {
            root => $report->{provider}{root},
            archive => $report->{provider}{archive},
            archive_bytes => 0 + $report->{provider}{archive_bytes},
            archive_sha256 => $report->{provider}{archive_sha256},
            binary => $binary,
            binary_sha256 => $report->{provider}{binary_sha256},
            version_output => $report->{tool_profile}{version_output},
        },
        source_set => clone($report->{source_set}),
        source_identity => $source_identity,
        emission_identity => 'emission/' . sha256_hex($json->encode({
            source_identity => $source_identity,
            commands => [\@analyze, \@elaborate, \@run],
        })),
        commands => {
            version => [$binary, '--version'],
            analyze => \@analyze,
            elaborate => \@elaborate,
            run => \@run,
        },
        validation => {
            expected_record_counts => reference_counts(),
            %$authority,
            run_repetitions => 2,
        },
        storage_context => {
            schema => 'fsmgen.vial_ghdl_lifecycle_storage.v1',
            schema_version => 1,
            mode => 'qualification',
            staging_identity => $stage,
            containment => 'lifecycle_process_group',
        },
    };
}

sub measurement_request {
    my $request = fake_request('measurement-policy');
    my $old = $request->{storage_context}{staging_identity};
    my $owner = sha256_hex("fsmgen-ghdl-measurement-policy-$$");
    my $stage = ".artifacts/tmp/vial-scale/$owner/validation/00/lifecycle";
    push @owned_stage, ".artifacts/tmp/vial-scale/$owner";
    for my $command (values %{$request->{commands}}) {
        for my $argument (@$command) {
            $argument =~ s/\Q$old\E/$stage/g;
        }
    }
    $request->{storage_context} = {
        schema => 'fsmgen.vial_ghdl_lifecycle_storage.v1',
        schema_version => 1,
        mode => 'architecture_scale_measurement',
        staging_identity => $stage,
        containment => 'outer_worker_process_group',
    };
    return $request;
}

sub reference_counts {
    return {
        header => 1, scenario_start => 2, events => 2, samples => 35,
        expectations => 2, scoreboards => 2, coverage => 28, faults => 2,
        scenario_end => 2, footer => 1,
    };
}

sub lifecycle_begin {
    return FSM::VIAL::Backend::VHDLPortableGHDLQualification::_ghdl_lifecycle_begin_for_test($_[0]);
}

sub lifecycle_advance {
    my ($request, $handle) = @_;
    return FSM::VIAL::Backend::VHDLPortableGHDLQualification::_ghdl_lifecycle_advance_for_test({
            %$request, handle => clone($handle),
        });
}

sub lifecycle_abort {
    my ($request, $handle) = @_;
    return FSM::VIAL::Backend::VHDLPortableGHDLQualification::_ghdl_lifecycle_abort_for_test({
            %$request, handle => clone($handle),
        });
}

sub lifecycle_finish {
    my ($request, $handle) = @_;
    return FSM::VIAL::Backend::VHDLPortableGHDLQualification::_ghdl_lifecycle_finish_for_test({
            %$request, handle => clone($handle),
        });
}

sub measurement_begin {
    return FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement::_ghdl_lifecycle_begin_for_test($_[0]);
}

sub measurement_advance {
    my ($request, $handle) = @_;
    return FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement::_ghdl_lifecycle_advance_for_test({
        %$request, handle => clone($handle),
    });
}

sub measurement_abort {
    my ($request, $handle) = @_;
    return FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement::_ghdl_lifecycle_abort_for_test({
        %$request, handle => clone($handle),
    });
}

sub repo_path {
    return File::Spec->catfile($repo_root, split m{/}, $_[0]);
}

sub write_raw {
    my ($path, $content) = @_;
    make_path(dirname($path));
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    print {$fh} $content or die "cannot populate $path: $!";
    close $fh or die "cannot close $path: $!";
}

sub append_raw {
    my ($path, $content) = @_;
    open my $fh, '>>:raw', $path or die "cannot append $path: $!";
    print {$fh} $content or die "cannot append content to $path: $!";
    close $fh or die "cannot close $path: $!";
}

sub decode_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $path: $!";
    return JSON::PP->new->decode($text);
}

sub file_sha256 {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot hash $path: $!";
    my $sha = Digest::SHA->new(256);
    $sha->addfile($fh);
    close $fh or die "cannot close $path: $!";
    return $sha->hexdigest;
}

sub clone {
    return JSON::PP->new->decode($json->encode($_[0]));
}

package FSM::VIAL::Backend::VHDLPortableGHDLQualification;

sub _ghdl_lifecycle_begin_for_test {
    return FSM::VIAL::Backend::GHDLLifecycle->begin_session($_[0]);
}

sub _ghdl_lifecycle_advance_for_test {
    return FSM::VIAL::Backend::GHDLLifecycle->advance_session($_[0]);
}

sub _ghdl_lifecycle_abort_for_test {
    return FSM::VIAL::Backend::GHDLLifecycle->abort_session($_[0]);
}

sub _ghdl_lifecycle_finish_for_test {
    return FSM::VIAL::Backend::GHDLLifecycle->finish_session($_[0]);
}

package main;

package FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement;

sub _ghdl_lifecycle_begin_for_test {
    return FSM::VIAL::Backend::GHDLLifecycle->begin_session($_[0]);
}

sub _ghdl_lifecycle_advance_for_test {
    return FSM::VIAL::Backend::GHDLLifecycle->advance_session($_[0]);
}

sub _ghdl_lifecycle_abort_for_test {
    return FSM::VIAL::Backend::GHDLLifecycle->abort_session($_[0]);
}

package main;
