#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

my $backlog_path = File::Spec->catfile(
    $repo_root, 'docs', 'book', 'src', '14-feature-backlog.md',
);
my $proposal_path = File::Spec->catfile(
    $repo_root, 'docs', 'ISF_ATL_DESIGN_PROPOSAL.md',
);
my $backlog = slurp($backlog_path);
my $proposal = slurp($proposal_path);

my $atl_section = section_for($backlog, 'Actor Network Orchestration');
ok(defined $atl_section, 'feature backlog has Actor Network Orchestration section');

my ($status) = defined $atl_section ? ($atl_section =~ m{^Status: (.+)$}m) : ();
is(
    $status,
    'shipped bounded ATL v0 public contract; broader ATL remains backlog.',
    'ATL feature-backlog status reflects closed tree and remaining backlog',
);

unlike(
    $atl_section || '',
    qr{active ATL design tree},
    'ATL feature-backlog section does not claim an active design tree',
);

like(
    $proposal,
    qr{^Status: closed ATL v0 design tree; bounded public contract partially implemented\.$}m,
    'ATL design proposal status reflects closed design tree',
);

unlike(
    $proposal,
    qr{^Status: active ATL v0 public contract}m,
    'ATL design proposal does not use stale active status wording',
);

unlike(
    $atl_section || '',
    qr{Active R14 ATL axis},
    'canonical feature backlog does not advertise the closed ATL axis as active',
);

done_testing();

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh;
    return $text;
}

sub section_for {
    my ($text, $heading) = @_;
    my ($section) = $text =~ m{^### \Q$heading\E\n(.*?)(?=^### |\z)}ms;
    return $section;
}
