#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::CapabilityManifestContract qw(build_capability_manifest_contract);

subtest 'manifest contract core section presence keys survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{manifest_contract};
    my $expected = build_capability_manifest_contract();
    is_deeply($contract->{'producer_presence_keys'}, $expected->{'producer_presence_keys'}, 'decoded manifest contract keeps producer_presence_keys');
    is_deeply($contract->{'support_accounting_presence_keys'}, $expected->{'support_accounting_presence_keys'}, 'decoded manifest contract keeps support_accounting_presence_keys');
    is_deeply($contract->{'diagnostics_presence_keys'}, $expected->{'diagnostics_presence_keys'}, 'decoded manifest contract keeps diagnostics_presence_keys');
    is_deeply($contract->{'semantic_exports_presence_keys'}, $expected->{'semantic_exports_presence_keys'}, 'decoded manifest contract keeps semantic_exports_presence_keys');
};
done_testing();
