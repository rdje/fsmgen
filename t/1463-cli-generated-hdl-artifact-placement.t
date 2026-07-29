#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path getcwd);
use File::Copy qw(copy);
use File::Basename qw(basename);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $fsmgen = File::Spec->catfile($repo_root, 'bin', 'fsmgen');
my $trial_fsm = File::Spec->catfile($repo_root, 'fsm', 'trial_0.fsm');
my $vhdl_fsm = File::Spec->catfile($repo_root, 't', 'corpus', 'direct_assignment_pair_form.fsm');
my $multi_domain_isf = File::Spec->catfile($repo_root, 'isf', 'clock_domain_event_crossing.isf');
my $source_dir = tempdir(CLEANUP => 1);
my $unique = basename($source_dir);
my $local_trial_fsm = File::Spec->catfile($source_dir, "${unique}_trial.fsm");
my $local_vhdl_fsm = File::Spec->catfile($source_dir, "${unique}_vhdl.fsm");
copy($trial_fsm, $local_trial_fsm) or die "cannot copy $trial_fsm to $local_trial_fsm: $!";
copy($vhdl_fsm, $local_vhdl_fsm) or die "cannot copy $vhdl_fsm to $local_vhdl_fsm: $!";

subtest 'implicit generated SystemVerilog lands under repository artifacts directory' => sub {
    my $workdir = tempdir(CLEANUP => 1);
    my $expected = File::Spec->catfile($repo_root, '.artifacts', 'sv', "${unique}_trial.sv");
    my $unexpected_root = File::Spec->catfile($workdir, "${unique}_trial.sv");

    in_directory($workdir, sub {
        my ($success, undef, undef, undef, $stderr_buf) = run(
            command => [$fsmgen, '--quiet', $local_trial_fsm],
        );

        ok($success, 'default SystemVerilog generation succeeds');
        is(join('', @{$stderr_buf || []}), '', 'default SystemVerilog generation keeps stderr clean');
    });

    ok(-f $expected, 'default SystemVerilog output is under repository .artifacts/sv');
    ok(!-e $unexpected_root, 'default SystemVerilog output is not left in the working directory root');
    unlink $expected or die "cannot remove focused-test generated HDL '$expected': $!";
};

subtest 'implicit generated VHDL lands under repository artifacts directory' => sub {
    my $workdir = tempdir(CLEANUP => 1);
    my $expected = File::Spec->catfile($repo_root, '.artifacts', 'vhd', "${unique}_vhdl.vhd");
    my $unexpected_root = File::Spec->catfile($workdir, "${unique}_vhdl.vhd");

    in_directory($workdir, sub {
        my ($success, undef, undef, undef, $stderr_buf) = run(
            command => [$fsmgen, '--quiet', '--language', 'vhdl', $local_vhdl_fsm],
        );

        ok($success, 'default VHDL generation succeeds');
        is(join('', @{$stderr_buf || []}), '', 'default VHDL generation keeps stderr clean');
    });

    ok(-f $expected, 'default VHDL output is under repository .artifacts/vhd');
    ok(!-e $unexpected_root, 'default VHDL output is not left in the working directory root');
    unlink $expected or die "cannot remove focused-test generated HDL '$expected': $!";
};

subtest 'explicit output path bypasses default artifact directory' => sub {
    my $workdir = tempdir(CLEANUP => 1);
    my $explicit_dir = File::Spec->catdir($workdir, 'chosen');
    my $explicit = File::Spec->catfile($explicit_dir, 'explicit.sv');
    make_path($explicit_dir);

    in_directory($workdir, sub {
        my ($success, undef, undef, undef, $stderr_buf) = run(
            command => [$fsmgen, '--quiet', '--output', $explicit, $trial_fsm],
        );

        ok($success, 'explicit SystemVerilog generation succeeds');
        is(join('', @{$stderr_buf || []}), '', 'explicit SystemVerilog generation keeps stderr clean');
    });

    ok(-f $explicit, 'explicit output path is honored');
    ok(!-e File::Spec->catdir($workdir, '.artifacts'), 'explicit output does not create the default artifact directory');
};

