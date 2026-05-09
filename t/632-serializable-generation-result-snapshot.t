#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::SerializableGenerationResultSnapshot qw(
    build_serializable_generation_result_snapshot
    build_serializable_generation_result_snapshot_contract
    serializable_generation_result_snapshot_contract_source
    serializable_generation_result_snapshot_public_top_level_keys
    serializable_generation_result_snapshot_summary_keys
);

subtest 'generation result snapshot contract describes JSON-safe shape' => sub {
    my $contract = build_serializable_generation_result_snapshot_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks snapshot as bounded public');
    is(
        $contract->{contract_source},
        serializable_generation_result_snapshot_contract_source(),
        'contract records its owner',
    );
    is_deeply(
        $contract->{public_top_level_presence_keys},
        serializable_generation_result_snapshot_public_top_level_keys(),
        'contract publishes top-level snapshot keys',
    );
    is_deeply(
        $contract->{summary_keys},
        serializable_generation_result_snapshot_summary_keys(),
        'contract publishes summary keys',
    );
    ok($contract->{json_safe_as_whole}, 'contract marks snapshot JSON-safe');
    ok(!$contract->{raw_result_object_exported}, 'contract does not export the raw result object');
};

subtest 'direct generation result snapshot summarizes stable public facts' => sub {
    my $fsm_path = write_direct_fixture();
    my $result = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
    )->generate_hdl_from_file($fsm_path);

    my $snapshot = build_serializable_generation_result_snapshot(result => $result);

    assert_public_keys($snapshot);
    is($snapshot->{generation_result_snapshot_schema_version}, 1, 'snapshot exposes schema version');
    is($snapshot->{contract_source}, serializable_generation_result_snapshot_contract_source(), 'snapshot records contract owner');
    is($snapshot->{summary}{module_name}, 'serializable_generation_result_snapshot_direct', 'snapshot records module name');
    is($snapshot->{summary}{source_root_kind}, 'fsm', 'snapshot records direct source root kind');
    ok($snapshot->{summary}{hdl_code_present}, 'snapshot records HDL presence');
    ok($snapshot->{summary}{hdl_code_length} > 0, 'snapshot records HDL size');
    ok($snapshot->{stable_summary_presence}{module_info}, 'snapshot records stable module_info presence');
    ok($snapshot->{semantic_layer_presence}{intent_hir}, 'snapshot records intent_hir presence');
    ok(!$snapshot->{raw_shell_presence}{composition_plan}{present}, 'direct snapshot records absent composition plan shell');
    ok(length(encode_json($snapshot)), 'direct snapshot encodes as JSON');
};

subtest 'composition generation result snapshot records raw shell presence without exporting raw objects' => sub {
    my $composition_path = File::Spec->catfile(File::Spec->catdir($FindBin::Bin, '..'), 'fsm', 'apb_tb.fsm');
    my $result = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
    )->generate_hdl_from_file($composition_path);

    my $snapshot = build_serializable_generation_result_snapshot(result => $result);

    assert_public_keys($snapshot);
    is($snapshot->{summary}{module_name}, 'apb_tb', 'composition snapshot records module name');
    is($snapshot->{summary}{source_root_kind}, 'top', 'composition snapshot records source root kind');
    is($snapshot->{summary}{composition_child_count}, 2, 'composition snapshot records child count');
    ok($snapshot->{raw_shell_presence}{composition_plan}{present}, 'composition snapshot records composition_plan presence');
    is($snapshot->{raw_shell_presence}{composition_plan}{value_ref}, 'FSM::Composition::Plan', 'composition snapshot records raw plan class metadata');
    ok($snapshot->{raw_shell_presence}{raw_ast}{present}, 'composition snapshot records raw_ast presence');
    ok(length(encode_json($snapshot)), 'composition snapshot encodes as JSON');
    my $decoded = decode_json(encode_json($snapshot));
    is($decoded->{summary}{module_name}, 'apb_tb', 'encoded snapshot decodes with module name intact');
};

done_testing();

sub assert_public_keys {
    my ($snapshot) = @_;
    for my $key (@{serializable_generation_result_snapshot_public_top_level_keys()}) {
        ok(exists $snapshot->{$key}, "snapshot keeps key $key");
    }
}

sub write_direct_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'serializable_generation_result_snapshot_direct.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:serializable_generation_result_snapshot_direct
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
    return $fsm_path;
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
