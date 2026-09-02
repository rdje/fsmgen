#!/usr/bin/env perl

use strict;
use warnings;

use Cwd ();
use File::Spec;
use FindBin;
use Getopt::Long qw(GetOptions);
use JSON::PP ();
use POSIX ();

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurementMatrix;

my $class =
    'FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurementMatrix';
my $repo_root = Cwd::abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $mode = 'direct';
my $synthetic_allocation_bytes = 0;
my ($profile_id, $help);

GetOptions(
    'mode=s' => \$mode,
    'profile=s' => \$profile_id,
    'synthetic-allocation-bytes=s' => \$synthetic_allocation_bytes,
    'help' => \$help,
) or usage(2);
usage(0) if $help;
usage(2) if @ARGV;
die "audit mode must be direct or isolated\n"
    unless $mode eq 'direct' || $mode eq 'isolated';
die "synthetic allocation must be an integer from 0 through 67108864\n"
    unless defined($synthetic_allocation_bytes)
        && !ref($synthetic_allocation_bytes)
        && $synthetic_allocation_bytes =~ /\A(?:0|[1-9][0-9]*)\z/
        && $synthetic_allocation_bytes <= 67_108_864;

my %expected_drift = map { $_ => 1 } qw(
    bridge-fanout-v1.configurations.limit-v1
    bridge-fanout-v1.types.qualification-candidate-v1
    bridge-fanout-v1.types.limit-v1
    bridge-fanout-v1.endpoints.limit-v1
    bridge-fanout-v1.backend-bindings.qualification-candidate-v1
    bridge-fanout-v1.backend-bindings.limit-v1
);
my @inventory = @{$class->inventory};
my %profile_by_id = map { $_->{profile_id} => $_ } @inventory;
die "semantic/bridge audit inventory changed\n"
    unless @inventory == 108 && keys(%profile_by_id) == 108;
die "semantic/bridge audit expected-drift inventory changed\n"
    if grep { !exists $profile_by_id{$_} } keys %expected_drift;
if (defined $profile_id) {
    die "audit profile is not selected\n"
        unless !ref($profile_id) && exists $profile_by_id{$profile_id};
    @inventory = ($profile_by_id{$profile_id});
}

my @root_stat = stat($repo_root);
die "repository filesystem identity is unavailable\n" unless @root_stat;
my $load = $class->can('_load_report_publication');
die "semantic/bridge publication audit seam is unavailable\n"
    unless defined $load;

my ($current, $drift) = (0, 0);
for my $profile (@inventory) {
    my $outcome = $mode eq 'direct'
        ? validate_profile($profile)
        : validate_profile_isolated($profile);
    $outcome eq 'current' ? $current++ : $drift++;
}

my $report = {
    schema => 'fsmgen.vial_semantic_bridge_profile_isolation_audit.v1',
    schema_version => 1,
    mode => $mode,
    selected_profile => $profile_id,
    profile_count => scalar(@inventory),
    current_match_count => $current,
    expected_drift_count => $drift,
    synthetic_allocation_bytes => 0 + $synthetic_allocation_bytes,
    outcome => 'accepted',
    explicit_nonclaims => [qw(
        capture publication current_performance_budget support capacity
    )],
};
print JSON::PP->new->canonical(1)->utf8(1)->encode($report), "\n";

sub validate_profile {
    my ($profile) = @_;
    my $synthetic = 'x' x $synthetic_allocation_bytes;
    die "synthetic audit allocation changed\n"
        unless length($synthetic) == $synthetic_allocation_bytes;
    my $ok = eval {
        $load->($repo_root, $root_stat[0], $profile);
        1;
    };
    my $error = $@;
    if ($expected_drift{$profile->{profile_id}}) {
        die "expected drift profile now validates\n" if $ok;
        die "expected drift profile returned no diagnostic\n"
            unless defined($error) && length($error);
        return 'expected_drift';
    }
    die "unexpected semantic/bridge validation failure at "
        . "'$profile->{profile_id}': $error" unless $ok;
    return 'current';
}

sub validate_profile_isolated {
    my ($profile) = @_;
    my $pid = fork();
    die "cannot fork semantic/bridge audit worker\n" unless defined $pid;
    if ($pid == 0) {
        my $ok = eval {
            validate_profile($profile);
            1;
        };
        if (!$ok) {
            my $error = $@;
            $error = 'isolated semantic/bridge audit failed without an error'
                unless defined($error) && length($error);
            $error =~ s/[^\x20-\x7e]+/ /g;
            $error =~ s/\s+/ /g;
            print STDERR substr($error, 0, 4_096), "\n";
        }
        POSIX::_exit($ok ? 0 : 70);
    }
    my $waited = waitpid($pid, 0);
    die "cannot wait for semantic/bridge audit worker\n"
        unless $waited == $pid;
    die "semantic/bridge audit worker was signalled\n" if $? & 127;
    my $exit = $? >> 8;
    die "semantic/bridge audit worker exited with status $exit\n"
        if $exit;
    return $expected_drift{$profile->{profile_id}}
        ? 'expected_drift' : 'current';
}

sub usage {
    my ($status) = @_;
    print STDERR <<'USAGE';
Usage:
  scripts/audit_vial_semantic_bridge_profile_isolation.pl [options]

Options:
  --mode MODE       Validate in one direct coordinator or one isolated child
                    per profile; default: direct.
  --profile ID      Audit one selected profile instead of all 108.
  --synthetic-allocation-bytes BYTES
                    Add a bounded 0..67108864-byte per-profile control.
  --help            Show this help.

This read-only audit authenticates the immutable revision-1 profile set through
the current semantic/bridge publication loader. It accepts only decision 0095's
six named historical drifts and publishes no measurement or artifact.
USAGE
    exit $status;
}
