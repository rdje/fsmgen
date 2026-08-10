#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(abs_path);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleWorkload;

my $class = 'FSM::VIAL::ArchitectureScaleWorkload';
my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $json = JSON::PP->new->canonical(1);
my $ambient_tmp_root = join('/', '', 'tmp', '');
my $vial_input = {
    relative_path => 'source/workload.vial',
    role => 'vial_source',
    encoding => 'utf-8',
    content => "(vial\n  (version 1)\n)\n",
};
my $second_vial_input = {
    relative_path => 'source/imported.vial',
    role => 'vial_source',
    encoding => 'utf-8',
    content => "(vial\n  (version 1)\n  (package imported)\n)\n",
};
my $hial_input = {
    relative_path => 'hial/workload.fsm',
    role => 'hial_source',
    encoding => 'utf-8',
    content => "(fsm workload\n  (state idle initial)\n)\n",
};

subtest 'catalog is exact, complete, bounded, and defensive' => sub {
    is_deeply(
        $class->specification_keys,
        [qw(schema schema_version family level primary_axis requested_counts expected_stage expected_outcome generator_revision seed anchor_identity source_route backend_profile tool_profile applicable_oracles explicit_nonclaims)],
        'workload specification exposes exactly the selected fields',
    );
    is_deeply(
        $class->construction_keys,
        [qw(ok status schema schema_version workload_identity specification input_identities inputs staging_identity diagnostics)],
        'construction result has one closed key set',
    );
    is_deeply(
        $class->staging_keys,
        [qw(ok status schema schema_version workload_identity staging_identity same_volume removed diagnostics)],
        'staging result has one closed key set',
    );

    my $catalog = $class->catalog;
    is($catalog->{schema}, 'fsmgen.vial_architecture_scale_catalog.v1', 'catalog schema is versioned');
    is($catalog->{generator_revision}, 'fsmgen.vial_architecture_scale_generator.v1', 'generator revision is exact');
    is($catalog->{seed}, 1701, 'version-1 seed is fixed');
    is($catalog->{random_algorithm}, 'sha256_counter_rejection_v1', 'payload algorithm reuses shipped authority');
    is($catalog->{staging_root}, '.artifacts/tmp/vial-scale', 'staging root is repository-relative');
    is_deeply(
        $catalog->{levels},
        [qw(reference_v1 gate_candidate_v1 qualification_candidate_v1 limit_v1 over_limit_v1)],
        'all selected levels are ordered explicitly',
    );
    is_deeply(
        [sort keys %{$catalog->{families}}],
        [sort qw(semantic_catalog_v1 bridge_fanout_v1 execution_graph_v1 checking_state_v1 backend_emission_v1 runtime_stream_v1)],
        'exactly six orthogonal families are cataloged',
    );
    is_deeply(
        [sort keys %{$catalog->{backend_profiles}}],
        [sort qw(sv_portable_verilator vhdl_portable_ghdl vhdl_osvvm_qualified sv_uvm_emit.accellera_2020_3_1)],
        'all selected emission profiles are explicit',
    );
    ok(!$catalog->{backend_profiles}{'sv_uvm_emit.accellera_2020_3_1'}{runtime_eligible},
        'native UVM remains emission-only');
    is($catalog->{families}{semantic_catalog_v1}{axes}{source_bytes_per_source}{levels}{gate_candidate_v1}{source_bytes_per_source}, 65_536,
        'per-source byte gate is cap divided by sixteen');
    is($catalog->{families}{semantic_catalog_v1}{axes}{source_bytes_per_source}{levels}{qualification_candidate_v1}{source_bytes_per_source}, 262_144,
        'per-source byte qualification is cap divided by four');
    is($catalog->{families}{semantic_catalog_v1}{axes}{source_bytes_combined}{levels}{gate_candidate_v1}{source_bytes_combined}, 1_048_576,
        'combined-source byte gate is cap divided by sixteen');
    is($catalog->{families}{semantic_catalog_v1}{axes}{source_bytes_combined}{levels}{qualification_candidate_v1}{source_bytes_combined}, 4_194_304,
        'combined-source byte qualification is cap divided by four');
    is($catalog->{families}{semantic_catalog_v1}{axes}{source_bytes_combined}{levels}{over_limit_v1}{construction_rule},
        'first_complete_valid_record_over_boundary', 'byte excess preserves complete valid records');
    is($catalog->{balanced_profile}{axes}{interaction_profile}{levels}{gate_candidate_v1}{operations_total}, 1_024,
        'balanced profile carries its exact conservative operation count');
    is($catalog->{anchor_identity}{vial_sha256},
        '2205b3b4f073a61374b19cb72f06afe31d75fc4d88f903c414b9b28a744ca4cd',
        'checked AHB anchor identity is exact');
    ok(grep { $_ eq 'architecture_scale_capacity' } @{$catalog->{explicit_nonclaims}},
        'catalog explicitly declines a capacity claim');

    $catalog->{families}{semantic_catalog_v1}{axes}{imports}{levels}{gate_candidate_v1}{imports} = 999;
    is($class->catalog->{families}{semantic_catalog_v1}{axes}{imports}{levels}{gate_candidate_v1}{imports}, 8,
        'catalog results are deeply defensive');
};

