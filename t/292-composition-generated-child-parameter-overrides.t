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

subtest 'generated child parameter overrides lower through structural IR into SV instance parameters' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'parameterized_generated_child_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'parameterized_generated_child_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:parameterized_generated_child_top
  (+constants
    (OVERRIDE_WIDTH 16)
    (TOP_LANES (8'hA5 8'h3C))
    (TOP_LANE_MASK (8'hF0 8'h0F))
    (TOP_LANE_INC (8'h01 8'h02))
  )
  (?ports:public_io
    clk
    rstn
    payload_in<16
    payload_out>16
  )
  (?fsmc:u_child child_src
    (params
      (WIDTH OVERRIDE_WIDTH)
      (LANES TOP_LANES)
      (EXPR_WIDTH (+ OVERRIDE_WIDTH 1))
      (LANES_MASKED (and TOP_LANES TOP_LANE_MASK))
      (LANES_SUM (+ TOP_LANES TOP_LANE_INC))
      (LANES_INVERTED (~ TOP_LANES))
      (LANES_EQUAL (== TOP_LANES TOP_LANES))
      (LANES_DIFFER (!= TOP_LANES TOP_LANE_MASK))
    )
  )
  (?dtc:sink sink_src)
  (?wiring:wiring
    /payload_in/u_child.in_data/
    /u_child.out_data/sink.sink_in/
    /sink.sink_out/payload_out/
  )
)

(?fsm:child_src
  (+params
    (WIDTH 8)
    (LANES (8'h00 8'h00))
    (EXPR_WIDTH 4)
    (LANES_MASKED (8'h00 8'h00))
    (LANES_SUM (8'h00 8'h00))
    (LANES_INVERTED (8'h00 8'h00))
    (LANES_EQUAL 0)
    (LANES_DIFFER 0)
  )
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (in_data 16)
    (out_data 16)
  )
  (-idle
    (out_data> = LANES <in_data=WIDTH)
  )
)

