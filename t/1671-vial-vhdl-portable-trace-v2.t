#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::VHDLPortableTraceValidator;

my $json = JSON::PP->new->canonical(1);
my $prefix = "FSMGEN_VIAL_TRACE_V2\t";
my $plan_id = 'plan/portable-vhdl-trace-v2-test';
my $run_id = "run/$plan_id/scenario/one";
my @kind = qw(
    header scenario_start events samples expectations scoreboards coverage faults
    scenario_end footer
);
my %expected = map { $_ => 0 } @kind;
@expected{qw(header scenario_start samples scenario_end footer)} = (1, 1, 2, 1, 1);

my $catalog_projection = {
    entries => [
        {sample_id => 'sample/endpoint/out', semantic_id => 'endpoint/out', width => 2},
        {sample_id => 'sample/probe/state', semantic_id => 'probe/state', width => 2},
    ],
    schema => 'fsmgen.vial_vhdl_observation_catalog.v1',
    total_width => 4,
};
my $catalog = {
    catalog_digest => 'sha256/' . sha256_hex($json->encode($catalog_projection)),
    %$catalog_projection,
};

my $checked_authority =
    FSM::VIAL::Backend::VHDLPortableTraceValidator->checked_reference_authority;
is_deeply([sort keys %$checked_authority], [sort qw(
    expected_observation_catalog expected_plan_id expected_run_ids
)], 'checked reference authority has one closed caller contract');
is($checked_authority->{expected_plan_id},
    'plan/e236297c8b434a9b374d1800112841e00327bdbd5d8d9130440bd20681fbed6e',
    'checked reference authority retains the emitted plan identity');
is($checked_authority->{expected_observation_catalog}{catalog_digest},
    'sha256/f315169a60ab43d9abc747aa42a2ae5fbe2dadd303bc965f0eafb1bbd95989e9',
    'checked reference authority retains the emitted catalog identity');
my $checked_snapshot = clone($checked_authority);
$checked_authority->{expected_plan_id} = 'plan/mutated';
$checked_authority->{expected_run_ids}[0] = 'run/mutated';
is_deeply(
    FSM::VIAL::Backend::VHDLPortableTraceValidator->checked_reference_authority,
    $checked_snapshot,
    'checked reference authority is returned as a defensive clone');

my @record = (
    record('header', undef, time_record(0, 0), {observation_catalog => $catalog}),
    record('scenario_start', $run_id, time_record(0, 0)),
    record('samples', $run_id, time_record(1, 1), {normalized_bits => '01XZ'}),
    record('samples', $run_id, time_record(2, 1), {normalized_bits => 'ZX10'}),
    record('scenario_end', $run_id, time_record(2, 3)),
    record('footer', undef, time_record(2, 3)),
);
number_records(\@record);

my $valid = validate_records(\@record);
ok($valid->{ok}, 'closed trace-v2 fixture validates');
is_deeply([sort keys %$valid],
    [sort @{FSM::VIAL::Backend::VHDLPortableTraceValidator->result_keys}],
    'validator result shell is closed');
is($valid->{trace}{schema}, 'fsmgen.vial_vhdl_runtime_trace.v2',
    'trace schema is exact revision 2');
is($valid->{trace}{record_count}, 6, 'record total is exact');
is($valid->{trace}{record_counts}{samples}, 2, 'sample total is exact');
is($valid->{trace}{observation_catalog}{catalog_digest}, $catalog->{catalog_digest},
    'validated result retains the authenticated catalog identity');
is($valid->{trace}{observation_catalog}{total_width}, 4,
    'validated result retains the exact normalized width');
is_deeply($valid->{trace}{observation_catalog}{sample_ids},
    ['sample/endpoint/out', 'sample/probe/state'],
    'validated result retains catalog order');

my $invocation = FSM::VIAL::Backend::VHDLPortableTraceValidator->validate({
    trace_text => trace_text(\@record),
});
failure($invocation, 'VIAL_VHDL_TRACE_SHAPE_ERROR',
    'open invocation record');

my $foreign_prefix = trace_text(\@record);
$foreign_prefix =~ s/FSMGEN_VIAL_TRACE_V2/FSMGEN_VIAL_TRACE_V1/;
failure(validate_text($foreign_prefix), 'VIAL_VHDL_TRACE_PREFIX_ERROR',
    'foreign prefix');

my $malformed = trace_text(\@record);
$malformed =~ s/}\n\z/\n/;
failure(validate_text($malformed), 'VIAL_VHDL_TRACE_JSON_ERROR',
    'malformed JSON');

