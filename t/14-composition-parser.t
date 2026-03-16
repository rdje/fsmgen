#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Composition::Parser;
use FSM::Composition::Spec;
use FSM::Composition::Top;
use FSM::Composition::Instance;
use FSM::Composition::Port;
use FSM::Composition::Link;
use FSM::Composition::PortsBlock;
use FSM::Composition::TopLink;

my $parser = FSM::Composition::Parser->new;

my $trial_one_ast = Lispish::multi(File::Spec->catfile($FindBin::Bin, '..', 'fsm', 'trial_1.fsm'));
my $trial_one_spec = $parser->parse_source($trial_one_ast);

isa_ok($trial_one_spec, 'FSM::Composition::Spec');
isa_ok($trial_one_spec->top, 'FSM::Composition::Top');
is($trial_one_spec->top->name, 'mytest', 'parser preserves top name from legacy composition fixture');
is(scalar(@{$trial_one_spec->top->instances}), 1, 'legacy composition fixture yields one typed child instance');
isa_ok($trial_one_spec->top->instances->[0], 'FSM::Composition::Instance');
is($trial_one_spec->top->instances->[0]->kind, 'fsmc', 'typed child instance records fsmc kind');
is($trial_one_spec->top->instances->[0]->source_name, 'trial', 'typed child instance records the referenced FSM source name');
ok(
    exists $trial_one_spec->embedded_fsm_sources->{trial},
    'parser records embedded FSM roots alongside the typed composition top',
);
ok(
    !exists $trial_one_spec->embedded_dt_sources->{trial},
    'legacy composition fixture does not invent embedded DT roots',
);

my $tempdir = tempdir(CLEANUP => 1);
my $explicit_top_path = File::Spec->catfile($tempdir, 'typed_top.fsm');
write_file(
    $explicit_top_path,
    <<'FSM'
(?top:typed_top
  (?ports:public_io
    clk
    rstn
    =output_data>8
  )
  (?fsmc:child_ctrl child_ctrl_src)
  (?rtl:uart_tx
    clk
    rstn
    txd>
  )
  (?toplink:loopback_bus
    /child_ctrl.output_data/txd/
  )
)

(?fsm:child_ctrl_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data <= 1)
  )
  (+size
    (output_data 8)
  )
)
FSM
);

my $explicit_spec = $parser->parse_source(scalar Lispish::multi($explicit_top_path));

is($explicit_spec->top->name, 'typed_top', 'parser preserves explicit typed-top name');
is(scalar(@{$explicit_spec->top->ports_blocks}), 1, 'parser records one typed ports block');
isa_ok($explicit_spec->top->ports_blocks->[0], 'FSM::Composition::PortsBlock');
is($explicit_spec->top->ports_blocks->[0]->name, 'public_io', 'ports block preserves its declared name');
is(scalar(@{$explicit_spec->top->ports_blocks->[0]->ports}), 3, 'ports block materializes explicit port tokens as typed ports');
isa_ok($explicit_spec->top->ports_blocks->[0]->ports->[0], 'FSM::Composition::Port');
is($explicit_spec->top->ports_blocks->[0]->ports->[0]->name, 'clk', 'typed port preserves port name');
is($explicit_spec->top->ports_blocks->[0]->ports->[0]->direction, 'input', 'typed port defaults to input direction');
is($explicit_spec->top->ports_blocks->[0]->ports->[2]->direction, 'output', 'typed port preserves explicit output direction');
is($explicit_spec->top->ports_blocks->[0]->ports->[2]->width, 8, 'typed port preserves explicit width');
is($explicit_spec->top->ports_blocks->[0]->ports->[2]->binding_mode, 'connect_by_name', 'typed port preserves explicit connect-by-name declaration');
is(scalar(@{$explicit_spec->top->instances}), 2, 'parser records both fsmc and rtl child instances');
is($explicit_spec->top->instances->[0]->kind, 'fsmc', 'first typed child preserves fsmc kind');
is($explicit_spec->top->instances->[0]->name, 'child_ctrl', 'fsmc child preserves declared child name');
is($explicit_spec->top->instances->[0]->source_name, 'child_ctrl_src', 'fsmc child preserves source name');
is($explicit_spec->top->instances->[1]->kind, 'rtl', 'second typed child preserves rtl kind');
is($explicit_spec->top->instances->[1]->module_name, 'uart_tx', 'rtl child preserves module name');
is(scalar(@{$explicit_spec->top->toplinks}), 1, 'parser records one toplink block');
isa_ok($explicit_spec->top->toplinks->[0], 'FSM::Composition::TopLink');
is($explicit_spec->top->toplinks->[0]->name, 'loopback_bus', 'toplink block preserves its declared name');
is(scalar(@{$explicit_spec->top->toplinks->[0]->links}), 1, 'toplink block materializes simple link tokens as typed links');
isa_ok($explicit_spec->top->toplinks->[0]->links->[0], 'FSM::Composition::Link');
is($explicit_spec->top->toplinks->[0]->links->[0]->source, 'child_ctrl.output_data', 'typed link preserves dotted child source endpoints');
is($explicit_spec->top->toplinks->[0]->links->[0]->target, 'txd', 'typed link preserves target endpoint');

my $inline_port_error = eval {
    $parser->parse_source(
        scalar Lispish::single(\'(?top:inline_ports clk rstn (?ports))'),
    );
    undef;
};
$inline_port_error = $@;

like(
    $inline_port_error,
    qr/legacy inline top-port shorthand .* only supports explicit '\?ports' blocks/s,
    'parser rejects legacy inline top-port shorthand with an explicit modern-scope error',
);

my $multi_source_error = eval {
    $parser->parse_source(
        scalar Lispish::single(\'(?top:multi_source (?fsmc:combo a b))'),
    );
    undef;
};
$multi_source_error = $@;

like(
    $multi_source_error,
    qr/requires exactly one source name per '\?fsmc'/s,
    'parser rejects legacy multi-source fsmc children outside the first active R6 lane',
);

my $dt_child_path = File::Spec->catfile($tempdir, 'dt_child_top.fsm');
write_file(
    $dt_child_path,
    <<'FSM'
(?top:dt_child_top
  (?ports:io
    data_in<8
    result_data>8
  )
  (?dtc:router route_src)
)

(?dt:route_src
  (-route
    (result_data> = data_in)
  )
  (+size
    (data_in 8)
    (result_data 8)
  )
)
FSM
);
my $dt_child_spec = $parser->parse_source(scalar Lispish::multi($dt_child_path));

is($dt_child_spec->top->instances->[0]->kind, 'dtc', 'typed child instance records dtc kind');
is($dt_child_spec->top->instances->[0]->name, 'router', 'dtc child preserves declared child name');
is($dt_child_spec->top->instances->[0]->source_name, 'route_src', 'dtc child preserves source name');
ok(
    exists $dt_child_spec->embedded_dt_sources->{route_src},
    'parser records embedded DT roots alongside the typed composition top',
);

my $multi_dtc_source_error = eval {
    $parser->parse_source(
        scalar Lispish::single(\'(?top:multi_dt_source (?dtc:combo a b))'),
    );
    undef;
};
$multi_dtc_source_error = $@;

like(
    $multi_dtc_source_error,
    qr/requires exactly one source name per '\?dtc'/s,
    'parser rejects multi-source dtc children outside the active generated-child lane',
);

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
