#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
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
    $repo, 'scripts', 'check_knowledge_card_history.pl');

subtest 'real exact sources, descriptors, and bounded partitions pass' => sub {
    my ($ok, $output) = run_verifier();
    ok($ok, 'repository knowledge-card history proof passes') or diag($output);
    like($output, qr/exact sources, stable partitions, answer-set equality/,
        'success reports exact retention and semantic partition proof');
};

subtest 'descriptor drift and omission fail independently' => sub {
    my $wrong = copied_archive();
    mutate_descriptors($wrong->{path}, sub {
        return if ($_[0]{descriptor_id} // '') ne
            'knowledge-direct-vhdl-pre-containment-2026-08-01';
        $_[0]{sha256} = '0' x 64;
    });
    my ($wrong_ok, $wrong_output) = run_verifier('--archives', $wrong->{relative});
    ok(!$wrong_ok, 'wrong historical digest fails');
    like($wrong_output, qr/descriptor .* field sha256 changed/,
        'changed descriptor field is named');

    my $missing = copied_archive();
    mutate_descriptors($missing->{path}, sub {
        $_[0]{_delete} = 1
            if ($_[0]{descriptor_id} // '') eq
                'knowledge-ial2-next-slice-pre-containment-2026-08-01';
    });
    my ($missing_ok, $missing_output) = run_verifier('--archives', $missing->{relative});
    ok(!$missing_ok, 'missing historical descriptor fails');
    like($missing_output, qr/missing descriptor knowledge-ial2-next-slice/,
        'missing descriptor is named');
};

subtest 'materialization is deterministic and current-card drift fails' => sub {
    my $current = create_project_tempdir(purpose => 'knowledge-card-current-tests');
    my ($materialized, $materialize_output) = run_verifier(
        '--current-root', $current, '--materialize');
    ok($materialized, 'exact activation sources materialize bounded partitions')
        or diag($materialize_output);
    like($materialize_output, qr/materialized 11 bounded cards/,
        'materialization reports the complete stable partition');

    my ($verified, $verify_output) = run_verifier('--current-root', $current);
    ok($verified, 'independently materialized cards verify') or diag($verify_output);

    my $priority = File::Spec->catfile(
        $current, qw(docs knowledge ial2-feature-completeness-priority.md));
    my $contents = slurp($priority);
    $contents =~ s/current feature completeness priority/current feature priority/;
    write_file($priority, $contents);
    my ($drift_ok, $drift_output) = run_verifier('--current-root', $current);
    ok(!$drift_ok, 'changed answer key fails');
    like($drift_output, qr/bounded replacement drifted|answer lost/,
        'current partition drift is explicit');
};

done_testing();

sub run_verifier {
    my (@args) = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => [$^X, $verifier, '--root', $repo, @args],
    );
    return ($ok, join('', @{$stdout || []}, @{$stderr || []}));
}

sub copied_archive {
    my $dir = create_project_tempdir(purpose => 'knowledge-card-archive-tests');
    my $path = File::Spec->catfile($dir, 'archive.jsonl');
    write_file($path, slurp(File::Spec->catfile(
        $repo, qw(doctrine live_document_size archive_descriptors.jsonl))));
    my $relative = File::Spec->abs2rel($path, $repo);
    $relative =~ s{\\}{/}g;
    return {path => $path, relative => $relative};
}

sub mutate_descriptors {
    my ($path, $mutator) = @_;
    my @records = map { JSON::PP::decode_json($_) }
        grep { $_ ne '' } split /\n/, slurp($path);
    $mutator->($_) for @records;
    @records = grep { !delete $_->{_delete} } @records;
    my $json = JSON::PP->new->canonical(1);
    write_file($path, join('', map { $json->encode($_) . "\n" } @records));
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $contents = <$fh> // '';
    close $fh;
    return $contents;
}

sub write_file {
    my ($path, $contents) = @_;
    make_path(dirname($path)) if !-d dirname($path);
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    print {$fh} $contents or die "cannot write $path: $!";
    close $fh or die "cannot close $path: $!";
}
