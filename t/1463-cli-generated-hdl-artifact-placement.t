#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $fsmgen = File::Spec->catfile($repo_root, 'bin', 'fsmgen');
my $trial_fsm = File::Spec->catfile($repo_root, 'fsm', 'trial_0.fsm');
my $vhdl_fsm = File::Spec->catfile($repo_root, 't', 'corpus', 'direct_assignment_pair_form.fsm');

subtest 'implicit generated SystemVerilog lands under hidden artifacts directory' => sub {
    my $workdir = tempdir(CLEANUP => 1);
    my $expected = File::Spec->catfile($workdir, '.artifacts', 'sv', 'trial_0.sv');
    my $unexpected_root = File::Spec->catfile($workdir, 'trial_0.sv');

    in_directory($workdir, sub {
        my ($success, undef, undef, undef, $stderr_buf) = run(
            command => [$fsmgen, '--quiet', $trial_fsm],
        );

        ok($success, 'default SystemVerilog generation succeeds');
        is(join('', @{$stderr_buf || []}), '', 'default SystemVerilog generation keeps stderr clean');
    });

    ok(-f $expected, 'default SystemVerilog output is under .artifacts/sv');
    ok(!-e $unexpected_root, 'default SystemVerilog output is not left in the working directory root');
};

subtest 'implicit generated VHDL lands under hidden artifacts directory' => sub {
    my $workdir = tempdir(CLEANUP => 1);
    my $expected = File::Spec->catfile($workdir, '.artifacts', 'vhd', 'direct_assignment_pair_form.vhd');
    my $unexpected_root = File::Spec->catfile($workdir, 'direct_assignment_pair_form.vhd');

    in_directory($workdir, sub {
        my ($success, undef, undef, undef, $stderr_buf) = run(
            command => [$fsmgen, '--quiet', '--language', 'vhdl', $vhdl_fsm],
        );

        ok($success, 'default VHDL generation succeeds');
        is(join('', @{$stderr_buf || []}), '', 'default VHDL generation keeps stderr clean');
    });

    ok(-f $expected, 'default VHDL output is under .artifacts/vhd');
    ok(!-e $unexpected_root, 'default VHDL output is not left in the working directory root');
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
