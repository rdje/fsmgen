#!/usr/bin/env perl
use strict;
use warnings;
our $forbidden = 0;
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$forbidden; die 'forbidden fork'; };
    *CORE::GLOBAL::system = sub { ++$forbidden; die 'forbidden system'; };
}
use FindBin;
use lib "$FindBin::Bin/../../../perl", "$FindBin::Bin/../../../t/lib", $FindBin::Bin,
    map { "$FindBin::Bin/../$_" } qw(native-proxy-observation-archive-release-omissions-ordinary-20260913
        native-proxy-image-custody-20260910
        native-proxy-image-coordination-20260910 native-proxy-image-publication-20260910
        native-proxy-runtime-records-20260910 native-proxy-runtime-census-20260910
        native-proxy-runtime-acquisition-20260910 native-proxy-runtime-retirement-20260910
        native-proxy-cleanup-receipts-20260910 native-proxy-observation-records-20260910
        native-proxy-observation-acquisition-20260910 native-proxy-observation-reuse-20260910
        native-proxy-observation-archive-records-20260911 native-proxy-observation-archive-20260911
        native-proxy-observation-archive-boundaries-20260911 native-proxy-observation-work-records-20260911
        native-proxy-observation-archive-release-20260911 native-proxy-observation-archive-release-boundaries-20260911
        native-proxy-observation-archive-release-ordinary-before-20260911);
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL O_NOFOLLOW S_ISREG);
use JSON::PP ();
use Errno qw(EIO);
use Test::More;
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use CallFaultTrace;
use CallPlan;
use OmissionPlan;
use Omissions;
use BoundaryTrace;
use ArchiveFixture;
use ReleaseFixture;

my $ROOT = FSM::Test::ProcessSupervisor::repository_root();
my $JSON = JSON::PP->new->canonical->ascii;
my $plan = $JSON->decode(NativeProxyArchiveFixture::read_bytes("$FindBin::Bin/plan.json"));
my $pins = $JSON->decode(NativeProxyArchiveFixture::read_bytes("$FindBin::Bin/preflight-pins.json"));
for my $pin (@$pins, @{$plan->{inputs}}) {
    my $raw = NativeProxyArchiveFixture::read_bytes("$ROOT/$pin->{path}");
    die "equal-reference omission input changed\n" unless length($raw) == $pin->{size_bytes} && sha256_hex($raw) eq $pin->{sha256};
}
my $log_relative = '.artifacts/logs/'.$plan->{component};
for my $name (qw(admission.jsonl qualification.json cases)) {
    die "matrix output already exists; preserve it before any rerun\n"
        if -e "$ROOT/$log_relative/$name" || -l "$ROOT/$log_relative/$name";
}
my $entries = NativeProxyReleaseBoundaryTrace::entries($plan);
my %sealed = map { $_ => 1 } @{$plan->{sealed_symbols}};
my $result = {schema => 'fsmgen.release_equal_omission_qualification.v1', success => JSON::PP::false,
    prospective_pins => $pins, cases => [], case_files => [], allocated => [], caller_controls => [], current_case => undef};
{
    local $! = EIO;
    $result->{errno_constants} = {EIO => 0 + $!};
    $result->{errno_text} = {EIO => "$!"};
}
my $log = NativeProxyArchiveFixture::initialize($plan->{component}, $result, \$forbidden);
mkdir("$log/cases", 0700) or die "cannot exclusively create matrix case directory: $!\n";
no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden process'; };

sub signature { return sha256_hex($JSON->encode($_[0])); }

sub publish_case {
    my ($row) = @_;
    my $name = sprintf('case-%04d.json', $row->{matrix_case}{index});
    my $relative = "$log_relative/cases/$name"; my $path = "$ROOT/$relative";
    my $raw = JSON::PP->new->canonical->ascii->pretty->encode($row);
    sysopen(my $fh, $path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600)
        or die "cannot exclusively publish matrix case: $!\n";
    print {$fh} $raw or die "cannot write matrix case: $!\n";
    close $fh or die "cannot close matrix case: $!\n";
    chmod(0400, $path) == 1 or die "cannot seal matrix case: $!\n";
    my @native = lstat($path);
    die "published matrix case identity or bytes differ\n" unless @native && S_ISREG($native[2])
        && $native[0] == (stat($ROOT))[0] && $native[3] == 1 && $native[4] == $<
        && ($native[2] & 07777) == 0400 && $native[7] == length($raw)
        && NativeProxyArchiveFixture::read_bytes($path) eq $raw;
    return {index => $row->{matrix_case}{index}, name => $row->{matrix_case}{name}, path => $relative,
        size_bytes => length($raw), sha256 => sha256_hex($raw)};
}

