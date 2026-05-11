#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::NormalizedSemanticLoweredRTLIRContract qw(build_normalized_semantic_lowered_rtl_ir_contract);

subtest 'lowered RTL IR contract full surface survives JSON round trip' => sub {
    my $contract = build_normalized_semantic_lowered_rtl_ir_contract();
    my $decoded = decode_json(encode_json($contract));
    is_deeply($decoded, $contract, 'decoded lowered RTL IR contract matches direct owner contract');
};

done_testing();
