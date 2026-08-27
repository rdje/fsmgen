#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use JSON::PP ();
use POSIX ();
use Test::More;
use Time::HiRes qw(sleep);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleMeasurement;
use FSM::VIAL::ArchitectureScaleWorkload;

my $class = 'FSM::VIAL::ArchitectureScaleMeasurement';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $source = "(vial\n  (version 1)\n)\n";
my $construction = FSM::VIAL::ArchitectureScaleWorkload->construct({
    family => 'semantic_catalog_v1',
    level => 'reference_v1',
    primary_axis => 'imports',
    backend_profile => undef,
    tool_profile => undef,
    inputs => [{
        relative_path => 'source/measurement-foundation.vial',
        role => 'vial_source',
        encoding => 'utf-8',
        content => $source,
    }],
});
my @record_keys = qw(
    schema schema_version measurement_identity workload_identity
    workload_specification git_revision dirty_state host_profile tool_profile
    run_class run_ordinal stage_measurements correctness_oracles resource_guard
    artifacts outcome diagnostic cleanup explicit_nonclaims
);
my @stage_keys = qw(
    stage status worker_status classification not_run_reason timeout wall_time_ns
    controller_cpu descendant_cpu rss input_counts output_counts
    semantic_object_counts command_identity process raw_samples
    unsupported_counters correctness_oracle_ids
);
my @stages = qw(
    construct parse_validate bridge bind_plan emit compile_analyze elaborate
    run trace_validate result_produce publish cleanup
);
my @nonclaims = qw(
    architecture_scale_capacity whole_product_big whole_product_really_big
    multi_unit multi_domain mixed_language native_uvm_runtime full_language
    synthesis general_cross_backend_parity public_performance_budget
);
my $validation;

subtest 'foundation authorities are exact and defensive' => sub {
    ok($construction->{ok}, 'canonical reference workload constructs');
    is_deeply($class->record_keys, \@record_keys,
        'record schema has one closed key authority');
    is_deeply($class->stage_keys, \@stage_keys,
        'stage schema has one closed key authority');
    is_deeply($class->stage_order, \@stages,
        'all twelve normative stages are ordered exactly');
    is($class->sampler_interval_ns, 250_000_000,
        'sampler interval is exactly 250 ms');
    is_deeply($class->explicit_nonclaims, \@nonclaims,
        'foundation carries the complete scale nonclaim boundary');
    is_deeply($class->effective_timeout({
        stage => 'run', backend_timeout_seconds => 30,
    }), {
        outer_seconds => 300,
        backend_seconds => 30,
        effective_seconds => 30,
        authority => 'qualified_backend',
    }, 'smaller qualified timeout dominates the architecture envelope');
    is_deeply($class->effective_timeout({
        stage => 'construct', backend_timeout_seconds => undef,
    }), {
        outer_seconds => 120,
        backend_seconds => undef,
        effective_seconds => 120,
        authority => 'architecture_scale_outer',
    }, 'outer timeout remains authoritative without a stricter backend cap');

    my $defensive = $class->stage_order;
    $defensive->[0] = 'forged';
    is($class->stage_order->[0], 'construct',
        'authority callers receive defensive arrays');
};

