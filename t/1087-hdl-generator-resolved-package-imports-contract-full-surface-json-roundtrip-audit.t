#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::HDLGeneratorResolvedPackageImportsContract qw(build_hdl_generator_resolved_package_imports_contract);

subtest 'resolved package imports contract full surface survives JSON round trip' => sub {
    my $contract = build_hdl_generator_resolved_package_imports_contract();
    my $decoded = decode_json(encode_json($contract));
    is_deeply($decoded, $contract, 'decoded resolved package imports contract matches owner');
};

done_testing();
