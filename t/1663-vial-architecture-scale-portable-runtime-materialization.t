#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScalePortableRuntimeMaterialization;
use FSM::VIAL::ArchitectureScaleRuntimeStream;
use FSM::VIAL::Tool qw(execute_vial_tool_request);

my $class = 'FSM::VIAL::ArchitectureScalePortableRuntimeMaterialization';
my $runtime = 'FSM::VIAL::ArchitectureScaleRuntimeStream';
my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $json = JSON::PP->new->canonical(1);
my $mirror_rel = ".artifacts/test/vial-portable-runtime-materialization-$$";
my $mirror_root = repo_path(split m{/}, $mirror_rel);
my @levels = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1
    limit_v1 over_limit_v1
);
my %expected = (
    reference_v1 => {
        status => 'structurally_qualified', records => 274,
        operations => 21, maps => 39, graph => undef,
        source => 'vial/ahb_subordinate_base_output_arbitration.vial',
        source_sha =>
            '2205b3b4f073a61374b19cb72f06afe31d75fc4d88f903c414b9b28a744ca4cd',
        report =>
            'portable-runtime-materialization/93e838cf670f5d2478f1e026b10024346f6e0e5cc1856488c770eeaa9cec16ec',
    },
    gate_candidate_v1 => {
        status => 'structurally_qualified', records => 10_000,
        operations => 22, maps => 40, graph => 32_098_531, artifacts => 19,
        source =>
            'vial/qualification/sv_portable_verilator_runtime_gate.vial',
        source_sha =>
            'f9a6a3f563b8f58e694ccd2a9e82b50e4866ac9c794b3aef363e7f2251518475',
        report =>
            'portable-runtime-materialization/cc7ce6f4e22dfbfa9d8a995f4734b871a347449b4116e6673b3b1920553715c7',
    },
    qualification_candidate_v1 => {
        status => 'structurally_qualified', records => 15_000,
        operations => 22, maps => 40, graph => 47_505_049, artifacts => 19,
        source =>
            'vial/qualification/sv_portable_verilator_runtime_qualification.vial',
        source_sha =>
            '569f9adbffd9aab214b09fab2ed8c9b4731e14b3c17781e1e75195e7a92275fa',
        report =>
            'portable-runtime-materialization/96077d58d3a1fc3d52e9cdfca43ca9f3fa28cb77ef9d1ae80237afd5c790d760',
    },
    limit_v1 => {
        status => 'preflight_dominated', records => 8_000_002,
        report =>
            'portable-runtime-materialization/2bbadc10bbd103fec1211de1f09ad3fa70e8374d1721e59f5c7e3842aceaef61',
    },
    over_limit_v1 => {
        status => 'preflight_dominated', records => 8_000_003,
        report =>
            'portable-runtime-materialization/b13d91f2e2054f006c6ef997756b323fc74164552e957eaeba99b84e6e2cae3b',
    },
);
my %record_family = (
    gate_candidate_v1 => {
        coverage => 1_982, drives => 16, events => 36,
        expectations => 11, faults => 3, fibers => 8, footer => 1,
        header => 1, models => 4, samples => 7_928,
        scenario_end => 2, scenario_start => 2, scoreboards => 4,
        transactions => 2,
    },
    qualification_candidate_v1 => {
        coverage => 2_982, drives => 16, events => 36,
        expectations => 11, faults => 3, fibers => 8, footer => 1,
        header => 1, models => 4, samples => 11_928,
        scenario_end => 2, scenario_start => 2, scoreboards => 4,
        transactions => 2,
    },
);
my %report;

END {
    remove_tree($mirror_root)
        if defined($mirror_root) && -d $mirror_root && !-l $mirror_root;
}

subtest 'portable ownership and candidate override preserve sibling roles' => sub {
    is_deeply($class->owned_shapes, [map {{
        backend_profile => 'sv_portable_verilator', level => $_,
    }} @levels], 'materializer owns exactly the five portable runtime roles');

    my $hial = slurp_raw(repo_path('ppif', 'ahb_lite_subordinate.ppif'));
    my $vial = slurp_raw(repo_path(
        'vial', 'ahb_subordinate_base_output_arbitration.vial'));
    for my $profile (qw(
        sv_portable_verilator vhdl_portable_ghdl vhdl_osvvm_qualified
    )) {
        my $construction = $runtime->construct({
            backend_profile => $profile,
            level => 'qualification_candidate_v1',
            reference_hial_text => $hial,
            reference_vial_text => $vial,
        });
        is(
            $construction->{specification}{requested_counts}
                {semantic_trace_records},
            $profile eq 'sv_portable_verilator' ? 15_000 : 100_000,
            "$profile retains its independently owned qualification count",
        );
    }
};

