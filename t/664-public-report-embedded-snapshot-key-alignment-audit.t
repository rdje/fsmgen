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

use FSM::Support::SerializableCompositionPlanSnapshot qw(serializable_composition_plan_snapshot_public_top_level_keys);
use FSM::Support::SerializableDiagnosticSummary qw(serializable_diagnostic_summary_public_top_level_keys);
use FSM::Support::SerializableGenerationResultSnapshot qw(serializable_generation_result_snapshot_public_top_level_keys);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $semantic_fixture = File::Spec->catfile($repo_root, 'fsm', 'apb_tb.fsm');
my $tempdir = tempdir(CLEANUP => 1);

subtest 'semantic JSON embedded snapshots match standalone key lists' => sub {
    my $report = command_json(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $semantic_fixture],
        expect_success => 1,
        label => 'semantic JSON',
    );

    assert_key_set(
        [keys %{$report->{generation_result_snapshot}}],
        serializable_generation_result_snapshot_public_top_level_keys(),
        'semantic generation_result_snapshot',
    );
    assert_key_set(
        [keys %{$report->{semantic}{composition}{plan_snapshot}}],
        serializable_composition_plan_snapshot_public_top_level_keys(),
        'semantic composition plan_snapshot',
    );
    assert_key_set(
        [keys %{$report->{diagnostic_summary}}],
        serializable_diagnostic_summary_public_top_level_keys(),
        'semantic diagnostic_summary',
    );
};

subtest 'check JSON diagnostic summary matches standalone key list' => sub {
    my $report = command_json(
        command => ['./bin/fsmgen', '--strict', '--check-json', write_bad_fixture()],
        expect_success => 0,
        label => 'check JSON',
    );

    assert_key_set(
        [keys %{$report->{diagnostic_summary}}],
        serializable_diagnostic_summary_public_top_level_keys(),
        'check diagnostic_summary',
    );
};

done_testing();

sub command_json {
    my (%args) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => $args{command},
    );

    is($success ? 1 : 0, $args{expect_success} ? 1 : 0, "$args{label} exits as expected");
    is(join('', @{$stderr_buf || []}), '', "$args{label} keeps stderr clean");
    return decode_json(join('', @{$stdout_buf || []}));
}

sub assert_key_set {
    my ($actual, $expected, $label) = @_;
    is_deeply(as_set($actual), as_set($expected), "$label keys match standalone contract");
}

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}

sub write_bad_fixture {
    my $bad_path = File::Spec->catfile($tempdir, 'public_report_snapshot_key_bad.fsm');
    write_file(
        $bad_path,
        <<'FSM'
(?fsm:public_report_snapshot_key_bad
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