subtest 'Linux logical-core discovery follows bounded kernel authorities' => sub {
    my $derive =
        \&FSM::VIAL::ArchitectureScaleMeasurement::_linux_logical_cores_from_text;
    my $cpulist =
        \&FSM::VIAL::ArchitectureScaleMeasurement::_linux_cpu_list_count;
    my $cpuinfo =
        \&FSM::VIAL::ArchitectureScaleMeasurement::_linux_cpuinfo_logical_core_count;

    is($derive->("0-3,8,10-11\n", "127\n", "processor : invalid\n"), 7,
        'stable sysfs online mask is the primary logical-core authority');
    is($derive->("0-3,3-4\n", "127\n", <<'CPUINFO'), 3,
processor : 0
model name : hosted probe
processor : 2
processor : 7
CPUINFO
        'malformed sysfs data falls back to distinct procfs processor IDs');
    is($derive->(undef, undef, "processor : 4\n"), 1,
        'procfs remains an independent fallback when sysfs is unavailable');
    ok(!defined($derive->(undef, undef, undef)),
        'missing kernel authorities fail closed');

    is($cpulist->("0\n", "0\n"), 1,
        'single online CPU and zero kernel maximum are valid');
    for my $case (
        ['', '127'],
        ['0,,1', '127'],
        ['0-3,3-4', '127'],
        ['3-1', '127'],
        ['2,0', '127'],
        ['0-3', '2'],
        ['0-1', '2147483648'],
        ['00', '127'],
    ) {
        ok(!defined($cpulist->($case->[0] . "\n", $case->[1] . "\n")),
            "hostile cpulist '$case->[0]' with kernel max '$case->[1]' rejects");
    }
    is($cpuinfo->("processor : 1\nprocessor : 9\n"), 2,
        'procfs fallback counts distinct non-contiguous processor IDs');
    ok(!defined($cpuinfo->("processor : 1\nprocessor : 1\n")),
        'duplicate procfs processor identity rejects');
    ok(!defined($cpuinfo->("processor : unknown\n")),
        'malformed procfs processor identity rejects');
    ok(!defined($cpuinfo->("model name : no processor record\n")),
        'procfs content without processor records rejects');
};

