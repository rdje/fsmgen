#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my %backlog_by_page = map {
    $_ => slurp(File::Spec->catfile($repo_root, 'docs', 'book', 'src', $_))
} qw(
    14a-language-and-data.md
    14k-isf-language-and-scheduling.md
);

my %expected_status = (
    'Automatic Aggregate Growth From Usage' => [
        '14a-language-and-data.md',
        'partially shipped; broader inference surfaces remain backlog.',
    ],
    'Backend-Owned Struct/Record Default Lowering' => [
        '14a-language-and-data.md',
        'partially shipped; broader default-lowering policy remains backlog.',
    ],
    'Bounded-Eventually Monitor Lowering' => [
        '14k-isf-language-and-scheduling.md',
        'shipped (the bounded-eventually subset); broader temporal forms remain backlog.',
    ],
    'Fully Frozen Schedule JSON Schema' => [
        '14k-isf-language-and-scheduling.md',
        'shipped for schedule JSON `schema_version: 1`.',
    ],
    'ISF Reusable Libraries' => [
        '14k-isf-language-and-scheduling.md',
        'shipped bounded actor-library surface; broader surfaces remain backlog.',
    ],
    'ISF Multi-Clock And CDC Semantics' => [
        '14k-isf-language-and-scheduling.md',
        'shipped first acknowledged-event CDC primitive; richer CDC remains backlog.',
    ],
);

for my $heading (sort keys %expected_status) {
    my ($page, $expected) = @{$expected_status{$heading}};
    my $backlog = $backlog_by_page{$page};
    my $section = section_for($backlog, $heading);
    ok(defined $section, "feature backlog has '$heading' section");

    my ($status) = defined $section ? ($section =~ m{^Status: (.+)$}m) : ();
    is($status, $expected, "$heading status is current");
}

for my $heading (
    'Automatic Aggregate Growth From Usage',
    'Backend-Owned Struct/Record Default Lowering',
) {
    my ($page) = @{$expected_status{$heading}};
    my $section = section_for($backlog_by_page{$page}, $heading);
    unlike(
        $section || '',
        qr{schedule JSON `schema_version: 1`},
        "$heading does not inherit schedule-report freeze wording",
    );
}

unlike(
    join("\n", values %backlog_by_page),
    qr{^Status: active (?:feature|task) tree under$}m,
    'closed task trees are not advertised as active feature-backlog status',
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
