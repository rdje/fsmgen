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

use FSM::Support::NormalizedSemanticReportContract qw(
    normalized_semantic_public_top_level_keys
    normalized_semantic_success_only_top_level_keys
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $tempdir = tempdir(CLEANUP => 1);

subtest 'successful semantic JSON keeps advertised snapshot top-level keys' => sub {
    my $decoded = semantic_json(
        path => File::Spec->catfile($repo_root, 'fsm', 'apb_requester.fsm'),
        expect_success => 1,
    );

    assert_keys_present($decoded, normalized_semantic_public_top_level_keys(), 'success top-level');
    assert_keys_present($decoded, normalized_semantic_success_only_top_level_keys(), 'success-only top-level');
    ok($decoded->{diagnostic_summary}, 'success report includes diagnostic_summary');
    ok($decoded->{generation_result_snapshot}, 'success report includes generation_result_snapshot');
};

subtest 'failed semantic JSON keeps advertised common keys and omits success-only snapshots' => sub {
    my $decoded = semantic_json(
        path => write_bad_fixture(),
        expect_success => 0,
    );

    assert_keys_present($decoded, normalized_semantic_public_top_level_keys(), 'failure top-level');
    ok($decoded->{diagnostic_summary}, 'failure report includes diagnostic_summary');
    for my $key (@{normalized_semantic_success_only_top_level_keys()}) {
        ok(!exists $decoded->{$key}, "failure report omits success-only key $key");
    }
};

done_testing();

sub semantic_json {
    my (%args) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $args{path}],
    );

    is($success ? 1 : 0, $args{expect_success} ? 1 : 0, "semantic JSON exits as expected for $args{path}");
    is(join('', @{$stderr_buf || []}), '', "semantic JSON keeps stderr clean for $args{path}");
    return decode_json(join('', @{$stdout_buf || []}));
}

sub assert_keys_present {
    my ($payload, $keys, $label) = @_;
    for my $key (@{$keys || []}) {
        ok(exists $payload->{$key}, "$label keeps key $key");
    }
}

sub write_bad_fixture {
    my $bad_path = File::Spec->catfile($tempdir, 'normalized_semantic_snapshot_presence_bad.fsm');
    write_file(
        $bad_path,
        <<'FSM'
(?fsm:normalized_semantic_snapshot_presence_bad
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
    return $bad_path;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
