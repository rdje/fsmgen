#!/usr/bin/env perl

use strict;
use warnings;

use JSON::PP ();
use Test::More;

use lib 'perl';

use FSM::Support::VIALToolingContract qw(build_vial_tooling_contract);
use FSM::VIAL::Backend::ResultProducer;
use FSM::VIAL::Backend::VerilatorLifecycle;

my $base = 'backends/sv_portable_verilator';
my $artifact_limit =
    build_vial_tooling_contract()->{limits}{artifact_bytes};
my $immutable_content = "module bounded; endmodule\n";
my $compile_transcript = "compile passed\n";
my $run_transcript = "run passed\n";
my $trace_jsonl = "{\"event\":\"bounded\"}\n";
my $selected_profile = {tool_name => 'verilator'};
my $published_profile = {
    %$selected_profile,
    selection_status => 'executed_qualified',
    execution_evidence => JSON::PP::true,
};
my $profile_json = JSON::PP->new->ascii->canonical->pretty
    ->encode($published_profile);
$profile_json .= "\n" unless $profile_json =~ /\n\z/;
my $known_without_result = length($immutable_content)
    + length($compile_transcript)
    + length($run_transcript)
    + length($trace_jsonl)
    + length($profile_json);

my $at_limit = phase_attempt($artifact_limit - $known_without_result);
is($at_limit->{error}, '', 'exact result-ready lower bound is admitted');
is($at_limit->{producer_calls}, 1, 'admitted result is produced exactly once');
is($at_limit->{writes}, 1, 'admitted result writes its lifecycle payload');

my $over_limit = phase_attempt(
    $artifact_limit - $known_without_result + 1,
);
is(
    ref($over_limit->{error}),
    'FSM::VIAL::Backend::VerilatorLifecycle::Failure',
    'one excess byte rejects through the lifecycle failure authority',
);
is(
    ref($over_limit->{error}) ? $over_limit->{error}{code} : '',
    'VIAL_RUN_LIMIT_EXCEEDED',
    'one excess byte uses the stable runtime limit diagnostic',
);
is(
    ref($over_limit->{error}) ? $over_limit->{error}{path} : '',
    '/artifacts',
    'one excess byte identifies the public artifact graph',
);
like(
    ref($over_limit->{error}) ? $over_limit->{error}{message} : '',
    qr{\b67108864\b},
    'diagnostic names the exact existing public artifact byte limit',
);
is(
    $over_limit->{producer_calls}, 1,
    'the exact result is produced once before its bytes are knowable',
);
is(
    $over_limit->{writes}, 0,
    'known excess rejects before any result-payload object is written',
);

done_testing();

sub phase_attempt {
    my ($result_bytes) = @_;
    my $result_content = 'x' x $result_bytes;
    my ($producer_calls, $writes) = (0, 0);
    my $trace = {
        projection => {trace_sha256 => '2' x 64},
    };
    my $session = {
        execution_ir => undef,
        selected_profile => $selected_profile,
        compile => {command_digest => '3' x 64},
        run => {command_digest => '4' x 64},
        emission => {
            plan_id => 'plan/' . ('5' x 64),
            negotiation => {},
        },
        artifact => {
            "$base/generated/bounded.sv" => {
                relpath => "$base/generated/bounded.sv",
                kind => 'systemverilog_source',
                content => $immutable_content,
            },
            "$base/evidence/tool-profile.json" => {
                relpath => "$base/evidence/tool-profile.json",
                kind => 'tool_profile',
                content => "{}\n",
            },
            "$base/backend-manifest.json" => {
                relpath => "$base/backend-manifest.json",
                kind => 'backend_manifest',
                content => "{}\n",
            },
        },
        objects => [
            {kind => 'validated_trace'},
            {kind => 'runtime_ordinary_lines'},
            {kind => 'tool_version_output'},
            {kind => 'runtime_trace_jsonl'},
        ],
    };

    no warnings 'redefine';
    local *FSM::VIAL::Backend::VerilatorLifecycle::_decode_object_json =
        sub {
            my (undef, $object) = @_;
            return $trace if $object->{kind} eq 'validated_trace';
            return [];
        };
    local *FSM::VIAL::Backend::VerilatorLifecycle::_read_object_content =
        sub {
            my (undef, $object) = @_;
            return $trace_jsonl
                if $object->{kind} eq 'runtime_trace_jsonl';
            return "Verilator 5.046\n";
        };
    local *FSM::VIAL::Backend::VerilatorLifecycle::_compile_transcript =
        sub { return $compile_transcript };
    local *FSM::VIAL::Backend::VerilatorLifecycle::_run_transcript =
        sub { return $run_transcript };
    local *FSM::VIAL::Backend::ResultProducer::produce = sub {
        $producer_calls++;
        return {
            ok => JSON::PP::true,
            status => 'passed',
            manifest => {result_id => 'result/' . ('6' x 64)},
            content => $result_content,
            diagnostics => [],
        };
    };
    local *FSM::VIAL::Backend::VerilatorLifecycle::_write_content_object =
        sub {
            $writes++;
            return {sha256 => '7' x 64};
        };

    my $result = eval {
        FSM::VIAL::Backend::VerilatorLifecycle::_phase_result_produce(
            $session,
        );
    };
    my $error = $@;
    return {
        result => $result,
        error => $error,
        producer_calls => $producer_calls,
        writes => $writes,
    };
}
