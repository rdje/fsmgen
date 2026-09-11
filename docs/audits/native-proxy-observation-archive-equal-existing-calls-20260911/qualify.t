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
        native-proxy-observation-archive-boundaries-20260911);
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
my $log_relative = '.artifacts/logs/native-proxy-observation-archive-equal-existing-calls-20260911';
my $pins = $JSON->decode(NativeProxyArchiveFixture::read_bytes("$ROOT/$log_relative/preflight-pins.json"));
for my $pin (@$pins, @{$plan->{inputs}}) {
    my $raw = NativeProxyArchiveFixture::read_bytes("$ROOT/$pin->{path}");
    die "prospective archive interruption input changed\n" unless length($raw) == $pin->{size_bytes}
        && sha256_hex($raw) eq $pin->{sha256};
}
my (%cases, %selectors);
for my $selection (@{$plan->{cases}}) {
    die "archive interruption alias\n" if $cases{$selection->{name}}++ || $selectors{$selection->{selector}}++;
    die "unsafe archive interruption selector\n"
        if $selection->{selector} =~ /\A(?:opened:|close:|close_sources:|operation:)/;
}
my $result = {schema => 'fsmgen.inactive_archive_equal_existing_calls_qualification.v1',
    success => JSON::PP::false, cases => [], allocated => []};
NativeProxyArchiveFixture::initialize('native-proxy-observation-archive-equal-existing-calls-20260911', $result, \$forbidden);
no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden process'; };
my $record_event = \&NativeProxyArchiveTrace::_event;

sub all_closed {
    my ($operation) = @_;
    return $operation->{all_observed_handles_closed}
        && !grep({ !$_->{actual_close_ok} || !$_->{closed_after_call} || !$_->{closed_at_return} }
                 @{$operation->{handles}});
}

for my $selection (@{$plan->{cases}}) {
    NativeProxyArchiveFixture::context($plan->{profile}, sub {
        my ($context) = @_;
        my $prior = NativeProxyArchiveFixture::footprint($context);
        my $retirement = NativeProxyRuntimeRetirement::retire_runtime_reference(
            $context->{store}{path}, $context->{runtime}, NativeProxyArchiveFixture::cleanup_receipts());
        my $retired = NativeProxyArchiveFixture::footprint($context);
        my $input_before = $JSON->encode($context);
        # Observe and preserve every preparation, including an unexpected
        # failed preparation, before any selected verification fault is active.
        my $preparation = NativeProxyArchiveTrace::observe_archive($context);
        $preparation->{before} = $retired;
        $preparation->{after} = NativeProxyArchiveFixture::footprint($context);
        $preparation->{descriptors} = [map { +{path => $_->{path}, descriptor => $_->{descriptor},
            closed => $_->{closed_at_return}, cloexec => $_->{cloexec_before_close}} }
            grep { $_->{kind} eq 'source' } @{$preparation->{handles}}];
        my $row = {name => $selection->{name}, selector => $selection->{selector},
            context => NativeProxyArchiveFixture::clone($context), prior_retirement => $prior,
            retirement => $retirement, preparation => $preparation};
        push @{$result->{cases}}, $row;
        NativeProxyArchiveFixture::save_result();
        my $id = $selection->{name};
        ok($preparation->{returned} && !$preparation->{error}
            && $JSON->encode($preparation->{events}) eq $JSON->encode($plan->{preparation_events}),
            "$id: complete healthy preparation is observed") or diag($preparation->{error});
        ok(all_closed($preparation), "$id: all actual preparation handles explicitly close");
        BAIL_OUT('first unexpected archive preparation retained') unless Test::More->builder->is_passing;

        my $before = NativeProxyArchiveFixture::footprint($context);
        my $hits = 0;
        my $diagnostic = "injected archive call: $selection->{selector}\n";
        local *NativeProxyArchiveTrace::_event = sub {
            $record_event->(@_);
            if ($_[0] eq $selection->{selector}) { ++$hits; die $diagnostic; }
        };
        my $operation = NativeProxyArchiveTrace::observe_archive($context);
        $operation->{before} = $before;
        $operation->{after} = NativeProxyArchiveFixture::footprint($context);
        $row->{operation} = $operation;
        $row->{injected_hits} = $hits;
        $row->{inputs_unchanged} = $JSON->encode($context) eq $input_before ? 1 : 0;
        NativeProxyArchiveFixture::save_result();
        ok(!keys(%{$retired->{workspace}}) && $retirement->{runtime_authorized} == 0,
            "$id: actual inactive retirement precedes both operations");
        ok($hits == 1 && !$operation->{returned} && !defined($operation->{result})
            && $operation->{error} eq $diagnostic, "$id: exact single fault propagates without success")
            or diag($operation->{error});
        ok(all_closed($operation), "$id: every actual verification handle explicitly closes");
        ok($row->{inputs_unchanged}, "$id: retained inputs unchanged through both operations");
        ok($JSON->encode($before) eq $JSON->encode($operation->{after}),
            "$id: complete archive and all other owners preserved");
        unless (Test::More->builder->is_passing) {
            NativeProxyArchiveFixture::save_result();
            BAIL_OUT('first unexpected existing archive interruption retained');
        }
    });
}
is($forbidden, 0, 'no compiler or native process attempt');
$result->{success} = Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false;
NativeProxyArchiveFixture::save_result();
done_testing;