my $noncanonical = trace_text(\@record);
$noncanonical =~ s/\{"payload"/\{ "payload"/;
failure(validate_text($noncanonical), 'VIAL_VHDL_TRACE_CANONICAL_ERROR',
    'noncanonical JSON');

my @missing = clone(\@record)->@*;
splice @missing, 3, 1;
number_records(\@missing);
failure(validate_records(\@missing), 'VIAL_VHDL_TRACE_COUNT_ERROR',
    'missing sample record');

my @duplicate = clone(\@record)->@*;
splice @duplicate, 4, 0, clone($duplicate[3]);
number_records(\@duplicate);
failure(validate_records(\@duplicate), 'VIAL_VHDL_TRACE_COUNT_ERROR',
    'duplicate sample record');

my @reordered = clone(\@record)->@*;
$reordered[2]{payload}{logical_time}{cycle} = 2;
$reordered[3]{payload}{logical_time}{cycle} = 1;
failure(validate_records(\@reordered), 'VIAL_VHDL_TRACE_TIME_ERROR',
    'reordered logical time');

my @foreign_plan = clone(\@record)->@*;
$_->{plan_id} = 'plan/foreign' for @foreign_plan;
failure(validate_records(\@foreign_plan), 'VIAL_VHDL_TRACE_ID_ERROR',
    'foreign plan identity');

my @foreign_run = clone(\@record)->@*;
$foreign_run[$_]{run_id} = 'run/foreign' for 1 .. 4;
failure(validate_records(\@foreign_run), 'VIAL_VHDL_TRACE_RUN_ERROR',
    'foreign run identity');

my @bad_digest = clone(\@record)->@*;
$bad_digest[0]{payload}{observation_catalog}{catalog_digest} = 'sha256/' . ('0' x 64);
failure(validate_records(\@bad_digest), 'VIAL_VHDL_TRACE_CATALOG_DIGEST_ERROR',
    'unauthenticated catalog');

my @foreign_catalog = clone(\@record)->@*;
$foreign_catalog[0]{payload}{observation_catalog}{entries}[0]{semantic_id}
    = 'endpoint/foreign';
my $foreign_projection = clone(
    $foreign_catalog[0]{payload}{observation_catalog});
delete $foreign_projection->{catalog_digest};
$foreign_catalog[0]{payload}{observation_catalog}{catalog_digest}
    = 'sha256/' . sha256_hex($json->encode($foreign_projection));
failure(validate_records(\@foreign_catalog), 'VIAL_VHDL_TRACE_CATALOG_ERROR',
    'foreign authenticated catalog');

my @bad_width = clone(\@record)->@*;
$bad_width[2]{payload}{normalized_bits} = '01X';
failure(validate_records(\@bad_width), 'VIAL_VHDL_TRACE_SAMPLE_WIDTH_ERROR',
    'wrong sample width');

my @unknown_symbol = clone(\@record)->@*;
$unknown_symbol[2]{payload}{normalized_bits} = '01UL';
failure(validate_records(\@unknown_symbol), 'VIAL_VHDL_TRACE_SAMPLE_ERROR',
    'unknown normalized symbol');

my @wrong_phase = clone(\@record)->@*;
$wrong_phase[2]{payload}{logical_time}{phase_rank} = 2;
failure(validate_records(\@wrong_phase), 'VIAL_VHDL_TRACE_SAMPLE_PHASE_ERROR',
    'sample outside SAMPLE phase');

my @unknown_phase = clone(\@record)->@*;
$unknown_phase[1]{payload}{logical_time}{phase_rank} = 4;
failure(validate_records(\@unknown_phase), 'VIAL_VHDL_TRACE_TIME_ERROR',
    'logical time outside the closed phase vocabulary');

my @unframed = clone(\@record)->@*;
$unframed[1]{record_kind} = 'samples';
$unframed[1]{payload}{normalized_bits} = '01XZ';
$unframed[1]{payload}{logical_time}{phase_rank} = 1;
$unframed[2]{record_kind} = 'scenario_start';
delete $unframed[2]{payload}{normalized_bits};
failure(validate_records(\@unframed), 'VIAL_VHDL_TRACE_RUN_ERROR',
    'sample before scenario start');

my @duplicate_catalog_id = clone(\@record)->@*;
$duplicate_catalog_id[0]{payload}{observation_catalog}{entries}[1]{sample_id}
    = 'sample/endpoint/out';
my $projection = clone($duplicate_catalog_id[0]{payload}{observation_catalog});
delete $projection->{catalog_digest};
$duplicate_catalog_id[0]{payload}{observation_catalog}{catalog_digest}
    = 'sha256/' . sha256_hex($json->encode($projection));
failure(validate_records(\@duplicate_catalog_id), 'VIAL_VHDL_TRACE_CATALOG_ERROR',
    'duplicate catalog sample identity');

done_testing();

sub record {
    my ($kind, $run, $time, $extra) = @_;
    return {
        payload => {logical_time => $time, %{clone($extra // {})}},
        plan_id => $plan_id,
        record_kind => $kind,
        run_id => $run,
        schema => 'fsmgen.vial_vhdl_runtime_trace.v2',
        schema_version => 2,
        sequence => 0,
    };
}

sub time_record {
    my ($cycle, $phase_rank) = @_;
    return {
        cycle => $cycle,
        local_index => 0,
        phase_rank => $phase_rank,
        static_rank => 0,
    };
}

sub number_records {
    my ($records) = @_;
    $records->[$_]{sequence} = $_ for 0 .. $#$records;
}

sub trace_text {
    my ($records) = @_;
    return join('', map { $prefix . $json->encode($_) . "\n" } @$records);
}

sub validate_records {
    my ($records) = @_;
    return validate_text(trace_text($records));
}

sub validate_text {
    my ($text) = @_;
    return FSM::VIAL::Backend::VHDLPortableTraceValidator->validate({
        trace_text => $text,
        expected_plan_id => $plan_id,
        expected_run_ids => [$run_id],
        expected_observation_catalog => $catalog,
        expected_record_counts => \%expected,
    });
}

sub failure {
    my ($result, $code, $label) = @_;
    ok(!$result->{ok}, "$label fails closed");
    is($result->{diagnostics}[0]{code}, $code, "$label has diagnostic $code");
}

sub clone {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}
