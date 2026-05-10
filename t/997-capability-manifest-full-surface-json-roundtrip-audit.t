#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);

subtest 'capability manifest full surface survives JSON round trip' => sub {
    my $expected = build_capability_manifest();
    my $decoded = decode_json(encode_json($expected));
    is_deeply($decoded, $expected, 'decoded capability manifest matches freshly built manifest');
};

done_testing();
