#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::ISFPublicInterfaceContract qw(
    isf_public_interface_live_document_paths
);

my $repo_root = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $matrix_path = 'docs/book/src/13k-isf-feature-support-matrix.md';
my $matrix = read_repo_file($matrix_path);
my $summary = read_repo_file('docs/book/src/SUMMARY.md');

like(
    $summary,
    qr{\[Feature Support Matrix\]\(13k-isf-feature-support-matrix\.md\)},
    'ISF feature support matrix is reachable from the mdBook summary',
);

my %live_paths = map { $_ => 1 } @{isf_public_interface_live_document_paths()};
ok(
    $live_paths{$matrix_path},
    'ISF feature support matrix is advertised through live_document_paths',
);

my @required_rows = (
    ['`.isf` CLI input', 'shipped'],
    ['Public parser and scheduler facades', 'shipped bounded surface'],
    ['Actor envelope', 'shipped'],
    ['Single-clock timing', 'shipped'],
    ['Multi-clock domains', 'shipped bounded surface'],
    ['Acknowledged event CDC', 'shipped bounded surface'],
    ['Interface ports', 'shipped'],
    ['Actor-owned scalar storage', 'shipped'],
    ['Actor-owned banks', 'shipped bounded surface'],
    ['Type aliases and package imports', 'shipped bounded surface'],
    ['Enum member values', 'shipped bounded surface'],
    ['Aggregate scalar leaves', 'shipped bounded surface'],
    ['Transaction entry', 'shipped'],
    ['Transaction assignments', 'shipped'],
    ['Named and inline drives', 'shipped'],
    ['Await and latency', 'shipped'],
    ['Static and dynamic waits', 'shipped bounded surface'],
    ['Transaction control flow', 'shipped bounded surface'],
    ['Transaction stages', 'shipped bounded surface'],
    ['Temporal contracts', 'shipped bounded surface'],
    ['Data manipulation', 'shipped bounded surface'],
    ['Rules and trigger fan-in', 'shipped'],
    ['Rule conflicts and priorities', 'shipped bounded surface'],
    ['Resources', 'shipped bounded surface'],
    ['Blocking child activation', 'shipped bounded surface'],
    ['Spawned generated children', 'shipped bounded surface'],
    ['Reusable ISF libraries', 'shipped bounded surface'],
    ['Schedule reports', 'shipped bounded surface'],
    ['Diagnostics and downstream issue reporting', 'shipped'],
);

for my $row (@required_rows) {
    my ($feature, $status) = @{$row};
    like(
        $matrix,
        qr{\|\s*\Q$feature\E\s*\|\s*\Q$status\E\s*\|},
        "matrix documents $feature as $status",
    );
}

my @required_examples = (
    '(clock-domains',
    '(crossings',
    '(stage wait_ready',
    '(contract finish_seen',
    '(repeat count',
    '(types',
    '(storage',
    '(resources',
    '(spawn worker as w0',
    '(imports',
    '--emit-schedule-json',
);

for my $example (@required_examples) {
    like(
        $matrix,
        qr{\Q$example\E},
        "matrix keeps representative example marker $example",
    );
}

my @required_non_claims = (
    'Multi-bit CDC payloads',
    'Spawn, blocking `do`, `await_all`, `await_any`',
    'Enum members are not writable targets',
    'Aggregate interface ports',
    'Backlog resource kinds',
    'Direct `(on ...)` activation-site `(params ...)`',
    'Nested stages',
    'Temporal contracts beyond the top-level bounded eventual subset',
    'VHDL is recognized as a target family',
);

for my $non_claim (@required_non_claims) {
    like(
        $matrix,
        qr{\Q$non_claim\E},
        "matrix keeps explicit non-claim: $non_claim",
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
