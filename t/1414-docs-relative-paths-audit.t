#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Find;
use FindBin;

# Decisions 0011/0012: every file-path reference in live docs and every generated
# Knowledge Map root/shard must be relative to the git repo root, never an absolute
# machine-local path. Absolute home-directory prefixes (e.g. a /Users/<user>/...
# or /home/<user>/... path) capture the author's local file structure and break
# for any other checkout. This guard scans docs/**/*.md plus the bounded Knowledge
# Map projection and fails on any such prefix, keeping the invariant from regressing.

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $docs_root = File::Spec->catdir($repo_root, 'docs');
my $knowledge_map = File::Spec->catfile($repo_root, 'KNOWLEDGE_MAP.md');
my $knowledge_shards = File::Spec->catdir(
    $repo_root, 'knowledge-map', 'generated');

# Machine-local home-directory prefixes that leak local structure. System paths
# (/usr, /bin, /tmp, /etc) are not local-structure leaks and are not flagged.
my $abs_local_re = qr{(?:/Users/[^/\s'"`)]+/|/home/[^/\s'"`)]+/)};

my @md_files;
find(
    {
        wanted => sub {
            return unless -f $_ && /\.md\z/;
            # Skip the generated mdBook HTML output tree (docs/book/book/) — it is a
            # gitignored, regenerable build artifact, not authored source.
            return if $File::Find::name =~ m{/book/book/};
            push @md_files, $File::Find::name;
        },
        no_chdir => 1,
    },
    $docs_root,
);
push @md_files, $knowledge_map if -f $knowledge_map;
if (-d $knowledge_shards) {
    find(
        {
            wanted => sub {
                push @md_files, $File::Find::name if -f $_ && /\.md\z/;
            },
            no_chdir => 1,
        },
        $knowledge_shards,
    );
}

ok(scalar(@md_files) > 0, 'found docs markdown files and Knowledge Map root/shards to audit');

my @violations;
for my $file (@md_files) {
    open my $fh, '<', $file or die "cannot read $file: $!";
    my $lineno = 0;
    while (my $line = <$fh>) {
        $lineno++;
        if ($line =~ $abs_local_re) {
            my $rel = File::Spec->abs2rel($file, $repo_root);
            chomp(my $text = $line);
            push @violations, "$rel:$lineno: $text";
        }
    }
    close $fh;
}

is(scalar(@violations), 0, 'no absolute machine-local file paths in docs or Knowledge Map root/shards (decisions 0011/0012)')
    or diag("Absolute local paths must be made repo-root-relative:\n  " . join("\n  ", @violations));

done_testing();
