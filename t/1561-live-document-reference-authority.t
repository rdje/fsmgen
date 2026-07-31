#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use IPC::Open3 qw(open3);
use JSON::PP;
use Symbol qw(gensym);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::ProjectDataLocality qw(create_project_tempdir);

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $checker = File::Spec->catfile(
    $repo_root, 'scripts', 'check_live_document_reference_authority.pl',
);
my $json = JSON::PP->new->canonical(1)->utf8(1);

subtest 'first maintained-reference classification uses the current aggregate' => sub {
    my $fixture = make_fixture();
    set_reference($fixture, 'REFERENCE-CLASSIFY.1', aggregate(2, 2, 4), aggregate(0, 0, 0));
    stage($fixture, 'doctrine/live_document_size/surfaces.jsonl');
    my ($ok, $output) = run_checker($fixture);
    ok($ok, 'exact first classification passes') or diag($output);
    like($output, qr/1 reference\(s\), 0 changed, mode staged/,
        'first classification is reported without invented aggregate growth');
};

subtest 'fresh exact authority accompanies product-reference growth' => sub {
    my $fixture = make_fixture(maintained => 1);
    write_file($fixture, 'docs/c.md', "ccc\n");
    set_reference($fixture, 'REFERENCE-GROWTH.1', aggregate(2, 2, 4), aggregate(1, 1, 4));
    stage($fixture, 'docs/c.md', 'doctrine/live_document_size/surfaces.jsonl');
    my ($ok, $output) = run_checker($fixture);
    ok($ok, 'fresh exact aggregate authority passes') or diag($output);
    like($output, qr/1 reference\(s\), 1 changed, mode staged/,
        'authorized aggregate change is counted');
};

subtest 'last aggregate authority persists across unrelated commits' => sub {
    my $fixture = make_fixture(maintained => 1);
    write_file($fixture, 'docs/c.md', "ccc\n");
    set_reference($fixture, 'REFERENCE-GROWTH.1', aggregate(2, 2, 4), aggregate(1, 1, 4));
    stage($fixture, 'docs/c.md', 'doctrine/live_document_size/surfaces.jsonl');
    git_ok($fixture, 'commit', '--no-verify', '-q', '-m', 'grow reference');
    write_file($fixture, 'unrelated.txt', "unrelated\n");
    stage($fixture, 'unrelated.txt');
    git_ok($fixture, 'commit', '--no-verify', '-q', '-m', 'unrelated change');
    my ($ok, $output) = run_checker($fixture);
    ok($ok, 'unchanged last-change authority survives an unrelated commit')
        or diag($output);
    like($output, qr/1 reference\(s\), 0 changed, mode committed/,
        'unrelated commit does not manufacture a new authority');
};

subtest 'stale, inexact, reused, and banked authority fail closed' => sub {
    my $stale = make_fixture(maintained => 1);
    write_file($stale, 'docs/c.md', "ccc\n");
    stage($stale, 'docs/c.md');
    my ($stale_ok, $stale_output) = run_checker($stale);
    ok(!$stale_ok, 'content growth without contract update is rejected');
    like($stale_output, qr/authorized aggregate files is 3, expected 2/,
        'stale aggregate contract names the mismatch');

    my $inexact = make_fixture(maintained => 1);
    write_file($inexact, 'docs/c.md', "ccc\n");
    set_reference($inexact, 'REFERENCE-GROWTH.2', aggregate(2, 2, 4), aggregate(1, 1, 3));
    stage($inexact, 'docs/c.md', 'doctrine/live_document_size/surfaces.jsonl');
    my ($inexact_ok, $inexact_output) = run_checker($inexact);
    ok(!$inexact_ok, 'inexact byte delta is rejected');
    like($inexact_output, qr/aggregate delta bytes_total is 4, expected 3/,
        'inexact delta is explicit');

    my $reused = make_fixture(maintained => 1);
    write_file($reused, 'docs/c.md', "ccc\n");
    set_reference($reused, 'REFERENCE-BASE.1', aggregate(2, 2, 4), aggregate(1, 1, 4));
    stage($reused, 'docs/c.md', 'doctrine/live_document_size/surfaces.jsonl');
    my ($reused_ok, $reused_output) = run_checker($reused);
    ok(!$reused_ok, 'prior authority id cannot authorize later growth');
    like($reused_output, qr/reuses authority_id REFERENCE-BASE\.1/,
        'authority reuse is explicit');

    my $banked = make_fixture(maintained => 1);
    set_reference($banked, 'REFERENCE-BANKED.1', aggregate(2, 2, 4), aggregate(0, 0, 0));
    stage($banked, 'doctrine/live_document_size/surfaces.jsonl');
    my ($banked_ok, $banked_output) = run_checker($banked);
    ok(!$banked_ok, 'authority cannot change without an aggregate change');
    like($banked_output, qr/changed aggregate authority without an aggregate change/,
        'banked authority is explicit');

    my $reclassified = make_fixture(maintained => 1);
    set_partitioned($reclassified);
    stage($reclassified, 'doctrine/live_document_size/surfaces.jsonl');
    my ($reclassified_ok, $reclassified_output) = run_checker($reclassified);
    ok(!$reclassified_ok, 'maintained reference cannot silently leave the lifecycle');
    like($reclassified_output, qr/disappeared or changed lifecycle without an owned authority-contract migration/,
        'lifecycle migration requires an owned checker change');
};

