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
my $multi_ports_blocks_path = File::Spec->catfile($tempdir, 'multi_ports_blocks_top.fsm');
my $missing_ports_path = File::Spec->catfile($tempdir, 'missing_ports_top.fsm');
my $empty_ports_path = File::Spec->catfile($tempdir, 'empty_ports_top.fsm');

write_file(
    $multi_ports_blocks_path,
    <<'FSM'
(?top:multi_ports_blocks_top
  (?ports:first
    clk
  )
  (?ports:second
    rstn
  )
  (?fsmc:child child_src)
)

(?fsm:child_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (OUT <= 1)
  )
  (+size
    (OUT 1)
  )
)
FSM
);

write_file(
    $missing_ports_path,
    <<'FSM'
(?top:missing_ports_top
  (?fsmc:left left_src)
  (?fsmc:right right_src)
)

(?fsm:left_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (OUT <= 1)
  )
  (+size
    (OUT 1)
  )
)

(?fsm:right_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (DONE <= 1)
  )
  (+size
    (DONE 1)
  )
)
FSM
);

write_file(
    $empty_ports_path,
    <<'FSM'
(?top:empty_ports_top
  (?ports)
  (?fsmc:left left_src)
  (?fsmc:right right_src)
)

(?fsm:left_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (OUT <= 1)
  )
  (+size
    (OUT 1)
  )
)

(?fsm:right_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (DONE <= 1)
  )
  (+size
    (DONE 1)
  )
)
FSM
);

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
);

subtest 'multiple ports blocks now say composition shape is blocked' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($multi_ports_blocks_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/recognized and parsed into typed composition IR, .*composition shape is blocked because the current active composition lanes require exactly one explicit '\?ports' block/s,
        'multiple ports blocks now say composition shape is blocked explicitly',
    );
};

subtest 'omitted ports outside inferable lanes now say composition shape is blocked' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($missing_ports_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/recognized and parsed into typed composition IR, .*composition shape is blocked because the current active composition lanes require exactly one explicit '\?ports' block/s,
        'omitted ports outside inferable lanes now say composition shape is blocked explicitly',
    );
};

subtest 'empty ports outside inferable lanes now say composition shape is blocked' => sub {
    my $exception = eval {
        $pipeline->generate_hdl_from_file($empty_ports_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/recognized and parsed into typed composition IR, .*composition shape is blocked because the current active composition lanes require '\?ports' to declare at least one explicit top port/s,
        'empty ports outside inferable lanes now say composition shape is blocked explicitly',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
