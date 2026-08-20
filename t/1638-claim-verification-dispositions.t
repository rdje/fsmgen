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
use JSON::PP;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::ProjectDataLocality qw(create_project_tempdir);

my $project_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $checker = File::Spec->catfile(
    $project_root, 'scripts', 'check_claim_verification_dispositions.pl'
);

subtest 'all four bounded disposition outcomes join current candidates' => sub {
    my $repo = make_fixture();
    my ($ok, $output) = run_checker($repo, '--report');
    ok($ok, 'complete disposition fixture passes') or diag($output);
    like(
        $output,
        qr/candidates=4, disposed=4, claim_records=1, gates=1, reviewed=1, gaps=1, open=0/,
        'outcome and open counts are explicit'
    );
    like($output, qr/group fixture disposed=4 total=4 open=0 required_complete=1/,
        'required group completeness is explicit');
};

subtest 'stale candidate IDs fail closed' => sub {
    my $repo = make_fixture();
    mutate_dispositions($repo, sub {
        $_[0][1]{candidate_id} = 'published-999999999999999999999999';
    });
    fails_like($repo, qr/stale or unknown candidate_id/, 'stale candidate');
};

subtest 'duplicate candidate dispositions fail closed' => sub {
    my $repo = make_fixture();
    mutate_dispositions($repo, sub {
        push @{$_[0]}, {%{$_[0][-1]}};
    });
    fails_like($repo, qr/duplicates candidate_id/, 'duplicate candidate');
};

subtest 'unknown disposition kinds fail closed' => sub {
    my $repo = make_fixture();
    mutate_dispositions($repo, sub {
        $_[0][-1]{disposition} = 'assumed_true';
    });
    fails_like($repo, qr/unknown disposition/, 'unknown outcome');
};

subtest 'missing derived-gate evidence fails closed' => sub {
    my $repo = make_fixture();
    mutate_dispositions($repo, sub {
        delete $_[0][2]{falsify}{oracle_paths};
    });
    fails_like($repo, qr/falsify is missing required key oracle_paths/,
        'missing evidence');
};

subtest 'aliased rederive and falsify paths fail closed' => sub {
    my $repo = make_fixture();
    mutate_dispositions($repo, sub {
        $_[0][2]{falsify}{oracle_paths} = ['scripts/rederive.pl'];
    });
    fails_like($repo, qr/aliases rederive producers and falsification oracles/,
        'aliased legs');
};

subtest 'required groups cannot hide an undisposed candidate' => sub {
    my $repo = make_fixture();
    mutate_dispositions($repo, sub { pop @{$_[0]} });
    fails_like($repo, qr/requires completeness but has 1 open candidate/,
        'incomplete group');
};

subtest 'claim-record source identity must match the candidate path' => sub {
    my $repo = make_fixture();
    mutate_jsonl($repo, 'doctrine/claim_verification/claims.jsonl', sub {
        $_[0][1]{source_path} = 'docs/book/src/other.md';
    });
    fails_like($repo, qr/claim source_path does not match the candidate path/,
        'fabricated source identity');
};

subtest 'owned gaps must name a live repair task' => sub {
    my $repo = make_fixture();
    my $task_path = path($repo, 'docs/tasks/EXAMPLE.md');
    my $task = slurp($task_path);
    $task =~ s/Status: `pending`/Status: `done`/;
    write_file($repo, 'docs/tasks/EXAMPLE.md', $task);
    fails_like($repo, qr/gap_owner REPAIR[.]1 is not a live repair task/,
        'closed repair owner');
};

done_testing();