done_testing();

sub make_fixture {
    my (%options) = @_;
    my $root = create_project_tempdir(purpose => 'live-document-reference-authority-tests');
    write_file($root, 'docs/a.md', "a\n");
    write_file($root, 'docs/b.md', "b\n");
    my $record = {
        surface_id => 'guide', lifecycle => 'partitioned_canonical',
        targets => ['docs/*.md'],
    };
    if ($options{maintained}) {
        apply_reference($record, 'REFERENCE-BASE.1', aggregate(2, 2, 4), aggregate(0, 0, 0));
    }
    write_file(
        $root, 'doctrine/live_document_size/surfaces.jsonl', json_line($record),
    );
    git_ok($root, 'init', '-q');
    git_ok($root, 'config', 'user.name', 'Fixture');
    git_ok($root, 'config', 'user.email', 'fixture.invalid@example.test');
    git_ok($root, 'config', 'core.hooksPath', '.no-hooks');
    stage($root, 'docs/a.md', 'docs/b.md', 'doctrine/live_document_size/surfaces.jsonl');
    git_ok($root, 'commit', '--no-verify', '-q', '-m', 'baseline');
    return $root;
}

sub set_reference {
    my ($root, $authority, $baseline, $delta) = @_;
    my $relative = 'doctrine/live_document_size/surfaces.jsonl';
    my $record = decode_json(slurp(File::Spec->catfile($root, split m{/}, $relative)));
    apply_reference($record, $authority, $baseline, $delta);
    write_file($root, $relative, json_line($record));
}

sub set_partitioned {
    my ($root) = @_;
    my $relative = 'doctrine/live_document_size/surfaces.jsonl';
    my $record = decode_json(slurp(File::Spec->catfile($root, split m{/}, $relative)));
    $record->{lifecycle} = 'partitioned_canonical';
    delete $record->{reference_contract};
    write_file($root, $relative, json_line($record));
}

sub apply_reference {
    my ($record, $authority, $baseline, $delta) = @_;
    $record->{lifecycle} = 'maintained_reference';
    $record->{reference_contract} = {
        aggregate_change => {
            authority_id => $authority, owner => 'fixture-owner',
            rationale => 'Fixture product-reference change.',
            baseline => $baseline, delta => $delta,
        },
    };
}

sub aggregate {
    my ($files, $lines, $bytes) = @_;
    return { files => $files, lines_total => $lines, bytes_total => $bytes };
}

sub json_line {
    my ($record) = @_;
    return $json->encode($record) . "\n";
}

sub write_file {
    my ($root, $relative, $contents) = @_;
    my $path = File::Spec->catfile($root, split m{/}, $relative);
    make_path(dirname($path));
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    print {$fh} $contents;
    close $fh or die "cannot close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $contents = <$fh> // '';
    close $fh or die "cannot close $path: $!";
    return $contents;
}

sub stage {
    my ($root, @paths) = @_;
    git_ok($root, 'add', '--', @paths);
}

sub git_ok {
    my ($root, @args) = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => ['git', '-C', $root, @args],
    );
    die "git @args failed: " . join('', @{$stdout || []}, @{$stderr || []}) if !$ok;
}

sub run_checker {
    my ($root) = @_;
    my $stderr = gensym;
    my $pid = open3(my $stdin, my $stdout, $stderr, $^X, $checker, '--root', $root);
    close $stdin;
    local $/;
    my $out = <$stdout> // '';
    my $err = <$stderr> // '';
    waitpid($pid, 0);
    return ($? == 0 ? 1 : 0, $out . $err);
}
