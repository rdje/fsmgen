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

subtest 'manifest-embedded typed extensions identity metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{typed_extensions};
    my $expected = build_extension_contract();
    is($contract->{'status'}, $expected->{'status'}, 'decoded manifest typed extension contract keeps status');
    is($contract->{'contract_source'}, $expected->{'contract_source'}, 'decoded manifest typed extension contract keeps contract_source');
    is_deeply($contract->{'implementation_owners'}, $expected->{'implementation_owners'}, 'decoded manifest typed extension contract keeps implementation_owners');
    is($contract->{schema_version}, $expected->{schema_version}, 'decoded manifest typed extension contract keeps schema_version');
};
done_testing();
