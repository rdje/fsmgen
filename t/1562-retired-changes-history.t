#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path);
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::ProjectDataLocality qw(create_project_tempdir);

my $repo = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $verifier = File::Spec->catfile($repo, 'scripts', 'check_retired_changes_history.pl');

subtest 'exact retired object passes with no live consumer' => sub {
    my $fixture = make_fixture();
    my ($ok, $output) = run_verifier($fixture);
    ok($ok, 'retired path and exact Git object pass') or diag($output);
    like($output, qr/exact .*:CHANGES\.md recovery and zero live consumers verified/,
        'success reports recovery and consumer closure');
};

subtest 'recreated path and planted active consumer fail independently' => sub {
    my $live = make_fixture();
    write_file($live->{root}, 'CHANGES.md', "recreated\n");
    my ($live_ok, $live_output) = run_verifier($live);
    ok(!$live_ok, 'recreated retired path fails');
    like($live_output, qr/CHANGES\.md is retired and must remain absent/,
        'live-path residue is named');

    my $consumer = make_fixture();
    write_file($consumer->{root}, 'AGENTS.md', "Read CHANGES.md for state.\n");
    run_git($consumer->{root}, 'add', 'AGENTS.md');
    my ($consumer_ok, $consumer_output) = run_verifier($consumer);
    ok(!$consumer_ok, 'planted policy consumer fails');
    like($consumer_output, qr/active policy consumer still names retired CHANGES\.md: AGENTS\.md/,
        'planted consumer is named exactly');
};

subtest 'retrieval identity failures fail closed' => sub {
    my $digest = make_fixture();
    $digest->{sha256} = '0' x 64;
    my ($digest_ok, $digest_output) = run_verifier($digest);
    ok(!$digest_ok, 'wrong digest fails');
    like($digest_output, qr/retrieved SHA-256 changed/, 'digest mismatch is explicit');

    my $revision = make_fixture();
    $revision->{revision} = '0' x 40;
    my ($revision_ok, $revision_output) = run_verifier($revision);
    ok(!$revision_ok, 'missing revision fails');
    like($revision_output, qr/cannot retrieve/, 'retrieval failure is explicit');
};

subtest 'whole-document token sweep detects planted orphan exactly' => sub {
    my $source = "# CHANGES\n### UNIT.1\n- changed `path/to/file.pm`\n";
    my $before = tokens($source);
    my $probe = 'fsmgen_orphan_probe_retired_changes_history';
    my $after = tokens($source . "### $probe\n");
    is(scalar(keys %{$after}), scalar(keys %{$before}) + 1,
        'planted orphan increases unique token inventory by one');
    ok($after->{$probe}, 'planted orphan token is reported exactly');
};

done_testing();

sub make_fixture {
    my $root = create_project_tempdir(purpose => 'retired-changes-history-tests');
    run_git($root, 'init');
    run_git($root, 'config', 'user.name', 'Fixture');
    run_git($root, 'config', 'user.email', 'fixture@example.invalid');
    my $source = "# CHANGES\n### UNIT.1\n- exact history\n";
    write_file($root, 'CHANGES.md', $source);
    write_file($root, 'AGENTS.md', "Current workflow.\n");
    run_git($root, 'add', '.');
    run_git($root, 'commit', '-m', 'fixture source');
    my $revision = run_git_output($root, 'rev-parse', 'HEAD');
    unlink File::Spec->catfile($root, 'CHANGES.md')
        or die "cannot remove fixture CHANGES.md: $!";
    run_git($root, 'add', '-u');
    return {
        root => $root,
        revision => $revision,
        sha256 => sha256_hex($source),
        lines => 3,
        bytes => length($source),
        longest => length('- exact history'),
    };
}
sub run_verifier {
    my ($fixture) = @_;
    my @command = (
        $verifier,
        '--root', $fixture->{root},
        '--revision', $fixture->{revision},
        '--sha256', $fixture->{sha256},
        '--lines', $fixture->{lines},
        '--bytes', $fixture->{bytes},
        '--longest', $fixture->{longest},
    );
    my ($ok, undef, undef, $stdout, $stderr) = run(command => \@command);
    return ($ok, join('', @{$stdout || []}, @{$stderr || []}));
}

sub tokens {
    my ($source) = @_;
    my %tokens;
    for my $line (split /\n/, $source) {
        my @values;
        push @values, $1 while $line =~ /`([^`]+)`/g;
        push @values, $1 if $line =~ /^#{1,6}\s+(.+)/;
        push @values, ($line =~ /\b[A-Z][A-Z0-9-]+(?:\.\d+)+\b/g);
        push @values, ($line =~ m{\b(?:[A-Za-z0-9_.-]+/)+[A-Za-z0-9_.-]+\b}g);
        push @values, ($line =~ /\b[A-Za-z0-9][A-Za-z0-9_.:+\/-]{4,}\b/g);
        for my $value (@values) {
            my $normalized = lc $value;
            $normalized =~ s/^\s+|\s+$//g;
            $tokens{$normalized} = 1 if length($normalized) >= 5;
        }
    }
    return \%tokens;
}

sub write_file {
    my ($root, $relative, $contents) = @_;
    my $path = File::Spec->catfile($root, split m{/+}, $relative);
    my (undef, $dirs) = File::Spec->splitpath($path);
    make_path($dirs) if $dirs ne '' && !-d $dirs;
    open my $fh, '>:raw', $path or die "cannot write $relative: $!";
    print {$fh} $contents or die "cannot write $relative: $!";
    close $fh or die "cannot close $relative: $!";
}

sub run_git {
    my ($root, @args) = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => ['git', '-C', $root, @args],
    );
    die "git @args failed: " . join('', @{$stdout || []}, @{$stderr || []})
        if !$ok;
}

sub run_git_output {
    my ($root, @args) = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => ['git', '-C', $root, @args],
    );
    die "git @args failed: " . join('', @{$stdout || []}, @{$stderr || []})
        if !$ok;
    my $output = join('', @{$stdout || []});
    $output =~ s/\s+\z//;
    return $output;
}
