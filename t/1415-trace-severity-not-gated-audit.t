#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Find;
use FindBin;

# Decision 0010: warnings/errors/fatals are never gated by a trace/verbosity level — a
# masked error is a silent failure. The clearest mis-routing is a severity-tagged message
# sent through the GATED trace API (fsm_debug / fsm_trace_*). This guard fails if any active
# perl source routes a `WARNING:` / `ERROR:` / `FATAL:` tagged message through the gated path;
# such messages must use the ungated fsm_warn / fsm_error / fsm_fatal channel instead.
# (Routine notes that merely describe a handled step — "parse miss", "no factoring needed" —
# legitimately stay on fsm_debug and carry no severity tag, so they are not flagged.)

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my @roots = map { File::Spec->catdir($repo_root, $_) } qw(perl bin);

my $gated_call = qr{\b(?:fsm_debug|fsm_trace_(?:enter|exit|decision|topic))\s*\(};
my $severity_tag = qr{\b(?:WARNING|ERROR|FATAL):};

my @src;
for my $root (@roots) {
    next unless -d $root;
    find(
        {
            wanted => sub {
                return unless -f $_;
                return unless /\.(?:pm|pl)\z/;
                return if /\.(?:orig|bak)\z/;
                push @src, $File::Find::name;
            },
            no_chdir => 1,
        },
        $root,
    );
}

ok(scalar(@src) > 0, 'found perl source to audit');

my @violations;
for my $file (@src) {
    open my $fh, '<', $file or die "cannot read $file: $!";
    my $lineno = 0;
    while (my $line = <$fh>) {
        $lineno++;
        next unless $line =~ $gated_call;
        next unless $line =~ $severity_tag;
        my $rel = File::Spec->abs2rel($file, $repo_root);
        chomp(my $text = $line);
        $text =~ s/^\s+//;
        push @violations, "$rel:$lineno: $text";
    }
    close $fh;
}

is(scalar(@violations), 0,
    'no WARNING:/ERROR:/FATAL: tagged message is routed through the gated trace API (decision 0010)')
    or diag("Route these through ungated fsm_warn/fsm_error/fsm_fatal instead:\n  "
        . join("\n  ", @violations));

done_testing();
