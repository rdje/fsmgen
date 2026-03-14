#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Composition::Plan;

my $tempdir = tempdir(CLEANUP => 1);
my $success_path = File::Spec->catfile($tempdir, 'connect_by_name_top.fsm');
my $ambiguous_path = File::Spec->catfile($tempdir, 'connect_by_name_ambiguous_top.fsm');
my $unknown_path = File::Spec->catfile($tempdir, 'connect_by_name_unknown_top.fsm');
my $width_mismatch_path = File::Spec->catfile($tempdir, 'connect_by_name_width_mismatch_top.fsm');

write_file(
    $success_path,
    <<'FSM'
(?top:connect_by_name_top
  (?ports:public_io
    clk
    rstn
    =final_data>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.output_data/consumer.input_data/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'7)
  )
  (+size
    (output_data 8)
  )
)

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (final_data> <= input_data)
  )
  (+size
    (input_data 8)
    (final_data 8)
  )
)
FSM
);

write_file(
    $ambiguous_path,
    <<'FSM'
(?top:connect_by_name_ambiguous_top
  (?ports:public_io
    clk
    rstn
    =shared_status>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
)

(?fsm:left_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (shared_status> <= 8'1)
  )
  (+size
    (shared_status 8)
  )
)

(?fsm:right_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (shared_status> <= 8'2)
  )
  (+size
    (shared_status 8)
  )
)
FSM
);

write_file(
    $unknown_path,
    <<'FSM'
(?top:connect_by_name_unknown_top
  (?ports:public_io
    clk
    rstn
    =missing_port>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.output_data/consumer.input_data/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'1)
  )
  (+size
    (output_data 8)
  )
)

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (final_data> <= input_data)
  )
  (+size
    (input_data 8)
    (final_data 8)
  )
)
FSM
);

write_file(
    $width_mismatch_path,
    <<'FSM'
(?top:connect_by_name_width_mismatch_top
  (?ports:public_io
    clk
    rstn
    =final_data>4
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.output_data/consumer.input_data/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'1)
  )
  (+size
    (output_data 8)
  )
)

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (final_data> <= input_data)
  )
  (+size
    (input_data 8)
    (final_data 8)
  )
)
FSM
);

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
);

my $result = $pipeline->generate_hdl_from_file($success_path);

isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
is($result->{composition_plan}->lane, 'C4', 'declared connect-by-name planning records the C4 lane');
is(scalar(@{$result->{composition_plan}->links}), 2, 'typed plan preserves both the explicit and by-name-resolved links');

my %consumer_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};
is($consumer_bindings{final_data}, 'final_data', 'declared connect-by-name wires the unique child output directly to the same-named top output');

my $hdl = $result->{hdl_code};
like($hdl, qr/\.final_data\(final_data\)/s, 'generated top module emits the by-name resolved final_data wiring');
unlike($hdl, qr/comp_link_consumer_final_data/s, 'declared connect-by-name does not create a synthetic net when a same-named top output can be wired directly');

my $ambiguous_exception = eval {
    $pipeline->generate_hdl_from_file($ambiguous_path);
    undef;
};
$ambiguous_exception = $@;

like(
    $ambiguous_exception,
    qr/declared connect-by-name, .*resolves ambiguously to multiple compatible child endpoints: left\.shared_status, right\.shared_status/s,
    'declared connect-by-name rejects ambiguous same-name child matches',
);

my $unknown_exception = eval {
    $pipeline->generate_hdl_from_file($unknown_path);
    undef;
};
$unknown_exception = $@;

like(
    $unknown_exception,
    qr/declared connect-by-name, .*no realized child endpoint with that name exists/s,
    'declared connect-by-name rejects top ports with no same-name child endpoint',
);

my $width_mismatch_exception = eval {
    $pipeline->generate_hdl_from_file($width_mismatch_path);
    undef;
};
$width_mismatch_exception = $@;

like(
    $width_mismatch_exception,
    qr/top port 'final_data' has width 4 while child endpoint 'consumer\.final_data' has width 8/s,
    'declared connect-by-name rejects width mismatches with both endpoints and conflicting widths',
);
like(
    $width_mismatch_exception,
    qr/exact width agreement/s,
    'declared connect-by-name width-mismatch diagnostics keep the shared exact-width rule visible',
);

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
