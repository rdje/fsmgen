#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::GHDLLifecycle;
use FSM::VIAL::Backend::ResultProducer;
use FSM::VIAL::Backend::VHDLResultSchema;

my $json = JSON::PP->new->canonical(1);
my $expected_plan_id = 'plan/' . ('a' x 64);
my @scenario_id = qw(fixture::scenario::one fixture::scenario::two);
my @expected_run_id = map { "run/$expected_plan_id/$_" } @scenario_id;
my $manifest = {map { $_ => undef }
    @{FSM::VIAL::Backend::ResultProducer->manifest_keys}};
$manifest->{schema} = 'fsmgen.verification_result_manifest.v1';
$manifest->{schema_version} = 1;
$manifest->{status} = 'pass';
$manifest->{plan_id} = $expected_plan_id;
$manifest->{scenario_results} = [map {
    {
        run_id => $expected_run_id[$_],
        scenario_id => $scenario_id[$_],
        status => 'pass',
        start_time => {
            domain_id => 'domain/main', cycle => 0,
            phase => 'drive', ordinal => 0,
        },
        end_time => {
            domain_id => 'domain/main', cycle => 0,
            phase => 'check', ordinal => 0,
        },
        completion_reason => 'completed',
        expectation_ids => [],
        diagnostic_ids => [],
        cancelled_fiber_ids => [],
        logical_cycle_count => 1,
    }
} 0 .. $#scenario_id];
$manifest->{parity_projection} = {
    plan_id => $expected_plan_id,
    schema => 'fsmgen.vial_vhdl_portable_outcomes.v1',
    schema_version => 1,
    outcomes => [map {{
        bus_accepts => 0,
        final_read_data_bits => '00000000',
        final_ready => 1,
        final_response => 0,
        nonzero_read_data_cycles => 0,
        ready_low_cycles => 0,
        response_error_cycles => 0,
        scenario_id => $_,
        status => 'pass',
        storage_bits => '00000000',
    }} @scenario_id],
};
my $encoded = $json->encode($manifest);

subtest 'canonical result is admitted at the exact byte boundary' => sub {
    my $decoded = decode_record($encoded, length($encoded));
    is_deeply($decoded, $manifest,
        'exact-boundary canonical result retains its semantic projection');
};

subtest 'one byte beyond the result boundary rejects before decoding' => sub {
    my $error = decode_failure($encoded, length($encoded) - 1);
    is($error->{code}, 'VIAL_GHDL_LIFECYCLE_LIMIT_ERROR',
        'adjacent result excess has the stable lifecycle limit diagnostic');
    is($error->{path}, '/result_produced',
        'adjacent result excess points to result production');
};

subtest 'noncanonical runtime result bytes reject' => sub {
    my $noncanonical = " $encoded";
    my $error = decode_failure($noncanonical, length($noncanonical));
    is($error->{code}, 'VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'noncanonical result has the stable result diagnostic');
    is($error->{path}, '/result_produced',
        'noncanonical result points to result production');
};

subtest 'result manifest top-level vocabulary is closed' => sub {
    my $missing = clone($manifest);
    delete $missing->{metrics};
    my $missing_encoded = $json->encode($missing);
    my $missing_error = decode_failure(
        $missing_encoded, length($missing_encoded),
    );
    is($missing_error->{code}, 'VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'missing shared manifest key rejects');
    is($missing_error->{path}, '/result_produced',
        'missing shared manifest key points to result production');

    my $foreign = clone($manifest);
    $foreign->{foreign_runtime_field} = 'unowned';
    my $foreign_encoded = $json->encode($foreign);
    my $foreign_error = decode_failure(
        $foreign_encoded, length($foreign_encoded),
    );
    is($foreign_error->{code}, 'VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'foreign shared manifest key rejects');
    is($foreign_error->{path}, '/result_produced',
        'foreign shared manifest key points to result production');
};

subtest 'result plan identities match the sealed trace authority' => sub {
    my $top_level = clone($manifest);
    $top_level->{plan_id} = 'plan/' . ('b' x 64);
    my $top_error = identity_failure($top_level);
    is($top_error->{code}, 'VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'foreign result plan identity rejects');
    is($top_error->{path}, '/result_produced/plan_id',
        'foreign result plan identity has the exact path');

    my $projection = clone($manifest);
    $projection->{parity_projection}{plan_id} = 'plan/' . ('b' x 64);
    my $projection_error = identity_failure($projection);
    is($projection_error->{code}, 'VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'foreign parity-projection plan identity rejects');
    is($projection_error->{path}, '/result_produced/parity_projection/plan_id',
        'foreign parity-projection plan identity has the exact path');

    my $wrong_shape = clone($manifest);
    $wrong_shape->{parity_projection} = [];
    my $shape_error = identity_failure($wrong_shape);
    is($shape_error->{code}, 'VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'non-object parity projection rejects');
    is($shape_error->{path}, '/result_produced/parity_projection',
        'non-object parity projection has the exact path');
};

subtest 'result scenario identities match ordered trace runs' => sub {
    my $valid = eval {
        validate_scenario_identities(clone($manifest));
        1;
    };
    ok($valid, 'closed ordered result identities are admitted');

    my $omitted = clone($manifest);
    pop @{$omitted->{scenario_results}};
    is(scenario_failure($omitted)->{path}, '/result_produced/scenario_results',
        'omitted scenario result rejects at the collection');

    my $duplicate = clone($manifest);
    $duplicate->{scenario_results}[1]{run_id} = $expected_run_id[0];
    is(scenario_failure($duplicate)->{path},
        '/result_produced/scenario_results/1/run_id',
        'duplicate run identity rejects at its ordered slot');

    my $reordered = clone($manifest);
    @{$reordered->{scenario_results}} =
        reverse @{$reordered->{scenario_results}};
    is(scenario_failure($reordered)->{path},
        '/result_produced/scenario_results/0/run_id',
        'reordered scenario results reject at the first mismatch');

    my $missing_outcome = clone($manifest);
    pop @{$missing_outcome->{parity_projection}{outcomes}};
    is(scenario_failure($missing_outcome)->{path},
        '/result_produced/parity_projection/outcomes',
        'omitted parity outcome rejects at the collection');

    my $foreign_outcome = clone($manifest);
    $foreign_outcome->{parity_projection}{outcomes}[0]{scenario_id} =
        'fixture::scenario::foreign';
    is(scenario_failure($foreign_outcome)->{path},
        '/result_produced/parity_projection/outcomes/0/scenario_id',
        'foreign parity scenario rejects at its ordered slot');
};

subtest 'VHDL parity vocabulary has one defensive schema authority' => sub {
    is(FSM::VIAL::Backend::VHDLResultSchema->parity_schema,
        'fsmgen.vial_vhdl_portable_outcomes.v1',
        'selected parity schema is exact');
    is(FSM::VIAL::Backend::VHDLResultSchema->parity_schema_version, 1,
        'selected parity schema version is exact');
    is_deeply(
        FSM::VIAL::Backend::VHDLResultSchema->parity_projection_keys,
        [qw(outcomes plan_id schema schema_version)],
        'projection vocabulary is exact');
    my $mutable = FSM::VIAL::Backend::VHDLResultSchema->parity_outcome_keys;
    is_deeply($mutable, [qw(
        bus_accepts final_read_data_bits final_ready final_response
        nonzero_read_data_cycles ready_low_cycles response_error_cycles
        scenario_id status storage_bits
    )], 'outcome vocabulary is exact');
    pop @$mutable;
    is(scalar @{FSM::VIAL::Backend::VHDLResultSchema->parity_outcome_keys}, 10,
        'callers cannot mutate the schema authority');
};

subtest 'nested result vocabularies and statuses remain closed' => sub {
    my $valid = eval {
        validate_result_shapes(clone($manifest));
        1;
    };
    ok($valid, 'closed pass-consistent nested result is admitted');

    my $missing_scenario = clone($manifest);
    delete $missing_scenario->{scenario_results}[0]{logical_cycle_count};
    is(shape_failure($missing_scenario)->{path},
        '/result_produced/scenario_results/0/logical_cycle_count',
        'missing shared scenario member rejects at its exact path');

    my $foreign_scenario = clone($manifest);
    $foreign_scenario->{scenario_results}[0]{foreign_runtime_field} = 1;
    is(shape_failure($foreign_scenario)->{path},
        '/result_produced/scenario_results/0/foreign_runtime_field',
        'foreign shared scenario member rejects at its exact path');

    my $failed_scenario = clone($manifest);
    $failed_scenario->{scenario_results}[0]{status} = 'fail';
    is(shape_failure($failed_scenario)->{path},
        '/result_produced/scenario_results/0/status',
        'non-pass scenario rejects beneath a passing result');

    my $foreign_projection = clone($manifest);
    $foreign_projection->{parity_projection}{foreign_runtime_field} = 1;
    is(shape_failure($foreign_projection)->{path},
        '/result_produced/parity_projection/foreign_runtime_field',
        'foreign parity-projection member rejects at its exact path');

    my $missing_projection = clone($manifest);
    delete $missing_projection->{parity_projection}{schema};
    is(shape_failure($missing_projection)->{path},
        '/result_produced/parity_projection/schema',
        'missing parity-projection member rejects at its exact path');

    my $wrong_projection_schema = clone($manifest);
    $wrong_projection_schema->{parity_projection}{schema} =
        'fsmgen.vial_vhdl_portable_outcomes.v2';
    is(shape_failure($wrong_projection_schema)->{path},
        '/result_produced/parity_projection/schema',
        'foreign parity-projection schema rejects at its exact path');

    my $wrong_projection_version = clone($manifest);
    $wrong_projection_version->{parity_projection}{schema_version} = 2;
    is(shape_failure($wrong_projection_version)->{path},
        '/result_produced/parity_projection/schema_version',
        'foreign parity-projection version rejects at its exact path');

    my $missing_outcome = clone($manifest);
    delete $missing_outcome->{parity_projection}{outcomes}[0]{storage_bits};
    is(shape_failure($missing_outcome)->{path},
        '/result_produced/parity_projection/outcomes/0/storage_bits',
        'missing VHDL outcome member rejects at its exact path');

    my $foreign_outcome = clone($manifest);
    $foreign_outcome->{parity_projection}{outcomes}[0]{foreign_runtime_field} = 1;
    is(shape_failure($foreign_outcome)->{path},
        '/result_produced/parity_projection/outcomes/0/foreign_runtime_field',
        'foreign VHDL outcome member rejects at its exact path');

    my $failed_outcome = clone($manifest);
    $failed_outcome->{parity_projection}{outcomes}[0]{status} = 'fail';
    is(shape_failure($failed_outcome)->{path},
        '/result_produced/parity_projection/outcomes/0/status',
        'non-pass parity outcome rejects beneath a passing result');
};

subtest 'scenario values obey the shared passing-result contract' => sub {
    my $valid = eval {
        validate_scenario_values(clone($manifest));
        1;
    };
    ok($valid, 'closed scenario values are admitted');

    my $missing_time = clone($manifest);
    delete $missing_time->{scenario_results}[0]{start_time}{ordinal};
    is(value_failure($missing_time)->{path},
        '/result_produced/scenario_results/0/start_time/ordinal',
        'missing logical-time member rejects at its exact path');

    my $foreign_time = clone($manifest);
    $foreign_time->{scenario_results}[0]{end_time}{host_tick} = 1;
    is(value_failure($foreign_time)->{path},
        '/result_produced/scenario_results/0/end_time/host_tick',
        'foreign logical-time member rejects at its exact path');

    my $domain_drift = clone($manifest);
    $domain_drift->{scenario_results}[0]{end_time}{domain_id} = 'domain/foreign';
    is(value_failure($domain_drift)->{path},
        '/result_produced/scenario_results/0/end_time/domain_id',
        'end domain must equal the scenario start domain');

    my $late_start = clone($manifest);
    $late_start->{scenario_results}[0]{start_time}{cycle} = 1;
    is(value_failure($late_start)->{path},
        '/result_produced/scenario_results/0/start_time/cycle',
        'scenario start must retain the zero cycle origin');

    my $wrong_start_phase = clone($manifest);
    $wrong_start_phase->{scenario_results}[0]{start_time}{phase} = 'sample';
    is(value_failure($wrong_start_phase)->{path},
        '/result_produced/scenario_results/0/start_time/phase',
        'scenario start must use the drive phase');

    my $wrong_end_phase = clone($manifest);
    $wrong_end_phase->{scenario_results}[0]{end_time}{phase} = 'react';
    is(value_failure($wrong_end_phase)->{path},
        '/result_produced/scenario_results/0/end_time/phase',
        'scenario end must use the check phase');

    my $foreign_ordinal = clone($manifest);
    $foreign_ordinal->{scenario_results}[0]{end_time}{ordinal} = 1;
    is(value_failure($foreign_ordinal)->{path},
        '/result_produced/scenario_results/0/end_time/ordinal',
        'scenario boundary ordinal must remain zero');

    my $zero_count = clone($manifest);
    $zero_count->{scenario_results}[0]{logical_cycle_count} = 0;
    is(value_failure($zero_count)->{path},
        '/result_produced/scenario_results/0/logical_cycle_count',
        'logical cycle count must be positive');

    my $off_by_one = clone($manifest);
    $off_by_one->{scenario_results}[0]{end_time}{cycle} = 1;
    is(value_failure($off_by_one)->{path},
        '/result_produced/scenario_results/0/end_time/cycle',
        'end cycle must equal logical cycle count minus one');

    my $wrong_completion = clone($manifest);
    $wrong_completion->{scenario_results}[0]{completion_reason} =
        'expectation_failed';
    is(value_failure($wrong_completion)->{path},
        '/result_produced/scenario_results/0/completion_reason',
        'passing scenario must complete normally');

    my $wrong_collection = clone($manifest);
    $wrong_collection->{scenario_results}[0]{expectation_ids} = {};
    is(value_failure($wrong_collection)->{path},
        '/result_produced/scenario_results/0/expectation_ids',
        'scenario ID collection must remain an array');

    my $unsafe_id = clone($manifest);
    $unsafe_id->{scenario_results}[0]{diagnostic_ids} = ["diagnostic/bad\n"];
    is(value_failure($unsafe_id)->{path},
        '/result_produced/scenario_results/0/diagnostic_ids/0',
        'unsafe scenario-owned identity rejects at its exact index');

    my $duplicate_id = clone($manifest);
    $duplicate_id->{scenario_results}[0]{cancelled_fiber_ids} =
        [qw(fiber/one fiber/one)];
    is(value_failure($duplicate_id)->{path},
        '/result_produced/scenario_results/0/cancelled_fiber_ids/1',
        'duplicate scenario-owned identity rejects at its second index');
};

subtest 'record cardinality and JSON shape remain fail closed' => sub {
    my $duplicate = decode_failure(
        "$encoded\nFSMGEN_VIAL_RESULT_V1\t$encoded",
        2 * length($encoded),
    );
    is($duplicate->{code}, 'VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'duplicate normalized results still reject');

    my $malformed = decode_failure('{', 1);
    is($malformed->{code}, 'VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'malformed normalized result still rejects');
};

done_testing();

sub decode_record {
    my ($content, $limit) = @_;
    return FSM::VIAL::Backend::GHDLLifecycle::_decode_runtime_result_record(
        "FSMGEN_VIAL_RESULT_V1\t$content\n", $limit,
    );
}

sub decode_failure {
    my ($content, $limit) = @_;
    my $ok = eval {
        decode_record($content, $limit);
        1;
    };
    ok(!$ok, 'controlled result record rejects');
    my $error = $@;
    isa_ok($error, 'FSM::VIAL::Backend::GHDLLifecycle::Failure');
    return ref($error) ? $error : {};
}

sub identity_failure {
    my ($candidate) = @_;
    my $ok = eval {
        FSM::VIAL::Backend::GHDLLifecycle::_validate_runtime_result_plan_identity(
            $candidate, $expected_plan_id,
        );
        1;
    };
    ok(!$ok, 'foreign result identity rejects');
    my $error = $@;
    isa_ok($error, 'FSM::VIAL::Backend::GHDLLifecycle::Failure');
    return ref($error) ? $error : {};
}

sub validate_scenario_identities {
    FSM::VIAL::Backend::GHDLLifecycle::_validate_runtime_result_scenario_identities(
        $_[0], $expected_plan_id, \@expected_run_id,
    );
}

sub scenario_failure {
    my ($candidate) = @_;
    my $ok = eval {
        validate_scenario_identities($candidate);
        1;
    };
    ok(!$ok, 'invalid result scenario identity rejects');
    my $error = $@;
    isa_ok($error, 'FSM::VIAL::Backend::GHDLLifecycle::Failure');
    return ref($error) ? $error : {};
}

sub validate_result_shapes {
    FSM::VIAL::Backend::GHDLLifecycle::_validate_runtime_result_shapes($_[0]);
}

sub shape_failure {
    my ($candidate) = @_;
    my $ok = eval {
        validate_result_shapes($candidate);
        1;
    };
    ok(!$ok, 'invalid nested result shape rejects');
    my $error = $@;
    isa_ok($error, 'FSM::VIAL::Backend::GHDLLifecycle::Failure');
    return ref($error) ? $error : {};
}

sub validate_scenario_values {
    FSM::VIAL::Backend::GHDLLifecycle::_validate_runtime_result_scenario_values(
        $_[0],
    );
}

sub value_failure {
    my ($candidate) = @_;
    my $ok = eval {
        validate_scenario_values($candidate);
        1;
    };
    ok(!$ok, 'invalid scenario value rejects');
    my $error = $@;
    isa_ok($error, 'FSM::VIAL::Backend::GHDLLifecycle::Failure');
    return ref($error) ? $error : {};
}

sub clone {
    return JSON::PP->new->decode(JSON::PP->new->encode($_[0]));
}
