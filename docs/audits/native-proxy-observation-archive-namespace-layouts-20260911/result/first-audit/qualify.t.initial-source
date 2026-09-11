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
my $pins = $JSON->decode(NativeProxyArchiveFixture::read_bytes("$FindBin::Bin/preflight-pins.json"));
for my $pin (@$pins, @{$plan->{inputs}}) {
    my $raw = NativeProxyArchiveFixture::read_bytes("$ROOT/$pin->{path}");
    die "prospective archive namespace-layout input changed\n" unless length($raw) == $pin->{size_bytes}
        && sha256_hex($raw) eq $pin->{sha256};
}
my $log_relative = '.artifacts/logs/native-proxy-observation-archive-namespace-layouts-20260911';
die "preserve the prior qualification before another execution\n"
    if -e "$ROOT/$log_relative/qualification.json" || -l "$ROOT/$log_relative/qualification.json";
my %profiles = map { $_->{name} => $_ } @{$plan->{profiles}};
my %cases;
for my $selection (@{$plan->{cases}}) {
    die "archive namespace-layout case aliases\n" if $cases{$selection->{name}}++;
    die "unknown archive namespace-layout profile\n" unless exists($profiles{$selection->{profile}});
}
my $result = {schema => 'fsmgen.inactive_archive_namespace_layouts_qualification.v1',
    success => JSON::PP::false, cases => [], allocated => []};
NativeProxyArchiveFixture::initialize('native-proxy-observation-archive-namespace-layouts-20260911', $result, \$forbidden);
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
        my $preparation = NativeProxyArchiveTrace::observe_archive($context);
        finish_observation($context, $preparation, $retired);
        $row->{preparation} = $preparation;
        NativeProxyArchiveFixture::save_result();
        ok($preparation->{returned} && !$preparation->{error}, "$id: healthy preparation observed")
            or diag($preparation->{error});
        ok(all_closed($preparation), "$id: actual preparation handles close");
        BAIL_OUT('first unexpected archive preparation retained') unless Test::More->builder->is_passing;

        my $spec = NativeProxyObservationArchiveRecord::archive_specification(
            $context->{store}{path}, $context->{request}, $context->{acquired});
        my $kind = $selection->{kind};
        my $mutation = {kind => $kind, added => []};
        if ($kind eq 'namespace') {
            my $extra = $selection->{value} - @{$spec->{files}};
            for my $index (0..$extra - 1) {
                my $path = "$spec->{archive_directory}/unknown-$index.member";
                die "controlled namespace destination exists\n" if -e "$ROOT/$path" || -l "$ROOT/$path";
                NativeProxyArchiveFixture::write_bytes("$ROOT/$path", '', 0400);
                push @{$mutation->{added}}, $path;
            }
        } elsif ($kind eq 'valid-symlink' || $kind eq 'dangling-symlink') {
            my $index = $selection->{index};
            my $path = $spec->{files}[$index]{path};
            my $retained = "$context->{evidence}{path}/retained-original-$index.source";
            die "controlled retained destination exists\n" if -e "$ROOT/$retained" || -l "$ROOT/$retained";
            rename("$ROOT/$path", "$ROOT/$retained") or die "retain original canonical source: $!\n";
            my $target = 'missing-owned-source';
            if ($kind eq 'valid-symlink') {
                $target = $spec->{files}[($index + 1) % @{$spec->{files}}]{path};
                $target =~ s{.*/}{};
            }
            symlink($target, "$ROOT/$path") or die "install controlled source symlink: $!\n";
            @$mutation{qw(path retained target)} = ($path, $retained, $target);
        } else {
            die "unknown archive namespace selection\n" unless $kind eq 'healthy';
        }
        $row->{mutation} = $mutation;
        NativeProxyArchiveFixture::save_result();
        my $before = NativeProxyArchiveFixture::footprint($context);
        my $operation = NativeProxyArchiveTrace::observe_archive($context);
        finish_observation($context, $operation, $before);
        $row->{operation} = $operation;
        $row->{inputs_unchanged} = $JSON->encode($context) eq $input_before ? 1 : 0;
        NativeProxyArchiveFixture::save_result();
        my $expected = $kind eq 'healthy' ? '' : $kind eq 'namespace'
            ? ($selection->{value} > 64 ? "namespace capacity exceeded\n" : "archive has incomplete or unknown members\n")
            : "symlink ancestry is forbidden\n";
        ok(!keys(%{$retired->{workspace}}) && $retirement->{runtime_authorized} == 0,
            "$id: actual inactive retirement precedes controls");
        ok($operation->{error} eq $expected && ($kind eq 'healthy'
            ? ($operation->{returned} && ref($operation->{result}) eq 'HASH')
            : (!$operation->{returned} && !defined($operation->{result}))),
            "$id: exact original admission outcome") or diag($operation->{error});
        ok(all_closed($operation), "$id: every admitted handle explicitly closes");
        ok($row->{inputs_unchanged}, "$id: retained inputs unchanged");
        ok($JSON->encode($before) eq $JSON->encode($operation->{after}) && !@{$operation->{writes}},
            "$id: verifier preserves controlled archive and other owners");
        BAIL_OUT('first unexpected archive namespace result retained') unless Test::More->builder->is_passing;
    });
}
is($forbidden, 0, 'no compiler or native process attempt');
$result->{success} = Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false;
NativeProxyArchiveFixture::save_result();
done_testing;
