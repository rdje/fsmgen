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
  (?rtl:uart_tx)
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
ok(!defined($explicit_spec->top->instances->[1]->name), 'rtl shorthand leaves instance alias undefined before realization');
is($explicit_spec->top->instances->[1]->module_name, 'uart_tx', 'rtl child preserves module name');
is(scalar(@{$explicit_spec->top->toplinks}), 1, 'parser records one toplink block');
isa_ok($explicit_spec->top->toplinks->[0], 'FSM::Composition::TopLink');
is($explicit_spec->top->toplinks->[0]->name, 'loopback_bus', 'toplink block preserves its declared name');
is(scalar(@{$explicit_spec->top->toplinks->[0]->links}), 1, 'toplink block materializes simple link tokens as typed links');
isa_ok($explicit_spec->top->toplinks->[0]->links->[0], 'FSM::Composition::Link');
is($explicit_spec->top->toplinks->[0]->links->[0]->source, 'child_ctrl.output_data', 'typed link preserves dotted child source endpoints');
is($explicit_spec->top->toplinks->[0]->links->[0]->target, 'txd', 'typed link preserves target endpoint');

my $verbose_ports_spec = $parser->parse_source(
    scalar Lispish::single(\'(?top:verbose_ports_top
  (?ports:public_io
    (input clk)
    (input rst_n)
    (input data_in (width 8))
    (output result_data (width 8))
    (input enable :same-name)
    (output status (width 8) :connect-by-name)
    (input ack (same-name))
    (output ready (connect-by-name))
  )
  (?dtc:router route_src)
)'),
);

my @verbose_ports = @{$verbose_ports_spec->top->ports_blocks->[0]->ports};
is(scalar(@verbose_ports), 8, 'verbose ports block materializes every verbose port declaration');
is($verbose_ports[0]->name, 'clk', 'verbose input preserves the port name');
is($verbose_ports[0]->direction, 'input', 'verbose input normalizes to the input direction');
is($verbose_ports[0]->width, 1, 'verbose input without width defaults to one bit');
is($verbose_ports[2]->name, 'data_in', 'verbose input with width preserves the port name');
is($verbose_ports[2]->direction, 'input', 'verbose input with width normalizes to the input direction');
is($verbose_ports[2]->width, 8, 'verbose input with width resolves its numeric width');
is($verbose_ports[3]->name, 'result_data', 'verbose output with width preserves the port name');
is($verbose_ports[3]->direction, 'output', 'verbose output normalizes to the output direction');
is($verbose_ports[3]->width, 8, 'verbose output with width resolves its numeric width');
is($verbose_ports[3]->binding_mode, 'explicit', 'verbose ports are explicit top ports');
is($verbose_ports[3]->raw_token, '(output result_data (width 8))', 'verbose port keeps a readable raw token');
is($verbose_ports[4]->name, 'enable', 'verbose same-name input preserves the port name');
is($verbose_ports[4]->direction, 'input', 'verbose same-name input normalizes to the input direction');
is($verbose_ports[4]->binding_mode, 'connect_by_name', 'verbose same-name input requests connect-by-name binding');
is($verbose_ports[4]->origin_kind, 'declared_connect_by_name_port', 'verbose same-name input keeps the declared by-name origin');
is($verbose_ports[5]->name, 'status', 'verbose connect-by-name alias output preserves the port name');
is($verbose_ports[5]->direction, 'output', 'verbose connect-by-name alias normalizes to the output direction');
is($verbose_ports[5]->width, 8, 'verbose connect-by-name alias output resolves its numeric width');
is($verbose_ports[5]->binding_mode, 'connect_by_name', 'verbose connect-by-name alias requests connect-by-name binding');
is($verbose_ports[6]->name, 'ack', 'parenthesized verbose same-name input preserves the port name');
is($verbose_ports[6]->binding_mode, 'connect_by_name', 'parenthesized verbose same-name input requests connect-by-name binding');
is($verbose_ports[7]->name, 'ready', 'parenthesized verbose connect-by-name output preserves the port name');
is($verbose_ports[7]->binding_mode, 'connect_by_name', 'parenthesized verbose connect-by-name output requests connect-by-name binding');

my $bad_verbose_keyword_error = eval {
    $parser->parse_source(
        scalar Lispish::single(\'(?top:bad_verbose_keyword (?ports:public_io (inout bus)))'),
    );
    undef;
};
$bad_verbose_keyword_error = $@;

