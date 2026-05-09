#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json encode_json);
use Scalar::Util qw(blessed);

my $tempdir = tempdir(CLEANUP => 1);
my $bad_path = File::Spec->catfile($tempdir, 'check_json_summary_roundtrip_bad.fsm');

write_file(
    $bad_path,
    <<'FSM'
(?fsm:check_json_summary_roundtrip_bad
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

subtest 'check JSON diagnostic summary survives JSON round trip' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check-json', $bad_path],
    );

    ok(!$success, 'check JSON command fails for invalid fixture');
    is(join('', @{$stderr_buf || []}), '', 'check JSON keeps stderr clean');
    my $decoded = decode_json(join('', @{$stdout_buf || []}));
    my $roundtrip = decode_json(encode_json($decoded));

    ok(!contains_blessed($roundtrip), 'round-tripped check report contains no unexpected blessed values');
    ok($roundtrip->{diagnostic_summary}, 'round-trip report keeps diagnostic_summary');
    is($roundtrip->{diagnostic_summary}{diagnostic_count}, 1, 'round-trip summary keeps diagnostic count');
    ok(@{$roundtrip->{diagnostic_summary}{unique_codes}} == 1, 'round-trip summary keeps unique code list');
    is($roundtrip->{diagnostic_summary}{severity_counts}{error}, 1, 'round-trip summary keeps error count');
    ok(!exists $roundtrip->{result}, 'round-trip failure report still omits success-only result');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub contains_blessed {
    my ($value) = @_;
    return 0 if blessed($value) && blessed($value) eq 'JSON::PP::Boolean';
    return 1 if blessed($value);
    return 0 unless ref($value);

    if (ref($value) eq 'ARRAY') {
        return 1 if grep { contains_blessed($_) } @$value;
        return 0;
    }

    if (ref($value) eq 'HASH') {
        return 1 if grep { contains_blessed($_) } values %$value;
        return 0;
    }

    return 0;
}
