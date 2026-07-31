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
    $repo_root, 'scripts', 'check_live_document_ceiling_authority.pl',
);
my $json = JSON::PP->new->canonical(1)->utf8(1);

subtest 'ceiling equality and lowering need no increase authority' => sub {
    my $equal = make_fixture();
    set_ceiling($equal, 100);
    stage($equal, 'doctrine/live_document_size/surfaces.jsonl');
    my ($equal_ok, $equal_output) = run_checker($equal);
    ok($equal_ok, 'unchanged inclusive ceiling passes') or diag($equal_output);

    my $lower = make_fixture();
    set_ceiling($lower, 90);
    stage($lower, 'doctrine/live_document_size/surfaces.jsonl');
    my ($lower_ok, $lower_output) = run_checker($lower);
    ok($lower_ok, 'ceiling reduction is free') or diag($lower_output);
    like($lower_output, qr/0 increase\(s\), mode staged/, 'lowering is reported as no increase');
};

subtest 'an unaccompanied ceiling increase fails closed' => sub {
    my $fixture = make_fixture();
    set_ceiling($fixture, 101);
    stage($fixture, 'doctrine/live_document_size/surfaces.jsonl');
    my ($ok, $output) = run_checker($fixture);
    ok(!$ok, 'unaccompanied increase is rejected');
    like(
        $output,
        qr/unauthorized enforcement-ceiling increase: guide lines_each 100 -> 101/,
        'surface, dimension, and exact delta are named',
    );
};

subtest 'one newly reviewed authority can authorize its exact increase' => sub {
    my $fixture = make_fixture();
    set_ceiling($fixture, 110);
    add_authority($fixture, 'CEILING-TEST-001', 100, 110, 'docs/decisions/0045-test.md');
    write_file(
        $fixture,
        'docs/decisions/0045-test.md',
        join("\n",
            '# 0045 — Fixture ceiling authority',
            '',
            '- Ceiling authority: `CEILING-TEST-001`',
            '- Surface: `guide`',
            '- Dimension: `lines_each`',
            '- Change: `100 -> 110`',
            '',
        ),
    );
    stage(
        $fixture,
        'doctrine/live_document_size/surfaces.jsonl',
        'doctrine/live_document_size/ceiling_increase_authorities.jsonl',
        'docs/decisions/0045-test.md',
    );
    my ($ok, $output) = run_checker($fixture);
    ok($ok, 'exact new authority plus new decision passes') or diag($output);
    like($output, qr/1 increase\(s\), mode staged/, 'authorized increase count is explicit');
};

subtest 'authority is neither reusable nor pre-authorizable' => sub {
    my $reused = make_fixture();
    write_file(
        $reused,
        'docs/decisions/0045-old.md',
        "# Old decision\n\n- Ceiling authority: `CEILING-OLD-001`\n"
            . "- Surface: `guide`\n- Dimension: `lines_each`\n- Change: `100 -> 110`\n",
    );
    stage($reused, 'docs/decisions/0045-old.md');
    git_ok($reused, 'commit', '--no-verify', '-q', '-m', 'old decision');
    set_ceiling($reused, 110);
    add_authority($reused, 'CEILING-OLD-001', 100, 110, 'docs/decisions/0045-old.md');
    stage(
        $reused,
        'doctrine/live_document_size/surfaces.jsonl',
        'doctrine/live_document_size/ceiling_increase_authorities.jsonl',
    );
    my ($reused_ok, $reused_output) = run_checker($reused);
    ok(!$reused_ok, 'an old decision cannot be reused for a later increase');
    like($reused_output, qr/must cite a decision newly added with this increase/,
        'fresh decision requirement is explicit');

    my $orphan = make_fixture();
    add_authority($orphan, 'CEILING-ORPHAN-001', 100, 110, 'docs/decisions/0045-orphan.md');
    write_file(
        $orphan,
        'docs/decisions/0045-orphan.md',
        "# Orphan\n\n- Ceiling authority: `CEILING-ORPHAN-001`\n"
            . "- Surface: `guide`\n- Dimension: `lines_each`\n- Change: `100 -> 110`\n",
    );
    stage(
        $orphan,
        'doctrine/live_document_size/ceiling_increase_authorities.jsonl',
        'docs/decisions/0045-orphan.md',
    );
    my ($orphan_ok, $orphan_output) = run_checker($orphan);
    ok(!$orphan_ok, 'authority cannot be banked before an increase');
    like($orphan_output, qr/does not match a ceiling increase in the same change/,
        'orphan authority is explicit');
};

subtest 'transition baseline is immutable across revisions' => sub {
    my $fixture = make_fixture();
    mutate_surface($fixture, sub { $_[0]{baseline}{lines_each} = 81 });
    stage($fixture, 'doctrine/live_document_size/surfaces.jsonl');
    my ($ok, $output) = run_checker($fixture);
    ok(!$ok, 'baseline rewrite is rejected');
    like($output, qr/surface guide changed its immutable transition baseline/,
        'immutable baseline failure is explicit');
};

done_testing();

sub make_fixture {
    my $root = create_project_tempdir(purpose => 'live-document-ceiling-authority-tests');
    write_file(
        $root,
        'doctrine/live_document_size/surfaces.jsonl',
        json_line({
            surface_id => 'guide',
            enforcement_ceilings => pressure(1, 100, 4096, 100, 4096),
            baseline => pressure(1, 80, 2048, 80, 2048),
        }),
    );
    write_file(
        $root,
        'doctrine/live_document_size/ceiling_increase_authorities.jsonl',
        json_line({ record_type => 'registry', schema_version => 1 }),
    );
    git_ok($root, 'init', '-q');
    git_ok($root, 'config', 'user.name', 'Fixture');
    git_ok($root, 'config', 'user.email', 'fixture.invalid@example.test');
    git_ok($root, 'config', 'core.hooksPath', '.no-hooks');
    stage(
        $root,
        'doctrine/live_document_size/surfaces.jsonl',
        'doctrine/live_document_size/ceiling_increase_authorities.jsonl',
    );
    git_ok($root, 'commit', '--no-verify', '-q', '-m', 'baseline');
    return $root;
}

sub set_ceiling {
    my ($root, $value) = @_;
    mutate_surface($root, sub { $_[0]{enforcement_ceilings}{lines_each} = $value });
}

sub mutate_surface {
    my ($root, $mutator) = @_;
    my $relative = 'doctrine/live_document_size/surfaces.jsonl';
    my $record = decode_json(slurp(File::Spec->catfile($root, split m{/}, $relative)));
    $mutator->($record);
    write_file($root, $relative, json_line($record));
}

sub add_authority {
    my ($root, $authority_id, $previous, $new, $decision) = @_;
    append_file(
        $root,
        'doctrine/live_document_size/ceiling_increase_authorities.jsonl',
        json_line({
            record_type => 'ceiling_increase_authority', schema_version => 1,
            authority_id => $authority_id, surface_id => 'guide', dimension => 'lines_each',
            previous => $previous, new => $new, decision => $decision,
            approved_on => '2030-01-01',
        }),
    );
}

sub pressure {
    my ($files, $lines_each, $bytes_each, $lines_total, $bytes_total) = @_;
    return {
        files => $files, lines_each => $lines_each, bytes_each => $bytes_each,
        lines_total => $lines_total, bytes_total => $bytes_total,
    };
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

sub append_file {
    my ($root, $relative, $contents) = @_;
    my $path = File::Spec->catfile($root, split m{/}, $relative);
    open my $fh, '>>:raw', $path or die "cannot append $path: $!";
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
