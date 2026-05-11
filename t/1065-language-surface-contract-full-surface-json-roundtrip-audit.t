#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::LanguageSurfaceContract qw(build_language_surface_contract);

subtest 'language surface contract full surface survives JSON round trip' => sub {
    my $contract = build_language_surface_contract();
    my $decoded = decode_json(encode_json($contract));
    is_deeply($decoded, $contract, 'decoded language surface contract matches owner contract');
};

done_testing();
