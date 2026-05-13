#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

sub lower_source {
    my ($source) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'switch-clause-boundary.isf');
    return FSM::Scheduler::ISF->new()->lower($actor);
}

sub assert_lower_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        lower_source($source);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected during lowering");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

subtest 'valid switch clause lowers explicit and default branches' => sub {
    my $result = lower_source(<<'ISF');
(actor switch_boundary
  (clock clk)
  (interface
    (input start)
    (input mode)
    (output flag)
    (output done))
  (drive first
    (flag 1))
  (drive fallback
    (flag 0))
  (transaction main
    (on start)
    (switch mode
      (0 (drive first))
      (default (drive fallback)))
    (complete done)))
ISF

    my $fsm = $result->{files}{'switch_boundary.fsm'};
    like($fsm, qr/\(\?mode\s+.*?\(=0 \(-> main_drive_1\)\).*?\(default \(-> main_drive_2\)\)/s,
        'switch emits explicit and default branch selectors');
};

subtest 'malformed switch clauses fail before branch expansion' => sub {
    assert_lower_rejected(<<'ISF', 'missing switch signal', qr/\ATransaction 'main': switch requires '\(switch signal \(value body\.\.\.\)\.\.\.\)' in transaction body/);
(actor switch_missing_signal
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (switch)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'nested switch signal', qr/\ATransaction 'main': switch requires '\(switch signal \(value body\.\.\.\)\.\.\.\)' in transaction body/);
(actor switch_nested_signal
  (clock clk)
  (interface (input start) (input mode) (output done))
  (transaction main
    (on start)
    (switch (mode)
      (0 (complete done)))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'missing switch branch', qr/\ATransaction 'main': switch requires '\(switch signal \(value body\.\.\.\)\.\.\.\)' in transaction body/);
(actor switch_missing_branch
  (clock clk)
  (interface (input start) (input mode) (output done))
  (transaction main
    (on start)
    (switch mode)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'scalar switch branch', qr/\ATransaction 'main': switch branches require '\(value body\.\.\.\)' in transaction body/);
(actor switch_scalar_branch
  (clock clk)
  (interface (input start) (input mode) (output done))
  (transaction main
    (on start)
    (switch mode 0)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'nested switch value', qr/\ATransaction 'main': switch branches require '\(value body\.\.\.\)' in transaction body/);
(actor switch_nested_value
  (clock clk)
  (interface (input start) (input mode) (output done))
  (transaction main
    (on start)
    (switch mode
      ((0) (complete done)))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'scalar switch body', qr/\ATransaction 'main': switch branches require '\(value body\.\.\.\)' in transaction body/);
(actor switch_scalar_body
  (clock clk)
  (interface (input start) (input mode) (output done))
  (transaction main
    (on start)
    (switch mode
      (0 complete))
    (complete done)))
ISF
};

done_testing();
