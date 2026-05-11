#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::ProducerContract qw(build_producer_contract);

subtest 'producer section contract full surface survives JSON round trip' => sub {
    my $contract = build_producer_contract();
    my $decoded = decode_json(encode_json($contract));
    is_deeply($decoded, $contract, 'decoded producer section contract matches owner contract');
};

done_testing();
