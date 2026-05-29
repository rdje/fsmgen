#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

# Build gate for the non-ISF `.fsm` (IAL0) book chapters.
#
# Last session's t/1376 gate covers the ISF surface by extracting every
# `lisp`-tagged `(actor ...)` block and lowering it in-process. This sibling
# gate covers the non-ISF `.fsm` authoring chapters: it extracts every
# `lisp`-tagged block that contains a generation root (`?fsm:`/`?dt:`/`?top:`/
# `?mod:`/`?module:`/`+fsm`) and asserts each one passes `./bin/fsmgen
# --check-json` (success: true), so a reader who copy-pastes a `lisp` example
# from these chapters gets a source that actually parses and generates.
#
# Inherently multi-file or schematic illustrations (composition tops that need
# sidecar children, `?pkg`-container examples, ellipsis shapes) are documented
# as `text` blocks, not `lisp`, so they are deliberately out of this gate's
# scope. The convention is: `lisp` == standalone-generatable fixture, `text`
# == schematic / multi-file illustration.

my $repo_root = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $src_dir   = File::Spec->catdir($repo_root, 'docs', 'book', 'src');
my $fsmgen    = File::Spec->catfile($repo_root, 'bin', 'fsmgen');

# IAL0 (.fsm) authoring chapters. The ISF chapters (13*.md) are covered by
# t/1376; the cookbook (12) is mixed, but the generation-root predicate below
# naturally excludes its ISF `(actor ...)` recipes.
my @chapters = qw(
    01-first-fsm.md
    02-language-basics.md
    03-decision-trees-and-fsms.md
    04-symbols-types-and-imports.md
    05-composition-basics.md
    06-composition-advanced.md
    07-packages-and-sharing.md
    08-type-inference-and-aggregate-data.md
    12-cookbook.md
);

my $tmp = tempdir(CLEANUP => 1);

my $blocks_checked = 0;
my $blocks_skipped = 0;
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

        # Only gate standalone .fsm generation fixtures: blocks that contain a
        # generation root. ISF `(actor ...)` recipes and pure declaration
        # snippets without a generation root are skipped here.
        unless ($code =~ /\(\?(?:fsm|dt|top|mod|module):/ || $code =~ /\(\+fsm\b/) {
            $blocks_skipped++;
            next;
        }

        my $fsm_path = File::Spec->catfile($tmp, "blk_${chapter}_${block_index}.fsm");
        $fsm_path =~ s/\.md_/_/;
        open my $out, '>', $fsm_path or die "$fsm_path: $!";
        print $out $code;
        close $out;

        my $sv_path = File::Spec->catfile($tmp, "blk_${chapter}_${block_index}.sv");
        $sv_path =~ s/\.md_/_/;

        my ($success, $err, undef, $stdout_buf, undef) = run(
            command => [
                $fsmgen,
                '--check-json',
                '-o', $sv_path,
                $fsm_path,
            ],
        );

        my $stdout = join('', @{$stdout_buf || []});
        my $decoded = eval { decode_json($stdout) };

        if (!$decoded) {
            push @failures,
                "$chapter block #$block_index: undecodable check JSON"
                . ($err ? " ($err)" : '');
            next;
        }
        if (!$decoded->{success}) {
            my $msg = '';
            if (ref($decoded->{diagnostics}) eq 'ARRAY' && @{$decoded->{diagnostics}}) {
                $msg = $decoded->{diagnostics}[0]{message} // '';
                $msg =~ s/\n.*//s;
            }
            push @failures, "$chapter block #$block_index: check failed: $msg";
            next;
        }

        $blocks_checked++;
    }
}

ok($blocks_checked > 0,
    "at least one standalone non-ISF .fsm book example generates cleanly (saw $blocks_checked)");

is(scalar(@failures), 0,
    'every lisp-tagged non-ISF .fsm book example with a generation root passes --check-json')
    or diag("Generation failures (" . scalar(@failures) . "):\n  " . join("\n  ", @failures));

diag("audit summary: $blocks_checked standalone .fsm fixtures generated cleanly, "
   . "$blocks_skipped non-generation-root lisp blocks skipped");

done_testing();