subtest 'a validated interrupted stage is recovered under exact ownership' => sub {
    my $stage_relative = validation_stage_relative($construction);
    my $stage_root = repo_path($stage_relative);
    make_path(File::Spec->catdir($stage_root, 'outputs', 'construct'));
    write_raw(
        File::Spec->catfile(
            $stage_root, 'outputs', 'construct', 'interrupted.txt',
        ),
        "interrupted before controller cleanup\n",
    );

    my $recovered = eval {
        $class->measure({
            repository_root => $repo_root,
            construction => $construction,
            run_class => 'validation',
            run_ordinal => 0,
            validation_record => undef,
            stage_plan => [construct_plan(delay_seconds => 0)],
        });
    };
    my $error = "$@";
    cleanup_stage_fixture($stage_relative) unless defined $recovered;
    ok(defined($recovered),
        'a regular controller-owned orphan is reclaimed before a fresh run')
        or diag($error);
    if (defined $recovered) {
        is($recovered->{outcome}, 'accepted',
            'the replacement run retains ordinary accepted evidence');
        ok(!-e $stage_root,
            'replacement-run cleanup removes the exact recovered identity');
    }

    my $pid = fork();
    die "cannot fork concurrent measurement probe\n" unless defined $pid;
    if ($pid == 0) {
        my $record = eval {
            $class->measure({
                repository_root => $repo_root,
                construction => $construction,
                run_class => 'validation',
                run_ordinal => 0,
                validation_record => undef,
                stage_plan => [construct_plan(delay_seconds => 2)],
            });
        };
        POSIX::_exit(
            defined($record) && $record->{outcome} eq 'accepted' ? 0 : 1,
        );
    }
    for (1 .. 200) {
        last if -d $stage_root;
        sleep(0.01);
    }
    ok(-d $stage_root, 'concurrent owner reaches its exact staging identity');
    like(dies(sub {
        $class->measure({
            repository_root => $repo_root,
            construction => $construction,
            run_class => 'validation',
            run_ordinal => 0,
            validation_record => undef,
            stage_plan => [construct_plan(delay_seconds => 0)],
        });
    }), qr/measurement staging identity is concurrently owned/,
        'a live owner rejects a second controller without reclamation');
    ok(-d $stage_root,
        'concurrent-owner rejection leaves the active tree untouched');
    waitpid($pid, 0);
    is($?, 0, 'the original concurrent owner completes normally');
    ok(!-e $stage_root,
        'the original owner removes its staging identity');

    make_path($stage_root);
    my $regular = File::Spec->catfile($stage_root, 'regular.txt');
    write_raw($regular, "regular\n");
    my $symlink = File::Spec->catfile($stage_root, 'unsafe-link');
    symlink('regular.txt', $symlink)
        or die "cannot create recovery symlink probe: $!";
    like(dies(sub { validation_probe() }),
        qr/interrupted measurement staging contains an unsafe entry/,
        'symlink-bearing orphan rejects before reclamation');
    ok(-l $symlink && -f $regular,
        'symlink rejection leaves every ambiguous entry in place');
    cleanup_stage_fixture($stage_relative);

    make_path($stage_root);
    my $fifo = File::Spec->catfile($stage_root, 'unsafe-fifo');
    POSIX::mkfifo($fifo, 0600)
        or die "cannot create recovery FIFO probe: $!";
    like(dies(sub { validation_probe() }),
        qr/interrupted measurement staging contains an unsafe entry/,
        'special-file orphan rejects before reclamation');
    ok(-p $fifo,
        'special-file rejection leaves the ambiguous FIFO in place');
    cleanup_stage_fixture($stage_relative);

    make_path($stage_root);
    my $original = File::Spec->catfile($stage_root, 'original.txt');
    my $hard_link = File::Spec->catfile($stage_root, 'hard-link.txt');
    write_raw($original, "hard-linked\n");
    link($original, $hard_link)
        or die "cannot create recovery hard-link probe: $!";
    like(dies(sub { validation_probe() }),
        qr/interrupted measurement staging contains a hard-linked file/,
        'hard-linked orphan rejects before reclamation');
    ok(-f $original && -f $hard_link,
        'hard-link rejection leaves both ambiguous names in place');
    cleanup_stage_fixture($stage_relative);

    my $lock_path = stage_lock_path($stage_relative);
    my $lock_target = File::Spec->catfile(
        dirname($lock_path), 'unsafe-lock-target',
    );
    unlink($lock_path)
        or die "cannot replace recovery lock probe: $!";
    write_raw($lock_target, "not a lock\n");
    symlink('unsafe-lock-target', $lock_path)
        or die "cannot create recovery lock symlink probe: $!";
    like(dies(sub { validation_probe() }),
        qr/(?:cannot open measurement stage lock|measurement stage lock identity is invalid)/,
        'a symlink cannot substitute for the exact lock inode');
    ok(-l $lock_path && -f $lock_target,
        'invalid lock identity rejects without touching either path');
    unlink($lock_path)
        or die "cannot remove recovery lock symlink probe: $!";
    unlink($lock_target)
        or die "cannot remove recovery lock target probe: $!";
};

