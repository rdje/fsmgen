#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::NormalizedSemanticSignalAnalysisContract qw(build_normalized_semantic_signal_analysis_contract);

subtest 'signal analysis contract full surface survives JSON round trip' => sub {
    my $contract = build_normalized_semantic_signal_analysis_contract();
    my $decoded = decode_json(encode_json($contract));
    is_deeply($decoded, $contract, 'decoded signal analysis contract matches direct owner contract');
};

done_testing();
