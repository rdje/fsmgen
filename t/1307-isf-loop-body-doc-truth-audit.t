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
    ok(
        documents_branch_await_any_before_do($content, 'when', qr/\blocal\b/, qr/\bdo\b/),
        "$path documents the shipped top-level when-body nested repeat local do after multi-pending await_any subset",
    );
    ok(
        documents_branch_prior_await_any_do_then_spawn($content, 'when', qr/\blocal\b/, qr/\bdo\b/),
        "$path documents the shipped top-level when-body nested repeat local do after multi-pending await_any then generated spawn subset",
    );
    ok(
        documents_branch_prior_await_any_local_do_then_spawn_second_await_any($content, 'when'),
        "$path documents the shipped top-level when-body nested repeat local do after multi-pending await_any then generated spawn and second await_any subset",
    );
    ok(
        documents_branch_post_do_await_any($content, 'when', qr/\blocal\b/, qr/\bdo\b/),
        "$path documents the shipped top-level when-body nested repeat local do before post-do multi-pending await_any subset",
    );
    ok(
        documents_branch_await_any_before_do($content, 'switch', qr/\blocal\b/, qr/\bdo\b/),
        "$path documents the shipped top-level switch-branch nested repeat local do after multi-pending await_any subset",
    );
    ok(
        documents_branch_prior_await_any_do_then_spawn($content, 'switch', qr/\blocal\b/, qr/\bdo\b/),
        "$path documents the shipped top-level switch-branch nested repeat local do after multi-pending await_any then generated spawn subset",
    );
    ok(
        documents_branch_prior_await_any_local_do_then_spawn_second_await_any($content, 'switch'),
        "$path documents the shipped top-level switch-branch nested repeat local do after multi-pending await_any then generated spawn and second await_any subset",
    );
    ok(
        documents_branch_post_do_await_any($content, 'switch', qr/\blocal\b/, qr/\bdo\b/),
        "$path documents the shipped top-level switch-branch nested repeat local do before post-do multi-pending await_any subset",
    );
    like(
        $content,
        qr/top-level\s+`?when`?\s+body.*nested[-\s]+repeats?.*generated-child.*do.*generated(?:\s+nested)?\s+spawn.*pending.*await_all.*drain/si,
        "$path documents the shipped top-level when-body nested repeat generated-child do while generated spawn pending subset",
    );
    ok(
        documents_branch_await_any_before_do($content, 'when', qr/generated-child/, qr/\bdo\b/),
        "$path documents the shipped top-level when-body nested repeat generated-child do after multi-pending await_any subset",
    );
    ok(
        documents_branch_prior_await_any_do_then_spawn($content, 'when', qr/generated-child/, qr/\bdo\b/),
        "$path documents the shipped top-level when-body nested repeat generated-child do after multi-pending await_any then generated spawn subset",
    );
    ok(
        documents_branch_prior_await_any_generated_child_do_then_spawn_second_await_any($content, 'when'),
        "$path documents the shipped top-level when-body nested repeat generated-child do after multi-pending await_any then generated spawn and second await_any subset",
    );
    ok(
        documents_branch_post_do_await_any($content, 'when', qr/generated-child/, qr/\bdo\b/),
        "$path documents the shipped top-level when-body nested repeat generated-child do before post-do multi-pending await_any subset",
    );
    ok(
        documents_branch_generated_do_pending_spawn(
            $content,
            'when',
            qr/static(?:[-\s]+parameter| params)|\(params \.\.\.\)/,
        ),
        "$path documents the shipped top-level when-body nested repeat generated static-parameter do while generated spawn pending subset",
    );
    ok(
        documents_branch_await_any_before_do($content, 'when', qr/static(?:[-\s]+parameter| params)|\(params \.\.\.\)/, qr/generated/, qr/\bdo\b/),
        "$path documents the shipped top-level when-body nested repeat generated static-parameter do after multi-pending await_any subset",
    );
    ok(
        documents_branch_prior_await_any_do_then_spawn($content, 'when', qr/static(?:[-\s]+parameter| params)|\(params \.\.\.\)/, qr/generated/, qr/\bdo\b/),
        "$path documents the shipped top-level when-body nested repeat generated static-parameter do after multi-pending await_any then generated spawn subset",
    );
    ok(
        documents_branch_post_do_await_any($content, 'when', qr/static(?:[-\s]+parameter| params)|\(params \.\.\.\)/, qr/generated/, qr/\bdo\b/),
        "$path documents the shipped top-level when-body nested repeat generated static-parameter do before post-do multi-pending await_any subset",
    );
    ok(
        documents_when_bound_generated_do_before_post_await_any($content),
        "$path documents the shipped top-level when-body nested repeat generated static-parameter bound do before post-do multi-pending await_any subset",
    );
    ok(
        documents_branch_await_any_before_do($content, 'when', qr/static(?:[-\s]+parameter| params)|\(params \.\.\.\)/, qr/(?:bind|binding|handoff)/, qr/generated/, qr/\bdo\b/),
        "$path documents the shipped top-level when-body nested repeat generated static-parameter bound do after multi-pending await_any subset",
    );
    ok(
        documents_branch_prior_await_any_do_then_spawn($content, 'when', qr/static(?:[-\s]+parameter| params)|\(params \.\.\.\)/, qr/(?:bind|binding|handoff)/, qr/generated/, qr/\bdo\b/),
        "$path documents the shipped top-level when-body nested repeat generated static-parameter bound do after multi-pending await_any then generated spawn subset",
    );
    ok(
        documents_branch_generated_do_pending_spawn(
            $content,
            'when',
            qr/static(?:[-\s]+parameter| params)|\(params \.\.\.\)/,
            qr/(?:bind|binding|handoff)/,
        ),
        "$path documents the shipped top-level when-body nested repeat generated static-parameter bound do while generated spawn pending subset",
    );
    like(
        $content,
        qr/(?:same[-\s]+domain|domain NAME)[\s\S]{0,1200}generated(?:\s+nested)?\s+spawns?[\s\S]{0,800}pending[\s\S]{0,800}await_all[\s\S]{0,300}drain/i,
        "$path documents the shipped top-level when-body nested repeat generated static-parameter same-domain do while generated spawn pending subset",
    );
    ok(
        documents_branch_await_any_before_do($content, 'when', qr/(?:same[-\s]+domain|domain name)/, qr/generated/, qr/\bdo\b/),
        "$path documents the shipped top-level when-body nested repeat generated static-parameter same-domain do after multi-pending await_any subset",
    );
    ok(
        documents_branch_prior_await_any_do_then_spawn($content, 'when', qr/(?:same[-\s]+domain|domain name)/, qr/generated/, qr/\bdo\b/),
        "$path documents the shipped top-level when-body nested repeat generated static-parameter same-domain do after multi-pending await_any then generated spawn subset",
    );
    like(
        $content,
        qr/switch(?:`|\s|-|branch)[\s\S]{0,1600}(?:same[-\s]+domain|domain NAME)[\s\S]{0,1200}generated(?:\s+nested)?\s+spawns?[\s\S]{0,800}pending[\s\S]{0,800}await_all[\s\S]{0,300}drain/i,
        "$path documents the shipped top-level switch-branch nested repeat generated static-parameter same-domain do while generated spawn pending subset",
    );
    ok(
        documents_branch_await_any_before_do($content, 'switch', qr/(?:same[-\s]+domain|domain name)/, qr/generated/, qr/\bdo\b/),
        "$path documents the shipped top-level switch-branch nested repeat generated static-parameter same-domain do after multi-pending await_any subset",
    );
    ok(
        documents_branch_prior_await_any_do_then_spawn($content, 'switch', qr/(?:same[-\s]+domain|domain name)/, qr/generated/, qr/\bdo\b/),
        "$path documents the shipped top-level switch-branch nested repeat generated static-parameter same-domain do after multi-pending await_any then generated spawn subset",
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
    ok(
        documents_branch_await_any_before_do($content, 'switch', qr/generated-child/, qr/\bdo\b/),
        "$path documents the shipped top-level switch-branch nested repeat generated-child do after multi-pending await_any subset",
    );
    ok(
        documents_branch_prior_await_any_do_then_spawn($content, 'switch', qr/generated-child/, qr/\bdo\b/),
        "$path documents the shipped top-level switch-branch nested repeat generated-child do after multi-pending await_any then generated spawn subset",
    );
    ok(
        documents_branch_prior_await_any_generated_child_do_then_spawn_second_await_any($content, 'switch'),
        "$path documents the shipped top-level switch-branch nested repeat generated-child do after multi-pending await_any then generated spawn and second await_any subset",
    );
    ok(
        documents_branch_post_do_await_any($content, 'switch', qr/generated-child/, qr/\bdo\b/),
        "$path documents the shipped top-level switch-branch nested repeat generated-child do before post-do multi-pending await_any subset",
    );
    ok(
        documents_branch_generated_do_pending_spawn(
            $content,
            'switch',
            qr/static(?:[-\s]+parameter| params)|\(params \.\.\.\)/,
        ),
        "$path documents the shipped top-level switch-branch nested repeat generated static-parameter do while generated spawn pending subset",
    );
    ok(
        documents_branch_await_any_before_do($content, 'switch', qr/static(?:[-\s]+parameter| params)|\(params \.\.\.\)/, qr/generated/, qr/\bdo\b/),
        "$path documents the shipped top-level switch-branch nested repeat generated static-parameter do after multi-pending await_any subset",
    );
    ok(
        documents_branch_prior_await_any_do_then_spawn($content, 'switch', qr/static(?:[-\s]+parameter| params)|\(params \.\.\.\)/, qr/generated/, qr/\bdo\b/),
        "$path documents the shipped top-level switch-branch nested repeat generated static-parameter do after multi-pending await_any then generated spawn subset",
    );
    ok(
        documents_branch_post_do_await_any($content, 'switch', qr/static(?:[-\s]+parameter| params)|\(params \.\.\.\)/, qr/generated/, qr/\bdo\b/),
        "$path documents the shipped top-level switch-branch nested repeat generated static-parameter do before post-do multi-pending await_any subset",
    );
    ok(
        documents_branch_post_do_await_any($content, 'switch', qr/static(?:[-\s]+parameter| params)|\(params \.\.\.\)/, qr/(?:bind|binding|handoff)/, qr/generated/, qr/\bdo\b/),
        "$path documents the shipped top-level switch-branch nested repeat generated static-parameter bound do before post-do multi-pending await_any subset",
    );
    ok(
        documents_branch_await_any_before_do($content, 'switch', qr/static(?:[-\s]+parameter| params)|\(params \.\.\.\)/, qr/(?:bind|binding|handoff)/, qr/generated/, qr/\bdo\b/),
        "$path documents the shipped top-level switch-branch nested repeat generated static-parameter bound do after multi-pending await_any subset",
    );
    ok(
        documents_branch_prior_await_any_do_then_spawn($content, 'switch', qr/static(?:[-\s]+parameter| params)|\(params \.\.\.\)/, qr/(?:bind|binding|handoff)/, qr/generated/, qr/\bdo\b/),
        "$path documents the shipped top-level switch-branch nested repeat generated static-parameter bound do after multi-pending await_any then generated spawn subset",
    );
    ok(
        documents_branch_generated_do_pending_spawn(
            $content,
            'switch',
            qr/static(?:[-\s]+parameter| params)|\(params \.\.\.\)/,
            qr/(?:bind|binding|handoff)/,
        ),
        "$path documents the shipped top-level switch-branch nested repeat generated static-parameter bound do while generated spawn pending subset",
    );
    ok(
        !documents_stale_prior_await_any_spawn_after_do_deferral($content),
        "$path does not re-defer shipped prior-awaitany spawn-after-do subsets",
    );
    ok(
        !documents_stale_local_prior_await_any_second_post_spawn_deferral($content),
        "$path does not re-defer shipped local prior-awaitany second post-spawn await_any subsets",
    );
    ok(
        !documents_stale_generated_child_prior_await_any_second_post_spawn_deferral($content),
        "$path does not re-defer shipped generated-child prior-awaitany second post-spawn await_any subsets",
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

sub documents_when_bound_generated_do_before_post_await_any {
    my ($content) = @_;
    my $normalized = lc $content;
    $normalized =~ s/`//g;

    for my $anchor (
        'top-level when body',
        'when-contained bound generated-do post-do',
    ) {
        my $offset = index($normalized, $anchor);
        while ($offset >= 0) {
            my $window = substr($normalized, $offset, 3200);
            return 1
                if ($window =~ /(?:static[-\s]+parameter|static params|\(params \.\.\.\))/)
                && ($window =~ /(?:bind|binding|handoff)/)
                && index($window, 'post-do') >= 0
                && index($window, 'await_any') >= 0
                && index($window, 'await_all') >= 0
                && index($window, 'drain') >= 0;
            $offset = index($normalized, $anchor, $offset + 1);
        }
    }

    return 0;
}

sub documents_branch_post_do_await_any {
    my ($content, $branch, @markers) = @_;
    my $normalized = lc $content;
    $normalized =~ s/`//g;

    my $anchor = $branch eq 'switch'
        ? 'top-level switch branch'
        : 'top-level when body';
    my $offset = index($normalized, $anchor);
    while ($offset >= 0) {
        my $window = substr($normalized, $offset, 4200);
        my $matches_markers = 1;
        for my $marker (@markers) {
            if ($window !~ $marker) {
                $matches_markers = 0;
                last;
            }
        }
        return 1
            if $matches_markers
            && index($window, 'post-do') >= 0
            && index($window, 'await_any') >= 0
            && index($window, 'await_all') >= 0
            && index($window, 'drain') >= 0
            && index($window, 'pending') >= 0;
        $offset = index($normalized, $anchor, $offset + 1);
    }

    return 0;
}

sub documents_branch_await_any_before_do {
    my ($content, $branch, @markers) = @_;
    my $normalized = lc $content;
    $normalized =~ s/`//g;

    my $anchor = $branch eq 'switch'
        ? 'top-level switch branch'
        : 'top-level when body';
    my $offset = index($normalized, $anchor);
    while ($offset >= 0) {
        my $window = substr($normalized, $offset, 4200);
        my $matches_markers = 1;
        for my $marker (@markers) {
            if ($window !~ $marker) {
                $matches_markers = 0;
                last;
            }
        }
        return 1
            if $matches_markers
            && index($window, 'multi-pending') >= 0
            && index($window, 'await_any') >= 0
            && index($window, 'await_all') >= 0
            && index($window, 'drain') >= 0
            && index($window, 'pending') >= 0;
        $offset = index($normalized, $anchor, $offset + 1);
    }

    return 0;
}

sub documents_branch_prior_await_any_do_then_spawn {
    my ($content, $branch, @markers) = @_;
    my $normalized = lc $content;
    $normalized =~ s/`//g;

    my @anchors = $branch eq 'switch'
        ? (
            'top-level switch branch',
            'top-level switch branches',
            'switch-contained',
            'branch-contained local-do',
            'branch-contained generated-child',
            'branch-contained same-domain',
        )
        : (
            'top-level when body',
            'top-level when bodies',
            'when-contained',
            'branch-contained local-do',
            'branch-contained generated-child',
            'branch-contained same-domain',
        );

    for my $anchor (@anchors) {
        my $offset = index($normalized, $anchor);
        while ($offset >= 0) {
            my $window = substr($normalized, $offset, 7000);
            my $matches_markers = 1;
            for my $marker (@markers) {
                if ($window !~ $marker) {
                    $matches_markers = 0;
                    last;
                }
            }
            return 1
                if $matches_markers
                && ($branch ne 'switch' || index($window, 'switch') >= 0)
                && ($branch ne 'when' || index($window, 'when') >= 0)
                && index($window, 'prior') >= 0
                && index($window, 'multi-pending') >= 0
                && index($window, 'await_any') >= 0
                && $window =~ /later\s+generated(?:\s+nested)?\s+spawns?/
                && index($window, 'await_all') >= 0
                && index($window, 'pre-do') >= 0
                && index($window, 'post-do') >= 0
                && (index($window, 'second') >= 0 || index($window, 'directly') >= 0)
                && index($window, 'fail-closed') >= 0;
            $offset = index($normalized, $anchor, $offset + 1);
        }
    }

    return 0;
}

sub documents_branch_prior_await_any_local_do_then_spawn_second_await_any {
    my ($content, $branch) = @_;
    my $normalized = lc $content;
    $normalized =~ s/`//g;

    my @anchors = $branch eq 'switch'
        ? (
            'top-level switch branch',
            'top-level switch-branch',
            'switch-contained',
            'branch-contained local-do',
        )
        : (
            'top-level when body',
            'top-level when-body',
            'when-contained',
            'branch-contained local-do',
        );

    for my $anchor (@anchors) {
        my $offset = index($normalized, $anchor);
        while ($offset >= 0) {
            my $window = substr($normalized, $offset, 7600);
            return 1
                if ($branch ne 'switch' || index($window, 'switch') >= 0)
                && ($branch ne 'when' || index($window, 'when') >= 0)
                && index($window, 'local') >= 0
                && index($window, 'do') >= 0
                && index($window, 'prior') >= 0
                && index($window, 'multi-pending') >= 0
                && index($window, 'await_any') >= 0
                && $window =~ /later\s+generated(?:\s+nested)?\s+spawns?/
                && index($window, 'second') >= 0
                && index($window, 'post-spawn') >= 0
                && index($window, 'await_all') >= 0
                && index($window, 'pre-do') >= 0
                && index($window, 'post-do') >= 0
                && index($window, 'drain') >= 0;
            $offset = index($normalized, $anchor, $offset + 1);
        }
    }

    return 0;
}

sub documents_branch_prior_await_any_generated_child_do_then_spawn_second_await_any {
    my ($content, $branch) = @_;
    my $normalized = lc $content;
    $normalized =~ s/`//g;

    my @anchors = $branch eq 'switch'
        ? (
            'top-level switch branch',
            'top-level switch-branch',
            'switch-contained',
            'branch-contained plain generated-child',
        )
        : (
            'top-level when body',
            'top-level when-body',
            'when-contained',
            'branch-contained plain generated-child',
        );

    for my $anchor (@anchors) {
        my $offset = index($normalized, $anchor);
        while ($offset >= 0) {
            my $window = substr($normalized, $offset, 8200);
            return 1
                if ($branch ne 'switch' || index($window, 'switch') >= 0)
                && ($branch ne 'when' || index($window, 'when') >= 0)
                && index($window, 'plain generated-child') >= 0
                && index($window, 'do') >= 0
                && index($window, 'prior') >= 0
                && index($window, 'multi-pending') >= 0
                && index($window, 'await_any') >= 0
                && $window =~ /later\s+generated(?:\s+nested)?\s+spawns?/
                && index($window, 'second') >= 0
                && index($window, 'post-spawn') >= 0
                && index($window, 'await_all') >= 0
                && index($window, 'pre-do') >= 0
                && index($window, 'post-do') >= 0
                && index($window, 'drain') >= 0;
            $offset = index($normalized, $anchor, $offset + 1);
        }
    }

    return 0;
}

sub documents_stale_prior_await_any_spawn_after_do_deferral {
    my ($content) = @_;
    my $normalized = lc $content;
    $normalized =~ s/`//g;

    my $offset = index($normalized, 'new nested spawn after generated do');
    while ($offset >= 0) {
        my $window = substr($normalized, $offset, 900);
        return 1
            if index($window, 'multi-pending await_any observation is active before the drain') >= 0
            && (
                index($window, 'after plain generated-child do') >= 0
                || index($window, 'after local do') >= 0
            )
            && index($window, 'remain fail-closed') >= 0;
        $offset = index($normalized, 'new nested spawn after generated do', $offset + 1);
    }

    for my $phrase (
        'prior-active-await_any same-domain generated-do spawn-after-do remains fail-closed',
        'same-domain generated-do active-prior spawn-after-do variants deferred',
        'same-domain generated-do active-prior spawn-after-do variants remain',
        'new nested spawn after same-domain generated do when a multi-pending await_any observation is active before the drain',
        'spawn after same-domain generated do while a multi-pending await_any observation is active before the drain remains fail-closed',
    ) {
        return 1 if index($normalized, $phrase) >= 0;
    }

    return 0;
}

sub documents_stale_local_prior_await_any_second_post_spawn_deferral {
    my ($content) = @_;
    my $normalized = lc $content;
    $normalized =~ s/`//g;

    for my $phrase (
        'those local-do do-then-spawn subsets may also start the later generated spawn after a prior multi-pending await_any observation, provided the local done pulse is observed first and the path advances directly to the mandatory same-body await_all drain; a second await_any after the later spawn remains fail-closed',
        'local-do do-then-spawn subsets may also start the later spawn after the local do follows a prior multi-pending await_any observation, but a second await_any after that later spawn remains fail-closed',
        'in the prior-observation form, that local-do do-then-spawn path advances directly to the mandatory same-body await_all drain and a second multi-pending await_any after the later spawn remains fail-closed',
        'a second post-spawn await_any in local-do prior-observation shapes remains backlog',
    ) {
        return 1 if index($normalized, $phrase) >= 0;
    }

    return 0;
}

sub documents_stale_generated_child_prior_await_any_second_post_spawn_deferral {
    my ($content) = @_;
    my $normalized = lc $content;
    $normalized =~ s/`//g;

    for my $anchor (
        'plain generated-child do may also be followed',
        'plain generated-child do-then-spawn subsets may also start',
        'generated-child do follows a prior multi-pending observation',
    ) {
        my $offset = index($normalized, $anchor);
        while ($offset >= 0) {
            my $window = substr($normalized, $offset, 1400);
            return 1
                if index($window, 'prior') >= 0
                && index($window, 'second') >= 0
                && index($window, 'await_any') >= 0
                && index($window, 'fail-closed') >= 0;
            $offset = index($normalized, $anchor, $offset + 1);
        }
    }

    for my $phrase (
        'a second post-spawn await_any in generated-child prior-observation shapes remains backlog',
        'a second post-spawn await_any in generated-child prior-observation shapes remains fail-closed',
        'generated-child prior-observation second post-spawn await_any remains fail-closed',
    ) {
        return 1 if index($normalized, $phrase) >= 0;
    }

    return 0;
}

sub documents_branch_generated_do_pending_spawn {
    my ($content, $branch, @markers) = @_;
    my $normalized = lc $content;
    $normalized =~ s/`//g;

    my $anchor = $branch eq 'switch'
        ? 'top-level switch branch'
        : 'top-level when body';
    my $offset = index($normalized, $anchor);
    while ($offset >= 0) {
        my $window = substr($normalized, $offset, 4200);
        my $matches_markers = 1;
        for my $marker (@markers) {
            if ($window !~ $marker) {
                $matches_markers = 0;
                last;
            }
        }
        return 1
            if $matches_markers
            && $window =~ /\bgenerated\b/
            && $window =~ /\bdo\b/
            && $window =~ /generated(?:\s+nested)?\s+spawn/
            && index($window, 'pending') >= 0
            && index($window, 'await_all') >= 0
            && index($window, 'drain') >= 0;
        $offset = index($normalized, $anchor, $offset + 1);
    }

    return 0;
}
