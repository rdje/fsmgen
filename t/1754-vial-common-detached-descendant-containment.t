#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
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
use FSM::VIAL::ArchitectureScaleWorkload;

my $class = 'FSM::VIAL::ArchitectureScaleMeasurement';
my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $fixture_root = File::Spec->catdir(
    $repo_root, '.artifacts', 'tmp',
    "vial-common-detached-descendant-containment-$$",
);
my $identity_path = File::Spec->catfile($fixture_root, 'descendant.pid');
my $source = "(vial\n  (version 1)\n)\n";
my $construction = FSM::VIAL::ArchitectureScaleWorkload->construct({
    family => 'semantic_catalog_v1',
    level => 'reference_v1',
    primary_axis => 'imports',
    backend_profile => undef,
    tool_profile => undef,
    inputs => [{
        relative_path => 'source/detached-descendant-containment.vial',
        role => 'vial_source',
        encoding => 'utf-8',
        content => $source,
    }],
});
my $stage_rel = validation_stage_relative($construction);
my $stage_abs = repo_path($stage_rel);
my $late_marker = File::Spec->catfile($stage_abs, 'detached-marker.txt');
my ($descendant_pid, $descendant_group);

die "detached-descendant construction is invalid\n"
    unless $construction->{ok};
die "detached-descendant fixture root already exists\n"
    if -e $fixture_root || -l $fixture_root;
die "detached-descendant stage residue already exists\n"
    if -e $stage_abs || -l $stage_abs;
make_path($fixture_root, {mode => 0700});
chmod 0700, $fixture_root
    or die "cannot seal detached-descendant fixture root: $!\n";

END {
    terminate_residue();
    remove_tree($stage_abs)
        if defined($stage_abs) && -d($stage_abs) && !-l($stage_abs);
    prune_stage_parents();
    remove_tree($fixture_root)
        if defined($fixture_root) && -d($fixture_root) && !-l($fixture_root);
}

my $record = $class->measure({
    repository_root => $repo_root,
    construction => $construction,
    run_class => 'validation',
    run_ordinal => 0,
    validation_record => undef,
    stage_plan => [detached_plan()],
});
read_descendant_identity();
my $marker_published = wait_for_path($late_marker, 2);

isnt($record->{outcome}, 'accepted',
    'a detached descendant cannot promote an accepted measurement');
ok($record->{cleanup}{ephemeral_removed},
    'successful descendant containment permits exact staging cleanup');
ok(!process_alive($descendant_pid),
    'the detached descendant is gone before controller return');
ok(!$marker_published && !-e($late_marker) && !-l($late_marker),
    'a detached descendant cannot recreate staging after cleanup');

terminate_residue();
remove_tree($stage_abs) if -d $stage_abs && !-l $stage_abs;
prune_stage_parents();
remove_tree($fixture_root);
ok(!-e($fixture_root) && !-l($fixture_root)
        && !-e($stage_abs) && !-l($stage_abs),
    'detached-descendant fixture leaves no repository-local residue');

done_testing();

sub detached_plan {
    return {
        stage => 'construct',
        classification => 'fsmgen_owned',
        command_identity => {
            logical_name => 'detached_descendant_containment_probe',
            arguments => [],
            thread_count => 1,
            job_count => 1,
        },
        input_counts => {
            files => 1, lines => 3,
            bytes => bytes::length($source), objects => 1,
        },
        backend_timeout_seconds => undef,
        worker => sub {
            my $child = fork();
            die "cannot fork detached-descendant probe\n"
                unless defined $child;
            if ($child == 0) {
                my $session = POSIX::setsid();
                POSIX::_exit(71) unless defined $session && $session > 0;
                my $group = POSIX::getpgrp();
                sysopen my $fh, $identity_path,
                    O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600
                    or POSIX::_exit(72);
                print {$fh} "$$ $group\n" or POSIX::_exit(73);
                close $fh or POSIX::_exit(74);
                for (1 .. 1_000) {
                    last unless -e $stage_abs || -l $stage_abs;
                    sleep 0.005;
                }
                POSIX::_exit(75) if -e $stage_abs || -l $stage_abs;
                make_path($stage_abs, {mode => 0700});
                sysopen my $marker, $late_marker,
                    O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600
                    or POSIX::_exit(76);
                print {$marker} "detached mutation\n" or POSIX::_exit(77);
                close $marker or POSIX::_exit(78);
                sleep 30;
                POSIX::_exit(0);
            }
            for (1 .. 200) {
                last if -f $identity_path && !-l $identity_path;
                sleep 0.005;
            }
            die "detached descendant did not publish its identity\n"
                unless -f $identity_path && !-l $identity_path;
            return {
                ok => JSON::PP::true,
                status => 'detached_descendant_leader_completed',
                output_counts => {
                    files => 0, lines => 0, bytes => 0, objects => 0,
                },
                semantic_object_counts => {},
                correctness_oracles => [{
                    oracle_id => 'detached_descendant_leader_completed',
                    ok => JSON::PP::true,
                    evidence => {leader_exit => 'zero'},
                }],
                artifacts => [],
                diagnostic => undef,
            };
        },
    };
}

sub read_descendant_identity {
    open my $fh, '<:raw', $identity_path
        or die "cannot read detached-descendant identity: $!\n";
    my $record = <$fh>;
    close $fh or die "cannot close detached-descendant identity: $!\n";
    ($descendant_pid, $descendant_group) = $record
        =~ /\A([1-9][0-9]*) ([1-9][0-9]*)\n\z/
        or die "detached-descendant identity is malformed\n";
    return;
}

sub validation_stage_relative {
    my ($value) = @_;
    my ($digest) = $value->{workload_identity}
        =~ m{\Aworkload/([0-9a-f]{64})\z};
    die "detached-descendant construction has no workload digest\n"
        unless defined $digest;
    return ".artifacts/tmp/vial-scale/$digest/validation/00";
}

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub wait_for_path {
    my ($path, $seconds) = @_;
    my $attempts = int($seconds / 0.01);
    for (0 .. $attempts) {
        return 1 if -e $path || -l $path;
        sleep 0.01;
    }
    return -e $path || -l $path;
}

sub process_alive {
    my ($pid) = @_;
    return defined($pid) && kill(0, $pid) ? 1 : 0;
}

sub terminate_residue {
    return unless defined $descendant_pid;
    my $own_group = POSIX::getpgrp();
    if (defined($descendant_group) && $descendant_group != $own_group) {
        kill 'TERM', -$descendant_group;
        for (1 .. 25) {
            return unless process_alive($descendant_pid);
            sleep 0.01;
        }
        kill 'KILL', -$descendant_group;
    }
    elsif ($descendant_pid != $$) {
        kill 'KILL', $descendant_pid;
    }
    for (1 .. 200) {
        last unless process_alive($descendant_pid);
        sleep 0.01;
    }
    return;
}

sub prune_stage_parents {
    return unless defined $stage_rel;
    my @parts = split m{/}, $stage_rel;
    pop @parts;
    while (@parts >= 2) {
        my $parent = repo_path(join '/', @parts);
        rmdir $parent if -d $parent && !-l $parent;
        pop @parts;
    }
    return;
}
