#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);

my $repo_root = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $bundle_root = tempdir('fsmgen-issue-bundle-test-XXXXXX', TMPDIR => 1, CLEANUP => 1);
my $bundle_dir = File::Spec->catdir($bundle_root, 'bundle');
my $moved_bundle_dir = File::Spec->catdir($bundle_root, 'moved-bundle');
my $case = File::Spec->catfile($repo_root, 't', 'corpus', 'direct_assignment_pair_form.fsm');
my $helper = File::Spec->catfile($repo_root, 'bin', 'fsmgen-issue-bundle');

subtest 'issue bundle helper creates rerunnable reproduction bundle' => sub {
    run_ok(
        [
            $helper,
            '--case' => $case,
            '--issue-id' => 'helper-smoke',
            '--bundle-dir' => $bundle_dir,
            '--speforge-version' => 'test',
            '--failure-class' => 'unknown',
            '--expected' => 'helper smoke should capture the direct FSM check',
            '--observed' => 'helper smoke',
            '--no-probes',
            '--',
            '--strict',
            '--check',
            '--json',
        ],
        'helper command succeeds',
    );

    ok(-f bundle_file('README.md'), 'bundle README exists');
    ok(-x bundle_file('commands.sh'), 'bundle commands.sh is executable');
    ok(-f bundle_file(qw(sources fsmgen-input direct_assignment_pair_form.fsm)), 'primary artifact is copied');
    exit_is('original', 0, 'original command succeeds during helper capture');
    ok(-s bundle_file(qw(observed stdout original.stdout)), 'original stdout is captured');

    ok(rename($bundle_dir, $moved_bundle_dir), 'bundle can be moved after capture');
    $bundle_dir = $moved_bundle_dir;

    run_ok([bundle_file('commands.sh')], 'generated commands.sh reruns from repo root after bundle move');

    exit_is('original', 0, 'rerun original command succeeds');
    exit_is('check-default', 0, 'rerun default check succeeds');
    exit_is('check-strict', 0, 'rerun strict check succeeds');
    exit_is('semantic-default', 0, 'rerun semantic probe succeeds');
    exit_is('generate-sv', 0, 'rerun SystemVerilog generation succeeds');
    ok(-s bundle_file(qw(observed generated output.sv)), 'rerun captures generated SystemVerilog');
};

done_testing();

sub run_ok {
    my ($command, $label) = @_;

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => $command,
        verbose => 0,
    );

    ok($success, $label)
        or diag(join('', @{$full_buf || []}) || $error_message || 'command failed without output');
}

sub exit_is {
    my ($name, $expected, $label) = @_;

    my $path = bundle_file(qw(observed command-logs), "$name.exit");
    ok(-f $path, "$label exit file exists");
    return unless -f $path;

    open my $fh, '<', $path or die "Unable to read $path: $!";
    my $exit = <$fh>;
    close $fh;
    chomp $exit;

    is($exit, $expected, $label);
}

sub bundle_file {
    return File::Spec->catfile($bundle_dir, @_);
}
