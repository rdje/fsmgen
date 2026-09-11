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
        native-proxy-observation-archive-records-20260911 native-proxy-observation-archive-20260911);
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Test::More;
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
# Trace hooks must compile before the prototype's storage methods.
use ArchiveTrace;
use ArchiveFixture;

my $JSON = JSON::PP->new->canonical->ascii;
my $ROOT = FSM::Test::ProcessSupervisor::repository_root();
my $plan = $JSON->decode(NativeProxyArchiveFixture::read_bytes("$FindBin::Bin/plan.json"));
my $log_relative = '.artifacts/logs/native-proxy-observation-archive-boundaries-20260911';
my $pins = $JSON->decode(NativeProxyArchiveFixture::read_bytes("$ROOT/$log_relative/preflight-pins.json"));
for my $pin (@$pins) {
    my $raw = NativeProxyArchiveFixture::read_bytes("$ROOT/$pin->{path}");
    die "prospective archive boundary input changed\n" unless length($raw) == $pin->{size_bytes}
        && sha256_hex($raw) eq $pin->{sha256};
}
my %cases;
for my $profile (@{$plan->{profiles}}) {
    for my $route (qw(fresh existing)) {
        my $id = "$profile->{name}:$route";
        die "archive boundary case alias\n" if $cases{$id}++;
        my $flow = $plan->{flows}{$id};
        die "missing declared archive boundary flow\n" unless $flow;
        my (%events, %handles);
        die "planned archive event alias\n" if grep { $events{$_->{event}}++ } @{$flow->{events}};
        die "planned archive handle alias\n" if grep { $handles{$_->{label}}++ } @{$flow->{handles}};
    }
}
die "unknown archive boundary flow\n" unless keys(%cases) == keys(%{$plan->{flows}});
my $result = {schema => 'fsmgen.inactive_archive_boundary_qualification.v1',
    success => JSON::PP::false, cases => [], allocated => []};
NativeProxyArchiveFixture::initialize('native-proxy-observation-archive-boundaries-20260911', $result, \$forbidden);
no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden process'; };

for my $profile (@{$plan->{profiles}}) {
    NativeProxyArchiveFixture::context($profile, sub {
        my ($context) = @_;
        my $prior = NativeProxyArchiveFixture::footprint($context);
        my $retirement = NativeProxyRuntimeRetirement::retire_runtime_reference(
            $context->{store}{path}, $context->{runtime}, NativeProxyArchiveFixture::cleanup_receipts());
        my $after_retirement = NativeProxyArchiveFixture::footprint($context);
        ok(!keys(%{$after_retirement->{workspace}}) && $retirement->{runtime_authorized} == 0,
            "$profile->{name}: actual inactive retirement before traces");
        for my $route (qw(fresh existing)) {
            my $id = "$profile->{name}:$route";
            my $row = {name => $id, context => NativeProxyArchiveFixture::clone($context),
                prior_retirement => NativeProxyArchiveFixture::clone($prior), retirement => $retirement,
                after_retirement => NativeProxyArchiveFixture::clone($after_retirement)};
            my $input_before = $JSON->encode($context);
            my $before = NativeProxyArchiveFixture::footprint($context);
            my $operation = NativeProxyArchiveTrace::observe_archive($context);
            $operation->{before} = $before;
            $operation->{after} = NativeProxyArchiveFixture::footprint($context);
            $operation->{descriptors} = [map { +{path => $_->{path}, descriptor => $_->{descriptor},
                closed => $_->{closed_at_return}, cloexec => $_->{cloexec_before_close}} }
                grep { $_->{kind} eq 'source' } @{$operation->{handles}}];
            $row->{operation} = $operation;
            $row->{inputs_unchanged} = $JSON->encode($context) eq $input_before ? 1 : 0;
            push @{$result->{cases}}, $row;
            NativeProxyArchiveFixture::save_result();
            is_deeply($operation->{events}, [map { $_->{event} } @{$plan->{flows}{$id}{events}}],
                "$id: complete ordered unique boundaries");
            ok($operation->{returned} && !$operation->{error}, "$id: actual archive returns") or diag($operation->{error});
            ok($operation->{all_observed_handles_closed}
                && !grep({ !$_->{actual_close_ok} || !$_->{closed_after_call} || !$_->{closed_at_return} }
                         @{$operation->{handles}}), "$id: explicit source/writer/directory closure");
            ok($row->{inputs_unchanged}, "$id: retained input is unchanged");
            my $preserved = !grep { $JSON->encode($before->{$_}) ne $JSON->encode($operation->{after}{$_}) }
                qw(store workspace other_workspace);
            ok($preserved, "$id: other owners and retired workspace remain unchanged");
            unless (Test::More->builder->is_passing) {
                NativeProxyArchiveFixture::save_result();
                BAIL_OUT('first unexpected archive boundary retained');
            }
        }
    });
}
is($forbidden, 0, 'no compiler or native process attempt');
$result->{success} = Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false;
NativeProxyArchiveFixture::save_result();
done_testing;
