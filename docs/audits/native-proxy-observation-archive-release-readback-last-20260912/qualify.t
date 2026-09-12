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
    map { "$FindBin::Bin/../$_" } qw(native-proxy-image-custody-20260910
        native-proxy-image-coordination-20260910 native-proxy-image-publication-20260910
        native-proxy-runtime-records-20260910 native-proxy-runtime-census-20260910
        native-proxy-runtime-acquisition-20260910 native-proxy-runtime-retirement-20260910
        native-proxy-cleanup-receipts-20260910 native-proxy-observation-records-20260910
        native-proxy-observation-acquisition-20260910 native-proxy-observation-reuse-20260910
        native-proxy-observation-archive-records-20260911 native-proxy-observation-archive-20260911
        native-proxy-observation-archive-boundaries-20260911 native-proxy-observation-work-records-20260911
        native-proxy-observation-archive-release-20260911 native-proxy-observation-archive-release-boundaries-20260911
        native-proxy-observation-archive-release-ordinary-before-20260911
        native-proxy-observation-archive-release-readback-ordinary-20260911);
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL O_NOFOLLOW S_ISREG);
use JSON::PP ();
use Test::More;
# Load the original I/O prerequisites before ReleaseTrace's compile-time
# mutation hooks, while keeping RustProxyFixture below the readback hooks.
use FSM::Test::ProcessSupervisor ();
use ReadbackCore;
use CallFaultTrace;
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use CallPlan;
use BoundaryTrace;
use ArchiveFixture;
use ReleaseFixture;
use ReadbackPlan;
use ReadbackTrace;

NativeProxyReleaseReadbackCore::install();

die "unsupported readback qualifier arguments\n"
    unless @ARGV == 0 || (@ARGV == 1 && $ARGV[0] eq '--admit-only');

