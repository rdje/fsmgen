#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $repo_root = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $src_dir   = File::Spec->catdir($repo_root, 'docs', 'book', 'src');

my @chapters = qw(
    12-cookbook.md
    13-intent-scheduling.md
    13a-actor-interface.md
    13b-transactions.md
    13c-drive-blocks.md
    13d-control-flow.md
    13e-data-manipulation.md
    13f-composition.md
    13g-rules.md
    13h-lowering-reference.md
    13j-type-enum-aggregate.md
    13k-isf-feature-support-matrix.md
    14-feature-backlog.md
);

my $blocks_lowered = 0;
my $blocks_skipped_fragments = 0;
my @failures;

for my $chapter (@chapters) {
    my $path = File::Spec->catfile($src_dir, $chapter);
    open my $fh, '<', $path or die "$path: $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    my $block_index = 0;
    while ($content =~ /^```lisp\s*\n(.*?)\n```/msg) {
        $block_index++;
        my $code = $1;

        if ($code !~ /^\s*\(actor\b/) {
            $blocks_skipped_fragments++;
            next;
        }

        my $actor = eval {
            FSM::Adapter::ISF->new()->parse_source(
                $code,
                "book-example: $chapter block #$block_index",
            );
        };
        if ($@) {
            my $msg = $@;
            $msg =~ s/\n.*//s;
            push @failures, "$chapter block #$block_index (parse): $msg";
            next;
        }

        my $result = eval {
            FSM::Scheduler::ISF->new()->lower($actor);
        };
        if ($@) {
            my $msg = $@;
            $msg =~ s/\n.*//s;
            push @failures, "$chapter block #$block_index (lower): $msg";
            next;
        }

        $blocks_lowered++;
    }
}

ok($blocks_lowered > 0,
    "at least one complete lisp-tagged book example lowers cleanly (saw $blocks_lowered)");

is(scalar(@failures), 0,
    'every lisp-tagged book example that starts with (actor parses and lowers cleanly')
    or diag("Lowering failures (" . scalar(@failures) . "):\n  " . join("\n  ", @failures));

diag("audit summary: $blocks_lowered complete fixtures lowered cleanly, "
   . "$blocks_skipped_fragments fragments skipped (did not start with (actor))");

done_testing();
