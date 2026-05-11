#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::ReportCommandContract qw(build_report_command_contract);

subtest 'report command contract full surface survives JSON round trip' => sub {
    my $contract = build_report_command_contract();
    my $decoded = decode_json(encode_json($contract));
    is_deeply($decoded, $contract, 'decoded report command contract matches owner contract');
};

done_testing();