subtest 'explicit output outside the repository fails before writing' => sub {
    my $outside = File::Spec->catfile($repo_root, File::Spec->updir(), "fsmgen-locality-outside-$$.sv");
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => [$fsmgen, '--quiet', '--output', $outside, $trial_fsm],
    );

    ok(!$success, 'off-repository explicit output is rejected');
    is(join('', @{$stdout_buf || []}), '', 'off-repository rejection keeps stdout clean');
    like(
        join('', @{$stderr_buf || []}),
        qr/--output path must resolve inside the FSMGen repository/,
        'off-repository rejection identifies the output containment boundary',
    );
    ok(!-e $outside, 'off-repository rejection creates no output');
};

subtest 'every project-owned CLI destination rejects repository escape' => sub {
    my $verification_isf = File::Spec->catfile(
        $repo_root,
        'isf',
        'verification_observation_metadata.isf',
    );
    my @cases = (
        {
            label => '--outdir',
            path => File::Spec->catdir($repo_root, File::Spec->updir(), "fsmgen-locality-outdir-$$"),
            command => sub {
                my ($path) = @_;
                return [$fsmgen, '--quiet', '--outdir', $path, $multi_domain_isf];
            },
        },
        {
            label => '--trace-log',
            path => File::Spec->catfile($repo_root, File::Spec->updir(), "fsmgen-locality-trace-$$.log"),
            command => sub {
                my ($path) = @_;
                return [$fsmgen, '--quiet', '--debug=1', '--trace-log', $path, $trial_fsm];
            },
        },
        {
            label => '--verification-outdir',
            path => File::Spec->catdir($repo_root, File::Spec->updir(), "fsmgen-locality-verification-$$"),
            command => sub {
                my ($path) = @_;
                return [
                    $fsmgen,
                    '--quiet',
                    '--emit-verification-output', 'uvm-passive-monitor',
                    '--verification-outdir', $path,
                    $verification_isf,
                ];
            },
        },
    );

    for my $case (@cases) {
        my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
            command => $case->{command}->($case->{path}),
        );
        ok(!$success, "$case->{label} rejects an off-repository destination");
        is(join('', @{$stdout_buf || []}), '', "$case->{label} rejection keeps stdout clean");
        like(
            join('', @{$stderr_buf || []}),
            qr/\Q$case->{label}\E path must resolve inside the FSMGen repository/,
            "$case->{label} rejection identifies the containment boundary",
        );
        ok(!-e $case->{path}, "$case->{label} rejection creates no data");
    }
};

subtest 'implicit multi-file lowering leaves no scheduled artifacts in the working directory' => sub {
    my $workdir = tempdir(CLEANUP => 1);
    my $explicit = File::Spec->catfile($workdir, 'clock_domain_event_crossing.sv');

    in_directory($workdir, sub {
        my ($success, undef, undef, undef, $stderr_buf) = run(
            command => [$fsmgen, '--quiet', '--output', $explicit, $multi_domain_isf],
        );

        ok($success, 'multi-file ISF generation succeeds without --outdir');
        is(join('', @{$stderr_buf || []}), '', 'implicit multi-file lowering keeps stderr clean');
    });

    ok(-f $explicit, 'multi-file generation writes only the requested HDL output');
    my @scheduled = glob(File::Spec->catfile($workdir, '*.fsm'));
    is_deeply(\@scheduled, [], 'implicit multi-file scheduled handoff stays out of the working directory');
};

done_testing();

sub in_directory {
    my ($dir, $callback) = @_;
    my $original = getcwd();
    chdir $dir or die "cannot chdir to $dir: $!";
    my $ok = eval {
        $callback->();
        1;
    };
    my $error = $@;
    chdir $original or die "cannot restore cwd to $original: $!";
    die $error unless $ok;
}
