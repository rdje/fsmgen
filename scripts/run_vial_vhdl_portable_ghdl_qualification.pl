#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use FindBin;
use Getopt::Long qw(GetOptions);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::VHDLPortableGHDLQualification;

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $provider_root = FSM::VIAL::Backend::VHDLPortableGHDLQualification
    ->default_provider_root;
my $output = 'vial/qualification/vhdl_portable_ghdl/ghdl-6.0.0-qualification.json';
my $check = 0;
GetOptions(
    'provider-root=s' => \$provider_root,
    'output=s' => \$output,
    'check' => \$check,
) or die "invalid qualification option\n";
die "qualification output must be repository-relative\n"
    if $output =~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\)}
        || grep { $_ eq '' || $_ eq '.' || $_ eq '..' } split m{/}, $output, -1;

my $result = FSM::VIAL::Backend::VHDLPortableGHDLQualification->qualify({
    repo_root => $repo_root,
    provider_root => $provider_root,
});
die "$result->{diagnostics}[0]{code}: $result->{diagnostics}[0]{message}\n"
    unless $result->{ok};

my $output_abs = File::Spec->catfile($repo_root, split m{/}, $output);
if ($check) {
    open my $fh, '<:raw', $output_abs
        or die "cannot read checked qualification report '$output'\n";
    local $/;
    my $checked = <$fh>;
    close $fh;
    die "checked qualification report differs from the exact rerun\n"
        unless $checked eq $result->{content};
    print "qualified and matched $output\n";
    exit 0;
}

make_path(dirname($output_abs));
open my $fh, '>:raw', $output_abs
    or die "cannot write qualification report '$output'\n";
print {$fh} $result->{content}
    or die "cannot populate qualification report '$output'\n";
close $fh
    or die "cannot close qualification report '$output'\n";
print "qualified and wrote $output\n";
