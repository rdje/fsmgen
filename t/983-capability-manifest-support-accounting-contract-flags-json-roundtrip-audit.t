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

subtest 'manifest support accounting contract derived catalog flags survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{support_accounting}{section_contract};
    my $expected = build_support_accounting_contract();
    is($contract->{'sanitized_catalog_entries'} ? 1 : 0, $expected->{'sanitized_catalog_entries'} ? 1 : 0, 'decoded manifest support accounting contract keeps sanitized_catalog_entries');
    is($contract->{'derived_from_regression_corpus'} ? 1 : 0, $expected->{'derived_from_regression_corpus'} ? 1 : 0, 'decoded manifest support accounting contract keeps derived_from_regression_corpus');
};
done_testing();