subtest 'every selected family axis and level constructs a closed candidate' => sub {
    my $catalog = $class->catalog;
    my $count = 0;
    for my $family (sort keys %{$catalog->{families}}) {
        for my $axis (sort keys %{$catalog->{families}{$family}{axes}}) {
            for my $level (sort keys %{$catalog->{families}{$family}{axes}{$axis}{levels}}) {
                my ($backend, $tool);
                if ($family eq 'backend_emission_v1') {
                    $backend = 'sv_portable_verilator';
                }
                elsif ($family eq 'runtime_stream_v1') {
                    $backend = 'sv_portable_verilator';
                    $tool = 'verilator_5_046';
                }
                my $result = $class->construct({
                    family => $family,
                    level => $level,
                    primary_axis => $axis,
                    backend_profile => $backend,
                    tool_profile => $tool,
                    inputs => $family eq 'semantic_catalog_v1'
                        ? [clone($vial_input)]
                        : [clone($vial_input), clone($hial_input)],
                });
                ok($result->{ok}, "$family/$axis/$level constructs");
                diag($json->encode($result->{diagnostics})) unless $result->{ok};
                is_deeply([sort keys %{$result->{specification}}], [sort @{$class->specification_keys}],
                    "$family/$axis/$level specification is closed");
                like($result->{workload_identity}, qr{\Aworkload/[0-9a-f]{64}\z},
                    "$family/$axis/$level identity is full SHA-256");
                $count++;
            }
        }
    }
    is($count, 250, 'catalog exercise covers exactly every selected orthogonal axis-level specification');

    for my $backend (sort keys %{$catalog->{backend_profiles}}) {
        my $emission = build(
            family => 'backend_emission_v1', primary_axis => 'artifact_graph',
            backend_profile => $backend, tool_profile => undef,
            inputs => [clone($vial_input), clone($hial_input)],
        );
        ok($emission->{ok}, "$backend emission selector constructs");
        is($emission->{specification}{backend_profile}, $backend, "$backend selector is retained exactly");
    }
    for my $backend (qw(sv_portable_verilator vhdl_portable_ghdl vhdl_osvvm_qualified)) {
        my $tool = $catalog->{backend_profiles}{$backend}{tool_profile};
        my $runtime = build(
            family => 'runtime_stream_v1', primary_axis => 'runtime_trace_records',
            backend_profile => $backend, tool_profile => $tool,
            inputs => [clone($vial_input), clone($hial_input)],
        );
        ok($runtime->{ok}, "$backend exact runtime/tool selector constructs");
        is($runtime->{specification}{tool_profile}, $tool, "$backend logical tool identity is exact");
    }
    my $balanced = build(
        family => 'balanced_portable_v1', primary_axis => 'interaction_profile',
        backend_profile => 'sv_portable_verilator', tool_profile => undef,
        inputs => [clone($vial_input), clone($hial_input)],
    );
    ok($balanced->{ok}, 'balanced portable profile constructs independently of orthogonal families');
    is($balanced->{specification}{expected_outcome}, 'unqualified_candidate',
        'balanced profile remains an unqualified candidate');
};

