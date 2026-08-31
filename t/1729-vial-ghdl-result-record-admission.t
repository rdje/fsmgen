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
my $manifest = {map { $_ => undef }
    @{FSM::VIAL::Backend::ResultProducer->manifest_keys}};
$manifest->{schema} = 'fsmgen.verification_result_manifest.v1';
$manifest->{schema_version} = 1;
$manifest->{status} = 'pass';
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
