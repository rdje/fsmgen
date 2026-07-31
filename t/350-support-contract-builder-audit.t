#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

my $support_dir = File::Spec->catdir($FindBin::Bin, '..', 'perl', 'FSM', 'Support');
my @contract_files = sort glob(File::Spec->catfile($support_dir, '*Contract.pm'));

ok(@contract_files, 'support contract audit found contract modules to inspect');

my %allowed_status = map { $_ => 1 } qw(
    bounded_public
    bounded_public_json_fragment
    bounded_top_level_presence
    optional_when_tools_installed
    shipped_private_in_process
    shipped_private_target_neutral_no_backend
);

for my $file (@contract_files) {
    my $module = _module_name_from_file($file);

    subtest $module => sub {
        require_ok($module);

        no strict 'refs';
        my @exports = @{"${module}::EXPORT_OK"};
        my @builders = grep { /^build_.*_contract$/ } @exports;
        use strict 'refs';

        is(
            scalar(@builders),
            1,
            "$module exports exactly one build_*_contract helper",
        );

        my $builder_name = $builders[0];
        ok(defined($builder_name), "$module exposes a build_*_contract helper")
            or return;

        no strict 'refs';
        my $builder = \&{"${module}::$builder_name"};
        use strict 'refs';

        my $contract = $builder->();
        is(ref($contract), 'HASH', "$module builder returns a hashref");
        is($contract->{schema_version}, 1, "$module contract keeps schema_version at 1");
        ok(
            defined($contract->{status}) && $allowed_status{$contract->{status}},
            "$module contract uses an allowed status value",
        );
        is(
            $contract->{contract_source},
            $module,
            "$module contract_source points back to its canonical owner",
        );
        ok(
            ref($contract->{guidance}) eq 'ARRAY' && @{$contract->{guidance}},
            "$module contract keeps non-empty guidance",
        );
    };
}

done_testing();

sub _module_name_from_file {
    my ($file) = @_;
    my $base = File::Spec->abs2rel($file, File::Spec->catdir($FindBin::Bin, '..', 'perl'));
    $base =~ s{\.pm$}{};
    $base =~ s{[/\\]}{::}g;
    return $base;
}
