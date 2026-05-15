#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'pipeline and CLI accept typed-list top expressions on aggregate targets' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'typed_top_expr_list_target.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'typed_top_expr_list_target.sv');
    my $rtl_metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:typed_top_expr_list_target
  (+types
    (type status_t (list bit (bits 4)))
  )
  (?ports:public_io
    status_bus<2
    payload_bus<4
    packed_status>status_t
  )
  (?rtl:uart_tx)
  (?wiring:wiring
    /status_bus[0],payload_bus[3:0]/packed_status/
    /=0/uart_tx.dummy/
  )
)
FSM
    );

    write_file(
        $rtl_metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  dummy<1:data
)
RTLIF
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);

    is_deeply(
        $result->{composition_plan}->auxiliary_assignments,
        [
            '    assign packed_status = {status_bus[0], payload_bus[3:0]};',
        ],
        'pipeline keeps the typed top-expression assignment when the aggregate target shape matches',
    );
    like(
        $result->{hdl_code},
        qr/assign packed_status = \{status_bus\[0\], payload_bus\[3:0\]\};/s,
        'generated HDL emits the typed top-expression assignment directly on the aggregate-typed top output',
    );

    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--output', $output_path, $composition_path],
        verbose => 0,
    );
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok($success, 'CLI accepts compatible typed top-expression aggregate targets');
    ok(-e $output_path, 'CLI writes HDL for compatible typed top-expression aggregate targets');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for compatible typed top-expression aggregate targets');
    unlike($combined_output, qr/aggregate-expression binding|declared type/s, 'successful typed top-expression aggregate run does not report aggregate-expression failures');
};

subtest 'pipeline and CLI accept typed aggregate top-port member sources' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'typed_aggregate_top_member_sources.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'typed_aggregate_top_member_sources.sv');
    my $rtl_metadata_path = File::Spec->catfile($tempdir, 'sink.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:typed_aggregate_top_member_sources
  (+types
    (type pair_t (list bit (bits 4) bit))
    (type frame_t (record (tag (bits 4)) (flag bit) (payload pair_t)))
  )
  (?ports:public_io
    in_frame<frame_t
    tag_out>4
  )
  (?rtl:sink)
  (?wiring:wiring
    /in_frame.tag/tag_out/
    /in_frame.payload[1]/sink.nibble/
    /in_frame.flag/sink.enable/
  )
)
FSM
    );

    write_file(
        $rtl_metadata_path,
        <<'RTLIF'
(?rtlif:sink
  nibble<4:data
  enable<1:data
)
RTLIF
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my ($sink_instance) = grep { $_->{instance_name} eq 'sink' } @{ $result->{structural_rtl_ir}{instances} || [] };
    my %binding_by_port = map { $_->{port_name} => $_ } @{ $sink_instance->{port_bindings} || [] };
    my $hdl = $result->{hdl_code};

    is_deeply(
        $result->{composition_plan}->auxiliary_assignments,
        [
            '    assign tag_out = in_frame.tag;',
        ],
        'pipeline emits direct top-output assignment from a typed aggregate top member source',
    );
    is($binding_by_port{nibble}{connection_expr}{kind}, 'member_access', 'structural binding keeps the typed list item as a member-access expression');
    is($binding_by_port{nibble}{connection_expr}{member_name}, 'item_1', 'structural binding lowers list item access to the generated packed-list field');
    is($binding_by_port{nibble}{connection_type_spec}{width}, 4, 'structural binding preserves the resolved list item width');
    is($binding_by_port{enable}{connection_type_spec}{kind}, 'bit', 'structural binding preserves single-bit record member type');
    like($hdl, qr/assign tag_out = in_frame\.tag;/s, 'generated HDL assigns from the top aggregate record member');
    like($hdl, qr/\.nibble\(in_frame\.payload\.item_1\)/s, 'generated HDL binds the top aggregate list item through the packed-list field');
    like($hdl, qr/\.enable\(in_frame\.flag\)/s, 'generated HDL binds the top aggregate single-bit record member');

    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--output', $output_path, $composition_path],
        verbose => 0,
    );
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok($success, 'CLI accepts typed aggregate top-port member sources');
    ok(-e $output_path, 'CLI writes HDL for typed aggregate top-port member sources');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for typed aggregate top-port member sources');
    unlike($combined_output, qr/aggregate member|endpoint resolution is blocked/s, 'successful aggregate top-port member source run stays quiet');
};

subtest 'pipeline and CLI accept typed aggregate child-output member sources' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'typed_aggregate_child_member_sources.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'typed_aggregate_child_member_sources.sv');
    my $rtl_metadata_path = File::Spec->catfile($tempdir, 'sink.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:typed_aggregate_child_member_sources
  (?ports:public_io
    tag_out>4
  )
  (?dtc:producer producer_src)
  (?rtl:sink)
  (?wiring:wiring
    /producer.OUT_FRAME.tag/tag_out/
    /producer.OUT_FRAME.payload[1]/sink.nibble/
    /producer.OUT_FRAME.flag/sink.enable/
  )
)

