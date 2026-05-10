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

subtest 'manifest-embedded typed extensions after_parse_source hook metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{typed_extensions};
    my $expected = build_extension_contract();
    is_deeply($contract->{'hooks'}, $expected->{'hooks'}, 'decoded manifest typed extension contract keeps hooks');
    is_deeply($contract->{hooks}{after_parse_source}, $expected->{hooks}{after_parse_source}, 'decoded manifest typed extension contract keeps after_parse_source hook');
};
done_testing();
