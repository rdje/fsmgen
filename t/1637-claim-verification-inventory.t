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
    $project_root, 'scripts', 'check_claim_verification_inventory.pl'
);

subtest 'derived inventory and independent census agree' => sub {
    my $repo = make_fixture();
    my ($ok, $output) = run_checker($repo, '--report');
    ok($ok, 'complete inventory passes') or diag($output);
    like($output, qr/current-surface census and independent census agree/,
        'independent parity is explicit');
    my $records = read_inventory($repo);
    ok(grep(($_->{classification} // '') eq 'actionable_quantitative', @{$records}),
        'quantified prose is inventoried as actionable');
    ok(grep(($_->{record_type} // '') eq 'repository_constant', @{$records}),
        'numeric control-plane leaves are inventoried');
};

subtest 'source mutation makes the tracked inventory RED' => sub {
    my $repo = make_fixture();
    append_file($repo, 'README.md', "The second census contains 43 files.\n");
    my ($ok, $output) = run_checker($repo);
    ok(!$ok, 'stale inventory fails closed');
    like($output, qr/inventory drift/, 'RED names regeneration rather than passing stale data');
};

subtest 'unknown numeric prose cannot fall into an incidental default' => sub {
    my $repo = make_fixture();
    mutate_file($repo, 'README.md', sub {
        $_[0] =~ s/42 files/42 widgets/;
    });
    run_checker_ok($repo, '--write');
    my $records = read_inventory($repo);
    my @review = grep {
        $_->{record_type} eq 'published_candidate'
            && $_->{classification} eq 'actionable_review_debt'
    } @{$records};
    ok(@review == 1, 'classifier mutation becomes explicit review debt');
    is($review[0]{migration_owner}, 'CLAIM-VERIFICATION-ADOPTION.5',
        'classifier RED retains an exact migration owner');
};

subtest 'referenced untracked producers remain visible' => sub {
    my $repo = make_fixture();
    mutate_file($repo, 'README.md', sub {
        $_[0] =~ s{scripts/producer[.]pl}{scripts/missing.pl};
    });
    run_checker_ok($repo, '--write');
    my $records = read_inventory($repo);
    my @untracked = grep {
        $_->{record_type} eq 'published_candidate'
            && $_->{producer_status} eq 'untracked'
    } @{$records};
    ok(@untracked == 1, 'untracked producer is inventoried');
    is_deeply($untracked[0]{untracked_paths}, ['scripts/missing.pl'],
        'the exact untracked path is retained');
};

subtest 'operational identifiers and fenced examples are partitioned' => sub {
    my $repo = make_fixture();
    my $records = read_inventory($repo);
    my ($census) = grep { $_->{record_type} eq 'census' } @{$records};
    is($census->{excluded_operational_paths}, 1,
        'operational path exclusion is explicit');
    is($census->{incidental_partitions}{code_or_data_example}, 1,
        'fenced numeric example is explicitly partitioned');
};

done_testing();

sub make_fixture {
    my $repo = create_project_tempdir(purpose => 'claim-inventory-tests');
    write_file($repo, '.gitignore', ".artifacts/\n");
    write_file(
        $repo, 'README.md',
        "# Fixture\n\nThe inventory contains 42 files from `scripts/producer.pl`.\n"
            . "Version `2.0` is an identifier.\n",
    );
    write_file($repo, 'MEMORY.md', "active task EXAMPLE.42\n");
    write_file(
        $repo, 'docs/book/src/chapter.md',
        "# Chapter\n\n```text\n(example 99 files)\n```\n",
    );
    write_file($repo, 'scripts/producer.pl', "fixture producer\n");
    write_file(
        $repo, 'scripts/check_claim_verification_inventory.pl',
        "fixture inventory checker\n"
    );
    write_file($repo, 'scripts/check_doctrines.sh', "fixture watcher\n");
    write_file($repo, 'scripts/check_live_document_size.sh', "fixture checker\n");
    write_file($repo, 't/1554-live-document-size-doctrine.t', "fixture oracle\n");
    write_file($repo, 't/1637-claim-verification-inventory.t', "fixture RED oracle\n");
    my $json = JSON::PP->new->canonical(1)->utf8(1);
    write_file(
        $repo, 'doctrine/live_document_size/surfaces.jsonl',
        $json->encode({record_type => 'registry', schema_version => 1}) . "\n"
            . $json->encode({
                record_type => 'surface', schema_version => 1,
                surface_id => 'root_documents', targets => ['*.md'],
            }) . "\n"
            . $json->encode({
                record_type => 'surface', schema_version => 1,
                surface_id => 'shipped_behavior', targets => ['docs/book/src/*.md'],
            }) . "\n",
    );
    write_file(
        $repo, 'doctrine/live_document_size/config.jsonl',
        $json->encode({
            max_records => 8, record_type => 'registry', schema_version => 1,
        }) . "\n",
    );
    write_file(
        $repo, 'doctrine/claim_verification/inventory_scope.json',
        $json->encode({
            constant_globs => ['doctrine/live_document_size/*.jsonl'],
            derived_projection_paths => [],
            excluded_operational_paths => ['MEMORY.md'],
            inventory_path => 'doctrine/claim_verification/inventory.jsonl',
            local_adoption_paths => [],
            portable_policy_paths => [],
            record_type => 'scope',
            schema_version => 1,
            surface_ids => ['root_documents', 'shipped_behavior'],
            surface_registry => 'doctrine/live_document_size/surfaces.jsonl',
        }) . "\n",
    );
    git_ok($repo, 'init', '-q');
    git_ok($repo, 'config', 'user.email', 'fixture@example.invalid');
    git_ok($repo, 'config', 'user.name', 'Fixture');
    git_ok($repo, 'add', '.');
    git_ok($repo, 'commit', '-q', '-m', 'fixture sources');
    run_checker_ok($repo, '--write');
    git_ok($repo, 'add', 'doctrine/claim_verification/inventory.jsonl');
    git_ok($repo, 'commit', '-q', '-m', 'fixture inventory');
    return $repo;
}

sub read_inventory {
    my ($repo) = @_;
    my $path = File::Spec->catfile(
        $repo, 'doctrine', 'claim_verification', 'inventory.jsonl'
    );
    my $json = JSON::PP->new->utf8(1);
    return [map { $json->decode($_) } grep { $_ ne '' } split /\n/, slurp($path)];
}

sub run_checker_ok {
    my ($repo, @args) = @_;
    my ($ok, $output) = run_checker($repo, @args);
    die "claim inventory fixture command failed: $output" if !$ok;
    return $output;
}

sub run_checker {
    my ($repo, @args) = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => [
            $checker, '--root', $repo,
            '--scope', 'doctrine/claim_verification/inventory_scope.json',
            @args,
        ],
    );
    return ($ok, join('', @{$stdout || []}, @{$stderr || []}));
}

sub write_file {
    my ($repo, $relative, $contents) = @_;
    my $path = File::Spec->catfile($repo, split m{/}, $relative);
    make_path(dirname($path));
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    print {$fh} $contents;
    close $fh or die "cannot close $path: $!";
}

sub append_file {
    my ($repo, $relative, $contents) = @_;
    my $path = File::Spec->catfile($repo, split m{/}, $relative);
    open my $fh, '>>:raw', $path or die "cannot append $path: $!";
    print {$fh} $contents;
    close $fh or die "cannot close $path: $!";
}

sub mutate_file {
    my ($repo, $relative, $mutation) = @_;
    my $path = File::Spec->catfile($repo, split m{/}, $relative);
    my $text = slurp($path);
    $mutation->($text);
    write_file($repo, $relative, $text);
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
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => ['git', '-C', $repo, @args]
    );
    die "git @args failed: " . join('', @{$stdout || []}, @{$stderr || []})
        if !$ok;
}
