#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $spec_path = File::Spec->catfile($repo_root, 'docs', 'ISF_SPEC.md');

open my $spec_fh, '<', $spec_path
    or die "Unable to read $spec_path: $!";
my $spec = do { local $/; <$spec_fh> };
close $spec_fh;

my ($focused_tests_section) = $spec =~ m{\nFocused tests:\n(.*?)\n## 12\. Explicitly Deferred}s;
ok(defined $focused_tests_section, 'ISF spec exposes the focused tests section');

my @listed_tests = $focused_tests_section
    ? ($focused_tests_section =~ m{\]\(\.\./(t/[0-9]+-isf-[^)]+\.t)\)}g)
    : ();

my $test_glob = File::Spec->catfile($repo_root, 't', '*-isf-*.t');
my @expected_tests = map {
    my $path = File::Spec->abs2rel($_, $repo_root);
    $path =~ s{\\}{/}g;
    $path;
} sort glob($test_glob);

is_deeply(
    \@listed_tests,
    \@expected_tests,
    'ISF spec focused tests list is synchronized with t/*-isf-*.t',
);

done_testing();