subtest 'all five levels reconstruct exact structural evidence' => sub {
    for my $level (@levels) {
        my $first = $class->evaluate({
            repository_root => $repo_root, level => $level,
        });
        my $second = $class->evaluate({
            repository_root => $repo_root, level => $level,
        });
        ok($first->{ok}, "$level is an accepted qualification outcome");
        is($json->encode($second), $json->encode($first),
            "$level evaluation is byte-identical");
        is_deeply([sort keys %$first], [sort @{$class->report_keys}],
            "$level report schema is closed");
        is($first->{status}, $expected{$level}{status},
            "$level status is exact");
        is($first->{family}, 'runtime_stream_v1',
            "$level retains the stable runtime family");
        is($first->{backend_profile}, 'sv_portable_verilator',
            "$level is portable-SystemVerilog only");
        is($first->{trace_projection}{record_count},
            $expected{$level}{records}, "$level record projection is exact");
        is($first->{report_identity}, $expected{$level}{report},
            "$level content identity is frozen");
        ok(!$first->{claims}{external_tool_executed}
                && !$first->{claims}{runtime_executed}
                && !$first->{claims}{trace_materialized}
                && !$first->{claims}{result_produced}
                && !$first->{claims}{support_claimed}
                && !$first->{claims}{performance_claimed}
                && !$first->{claims}{capacity_claimed}
                && !$first->{claims}{reached_record_boundary}
                && !$first->{claims}{public_api_changed},
            "$level preserves every runtime/product nonclaim");
        is_deeply($first->{cleanup}{residue}, [],
            "$level leaves no structural-evaluation residue");

        if ($level =~ /\A(?:limit|over_limit)_v1\z/) {
            ok($first->{claims}{preflight_dominance_proved},
                "$level is rejected by preflight authority");
            ok(!$first->{claims}{ordinary_route_reconstructed}
                    && !$first->{claims}{schedule_materialized},
                "$level creates neither route nor schedule");
            is($first->{graph_projection}{status}, 'preflight_dominated',
                "$level cannot start an external tool");
            is($first->{trace_projection}{derivation}
                    {minimum_structural_trace_bytes},
                $level eq 'limit_v1' ? 67_108_864 : 67_108_865,
                "$level retains its minimum truthful byte representation");
        }
        else {
            is($first->{source_identity}{relative_path},
                $expected{$level}{source}, "$level source path is tracked");
            is($first->{source_identity}{sha256},
                $expected{$level}{source_sha}, "$level source identity is exact");
            is($first->{schedule_oracle}{operation_count},
                $expected{$level}{operations}, "$level operation count is exact");
            is($first->{schedule_oracle}{source_map_count},
                $expected{$level}{maps}, "$level source-map count is exact");
            ok($first->{structural_equivalence}
                    {only_selected_source_deltas}
                    && $first->{structural_equivalence}
                        {execution_topology_preserved}
                    && $first->{structural_equivalence}
                        {source_map_topology_preserved},
                "$level closes source, ExecutionIR, and source-map equivalence");
            ok($first->{emission_oracle}{byte_equal_rerun},
                "$level emission is byte-identical");
            like($first->{emission_oracle}{generated_reset_loop},
                qr{\Arepeat \([0-9]+\) vial_inactive_barrier\(\);\z},
                "$level binds its authored reset to one generated loop");
        }

        if (exists $record_family{$level}) {
            is_deeply($first->{trace_projection}{record_families},
                $record_family{$level},
                "$level projects every exact semantic record family");
            is($first->{graph_projection}{expected_full_graph_bytes},
                $expected{$level}{graph},
                "$level binds the final tracked full-graph observation");
            is($first->{graph_projection}{status}, 'admitted',
                "$level satisfies the headroom admission rule");
        }
        $report{$level} = $first;
    }

    is($report{qualification_candidate_v1}{graph_projection}
            {qualification_admission_ceiling_bytes}, 50_331_648,
        'qualification admission ceiling is exactly three quarters of the public cap');
    is($report{qualification_candidate_v1}{graph_projection}
            {admission_headroom_bytes}, 2_826_599,
        'final tracked 15,000 graph retains exact admission headroom');
    is($report{qualification_candidate_v1}{graph_projection}
            {hard_cap_headroom_bytes}, 19_603_815,
        'final tracked 15,000 graph retains exact hard-cap headroom');
    is_deeply(
        [map { [$_->{records}, $_->{classification},
            0 + $_->{external_tool_eligible}] }
            @{$report{qualification_candidate_v1}{dominance}}],
        [
            [20_000, 'qualification_headroom_rule_rejected', 0],
            [25_000, 'public_artifact_cap_rejected', 0],
            [100_000, 'runtime_capture_rejected', 0],
        ],
        '20,000/25,000/100,000 falsifiers remain tool-free and honestly classified',
    );
};