sub make_fixture {
    my $repo = create_project_tempdir(purpose => 'claim-disposition-tests');
    write_file($repo, '.gitignore', ".artifacts/\n");
    write_file($repo, 'docs/book/src/page.md', "# Fixture\n");
    write_file($repo, 'docs/book/src/other.md', "# Other\n");
    write_file(
        $repo, 'docs/tasks/EXAMPLE.md',
        "- ID: `EXAMPLE.1`\n  Status: `active`\n"
            . "- ID: `REPAIR.1`\n  Status: `pending`\n"
    );
    for my $path (qw(
        scripts/rederive.pl scripts/oracle.pl scripts/durability.pl
        scripts/watcher.pl
    )) {
        write_file($repo, $path, "fixture evidence\n");
    }

    my @candidate_ids = map { 'published-' . ($_ x 24) } qw(1 2 3 4);
    write_jsonl(
        $repo, 'doctrine/claim_verification/inventory.jsonl',
        registry(8_388_608, 4096, 8192),
        map {
            {
                candidate_id => $_,
                migration_owner => 'CLAIM-VERIFICATION-ADOPTION.5',
                path => 'docs/book/src/page.md',
                record_type => 'published_candidate',
            }
        } @candidate_ids
    );
    write_jsonl(
        $repo, 'doctrine/claim_verification/claims.jsonl',
        registry(65_536, 4096, 256),
        {
            claim_id => 'fixture-published-claim',
            classification => 'published_claim',
            record_type => 'claim',
            source_path => 'docs/book/src/page.md',
        }
    );
    write_jsonl(
        $repo, 'doctrine/claim_verification/disposition_groups.jsonl',
        registry(32_768, 8192, 8),
        {
            group_id => 'fixture',
            owner_task => 'EXAMPLE.1',
            paths => ['docs/book/src/page.md'],
            record_type => 'candidate_group',
            required_complete => JSON::PP::true,
            schema_version => 1,
        }
    );
    write_jsonl(
        $repo, 'doctrine/claim_verification/dispositions.jsonl',
        registry(4_194_304, 8192, 2048),
        {
            candidate_id => $candidate_ids[0],
            claim_id => 'fixture-published-claim',
            disposition => 'claim_record',
            owner_path => 'docs/tasks/EXAMPLE.md',
            owner_task => 'EXAMPLE.1',
            record_type => 'disposition',
            schema_version => 1,
        },
        {
            candidate_id => $candidate_ids[1],
            disposition => 'derived_gate',
            durability => {
                evidence => 'The registered watcher reruns the durable producer.',
                producer_paths => ['scripts/durability.pl'],
                watcher_paths => ['scripts/watcher.pl'],
            },
            falsify => {
                competing_hypothesis => 'The producer can emit a plausible but false result.',
                evidence => 'The independent oracle rejects a mutated result.',
                oracle_paths => ['scripts/oracle.pl'],
            },
            owner_path => 'docs/tasks/EXAMPLE.md',
            owner_task => 'EXAMPLE.1',
            record_type => 'disposition',
            rederive => {
                evidence => 'The producer recomputes the value from source inputs.',
                producer_paths => ['scripts/rederive.pl'],
            },
            schema_version => 1,
        },
        {
            candidate_id => $candidate_ids[2],
            disposition => 'owned_gap',
            gap_owner => 'REPAIR.1',
            gap_owner_path => 'docs/tasks/EXAMPLE.md',
            gap_reason => 'The separating falsification oracle is not implemented yet.',
            missing_legs => ['falsify'],
            owner_path => 'docs/tasks/EXAMPLE.md',
            owner_task => 'EXAMPLE.1',
            record_type => 'disposition',
            schema_version => 1,
        },
        {
            candidate_id => $candidate_ids[3],
            disposition => 'reviewed_incidental',
            owner_path => 'docs/tasks/EXAMPLE.md',
            owner_task => 'EXAMPLE.1',
            reason => 'This numeral is a syntax example, not a project measurement.',
            reason_code => 'syntax_or_example_value',
            record_type => 'disposition',
            schema_version => 1,
        }
    );

    git_ok($repo, 'init', '-q');
    git_ok($repo, 'config', 'user.email', 'fixture@example.invalid');
    git_ok($repo, 'config', 'user.name', 'Fixture');
    git_ok($repo, 'add', '.');
    git_ok($repo, 'commit', '-q', '-m', 'fixture');
    return $repo;
}

sub registry {
    my ($max_bytes, $max_record_bytes, $max_records) = @_;
    return {
        max_bytes => $max_bytes,
        max_record_bytes => $max_record_bytes,
        max_records => $max_records,
        record_type => 'registry',
        schema_version => 1,
    };
}

sub mutate_dispositions {
    my ($repo, $mutation) = @_;
    mutate_jsonl(
        $repo, 'doctrine/claim_verification/dispositions.jsonl', $mutation
    );
}

sub mutate_jsonl {
    my ($repo, $relative, $mutation) = @_;
    my @records = map { JSON::PP->new->utf8(1)->decode($_) }
        grep { $_ ne '' } split /\n/, slurp(path($repo, $relative));
    $mutation->(\@records);
    write_jsonl($repo, $relative, @records);
}

sub fails_like {
    my ($repo, $pattern, $label) = @_;
    my ($ok, $output) = run_checker($repo);
    ok(!$ok, "$label fails");
    like($output, $pattern, "$label diagnostic is exact");
}

sub run_checker {
    my ($repo, @args) = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => [$checker, '--root', $repo, @args],
    );
    return ($ok, join('', @{$stdout || []}, @{$stderr || []}));
}

sub write_jsonl {
    my ($repo, $relative, @records) = @_;
    my $json = JSON::PP->new->canonical(1)->utf8(1);
    write_file($repo, $relative, join("\n", map { $json->encode($_) } @records) . "\n");
}

sub write_file {
    my ($repo, $relative, $contents) = @_;
    my $file = path($repo, $relative);
    make_path(dirname($file));
    open my $fh, '>:raw', $file or die "cannot write $file: $!";
    print {$fh} $contents;
    close $fh or die "cannot close $file: $!";
}

sub slurp {
    my ($file) = @_;
    open my $fh, '<:raw', $file or die "cannot read $file: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $file: $!";
    return $text;
}

sub path {
    my ($repo, $relative) = @_;
    return File::Spec->catfile($repo, split m{/}, $relative);
}

sub git_ok {
    my ($repo, @args) = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => ['git', '-C', $repo, @args],
    );
    die "git @args failed: " . join('', @{$stdout || []}, @{$stderr || []})
        if !$ok;
}
