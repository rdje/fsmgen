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

subtest 'manifest support accounting contract presence key family map survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{support_accounting}{section_contract};
    my $expected = build_support_accounting_contract();
    is_deeply($contract->{'presence_key_family_map'}, $expected->{'presence_key_family_map'}, 'decoded manifest support accounting contract keeps presence_key_family_map');
};
done_testing();