subtest 'identity is canonical, path-independent, content-sensitive, and defensive' => sub {
    my $first = build(inputs => [clone($vial_input), clone($second_vial_input)]);
    ok($first->{ok}, 'two-input semantic workload constructs');
    is_deeply([map { $_->{relative_path} } @{$first->{inputs}}],
        [qw(source/imported.vial source/workload.vial)], 'inputs are path-sorted');
    my $reordered = build(inputs => [clone($second_vial_input), clone($vial_input)]);
    is($reordered->{workload_identity}, $first->{workload_identity},
        'caller input ordering cannot perturb canonical identity');
    is($json->encode($reordered), $json->encode($first),
        'independent constructions are byte-equal canonical projections');

    my $changed_input = clone($second_vial_input);
    $changed_input->{content} .= "\n";
    my $changed = build(inputs => [clone($vial_input), $changed_input]);
    isnt($changed->{workload_identity}, $first->{workload_identity},
        'one input byte changes workload identity');
    my $axis = build(primary_axis => 'fixtures', inputs => [clone($vial_input)]);
    isnt($axis->{workload_identity}, build(inputs => [clone($vial_input)])->{workload_identity},
        'specification selection changes workload identity');
    unlike($json->encode($first->{specification}), qr{/Volumes/|/private/|\Q$ambient_tmp_root\E},
        'durable specification contains no absolute host path');

    $first->{specification}{requested_counts}{imports} = 999;
    $first->{inputs}[0]{content} = 'mutated';
    my $fresh = build(inputs => [clone($vial_input), clone($second_vial_input)]);
    is($fresh->{specification}{requested_counts}{imports}, 8, 'specification is defensive across calls');
    isnt($fresh->{inputs}[0]{content}, 'mutated', 'input projection is defensive across calls');
};

subtest 'stable names and payloads are deterministic without selecting structure' => sub {
    is(
        $class->stable_name({family => 'semantic_catalog_v1', primary_axis => 'imports', ordinal => 7}),
        'vial_scale__semantic_catalog_v1__imports__00000007',
        'stable name uses family, axis, and eight-digit ordinal',
    );
    my $first = $class->payload_uint({
        family => 'semantic_catalog_v1', primary_axis => 'imports', ordinal => 7,
        low => 10, high => 99,
    });
    my $second = $class->payload_uint({
        family => 'semantic_catalog_v1', primary_axis => 'imports', ordinal => 7,
        low => 10, high => 99,
    });
    is_deeply($second, $first, 'payload rerun is deterministic');
    is($first->{algorithm}, 'sha256_counter_rejection_v1', 'payload names shipped algorithm');
    is($first->{seed}, 1701, 'payload retains fixed seed');
    cmp_ok($first->{value}, '>=', 10, 'payload is above inclusive low bound');
    cmp_ok($first->{value}, '<=', 99, 'payload is below inclusive high bound');
    my $other = $class->payload_uint({
        family => 'semantic_catalog_v1', primary_axis => 'imports', ordinal => 8,
        low => 10, high => 99,
    });
    isnt($other->{occurrence_id}, $first->{occurrence_id}, 'ordinal changes occurrence identity');
};

