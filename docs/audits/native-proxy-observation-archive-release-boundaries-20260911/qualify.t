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
        native-proxy-observation-archive-release-20260911);
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Test::More;
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use BoundaryTrace;
use ArchiveFixture;
use ReleaseFixture;

my $JSON = JSON::PP->new->canonical->ascii;
my $ROOT = FSM::Test::ProcessSupervisor::repository_root();
my $plan = $JSON->decode(NativeProxyArchiveFixture::read_bytes("$FindBin::Bin/plan.json"));
my $pins = $JSON->decode(NativeProxyArchiveFixture::read_bytes("$FindBin::Bin/preflight-pins.json"));
for my $pin (@$pins, @{$plan->{inputs}}) {
    my $raw = NativeProxyArchiveFixture::read_bytes("$ROOT/$pin->{path}");
    die "release boundary input changed\n" unless length($raw) == $pin->{size_bytes} && sha256_hex($raw) eq $pin->{sha256};
}
my $entries = NativeProxyReleaseBoundaryTrace::entries($plan);
my $result = {schema => 'fsmgen.inactive_release_boundary_qualification.v1', success => JSON::PP::false,
    prospective_pins => $pins, cases => [], allocated => [], caller_controls => []};
NativeProxyArchiveFixture::initialize($plan->{component}, $result, \$forbidden);
no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden process'; };
$result->{caller_controls} = NativeProxyReleaseBoundaryTrace::caller_controls($entries);
NativeProxyArchiveFixture::save_result();
for my $control (@{$result->{caller_controls}}) {
    is($control->{baseline_returned}, 0, "$control->{name}: original rejects external caller");
    is($control->{instrumented_returned}, 0, "$control->{name}: tail wrapper preserves rejection");
    is($control->{instrumented_error}, $control->{baseline_error}, "$control->{name}: exact caller diagnostic preserved");
    ok(@{$control->{calls}} == 1 && $control->{calls}[0]{tail}
        && $control->{calls}[0]{completion} eq 'external_rejection', "$control->{name}: rejected tail frame observed");
}
BAIL_OUT('first caller-admission failure retained before allocation') unless Test::More->builder->is_passing;

for my $profile (@{$plan->{profiles}}) {
    my $selection = $profile->{selection};
    NativeProxyArchiveFixture::context($selection, sub {
        my ($context) = @_;
        my $row = {profile_id => $profile->{id}, name => $selection->{name},
            selection => NativeProxyArchiveFixture::clone($selection), context => NativeProxyArchiveFixture::clone($context),
            setup_before => NativeProxyArchiveFixture::footprint($context)};
        my ($work, $settlement) = NativeProxyReleaseFixture::work($context, $selection->{cleanup});
        $row->{work_selection} = NativeProxyArchiveFixture::clone($work);
        $row->{work_settlement} = NativeProxyArchiveFixture::clone($settlement);
        if ($selection->{runtime} eq 'retired') {
            $row->{retirement} = NativeProxyRuntimeRetirement::retire_runtime_reference(
                $context->{store}{path}, $context->{runtime}, NativeProxyArchiveFixture::cleanup_receipts());
        }
        if ($selection->{last_observation}) {
            my $source = $context->{other_observation}{observation_reference}{source};
            my $path = $source->{identity}{path}; my @native = lstat("$ROOT/$path");
            die 'setup hold identity differs' unless @native && $native[0] == $source->{identity}{device}
                && $native[1] == $source->{identity}{inode}
                && NativeProxyArchiveFixture::read_bytes("$ROOT/$path") eq $source->{bytes};
            unlink("$ROOT/$path") == 1 or die 'cannot construct last-observation fixture';
            $row->{controlled_setup_removed_hold} = $path;
        }
        $row->{before_archive} = NativeProxyArchiveFixture::footprint($context);
        my $archive = NativeProxyObservationArchive::archive_retained_sources(
            $context->{store}{path}, $context->{request}, $context->{acquired});
        $row->{archive_receipt} = NativeProxyArchiveFixture::clone($archive);
        $row->{before_mutation} = NativeProxyArchiveFixture::footprint($context);
        my $arguments = NativeProxyArchiveFixture::clone([
            $context->{store}{path}, $context->{request}, $context->{acquired}, $archive, $work, $settlement]);
        $row->{mutation} = NativeProxyReleaseFixture::mutation($context, $selection, $arguments);
        $row->{arguments} = NativeProxyArchiveFixture::clone($arguments);
        $row->{planned_calls} = NativeProxyArchiveFixture::clone($profile->{expected_calls});
        # Save the complete constructed ownership and count domain before release.
        push @{$result->{cases}}, $row; NativeProxyArchiveFixture::save_result();
        my $before_input = $JSON->encode(NativeProxyReleaseFixture::fingerprint($arguments));
        my $operation = {before => NativeProxyArchiveFixture::footprint($context)};
        my $observed = NativeProxyReleaseBoundaryTrace::observe($context, $arguments, $entries);
        %$operation = (%$operation, %$observed);
        $operation->{after} = NativeProxyArchiveFixture::footprint($context); $row->{operation} = $operation;
        $row->{inputs_unchanged} = $JSON->encode(NativeProxyReleaseFixture::fingerprint($arguments)) eq $before_input ? 1 : 0;
        NativeProxyArchiveFixture::save_result();
        is($operation->{returned}, 1, "$profile->{id}: attempt returns");
        is($operation->{result}{success}, 1, "$profile->{id}: original release succeeds with caller admission intact")
            or diag($operation->{result}{error} // $operation->{error});
        is($operation->{result}{error}, '', "$profile->{id}: no original release error");
        is(scalar(@{$operation->{unlinks}}), 1, "$profile->{id}: one actual exact unlink");
        ok($operation->{all_observed_handles_closed}
            && !grep({ !$_->{actual_close_ok} || !$_->{closed_after_call} || !$_->{closed_at_return} } @{$operation->{handles}}),
            "$profile->{id}: every actual observed handle closes");
        ok($row->{inputs_unchanged}, "$profile->{id}: input types and byte flags remain unchanged");
        is($operation->{forbidden_mutation_attempts} + $operation->{forbidden_source_attempts}, 0,
            "$profile->{id}: no unrelated mutation or private-source read");
        my $expected = NativeProxyArchiveFixture::clone($operation->{before});
        my $relative = $operation->{expected_hold}; $relative =~ s/^\Q$context->{store}{path}\E\///;
        delete $expected->{store}{$relative};
        is_deeply($operation->{after}, $expected, "$profile->{id}: exact effect and preserved archive/other owners");
        my %calls; $calls{$_->{name}}++ for @{$operation->{boundary_calls}};
        is_deeply(\%calls, $profile->{expected_calls}, "$profile->{id}: prospective source-loop occurrence counts match");
        ok($operation->{boundary_stack_complete} && !@{$operation->{pending_boundary_ids}}, "$profile->{id}: every call and continuation completes");
        unless (Test::More->builder->is_passing) {
            NativeProxyArchiveFixture::save_result(); BAIL_OUT('first healthy boundary failure retained');
        }
    });
}
is($forbidden, 0, 'no original producer, compiler or native process attempt');
$result->{success} = Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false;
NativeProxyArchiveFixture::save_result();
done_testing;
