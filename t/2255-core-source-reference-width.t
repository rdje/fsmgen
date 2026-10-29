use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr);
use Lispish;
use FSM::CoreAST;
use FSM::CoreExpressionWidthSupport;
use FSM::Adapter::FSMGenFull;

my $class = 'FSM::CoreExpressionWidthSupport';
my $json = JSON::PP->new->canonical;
sub width { $class->infer_width(@_) }
sub ref_signal { FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name => $_[0], width => $_[1])) }
sub binary { FSM::CoreAST::BinaryOp->new(@_) }

subtest 'an explicit source resolver distinguishes fallback unknown and exact reference width' => sub {
    my $ref = ref_signal('HELPER', 1);
    my $floor = ref_signal('INDEPENDENT', 16);
    $floor->signal->set_attribute('width_declared', 1);
    my $expr = binary('|', $ref, $floor);
    is(width($expr), 16, 'ordinary reference inference remains selected-width based');
    my @seen;
    is(width($expr, source_reference_width => sub {push @seen, refaddr($_[0]); undef}), 16,
        'explicit no-override preserves independent selected widths');
    is_deeply(\@seen, [refaddr($ref), refaddr($floor)], 'source callback receives actual ordered typed reference identities');
    ok(!defined(width($expr, source_reference_width => sub {
        return refaddr($_[0]) == refaddr($ref) ? {width => undef} : undef;
    })), 'explicit unresolved source helper cannot fall back to its nominal scalar');
    is(width($expr, source_reference_width => sub {
        return refaddr($_[0]) == refaddr($ref) ? {width => 32} : undef;
    }), 32, 'an explicitly resolved helper width participates in the ordinary max walk');
    for my $kind (32, '32') {
        is($json->encode(width($ref, source_reference_width => sub {{width => $kind}})), $json->encode($kind),
            'the explicit positive width retains numeric versus string kind');
    }
    is($ref->signal->width, 1, 'resolving width does not resize the source helper');
    is($floor->signal->width, 16, 'independent source floor stays unchanged');
    is(width($expr), 16, 'a previous explicit source call cannot change ordinary inference');
};

subtest 'malformed source resolutions withhold and exceptions remain explicit' => sub {
    my $ref = ref_signal('HELPER', 1);
    for my $bad ({}, {width => 0}, {width => -1}, {width => 'unknown'}, {width => []},
        {width => JSON::PP::true}, {width => 8, extra => 1}, [], 8, '8') {
        ok(!defined(width($ref, source_reference_width => sub {$bad})),
            'invalid source resolution never borrows the nominal width');
    }
    eval {width($ref, source_reference_width => sub {die "source contract refused\n"})};
    like($@, qr/source contract refused/, 'source callback error propagates');
    eval {width($ref, source_reference_width => 8)};
    like($@, qr/source_reference_width.*callback/, 'noncallback source option rejects');
    eval {width($ref, unknown_width_option => sub {8})};
    like($@, qr/optional/, 'unknown options still reject');
};

subtest 'explicit syntax scalar wrappers and unknown classes cannot borrow the reference resolver' => sub {
    my $ref = ref_signal('VECTOR', 64);
    my @independent = (
        [FSM::CoreAST::Literal->new('100000000', width => 9, radix => 'binary'), 9],
        [FSM::CoreAST::SignalRef->new($ref->signal, slice => [7, 4]), 4],
        [FSM::CoreAST::ParameterRef->new('P', width => 2), 2],
        [FSM::CoreAST::UnaryOp->new(operator => '!', operand => $ref), 1],
        [FSM::CoreAST::UnaryOp->new(operator => '^', operand => $ref), 1],
        [binary('==', $ref, FSM::CoreAST::Literal->new(0)), 1],
        [FSM::CoreAST::Expression->new(type => 'future'), undef],
    );
    for my $case (@independent) {
        my $calls = 0;
        is(width($case->[0], source_reference_width => sub {++$calls; {width => 128}}), $case->[1],
            'independent syntax or scalar result keeps its own width');
        is($calls, 0, 'reference callback is not applied outside actual whole references');
    }
    for my $value (256, '256') {
        my $literal = FSM::CoreAST::Literal->new($value, radix => 'decimal');
        my $before = $json->encode([$literal->value, $literal->width, $literal->radix, $ref->signal->width]);
        is(width(binary('|', $ref, $literal), source_reference_width => sub {{width => 9}},
            unsized_literal_width => sub {32}), 32, 'separate explicit reference and literal contracts compose');
        is($json->encode([$literal->value, $literal->width, $literal->radix, $ref->signal->width]), $before,
            'source data and raw literal kinds remain untouched');
    }
    my $dangling = FSM::CoreAST::SignalRef->new(undef);
    my $calls = 0;
    ok(!defined(width($dangling, source_reference_width => sub {++$calls; {width => 8}})), 'missing actual source cannot borrow a resolver');
    is($calls, 0, 'dangling reference never reaches the source callback');
};

