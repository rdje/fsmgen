#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::CompositionReportContract qw(build_composition_report_contract);

subtest 'manifest-embedded composition report tested_by and guidance lists survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{composition_report};
    my $expected = build_composition_report_contract();
    is_deeply($contract->{'tested_by'}, $expected->{'tested_by'}, 'decoded manifest composition report keeps tested_by');
    is_deeply($contract->{'guidance'}, $expected->{'guidance'}, 'decoded manifest composition report keeps guidance');
};
done_testing();
