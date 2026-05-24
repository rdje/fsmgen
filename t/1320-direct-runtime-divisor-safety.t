#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Adapter::FSMGenFull;

my $tempdir = tempdir(CLEANUP => 1);

sub parse_source {
    my ($source, $label) = @_;
    my $path = File::Spec->catfile($tempdir, "$label.fsm");
    write_file($path, $source);

    my $raw_ast = Lispish::multi($path);
    return FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm($raw_ast);
}

sub parse_failure {
    my ($source, $label) = @_;

    my $ok = eval {
        parse_source($source, $label);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    return $diagnostic;
}

subtest 'direct runtime division by literal zero fails closed' => sub {
    my $diagnostic = parse_failure(<<'FSM', 'direct_runtime_divide_literal_zero');
(?fsm:direct_runtime_divide_literal_zero
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (COND 1)
    (A 8)
    (OUT 8)
  )
  (idle
    (<COND
      (= (OUT (/ A 0)))
    )
  )
)
FSM

    like(
        $diagnostic,
        qr/Malformed expression operator '\/' uses literal zero divisor '0' in division/s,
        'division diagnostic names the literal-zero divisor',
    );
};

subtest 'direct runtime modulo by exact-width literal zero fails closed' => sub {
    my $diagnostic = parse_failure(<<'FSM', 'direct_runtime_modulo_exact_zero');
(?fsm:direct_runtime_modulo_exact_zero
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (COND 1)
    (A 8)
    (OUT 8)
  )
  (idle
    (<COND
      (= (OUT (mod A 8'd0)))
    )
  )
)
FSM

    like(
        $diagnostic,
        qr/Malformed expression operator 'mod' uses literal zero divisor '8'd0' in modulo/s,
        'modulo diagnostic preserves the authored alias and exact-width literal',
    );
};

subtest 'direct runtime chained division rejects later literal zero divisor' => sub {
    my $diagnostic = parse_failure(<<'FSM', 'direct_runtime_chained_divide_literal_zero');
(?fsm:direct_runtime_chained_divide_literal_zero
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (COND 1)
    (A 8)
    (B 8)
    (OUT 8)
  )
  (idle
    (<COND
      (= (OUT (/ A B 0)))
    )
  )
)
FSM

    like(
        $diagnostic,
        qr/Malformed expression operator '\/' uses literal zero divisor '0' in division/s,
        'n-ary division treats every operand after the first as a divisor',
    );
};

subtest 'nonzero literal and dynamic direct runtime divisors remain accepted' => sub {
    my $fsm_module = parse_source(<<'FSM', 'direct_runtime_safe_divisors');
(?fsm:direct_runtime_safe_divisors
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (COND 1)
    (A 8)
    (B 8)
    (Q 8)
    (R 8)
  )
  (idle
    (<COND
      (= (Q (/ A B)))
      (= (R (% A 8'd2)))
    )
  )
)
FSM

    ok($fsm_module, 'nonzero literal and dynamic divisors still parse');
    is($fsm_module->name, 'direct_runtime_safe_divisors', 'accepted module keeps its name');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
