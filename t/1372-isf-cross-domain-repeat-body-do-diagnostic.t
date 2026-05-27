#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

subtest 'cross-domain repeat-body do annotation emits targeted diagnostic' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor top_level_cross_domain_do_diag
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain aux (clock aux_clk) (reset aux_rst_n)))
  (interface
    (input start (domain core))
    (input loops (width 3) (domain core))
    (output done (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (repeat loops
      (do worker
        (domain aux))))
  (transaction worker
    (domain aux)
    (complete done)))
ISF
        qr/Transaction 'parent': repeat-body generated do target 'worker' is in a different clock domain than the calling transaction; cross-domain repeat-body do remains deferred/,
        'top-level repeat-body do with cross-domain target emits the targeted diagnostic',
    );

    assert_lower_rejected(
        <<'ISF',
(actor when_body_cross_domain_do_diag
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain aux (clock aux_clk) (reset aux_rst_n)))
  (interface
    (input start (domain core))
    (input cond (domain core))
    (input loops (width 3) (domain core))
    (output done (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (when cond
      (repeat loops
        (do worker
          (domain aux))))
    (complete done))
  (transaction worker
    (domain aux)
    (complete done)))
ISF
        qr/Transaction 'parent': when-body nested repeat generated do target 'worker' is in a different clock domain than the calling transaction; cross-domain repeat-body do remains deferred/,
        'when-body nested repeat do with cross-domain target emits the targeted diagnostic',
    );

    assert_lower_rejected(
        <<'ISF',
(actor switch_branch_cross_domain_do_diag
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain aux (clock aux_clk) (reset aux_rst_n)))
  (interface
    (input start (domain core))
    (input mode (domain core))
    (input loops (width 3) (domain core))
    (output done (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (switch mode
      (0
        (repeat loops
          (do worker
            (domain aux)))))
    (complete done))
  (transaction worker
    (domain aux)
    (complete done)))
ISF
        qr/Transaction 'parent': switch-branch nested repeat generated do target 'worker' is in a different clock domain than the calling transaction; cross-domain repeat-body do remains deferred/,
        'switch-branch nested repeat do with cross-domain target emits the targeted diagnostic',
    );
};

subtest 'same-domain repeat-body do without (params) still requires (params)' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor same_domain_no_params_still_rejected
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain aux (clock aux_clk) (reset aux_rst_n)))
  (interface
    (input start (domain core))
    (input loops (width 3) (domain core))
    (output done (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (repeat loops
      (do worker
        (domain core))))
  (transaction worker
    (domain core)
    (complete done)))
ISF
        qr/Transaction 'parent': repeat-body generated do domain metadata requires static '\(params \.\.\.\)' overrides in the current generated blocking-do subset/,
        'same-domain (domain ...) annotation without (params) still triggers the requires-(params) diagnostic',
    );
};

subtest 'cross-domain do without (domain) annotation still falls through to clock-domain violation' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor cross_domain_no_annotation_falls_through
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain aux (clock aux_clk) (reset aux_rst_n)))
  (interface
    (input start (domain core))
    (input loops (width 3) (domain core))
    (output done (domain core)))
  (transaction parent
    (domain core)
    (on start)
    (repeat loops
      (do worker)))
  (transaction worker
    (domain aux)
    (complete done)))
ISF
        qr/clock-domain violation: transaction 'parent' do target 'worker' references transaction in domain 'aux' from domain 'core' without a crossing primitive/,
        'cross-domain do without (domain) annotation still emits the generic clock-domain violation',
    );
};

done_testing();

sub parse_source {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source(
        $source,
        'cross-domain-repeat-body-do-diagnostic.isf',
    );
}

sub lower_source {
    my ($source) = @_;
    my $actor = parse_source($source);
    return FSM::Scheduler::ISF->new()->lower($actor);
}

sub assert_lower_rejected {
    my ($source, $pattern, $label) = @_;
    my $ok = eval {
        lower_source($source);
        1;
    };

    ok(!$ok, $label);
    like($@, $pattern, "$label diagnostic");
}
