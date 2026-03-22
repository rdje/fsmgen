#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'direct generated roots now surface a forward intent_hir summary' => sub {
    my $fsm_path = write_fsm('intent_hir_direct.fsm', <<'FSM');
(?fsm:intent_hir_direct
  (+system
    (clock clk)
    (asreset rstn)
  )
  (+size
    (IN 8)
    (OUT 8)
  )
  (IDLE
    (OUT> <= IN)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($fsm_path);
    my $intent_hir = $result->{intent_hir};

    is($intent_hir->{module_name}, 'intent_hir_direct', 'direct result exposes the module name through intent_hir');
    is($intent_hir->{source_root_kind}, 'fsm', 'direct result exposes the forward root kind through intent_hir');
    is($intent_hir->{regular_state_count}, 1, 'direct result exposes the regular-state count through intent_hir');
    is_deeply($intent_hir->{regular_state_names}, ['IDLE'], 'direct result exposes regular-state names through intent_hir');
    is($intent_hir->{standalone_dt_count}, 0, 'direct result keeps standalone dt count separate in intent_hir');
    is_deeply($intent_hir->{signal_names}, ['IN', 'OUT'], 'direct result exposes stable signal names through intent_hir');
    is($intent_hir->{system_contract}{clock}, 'clk', 'direct result exposes the effective system clock through intent_hir');
    is($intent_hir->{system_contract}{reset}, 'rstn', 'direct result exposes the effective system reset through intent_hir');
    ok($result->{module_info}{intent_hir}, 'module_info preserves the same serialized intent_hir summary');
    is_deeply(
        $result->{module_info}{intent_hir},
        $intent_hir,
        'module_info carries the same serialized forward intent_hir surface',
    );
};

subtest 'realized generated children preserve their forward intent_hir summary through composition' => sub {
    my $composition_path = write_fsm('intent_hir_child_top.fsm', <<'TOP');
(?top:intent_hir_child_top
  (?dtc:router route_src)
)

(?dt:route_src
  (+size
    (SEL 1)
    (A 8)
    (B 8)
    (OUT 8)
  )
  (-from_a
    (<SEL==1'b0
      (OUT = A)
    )
  )
  (-from_b
    (<SEL==1'b1
      (OUT = B)
    )
  )
)
TOP

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $child_info = $result->{composition_plan}->instances->[0]->module_info;
    my $intent_hir = $child_info->{intent_hir};

    is($intent_hir->{module_name}, 'route_src', 'realized child preserves the source module name in intent_hir');
    is($intent_hir->{source_root_kind}, 'dt', 'realized child preserves the dt root kind in intent_hir');
    is($intent_hir->{regular_state_count}, 0, 'realized dt child reports no regular FSM states in intent_hir');
    is($intent_hir->{standalone_dt_count}, 2, 'realized dt child reports standalone dt block count in intent_hir');
    is_deeply(
        $intent_hir->{standalone_dt_names},
        ['-from_a', '-from_b'],
        'realized dt child preserves standalone dt block names in intent_hir',
    );
    ok(!$intent_hir->{requires_implicit_system_ports}, 'purely combinational dt child keeps the non-system intent in intent_hir');
    is_deeply(
        $intent_hir->{standalone_dt_enable_families},
        [
            { dt_name => '-from_a', enable_signal => 'from_a_en' },
            { dt_name => '-from_b', enable_signal => 'from_b_en' },
        ],
        'realized dt child preserves standalone dt enable families in intent_hir',
    );
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
