#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CheckDiagnosticsContract qw(
    check_json_public_top_level_keys
    check_json_success_only_top_level_keys
);

my $tempdir = tempdir(CLEANUP => 1);
my $ok_path = File::Spec->catfile($tempdir, 'check_json_summary_presence_ok.fsm');
my $bad_path = File::Spec->catfile($tempdir, 'check_json_summary_presence_bad.fsm');

write_file(
    $ok_path,
    <<'FSM'
(?fsm:check_json_summary_presence_ok
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
(?fsm:check_json_summary_presence_bad
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

subtest 'successful check JSON keeps advertised diagnostic summary keys' => sub {
    my $decoded = check_json(path => $ok_path, expect_success => 1);
    assert_keys_present($decoded, check_json_public_top_level_keys(), 'success top-level');
    assert_keys_present($decoded, check_json_success_only_top_level_keys(), 'success-only top-level');
    ok($decoded->{diagnostic_summary}, 'success report includes diagnostic_summary');
    ok($decoded->{result}, 'success report includes result');
};

subtest 'failed check JSON keeps common summary key and omits success-only result' => sub {
    my $decoded = check_json(path => $bad_path, expect_success => 0);
    assert_keys_present($decoded, check_json_public_top_level_keys(), 'failure top-level');
    ok($decoded->{diagnostic_summary}, 'failure report includes diagnostic_summary');
    for my $key (@{check_json_success_only_top_level_keys()}) {
        ok(!exists $decoded->{$key}, "failure report omits success-only key $key");
    }
};

done_testing();

sub check_json {
    my (%args) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check-json', $args{path}],
    );

    is($success ? 1 : 0, $args{expect_success} ? 1 : 0, "check JSON exits as expected for $args{path}");
    is(join('', @{$stderr_buf || []}), '', "check JSON keeps stderr clean for $args{path}");
    return decode_json(join('', @{$stdout_buf || []}));
}

sub assert_keys_present {
    my ($payload, $keys, $label) = @_;
    for my $key (@{$keys || []}) {
        ok(exists $payload->{$key}, "$label keeps key $key");
    }
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
