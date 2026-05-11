#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::SupportAccountingContract qw(build_support_accounting_contract);

subtest 'support accounting contract full surface survives JSON round trip' => sub {
    my $contract = build_support_accounting_contract();
    my $decoded = decode_json(encode_json($contract));
    is_deeply($decoded, $contract, 'decoded support accounting contract matches direct owner contract');
};

done_testing();