$result->{caller_controls} = NativeProxyReleaseCallFaultTrace::caller_controls($entries, $plan->{sealed_symbols});
NativeProxyArchiveFixture::save_result();
for my $control (@{$result->{caller_controls}}) {
    is($control->{baseline_returned}, 0, "$control->{name}: original external caller rejects");
    is($control->{instrumented_returned}, 0, "$control->{name}: fault wrapper preserves caller rejection");
    is($control->{instrumented_error}, $control->{baseline_error}, "$control->{name}: original caller diagnostic remains exact");
    ok(@{$control->{calls}} == 1 && $control->{calls}[0]{tail}
        && @{$control->{interrupted_boundary_ids}} == 1, "$control->{name}: rejected original call stays an interrupted prefix");
}
BAIL_OUT('first caller guard failure retained before allocation') unless Test::More->builder->is_passing;

for my $selected (@{$plan->{cases}}) {
    $result->{cases} = [];
    $result->{current_case} = NativeProxyArchiveFixture::clone($selected);
    NativeProxyArchiveFixture::save_result();
    my $completed;
    NativeProxyArchiveFixture::context($plan->{selection}, sub {
        my ($context) = @_;
        my $row = {matrix_case => NativeProxyArchiveFixture::clone($selected),
            profile_id => $plan->{profile_id}, name => $plan->{selection}{name},
            selection => NativeProxyArchiveFixture::clone($plan->{selection}),
            context => NativeProxyArchiveFixture::clone($context), setup_before => NativeProxyArchiveFixture::footprint($context)};
        # Only one complete in-flight body is mutable. Completed case bodies
        # live in their immutable files, not this repeatedly saved report.
        $result->{cases} = [$row]; NativeProxyArchiveFixture::save_result();
        my ($work, $settlement) = NativeProxyReleaseFixture::work($context, $plan->{selection}{cleanup});
        $row->{work_selection} = NativeProxyArchiveFixture::clone($work);
        $row->{work_settlement} = NativeProxyArchiveFixture::clone($settlement);
        $row->{retirement} = NativeProxyRuntimeRetirement::retire_runtime_reference(
            $context->{store}{path}, $context->{runtime}, NativeProxyArchiveFixture::cleanup_receipts());
        $row->{before_archive} = NativeProxyArchiveFixture::footprint($context);
        my $archive = NativeProxyObservationArchive::archive_retained_sources(
            $context->{store}{path}, $context->{request}, $context->{acquired});
        $row->{archive_receipt} = NativeProxyArchiveFixture::clone($archive);
        $row->{before_mutation} = NativeProxyArchiveFixture::footprint($context);
        my $arguments = NativeProxyArchiveFixture::clone([
            $context->{store}{path}, $context->{request}, $context->{acquired}, $archive, $work, $settlement]);
        $row->{mutation} = NativeProxyReleaseFixture::mutation($context, $plan->{selection}, $arguments);
        $row->{arguments} = NativeProxyArchiveFixture::clone($arguments);
        my $operation = {before => NativeProxyArchiveFixture::footprint($context)};
        $row->{operation} = $operation;
        my ($flow, $resolved);
        my $planned = eval {
            my $spec = NativeProxyObservationArchiveRecord::archive_specification(@$arguments[0,1,2]);
            $flow = NativeProxyReleaseCallPlan::derive($context, $operation->{before}, $spec);
            $resolved = NativeProxyReleaseOmissionPlan::resolve($flow, $context, $selected->{recipe});
            1;
        };
        my $planning_error = $@; $planning_error =~ s/\Q$ROOT\E/./g;
        $row->{prospective} = {error => $planning_error, resolved => $resolved,
            flow_calls => defined($flow) ? scalar(@$flow) : undef,
            flow_sha256 => defined($flow) ? signature($flow) : undef};
        my $before_input = signature(NativeProxyReleaseFixture::fingerprint($arguments));
        $row->{input_fingerprint_before} = $before_input;
        NativeProxyArchiveFixture::save_result();
        unless ($planned) { fail('current-input resolution failed'); BAIL_OUT('first prospective resolution failure retained'); }
        my $observation = NativeProxyReleaseOmissions::observe(
            $context, $arguments, $entries, $plan->{sealed_symbols}, $flow, $resolved);
        my $observed = delete $observation->{operation};
        $row->{omission} = $observation;
        unless (defined($observed)) {
            NativeProxyArchiveFixture::save_result();
            BAIL_OUT('first original omission observer failure retained');
        }
        %$operation = (%$operation, %$observed);
        $operation->{after} = NativeProxyArchiveFixture::footprint($context);
        $row->{input_fingerprint_after} = signature(NativeProxyReleaseFixture::fingerprint($arguments));
        $row->{inputs_unchanged} = $row->{input_fingerprint_after} eq $before_input ? 1 : 0;
        NativeProxyArchiveFixture::save_result();
        my $fault = @$resolved ? 1 : 0;
        my @checks = grep { $_->{name} eq 'NativeProxyObservationRelease::_assert_absent' }
            @{$operation->{boundary_calls}};
        my $latest = @checks ? {phase => $checks[-1]{phase},
            state => exists($checks[-1]{completion}) ? 'absent' : 'unknown'} : undef;
        my $unlinked = scalar(grep { $_->{actual_count} == 1 } @{$operation->{unlinks}}) ? 1 : 0;
        my $effects = {unlink_attempted => $unlinked, unlink_completed => $unlinked,
            reference_absence_verified => scalar(grep { exists($_->{completion}) } @checks) ? 1 : 0,
            last_reference_check => $latest};
        my $attempt = $operation->{result} // {};
        my $id = $selected->{name};
        is($operation->{returned}, 1, "$id: original public attempt returns");
        is_deeply([$attempt->{success}, $attempt->{error}], [1, ''], "$id: reported success remains original");
        is_deeply($observation->{omission_hits}, [map { $_->{address} } @$resolved], "$id: exact selected omission");
        is($operation->{injected_hits} + $operation->{modeled_close_hits}, 0, "$id: no helper or reported-error injection");
        is_deeply({map { $_ => $attempt->{$_} } keys %$effects}, $effects, "$id: actual unlink and absence remain truthful");
        is($operation->{all_observed_handles_closed}, $fault ? 0 : 1, "$id: original open-handle verdict is preserved");
        my %target = map { $_->{label} => $_ } @$resolved;
        ok(!grep({ $target{$_->{label}}
            ? ($_->{actual_close_performed} || $_->{actual_close_ok} || $_->{closed_after_call} || $_->{closed_at_return}
                || $_->{reported_return} != 1 || $_->{reported_errno})
            : (!$_->{actual_close_ok} || !$_->{closed_after_call} || !$_->{closed_at_return} || $_->{actual_errno})
            } @{$operation->{handles}}), "$id: omitted and actual closes remain distinct");
        my %handles = map { $_->{label} => $_ } @{$operation->{handles}};
        ok(@{$observation->{open_witnesses}} == $fault && !grep({
            my $h = $handles{$_->{label}};
            !$_->{open_after_original_return} || !$target{$_->{label}}
                || $_->{descriptor} != $h->{descriptor} || $_->{device} != $h->{device} || $_->{inode} != $h->{inode}
                || $_->{object_address} != $h->{omitted_object_address}
            } @{$observation->{open_witnesses}}), "$id: same native object remains open after the original verdict");
        ok($observation->{recovery_complete} && @{$observation->{observer_recovery}} == $fault
            && !grep({ !$_->{performed} || !$_->{actual_return} || $_->{actual_errno} || !$_->{closed_after}
                || $_->{object_address} != $handles{$_->{label}}{omitted_object_address}
                || $_->{primitive} ne ($handles{$_->{label}}{kind} eq 'directory' ? 'CORE::closedir' : 'CORE::close')
            } @{$observation->{observer_recovery}}), "$id: exact separate recovery closes each omitted object once");
        ok($observation->{observation_returned} && !@{$observation->{observer_errors}}
            && $observation->{original_sha256_before_recovery} eq $observation->{original_sha256_after_recovery},
            "$id: recovery preserves the complete original snapshot and failure truth");
        ok($row->{inputs_unchanged}, "$id: original input bytes and types remain unchanged");
        is($operation->{forbidden_mutation_attempts} + $operation->{forbidden_source_attempts}, 0,
            "$id: no unrelated publication mutation or private-source read");
        my $expected = NativeProxyArchiveFixture::clone($operation->{before});
        if ($effects->{unlink_completed}) {
            my $relative = $operation->{expected_hold}; $relative =~ s/^\Q$context->{store}{path}\E\///;
            delete $expected->{store}{$relative};
        }
        is_deeply($operation->{after}, $expected, "$id: exact physical effect preserves archive and every other owner");
        ok($attempt->{runtime_authorized} == 0 && !defined($attempt->{executable}) && defined($attempt->{release}),
            "$id: inactive receipt authority stays closed");
        unless (Test::More->builder->is_passing) {
            NativeProxyArchiveFixture::save_result(); BAIL_OUT('first unexpected equal-reference omission failure retained');
        }
        $completed = $row;
    });
    # File::Temp ownership is discharged by context before immutable publication.
    for my $kind (qw(store workspace other_workspace evidence)) {
        my $path = "$ROOT/$completed->{context}{$kind}{path}";
        die "completed matrix case retains a root\n" if -e $path || -l $path;
    }
    $completed->{roots_absent} = JSON::PP::true;
    push @{$result->{case_files}}, publish_case($completed);
    $result->{cases} = []; $result->{current_case} = undef;
    NativeProxyArchiveFixture::save_result();
}
is($forbidden, 0, 'no original producer, compiler or native process attempt');
$result->{success} = Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false;
NativeProxyArchiveFixture::save_result(); done_testing;
