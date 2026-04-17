#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

my $tempdir = tempdir(CLEANUP => 1);
my $ok_path = File::Spec->catfile($tempdir, 'check_json_ok.fsm');
my $ok_out_path = File::Spec->catfile($tempdir, 'check_json_ok.sv');
my $bad_path = File::Spec->catfile($tempdir, 'check_json_bad_infix.fsm');
my $bad_out_path = File::Spec->catfile($tempdir, 'check_json_bad_infix.sv');

write_file(
    $ok_path,
    <<'FSM'
(?fsm:check_json_ok
  (+system
    (clock clk)
    (sreset reset)
  )

  (+size
    (COND 1)
    (SRC 8)
    (OUT 8)
  )

  (idle
    (<COND
      (= (OUT SRC))
    )
  )
)
FSM
);

write_file(
    $bad_path,
    <<'FSM'
(?fsm:check_json_bad_infix
  (+system
    (clock clk)
    (sreset reset)
  )

  (+size
    (SRC 8)
    (OUT 8)
  )

  (idle
    (OUT = SRC)
  )
)
FSM
);

subtest 'check json reports success without emitting HDL' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', '-o', $ok_out_path, $ok_path],
    );

    ok($success, 'check JSON succeeds for a strict-clean source');
    is(join('', @{$stderr_buf || []}), '', 'successful check JSON does not print stderr');
    ok(!-e $ok_out_path, 'successful check JSON does not emit an HDL file');

    my $decoded = decode_json(join('', @{$stdout_buf || []}));
    is($decoded->{check_schema_version}, 1, 'success report exposes schema version');
    ok($decoded->{success}, 'success report marks success true');
    is($decoded->{command}{mode}, 'check', 'success report records check mode');
    ok($decoded->{command}{json}, 'success report records JSON mode');
    ok($decoded->{command}{strict_mode}, 'success report records strict mode');
    is($decoded->{source}{resolved_path}, File::Spec->rel2abs($ok_path), 'success report records resolved source path');
    is(scalar(@{$decoded->{diagnostics}}), 0, 'success report has no diagnostics');
    ok(!$decoded->{generated_output}{emitted}, 'success report says no generated output was emitted');
    is($decoded->{result}{module_name}, 'check_json_ok', 'success report keeps the checked module name');
};

subtest 'check json success stays clean without an explicit output path' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check-json', $ok_path],
    );

    ok($success, 'check JSON succeeds without -o');
    is(join('', @{$stderr_buf || []}), '', 'check JSON without -o does not warn on stderr');

    my $decoded = decode_json(join('', @{$stdout_buf || []}));
    ok($decoded->{success}, 'check JSON without -o still reports success');
    ok(!$decoded->{generated_output}{emitted}, 'check JSON without -o still emits no HDL');
};

subtest 'check json reports stable diagnostic code for expected failures' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check-json', '-o', $bad_out_path, $bad_path],
    );

    ok(!$success, 'check JSON exits non-zero for a rejected source');
    is(join('', @{$stderr_buf || []}), '', 'failed check JSON does not print stderr');
    ok(!-e $bad_out_path, 'failed check JSON does not emit an HDL file');

    my $decoded = decode_json(join('', @{$stdout_buf || []}));
    ok(!$decoded->{success}, 'failure report marks success false');
    is($decoded->{command}{mode}, 'check', 'failure report records check mode');
    ok($decoded->{command}{strict_mode}, 'failure report records strict mode');
    is($decoded->{source}{resolved_path}, File::Spec->rel2abs($bad_path), 'failure report records resolved source path');
    is(scalar(@{$decoded->{diagnostics}}), 1, 'failure report carries one diagnostic');

    my $diagnostic = $decoded->{diagnostics}[0];
    is($diagnostic->{code}, 'FSMGEN_STRICT_INFIX_ASSIGNMENT', 'failure report emits the stable diagnostic code');
    is($diagnostic->{severity}, 'error', 'failure report emits severity metadata');
    is($diagnostic->{stability}, 'stable', 'failure report emits stability metadata');
    is($diagnostic->{matched_corpus_entry_id}, 'legacy.infix_assignment.strict_rejection',
        'failure report records the matched support-accounting entry');
    ok($diagnostic->{migration_hint_available}, 'failure report records migration-hint availability');
    is($diagnostic->{source_file}, File::Spec->rel2abs($bad_path), 'failure diagnostic records the source file');
    like($diagnostic->{message}, qr/Strict mode rejects infix assignment '\(OUT = SRC\)'/s,
        'failure diagnostic keeps the human message');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