like(
    $bad_verbose_keyword_error,
    qr/verbose declaration '\(inout bus\)'.*must start with the literal keyword 'input' or 'output'/s,
    'parser rejects unsupported verbose port direction keywords with a targeted error',
);

my $bad_verbose_width_error = eval {
    $parser->parse_source(
        scalar Lispish::single(\'(?top:bad_verbose_width (?ports:public_io (output bus (width))))'),
    );
    undef;
};
$bad_verbose_width_error = $@;

like(
    $bad_verbose_width_error,
    qr/verbose declaration '\(output bus \(width\)\)'.*'\(width TOKEN\)' must contain exactly one scalar width token/s,
    'parser rejects verbose width attributes without a scalar token',
);

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
    qr/contains '\?fsmc' child 'combo' with 2 FSM source names, .*composition child source count is blocked because the active composition parser currently requires exactly one FSM source name per '\?fsmc'/s,
    'parser now says multi-source fsmc children block composition child source count',
);

my $nested_fsm_source_error = eval {
    $parser->parse_source(
        scalar Lispish::single(\'(?top:nested_fsm_source (?fsmc:combo (opt a)))'),
    );
    undef;
};
$nested_fsm_source_error = $@;

like(
    $nested_fsm_source_error,
    qr/contains '\?fsmc' child 'combo' with unsupported nested block 'opt', .*composition generated-child source shape is blocked because nested '\?fsmc' payloads currently accept only '\(params \(NAME value\) \.\.\.\)' semantic blocks/s,
    'parser now says unsupported nested fsmc payloads block generated-child source shape',
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

my $parameterized_generated_spec = $parser->parse_source(
    scalar Lispish::multi(\<<'FSM'),
(?top:parameterized_generated_top
  (?fsmc:u_ctrl ctrl_src
    (params
      (WIDTH 16)
      (LANES (8'hA5 8'h3C))
    )
  )
  (?dtc:router
    (params
      (MODE 1)
    )
  )
)
FSM
);

is(scalar(@{$parameterized_generated_spec->top->instances}), 2, 'parser records parameterized generated children');
is($parameterized_generated_spec->top->instances->[0]->kind, 'fsmc', 'parameterized fsmc child preserves kind');
is($parameterized_generated_spec->top->instances->[0]->name, 'u_ctrl', 'parameterized fsmc child preserves instance name');
is($parameterized_generated_spec->top->instances->[0]->source_name, 'ctrl_src', 'parameterized fsmc child preserves source name');
is_deeply(
    [map { $_->{name} } @{$parameterized_generated_spec->top->instances->[0]->parameter_overrides}],
    [qw(WIDTH LANES)],
    'parser preserves generated fsmc parameter override order',
);
is($parameterized_generated_spec->top->instances->[0]->parameter_overrides->[0]{origin_kind}, 'generated_child_parameter_override', 'parser marks fsmc overrides as generated-child overrides');
is($parameterized_generated_spec->top->instances->[0]->parameter_overrides->[1]{value_kind}, 'list', 'parser preserves aggregate generated-child parameter override kind');
is($parameterized_generated_spec->top->instances->[1]->kind, 'dtc', 'parameterized dtc child preserves kind');
is($parameterized_generated_spec->top->instances->[1]->name, 'router', 'parameterized dtc child preserves instance name');
is($parameterized_generated_spec->top->instances->[1]->source_name, 'router', 'parameterized named dtc child defaults source name even with params block');
is_deeply(
    [map { $_->{name} } @{$parameterized_generated_spec->top->instances->[1]->parameter_overrides}],
    ['MODE'],
    'parser preserves generated dtc parameter overrides with defaulted source name',
);

my $symbol_top_spec = $parser->parse_source(
    scalar Lispish::single(\'(?top:symbol_top
  (+constants
    (RESET_BYTE 8\'165)
    (IDLE_MASK const_4b0)
  )
  (+enums
    (mode
      (IDLE 0)
      (BUSY 1)
    )
  )
  (?ports:public_io
    status_out>
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /=mode.BUSY/status_out/
  )
)'),
);

is($symbol_top_spec->top->name, 'symbol_top', 'parser preserves composition top name when symbol sections are present');
is_deeply(
    $symbol_top_spec->top->top_symbols->summary,
    {
        constants => 2,
        enums => 1,
        types => 0,
    },
    'parser records composition-root +constants and +enums as typed top symbols',
);
is(
    $symbol_top_spec->top->top_symbols->resolve_actual_payload('RESET_BYTE'),
    "8'd165",
    'top symbols canonicalize composition-root constants onto the structural-actual literal family',
);
is(
    $symbol_top_spec->top->top_symbols->resolve_actual_payload('IDLE_MASK'),
    "4'b0",
    'top symbols preserve const_8b-style binary constants as canonical literal payloads',
);
is(
    $symbol_top_spec->top->top_symbols->resolve_actual_payload('mode.BUSY'),
    '1',
    'top symbols resolve enum members onto canonical literal payloads',
);

my $aliased_rtl_spec = $parser->parse_source(
    scalar Lispish::single(\'(?top:aliased_rtl_parse
  (?rtl:u_uart_a uart_tx)
)'),
);

is(scalar(@{$aliased_rtl_spec->top->instances}), 1, 'parser records one aliased rtl child instance');
is($aliased_rtl_spec->top->instances->[0]->kind, 'rtl', 'aliased rtl child preserves rtl kind');
is($aliased_rtl_spec->top->instances->[0]->name, 'u_uart_a', 'aliased rtl child preserves explicit instance name');
is($aliased_rtl_spec->top->instances->[0]->module_name, 'uart_tx', 'aliased rtl child preserves source module/interface name');

my $aggregate_symbol_top_spec = $parser->parse_source(
    scalar Lispish::single(\'(?top:aggregate_symbol_top
  (+constants
    (BYTES (8\'165 8\'60 0))
    (FRAME ((mode 3) (flag 1)))
    (NEST ((header ((nibble 4\'10))) (tail (1 0))))
  )
  (?ports:public_io
    status_out>
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /=FRAME.flag/status_out/
  )
)'),
);

is_deeply(
    $aggregate_symbol_top_spec->top->top_symbols->summary,
    {
        constants => 3,
        enums => 0,
        types => 0,
    },
    'parser records composition-root aggregate +constants as typed top symbols too',
);
is(
    $aggregate_symbol_top_spec->top->top_symbols->resolve_actual_payload('BYTES[1]'),
    "8'd60",
    'top symbols resolve composition-root aggregate list leaves onto canonical literal payloads',
);
is(
    $aggregate_symbol_top_spec->top->top_symbols->resolve_actual_payload('FRAME.flag'),
    '1',
    'top symbols resolve composition-root aggregate hash leaves onto canonical literal payloads',
);
is(
    $aggregate_symbol_top_spec->top->top_symbols->resolve_actual_payload('NEST.header.nibble'),
    "4'd10",
    'top symbols resolve nested composition-root aggregate leaves onto canonical literal payloads',
);
ok(
    !defined($aggregate_symbol_top_spec->top->top_symbols->resolve_actual_payload('FRAME')),
    'top symbols keep unresolved composition-root aggregate roots off the scalar payload path',
);

my $package_top_spec = $parser->parse_source(
    scalar Lispish::multi(\<<'FSM'),
(?top:package_top
  (+import shared_local shared_external)
  (?ports:public_io
    status_out>
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /=shared_local.mode.BUSY/status_out/
  )
)

(?pkg:shared_local
  (+constants
    (RESET_BYTE 8'hA5)
  )
  (+enums
    (mode
      (IDLE 0)
      (BUSY 1)
    )
  )
)
FSM
);

is_deeply(
    $package_top_spec->top->package_imports,
    ['shared_local', 'shared_external'],
    'parser preserves explicit package imports on the typed composition top',
);
ok(
    exists $package_top_spec->embedded_package_sources->{shared_local},
    'parser records embedded package roots alongside the typed composition top',
);
ok(
    !exists $package_top_spec->embedded_package_sources->{shared_external},
    'parser does not invent missing embedded package roots',
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
    qr/contains '\?dtc' child 'combo' with 2 standalone-DT source names, .*composition child source count is blocked because the active composition parser currently requires exactly one standalone-DT source name per '\?dtc'/s,
    'parser now says multi-source dtc children block composition child source count',
);

my $nested_dtc_source_error = eval {
    $parser->parse_source(
        scalar Lispish::single(\'(?top:nested_dt_source (?dtc:combo (opt a)))'),
    );
    undef;
};
$nested_dtc_source_error = $@;

like(
    $nested_dtc_source_error,
    qr/contains '\?dtc' child 'combo' with unsupported nested block 'opt', .*composition generated-child source shape is blocked because nested '\?dtc' payloads currently accept only '\(params \(NAME value\) \.\.\.\)' semantic blocks/s,
    'parser now says unsupported nested dtc payloads block generated-child source shape',
);

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
