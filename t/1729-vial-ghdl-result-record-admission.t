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

my $json = JSON::PP->new->canonical(1);
my $expected_plan_id = 'plan/' . ('a' x 64);
my $manifest = {map { $_ => undef }
    @{FSM::VIAL::Backend::ResultProducer->manifest_keys}};
$manifest->{schema} = 'fsmgen.verification_result_manifest.v1';
$manifest->{schema_version} = 1;
$manifest->{status} = 'pass';
$manifest->{plan_id} = $expected_plan_id;
$manifest->{parity_projection} = {plan_id => $expected_plan_id};
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

sub clone {
    return JSON::PP->new->decode(JSON::PP->new->encode($_[0]));
}
