#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SupportAccountingContract qw(build_support_accounting_contract);

subtest 'manifest support accounting contract entrypoint metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{support_accounting}{section_contract};
    my $expected = build_support_accounting_contract();
    is_deeply($contract->{'entrypoints'}, $expected->{'entrypoints'}, 'decoded manifest support accounting contract keeps entrypoints');
};
done_testing();
