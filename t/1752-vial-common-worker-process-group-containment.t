#!/usr/bin/env perl

use strict;
use warnings;

use Fcntl qw(O_CREAT O_EXCL O_NOFOLLOW O_WRONLY);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use JSON::PP ();
use POSIX ();
use Test::More;
use Time::HiRes qw(sleep);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleMeasurement;

my $class = 'FSM::VIAL::ArchitectureScaleMeasurement';
my $run_stage = $class->can('_run_stage')
    or die "common stage runner is unavailable\n";
my $cleanup_after_containment =
    $class->can('_remove_owned_stage_after_worker_containment')
    or die "worker-containment cleanup gate is unavailable\n";
my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $fixture_root = File::Spec->catdir(
    $repo_root, '.artifacts', 'tmp',
    "vial-common-worker-process-group-containment-$$",
);
my $stage_root = File::Spec->catdir($fixture_root, 'stage');
my $pid_path = File::Spec->catfile($fixture_root, 'descendant.pid');
my ($descendant_pid, $descendant_group);

die "worker-group fixture root already exists\n"
    if -e $fixture_root || -l $fixture_root;
make_path($stage_root, {mode => 0700});
chmod 0700, $fixture_root, $stage_root
    or die "cannot seal worker-group fixture root: $!\n";
my @root_stat = stat($repo_root);
die "repository device is unavailable\n" unless @root_stat;

END {
    terminate_residue();
    remove_tree($fixture_root)
        if defined($fixture_root) && -d($fixture_root) && !-l($fixture_root);
}

my $result = stage_request(
    'worker_group_residue_probe', residual_worker(),
);
read_descendant_identity();

ok(!$result->{ok},
    'a successful leader cannot promote a stage with a live descendant');
like($result->{diagnostic}{message} // '', qr/worker retained a descendant/,
    'normal-exit descendant residue has an explicit containment diagnostic');
ok(wait_for_group_exit($descendant_group, 0.25),
    'the residual worker process group is gone before stage return');
ok($result->{cleanup_safe},
    'successful residual-group containment permits later staging cleanup');

unlink $pid_path or die "cannot reset descendant identity fixture: $!\n";
($descendant_pid, $descendant_group) = (undef, undef);
my $containment_failure;
{
    no warnings qw(redefine once);
    local *FSM::VIAL::ArchitectureScaleMeasurement::_terminate_worker_descendants =
        sub { 0 };
    local *FSM::VIAL::ArchitectureScaleMeasurement::_terminate_residual_process_group =
        sub { die "forced residual containment failure\n" };
    $containment_failure = stage_request(
        'worker_group_containment_failure_probe', residual_worker(),
    );
}
read_descendant_identity();
ok(!$containment_failure->{cleanup_safe},
    'unproven residual-group termination seals recursive cleanup closed');
like($containment_failure->{diagnostic}{message} // '',
    qr/forced residual containment failure/,
    'containment failure remains explicit in the residue diagnostic');
my $remove_called = 0;
my $cleanup_error;
{
    no warnings qw(redefine once);
    local *FSM::VIAL::ArchitectureScaleMeasurement::_remove_owned_stage = sub {
        $remove_called = 1;
        return undef;
    };
    $cleanup_error = $cleanup_after_containment->(
        0, $stage_root, 'owned/stage', [],
    );
}
like($cleanup_error, qr/retained a live worker process group/,
    'unsafe cleanup retains the exact owned staging identity');
ok(!$remove_called,
    'containment failure cannot reach recursive owned-stage deletion');
terminate_residue();
unlink $pid_path or die "cannot clear descendant identity fixture: $!\n";
($descendant_pid, $descendant_group) = (undef, undef);

my $setup_failure;
{
    no warnings qw(redefine once);
    local *FSM::VIAL::ArchitectureScaleMeasurement::_worker_process_group_ready =
        sub { 0 };
    $setup_failure = stage_request('worker_group_setup_failure_probe', sub {
        die "worker ran without process-group containment\n";
    });
}
ok(!$setup_failure->{ok},
    'a worker cannot run without its exact process-group identity');
like($setup_failure->{diagnostic}{message} // '',
    qr/measurement worker process-group containment failed/,
    'process-group setup failure has one fail-closed worker diagnostic');

terminate_residue();
remove_tree($fixture_root);
ok(!-e($fixture_root) && !-l($fixture_root),
    'worker-group fixture leaves no repository-local residue');

done_testing();

sub residual_worker {
    return sub {
        my $child = fork();
        die "cannot fork worker-group residue probe\n" unless defined $child;
        if ($child == 0) {
            $SIG{TERM} = 'IGNORE';
            my $group = POSIX::getpgrp();
            sysopen my $fh, $pid_path,
                O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600
                or POSIX::_exit(71);
            print {$fh} "$$ $group\n" or POSIX::_exit(72);
            close $fh or POSIX::_exit(73);
            sleep 30;
            POSIX::_exit(0);
        }
        for (1 .. 200) {
            last if -f $pid_path && !-l $pid_path;
            sleep 0.005;
        }
        die "worker-group descendant did not publish its identity\n"
            unless -f $pid_path && !-l $pid_path;
        return {
            ok => JSON::PP::true,
            status => 'worker_group_leader_completed',
            output_counts => {
                files => 0, lines => 0, bytes => 0, objects => 0,
            },
            semantic_object_counts => {},
            correctness_oracles => [{
                oracle_id => 'worker_group_leader_completed',
                ok => JSON::PP::true,
                evidence => {leader_exit => 'zero'},
            }],
            artifacts => [],
            diagnostic => undef,
        };
    };
}

sub read_descendant_identity {
    open my $pid_fh, '<:raw', $pid_path
        or die "cannot read worker-group descendant identity: $!\n";
    my $pid_record = <$pid_fh>;
    close $pid_fh
        or die "cannot close worker-group descendant identity: $!\n";
    ($descendant_pid, $descendant_group) = $pid_record
        =~ /\A([1-9][0-9]*) ([1-9][0-9]*)\n\z/
        or die "worker-group descendant identity is malformed\n";
    return;
}

sub stage_request {
    my ($logical_name, $worker) = @_;
    return $run_stage->({
        plan => {
            stage => 'construct',
            classification => 'fsmgen_owned',
            command_identity => {
                logical_name => $logical_name,
                arguments => [],
                thread_count => 1,
                job_count => 1,
            },
            input_counts => {
                files => 0, lines => 0, bytes => 0, objects => 0,
            },
            backend_timeout_seconds => undef,
            worker => $worker,
        },
        run_class => 'validation',
        run_ordinal => 0,
        stage_abs => $stage_root,
        stage_rel => '.artifacts/tmp/worker-group-residue/stage',
        root_device => $root_stat[0],
        workload_identity => 'worker-group-residue-probe-v1',
    });
}

sub wait_for_group_exit {
    my ($group, $seconds) = @_;
    my $attempts = int($seconds / 0.01);
    for (0 .. $attempts) {
        return 1 unless kill(0, -$group);
        sleep 0.01;
    }
    return !kill(0, -$group);
}

sub terminate_residue {
    return unless defined $descendant_pid;
    my $own_group = POSIX::getpgrp();
    if (defined($descendant_group) && $descendant_group != $own_group) {
        kill 'TERM', -$descendant_group;
        return if wait_for_group_exit($descendant_group, 0.25);
        kill 'KILL', -$descendant_group;
        wait_for_group_exit($descendant_group, 2);
    }
    else {
        kill 'KILL', $descendant_pid;
    }
    return;
}
