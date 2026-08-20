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

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $checker = File::Spec->catfile(
    $repo_root, 'scripts', 'check_claim_verification.pl'
);

subtest 'complete three-leg fixture passes' => sub {
    my $repo = make_fixture();
    my ($ok, $output) = run_checker($repo);
    ok($ok, 'complete bounded fixture passes') or diag($output);
    like($output, qr/records=1, published=1, fixtures=0/,
        'positive result reports the registry classification');
};

subtest 'an exact source record cannot omit a named leg' => sub {
    my $repo = make_fixture();
    mutate_file($repo, 'docs/claim.md', sub {
        $_[0] =~ s/^- Falsify:.*\n//m;
    });
    expect_failure(
        $repo, qr/source does not contain its exact registered record block/,
        'missing source leg'
    );
};

subtest 'a structurally missing registry leg fails closed' => sub {
    my $repo = make_fixture();
    mutate_claim($repo, sub { delete $_[0]{falsify}; });
    expect_failure($repo, qr/missing required key falsify/, 'missing registry leg');
};

subtest 'an aliased re-derive and falsification leg is RED' => sub {
    my $repo = make_fixture();
    mutate_claim($repo, sub {
        my ($claim) = @_;
        $claim->{falsify}{evidence} = $claim->{rederive}{evidence};
        $claim->{falsify}{oracle_paths} = [@{$claim->{rederive}{producer_paths}}];
    }, 1);
    expect_failure($repo, qr/aliases rederive and falsify evidence/,
        'aliased evidence');
};

subtest 'an explicit task-owned missing leg remains publishable' => sub {
    my $repo = make_fixture();
    mutate_claim($repo, sub {
        my ($claim) = @_;
        $claim->{falsify} = {
            evidence => undef,
            gap_owner => 'EXAMPLE.1',
            gap_reason => 'No separating oracle has been selected yet.',
            oracle_paths => [],
            status => 'missing',
        };
    }, 1);
    my ($ok, $output) = run_checker($repo);
    ok($ok, 'an explicit owned gap passes') or diag($output);
};

subtest 'a missing leg without its declared task owner is RED' => sub {
    my $repo = make_fixture();
    mutate_claim($repo, sub {
        my ($claim) = @_;
        $claim->{falsify} = {
            evidence => undef,
            gap_owner => 'EXAMPLE.9',
            gap_reason => 'No separating oracle has been selected yet.',
            oracle_paths => [],
            status => 'missing',
        };
    });
    expect_failure($repo, qr/gap_owner EXAMPLE\.9 is absent/,
        'unowned missing leg');
};

subtest 'absolute and untracked evidence paths are RED' => sub {
    my $absolute = make_fixture();
    mutate_claim($absolute, sub {
        $_[0]{rederive}{producer_paths} = ['/off-volume/producer'];
    });
    expect_failure($absolute, qr/is not a repository-relative local path/,
        'absolute producer path');

    my $untracked = make_fixture();
    write_file($untracked, 'scripts/untracked-producer', "fixture\n");
    mutate_claim($untracked, sub {
        $_[0]{rederive}{producer_paths} = ['scripts/untracked-producer'];
    });
    expect_failure($untracked, qr/is not tracked: scripts\/untracked-producer/,
        'untracked producer path');
};

subtest 'an undeclared exact marker is RED' => sub {
    my $repo = make_fixture();
    write_file(
        $repo,
        'docs/undeclared.md',
        "<!-- CLAIM-VERIFICATION:BEGIN undeclared-claim -->\n"
            . "- Claim: Undeclared.\n"
            . "- Re-derive: A.\n"
            . "- Falsify: B.\n"
            . "- Durability: C.\n"
            . "<!-- CLAIM-VERIFICATION:END undeclared-claim -->\n",
    );
    git_ok($repo, 'add', '--', 'docs/undeclared.md');
    expect_failure($repo, qr/claim marker undeclared-claim is not declared/,
        'undeclared marker');
};

done_testing();

sub base_claim {
    return {
        classification => 'published_claim',
        claim => 'The fixture has a complete three-leg claim record.',
        claim_id => 'fixture-complete-claim',
        durability => {
            evidence => 'Run the tracked watcher whenever the fixture gate executes.',
            gap_owner => undef,
            gap_reason => undef,
            producer_paths => ['registry/claims.jsonl'],
            status => 'available',
            watcher_paths => ['scripts/watcher'],
        },
        falsify => {
            evidence => 'Challenge the claim with the separately tracked oracle.',
            gap_owner => undef,
            gap_reason => undef,
            oracle_paths => ['scripts/oracle'],
            status => 'available',
        },
        owner_path => 'docs/tasks/OWNER.md',
        owner_task => 'EXAMPLE.1',
        record_type => 'claim',
        rederive => {
            evidence => 'Recompute the claim with the tracked producer.',
            gap_owner => undef,
            gap_reason => undef,
            producer_paths => ['scripts/producer'],
            status => 'available',
        },
        schema_version => 1,
        source_path => 'docs/claim.md',
    };
}

