#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Fcntl qw(O_CREAT O_EXCL O_NOFOLLOW O_WRONLY);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleMeasurement;
use FSM::VIAL::ArchitectureScaleWorkload;

my $class = 'FSM::VIAL::ArchitectureScaleMeasurement';
my $cleanup_after_containment =
    $class->can('_remove_owned_stage_after_worker_containment')
    or die "worker-containment cleanup gate is unavailable\n";
my $remove_owned_stage = $class->can('_remove_owned_stage')
    or die "owned-stage cleanup is unavailable\n";
my $recover_interrupted_stage = $class->can('_recover_interrupted_stage')
    or die "interrupted-stage recovery is unavailable\n";
my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $fixture_root = File::Spec->catdir(
    $repo_root, '.artifacts', 'tmp',
    "vial-common-bounded-cleanup-admission-$$",
);
my $replacement_root = File::Spec->catdir($fixture_root, 'replacement');
my $replacement_marker =
    File::Spec->catfile($replacement_root, 'foreign-marker.txt');
my $fixture_guard = File::Spec->catfile($fixture_root, 'fixture.guard');
my $source = "(vial\n  (version 1)\n)\n";
my $construction = FSM::VIAL::ArchitectureScaleWorkload->construct({
    family => 'semantic_catalog_v1',
    level => 'reference_v1',
    primary_axis => 'imports',
    backend_profile => undef,
    tool_profile => undef,
    inputs => [{
        relative_path => 'source/bounded-cleanup-admission.vial',
        role => 'vial_source',
        encoding => 'utf-8',
        content => $source,
    }],
});
my $stage_rel = validation_stage_relative($construction);
my $stage_abs = repo_path($stage_rel);
my $displaced_abs = "$stage_abs.displaced";

die "bounded-cleanup construction is invalid\n" unless $construction->{ok};
die "bounded-cleanup fixture root already exists\n"
    if -e $fixture_root || -l $fixture_root;
die "bounded-cleanup stage residue already exists\n"
    if -e $stage_abs || -l $stage_abs
        || -e $displaced_abs || -l $displaced_abs;
make_path($replacement_root, {mode => 0700});
chmod 0700, $fixture_root, $replacement_root
    or die "cannot seal bounded-cleanup fixture root: $!\n";
touch_file($replacement_marker);
touch_file($fixture_guard);
my @repo_stat = stat($repo_root);
die "repository device is unavailable\n" unless @repo_stat;

END {
    cleanup_stage_roots();
    remove_tree($fixture_root)
        if defined($fixture_root) && -d($fixture_root) && !-l($fixture_root);
}

my $replacement_record = measure_with_plan(root_replacement_plan());
ok(!$replacement_record->{cleanup}{ephemeral_removed},
    'cleanup refuses a replacement at the owned staging pathname');
like($replacement_record->{diagnostic}{message} // '',
    qr/staging root identity changed/,
    'pathname replacement has one explicit root-identity diagnostic');
ok(-f $replacement_marker || -f File::Spec->catfile(
        $stage_abs, 'foreign-marker.txt',
    ), 'cleanup does not delete the unauthenticated replacement marker');
ok(-d $displaced_abs && !-l $displaced_abs,
    'the displaced controller-created root remains available as residue');
cleanup_stage_roots();

my $disappearance_record = measure_with_plan(root_disappearance_plan());
ok(!$disappearance_record->{cleanup}{ephemeral_removed},
    'cleanup cannot promote disappearance of the authenticated staging root');
like($disappearance_record->{diagnostic}{message} // '',
    qr/staging root identity changed/,
    'missing-root cleanup reports the same exact identity failure');
ok(-d $displaced_abs && !-l $displaced_abs,
    'missing-root rejection retains the displaced owned tree as residue');
cleanup_stage_roots();

my $growth_injected = 0;
my $growth_record;
{
    no warnings qw(redefine once);
    local *FSM::VIAL::ArchitectureScaleMeasurement::_remove_owned_stage_after_worker_containment =
        sub {
            my @args = @_;
            my $root = $args[1];
            for my $index (0 .. 1_024) {
                touch_file(File::Spec->catfile(
                    $root, sprintf('late-%04d', $index),
                ));
            }
            $growth_injected = 1;
            return $cleanup_after_containment->(@args);
        };
    $growth_record = measure_with_plan(empty_plan());
}
ok($growth_injected, 'the excess tree is installed after terminal census');
ok(!$growth_record->{cleanup}{ephemeral_removed},
    'cleanup refuses first-excess growth after terminal census');
like($growth_record->{diagnostic}{message} // '',
    qr/1024-file census ceiling/,
    'post-census growth retains the common exact file-count authority');
ok(-f File::Spec->catfile($stage_abs, 'late-1024'),
    'first-excess cleanup rejection retains the exact staging residue');
cleanup_stage_roots();

