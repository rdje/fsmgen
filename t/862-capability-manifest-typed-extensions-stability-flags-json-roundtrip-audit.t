#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ExtensionContract qw(build_extension_contract);

subtest 'manifest-embedded typed extensions stability and closure flags survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{typed_extensions};
    my $expected = build_extension_contract();
    is($contract->{'stable_context_accessor_names'} ? 1 : 0, $expected->{'stable_context_accessor_names'} ? 1 : 0, 'decoded manifest typed extension contract keeps stable_context_accessor_names');
    is($contract->{'hook_set_closed_for_schema_version'} ? 1 : 0, $expected->{'hook_set_closed_for_schema_version'} ? 1 : 0, 'decoded manifest typed extension contract keeps hook_set_closed_for_schema_version');
    is($contract->{'full_extension_api_frozen'} ? 1 : 0, $expected->{'full_extension_api_frozen'} ? 1 : 0, 'decoded manifest typed extension contract keeps full_extension_api_frozen');
};
done_testing();
