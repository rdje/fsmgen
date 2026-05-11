#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CheckResultContract qw(build_check_result_contract);

subtest 'check result contract full surface survives JSON round trip' => sub {
    my $expected = build_check_result_contract();
    my $decoded = decode_json(encode_json($expected));
    is_deeply($decoded, $expected, 'decoded check result contract matches direct owner contract');
};

done_testing();
