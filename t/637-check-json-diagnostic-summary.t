#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializableDiagnosticSummary qw(
    serializable_diagnostic_summary_contract_source
    serializable_diagnostic_summary_public_top_level_keys
);

my $tempdir = tempdir(CLEANUP => 1);
my $ok_path = File::Spec->catfile($tempdir, 'check_json_diagnostic_summary_ok.fsm');
my $bad_path = File::Spec->catfile($tempdir, 'check_json_diagnostic_summary_bad.fsm');

write_file(
    $ok_path,
    <<'FSM'
(?fsm:check_json_diagnostic_summary_ok
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
(?fsm:check_json_diagnostic_summary_bad
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

subtest 'successful check JSON embeds an empty diagnostic summary' => sub {
    my $decoded = check_json(path => $ok_path, expect_success => 1);
    my $summary = $decoded->{diagnostic_summary};

    assert_summary_shell($summary);
    ok($summary->{success}, 'successful check summary records success');
    is($summary->{diagnostic_count}, 0, 'successful check summary records zero diagnostics');
    ok(!$summary->{has_diagnostics}, 'successful check summary records no diagnostic presence');
    ok(length(encode_json($summary)), 'successful check summary encodes as JSON');
};

subtest 'failed check JSON embeds a stable-code diagnostic summary' => sub {
    my $decoded = check_json(path => $bad_path, expect_success => 0);
    my $summary = $decoded->{diagnostic_summary};

    assert_summary_shell($summary);
    ok(!$summary->{success}, 'failed check summary records failure');
    is($summary->{diagnostic_count}, 1, 'failed check summary records one diagnostic');
    is_deeply($summary->{unique_codes}, ['FSMGEN_STRICT_INFIX_ASSIGNMENT'], 'failed check summary records stable code');
    ok($summary->{has_diagnostics}, 'failed check summary records diagnostic presence');
    ok($summary->{has_stable_codes}, 'failed check summary records stable-code presence');
    ok($summary->{matched_support_accounting}, 'failed check summary records support-accounting match presence');
    ok(length(encode_json($summary)), 'failed check summary encodes as JSON');
};

done_testing();

sub check_json {
    my (%args) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check-json', $args{path}],
    );

    if ($args{expect_success}) {
        ok($success, "check JSON succeeds for $args{path}");
    } else {
        ok(!$success, "check JSON fails for $args{path}");
    }
    is(join('', @{$stderr_buf || []}), '', "check JSON keeps stderr clean for $args{path}");

    my $decoded = decode_json(join('', @{$stdout_buf || []}));
    is($decoded->{success} ? 1 : 0, $args{expect_success} ? 1 : 0, "check JSON reports expected success flag for $args{path}");
    return $decoded;
}

sub assert_summary_shell {
    my ($summary) = @_;
    ok($summary, 'check report includes diagnostic_summary');
    for my $key (@{serializable_diagnostic_summary_public_top_level_keys()}) {
        ok(exists $summary->{$key}, "diagnostic_summary keeps key $key");
    }
    is($summary->{contract_source}, serializable_diagnostic_summary_contract_source(), 'diagnostic_summary records contract owner');
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
