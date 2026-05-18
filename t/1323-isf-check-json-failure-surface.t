#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

subtest 'ISF lowering failures emit check JSON instead of empty stdout' => sub {
    my $decoded = run_failed_check_json_source(<<'ISF', 'bad_contract.isf');
(actor bad_contract
  (clock clk)
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (always ack))
    (complete done)))
ISF

    ok(!$decoded->{success}, 'lowering failure marks success false');
    is(scalar(@{$decoded->{diagnostics} || []}), 1, 'lowering failure emits one diagnostic');
    like(
        $decoded->{diagnostics}[0]{message},
        qr/\ATransaction 'main': contract 'ack_seen' supports only '\(eventually signal within cycles\)' or '\(eventually signal \(within cycles\)\)'/,
        'lowering diagnostic is preserved in the JSON payload',
    );
    is($decoded->{command}{mode}, 'check', 'failure payload keeps check command mode');
    ok($decoded->{command}{json}, 'failure payload records JSON mode');
};

subtest 'ISF semantic conflicts emit check JSON instead of empty stdout' => sub {
    my $decoded = run_failed_check_json_source(<<'ISF', 'stage_conflict.isf');
(actor stage_conflict
  (clock clk)
  (interface
    (input start)
    (input ready)
    (output valid)
    (output done))
  (rule force_valid
    (valid 1))
  (transaction main
    (on start)
    (stage accept (ready ready) (valid valid))
    (complete done)))
ISF

    ok(!$decoded->{success}, 'semantic conflict marks success false');
    is(scalar(@{$decoded->{diagnostics} || []}), 1, 'semantic conflict emits one diagnostic');
    like(
        $decoded->{diagnostics}[0]{message},
        qr/ISF conflict 'isf_priority_mixed_timing_conflict' on target 'valid'.*rule 'force_valid'.*transaction 'main' \(stage_valid, = 1\)/s,
        'semantic conflict diagnostic is preserved in the JSON payload',
    );
    ok(!$decoded->{generated_output}{emitted}, 'failure payload records no generated output');
};

done_testing();

sub run_failed_check_json_source {
    my ($source, $basename) = @_;

    my $tempdir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($tempdir, $basename);
    write_file($path, $source);

    my ($success, undef, undef, $stdout, $stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check-json', $path],
    );

    ok(!$success, "$basename fails the check");
    is(join('', @{$stderr || []}), '', "$basename keeps stderr clean");

    my $payload = join('', @{$stdout || []});
    isnt($payload, '', "$basename emits JSON on stdout");
    my $decoded = eval { decode_json($payload) };
    ok(!$@, "$basename emits decodable JSON");

    return $decoded;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