subtest 'validation executes correctness without retaining performance' => sub {
    $validation = $class->measure({
        repository_root => $repo_root,
        construction => $construction,
        run_class => 'validation',
        run_ordinal => 0,
        validation_record => undef,
        stage_plan => [
            construct_plan(delay_seconds => 0),
            parse_validate_plan(delay_seconds => 0),
        ],
    });
    is_deeply([sort keys %$validation], [sort @record_keys],
        'validation record schema is closed');
    is($validation->{schema},
        'fsmgen.vial_architecture_scale_measurement.v1',
        'record uses the selected revision-1 schema');
    like($validation->{measurement_identity},
        qr{\Ameasurement/[0-9a-f]{64}\z},
        'complete validation record is content-addressed');
    is($validation->{workload_identity}, $construction->{workload_identity},
        'canonical workload identity is preserved');
    is($validation->{run_class}, 'validation',
        'validation class is explicit');
    is($validation->{run_ordinal}, 0,
        'validation has the unique zero ordinal');
    is($validation->{outcome}, 'accepted',
        'stage-local validation correctness succeeds');
    is_deeply([map { $_->{stage} } @{$validation->{stage_measurements}}],
        \@stages, 'record contains every normative stage in order');
    is($validation->{stage_measurements}[0]{status},
        'validated_unmeasured', 'construct correctness runs unmeasured');
    is($validation->{stage_measurements}[1]{status},
        'validated_unmeasured',
        'a second stage uses its independently owned output root');
    is(scalar(@{$validation->{artifacts}{records}}), 2,
        'whole-staging census retains both stage-partitioned artifacts');
    ok(!defined($validation->{stage_measurements}[0]{wall_time_ns}),
        'validation retains no wall-time sample');
    is_deeply($validation->{stage_measurements}[0]{raw_samples}, [],
        'validation retains no raw resource sample');
    is($validation->{stage_measurements}[-1]{status},
        'validated_unmeasured', 'controller cleanup is also unmeasured');
    ok($validation->{cleanup}{ephemeral_removed},
        'validation removes its exact owned staging root');
    ok(!-e repo_path($validation->{cleanup}{staging_identity}),
        'validation staging is absent after return');
    is_deeply($validation->{explicit_nonclaims}, \@nonclaims,
        'validation does not create a product or capacity claim');
    is($json->encode($class->validate_record({record => $validation})),
        $json->encode($validation),
        'closed validation accepts and returns defensive canonical evidence');

    my $mutated = clone($validation);
    $mutated->{stage_measurements}[0]{status} = 'measured';
    like(dies(sub { $class->validate_record({record => $mutated}) }),
        qr/(?:validation stage has a measured status|validation stage retained performance|measured stage has no wall|measurement identity changed)/,
        'mutated validation evidence fails closed');

    my $forged_timeout = clone($validation);
    $forged_timeout->{stage_measurements}[0]{timeout}{effective_seconds}++;
    like(dies(sub {
        $class->validate_record({record => $forged_timeout});
    }), qr/timeout authority changed/,
        'a forged effective timeout fails before identity comparison');

    my $forged_artifact = clone($validation);
    $forged_artifact->{artifacts}{records}[0]{relative_path} =
        '/machine-local/forged.txt';
    like(dies(sub {
        $class->validate_record({record => $forged_artifact});
    }), qr/path is unsafe or misowned/,
        'a machine-local artifact identity fails closed');
};

subtest 'guard, ordinal, ordering, and external admission fail closed' => sub {
    local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    like(dies(sub {
        $class->measure({
            repository_root => $repo_root,
            construction => $construction,
            run_class => 'gate_measurement',
            run_ordinal => 1,
            validation_record => $validation,
            stage_plan => [construct_plan(delay_seconds => 0)],
        });
    }), qr/active repository RAM guard/,
        'a measured run cannot start outside active safety enforcement');

    like(dies(sub {
        $class->measure({
            repository_root => $repo_root,
            construction => $construction,
            run_class => 'gate_measurement',
            run_ordinal => 4,
            validation_record => $validation,
            stage_plan => [construct_plan(delay_seconds => 0)],
        });
    }), qr/outside the selected repetition contract/,
        'fourth gate sample is outside the selected three-run contract');
    like(dies(sub {
        $class->measure({
            repository_root => $repo_root,
            construction => $construction,
            run_class => 'qualification_measurement',
            run_ordinal => 6,
            validation_record => $validation,
            stage_plan => [construct_plan(delay_seconds => 0)],
        });
    }), qr/outside the selected repetition contract/,
        'sixth qualification sample is outside the selected five-run contract');

    my $external = construct_plan(delay_seconds => 0);
    $external->{classification} = 'external_tool';
    like(dies(sub {
        $class->measure({
            repository_root => $repo_root,
            construction => $construction,
            run_class => 'validation',
            run_ordinal => 0,
            validation_record => undef,
            stage_plan => [$external],
        });
    }), qr/external-tool stage admission is not implemented/,
        'foundation cannot borrow later external-tool admission');

    my $later = construct_plan(delay_seconds => 0);
    $later->{stage} = 'emit';
    like(dies(sub {
        $class->measure({
            repository_root => $repo_root,
            construction => $construction,
            run_class => 'validation',
            run_ordinal => 0,
            validation_record => undef,
            stage_plan => [$later, construct_plan(delay_seconds => 0)],
        });
    }), qr/normative stage order/,
        'out-of-order stage plans reject before a worker starts');

    my $unreported = $class->measure({
        repository_root => $repo_root,
        construction => $construction,
        run_class => 'validation',
        run_ordinal => 0,
        validation_record => undef,
        stage_plan => [unreported_artifact_plan()],
    });
    is($unreported->{outcome}, 'stage_failure',
        'unreported stage output fails the validation run');
    is($unreported->{diagnostic}{code},
        'VIAL_SCALE_MEASUREMENT_RESULT_VALIDATION_ERROR',
        'unreported output uses one stable result-validation diagnostic');
    ok($unreported->{cleanup}{ephemeral_removed}
            && !-e repo_path($unreported->{cleanup}{staging_identity}),
        'unreported output is still removed exactly');
    $class->validate_record({record => $unreported});
};