my $boundary_record;
{
    no warnings qw(redefine once);
    local *FSM::VIAL::ArchitectureScaleMeasurement::_remove_owned_stage_after_worker_containment =
        sub {
            my @args = @_;
            my $root = $args[1];
            for my $index (0 .. 1_023) {
                touch_file(File::Spec->catfile(
                    $root, sprintf('late-%04d', $index),
                ));
            }
            return $cleanup_after_containment->(@args);
        };
    $boundary_record = measure_with_plan(empty_plan());
}
ok($boundary_record->{cleanup}{ephemeral_removed},
    'the exact cleanup file-count boundary remains admissible');
ok(!-e($stage_abs) && !-l($stage_abs),
    'bounded cleanup removes its authenticated staging identity');

my $recovery_rel = join '/', '.artifacts', 'tmp',
    "vial-common-bounded-cleanup-admission-$$", 'recovery-growth';
my $recovery_abs = repo_path($recovery_rel);
make_path($recovery_abs, {mode => 0700});
for my $index (0 .. 1_023) {
    touch_file(File::Spec->catfile(
        $recovery_abs, sprintf('orphan-%04d', $index),
    ));
}
my $recovery_error;
{
    no warnings qw(redefine once);
    local *FSM::VIAL::ArchitectureScaleMeasurement::_remove_owned_stage = sub {
        my @args = @_;
        touch_file(File::Spec->catfile($args[0], 'orphan-1024'));
        return $remove_owned_stage->(@args);
    };
    $recovery_error = capture_error(sub {
        $recover_interrupted_stage->(
            $repo_root, $repo_stat[0], $recovery_rel,
        );
    });
}
like($recovery_error, qr/1024-file census ceiling/,
    'interrupted recovery re-bounds growth at destructive cleanup');
ok(-f File::Spec->catfile($recovery_abs, 'orphan-1024'),
    'recovery first-excess rejection retains the complete orphan');
remove_tree($recovery_abs);

cleanup_stage_roots();
remove_tree($fixture_root);
ok(!-e($fixture_root) && !-l($fixture_root),
    'bounded-cleanup fixture leaves no repository-local residue');

done_testing();

sub root_replacement_plan {
    my $plan = empty_plan();
    $plan->{command_identity}{logical_name} =
        'bounded_cleanup_root_replacement_probe';
    $plan->{worker} = sub {
        my ($context) = @_;
        rename $context->{staging_root}, $displaced_abs
            or die "cannot displace controller-created staging root\n";
        rename $replacement_root, $context->{staging_root}
            or die "cannot install replacement staging root\n";
        return empty_worker_result('root_replacement_completed');
    };
    return $plan;
}

sub root_disappearance_plan {
    my $plan = empty_plan();
    $plan->{command_identity}{logical_name} =
        'bounded_cleanup_root_disappearance_probe';
    $plan->{worker} = sub {
        my ($context) = @_;
        rename $context->{staging_root}, $displaced_abs
            or die "cannot displace controller-created staging root\n";
        return empty_worker_result('root_disappearance_completed');
    };
    return $plan;
}

sub empty_plan {
    return {
        stage => 'construct',
        classification => 'fsmgen_owned',
        command_identity => {
            logical_name => 'bounded_cleanup_empty_probe',
            arguments => [],
            thread_count => 1,
            job_count => 1,
        },
        input_counts => {
            files => 1, lines => 3,
            bytes => bytes::length($source), objects => 1,
        },
        backend_timeout_seconds => undef,
        worker => sub { empty_worker_result('empty_probe_completed') },
    };
}

sub empty_worker_result {
    my ($status) = @_;
    return {
        ok => JSON::PP::true,
        status => $status,
        output_counts => {
            files => 0, lines => 0, bytes => 0, objects => 0,
        },
        semantic_object_counts => {},
        correctness_oracles => [{
            oracle_id => 'bounded_cleanup_worker_completed',
            ok => JSON::PP::true,
            evidence => {worker_status => $status},
        }],
        artifacts => [],
        diagnostic => undef,
    };
}

sub measure_with_plan {
    my ($plan) = @_;
    return $class->measure({
        repository_root => $repo_root,
        construction => $construction,
        run_class => 'validation',
        run_ordinal => 0,
        validation_record => undef,
        stage_plan => [$plan],
    });
}

sub validation_stage_relative {
    my ($value) = @_;
    my ($digest) = $value->{workload_identity}
        =~ m{\Aworkload/([0-9a-f]{64})\z};
    die "bounded-cleanup construction has no workload digest\n"
        unless defined $digest;
    return ".artifacts/tmp/vial-scale/$digest/validation/00";
}

sub cleanup_stage_roots {
    for my $path ($stage_abs, $displaced_abs) {
        remove_tree($path) if -d $path && !-l $path;
    }
    my @parts = split m{/}, $stage_rel;
    pop @parts;
    while (@parts >= 2) {
        my $parent = repo_path(join '/', @parts);
        rmdir $parent if -d $parent && !-l $parent;
        pop @parts;
    }
    return;
}

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub touch_file {
    my ($path) = @_;
    sysopen my $fh, $path,
        O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600
        or die "cannot create bounded-cleanup fixture '$path': $!\n";
    close $fh
        or die "cannot close bounded-cleanup fixture '$path': $!\n";
}

sub capture_error {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? '' : "$@";
}