sub make_fixture {
    my $repo = create_project_tempdir(purpose => 'claim-verification-tests');
    write_file($repo, '.gitignore', ".artifacts/\n");
    write_file($repo, 'scripts/producer', "fixture producer\n");
    write_file($repo, 'scripts/oracle', "fixture oracle\n");
    write_file($repo, 'scripts/watcher', "fixture watcher\n");
    write_file(
        $repo,
        'docs/tasks/OWNER.md',
        "# Owner\n\n- ID: `EXAMPLE.1`\n  Status: `active`\n",
    );
    my $claim = base_claim();
    write_registry($repo, $claim);
    write_source($repo, $claim);
    git_command_ok($repo, 'init', '-q');
    git_command_ok($repo, 'config', 'user.email', 'fixture@example.invalid');
    git_command_ok($repo, 'config', 'user.name', 'Fixture');
    git_command_ok($repo, 'add', '.');
    git_command_ok($repo, 'commit', '-q', '-m', 'fixture baseline');
    return $repo;
}

sub mutate_claim {
    my ($repo, $mutation, $sync_source) = @_;
    my $path = File::Spec->catfile($repo, 'registry', 'claims.jsonl');
    my @lines = split /\n/, slurp($path);
    my $json = JSON::PP->new->canonical(1)->utf8(1);
    my $claim = $json->decode($lines[1]);
    $mutation->($claim);
    $lines[1] = $json->encode($claim);
    write_file($repo, 'registry/claims.jsonl', join("\n", @lines) . "\n");
    write_source($repo, $claim) if $sync_source;
}

sub write_registry {
    my ($repo, $claim) = @_;
    my $json = JSON::PP->new->canonical(1)->utf8(1);
    my $meta = {
        max_bytes => 8192,
        max_record_bytes => 4096,
        max_records => 8,
        record_type => 'registry',
        schema_version => 1,
    };
    write_file(
        $repo,
        'registry/claims.jsonl',
        $json->encode($meta) . "\n" . $json->encode($claim) . "\n",
    );
}

sub write_source {
    my ($repo, $claim) = @_;
    my $id = $claim->{claim_id};
    write_file(
        $repo,
        'docs/claim.md',
        "# Fixture claim\n\n"
            . "<!-- CLAIM-VERIFICATION:BEGIN $id -->\n"
            . "- Claim: $claim->{claim}\n"
            . "- Re-derive: " . display_leg($claim->{rederive}) . "\n"
            . "- Falsify: " . display_leg($claim->{falsify}) . "\n"
            . "- Durability: " . display_leg($claim->{durability}) . "\n"
            . "<!-- CLAIM-VERIFICATION:END $id -->\n",
    );
}

sub display_leg {
    my ($leg) = @_;
    return $leg->{evidence} if ($leg->{status} // '') eq 'available';
    return "MISSING - $leg->{gap_reason} (owner: $leg->{gap_owner})";
}

sub expect_failure {
    my ($repo, $expected, $label) = @_;
    my ($ok, $output) = run_checker($repo);
    ok(!$ok, "$label fails closed");
    like($output, $expected, "$label reports the separating reason");
}

sub run_checker {
    my ($repo) = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => [$checker, '--root', $repo, '--registry', 'registry/claims.jsonl']
    );
    return ($ok, join('', @{$stdout || []}, @{$stderr || []}));
}

sub mutate_file {
    my ($repo, $relative, $mutation) = @_;
    my $text = slurp(File::Spec->catfile($repo, split m{/}, $relative));
    $mutation->($text);
    write_file($repo, $relative, $text);
}

sub write_file {
    my ($repo, $relative, $contents) = @_;
    my $path = File::Spec->catfile($repo, split m{/}, $relative);
    make_path(dirname($path));
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    print {$fh} $contents;
    close $fh or die "cannot close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $path: $!";
    return $text;
}

sub git_ok {
    my ($repo, @args) = @_;
    git_command_ok($repo, @args);
}

sub git_command_ok {
    my ($repo, @args) = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => ['git', '-C', $repo, @args]
    );
    if (!$ok) {
        die "git @args failed: " . join('', @{$stdout || []}, @{$stderr || []});
    }
}
