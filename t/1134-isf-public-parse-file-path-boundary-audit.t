#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Support::ISFPublicInterfaceContract qw(build_isf_public_interface_contract);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $valid_isf = repo_file('isf/apb_requester.isf');

subtest 'contract advertises parse_file path requirement' => sub {
    my $contract = build_isf_public_interface_contract();

    is(
        $contract->{parse_file_path_requirement},
        'defined scalar path with .isf suffix naming a readable regular file before private parsing',
        'contract advertises parse_file path requirement',
    );
    ok(
        key_list_contains($contract->{public_top_level_presence_keys}, 'parse_file_path_requirement'),
        'parse_file path requirement is part of the public contract surface',
    );
};

subtest 'parse_file accepts readable .isf files and rejects invalid paths before private parsing' => sub {
    my $adapter = FSM::Adapter::ISF->new();

    my $actor = $adapter->parse_file($valid_isf);
    is($actor->{actor_name}, 'apb_requester', 'parse_file accepts a readable .isf file');

    for my $case (
        ['missing .isf file', repo_file('isf/__missing_parse_file_boundary__.isf')],
        ['directory path',    repo_file('isf')],
        ['wrong extension',   repo_file('README.md')],
    ) {
        my ($label, $path) = @$case;
        assert_rejects(
            sub { $adapter->parse_file($path) },
            qr/\QFSM::Adapter::ISF->parse_file argument 1 must name a readable .isf file\E/,
            "parse_file rejects $label",
        );
    }
};

done_testing();

sub assert_rejects {
    my ($code, $pattern, $label) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok, $label);
    like($@, $pattern, "$label diagnostic");
}

sub repo_file {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
}

sub key_list_contains {
    my ($keys, $needle) = @_;
    return scalar grep { $_ eq $needle } @{$keys || []};
}
