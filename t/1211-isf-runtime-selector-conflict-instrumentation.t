#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use Storable qw(dclone);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Backend::GeneratedModuleEmitter;
use FSM::Pipeline::HDLGenerator;
use FSM::Scheduler::ISF;

subtest 'same-value rule fan-in remains compatible without source exclusivity' => sub {
    my $result = generate_from_isf(
        'same_value_selector_probe',
        <<'ISF',
(actor same_value_selector_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (input b)
    (output done)
    (output valid))
  (transaction main
    (on start)
    (complete done))
  (rule r0 a
    (valid 1))
  (rule r1 b
    (valid 1)))
ISF
        'systemverilog',
    );

    my $valid_target = selector_target($result, 'valid');
    my ($one_family) = grep {
        ($_->{rhs_value} // '') eq '1'
    } @{$valid_target->{rhs_enable_families} || []};

    is_deeply(
        $one_family->{same_value_assertion},
        {
            kind => 'compatible_fanin',
            target_signal => 'valid',
            rhs_value => '1',
            input_count => 2,
            input_enable_signals => ['r0_valid_1_en', 'r1_valid_1_en'],
        },
        'legacy metadata key explicitly identifies compatible source fan-in',
    );
    unlike(
        $result->{hdl_code},
        qr/assert \(\$onehot0\(\{r0_valid_1_en, r1_valid_1_en\}\)\) else \$error\("selector same-value conflict: valid 1"\);/,
        'SystemVerilog does not forbid admitted same-value source overlap',
    );
    like(
        $result->{hdl_code},
        qr/assign valid_1_en = r0_valid_1_en \| r1_valid_1_en;/,
        'the actual value-family selector still ORs both source enables',
    );
    my $explicit = dclone($result->{module_info});
    my ($target) = grep {$_->{signal_name} eq 'valid'} @{$explicit->{selector_conflict_targets}};
    my ($family) = grep {$_->{rhs_value} eq '1'} @{$target->{rhs_enable_families}};
    $family->{same_value_assertion}{kind} = 'onehot0';
    my $lines = join "\n", FSM::Backend::GeneratedModuleEmitter->selector_conflict_assertion_runtime_lines(
        module_info => $explicit, target_language => 'systemverilog');
    like($lines, qr/\$onehot0\(\{r0_valid_1_en, r1_valid_1_en\}\)/,
        'an explicitly declared exclusive-source policy still emits its check');
    is($one_family->{same_value_assertion}{kind}, 'compatible_fanin',
        'the explicit-policy control does not mutate the actual producer contract');
};

subtest 'priority-resolved rule conflicts still emit whole-mux value selector assertions' => sub {
    my $result = generate_from_isf(
        'multi_value_selector_probe',
        <<'ISF',
(actor multi_value_selector_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (input b)
    (output done)
    (output valid))
  (priority high over low)
  (transaction main
    (on start)
    (complete done))
  (rule high a
    (valid 1))
  (rule low b
    (valid 0)))
ISF
        'systemverilog',
    );

    my $valid_target = selector_target($result, 'valid');
    is_deeply(
        $valid_target->{multi_value_assertion},
        {
            kind => 'onehot0',
            target_signal => 'valid',
            input_count => 2,
            input_enable_signals => ['valid_0_en', 'valid_1_en'],
        },
        'lowered metadata records the whole-mux selector assertion over value selectors',
    );
    like(
        $result->{hdl_code},
        qr/assert \(\$onehot0\(\{valid_0_en, valid_1_en\}\)\) else \$error\("selector multi-value conflict: valid"\);/,
        'SystemVerilog HDL emits the whole-mux multi-value selector assertion',
    );
    ok(
        selector_target($result, 'next_state'),
        'selector instrumentation is derived from all analyzed muxes, including generated state-transition muxes',
    );
};

subtest 'Verilog output stays free of SystemVerilog selector assertions' => sub {
    my $result = generate_from_isf(
        'selector_assertion_verilog_probe',
        <<'ISF',
(actor selector_assertion_verilog_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (input b)
    (output done)
    (output valid))
  (transaction main
    (on start)
    (complete done))
  (rule r0 a
    (valid 1))
  (rule r1 b
    (valid 1)))
ISF
        'verilog',
    );

    unlike($result->{hdl_code}, qr/\$onehot0/, 'Verilog HDL does not emit selector onehot0 assertions');
    unlike($result->{hdl_code}, qr/selector .* conflict/, 'Verilog HDL does not emit selector assertion error text');
};

done_testing();

sub generate_from_isf {
    my ($module_name, $source, $target_language) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($tempdir, "$module_name.isf");
    write_file($isf_path, $source);

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $scheduled_fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{"$module_name.fsm"};
    my $fsm_path = File::Spec->catfile($tempdir, "$module_name.fsm");
    write_file($fsm_path, $scheduled_fsm);

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => $target_language,
        debug_level => 0,
        quiet => 1,
    );
    return $pipeline->generate_hdl_from_file($fsm_path);
}

sub selector_target {
    my ($result, $signal_name) = @_;
    for my $target (@{$result->{module_info}{selector_conflict_targets} || []}) {
        next unless ref($target) eq 'HASH';
        return $target if ($target->{signal_name} || '') eq $signal_name;
    }
    return undef;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