my $ROOT = FSM::Test::ProcessSupervisor::repository_root();
my $JSON = JSON::PP->new->canonical->ascii;
my $plan = $JSON->decode(NativeProxyArchiveFixture::read_bytes("$FindBin::Bin/plan.json"));
my $pins = $JSON->decode(NativeProxyArchiveFixture::read_bytes("$FindBin::Bin/preflight-pins.json"));
for my $pin (@$pins, @{$plan->{inputs}}) {
    my $raw = NativeProxyArchiveFixture::read_bytes("$ROOT/$pin->{path}");
    die "last-observation readback input changed\n" unless length($raw) == $pin->{size_bytes} && sha256_hex($raw) eq $pin->{sha256};
}
if (@ARGV) {
    print $JSON->encode({admitted => 1, hooks_installed => $NativeProxyReleaseReadbackCore::INSTALLED,
        allocated_fixtures => 0, prospective_pins => scalar(@$pins), unchanged_inputs => scalar(@{$plan->{inputs}})}), "\n";
    exit 0;
}
my $log_relative = '.artifacts/logs/'.$plan->{component};
for my $name (qw(admission.jsonl qualification.json cases)) {
    die "matrix output already exists; preserve it before any rerun\n"
        if -e "$ROOT/$log_relative/$name" || -l "$ROOT/$log_relative/$name";
}
my $entries = NativeProxyReleaseBoundaryTrace::entries($plan);
my %sealed = map { $_ => 1 } @{$plan->{sealed_symbols}};
my $result = {schema => 'fsmgen.release_readback_last_qualification.v1', success => JSON::PP::false,
    prospective_pins => $pins, cases => [], case_files => [], allocated => [], caller_controls => [], current_case => undef};
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
        die "last-observation matrix requires a retired target and final hold\n"
            unless $plan->{selection}{runtime} eq 'retired' && $plan->{selection}{last_observation};
        $row->{retirement} = NativeProxyRuntimeRetirement::retire_runtime_reference(
            $context->{store}{path}, $context->{runtime}, NativeProxyArchiveFixture::cleanup_receipts());
        # This is the original controlled setup removal, outside the observed release.
        my $source = $context->{other_observation}{observation_reference}{source};
        my $path = $source->{identity}{path}; my @native = lstat("$ROOT/$path");
        die 'setup hold identity differs' unless @native && $native[0] == $source->{identity}{device}
            && $native[1] == $source->{identity}{inode}
            && NativeProxyArchiveFixture::read_bytes("$ROOT/$path") eq $source->{bytes};
        unlink("$ROOT/$path") == 1 or die 'cannot construct last-observation fixture';
        $row->{controlled_setup_removed_hold} = $path;
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
        my ($flow, $resolved, $expected_error);
        my $planned = eval {
            my $spec = NativeProxyObservationArchiveRecord::archive_specification(@$arguments[0,1,2]);
            $flow = NativeProxyReleaseCallPlan::derive($context, $operation->{before}, $spec);
            $resolved = NativeProxyReleaseReadbackPlan::resolve($flow, $selected->{selector})
                if defined($selected->{selector});
            $expected_error = NativeProxyReleaseReadbackPlan::error($flow, $resolved);
            die "current consumer differs from corrected domain\n"
                unless ($expected_error eq '' ? 1 : 0) == $selected->{expected_success};
            1;
        };
        my $planning_error = $@; $planning_error =~ s/\Q$ROOT\E/./g;
        $row->{prospective} = {error => $planning_error, resolved => $resolved,
            expected_error => $expected_error,
            flow_calls => defined($flow) ? scalar(@$flow) : undef,
            flow_sha256 => defined($flow) ? signature($flow) : undef};
        my $before_input = signature(NativeProxyReleaseFixture::fingerprint($arguments));
        $row->{input_fingerprint_before} = $before_input;
        NativeProxyArchiveFixture::save_result();
        unless ($planned) { fail('current-input resolution failed'); BAIL_OUT('first prospective resolution failure retained'); }
        my $observed;
        my $observed_ok = eval {
            $observed = NativeProxyReleaseReadbackTrace::observe(
                $context, $arguments, $entries, $plan->{sealed_symbols}, $flow, $resolved);
            1;
        };
        unless ($observed_ok) {
            my $error = $@; $error =~ s/\Q$ROOT\E/./g;
            $row->{observer_failure} = $error; NativeProxyArchiveFixture::save_result();
            BAIL_OUT('first unexpected readback observer failure retained');
        }
        %$operation = (%$operation, %$observed);
        $operation->{after} = NativeProxyArchiveFixture::footprint($context);
        $row->{input_fingerprint_after} = signature(NativeProxyReleaseFixture::fingerprint($arguments));
        $row->{inputs_unchanged} = $row->{input_fingerprint_after} eq $before_input ? 1 : 0;
        NativeProxyArchiveFixture::save_result();
        my $readback = defined($selected->{selector}) ? 1 : 0;
        my $success = $selected->{expected_success};
        my $effects = $selected->{expected_effects};
        my $attempt = $operation->{result} // {};
        my $id = $selected->{name};
        is($operation->{returned}, 1, "$id: original public attempt returns");
        is($attempt->{success}, $success, "$id: exact success disposition");
        is($attempt->{error}, $expected_error, "$id: exact primary diagnostic")
            or diag($operation->{error} // '');
        is_deeply([$operation->{injected_hits}, $operation->{readback_hits}], [0, $readback], "$id: only the selected readback control is hit");
        is_deeply({map { $_ => $attempt->{$_} } keys %$effects}, $effects, "$id: actual unlink and historical/latest absence remain truthful");
        ok($operation->{all_observed_handles_closed}
            && !grep({ !$_->{actual_close_ok} || !$_->{closed_after_call} || !$_->{closed_at_return} } @{$operation->{handles}}),
            "$id: every actual observed descriptor closes without recovery");
        ok($row->{inputs_unchanged}, "$id: original input bytes and types remain unchanged");
        is($operation->{forbidden_mutation_attempts} + $operation->{forbidden_source_attempts}, 0,
            "$id: no unrelated publication mutation or private-source read");
        my $expected = NativeProxyArchiveFixture::clone($operation->{before});
        if ($effects->{unlink_completed}) {
            my $relative = $operation->{expected_hold}; $relative =~ s/^\Q$context->{store}{path}\E\///;
            delete $expected->{store}{$relative};
        }
        is_deeply($operation->{after}, $expected, "$id: exact physical effect preserves archive and every other owner");
        ok($attempt->{runtime_authorized} == 0 && !defined($attempt->{executable})
            && ($success ? defined($attempt->{release}) : !defined($attempt->{release})), "$id: inactive receipt authority stays closed");
        my $reader = $operation->{readback};
        my $strong = $readback && $resolved->{strong_alias};
        my $lower_failure = $readback && $resolved->{control} =~ /\A(?:first-eio|partial-eio|early-eof)\z/;
        ok(!$readback ? !defined($reader) : $reader->{observation_completed}
            && $reader->{observation_error} eq '' && $reader->{post_observation_error} eq ''
            && $reader->{reader_returned} == ($lower_failure ? 0 : 1)
            && $reader->{weak_open_at_return} == ($lower_failure && !$strong ? 0 : 1)
            && $reader->{weak_open_at_release_return} == ($strong ? 1 : 0)
            && @{$reader->{recovery}} == ($strong ? 1 : 0),
            "$id: weak reader lifetime and explicit strong-counterexample recovery stay distinct");
        unless (Test::More->builder->is_passing) {
            NativeProxyArchiveFixture::save_result(); BAIL_OUT('first unexpected last-observation readback failure retained');
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
