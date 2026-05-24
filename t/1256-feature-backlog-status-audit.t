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

open my $backlog_fh, '<', $backlog_path
    or die "Unable to read $backlog_path: $!";
my $backlog = do { local $/; <$backlog_fh> };
close $backlog_fh;

my %expected_status = (
    'Automatic Aggregate Growth From Usage' =>
        'partially shipped; broader inference surfaces remain backlog.',
    'Backend-Owned Struct/Record Default Lowering' => 'backlog.',
    'Temporal Contract Lowering' =>
        'partially shipped; broader contract forms remain backlog.',
    'Fully Frozen Schedule JSON Schema' =>
        'shipped for schedule JSON `schema_version: 1`.',
    'ISF Reusable Libraries' =>
        'shipped bounded actor-library surface; broader surfaces remain backlog.',
    'ISF Multi-Clock And CDC Semantics' =>
        'shipped first acknowledged-event CDC primitive; richer CDC remains backlog.',
);

for my $heading (sort keys %expected_status) {
    my $section = section_for($backlog, $heading);
    ok(defined $section, "feature backlog has '$heading' section");

    my ($status) = defined $section ? ($section =~ m{^Status: (.+)$}m) : ();
    is($status, $expected_status{$heading}, "$heading status is current");
}

for my $heading (
    'Automatic Aggregate Growth From Usage',
    'Backend-Owned Struct/Record Default Lowering',
) {
    my $section = section_for($backlog, $heading);
    unlike(
        $section || '',
        qr{schedule JSON `schema_version: 1`},
        "$heading does not inherit schedule-report freeze wording",
    );
}

unlike(
    $backlog,
    qr{^Status: active (?:feature|task) tree under$}m,
    'closed task trees are not advertised as active feature-backlog status',
);

done_testing();

sub section_for {
    my ($text, $heading) = @_;
    my ($section) = $text =~ m{^### \Q$heading\E\n(.*?)(?=^### |\z)}ms;
    return $section;
}
