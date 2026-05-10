#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::HDLGeneratorResultContract qw(build_hdl_generator_result_contract);

subtest 'HDLGenerator result contract full surface survives JSON round trip' => sub {
    my $expected = build_hdl_generator_result_contract();
    my $decoded = decode_json(encode_json($expected));
    is_deeply($decoded, $expected, 'decoded HDLGenerator result contract matches direct owner contract');
};

done_testing();