subtest 'guarded sampling, failure cleanup, and publication are exact' => sub {
    plan skip_all =>
        'set FSMGEN_VIAL_SCALE_MEASUREMENT_EXACT=1 under scripts/run_with_ram_guard.sh'
        unless $ENV{FSMGEN_VIAL_SCALE_MEASUREMENT_EXACT};
    is($ENV{FSMGEN_RAM_GUARD_ACTIVE}, 1,
        'exact measurement runs below the active repository guard');

    my $measured = $class->measure({
        repository_root => $repo_root,
        construction => $construction,
        run_class => 'gate_measurement',
        run_ordinal => 1,
        validation_record => $validation,
        stage_plan => [
            construct_plan(delay_seconds => 0.36),
            parse_validate_plan(delay_seconds => 0),
        ],
    });
    is($measured->{outcome}, 'accepted',
        'guarded measured stage passes correctness first');
    is($measured->{workload_identity}, $validation->{workload_identity},
        'volatile measurements and run ordinal do not enter workload identity');
    isnt($measured->{measurement_identity}, $validation->{measurement_identity},
        'complete record identity still distinguishes measured evidence');
    is($measured->{correctness_oracles}[0]{evidence_identity},
        $validation->{correctness_oracles}[0]{evidence_identity},
        'volatile measurements do not enter semantic oracle identity');
    ok($measured->{resource_guard}{active},
        'record binds active safety enforcement');
    is($measured->{resource_guard}{host_max_percent}, 88,
        'record retains exact host threshold');
    is($measured->{resource_guard}{single_descendant_max_mib}, 4096,
        'record retains exact descendant threshold');
    my $construct = $measured->{stage_measurements}[0];
    is($construct->{status}, 'measured',
        'construct stage retains measured evidence');
    ok($construct->{wall_time_ns} >= 250_000_000,
        'monotonic wall sample observes the delayed worker');
    cmp_ok(scalar(@{$construct->{raw_samples}}), '>=', 2,
        '250-ms sampler retains repeated raw process-tree observations');
    is_deeply(
        [map { $_->{ordinal} } @{$construct->{raw_samples}}],
        [0 .. $#{$construct->{raw_samples}}],
        'raw sample ordinals are complete and contiguous',
    );
    ok(!defined($construct->{rss}{unsupported_reason}),
        'supported Darwin/Linux exact host provides real RSS counters');
    cmp_ok($construct->{rss}{peak_process_tree_bytes}, '>', 0,
        'summed process-tree RSS is positive');
    cmp_ok($construct->{rss}{peak_single_descendant_bytes}, '>', 0,
        'single-descendant RSS is positive');
    is_deeply($construct->{output_counts}, {
        files => 1,
        lines => 1,
        bytes => bytes::length("foundation measurement output\n"),
        objects => 1,
    }, 'deterministic output file/line/byte/object counts are exact');
    is_deeply($construct->{semantic_object_counts}, {
        foundation_construct_records => 1,
    }, 'semantic object counts stay stage-local');
    is($measured->{stage_measurements}[1]{status}, 'measured',
        'second stage is measured independently after the delayed stage');
    is(scalar(@{$measured->{artifacts}{records}}), 2,
        'aggregate census accepts exactly both stage-owned files');
    ok($measured->{cleanup}{ephemeral_removed}
            && !-e repo_path($measured->{cleanup}{staging_identity}),
        'guarded success leaves no ephemeral staging residue');
    is($json->encode($class->validate_record({record => $measured})),
        $json->encode($measured),
        'complete raw measured record validates canonically');

    my $failed = $class->measure({
        repository_root => $repo_root,
        construction => $construction,
        run_class => 'gate_measurement',
        run_ordinal => 2,
        validation_record => $validation,
        stage_plan => [failure_plan()],
    });
    is($failed->{outcome}, 'stage_failure',
        'worker exception remains a failed measured outcome');
    is($failed->{diagnostic}{code},
        'VIAL_SCALE_MEASUREMENT_WORKER_ERROR',
        'worker failure uses one stable diagnostic family');
    unlike($json->encode($failed), qr{\Q$repo_root\E},
        'failed record redacts the machine-local repository path');
    ok($failed->{cleanup}{ephemeral_removed}
            && !-e repo_path($failed->{cleanup}{staging_identity}),
        'guarded failure also removes exact staging');
    $class->validate_record({record => $failed});

    my $timed_out = $class->measure({
        repository_root => $repo_root,
        construction => $construction,
        run_class => 'gate_measurement',
        run_ordinal => 3,
        validation_record => $validation,
        stage_plan => [construct_plan(
            delay_seconds => 2,
            backend_timeout_seconds => 1,
        )],
    });
    is($timed_out->{outcome}, 'stage_failure',
        'effective smaller-of timeout rejects the measured run');
    is($timed_out->{diagnostic}{code},
        'VIAL_SCALE_MEASUREMENT_TIMEOUT',
        'timeout uses one stable diagnostic family');
    ok($timed_out->{stage_measurements}[0]{process}{timed_out},
        'stage process record retains the timeout result');
    is($timed_out->{stage_measurements}[0]{timeout}{authority},
        'qualified_backend',
        'the stricter backend timeout remains authoritative');
    ok($timed_out->{cleanup}{ephemeral_removed}
            && !-e repo_path($timed_out->{cleanup}{staging_identity}),
        'timeout termination leaves no operation-owned residue');
    $class->validate_record({record => $timed_out});

    my $profile = 'foundation-probe-' . substr(
        $measured->{measurement_identity}, -12,
    );
    cleanup_publication($profile);
    my $publication_base = repo_path(
        '.artifacts', 'qualification', 'vial-scale',
    );
    my $publication_base_preexisting =
        -d $publication_base && !-l $publication_base;
    like(dies(sub {
        $class->publish_record({
            repository_root => $repo_root,
            contract_version => 'v1',
            profile_id => "$profile-validation",
            record => $validation,
        });
    }), qr/accepted measured record/,
        'unmeasured validation evidence cannot be published as qualification');
    my $rollback_profile = "$profile-rollback";
    cleanup_publication($rollback_profile);
    my $rollback;
    {
        no warnings 'redefine';
        local *FSM::VIAL::ArchitectureScaleMeasurement::_atomic_publish = sub {
            die "intentional atomic publication failure\n";
        };
        $rollback = $class->publish_record({
            repository_root => $repo_root,
            contract_version => 'v1',
            profile_id => $rollback_profile,
            record => $measured,
        });
    }
    ok(!$rollback->{ok} && $rollback->{same_volume}
            && !$rollback->{atomic},
        'injected same-volume atomic publication failure is rejected exactly');
    is($rollback->{diagnostics}[0]{code},
        'VIAL_SCALE_MEASUREMENT_PUBLICATION_ERROR',
        'atomic publication failure has one stable diagnostic');
    ok(!-e repo_path($rollback->{publication_identity})
            && ($publication_base_preexisting
                ? -d $publication_base && !-l $publication_base
                : !-e $publication_base),
        'publication failure rolls back only its target and new parents');
    my $published = $class->publish_record({
        repository_root => $repo_root,
        contract_version => 'v1',
        profile_id => $profile,
        record => $measured,
    });
    ok($published->{ok} && $published->{atomic}
            && $published->{same_volume},
        'first publication is atomic on the repository volume');
    is($published->{status}, 'published',
        'first publication creates the exact qualification tree');
    ok(-f repo_path($published->{artifact_relative_path}),
        'published canonical record exists at its relative identity');
    is(slurp_raw(repo_path($published->{artifact_relative_path})),
        $json->encode($measured) . "\n",
        'published bytes are exact canonical record bytes');
    my $unchanged = $class->publish_record({
        repository_root => $repo_root,
        contract_version => 'v1',
        profile_id => $profile,
        record => $measured,
    });
    is($unchanged->{status}, 'unchanged',
        'byte-identical republication does not rewrite evidence');
    append_raw(repo_path($published->{artifact_relative_path}), "changed\n");
    my $collision = $class->publish_record({
        repository_root => $repo_root,
        contract_version => 'v1',
        profile_id => $profile,
        record => $measured,
    });
    ok(!$collision->{ok}, 'byte-different republication fails closed');
    is($collision->{diagnostics}[0]{code},
        'VIAL_SCALE_MEASUREMENT_PUBLICATION_COLLISION',
        'publication collision has one stable diagnostic');
    cleanup_publication($profile);
    ok(!-e repo_path('.artifacts', 'tmp', 'vial-scale'),
        'publication success and collision leave no scale staging residue');
};

done_testing();

sub construct_plan {
    my (%args) = @_;
    return probe_plan('construct', %args);
}

sub parse_validate_plan {
    my (%args) = @_;
    return probe_plan('parse_validate', %args);
}

sub probe_plan {
    my ($stage, %args) = @_;
    my $content = $stage eq 'construct'
        ? "foundation measurement output\n"
        : "foundation parse validation output\n";
    return {
        stage => $stage,
        classification => 'fsmgen_owned',
        command_identity => {
            logical_name => "foundation_${stage}_probe",
            arguments => [],
            thread_count => 1,
            job_count => 1,
        },
        input_counts => {
            files => 1,
            lines => 3,
            bytes => bytes::length($source),
            objects => 1,
        },
        backend_timeout_seconds => $args{backend_timeout_seconds},
        worker => sub {
            my ($context) = @_;
            sleep($args{delay_seconds}) if $args{delay_seconds};
            make_path($context->{output_root});
            my $path = File::Spec->catfile(
                $context->{output_root}, "$stage.txt",
            );
            write_raw($path, $content);
            return {
                ok => JSON::PP::true,
                status => "foundation_${stage}_completed",
                output_counts => {
                    files => 1,
                    lines => 1,
                    bytes => bytes::length($content),
                    objects => 1,
                },
                semantic_object_counts => {
                    "foundation_${stage}_records" => 1,
                },
                correctness_oracles => [{
                    oracle_id => "foundation_${stage}_content_exact",
                    ok => JSON::PP::true,
                    evidence => {
                        bytes => bytes::length($content),
                        sha256 => sha256_hex($content),
                    },
                }],
                artifacts => [{
                    relative_path => "$context->{output_identity}/$stage.txt",
                    kind => 'foundation_probe',
                    bytes => bytes::length($content),
                    lines => 1,
                    sha256 => sha256_hex($content),
                }],
                diagnostic => undef,
            };
        },
    };
}

sub failure_plan {
    return {
        stage => 'construct',
        classification => 'fsmgen_owned',
        command_identity => {
            logical_name => 'foundation_failure_probe',
            arguments => [],
            thread_count => 1,
            job_count => 1,
        },
        input_counts => {
            files => 1,
            lines => 3,
            bytes => bytes::length($source),
            objects => 1,
        },
        backend_timeout_seconds => undef,
        worker => sub {
            die "intentional measurement failure at $repo_root/private\n";
        },
    };
}

sub unreported_artifact_plan {
    my $plan = construct_plan(delay_seconds => 0);
    $plan->{worker} = sub {
        my ($context) = @_;
        make_path($context->{output_root});
        write_raw(
            File::Spec->catfile($context->{output_root}, 'unreported.txt'),
            "unreported\n",
        );
        return {
            ok => JSON::PP::true,
            status => 'foundation_unreported_probe_completed',
            output_counts => {
                files => 0, lines => 0, bytes => 0, objects => 0,
            },
            semantic_object_counts => {},
            correctness_oracles => [{
                oracle_id => 'foundation_unreported_probe_reached',
                ok => JSON::PP::true,
                evidence => {worker_completed => JSON::PP::true},
            }],
            artifacts => [],
            diagnostic => undef,
        };
    };
    return $plan;
}

sub cleanup_publication {
    my ($profile) = @_;
    my $target = repo_path(
        qw(.artifacts qualification vial-scale v1), $profile,
    );
    remove_tree($target) if -d $target && !-l $target;
    for my $parts (
        [qw(.artifacts qualification vial-scale v1)],
        [qw(.artifacts qualification vial-scale)],
        [qw(.artifacts qualification)],
    ) {
        my $path = repo_path(@$parts);
        rmdir $path if -d $path && !-l $path;
    }
}

sub validation_stage_relative {
    my ($value) = @_;
    my ($digest) = $value->{workload_identity}
        =~ m{\Aworkload/([0-9a-f]{64})\z};
    die "test construction has no workload digest\n" unless defined $digest;
    return ".artifacts/tmp/vial-scale/$digest/validation/00";
}

sub stage_lock_path {
    my ($stage_relative) = @_;
    return repo_path(
        '.artifacts', 'locks', 'vial-scale-measurement',
        sha256_hex($stage_relative) . '.lock',
    );
}

sub cleanup_stage_fixture {
    my ($relative) = @_;
    my $path = repo_path($relative);
    remove_tree($path) if -d $path && !-l $path;
    my @parts = split m{/}, $relative;
    pop @parts;
    while (@parts >= 2) {
        my $parent = repo_path(@parts);
        rmdir $parent if -d $parent && !-l $parent;
        pop @parts;
    }
}

sub validation_probe {
    return $class->measure({
        repository_root => $repo_root,
        construction => $construction,
        run_class => 'validation',
        run_ordinal => 0,
        validation_record => undef,
        stage_plan => [construct_plan(delay_seconds => 0)],
    });
}

sub repo_path {
    my (@parts) = @_;
    if (@parts == 1 && $parts[0] =~ m{/}) {
        @parts = split m{/}, $parts[0];
    }
    return File::Spec->catfile($repo_root, @parts);
}

sub write_raw {
    my ($path, $content) = @_;
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    print {$fh} $content;
    close $fh or die "cannot close $path: $!";
}

sub append_raw {
    my ($path, $content) = @_;
    open my $fh, '>>:raw', $path or die "cannot append $path: $!";
    print {$fh} $content;
    close $fh or die "cannot close $path: $!";
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "cannot close $path: $!";
    return $content;
}

sub dies {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? '' : "$@";
}

sub clone {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}
