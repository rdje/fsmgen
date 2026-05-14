#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;

sub parse_source {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, 'resource-priority-boundary.isf');
}

sub assert_parse_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        parse_source($source);
        1;
    };

    ok(!$ok, "$label is rejected by the parser");
    like($@, $diagnostic_re, "$label diagnostic is targeted");
}

subtest 'valid resource and priority metadata survives parsing' => sub {
    my $path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'full_featured.isf');
    my $actor = FSM::Adapter::ISF->new()->parse_file($path);

    is_deeply(
        $actor->{priorities},
        [['main_transfer', 'over', 'chained']],
        'actor-level priority shape is preserved',
    );
    is_deeply(
        $actor->{resources},
        [
            { name => 'shared_bus', arbiter => 'priority' },
            { name => 'mem_port',   arbiter => 'round_robin' },
        ],
        'resource metadata shape is preserved',
    );
};

subtest 'malformed resources are rejected before actor shell return' => sub {
    assert_parse_rejected(<<'ISF', 'malformed resource keyword', qr/resource entries require/);
(actor bad_resource_keyword
  (clock clk)
  (interface (input start) (output done))
  (transaction main (on start) (complete done))
  (resources
    (shared_bus (arbiter priority))))
ISF

    assert_parse_rejected(<<'ISF', 'unsupported resource arbiter', qr/resource 'shared_bus' arbiter requires/);
(actor bad_resource_arbiter
  (clock clk)
  (interface (input start) (output done))
  (transaction main (on start) (complete done))
  (resources
    (resource shared_bus (arbiter lottery))))
ISF

    assert_parse_rejected(<<'ISF', 'duplicate resource name', qr/duplicate resource 'shared_bus'/);
(actor duplicate_resource
  (clock clk)
  (interface (input start) (output done))
  (transaction main (on start) (complete done))
  (resources
    (resource shared_bus (arbiter priority))
    (resource shared_bus (arbiter round_robin))))
ISF
};

subtest 'malformed priorities are rejected before actor shell return' => sub {
    assert_parse_rejected(<<'ISF', 'actor priority without over', qr/\(priority \.\.\.\) requires/);
(actor bad_actor_priority
  (clock clk)
  (interface (input start) (output done))
  (transaction main (on start) (complete done))
  (priority main chained))
ISF

    assert_parse_rejected(<<'ISF', 'rule priority without target', qr/rule 'high_pri' priority requires/);
(actor bad_rule_priority
  (clock clk)
  (interface (input start) (output done))
  (transaction main (on start) (complete done))
  (rule high_pri start
    (priority over)
    (done 1)))
ISF
};

done_testing();
