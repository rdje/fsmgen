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

subtest 'manifest-embedded typed extensions tested_by and entrypoint metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{typed_extensions};
    my $expected = build_extension_contract();
    is_deeply($contract->{'tested_by'}, $expected->{'tested_by'}, 'decoded manifest typed extension contract keeps tested_by');
    is_deeply($contract->{'entrypoints'}, $expected->{'entrypoints'}, 'decoded manifest typed extension contract keeps entrypoints');
};
done_testing();
