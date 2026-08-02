#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use FindBin;
use JSON::PP ();

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::VHDLPortableGHDL;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

die "usage: perl scripts/refresh_vial_vhdl_foundation_gallery.pl [--check]\n"
    unless @ARGV <= 1 && (!@ARGV || $ARGV[0] eq '--check');
my $check_only = @ARGV && $ARGV[0] eq '--check';

my $repo_root = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $vial_id = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
my $profile = 'vhdl_portable_ghdl';
my $backend_prefix = "backends/$profile/";
my $gallery_rel = 'vial/review_gallery/vhdl_portable_ghdl/ahb_base_output_foundation';
my $gallery_root = _repo_path(split m{/}, $gallery_rel);

my $semantic_ir = FSM::VIAL::Parser->parse_source({
    text => _slurp($vial_id),
    source_name => $vial_id,
    source_catalog => {},
});
my $built = FSM::VIAL::PlanBuilder->build({
    semantic_ir => $semantic_ir,
    hial_source => {
        source_id => $hial_id,
        text => _slurp($hial_id),
        format => 'ppif',
    },
    fixture_id => undef,
    scenario_ids => [],
    execution_profile => 'core_directed_single_clock_execution_v1',
    replay_manifest => undef,
    native_extension_catalog => [],
});
die 'cannot build portable VHDL gallery plan: '
    . JSON::PP->new->canonical(1)->encode($built->{diagnostics}) . "\n"
    unless $built->{ok};

my $emission = FSM::VIAL::Backend::VHDLPortableGHDL->emit({
    execution_ir => $built->{execution_ir},
    bridge_manifest => $built->{bridge_manifest},
    backend_inputs => $built->{backend_inputs},
    artifact_root => '.artifacts/gallery/vial-vhdl-foundation',
    backend_profile => $profile,
});
die 'cannot emit portable VHDL gallery: '
    . JSON::PP->new->canonical(1)->encode($emission->{diagnostics}) . "\n"
    unless $emission->{ok};

my %expected;
for my $artifact (@{$emission->{artifacts}}) {
    my $relpath = $artifact->{relpath};
    die "emitted gallery artifact is outside $backend_prefix: $relpath\n"
        unless index($relpath, $backend_prefix) == 0;
    my $gallery_path = substr($relpath, length($backend_prefix));
    $expected{$gallery_path} = $artifact->{content};
}

for my $relpath (sort keys %expected) {
    my $path = File::Spec->catfile($gallery_root, split m{/}, $relpath);
    if ($check_only) {
        die "portable VHDL gallery snapshot is missing: $gallery_rel/$relpath\n"
            unless -f $path;
        die "portable VHDL gallery snapshot has byte drift: $gallery_rel/$relpath\n"
            unless _slurp_path($path, "$gallery_rel/$relpath") eq $expected{$relpath};
    }
    else {
        make_path(dirname($path));
        open my $fh, '>:raw', $path
            or die "cannot write $gallery_rel/$relpath: $!\n";
        print {$fh} $expected{$relpath}
            or die "cannot write bytes to $gallery_rel/$relpath: $!\n";
        close $fh or die "cannot close $gallery_rel/$relpath: $!\n";
    }
}

if ($check_only) {
    die "portable VHDL gallery review guide is missing: $gallery_rel/README.md\n"
        unless -f File::Spec->catfile($gallery_root, 'README.md');
    my @actual = _walk_files($gallery_root, '');
    my %allowed = map { $_ => 1 } ('README.md', keys %expected);
    my @extra = grep { !$allowed{$_} } @actual;
    die "portable VHDL gallery has unexpected file: $gallery_rel/$extra[0]\n"
        if @extra;
}

print(($check_only ? 'portable VHDL foundation gallery current: ' : 'refreshed '),
    scalar(grep { /\.vhd\z/ } keys %expected), ' VHDL sources; ',
    scalar(keys(%expected)) - scalar(grep { /\.vhd\z/ } keys %expected),
    ' evidence artifacts; ', scalar(@{$emission->{source_map}{entries}}),
    ' source-map entries; ', scalar(@{$emission->{static_validation}{checks}}),
    " static checks\n");

sub _walk_files {
    my ($root, $relative) = @_;
    my $path = length($relative)
        ? File::Spec->catdir($root, split m{/}, $relative)
        : $root;
    opendir my $dh, $path or die "cannot inspect $path: $!\n";
    my @name = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh or die "cannot close $path: $!\n";
    my @files;
    for my $name (@name) {
        my $rel = length($relative) ? "$relative/$name" : $name;
        my $entry = File::Spec->catfile($path, $name);
        push @files, -d $entry ? _walk_files($root, $rel) : $rel;
    }
    return @files;
}

sub _slurp {
    my ($relpath) = @_;
    return _slurp_path(_repo_path(split m{/}, $relpath), $relpath);
}

sub _slurp_path {
    my ($path, $label) = @_;
    open my $fh, '<:raw', $path or die "cannot read $label: $!\n";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $label: $!\n";
    return $text;
}

sub _repo_path {
    return File::Spec->catfile($repo_root, @_);
}
