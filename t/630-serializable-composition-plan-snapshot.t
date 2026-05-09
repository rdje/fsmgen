#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use JSON::PP qw(decode_json encode_json);
use Scalar::Util qw(blessed);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::SerializableCompositionPlanSnapshot qw(
    build_serializable_composition_plan_snapshot
    build_serializable_composition_plan_snapshot_contract
    serializable_composition_plan_snapshot_collection_keys
    serializable_composition_plan_snapshot_contract_source
    serializable_composition_plan_snapshot_public_top_level_keys
    serializable_composition_plan_snapshot_summary_keys
);

subtest 'composition plan snapshot contract describes JSON-safe public shape' => sub {
    my $contract = build_serializable_composition_plan_snapshot_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks snapshot as bounded public');
    is(
        $contract->{contract_source},
        serializable_composition_plan_snapshot_contract_source(),
        'contract records its owner',
    );
    is_deeply(
        $contract->{public_top_level_presence_keys},
        serializable_composition_plan_snapshot_public_top_level_keys(),
        'contract publishes top-level snapshot keys',
    );
    is_deeply(
        $contract->{summary_keys},
        serializable_composition_plan_snapshot_summary_keys(),
        'contract publishes summary keys',
    );
    is_deeply(
        $contract->{collection_keys},
        serializable_composition_plan_snapshot_collection_keys(),
        'contract publishes collection keys',
    );
    ok($contract->{json_safe_as_whole}, 'contract marks snapshot JSON-safe as a whole');
    ok(!$contract->{raw_plan_object_exported}, 'contract does not export the raw plan object');
};

subtest 'snapshot serializes composition plan without blessed objects' => sub {
    my $composition_path = write_composition_fixture();
    my $result = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
    )->generate_hdl_from_file($composition_path);

    ok(blessed($result->{composition_plan}), 'fixture returns the raw in-process composition plan');

    my $snapshot = build_serializable_composition_plan_snapshot(
        composition_plan => $result->{composition_plan},
    );

    is($snapshot->{composition_plan_snapshot_schema_version}, 1, 'snapshot exposes schema version');
    is($snapshot->{report_source}, serializable_composition_plan_snapshot_contract_source(), 'snapshot records report owner');
    ok($snapshot->{present}, 'snapshot marks the raw plan as present');
    is($snapshot->{source_object_class}, 'FSM::Composition::Plan', 'snapshot records raw plan class as metadata');
    is($snapshot->{lane}, 'C1', 'snapshot records lane');
    is($snapshot->{top_name}, 'serializable_plan_snapshot_top', 'snapshot records top name');
    is($snapshot->{summary}{port_count}, 4, 'snapshot records top-port count');
    is($snapshot->{summary}{instance_count}, 1, 'snapshot records instance count');
    is($snapshot->{summary}{resolved_link_count}, 4, 'snapshot records resolved link count');
    is($snapshot->{top_ports}[3]{name}, 'output_data', 'snapshot records top-port summaries');
    is($snapshot->{instances}[0]{instance_name}, 'producer', 'snapshot records child instance summaries');
    is_deeply(
        [sort @{$snapshot->{instances}[0]{interface_port_names}}],
        [sort qw(clk rstn select output_data)],
        'snapshot records child interface port names',
    );
    ok(!contains_blessed($snapshot), 'snapshot contains no blessed objects');

    my $encoded = encode_json($snapshot);
    ok(length($encoded), 'snapshot encodes as JSON');
    my $decoded = decode_json($encoded);
    is($decoded->{top_name}, 'serializable_plan_snapshot_top', 'encoded snapshot decodes with top name intact');
};

subtest 'missing raw plan still produces a bounded absent snapshot' => sub {
    my $snapshot = build_serializable_composition_plan_snapshot();

    ok(!$snapshot->{present}, 'absent snapshot records plan absence');
    is($snapshot->{summary}{port_count}, 0, 'absent snapshot has zero ports');
    is_deeply($snapshot->{top_ports}, [], 'absent snapshot has an empty top-port list');
    ok(!contains_blessed($snapshot), 'absent snapshot contains no blessed objects');
};

done_testing();

sub contains_blessed {
    my ($value) = @_;
    return 0 if defined(blessed($value)) && blessed($value) eq 'JSON::PP::Boolean';
    return 1 if blessed($value);
    return 0 unless ref($value);
    if (ref($value) eq 'ARRAY') {
        return 1 if grep { contains_blessed($_) } @$value;
        return 0;
    }
    if (ref($value) eq 'HASH') {
        return 1 if grep { contains_blessed($_) } values %$value;
        return 0;
    }
    return 0;
}

sub write_composition_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'serializable_plan_snapshot_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:serializable_plan_snapshot_top
  (?ports:public_io
    clk
    rstn
    select
    output_data>8
  )
  (?fsmc:producer producer_src)
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (select 1)
    (output_data 8)
  )
  (IDLE
    (<select==1'b0
      (<= (output_data> 8'1))
    )
  )
)
FSM
    );
    return $composition_path;
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