subtest 'reports, private route, and repository sources fail closed' => sub {
    my $validated = $class->validate_report({
        repository_root => $repo_root,
        report => $report{gate_candidate_v1},
    });
    is($json->encode($validated),
        $json->encode($report{gate_candidate_v1}),
        'canonical report validates defensively');
    $validated->{trace_projection}{record_count} = 9_999;
    is($report{gate_candidate_v1}{trace_projection}{record_count}, 10_000,
        'validated mutation cannot alter stored evidence');

    my $mutated = clone($report{qualification_candidate_v1});
    $mutated->{claims}{runtime_executed} = JSON::PP::true;
    eval {
        $class->validate_report({
            repository_root => $repo_root, report => $mutated,
        });
    };
    like($@, qr/report is not canonical/,
        'runtime-claim substitution is rejected');

    eval {
        FSM::VIAL::ArchitectureScalePortableRuntimeMaterialization::_canonical_route(
            undef, undef, undef,
        );
    };
    like($@, qr/canonical route is caller-sealed/,
        'callers cannot inject source or IR through the private route');
    eval {
        FSM::VIAL::ArchitectureScalePortableRuntimeMaterialization::evaluate(
            'FSM::VIAL::ArchitectureScalePortableRuntimeMaterialization::Subclass',
            {repository_root => $repo_root, level => 'reference_v1'},
        );
    };
    like($@, qr/requires the exact class invocant/,
        'subclass invocants cannot widen materialization');

    build_mirror();
    my $mirror = $class->evaluate({
        repository_root => $mirror_root, level => 'gate_candidate_v1',
    });
    is($mirror->{report_identity},
        $report{gate_candidate_v1}{report_identity},
        'same-volume repository relocation preserves canonical evidence');
    my $gate = slurp_raw(File::Spec->catfile(
        $mirror_root, qw(vial qualification sv_portable_verilator_runtime_gate.vial),
    ));
    $gate =~ s/reset bus 1948/reset bus 1949/
        or die 'mirror mutation anchor is absent';
    write_raw(File::Spec->catfile(
        $mirror_root, qw(vial qualification sv_portable_verilator_runtime_gate.vial),
    ), $gate);
    eval {
        $class->evaluate({
            repository_root => $mirror_root, level => 'gate_candidate_v1',
        });
    };
    like($@, qr/source identity changed/,
        'changed tracked source rejects before parse, plan, or emission');
    remove_tree($mirror_root);
    ok(!-e $mirror_root && !-l $mirror_root,
        'hostile mirror is removed exactly');
};

subtest 'same-volume staging cleans success, failure, and preflight denial' => sub {
    my $seen;
    my $success = $class->with_staging({
        repository_root => $repo_root,
        level => 'gate_candidate_v1',
        consumer => sub {
            my ($context) = @_;
            $seen = $context->{staging_identity};
            ok(-d $context->{staging_root},
                'consumer sees one exact repository-volume stage');
            is($context->{report}{trace_projection}{record_count}, 10_000,
                'consumer receives only regenerated canonical evidence');
        },
    });
    ok($success->{ok} && $success->{same_volume} && $success->{removed},
        'successful structural staging is same-volume and removed');
    ok(defined($seen) && !-e repo_path(split m{/}, $seen),
        'successful staging identity leaves no residue');

    my $failed = $class->with_staging({
        repository_root => $repo_root,
        level => 'gate_candidate_v1',
        consumer => sub { die "intentional materialization consumer failure\n" },
    });
    ok(!$failed->{ok}, 'consumer failure remains visible');
    is($failed->{diagnostics}[0]{code}, 'VIAL_SCALE_CONSUMER_ERROR',
        'consumer failure retains the stable workload diagnostic');
    ok(!-e repo_path(split m{/}, $seen),
        'failed staging also leaves no residue');

    eval {
        $class->with_staging({
            repository_root => $repo_root,
            level => 'limit_v1',
            consumer => sub { die 'must not run' },
        });
    };
    like($@, qr/preflight-dominated runtime shapes cannot create staging/,
        'nominal limit rejects before staging or external execution');
};