subtest 'closed validation rejects malformed specifications and forged input graphs' => sub {
    failure_code({%{base_args()}, extra => 1}, 'VIAL_SCALE_INVOCATION_ERROR', 'unknown construction key');
    my $missing = base_args();
    delete $missing->{level};
    failure_code($missing, 'VIAL_SCALE_INVOCATION_ERROR', 'missing construction key');
    failure_code({%{base_args()}, family => 'unknown_v1'}, 'VIAL_SCALE_SPEC_ERROR', 'unknown family');
    failure_code({%{base_args()}, level => 'huge_v1'}, 'VIAL_SCALE_SPEC_ERROR', 'unknown level');
    failure_code({%{base_args()}, primary_axis => 'comments'}, 'VIAL_SCALE_SPEC_ERROR', 'unknown axis');
    failure_code({%{base_args()}, backend_profile => 'sv_portable_verilator'}, 'VIAL_SCALE_SPEC_ERROR',
        'semantic family rejects backend selection');
    failure_code({
        %{base_args()}, family => 'runtime_stream_v1', primary_axis => 'runtime_trace_records',
        backend_profile => 'sv_portable_verilator', tool_profile => 'wrong',
        inputs => [clone($vial_input), clone($hial_input)],
    }, 'VIAL_SCALE_SPEC_ERROR', 'runtime rejects mismatched tool selector');
    failure_code({
        %{base_args()}, family => 'runtime_stream_v1', primary_axis => 'runtime_trace_records',
        backend_profile => 'sv_uvm_emit.accellera_2020_3_1', tool_profile => 'verilator_5_046',
        inputs => [clone($vial_input), clone($hial_input)],
    }, 'VIAL_SCALE_SPEC_ERROR', 'runtime rejects emission-only backend');
    failure_code({%{base_args()}, inputs => []}, 'VIAL_SCALE_INPUT_ERROR', 'empty input set');

    my $unsafe = clone($vial_input);
    $unsafe->{relative_path} = '../outside.vial';
    failure_code({%{base_args()}, inputs => [$unsafe]}, 'VIAL_SCALE_INPUT_ERROR', 'unsafe relative path');
    my $role = clone($vial_input);
    $role->{role} = 'hial_source';
    failure_code({%{base_args()}, inputs => [$role]}, 'VIAL_SCALE_INPUT_ERROR', 'role/suffix mismatch');
    my $nul = clone($vial_input);
    $nul->{content} .= "\0";
    failure_code({%{base_args()}, inputs => [$nul]}, 'VIAL_SCALE_INPUT_ERROR', 'NUL input');
    failure_code({%{base_args()}, inputs => [clone($vial_input), clone($vial_input)]},
        'VIAL_SCALE_INPUT_ERROR', 'duplicate path');
    my $folded = clone($vial_input);
    $folded->{relative_path} = 'SOURCE/WORKLOAD.vial';
    failure_code({%{base_args()}, inputs => [clone($vial_input), $folded]},
        'VIAL_SCALE_INPUT_ERROR', 'case-fold collision');
    my $prefix = clone($vial_input);
    $prefix->{relative_path} = 'source.vial';
    my $child = clone($vial_input);
    $child->{relative_path} = 'source.vial/child.vial';
    failure_code({%{base_args()}, inputs => [$prefix, $child]},
        'VIAL_SCALE_INPUT_ERROR', 'file/directory collision');
    my $hial = clone($hial_input);
    failure_code({%{base_args()}, inputs => [clone($vial_input), $hial]},
        'VIAL_SCALE_INPUT_ERROR', 'semantic family rejects HIAL input');
    my $bridge_without_hial = {
        %{base_args()}, family => 'bridge_fanout_v1', primary_axis => 'endpoints',
        inputs => [clone($vial_input)],
    };
    failure_code($bridge_without_hial, 'VIAL_SCALE_INPUT_ERROR', 'bridge family requires HIAL input');
    my $oversized = clone($vial_input);
    $oversized->{content} = 'x' x 1_114_113;
    failure_code({%{base_args()}, inputs => [$oversized]}, 'VIAL_SCALE_INPUT_ERROR',
        'individual construction envelope is bounded');
    my @combined_limit = map {
        {
            relative_path => sprintf('source/combined-%02d.vial', $_),
            role => 'vial_source',
            encoding => 'utf-8',
            content => 'x' x 1_048_576,
        }
    } 0 .. 16;
    ok(build(inputs => \@combined_limit)->{ok},
        'combined construction envelope accepts its exact 17,825,792-byte boundary');
    $combined_limit[0]{content} .= 'x';
    failure_code({%{base_args()}, inputs => \@combined_limit}, 'VIAL_SCALE_INPUT_ERROR',
        'combined construction envelope rejects its first excess byte');
};

