#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

my @docs = (
    'docs/book/src/13b-transactions.md',
    'docs/book/src/13d-control-flow.md',
    'docs/ISF_SPEC.md',
    'docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md',
    'docs/ISF_PUBLIC_INTERFACE_CONTRACT.md',
);

my @shipped_terms = qw(
    drive
    await
    sample
    update
    set
    shift_left
    shift_right
    assemble
    extract
    store
    load
    wait
);

my @deferred_terms = qw(
    do
    spawn
    await_all
    await_any
    stage
    contract
    while
    until
);

for my $path (@docs) {
    my $text = read_repo_file($path);
    my $section = repeat_body_truth_section($text);

    ok(defined $section, "$path carries the repeat-body shipped-subset marker");
    next unless defined $section;

    for my $term (@shipped_terms) {
        like($section, qr/\Q$term\E/, "$path repeat-body section names shipped '$term'");
    }

    for my $term (@deferred_terms) {
        like($section, qr/\Q$term\E/, "$path repeat-body section names deferred '$term'");
    }
}

done_testing();

sub repeat_body_truth_section {
    my ($text) = @_;
    my ($section) = $text =~ m{
        (The\s+shipped\s+repeat-body\s+clause\s+surface\s+is.*?
        outside\s+the\s+shipped\s+repeat-body\s+subset\.)
    }sx;
    return $section;
}

sub read_repo_file {
    my ($relpath) = @_;
    my $path = File::Spec->catfile($repo_root, split m{/}, $relpath);
    open my $fh, '<', $path
        or die "Unable to read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh;
    return $text;
}
