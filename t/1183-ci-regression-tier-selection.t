#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $ci = File::Spec->catfile($repo_root, 'bin', 'ci-regression');

sub run_ci {
    my (@args) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [$ci, @args],
    );

    return {
        success => $success,
        stdout  => join('', @{$stdout_buf || []}),
        stderr  => join('', @{$stderr_buf || []}),
        error   => $error_message,
    };
}

subtest 'list mode advertises concrete quick and ISF test tiers' => sub {
    my $result = run_ci('--list');

    ok($result->{success}, '--list succeeds');
    is($result->{stderr}, '', '--list keeps stderr clean');
    like($result->{stdout}, qr/\Aquick tests:\n/, '--list starts with quick tests');
    like($result->{stdout}, qr/t\/01-regression\.t/, 'quick tier includes basic direct regression');
    like($result->{stdout}, qr/t\/13-composition-source-classification\.t/, 'quick tier includes composition classification');
    like($result->{stdout}, qr/t\/1091-isf-parser-apb-requester\.t/, 'quick tier includes ISF parsing smoke');
    like($result->{stdout}, qr/isf tests:\n/, '--list includes ISF tier');
    like($result->{stdout}, qr/t\/1182-isf-rule-trigger-target-boundary\.t/, 'ISF tier includes the latest ISF boundary test');
};

subtest 'dry-run modes select the expected command families' => sub {
    my $quick = run_ci('quick', '--dry-run');
    ok($quick->{success}, 'quick dry-run succeeds');
    is($quick->{stderr}, '', 'quick dry-run keeps stderr clean');
    like($quick->{stdout}, qr/==> Perl quick smoke suite/, 'quick dry-run selects quick suite');
    like($quick->{stdout}, qr/t\/1112-isf-public-interface-contract\.t/, 'quick dry-run includes ISF public contract smoke');
    like($quick->{stdout}, qr/==> mdBook build/, 'quick dry-run builds the book by default');

    my $isf = run_ci('isf', '--dry-run', '--no-book');
    ok($isf->{success}, 'ISF dry-run succeeds');
    is($isf->{stderr}, '', 'ISF dry-run keeps stderr clean');
    like($isf->{stdout}, qr/==> Perl ISF regression suite/, 'ISF dry-run selects ISF suite');
    like($isf->{stdout}, qr/t\/1182-isf-rule-trigger-target-boundary\.t/, 'ISF dry-run includes latest ISF test');
    unlike($isf->{stdout}, qr/mdBook build/, '--no-book suppresses book build');

    my $full = run_ci('full', '--dry-run');
    ok($full->{success}, 'full dry-run succeeds');
    is($full->{stderr}, '', 'full dry-run keeps stderr clean');
    like($full->{stdout}, qr/==> Perl regression suite/, 'full dry-run selects full suite');
    like($full->{stdout}, qr/\bprove\s+-I\s+perl\s+t\b/, 'full dry-run preserves default prove command');
};

subtest 'unknown modes fail with usage' => sub {
    my $result = run_ci('fast');

    ok(!$result->{success}, 'unknown mode fails');
    like($result->{stderr}, qr/ci-regression: unknown argument: fast/, 'unknown mode diagnostic names the argument');
    like($result->{stderr}, qr/Usage: \.\/bin\/ci-regression/, 'unknown mode prints usage');
};

done_testing();
