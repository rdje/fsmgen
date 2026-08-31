#!/usr/bin/env perl

use strict;
use warnings;

use JSON::PP ();
use Test::More;

use lib 'perl';

use FSM::Support::VIALToolingContract qw(build_vial_tooling_contract);
use FSM::VIAL::Backend::TraceValidator;
use FSM::VIAL::Backend::VerilatorLifecycle;

my $base = 'backends/sv_portable_verilator';
my $artifact_limit =
    build_vial_tooling_contract()->{limits}{artifact_bytes};
my $immutable_content = "module bounded; endmodule\n";
my $immutable_bytes = length($immutable_content);

my $at_limit = phase_attempt($artifact_limit - $immutable_bytes);
is($at_limit->{error}, '', 'exact public-artifact lower bound is admitted');
is($at_limit->{writes}, 3, 'admitted trace writes all three trace objects');

my $over_limit = phase_attempt($artifact_limit - $immutable_bytes + 1);
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
    qr{\b67[ _]?108[ _]?864\b|\b67108864\b},
    'diagnostic names the exact existing public artifact byte limit',
);
is(
    $over_limit->{writes}, 0,
    'known excess rejects before any validated-trace object is written',
);

done_testing();

sub phase_attempt {
    my ($trace_bytes) = @_;
    my $trace_jsonl = 'x' x $trace_bytes;
    my $writes = 0;
    my $session = {
        execution_ir => undef,
        artifact => {
            "$base/generated/bounded.sv" => {
                relpath => "$base/generated/bounded.sv",
                content => $immutable_content,
            },
            "$base/evidence/tool-profile.json" => {
                relpath => "$base/evidence/tool-profile.json",
                content => "{}\n",
            },
            "$base/backend-manifest.json" => {
                relpath => "$base/backend-manifest.json",
                content => "{}\n",
            },
        },
        objects => [
            {kind => 'runtime_raw_output'},
            {kind => 'runtime_process_evidence'},
        ],
    };

    no warnings 'redefine';
    local *FSM::VIAL::Backend::VerilatorLifecycle::_read_object_content =
        sub { return '' };
    local *FSM::VIAL::Backend::VerilatorLifecycle::_decode_object_json =
        sub { return {exit_code => 0} };
    local *FSM::VIAL::Backend::VerilatorLifecycle::_extract_trace =
        sub { return ('', $trace_jsonl, []) };
    local *FSM::VIAL::Backend::TraceValidator::validate = sub {
        return {
            ok => JSON::PP::true,
            projection => {
                trace_sha256 => '0' x 64,
                record_count => 1,
            },
            diagnostics => [],
        };
    };
    local *FSM::VIAL::Backend::VerilatorLifecycle::_write_content_object =
        sub {
            $writes++;
            return {sha256 => '1' x 64};
        };

    my $result = eval {
        FSM::VIAL::Backend::VerilatorLifecycle::_phase_trace_validate(
            $session,
        );
    };
    my $error = $@;
    return {
        result => $result,
        error => $error,
        writes => $writes,
    };
}
