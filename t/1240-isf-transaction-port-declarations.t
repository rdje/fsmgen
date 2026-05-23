#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

sub parse_source {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, 'transaction-port-declarations.isf');
}

sub assert_parse_rejected {
    my ($source, $label, $diagnostic_re) = @_;
    my $ok = eval {
        parse_source($source);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected by parser");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

subtest 'transaction ports parse into the public actor shell' => sub {
    my $actor = parse_source(<<'ISF');
(actor port_decl
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction main
    (ports
      (input addr (width 32))
      (input wr_en)
      (output data (width 8)))
    (on start)
    (complete done)))
ISF

    my ($main) = @{$actor->{transactions}};
    is($main->{name}, 'main', 'transaction name is preserved');
    is_deeply(
        $main->{ports},
        {
            inputs => [
                { name => 'addr', width => 32 },
                { name => 'wr_en', width => 1 },
            ],
            outputs => [
                { name => 'data', width => 8 },
            ],
        },
        'transaction ports are grouped by direction with default width 1',
    );
    is_deeply(
        [map { ref($_) eq 'ARRAY' ? $_->[0] : $_ } @{$main->{clauses}}],
        [qw(on complete)],
        'ports declaration is not forwarded as a scheduler body clause',
    );
};

subtest 'transactions without ports keep an empty ports shell' => sub {
    my $actor = parse_source(<<'ISF');
(actor no_ports
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)))
ISF

    is_deeply(
        $actor->{transactions}[0]{ports},
        { inputs => [], outputs => [] },
        'transactions without a ports clause still expose an empty ports shell',
    );
};

subtest 'port declarations are parser-only until binding/lowering ships' => sub {
    my $actor = parse_source(<<'ISF');
(actor port_decl_lowering
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction main
    (ports
      (input addr (width 32))
      (output data (width 32)))
    (on start)
    (complete done)))
ISF

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    like(
        $lowered->{files}{'port_decl_lowering.fsm'},
        qr/\(\?fsm:port_decl_lowering\b/,
        'scheduler still lowers transactions that only declare ports',
    );
};

subtest 'malformed transaction ports fail closed at parse time' => sub {
    assert_parse_rejected(<<'ISF', 'duplicate ports clause', qr/\AError: transaction 'main' accepts only one '\(ports \.\.\.\)' clause/);
(actor dup_ports
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (ports (input addr))
    (ports (output data))
    (on start)
    (complete done)))
ISF

    assert_parse_rejected(<<'ISF', 'bad direction', qr/\AError: transaction 'main' port direction must be input or output/);
(actor bad_dir
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (ports (inout data))
    (on start)
    (complete done)))
ISF

    assert_parse_rejected(<<'ISF', 'nested name', qr/\AError: transaction 'main' port requires a scalar HDL identifier name/);
(actor nested_name
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (ports (input (addr)))
    (on start)
    (complete done)))
ISF

    assert_parse_rejected(<<'ISF', 'duplicate name', qr/\AError: transaction 'main' has duplicate port 'addr'/);
(actor dup_name
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (ports (input addr) (output addr))
    (on start)
    (complete done)))
ISF

    assert_parse_rejected(<<'ISF', 'bad width', qr/\AError: transaction 'main' port 'addr' width requires '\(width positive_integer_or_actor_scalar_parameter\)'/);
(actor bad_width
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (ports (input addr (width 0)))
    (on start)
    (complete done)))
ISF

    assert_parse_rejected(<<'ISF', 'unsupported option', qr/\AError: transaction 'main' port 'addr' has unsupported option 'reset'/);
(actor bad_option
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (ports (input addr (reset 0)))
    (on start)
    (complete done)))
ISF
};

done_testing();
