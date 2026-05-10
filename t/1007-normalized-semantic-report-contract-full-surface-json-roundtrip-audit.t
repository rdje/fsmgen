#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::NormalizedSemanticReportContract qw(build_normalized_semantic_report_contract);

subtest 'normalized semantic report contract full surface survives JSON round trip' => sub {
    my $expected = build_normalized_semantic_report_contract();
    my $decoded = decode_json(encode_json($expected));
    is_deeply($decoded, $expected, 'decoded normalized semantic report contract matches direct owner contract');
};

done_testing();
