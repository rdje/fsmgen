#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path);
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP;
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::ProjectDataLocality qw(create_project_tempdir);

my $repo = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $verifier = File::Spec->catfile(
    $repo, 'scripts', 'check_engineering_rationale_ledger.pl',
);

subtest 'immutable source plus a real current append reconstruct exactly' => sub {
    my $fixture = make_fixture();
    my ($ok, $output) = run_verifier($fixture);
    ok($ok, 'version-backed source and appended current range pass')
        or diag($output);
    like(
        $output,
        qr/exact immutable source prefix plus 1 post-cutover current entry reconstructed across 2 ranges/,
        'success states the first-append and range proof',
    );
};

subtest 'current mutation and missing current append fail closed' => sub {
    my $mutation = make_fixture();
    append_file($mutation->{root}, 'DEVELOPMENT_NOTES.md', "mutated\n");
    my ($mutation_ok, $mutation_output) = run_verifier($mutation);
    ok(!$mutation_ok, 'unregistered mutation fails');
    like($mutation_output, qr/current.*(?:line count|byte count|digest) changed/,
        'current range identity mismatch is explicit');

    my $missing = make_fixture();
    write_file(
        $missing->{root},
        'DEVELOPMENT_NOTES.md',
        "# DEVELOPMENT_NOTES\n\nSee DEVELOPMENT_NOTES_INDEX.md.\n",
    );
    my ($missing_ok, $missing_output) = run_verifier($missing);
    ok(!$missing_ok, 'ledger with no post-cutover entry fails');
    like($missing_output, qr/current rationale view contains no whole rationale entry/,
        'missing current entry is explicit');
};

