#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;
use Time::HiRes qw(time);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::VHDLPortableGHDL;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

my $json = JSON::PP->new->canonical(1);
my $profile = 'vhdl_portable_ghdl';
my $vial_source_name = 'vial/ahb_subordinate_base_output_arbitration_1.vial';
my $hial_source_name = 'ppif/ahb_lite_subordinate.ppif';
my $reference_vial = slurp_raw(repo_path(
    'vial', 'ahb_subordinate_base_output_arbitration.vial'));
my $reference_hial = slurp_raw(repo_path(
    'ppif', 'ahb_lite_subordinate.ppif'));

subtest 'metadata validation and source-map anchoring retain linear source shape' => sub {
    my $validator = slurp_raw(repo_path(
        'perl', 'FSM', 'VIAL', 'Backend', 'VHDLPortableStaticValidator.pm'));
    ok(
        $validator !~ qr/for\s+my\s+\$index\s*\([^}]+?\$text\{vhdl_fixture_metadata\}\s*=~/s,
        'validator does not rescan the complete metadata text inside its operation loop',
    );
    ok(
        $validator !~ qr/_count_matches\s*\(\$text\{vhdl_fixture_metadata\}/,
        'validator does not repeat fixed whole-metadata census scans',
    );

    my $emitter = slurp_raw(repo_path(
        'perl', 'FSM', 'VIAL', 'Backend', 'VHDLPortableGHDL.pm'));
    ok(
        $emitter !~ qr/_find_line\s*\(\$metadata_text/,
        'source-map construction does not split and scan metadata once per operation',
    );
    ok(
        $emitter !~ qr/_line_(?:count|column)\s*\(\$text/,
        'source-map finalization does not rescan artifact text once per entry',
    );
};

if ($ENV{FSMGEN_VIAL_VHDL_LINEAR_SOURCE_ONLY}) {
    done_testing;
    exit;
}

my %expected = (
    21 => {source_bytes => 118_064, source_maps => 59},
    128 => {source_bytes => 176_433, source_maps => 166},
    512 => {source_bytes => 388_401, source_maps => 550},
    29_506 => {source_bytes => 16_777_107, source_maps => 29_544},
);

for my $total (512, 21, 128) {
    subtest "portable VHDL T=$total is exact and byte deterministic" => sub {
        my $built = build_plan($total);
        is(operation_count($built), $total,
            'ordinary parser and PlanBuilder produce the requested operation total');
        my ($first, $first_seconds) = emit_with_ceiling($built, $total, 60);
        ok($first->{ok}, 'first canonical emission succeeds inside the linearity ceiling');
        diag($json->encode($first->{diagnostics})) unless $first->{ok};
        assert_emission($first, $total);

        my ($second, $second_seconds) = emit_with_ceiling($built, $total, 60);
        ok($second->{ok}, 'independent canonical rerun succeeds');
        is($json->encode($second), $json->encode($first),
            'independent canonical rerun is byte-identical');
        ok($first_seconds < 60 && $second_seconds < 60,
            'both emissions finish before the bounded regression alarm');
    };
}

if ($ENV{FSMGEN_VIAL_VHDL_SCALE_EXACT}) {
    subtest 'selected accepted and adjacent portable VHDL byte boundary is exact' => sub {
        my $accepted_plan = build_plan(29_506);
        my ($accepted, $accepted_seconds) =
            emit_with_ceiling($accepted_plan, 29_506, 300);
        ok($accepted->{ok}, 'T=29,506 succeeds inside the selected emission ceiling');
        diag($json->encode($accepted->{diagnostics})) unless $accepted->{ok};
        assert_emission($accepted, 29_506);

        my ($rerun, $rerun_seconds) =
            emit_with_ceiling($accepted_plan, 29_506, 300);
        ok($rerun->{ok}, 'accepted boundary rerun succeeds');
        is($json->encode($rerun), $json->encode($accepted),
            'accepted boundary rerun is byte-identical');

        my $excess_plan = build_plan(29_507);
        my ($excess, $excess_seconds) =
            emit_with_ceiling($excess_plan, 29_507, 300);
        ok(!$excess->{ok}, 'adjacent T=29,507 rejects');
        is_deeply($excess->{diagnostics}, [{
            code => 'VIAL_VHDL_BACKEND_LIMIT_EXCEEDED',
            severity => 'error',
            message => 'generated VHDL exceeds the 16 MiB backend cap',
            path => '/artifacts',
        }], 'adjacent rejection keeps the exact earliest diagnostic');
        is_deeply($excess->{artifacts}, [], 'adjacent rejection publishes no artifacts');
        ok(!defined($excess->{plan_id}) && !defined($excess->{operation_id})
                && !defined($excess->{source_map})
                && !defined($excess->{static_validation}),
            'adjacent rejection publishes no partial backend identity or evidence graph');
        ok($accepted_seconds < 300 && $rerun_seconds < 300
                && $excess_seconds < 300,
            'accepted, rerun, and adjacent outcomes stay inside the selected ceiling');
    };
}
else {
    note('set FSMGEN_VIAL_VHDL_SCALE_EXACT=1 for the T=29,506/29,507 boundary proof');
}

done_testing;

sub build_plan {
    my ($total) = @_;
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => scale_source($total),
        source_name => $vial_source_name,
        source_catalog => {},
    });
    my $built = FSM::VIAL::PlanBuilder->build({
        semantic_ir => $semantic_ir,
        hial_source => {
            source_id => $hial_source_name,
            text => $reference_hial,
            format => 'ppif',
        },
        fixture_id => undef,
        scenario_ids => [],
        execution_profile => 'core_directed_single_clock_execution_v1',
        replay_manifest => undef,
        native_extension_catalog => [],
    });
    die 'canonical scale plan did not build: ' . $json->encode($built->{diagnostics})
        unless $built->{ok};
    return $built;
}

sub scale_source {
    my ($total) = @_;
    return $reference_vial if $total == 21;
    die "operation total $total is below the anchored recipe\n" if $total < 22;
    my $repeat_count = $total - 22;
    my $needle = '              (scoreboard_check writes)))';
    my $insertion = "              (repeat $repeat_count"
        . ' (expect scale_response_ok (same (sample response) #b0)))' . "\n";
    my $source = $reference_vial;
    my $matches = $source =~ s/\Q$needle\E/$insertion$needle/;
    die "anchored response-expectation insertion point is not unique\n"
        unless $matches == 1;
    return $source;
}

sub emit_with_ceiling {
    my ($built, $total, $seconds) = @_;
    my ($emission, $error);
    my $started = time;
    {
        local $SIG{ALRM} = sub {
            die "portable VHDL T=$total exceeded the $seconds-second test ceiling\n";
        };
        alarm $seconds;
        eval {
            $emission = FSM::VIAL::Backend::VHDLPortableGHDL->emit({
                execution_ir => $built->{execution_ir},
                bridge_manifest => $built->{bridge_manifest},
                backend_inputs => $built->{backend_inputs},
                artifact_root => ".artifacts/test/vial-vhdl-scale-t$total",
                backend_profile => $profile,
            });
            1;
        } or $error = $@;
        alarm 0;
    }
    BAIL_OUT($error) if defined($error) && length($error);
    return ($emission, time - $started);
}

sub assert_emission {
    my ($emission, $total) = @_;
    my $source_bytes = 0;
    $source_bytes += bytes::length($_->{content})
        for grep { $_->{language} eq 'vhdl' } @{$emission->{artifacts}};
    is(scalar(@{$emission->{artifacts}}), 17, 'artifact inventory remains exact');
    is(scalar(grep { $_->{language} eq 'vhdl' } @{$emission->{artifacts}}), 6,
        'source inventory remains exact');
    is($source_bytes, $expected{$total}{source_bytes},
        'generated six-source byte total is exact');
    is(scalar(@{$emission->{source_map}{entries}}),
        $expected{$total}{source_maps}, 'complete source-map count is exact');
    is(scalar(@{$emission->{static_validation}{checks}}), 21,
        'all twenty-one static checks remain present');
    is(scalar(grep { $_->{status} ne 'passed' }
            @{$emission->{static_validation}{checks}}), 0,
        'all static checks pass');
    ok(!-e repo_path('.artifacts', 'test', "vial-vhdl-scale-t$total"),
        'pure in-memory emission creates no artifact root');
}

sub operation_count {
    my ($built) = @_;
    return scalar(@{$built->{execution_ir}->as_hashref
        ->{operation_graph}{operations}});
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!\n";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $path: $!\n";
    return $text;
}

sub repo_path {
    return File::Spec->catfile($FindBin::Bin, '..', @_);
}
