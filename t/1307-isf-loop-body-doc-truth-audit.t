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
        qr/repeat(?:-body| body).*generated-child.*do/s,
        "$path documents the shipped repeat-body generated-child do subset",
    );
    like(
        $content,
        qr/repeat(?:-body| body).*generated.*do.*bind/s,
        "$path documents the shipped repeat-body generated do binding subset",
    );
    like(
        $content,
        qr/repeat(?:-body| body).*generated.*do.*domain/s,
        "$path documents the shipped repeat-body generated do same-domain metadata subset",
    );
    like(
        $content,
        qr/repeat(?:-body| body).*sample.*spawn.*sync/s,
        "$path documents the shipped repeat-body sample/spawn timing",
    );
    like(
        $content,
        qr/repeat(?:-body| body).*sample.*do.*repeat check/s,
        "$path documents the shipped repeat-body sample/do timing",
    );
    like(
        $content,
        qr/(?:repeat(?:-body| body).*multi-pending|multi-pending.*repeat(?:-body| body)).*await_any.*await_all.*drain/si,
        "$path documents the shipped repeat-body multi-pending await_any drain",
    );
    like(
        $content,
        qr/(?:top-level\s+when-body\s+nested\s+repeat\s+local\s+`?\(do child\)`?|repeat(?:-body| body).*top-level\s+`?when`?\s+body.*local.*do)/si,
        "$path documents the shipped top-level when-body nested repeat local do subset",
    );
    like(
        $content,
        qr/top-level\s+`?when`?\s+body.*nested\s+repeat.*spawn.*await_all/si,
        "$path documents the shipped top-level when-body nested repeat spawn await_all subset",
    );
    like(
        $content,
        qr/top-level\s+`?when`?\s+body.*nested\s+repeat.*(?:multiple|one or more|generated spawns).*await_all/si,
        "$path documents the shipped top-level when-body nested repeat multiple-spawn await_all subset",
    );
    like(
        $content,
        qr/top-level\s+`?when`?\s+body.*nested\s+repeat.*spawn.*await_any/si,
        "$path documents the shipped top-level when-body nested repeat spawn await_any subset",
    );
    like(
        $content,
        qr/top-level\s+`?when`?\s+body.*nested\s+repeat.*multi-pending.*await_any.*await_all.*drain/si,
        "$path documents the shipped top-level when-body nested repeat multi-pending await_any drain subset",
    );
    like(
        $content,
        qr/top-level\s+`?when`?\s+body.*nested[-\s]+repeats?.*local.*do.*generated(?:\s+nested)?\s+spawn.*pending.*await_all.*drain/si,
        "$path documents the shipped top-level when-body nested repeat local do while generated spawn pending subset",
    );
    like(
        $content,
        qr/top-level\s+`?when`?\s+body.*nested[-\s]+repeats?.*generated-child.*do.*generated(?:\s+nested)?\s+spawn.*pending.*await_all.*drain/si,
        "$path documents the shipped top-level when-body nested repeat generated-child do while generated spawn pending subset",
    );
    like(
        $content,
        qr/top-level\s+`?when`?\s+body.*nested[-\s]+repeats?.*generated.*do.*static(?:[-\s]+parameter| params).*generated(?:\s+nested)?\s+spawn.*pending.*await_all.*drain/si,
        "$path documents the shipped top-level when-body nested repeat generated static-parameter do while generated spawn pending subset",
    );
    like(
        $content,
        qr/top-level\s+`?when`?\s+body.*nested[-\s]+repeats?.*generated.*do.*static(?:[-\s]+parameter| params).*bind.*generated(?:\s+nested)?\s+spawn.*pending.*await_all.*drain/si,
        "$path documents the shipped top-level when-body nested repeat generated static-parameter bound do while generated spawn pending subset",
    );
    like(
        $content,
        qr/top-level\s+`?switch`?\s+branch.*nested\s+repeat.*spawn.*await_all/si,
        "$path documents the shipped top-level switch-branch nested repeat spawn await_all subset",
    );
    like(
        $content,
        qr/top-level\s+`?switch`?\s+branch.*nested\s+repeat.*(?:multiple|one or more|generated spawns).*await_all/si,
        "$path documents the shipped top-level switch-branch nested repeat multiple-spawn await_all subset",
    );
    like(
        $content,
        qr/top-level\s+`?switch`?\s+branch.*nested\s+repeat.*spawn.*await_any/si,
        "$path documents the shipped top-level switch-branch nested repeat spawn await_any subset",
    );
    like(
        $content,
        qr/top-level\s+`?switch`?\s+branch.*nested\s+repeat.*multi-pending.*await_any.*await_all.*drain/si,
        "$path documents the shipped top-level switch-branch nested repeat multi-pending await_any drain subset",
    );
    like(
        $content,
        qr/top-level\s+`?switch`?\s+branch.*nested[-\s]+repeats?.*local.*do.*generated(?:\s+nested)?\s+spawn.*pending.*await_all.*drain/si,
        "$path documents the shipped top-level switch-branch nested repeat local do while generated spawn pending subset",
    );
    like(
        $content,
        qr/top-level\s+`?switch`?\s+branch.*nested[-\s]+repeats?.*generated-child.*do.*generated(?:\s+nested)?\s+spawn.*pending.*await_all.*drain/si,
        "$path documents the shipped top-level switch-branch nested repeat generated-child do while generated spawn pending subset",
    );
    like(
        $content,
        qr/top-level\s+`?switch`?\s+branch.*nested[-\s]+repeats?.*generated.*do.*static(?:[-\s]+parameter| params).*generated(?:\s+nested)?\s+spawn.*pending.*await_all.*drain/si,
        "$path documents the shipped top-level switch-branch nested repeat generated static-parameter do while generated spawn pending subset",
    );
    like(
        $content,
        qr/(?:top-level\s+switch-branch\s+nested\s+repeat\s+local\s+`?\(do child\)`?|repeat(?:-body| body).*top-level\s+`?switch`?\s+branch.*local.*do)/si,
        "$path documents the shipped top-level switch-branch nested repeat local do subset",
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
