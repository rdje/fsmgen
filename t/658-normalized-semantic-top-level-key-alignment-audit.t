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

subtest 'semantic success top-level keys match common plus success-only contract' => sub {
    my $decoded = semantic_json(
        path => File::Spec->catfile($repo_root, 'fsm', 'apb_requester.fsm'),
        expect_success => 1,
    );
    assert_key_set(
        [keys %{$decoded}],
        [@{normalized_semantic_public_top_level_keys()}, @{normalized_semantic_success_only_top_level_keys()}],
        'success report top-level keys',
    );
};

subtest 'semantic failure top-level keys match common contract only' => sub {
    my $decoded = semantic_json(path => write_bad_fixture(), expect_success => 0);
    assert_key_set(
        [keys %{$decoded}],
        normalized_semantic_public_top_level_keys(),
        'failure report top-level keys',
    );
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

sub assert_key_set {
    my ($actual, $expected, $label) = @_;
    is_deeply(as_set($actual), as_set($expected), "$label match contract");
}

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}

sub write_bad_fixture {
    my $bad_path = File::Spec->catfile($tempdir, 'normalized_semantic_key_alignment_bad.fsm');
    write_file(
        $bad_path,
        <<'FSM'
(?fsm:normalized_semantic_key_alignment_bad
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
