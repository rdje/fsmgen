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
        native-proxy-observation-archive-boundaries-20260911 native-proxy-observation-work-records-20260911);
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Test::More;
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use ReleaseTrace;
use ArchiveFixture;
use ReleaseFixture;

my $JSON = JSON::PP->new->canonical->ascii;
my $ROOT = FSM::Test::ProcessSupervisor::repository_root();
my $plan = $JSON->decode(NativeProxyArchiveFixture::read_bytes("$FindBin::Bin/plan.json"));
my $pins = $JSON->decode(NativeProxyArchiveFixture::read_bytes("$FindBin::Bin/preflight-pins.json"));
for my $pin (@$pins, grep { $_->{applicability} eq 'unchanged_current_source' } @{$plan->{inputs}}) {
    my $raw = NativeProxyArchiveFixture::read_bytes("$ROOT/$pin->{path}");
    die "release source input changed\n" unless length($raw) == $pin->{size_bytes} && sha256_hex($raw) eq $pin->{sha256};
}
my $result = {schema => 'fsmgen.inactive_observation_release_qualification.v1',
    success => JSON::PP::false, cases => [], allocated => [], prospective_pins => $pins};
NativeProxyArchiveFixture::initialize($plan->{component}, $result, \$forbidden);
no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden process'; };

for my $selection (@{$plan->{cases}}) {
    NativeProxyArchiveFixture::context($selection, sub {
        my ($context) = @_;
        my $row = {name => $selection->{name}, selection => NativeProxyArchiveFixture::clone($selection),
            context => NativeProxyArchiveFixture::clone($context), setup_before => NativeProxyArchiveFixture::footprint($context)};
        # Freeze selected work before archival or any modeled observation work.
        my ($work, $settlement) = NativeProxyReleaseFixture::work($context, $selection->{cleanup});
        $row->{work_selection} = NativeProxyArchiveFixture::clone($work);
        $row->{work_settlement} = NativeProxyArchiveFixture::clone($settlement);
        if ($selection->{runtime} eq 'retired') {
            $row->{retirement} = NativeProxyRuntimeRetirement::retire_runtime_reference(
                $context->{store}{path}, $context->{runtime}, NativeProxyArchiveFixture::cleanup_receipts());
        }
        if ($selection->{last_observation}) {
            # Explicit owned fixture construction, not evidence for the release API.
            my $source = $context->{other_observation}{observation_reference}{source};
            my $path = $source->{identity}{path};
            my @native = lstat("$ROOT/$path");
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
        pop @$arguments if ($selection->{argument_change} // '') eq 'drop';
        push @$arguments, 'extra' if ($selection->{argument_change} // '') eq 'append';
        $row->{arguments} = NativeProxyArchiveFixture::clone($arguments);
        my $before_input = $JSON->encode(NativeProxyReleaseFixture::fingerprint($arguments));
        my $operation = {before => NativeProxyArchiveFixture::footprint($context)};
        my $observed = NativeProxyReleaseTrace::observe($context, $arguments, $selection->{control});
        %$operation = (%$operation, %$observed);
        $operation->{after} = NativeProxyArchiveFixture::footprint($context);
        $row->{operation} = $operation;
        $row->{inputs_unchanged} = $JSON->encode(NativeProxyReleaseFixture::fingerprint($arguments)) eq $before_input ? 1 : 0;
        push @{$result->{cases}}, $row; NativeProxyArchiveFixture::save_result();
        is($operation->{returned}, $selection->{expected_public_return} ? 1 : 0, "$selection->{name}: public return contract");
        my $attempt = $operation->{result};
        my $success = $operation->{returned} && $attempt->{success} ? 1 : 0;
        is($success, $selection->{expected_success} ? 1 : 0, "$selection->{name}: release success contract");
        my $error = $operation->{returned} ? $attempt->{error} : $operation->{error};
        ok($selection->{expected_success} ? $error eq '' : $error =~ /$selection->{expected_error}/,
            "$selection->{name}: original diagnostic retained") or diag($error);
        my $unlinked = grep { $_->{actual_count} == 1 } @{$operation->{unlinks}};
        is($unlinked ? 1 : 0, $selection->{expected_unlinked} ? 1 : 0, "$selection->{name}: actual unlink effect");
        ok($operation->{all_observed_handles_closed}
            && !grep({ !$_->{actual_close_ok} || !$_->{closed_after_call} || !$_->{closed_at_return} } @{$operation->{handles}}),
            "$selection->{name}: actual observed source, lock and directory closure");
        ok($row->{inputs_unchanged}, "$selection->{name}: input scalar types and byte flags preserved");
        is($operation->{forbidden_mutation_attempts} + $operation->{forbidden_source_attempts}, 0,
            "$selection->{name}: no publication, unrelated mutation or private source read");
        my $expected = NativeProxyArchiveFixture::clone($operation->{before});
        if ($selection->{expected_unlinked}) {
            my $relative = $operation->{expected_hold}; $relative =~ s/^\Q$context->{store}{path}\E\///;
            delete $expected->{store}{$relative};
        }
        is_deeply($operation->{after}, $expected, "$selection->{name}: exact selected effect and preserved owners/archive");
        unless (Test::More->builder->is_passing) {
            NativeProxyArchiveFixture::save_result();
            BAIL_OUT('first unexpected exact release retained');
        }
    });
}
is($forbidden, 0, 'no original producer, compiler or native process attempt');
$result->{success} = Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false;
NativeProxyArchiveFixture::save_result();
done_testing;