subtest 'the canonical walk still bounds cycles depth and repeated source occurrences' => sub {
    my $ref = ref_signal('HELPER', 1);
    my $expr = $ref;
    $expr = binary('|', $expr, $ref) for 1 .. $class->MAX_DEPTH;
    is(width($expr, source_reference_width => sub {{width => 8}}), 8, 'existing depth boundary remains inclusive');
    $expr = binary('|', $expr, $ref);
    ok(!defined(width($expr, source_reference_width => sub {{width => 8}})), 'next depth cannot bypass the canonical budget');
    $expr = binary('|', $ref, $ref);
    $expr->{operands}[0] = $expr;
    ok(!defined(width($expr, source_reference_width => sub {{width => 8}})), 'active AST cycle stays unknown');
    $expr = $ref;
    $expr = binary('|', $expr, $expr) for 1 .. 12;
    my $calls = 0;
    ok(!defined(width($expr, source_reference_width => sub {++$calls; {width => 8}})), 'repeated occurrences consume the shared budget');
    ok($calls > 0 && $calls < $class->MAX_NODES, 'resolver work stays within actual visited reference occurrences');
    is(width($ref, source_reference_width => sub {{width => 8}}), 8, 'failed walks leave later source calls usable');
};

subtest 'actual completed literal intent distinguishes source unknown from selected helper width' => sub {
    for my $mutable (0, 1) {for my $bits (1, 8) {for my $sized (0, 1) {
        my $params = $mutable ? "(+params (W $bits))" : '';
        my $slot = $mutable ? '(param W)' : $bits;
        my $literal = $sized ? "9'b100000000" : '256';
        my $text = "(?fsm:source_reference $params (+size (A $slot) (B $slot) (DATA 1) (OTHER 1))"
            ." (idle (<(| A B $literal) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
        my $adapter = FSM::Adapter::FSMGenFull->new;
        $adapter->parse_fsm(scalar Lispish::multi(\$text));
        my ($helper) = grep {defined($_->source_literal_width_allocation)} values %{$adapter->{signal_manager}{signal_registry}};
        ok($helper, 'actual completed helper has the independently published literal contract');
        next unless $helper;
        my $outer = binary('^', FSM::CoreAST::SignalRef->new($helper), ref_signal('EXTERNAL', 8));
        my $resolve = sub {
            my ($reference) = @_;
            my $signal = $reference->signal;
            return undef unless $signal->get_attribute('is_intermediate');
            my $record = $signal->source_literal_width_allocation;
            return {width => $record ? $record->{selected_width} : undef};
        };
        is(width($outer), $sized ? 9 : 8, 'ordinary walk still reads selected helper widths without source expansion');
        is(width($outer, source_reference_width => $resolve), $sized ? 9 : undef,
            'explicit current source join preserves independent floor and nullable exact literal width');
        $adapter->{signal_manager}->register_signal($helper->name, width => $helper->width);
        ok(!defined(width($outer, source_reference_width => $resolve)), 'explicit source caller withholds revoked helpers rather than reclassifying a placeholder');
    }}}
};

done_testing();