subtest 'source descriptor and index omissions fail independently' => sub {
    my $digest = make_fixture();
    rewrite_jsonl_record(
        $digest->{root},
        'registry/archive.jsonl',
        sub {
            my ($record) = @_;
            $record->{sha256} = '0' x 64
                if ($record->{descriptor_id} // '') eq 'rationale_source';
        },
    );
    my ($digest_ok, $digest_output) = run_verifier($digest);
    ok(!$digest_ok, 'wrong source descriptor digest fails');
    like($digest_output, qr/source descriptor digest changed/,
        'source descriptor mismatch is explicit');

    my $index = make_fixture();
    write_file(
        $index->{root},
        'DEVELOPMENT_NOTES_INDEX.md',
        "# Index\n\n- rationale-current\n",
    );
    my ($index_ok, $index_output) = run_verifier($index);
    ok(!$index_ok, 'incomplete range index fails');
    like($index_output, qr/rationale index omits range rationale-0001/,
        'omitted range is named');
};

done_testing();

sub make_fixture {
    my $root = create_project_tempdir(
        purpose => 'engineering-rationale-ledger-tests',
    );
    run_git($root, 'init');
    run_git($root, 'config', 'user.name', 'Fixture');
    run_git($root, 'config', 'user.email', 'fixture@example.invalid');

    my $source = "# DEVELOPMENT_NOTES\n\n"
        . "## First rationale\n\nLegacy one.\n\n"
        . "## Second rationale\n\nLegacy two.\n";
    write_file($root, 'DEVELOPMENT_NOTES.md', $source);
    run_git($root, 'add', 'DEVELOPMENT_NOTES.md');
    run_git($root, 'commit', '-m', 'fixture rationale source');
    my $revision = run_git_output($root, 'rev-parse', 'HEAD');

    my $current = "# DEVELOPMENT_NOTES\n\n"
        . "See DEVELOPMENT_NOTES_INDEX.md.\n\n"
        . "## Current rationale\n\nPost-cutover append.\n";
    write_file($root, 'DEVELOPMENT_NOTES.md', $current);
    write_file(
        $root,
        'DEVELOPMENT_NOTES_INDEX.md',
        "# Index\n\n- rationale-0001\n- rationale-current\n",
    );

    my ($source_body, $source_entries) = entries($source);
    my ($current_body, $current_entries) = entries($current);
    my $all_entries = $source_body . $current_body;
    my $archive = [
        registry(8, 8192, 4096),
        {
            record_type => 'descriptor', schema_version => 1,
            descriptor_id => 'rationale_source', surface_id => 'engineering_rationale',
            former_path => 'DEVELOPMENT_NOTES.md', range_id => 'complete-source',
            revision => $revision, lines => line_count($source), bytes => length($source),
            sha256 => sha256_hex($source), retrieval_kind => 'version_object',
            retrieval_locator => "git show $revision:DEVELOPMENT_NOTES.md",
            current_pointer => 'DEVELOPMENT_NOTES.md', sealed_on => '2030-01-01',
            verifier => 'adapter:scripts/check_engineering_rationale_ledger.pl',
            retention_contract => 'fixture_history',
        },
        {
            record_type => 'descriptor', schema_version => 1,
            descriptor_id => 'rationale_range_0001',
            surface_id => 'engineering_rationale',
            former_path => 'DEVELOPMENT_NOTES.md', range_id => 'rationale-0001',
            revision => $revision, lines => line_count($source_body),
            bytes => length($source_body), sha256 => sha256_hex($source_body),
            retrieval_kind => 'version_object', retrieval_locator => 'fixture source body',
            current_pointer => 'DEVELOPMENT_NOTES.md', sealed_on => '2030-01-01',
            verifier => 'adapter:scripts/check_engineering_rationale_ledger.pl',
            retention_contract => 'fixture_history',
        },
    ];
    my $ledgers = [
        registry(8, 16384, 8192),
        {
            record_type => 'ledger', schema_version => 1,
            ledger_id => 'engineering_rationale', surface_id => 'engineering_rationale',
            current_path => 'DEVELOPMENT_NOTES.md',
            index_path => 'DEVELOPMENT_NOTES_INDEX.md', entry_start_prefix => '## ',
            ordering => 'append_only', source_descriptor_id => 'rationale_source',
            total_entries => 3, entries_lines => line_count($all_entries),
            entries_bytes => length($all_entries), entries_sha256 => sha256_hex($all_entries),
            current_entry_limit => 8, index_lines_ceiling => 32,
            index_bytes_ceiling => 4096,
            reconstruction_verifier => 'adapter:scripts/check_engineering_rationale_ledger.pl',
            archive_transition => {
                archive_surface_id => 'exact_history', max_live_ranges => 2,
                max_live_lines => 64, max_live_bytes => 4096,
            },
        },
        range_record(
            'rationale-0001', 1, 1, 2, $source_body, $source_entries,
            $revision, 'archive_descriptor', 'rationale_range_0001',
            'builtin:archive_descriptor',
        ),
        range_record(
            'rationale-current', 2, 3, 3, $current_body, $current_entries,
            'worktree', 'current', 'DEVELOPMENT_NOTES.md', 'builtin:current',
        ),
    ];
    write_records($root, 'registry/archive.jsonl', $archive);
    write_records($root, 'registry/ledgers.jsonl', $ledgers);
    return {
        root => $root,
        revision => $revision,
        sha256 => sha256_hex($source),
    };
}

sub range_record {
    my ($id, $sequence, $first, $last, $body, $entries, $revision,
        $storage_kind, $storage_locator, $verifier_name) = @_;
    return {
        record_type => 'range', schema_version => 1,
        range_id => $id, ledger_id => 'engineering_rationale', sequence => $sequence,
        first_ordinal => $first, last_ordinal => $last,
        entry_count => scalar(@{$entries}), revision => $revision,
        lines => line_count($body), bytes => length($body), sha256 => sha256_hex($body),
        first_entry_sha256 => sha256_hex($entries->[0]),
        last_entry_sha256 => sha256_hex($entries->[-1]),
        storage_kind => $storage_kind, storage_locator => $storage_locator,
        verifier => $verifier_name,
    };
}

sub run_verifier {
    my ($fixture) = @_;
    my @command = (
        $verifier,
        '--root', $fixture->{root},
        '--revision', $fixture->{revision},
        '--source-sha256', $fixture->{sha256},
        '--archives', 'registry/archive.jsonl',
        '--ledgers', 'registry/ledgers.jsonl',
    );
    my ($ok, undef, undef, $stdout, $stderr) = run(command => \@command);
    return ($ok, join('', @{$stdout || []}, @{$stderr || []}));
}

sub entries {
    my ($contents) = @_;
    my $body = substr($contents, index($contents, '## '));
    my @entries = ($body =~ /(\Q## \E.*?)(?=^\Q## \E|\z)/msg);
    return ($body, \@entries);
}

sub registry {
    my ($max_records, $max_bytes, $max_record_bytes) = @_;
    return {
        record_type => 'registry', schema_version => 1,
        max_records => $max_records, max_bytes => $max_bytes,
        max_record_bytes => $max_record_bytes,
    };
}

sub line_count {
    my ($contents) = @_;
    return scalar(() = $contents =~ /\n/g);
}

sub rewrite_jsonl_record {
    my ($root, $relative, $mutator) = @_;
    my $path = File::Spec->catfile($root, split m{/+}, $relative);
    open my $fh, '<:raw', $path or die "cannot read $relative: $!";
    my @records = map { JSON::PP::decode_json($_) } grep { $_ ne '' } <$fh>;
    close $fh or die "cannot close $relative: $!";
    $mutator->($_) for @records;
    write_records($root, $relative, \@records);
}

sub write_records {
    my ($root, $relative, $records) = @_;
    my $json = JSON::PP->new->canonical(1);
    write_file($root, $relative, join('', map { $json->encode($_) . "\n" } @{$records}));
}

sub append_file {
    my ($root, $relative, $contents) = @_;
    my $path = File::Spec->catfile($root, split m{/+}, $relative);
    open my $fh, '>>:raw', $path or die "cannot append $relative: $!";
    print {$fh} $contents or die "cannot append $relative: $!";
    close $fh or die "cannot close $relative: $!";
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
