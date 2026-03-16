#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Pipeline::HDLGenerator;
use FSM::SourceClassifier;

my $tempdir = tempdir(CLEANUP => 1);

subtest '?dt root with combinational DT blocks generates without implicit system ports' => sub {
    my $dt_path = write_fsm('comb_dt_root.fsm', <<'DT');
(?dt:comb_dt_root
  (+size
    (DATA_IN 8)
    (DATA_OUT 8)
    (ZERO_FLAG 1)
  )
  (-route_data
    (DATA_OUT = DATA_IN)
  )
  (-flag_zero
    (<DATA_IN==8'0
      (ZERO_FLAG = 1)
    )
  )
)
DT

    my $raw_ast = Lispish::multi($dt_path);
    my $source_info = FSM::SourceClassifier::classify_source_ast($raw_ast);
    is($source_info->{kind}, 'dt', '?dt root is classified as a dt source');
    is($source_info->{header}, '?dt:comb_dt_root', 'classifier preserves the dt header');

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($dt_path);

    is($result->{source_info}{kind}, 'dt', 'pipeline preserves dt source kind');
    is($result->{fsm_module}->source_root_kind, 'dt', 'parsed module keeps dt root kind');
    ok(!$result->{fsm_module}->requires_implicit_system_ports, 'purely combinational dt root does not require implicit system ports');
    ok(!$result->{module_info}->{system_contract}->{declare_ports}, 'module info marks combinational dt root as system-port free');
    is($result->{module_info}->{state_count}, 0, 'standalone dt root does not add regular FSM states');

    my @state_types = map { $_->state_type } @{$result->{fsm_module}->states || []};
    is_deeply(\@state_types, ['standalone_dt', 'standalone_dt'], 'all top-level dt blocks stay standalone');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/module\s+comb_dt_root\b/s, 'dt root still generates a module');
    unlike($hdl, qr/\binput\s+wire\s+clk\b/s, 'combinational dt root does not expose clk');
    unlike($hdl, qr/\binput\s+wire\s+rst_n\b/s, 'combinational dt root does not expose rst_n');
    unlike($hdl, qr/\bcurrent_state\b/s, 'combinational dt root does not synthesize current_state');
    like($hdl, qr/\binput\s+wire\s+\[7:0\]\s+DATA_IN\b/s, 'ordinary data inputs remain visible');
    like($hdl, qr/\boutput\s+reg\s+\[7:0\]\s+DATA_OUT\b/s, 'driven outputs remain visible');
    like($hdl, qr/\boutput\s+reg\s+ZERO_FLAG\b/s, 'single-bit driven outputs also become module outputs');
};

subtest '?dt root with sequential assignments implicitly exposes clk and rst_n' => sub {
    my $dt_path = write_fsm('seq_dt_root.fsm', <<'DT');
(?dt:seq_dt_root
  (+size
    (ACC 8)
    (DATA_IN 8)
  )
  (:= ACC=8'0)
  (-accumulate
    (ACC <- DATA_IN)
  )
)
DT

    my $raw_ast = Lispish::multi($dt_path);
    my $source_info = FSM::SourceClassifier::classify_source_ast($raw_ast);
    is($source_info->{kind}, 'dt', 'sequential ?dt root is classified as a dt source');

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($dt_path);

    is($result->{fsm_module}->source_root_kind, 'dt', 'sequential dt root keeps dt source kind');
    ok($result->{fsm_module}->requires_implicit_system_ports, 'sequential dt root requires implicit system ports');
    is($result->{module_info}->{system_contract}->{clock}, 'clk', 'sequential dt root uses clk by default');
    is($result->{module_info}->{system_contract}->{reset}, 'rst_n', 'sequential dt root uses rst_n by default');
    ok($result->{module_info}->{system_contract}->{declare_ports}, 'module info exposes implicit system ports for sequential dt roots');
    is($result->{module_info}->{state_count}, 0, 'sequential dt root still has no regular FSM states');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\binput\s+wire\s+clk\b/s, 'sequential dt root exposes clk');
    like($hdl, qr/\binput\s+wire\s+rst_n\b/s, 'sequential dt root exposes rst_n');
    like($hdl, qr/\boutput\s+reg\s+\[7:0\]\s+ACC\b/s, 'sequentially-driven targets become module outputs');
    unlike($hdl, qr/\bcurrent_state\b/s, 'sequential dt root still does not synthesize current_state');
    like($hdl, qr/always_ff\s*@\(posedge\s+clk\s+or\s+negedge\s+rst_n\)/s, 'sequential dt root uses implicit clk/rst_n in emitted sequential logic');
};

done_testing();

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}
