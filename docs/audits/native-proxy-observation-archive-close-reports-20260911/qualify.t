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
use CloseReports;
use ArchiveFixture;

my $JSON = JSON::PP->new->canonical->ascii;
my $ROOT = FSM::Test::ProcessSupervisor::repository_root();
my $plan = $JSON->decode(NativeProxyArchiveFixture::read_bytes("$FindBin::Bin/plan.json"));
my $pins = $JSON->decode(NativeProxyArchiveFixture::read_bytes("$FindBin::Bin/preflight-pins.json"));
for my $pin (@$pins, @{$plan->{inputs}}) {
    my $raw = NativeProxyArchiveFixture::read_bytes("$ROOT/$pin->{path}");
    die "prospective archive close-report input changed\n" unless length($raw) == $pin->{size_bytes}
        && sha256_hex($raw) eq $pin->{sha256};
}
my $log_relative = '.artifacts/logs/native-proxy-observation-archive-close-reports-20260911';
die "preserve the prior qualification before another execution\n"
    if -e "$ROOT/$log_relative/qualification.json" || -l "$ROOT/$log_relative/qualification.json";
my %profiles = map { $_->{name} => $_ } @{$plan->{profiles}};
my %cases;
for my $selection (@{$plan->{cases}}) {
    die "archive close-report case aliases\n" if $cases{$selection->{name}}++;
    die "unknown archive close-report profile\n" unless exists($profiles{$selection->{profile}});
}
my $result = {schema => 'fsmgen.inactive_archive_close_reports_qualification.v1',
    success => JSON::PP::false, cases => [], allocated => []};
NativeProxyArchiveFixture::initialize('native-proxy-observation-archive-close-reports-20260911', $result, \$forbidden);
no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden process'; };

sub finish_observation {
    my ($context, $operation, $before) = @_;
    $operation->{before} = $before;
    $operation->{after} = NativeProxyArchiveFixture::footprint($context);
    $operation->{descriptors} = [map { +{path => $_->{path}, descriptor => $_->{descriptor},
        closed => $_->{closed_at_return}, cloexec => $_->{cloexec_before_close}} }
        grep { $_->{kind} eq 'source' } @{$operation->{handles}}];
}

sub all_closed {
    my ($operation) = @_;
    return $operation->{all_observed_handles_closed}
        && !grep({ !$_->{actual_close_ok} || $_->{actual_errno}
            || !$_->{closed_after_call} || !$_->{closed_at_return} }
            @{$operation->{handles}});
}

for my $selection (@{$plan->{cases}}) {
    NativeProxyArchiveFixture::context($profiles{$selection->{profile}}, sub {
        my ($context) = @_;
        my $prior = NativeProxyArchiveFixture::footprint($context);
        my $retirement = NativeProxyRuntimeRetirement::retire_runtime_reference(
            $context->{store}{path}, $context->{runtime}, NativeProxyArchiveFixture::cleanup_receipts());
        my $retired = NativeProxyArchiveFixture::footprint($context);
        my $input_before = $JSON->encode($context);
        my $row = {name => $selection->{name}, selection => NativeProxyArchiveFixture::clone($selection),
            context => NativeProxyArchiveFixture::clone($context), prior_retirement => $prior,
            retirement => $retirement, retired => $retired};
        push @{$result->{cases}}, $row;
        NativeProxyArchiveFixture::save_result();
        my $id = $selection->{name};
        if ($selection->{route} eq 'existing') {
            my $preparation = NativeProxyArchiveTrace::observe_archive($context);
            finish_observation($context, $preparation, $retired);
            $row->{preparation} = $preparation;
            NativeProxyArchiveFixture::save_result();
            ok($preparation->{returned} && !$preparation->{error}, "$id: healthy preparation is observed")
                or diag($preparation->{error});
            ok(all_closed($preparation), "$id: all actual preparation handles explicitly close");
            BAIL_OUT('first unexpected archive close preparation retained') unless Test::More->builder->is_passing;
        }
        my $before = NativeProxyArchiveFixture::footprint($context);
        my $operation = NativeProxyArchiveCloseReports::observe($context, $selection);
        finish_observation($context, $operation, $before);
        $row->{operation} = $operation;
        $row->{inputs_unchanged} = $JSON->encode($context) eq $input_before ? 1 : 0;
        NativeProxyArchiveFixture::save_result();
        my @selected = sort map { $_->{label} } @{$selection->{reports}};
        my @hit = sort @{$operation->{reported_error_hits}};
        my $reports_match = $JSON->encode(\@selected) eq $JSON->encode(\@hit);
        my $primary = defined($selection->{primary});
        my $output_matches = $selection->{kind} eq 'healthy'
            ? ($operation->{returned} && ref($operation->{result}) eq 'HASH' && !length($operation->{error}))
            : (!$operation->{returned} && !defined($operation->{result}) && length($operation->{error}));
        $output_matches &&= $operation->{error} eq "primary archive close-control: $selection->{name}\n" if $primary;
        ok(!keys(%{$retired->{workspace}}) && $retirement->{runtime_authorized} == 0,
            "$id: actual inactive retirement precedes close controls");
        ok($reports_match && $operation->{primary_hits} == ($primary ? 1 : 0) && $output_matches,
            "$id: selected reports and primary outcome are observed") or diag($operation->{error});
        ok(all_closed($operation), "$id: every actual owned handle explicitly closes");
        ok($row->{inputs_unchanged}, "$id: retained inputs unchanged");
        my $preserved = !grep { $JSON->encode($before->{$_}) ne $JSON->encode($operation->{after}{$_}) }
            qw(store workspace other_workspace);
        $preserved &&= $JSON->encode($before) eq $JSON->encode($operation->{after})
            if $selection->{route} eq 'existing';
        ok($preserved, "$id: expected complete archive and other owners preserved");
        unless (Test::More->builder->is_passing) {
            NativeProxyArchiveFixture::save_result();
            BAIL_OUT('first unexpected archive close-report result retained');
        }
    });
}
is($forbidden, 0, 'no compiler or native process attempt');
$result->{success} = Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false;
NativeProxyArchiveFixture::save_result();
done_testing;
