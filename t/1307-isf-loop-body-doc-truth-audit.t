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
        qr/`do`.*`spawn`.*`await_all`.*`await_any`.*`stage`.*`contract`/s,
        "$path keeps while/until child, await-sync, stage, and contract loop-body deferrals",
    );
    like(
        $content,
        qr/repeat(?:-body| body).*spawn.*(?:same-body|same repeat body).*await_all/s,
        "$path documents the shipped repeat-body spawn plus same-body await_all subset",
    );
    like(
        $content,
        qr/repeat(?:-body| body).*spawn.*params/s,
        "$path documents the shipped repeat-body spawn static params subset",
    );
    like(
        $content,
        qr/repeat(?:-body| body).*spawn.*domain/s,
        "$path documents the shipped repeat-body spawn same-domain metadata subset",
    );
    like(
        $content,
        qr/repeat(?:-body| body).*spawn.*await_any/s,
        "$path documents the shipped repeat-body single-pending await_any subset",
    );
    like(
        $content,
        qr/repeat(?:-body| body).*local.*do/s,
        "$path documents the shipped repeat-body local do subset",
    );
    like(
        $content,
        qr/repeat(?:-body| body).*generated.*do.*params/s,
        "$path documents the shipped repeat-body generated do static-parameter subset",
    );
    like(
        $content,
        qr/repeat(?:-body| body).*generated.*do.*bind/s,
        "$path documents the shipped repeat-body generated do binding subset",
    );
    like(
        $content,
        qr/repeat(?:-body| body).*sample.*spawn.*sync/s,
        "$path documents the shipped repeat-body sample-after-spawn timing",
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
