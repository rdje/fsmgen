#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

my $repo_root = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));

my @loop_docs = qw(
    docs/ISF_SPEC.md
    docs/book/src/14-feature-backlog.md
    docs/book/src/13b-transactions.md
);

for my $path (@loop_docs) {
    my $content = read_repo_file($path);
    like(
        $content,
        qr/named drive[s ]+.*`await`.*`sample`.*`update`.*`set`.*store.*load.*wait/s,
        "$path lists set in the shipped loop-body inline subset",
    );
    like(
        $content,
        qr/`do`,\s+`spawn`,\s+`await_all`,\s+`await_any`,\s+`stage`,\s+`contract`/s,
        "$path keeps child, await-sync, stage, and contract loop-body deferrals",
    );
}

done_testing();

sub read_repo_file {
    my ($relpath) = @_;
    my $path = File::Spec->catfile($repo_root, split m{/}, $relpath);
    open my $fh, '<', $path or die "Unable to read $path: $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    return $content;
}