(?dt:producer_src
  (+types
    (type pair_t (list bit (bits 4) bit))
    (type frame_t (record (tag (bits 4)) (flag bit) (payload pair_t)))
  )
  (+size
    (OUT_FRAME frame_t)
  )
  (-pass
    (OUT_FRAME = 11'b10100111100)
  )
)
FSM
    );

    write_file(
        $rtl_metadata_path,
        <<'RTLIF'
(?rtlif:sink
  nibble<4:data
  enable<1:data
)
RTLIF
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my ($sink_instance) = grep { $_->{instance_name} eq 'sink' } @{ $result->{structural_rtl_ir}{instances} || [] };
    my %binding_by_port = map { $_->{port_name} => $_ } @{ $sink_instance->{port_bindings} || [] };
    my ($carrier_net) = grep { $_->{name} eq 'comp_link_producer_OUT_FRAME' } @{ $result->{structural_rtl_ir}{nets} || [] };
    my $hdl = $result->{hdl_code};

    ok($carrier_net, 'pipeline creates one typed carrier for projected aggregate child-output member sources');
    is($carrier_net->{declared_type_name}, 'frame_t', 'carrier preserves the child aggregate declared type name');
    is($carrier_net->{declared_type_spec}{kind}, 'record', 'carrier preserves the child aggregate declared type spec');
    is_deeply(
        $result->{composition_plan}->auxiliary_assignments,
        [
            '    assign tag_out = comp_link_producer_OUT_FRAME.tag;',
        ],
        'pipeline emits top-output assignment from the projected child aggregate carrier',
    );
    is($binding_by_port{nibble}{connection_expr}{kind}, 'member_access', 'structural binding keeps projected child list item as a member-access expression');
    is($binding_by_port{nibble}{connection_expr}{member_name}, 'item_1', 'structural binding lowers projected child list item to the generated packed-list field');
    is($binding_by_port{nibble}{connection_type_spec}{width}, 4, 'structural binding preserves projected child list item width');
    like($hdl, qr/\bframe_t__fsmgen_t\s+comp_link_producer_OUT_FRAME\b/s, 'generated HDL declares the projected child carrier with its aggregate typedef');
    like($hdl, qr/\.OUT_FRAME\(comp_link_producer_OUT_FRAME\)/s, 'generated HDL binds the producer aggregate output to the shared carrier');
    like($hdl, qr/assign tag_out = comp_link_producer_OUT_FRAME\.tag;/s, 'generated HDL assigns from the projected child aggregate record member');
    like($hdl, qr/\.nibble\(comp_link_producer_OUT_FRAME\.payload\.item_1\)/s, 'generated HDL binds the projected child aggregate list item through the packed-list field');
    like($hdl, qr/\.enable\(comp_link_producer_OUT_FRAME\.flag\)/s, 'generated HDL binds the projected child aggregate single-bit record member');

    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--output', $output_path, $composition_path],
        verbose => 0,
    );
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok($success, 'CLI accepts typed aggregate child-output member sources');
    ok(-e $output_path, 'CLI writes HDL for typed aggregate child-output member sources');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for typed aggregate child-output member sources');
    unlike($combined_output, qr/aggregate member|endpoint resolution is blocked/s, 'successful aggregate child-output member source run stays quiet');
};

subtest 'pipeline rejects width-equal top expressions across incompatible typed aggregate targets' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'typed_top_expr_mismatch.fsm');
    my $rtl_metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:typed_top_expr_mismatch
  (+types
    (type wrong_t (record (flag bit) (payload (bits 4))))
  )
  (?ports:public_io
    status_bus<2
    payload_bus<4
    packed_status>wrong_t
  )
  (?rtl:uart_tx)
  (?wiring:wiring
    /status_bus[0],payload_bus[3:0]/packed_status/
    /=0/uart_tx.dummy/
  )
)
FSM
    );

    write_file(
        $rtl_metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  dummy<1:data
)
RTLIF
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses top expression 'status_bus\[0\],payload_bus\[3:0\]' as an explicit link source, .* explicit aggregate-expression binding is blocked because expression contract 'list<bit, bits\[4\]>' does not match target declared type 'record\{flag:bit, payload:bits\[4\]\}' on 'packed_status'/s,
        'pipeline blocks width-equal top-expression bindings when aggregate shape conflicts with the target declared type',
    );
};

subtest 'pipeline rejects width-equal child expressions across incompatible typed aggregate targets' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'typed_child_expr_mismatch.fsm');
    my $producer_metadata_path = File::Spec->catfile($tempdir, 'producer.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:typed_child_expr_mismatch
  (+types
    (type wrong_t (record (flag bit) (payload (bits 4))))
  )
  (?ports:public_io
    packed_status>wrong_t
  )
  (?rtl:producer)
  (?wiring:wiring
    /producer.OUT_WORD[4:0]/packed_status/
  )
)
FSM
    );

    write_file(
        $producer_metadata_path,
        <<'RTLIF'
(?rtlif:producer
  OUT_WORD>8:data
)
RTLIF
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses child expression 'producer\.OUT_WORD\[4:0\]' as an explicit link source, .* explicit aggregate-expression binding is blocked because expression contract 'bits\[5\]' does not match target declared type 'record\{flag:bit, payload:bits\[4\]\}' on 'packed_status'/s,
        'pipeline blocks width-equal child-expression bindings when aggregate shape conflicts with the target declared type',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
