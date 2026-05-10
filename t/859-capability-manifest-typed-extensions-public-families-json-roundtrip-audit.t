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

subtest 'manifest-embedded typed extensions public key and name families survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{typed_extensions};
    my $expected = build_extension_contract();
    is_deeply($contract->{'public_top_level_presence_keys'}, $expected->{'public_top_level_presence_keys'}, 'decoded manifest typed extension contract keeps public_top_level_presence_keys');
    is_deeply($contract->{'hook_names'}, $expected->{'hook_names'}, 'decoded manifest typed extension contract keeps hook_names');
    is_deeply($contract->{'context_accessors'}, $expected->{'context_accessors'}, 'decoded manifest typed extension contract keeps context_accessors');
    is_deeply($contract->{'name_family_map'}, $expected->{'name_family_map'}, 'decoded manifest typed extension contract keeps name_family_map');
    is_deeply($contract->{'supported_source_kinds'}, $expected->{'supported_source_kinds'}, 'decoded manifest typed extension contract keeps supported_source_kinds');
};
done_testing();