SKIP: {
    skip 'set FSMGEN_RUN_VIAL_PORTABLE_RUNTIME_EXACT=1 under the RAM guard for qualified public runs', 10
        unless ($ENV{FSMGEN_RUN_VIAL_PORTABLE_RUNTIME_EXACT} // '') eq '1';
    is($ENV{FSMGEN_RAM_GUARD_ACTIVE}, '1',
        'exact public execution is nested below the repository RAM guard');
    for my $level (qw(gate_candidate_v1 qualification_candidate_v1)) {
        my $path = $expected{$level}{source};
        my $sink = [];
        my $result = execute_vial_tool_request(
            run_request($path, slurp_raw(repo_path(split m{/}, $path))),
            {
                source_catalog => {}, artifact_sink => $sink,
                repository_root => $repo_root,
            },
        );
        ok($result->{success}, "$level executes through the public Runner");
        diag($json->encode($result->{diagnostics})) unless $result->{success};
        my $bytes = 0;
        $bytes += bytes::length($_->{content}) for @$sink;
        is(scalar(@$sink), $expected{$level}{artifacts},
            "$level complete public artifact inventory is exact");
        is($bytes, $expected{$level}{graph},
            "$level complete public graph matches the pre-tool projection");
        my ($trace) = grep { $_->{role} eq 'validated_runtime_trace' } @$sink;
        my %family;
        for my $line (grep { length } split /\n/, $trace->{content}) {
            my $record = JSON::PP->new->decode($line);
            $family{$record->{record_kind}}++;
        }
        is_deeply(\%family, $record_family{$level},
            "$level runtime produces every projected record family exactly");
        is($result->{result_manifest}{status}, 'pass',
            "$level normalized result passes");
        is(scalar(@{$result->{result_manifest}{scenario_results}}), 2,
            "$level retains both semantic scenarios");
    }
    my @residue = tree_files(repo_path('.artifacts', 'tmp', 'vial'));
    is_deeply(\@residue, [],
        'exact public executions remove every runtime staging artifact');
}

done_testing;

sub run_request {
    my ($vial_path, $vial_text) = @_;
    my $hial_path = 'ppif/ahb_lite_subordinate.ppif';
    return {
        schema => 'fsmgen.vial_tool_request.v1',
        schema_version => 1,
        action => 'run',
        vial_source => source_envelope($vial_path, $vial_text, 'vial'),
        hial_source => source_envelope(
            $hial_path, slurp_raw(repo_path(split m{/}, $hial_path)), 'ppif',
        ),
        options => {
            source_style => 'auto', output_style => undef,
            fixture_id => 'base_output_arbitration', scenario_ids => [],
            execution_profile => 'core_directed_single_clock_execution_v1',
            backend_profile => 'sv_portable_verilator', replay_manifest => undef,
            native_extension_catalogs => [],
            artifact_policy => {mode => 'virtual', artifact_root => undef},
            quiet => JSON::PP::false,
        },
    };
}

sub source_envelope {
    my ($source_id, $text, $kind) = @_;
    return {
        source_id => $source_id, source_kind_hint => $kind, text => $text,
        encoding => 'utf-8', origin => 'memory', display_name => $source_id,
        canonical_id => undef, relative_path => $source_id, metadata => {},
    };
}

sub build_mirror {
    remove_tree($mirror_root) if -d $mirror_root && !-l $mirror_root;
    for my $relative (
        'ppif/ahb_lite_subordinate.ppif',
        'vial/ahb_subordinate_base_output_arbitration.vial',
        'vial/qualification/sv_portable_verilator_runtime_gate.vial',
        'vial/qualification/sv_portable_verilator_runtime_qualification.vial',
    ) {
        my @parts = split m{/}, $relative;
        my $name = pop @parts;
        my $directory = File::Spec->catdir($mirror_root, @parts);
        make_path($directory);
        write_raw(File::Spec->catfile($directory, $name),
            slurp_raw(repo_path(split m{/}, $relative)));
    }
}

sub tree_files {
    my ($root) = @_;
    return () unless -d $root && !-l $root;
    my @files;
    require File::Find;
    File::Find::find({
        no_chdir => 1,
        wanted => sub {
            return unless -f $File::Find::name && !-l $File::Find::name;
            push @files, File::Spec->abs2rel($File::Find::name, $root);
        },
    }, $root);
    return sort @files;
}

sub repo_path {
    return File::Spec->catfile($repo_root, @_);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!\n";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $path: $!\n";
    return $text;
}

sub write_raw {
    my ($path, $content) = @_;
    open my $fh, '>:raw', $path or die "cannot write $path: $!\n";
    print {$fh} $content;
    close $fh or die "cannot close $path: $!\n";
}

sub clone {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}