subtest 'same-volume staging is exact, collision-safe, and always cleaned' => sub {
    my $construction = build(inputs => [clone($vial_input)]);
    ok($construction->{ok}, 'staging construction is valid');
    my $stage_abs = File::Spec->catdir(
        $repo_root, split(m{/}, $construction->{staging_identity}),
    );
    ok(!-e $stage_abs && !-l $stage_abs, 'deterministic staging root begins absent');

    my ($seen_identity, $seen_content, $nested);
    my $staged = $class->with_staging({
        repository_root => $repo_root,
        construction => $construction,
        consumer => sub {
            my ($context) = @_;
            $seen_identity = $context->{staging_identity};
            ok(-d $context->{staging_root} && !-l $context->{staging_root},
                'consumer receives an existing non-symlink staging root');
            my $path = $context->{inputs}[0]{absolute_path};
            open my $fh, '<:raw', $path or die "cannot read staged input";
            local $/;
            $seen_content = <$fh>;
            close $fh or die "cannot close staged input";
            $nested = $class->with_staging({
                repository_root => $repo_root,
                construction => $construction,
                consumer => sub { die 'nested consumer must not run' },
            });
            return;
        },
    });
    ok($staged->{ok}, 'successful consumer returns a staging success');
    is($staged->{status}, 'consumed_unmeasured', 'staging does not claim measurement');
    ok($staged->{same_volume}, 'staging proves repository-volume identity');
    ok($staged->{removed}, 'staging reports exact removal');
    is($seen_identity, $construction->{staging_identity}, 'consumer sees only repository-relative durable identity');
    is($seen_content, $vial_input->{content}, 'staged input bytes are exact');
    is($nested->{diagnostics}[0]{code}, 'VIAL_SCALE_COLLISION', 'concurrent identity collision fails closed');
    ok(!-e $stage_abs && !-l $stage_abs, 'successful workflow leaves no staging residue');

    my $failed = $class->with_staging({
        repository_root => $repo_root,
        construction => $construction,
        consumer => sub { die "consumer failure at $repo_root/secret\n" },
    });
    ok(!$failed->{ok}, 'consumer failure is reported');
    is($failed->{diagnostics}[0]{code}, 'VIAL_SCALE_CONSUMER_ERROR', 'consumer failure has stable code');
    unlike($json->encode($failed), qr{\Q$repo_root\E|/Volumes/|/private/|\Q$ambient_tmp_root\E},
        'consumer diagnostics expose no absolute host path');
    ok(!-e $stage_abs && !-l $stage_abs, 'consumer failure leaves no staging residue');

    my $forged = clone($construction);
    $forged->{workload_identity} =~ s/[0-9a-f]\z/0/;
    $forged->{workload_identity} .= '1' if $forged->{workload_identity} eq $construction->{workload_identity};
    my $forged_result = $class->with_staging({
        repository_root => $repo_root,
        construction => $forged,
        consumer => sub { die 'forged consumer must not run' },
    });
    is($forged_result->{diagnostics}[0]{code}, 'VIAL_SCALE_SPEC_ERROR',
        'mutated construction identity is rejected before staging');
    ok(!-e $stage_abs && !-l $stage_abs, 'forged construction creates no residue');

    my $not_root = File::Spec->catdir($repo_root, 'vial');
    my $bad_root = $class->with_staging({
        repository_root => $not_root,
        construction => $construction,
        consumer => sub { die 'invalid-root consumer must not run' },
    });
    is($bad_root->{diagnostics}[0]{code}, 'VIAL_SCALE_PATH_ERROR',
        'directory without repository identity is rejected');
};

subtest 'mdBook documents the shipped foundation without promoting scale' => sub {
    my $chapter = slurp_raw(File::Spec->catfile(
        $repo_root, 'docs', 'book', 'src', '16d-hial-vial-verification-architecture.md',
    ));
    like($chapter, qr/^### Deterministic construction foundation$/m,
        'book contains a dedicated construction-foundation section');
    like($chapter, qr/FSM::VIAL::ArchitectureScaleWorkload->construct/,
        'book names the exact public construction entrypoint');
    like($chapter, qr/floor\(cap \/ 16\).*floor\(cap \/ 4\)/s,
        'book explains derived byte candidates');
    like($chapter, qr/1,114,112 bytes per input and 17,825,792 bytes\ncombined/,
        'book records bounded source envelope');
    like($chapter, qr/qualification infrastructure,\nnot a user capacity or support claim/,
        'book keeps construction separate from scale support');
    like($chapter, qr/with_staging.*removes the exact owned\ntree on success or failure/s,
        'book documents same-volume cleanup semantics');
};

sub build {
    my (%override) = @_;
    return $class->construct({%{base_args()}, %override});
}

sub base_args {
    return {
        family => 'semantic_catalog_v1',
        level => 'gate_candidate_v1',
        primary_axis => 'imports',
        backend_profile => undef,
        tool_profile => undef,
        inputs => [clone($vial_input)],
    };
}

sub failure_code {
    my ($args, $code, $label) = @_;
    my $result = $class->construct($args);
    ok(!$result->{ok}, "$label fails");
    is($result->{diagnostics}[0]{code}, $code, "$label has stable diagnostic code");
    is_deeply([sort keys %$result], [sort @{$class->construction_keys}], "$label result remains closed");
}

sub clone {
    my ($value) = @_;
    return undef unless defined $value;
    return {map { $_ => clone($value->{$_}) } keys %$value} if ref($value) eq 'HASH';
    return [map { clone($_) } @$value] if ref($value) eq 'ARRAY';
    return $value;
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read '$path': $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close '$path': $!";
    return $text;
}

done_testing;
