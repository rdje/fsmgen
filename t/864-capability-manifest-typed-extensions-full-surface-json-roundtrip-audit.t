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

subtest 'manifest-embedded typed extensions full embedded typed-extension contract survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{typed_extensions};
    my $expected = build_extension_contract();
    is_deeply($contract->{'extension_object_contract'}, $expected->{'extension_object_contract'}, 'decoded manifest typed extension contract keeps extension_object_contract');
    is_deeply($contract->{'context_contract'}, $expected->{'context_contract'}, 'decoded manifest typed extension contract keeps context_contract');
    is_deeply($contract->{'hooks'}, $expected->{'hooks'}, 'decoded manifest typed extension contract keeps hooks');
    is_deeply($contract->{'name_family_map'}, $expected->{'name_family_map'}, 'decoded manifest typed extension contract keeps name_family_map');
    is_deeply($contract->{'guidance'}, $expected->{'guidance'}, 'decoded manifest typed extension contract keeps guidance');
};
done_testing();
