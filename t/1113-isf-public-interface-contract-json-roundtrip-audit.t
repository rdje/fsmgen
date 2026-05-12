#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::ISFPublicInterfaceContract qw(build_isf_public_interface_contract);

subtest 'ISF public-interface contract full surface survives JSON round trip' => sub {
    my $contract = build_isf_public_interface_contract();
    my $decoded = decode_json(encode_json($contract));
    is_deeply($decoded, $contract, 'decoded ISF public-interface contract matches owner contract');
};

done_testing();
