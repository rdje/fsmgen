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

subtest 'manifest-embedded typed extensions extension object and loader shapes survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{typed_extensions};
    my $expected = build_extension_contract();
    is_deeply($contract->{'extension_object_contract'}, $expected->{'extension_object_contract'}, 'decoded manifest typed extension contract keeps extension_object_contract');
};
done_testing();