(?dt:sink_src
  (+size
    (sink_in 16)
    (sink_out 16)
  )
  (-pass
    (sink_out> = sink_in)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $instance = $result->{composition_plan}->instances->[0];
    my $parameter_overrides = $instance->parameter_overrides;

    is($result->{composition_plan}->lane, 'C2', 'parameterized generated-child composition uses the generated-child C2 lane');
    is_deeply(
        [map { $_->{name} } @$parameter_overrides],
        [qw(WIDTH LANES EXPR_WIDTH LANES_MASKED LANES_SUM LANES_INVERTED LANES_EQUAL LANES_DIFFER)],
        'composition plan preserves generated-child parameter override order',
    );
    my %overrides = map { $_->{name} => $_ } @$parameter_overrides;
    is($overrides{WIDTH}{value_text}, '16', 'generated-child scalar override resolves top constant value');
    is($overrides{WIDTH}{raw_value}, 'OVERRIDE_WIDTH', 'generated-child scalar override preserves raw top constant token');
    is($overrides{WIDTH}{origin_kind}, 'generated_child_parameter_override', 'generated-child scalar override keeps generated-child provenance');
    is($overrides{LANES}{value_text}, "16'b1010010100111100", 'generated-child aggregate override resolves and packs top aggregate constant');
    is($overrides{LANES}{value_kind}, 'list', 'generated-child aggregate override keeps list kind');
    is($overrides{LANES}{value_width}, 16, 'generated-child aggregate override keeps packed width');
    is($overrides{EXPR_WIDTH}{value_text}, '(16 + 1)', 'generated-child scalar expression override resolves top constant value');
    is($overrides{EXPR_WIDTH}{value_kind}, 'scalar', 'generated-child scalar expression override stays scalar');
    is($overrides{LANES_MASKED}{value_text}, "16'b1010000000001100", 'generated-child aggregate bitwise expression override resolves top aggregate constants');
    is($overrides{LANES_MASKED}{value_kind}, 'list', 'generated-child aggregate bitwise expression override stays aggregate');
    is($overrides{LANES_SUM}{value_text}, "16'b1010011000111110", 'generated-child aggregate arithmetic expression override resolves top aggregate constants');
    is($overrides{LANES_SUM}{value_kind}, 'list', 'generated-child aggregate arithmetic expression override stays aggregate');
    is($overrides{LANES_INVERTED}{value_text}, "16'b0101101011000011", 'generated-child aggregate unary complement expression override resolves top aggregate constants');
    is($overrides{LANES_INVERTED}{value_kind}, 'list', 'generated-child aggregate unary complement expression override stays aggregate');
    is($overrides{LANES_EQUAL}{value_text}, "1'b1", 'generated-child aggregate equality expression override resolves top aggregate constants');
    is($overrides{LANES_EQUAL}{value_kind}, 'scalar', 'generated-child aggregate equality expression override folds to scalar');
    is($overrides{LANES_EQUAL}{value_width}, 1, 'generated-child aggregate equality expression override infers scalar width');
    is($overrides{LANES_DIFFER}{value_text}, "1'b1", 'generated-child aggregate inequality expression override resolves top aggregate constants');
    is($overrides{LANES_DIFFER}{value_kind}, 'scalar', 'generated-child aggregate inequality expression override folds to scalar');
    is($overrides{LANES_DIFFER}{value_width}, 1, 'generated-child aggregate inequality expression override infers scalar width');

    is_deeply(
        $result->{structural_rtl_ir}{instances}[0]{parameter_overrides},
        $parameter_overrides,
        'structural RTL IR preserves generated-child parameter override values for backend lowering',
    );
    is_deeply(
        $result->{intent_hir}{composition_children}[0]{parameter_overrides},
        $parameter_overrides,
        'intent HIR child export preserves generated-child parameter override values',
    );
    is(
        $result->{intent_hir}{composition_children}[0]{parameter_override_count},
        8,
        'intent HIR child export reports generated-child parameter override count',
    );

    my $hdl = $result->{hdl_code};
    like($hdl, qr/module\s+child_src\s*#\(\s*parameter\s+EXPR_WIDTH\s*=\s*4,\s*parameter\s+LANES\s*=\s*16'b0000000000000000,\s*parameter\s+LANES_DIFFER\s*=\s*0,\s*parameter\s+LANES_EQUAL\s*=\s*0,\s*parameter\s+LANES_INVERTED\s*=\s*16'b0000000000000000,\s*parameter\s+LANES_MASKED\s*=\s*16'b0000000000000000,\s*parameter\s+LANES_SUM\s*=\s*16'b0000000000000000,\s*parameter\s+WIDTH\s*=\s*8\s*\)/s, 'generated child module emits direct parameter declarations');
    like($hdl, qr/\bchild_src\s+#\(\s*\.WIDTH\(16\),\s*\.LANES\(16'b1010010100111100\),\s*\.EXPR_WIDTH\(\(16 \+ 1\)\),\s*\.LANES_MASKED\(16'b1010000000001100\),\s*\.LANES_SUM\(16'b1010011000111110\),\s*\.LANES_INVERTED\(16'b0101101011000011\),\s*\.LANES_EQUAL\(1'b1\),\s*\.LANES_DIFFER\(1'b1\)\s*\)\s+u_child\s*\(/s, 'generated top emits SV parameter overrides on the generated-child instance');
    like($hdl, qr/\bin_data\s*==\s*WIDTH\b/s, 'generated child internals keep scalar parameter reference in guard equality');
    like($hdl, qr/\bout_data\s*=\s*LANES\b/s, 'generated child internals keep aggregate parameter reference on RHS');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for parameterized generated-child composition');
    ok(-e $output_path, 'CLI writes HDL for parameterized generated-child composition');
};

subtest 'generated child parameter overrides must be declared by the child source' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'unknown_generated_child_parameter_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'unknown_generated_child_parameter_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:unknown_generated_child_parameter_top
  (?ports:public_io
    clk
    rstn
    payload_out>
  )
  (?dtc:u_child child_src
    (params
      (MODE 1)
    )
  )
  (?wiring:wiring
    /u_child.payload_out/payload_out/
  )
)

(?dt:child_src
  (+params
    (WIDTH 8)
  )
  (-drive
    (payload_out> = 1)
  )
)
FSM
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
    $exception = $@ if !$exception;

    like(
        $exception,
        qr/generated-child parameter\/generic override validation is blocked because override 'MODE' has no matching direct '\+params' declaration/s,
        'pipeline rejects generated-child overrides that are not declared by the child source',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );
    ok(!$success, 'CLI rejects undeclared generated-child parameter override');
    ok(!-e $output_path, 'CLI does not emit HDL when generated-child parameter override validation fails');
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []}, ($error_message || ''));
    like(
        $combined_output,
        qr/override 'MODE' has no matching direct '\+params' declaration/s,
        'CLI surfaces undeclared generated-child parameter override validation diagnostics',
    );
};

subtest 'generated child aggregate parameter overrides must match the child default shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'bad_aggregate_generated_child_parameter_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'bad_aggregate_generated_child_parameter_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:bad_aggregate_generated_child_parameter_top
  (?ports:public_io
    clk
    rstn
    payload_out>16
  )
  (?dtc:u_child child_src
    (params
      (LANES (8'hA5))
    )
  )
  (?wiring:wiring
    /u_child.payload_out/payload_out/
  )
)

(?dt:child_src
  (+params
    (LANES (8'h00 8'h00))
  )
  (-drive
    (payload_out> = LANES)
  )
)
FSM
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
    $exception = $@ if !$exception;

    like(
        $exception,
        qr/generated-child parameter\/generic override validation is blocked because override 'LANES' uses list<.*> while child source 'child_src' declares list<.*>.*Aggregate parameter\/generic overrides must match/s,
        'pipeline rejects generated-child aggregate parameter override shape mismatches',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );
    ok(!$success, 'CLI rejects aggregate generated-child parameter shape mismatches');
    ok(!-e $output_path, 'CLI does not emit HDL when aggregate generated-child parameter shape validation fails');
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []}, ($error_message || ''));
    like(
        $combined_output,
        qr/override 'LANES' uses list<.*> while child source 'child_src' declares list<.*>/s,
        'CLI surfaces aggregate generated-child parameter shape validation diagnostics',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
