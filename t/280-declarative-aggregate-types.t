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

subtest 'direct-root +types accept packed list and record aliases with order-independent local and imported references' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $fsm_path = File::Spec->catfile($tempdir, 'typed_aggregate_direct_root.fsm');
    my $package_path = File::Spec->catfile($libdir, 'shared_types.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'typed_aggregate_direct_root.sv');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_types
  (+types
    (type frame_t (record (tag nibble_t) (flag bit) (payload header_t)))
    (type header_t (list nibble_t nibble_t))
    (type nibble_t (bits 4))
  )
)
FSM
    );

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:typed_aggregate_direct_root
  (+import shared_types)
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+types
    (type pair_t (list bit shared_types.nibble_t bit))
    (type local_frame shared_types.frame_t)
  )
  (+size
    (PAIR_OUT pair_t)
    (FRAME_OUT local_frame)
  )
  (idle
    (PAIR_OUT = 6'b101010)
    (FRAME_OUT = 13'b1010100111100)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
        source_search_paths => [$libdir],
    );
    my $result = $pipeline->generate_hdl_from_file($fsm_path);
    my $symbol_contract = $result->{intent_hir}{symbol_contract};
    my $module_info = $result->{module_info};
    my $hdl = $result->{hdl_code};

    is($symbol_contract->{type_count}, 2, 'direct aggregate symbol contract counts declared local types');
    is_deeply($symbol_contract->{type_names}, ['local_frame', 'pair_t'], 'direct aggregate symbol contract preserves stable local type names');
    is($symbol_contract->{types}{local_frame}{kind}, 'record', 'direct aggregate symbol contract preserves record type shape');
    is($symbol_contract->{types}{local_frame}{width}, 13, 'direct aggregate symbol contract preserves packed record width');
    is_deeply($symbol_contract->{types}{local_frame}{member_order}, ['tag', 'flag', 'payload'], 'direct aggregate symbol contract preserves record member order');
    is($symbol_contract->{types}{local_frame}{members}{payload}{kind}, 'list', 'direct aggregate symbol contract preserves nested list shape');
    is($symbol_contract->{types}{local_frame}{members}{payload}{width}, 8, 'direct aggregate symbol contract preserves nested list packed width');
    is($symbol_contract->{types}{pair_t}{kind}, 'list', 'direct aggregate symbol contract preserves list type shape');
    is($symbol_contract->{types}{pair_t}{width}, 6, 'direct aggregate symbol contract preserves packed list width');
    is_deeply($module_info->{symbol_contract}, $symbol_contract, 'module_info mirrors direct aggregate symbol contracts');
    like($hdl, qr/typedef struct packed \{\n\s+logic \[3:0\] tag;\n\s+logic flag;\n\s+struct packed \{\n\s+logic \[3:0\] item_0;\n\s+logic \[3:0\] item_1;\n\s+\} payload;\n\s+\} local_frame__fsmgen_t; \/\/ local_frame/s, 'generated HDL emits a packed typedef for direct aggregate record signals');
    like($hdl, qr/typedef struct packed \{\n\s+logic item_0;\n\s+logic \[3:0\] item_1;\n\s+logic item_2;\n\s+\} pair_t__fsmgen_t; \/\/ pair_t/s, 'generated HDL emits a packed typedef for direct aggregate list signals');
    like($hdl, qr/\blocal_frame__fsmgen_t\s+FRAME_OUT\b/s, 'generated HDL declares direct aggregate record signals through their typedef');
    like($hdl, qr/\bpair_t__fsmgen_t\s+PAIR_OUT\b/s, 'generated HDL declares direct aggregate list signals through their typedef');

    my @cmd = ('./bin/fsmgen', '--quiet', '--path', $libdir, '--output', $output_path, $fsm_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok($success, 'CLI accepts direct-root aggregate type aliases');
    ok(-e $output_path, 'CLI emits HDL for direct-root aggregate type aliases');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for direct-root aggregate type aliases');
    unlike($combined_output, qr/declarative type|aggregate type alias/s, 'successful direct aggregate type CLI run does not report type failures');
};

subtest 'composition ?ports accept packed list and record aliases, including local aliases with imported aggregate members' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $composition_path = File::Spec->catfile($tempdir, 'typed_aggregate_top_ports.fsm');
    my $package_path = File::Spec->catfile($libdir, 'shared_types.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'typed_aggregate_top_ports.sv');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_types
  (+types
    (type frame_t (record (tag nibble_t) (flag bit) (payload header_t)))
    (type header_t (list nibble_t nibble_t))
    (type nibble_t (bits 4))
  )
)
FSM
    );

    write_file(
        $composition_path,
        <<'FSM'
(?top:typed_aggregate_top_ports
  (+import shared_types)
  (?ports:public_io
    in_frame<shared_types.frame_t
    out_frame>frame_t
    out_lane>lane_t
  )
  (+types
    (type frame_t shared_types.frame_t)
    (type lane_t (record (head shared_types.header_t) (tail (list bit bit))))
  )
  (?rtl:bridge)
  (?toplink:wiring
    /in_frame/bridge.frame_in/
    /bridge.frame_out/out_frame/
    /bridge.lane_out/out_lane/
  )
)

(?rtlif:bridge
  frame_in<13:data
  frame_out>13:data
  lane_out>10:data
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
        source_search_paths => [$libdir],
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $ports = $result->{composition_spec}->top->ports_blocks->[0]->ports;
    my %ports_by_name = map { $_->name => $_ } @$ports;
    my $symbol_contract = $result->{intent_hir}{symbol_contract};
    my $module_info = $result->{module_info};
    my $hdl = $result->{hdl_code};

    is($ports_by_name{in_frame}->width, 13, 'composition imported aggregate package type resolves to packed width 13');
    is($ports_by_name{out_frame}->width, 13, 'composition local alias to imported aggregate type resolves to packed width 13');
    is($ports_by_name{out_lane}->width, 10, 'composition local aggregate type with imported members resolves to packed width 10');
    is($symbol_contract->{types}{frame_t}{kind}, 'record', 'composition symbol contract preserves local imported record alias shape');
    is($symbol_contract->{types}{frame_t}{width}, 13, 'composition symbol contract preserves local imported record alias width');
    is($symbol_contract->{types}{lane_t}{kind}, 'record', 'composition symbol contract preserves local record alias shape');
    is_deeply($symbol_contract->{types}{lane_t}{member_order}, ['head', 'tail'], 'composition symbol contract preserves record member order');
    is($symbol_contract->{types}{lane_t}{members}{head}{kind}, 'list', 'composition symbol contract preserves imported nested list members');
    is($symbol_contract->{types}{lane_t}{members}{head}{width}, 8, 'composition symbol contract preserves imported nested list member width');
    is($symbol_contract->{types}{lane_t}{width}, 10, 'composition symbol contract preserves packed local record width');
    is_deeply($module_info->{symbol_contract}, $symbol_contract, 'module_info mirrors composition aggregate symbol contracts');
    like($hdl, qr/typedef struct packed \{\n\s+logic \[3:0\] tag;\n\s+logic flag;\n\s+struct packed \{\n\s+logic \[3:0\] item_0;\n\s+logic \[3:0\] item_1;\n\s+\} payload;\n\} shared_types__frame_t__fsmgen_t; \/\/ shared_types\.frame_t/s, 'generated top HDL emits a packed typedef for the imported aggregate alias');
    like($hdl, qr/typedef struct packed \{\n\s+struct packed \{\n\s+logic \[3:0\] item_0;\n\s+logic \[3:0\] item_1;\n\s+\} head;\n\s+struct packed \{\n\s+logic item_0;\n\s+logic item_1;\n\s+\} tail;\n\} lane_t__fsmgen_t; \/\/ lane_t/s, 'generated top HDL emits a packed typedef for the local aggregate alias');
    like($hdl, qr/input shared_types__frame_t__fsmgen_t in_frame\b/s, 'generated top HDL uses the imported aggregate typedef on input ports');
    like($hdl, qr/output frame_t__fsmgen_t out_frame\b/s, 'generated top HDL uses the local aggregate typedef on output ports');
    like($hdl, qr/output lane_t__fsmgen_t out_lane\b/s, 'generated top HDL uses the local aggregate typedef on output ports');

    my @cmd = ('./bin/fsmgen', '--quiet', '--path', $libdir, '--output', $output_path, $composition_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok($success, 'CLI accepts composition aggregate type aliases');
    ok(-e $output_path, 'CLI emits HDL for composition aggregate type aliases');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for composition aggregate type aliases');
    unlike($combined_output, qr/composition port sizing is blocked|aggregate type alias/s, 'successful composition aggregate type CLI run does not report width-token failures');
};

subtest 'direct-root aggregate type cycles fail explicitly' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'bad_direct_aggregate_type_cycle.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'bad_direct_aggregate_type_cycle.sv');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:bad_direct_aggregate_type_cycle
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+types
    (type A (record (next B)))
    (type B (list A bit))
  )
  (+size
    (OUT A)
  )
  (idle
    (OUT = 0)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    like(
        $pipeline_error,
        qr/Malformed declarative type scope in source 'bad_direct_aggregate_type_cycle'.*Cycle:\s*type 'A' -> type 'B' -> type 'A'/s,
        'pipeline reports the explicit aggregate type dependency cycle',
    );

    my @cmd = ('./bin/fsmgen', '--quiet', '--output', $output_path, $fsm_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok(!$success, 'CLI rejects aggregate type dependency cycles');
    ok(!-e $output_path, 'CLI does not emit HDL for aggregate type dependency cycles');
    like(
        $combined_output,
        qr/Malformed declarative type scope in source 'bad_direct_aggregate_type_cycle'.*Cycle:\s*type 'A' -> type 'B' -> type 'A'/s,
        'CLI surfaces the explicit aggregate type dependency cycle',
    );
    isnt($error_code, 0, 'CLI exits non-zero for aggregate type dependency cycles');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print {$fh} $content;
    close $fh or die "Cannot close $path: $!";
}
