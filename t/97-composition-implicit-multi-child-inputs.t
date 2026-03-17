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
use FSM::Composition::Plan;

my $tempdir = tempdir(CLEANUP => 1);
my $success_path = File::Spec->catfile($tempdir, 'implicit_multi_child_inputs_top.fsm');
my $success_out_path = File::Spec->catfile($tempdir, 'implicit_multi_child_inputs_top.sv');
my $width_mismatch_path = File::Spec->catfile($tempdir, 'implicit_multi_child_input_width_mismatch_top.fsm');

write_file(
    $success_path,
    <<'FSM'
(?top:implicit_multi_child_inputs_top
  (?ports:public_io
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.output_data/consumer.input_data/
    /consumer.final_data/result_data/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (<shared_in
      (output_data> <= 8'1)
    )
  )
  (+size
    (shared_in 1)
    (output_data 8)
  )
)

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (<shared_in
      (final_data> <= input_data)
    )
  )
  (+size
    (shared_in 1)
    (input_data 8)
    (final_data 8)
  )
)
FSM
);

write_file(
    $width_mismatch_path,
    <<'FSM'
(?top:implicit_multi_child_input_width_mismatch_top
  (?ports:public_io
    result_data>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?toplink:wiring
    /left.output_data/result_data/
  )
)

(?fsm:left_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (<shared_cfg
      (output_data> <= 8'1)
    )
  )
  (+size
    (shared_cfg 8)
    (output_data 8)
  )
)

(?fsm:right_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (<shared_cfg
      (spare_out> <= 1)
    )
  )
  (+size
    (shared_cfg 4)
    (spare_out 1)
  )
)
FSM
);

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
);

subtest 'explicit-link multi-child tops infer undeclared shared top inputs' => sub {
    my $result = $pipeline->generate_hdl_from_file($success_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C2', 'multi-child inferred-input success stays in explicit-link C2');

    my %ports = map { $_->name => $_ } @{$result->{composition_plan}->ports};
    ok($ports{clk}, 'clk is inferred as a top input');
    ok($ports{rstn}, 'rstn is inferred as a top input');
    ok($ports{shared_in}, 'shared_in is inferred as a shared top input');
    ok($ports{result_data}, 'explicit top output remains present');
    is($ports{shared_in}->direction, 'input', 'inferred shared input keeps input direction');
    is($ports{shared_in}->width, 1, 'inferred shared input keeps width');
    is($ports{result_data}->direction, 'output', 'explicit top output keeps output direction');

    my %instance_bindings;
    for my $instance (@{$result->{composition_plan}->instances}) {
        $instance_bindings{$instance->instance_name} = {
            map { $_->{port_name} => $_->{signal_name} } @{$instance->port_bindings || []}
        };
    }

    is($instance_bindings{producer}{shared_in}, 'shared_in', 'producer shared input binds to inferred top input');
    is($instance_bindings{consumer}{shared_in}, 'shared_in', 'consumer shared input binds to inferred top input');
    is($instance_bindings{consumer}{input_data}, 'comp_link_producer_output_data', 'explicit child-to-child data link still uses a deterministic carrier');
    is($instance_bindings{consumer}{final_data}, 'result_data', 'explicit top output link still binds directly');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\binput\s+clk\b/s, 'generated HDL exposes inferred clk input');
    like($hdl, qr/\binput\s+rstn\b/s, 'generated HDL exposes inferred rstn input');
    like($hdl, qr/\binput\s+shared_in\b/s, 'generated HDL exposes inferred shared input');
    like($hdl, qr/\boutput\s+\[7:0\]\s+result_data\b/s, 'generated HDL still exposes explicit result output');
    like($hdl, qr/\.shared_in\(shared_in\)/s, 'generated HDL fans inferred shared input into matching child inputs');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $success_out_path, '--quiet', $success_path],
    );
    ok($success, 'CLI succeeds for explicit-link multi-child tops with inferred undeclared shared inputs');
    ok(-e $success_out_path, 'CLI writes HDL output for inferred undeclared shared inputs');
};

subtest 'undeclared shared top-input inference rejects width disagreement' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($width_mismatch_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/omits top port 'shared_cfg', .*undeclared top-input inference cannot choose a width because same-name child inputs disagree.*left\.shared_cfg\[input, width=8\].*right\.shared_cfg\[input, width=4\]/s,
        'undeclared shared top-input inference rejects same-name child inputs with mismatched widths',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
