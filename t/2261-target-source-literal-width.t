use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(blessed refaddr weaken);
use Lispish;
use FSM::CoreAST;
use FSM::Adapter::FSMGenFull;
use FSM::CoreExpressionWidthSupport;

my $available = eval {require FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport; 1};
ok($available, 'target-owned completed source literal observation is available') or diag $@;
unless ($available) {done_testing(); exit}
my $class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport';
my $json = JSON::PP->new->canonical;
sub reference { FSM::CoreAST::SignalRef->new($_[0]) }
sub prepare { $class->prepare(signal => $_[0]) }
sub current { $class->current(signal => $_[0], observation => $_[1]) }
sub fixture {
    my (%args) = @_;
    my $bits = $args{bits} // 8;
    my $floor = $args{floor} // 16;
    my $slot = $args{mutable} ? '(param W)' : $bits;
    my $literal = $args{explicit} ? "9'b100000000" : '256';
    my $text = "(?fsm:target_literal (+params (W $bits)) (+size (A $slot) (B $floor) (DATA 1) (OTHER 1))"
        ." (idle (<(^ (| A $literal) B) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $raw = scalar Lispish::multi(\$text);
    my $before = $json->encode($raw);
    my $adapter = FSM::Adapter::FSMGenFull->new;
    $args{parser} ? $adapter->{parser}->parse_fsm($raw) : $adapter->parse_fsm($raw);
    my $registry = $adapter->{signal_manager}{signal_registry};
    my ($root) = grep {defined($_->source_literal_width_allocation) && $_->driving_ast->operator eq '^'} values %$registry;
    my ($child) = grep {defined($_->source_literal_width_allocation) && $_->driving_ast->operator eq '|'} values %$registry;
    return {adapter => $adapter, registry => $registry, root => $root, child => $child, raw => $raw, input => $before};
}
# Compare the complete raw object graph without following the pre-existing
# fanout cycles. The observation must leave every source field and JSON kind.
sub plain {
    my ($value) = @_;
    return $value if JSON::PP::is_bool($value);
    return [ref($value), sprintf('%x', refaddr($value))] if blessed($value);
    return [map {plain($_)} @$value] if ref($value) eq 'ARRAY';
    return {map {$_ => plain($value->{$_})} keys %$value} if ref($value) eq 'HASH';
    return $value;
}
sub snapshot {
    my ($f) = @_;
    my %objects;
    my @pending = values %{$f->{registry}};
    while (my $object = shift @pending) {
        my $id = sprintf('%x', refaddr($object));
        next if exists $objects{$id};
        $objects{$id} = plain({%$object});
        my @values = values %$object;
        while (@values) {
            my $value = shift @values;
            if (blessed($value) && !JSON::PP::is_bool($value)) {push @pending, $value}
            elsif (ref($value) eq 'ARRAY') {push @values, @$value}
            elsif (ref($value) eq 'HASH') {push @values, values %$value}
        }
    }
    return $json->encode(\%objects);
}

subtest 'actual completed fixed and mutable Parser and facade sources keep independent floors' => sub {
    for my $parser (0, 1) {for my $mutable (0, 1) {for my $bits (1, 8, 64) {for my $explicit (0, 1) {
        my $f = fixture(parser => $parser, mutable => $mutable, bits => $bits, explicit => $explicit);
        my $before = snapshot($f);
        my $observation = prepare($f->{root});
        ok($observation, 'actual completed source prepares') or next;
        my $literal_width = $explicit ? 9 : 32;
        my $expected = $bits > $literal_width ? $bits : $literal_width;
        $expected = 16 if $expected < 16;
        is($observation->{selected_width}, $expected, 'nested result retains the actual target literal and independent leaf maximum');
        is($observation->{literal_floor}, $literal_width, 'literal floor stays independent of the selected helper width');
        is($observation->{leaf_floor}, $bits > 16 ? $bits : 16, 'independent original leaf floor is retained separately');
        is_deeply([map {$_->{source}{name}} @{$observation->{leaves}}], ['A', 'B'], 'leaf membership excludes generated placeholder helpers');
        is_deeply($observation->{source_capsule}, $f->{root}{_source_literal_width_allocation}, 'complete original source capsule and raw kinds conserve');
        is_deeply($observation->{literals}[0]{literal}, {value => $explicit ? '100000000' : 256,
            width => $explicit ? 9 : undef, radix => $explicit ? 'binary' : 'decimal'}, 'raw source literal is never reformatted or coerced');
        is(scalar @{$observation->{reference_widths}}, 1, 'actual nested reference receives its own explicit resolution');
        is($observation->{reference_widths}[0]{width}, $bits > $literal_width ? $bits : $literal_width, 'child width is resolved before the parent');
        if ($mutable) {
            my $raw_leaf = $json->decode($observation->{leaves}[0]{source}{raw_state});
            is_deeply($raw_leaf->{fields}{_declared_width_binding}, $f->{registry}{A}{_declared_width_binding},
                'original independent mutable width relationship and default-one vector metadata retain');
        }
        is(snapshot($f), $before, 'every raw source object edge and JSON kind remains unchanged');
        is($json->encode($f->{raw}), $f->{input}, 'original complete parameter and caller input is unchanged');
        is_deeply(current($f->{root}, $observation), $observation, 'current source reproduces the detached observation');
        my $copy = $json->decode($json->encode($observation));
        $copy->{selected_width} = JSON::PP::true;
        ok(!defined current($f->{root}, $copy), 'Boolean selected width cannot impersonate the observation');
        $copy = $json->decode($json->encode($observation));
        $copy->{literal_floor} = $expected;
        ok(!defined current($f->{root}, $copy), 'selected maximum cannot replace an independent literal floor') if $expected != $literal_width;
        $observation->{literals}[0]{literal}{value} = 'changed';
        is_deeply(prepare($f->{root})->{literals}[0]{literal}, {value => $explicit ? '100000000' : 256,
            width => $explicit ? 9 : undef, radix => $explicit ? 'binary' : 'decimal'}, 'escaped observation data is detached');
    }}}}
};

subtest 'one source capture and raw literal scalar kinds remain explicit' => sub {
    my $f = fixture();
    my $capture = FSM::SourceLiteralWidthAllocationSupport->can('_capture');
    my $count = 0;
    {
        no warnings 'redefine';
        local *FSM::SourceLiteralWidthAllocationSupport::_capture = sub {++$count; $capture->(@_)};
        ok(prepare($f->{root}), 'complete nested source prepares with one capture');
    }
    is($count, 1, 'one globally bounded source capture serves all child inference');
    for my $value (256, '256') {
        $f = fixture();
        my $child = $f->{child};
        my $child_record = $child->source_literal_width_allocation;
        $child->driving_ast->right->{value} = $value;
        $child_record->{expression_tree}[2][1]{value} = $value;
        $child->set_source_literal_width_allocation($child_record);
        my $observation = prepare($child);
        ok($observation, 'fresh explicit source installation qualifies either raw value kind') or next;
        is($json->encode($observation->{literals}[0]{literal}{value}), $json->encode($value),
            'numeric versus string raw value kind conserves without literal interpretation');
    }
};

subtest 'source currentness and actual ownership are required even after matching changes' => sub {
    for my $change (
        sub {$_[0]{adapter}{signal_manager}->register_signal($_[0]{child}->name, width => $_[0]{child}->width)},
        sub {delete $_[0]{child}{_source_literal_width_allocation}},
        sub {$_[0]{adapter}{signal_manager}->register_signal('A', width => $_[0]{registry}{A}->width)},
        sub {$_[0]{root}{driving_ast}{operands}[0] = reference($_[0]{child})},
        sub {$_[0]{root}{_source_literal_width_allocation} = $_[1]{root}{_source_literal_width_allocation}},
        sub {push @{$_[0]{registry}{B}{constraints}}, {opaque => 1}},
    ) {
        my $f = fixture(mutable => 1);
        my $saved = prepare($f->{root});
        my $foreign = fixture(mutable => 1);
        $change->($f, $foreign);
        ok(!defined prepare($f->{root}), 'stale missing foreign or independently constrained source withholds');
        ok(!defined current($f->{root}, $saved), 'saved observation cannot authorize changed source');
    }
    my $f = fixture();
    my $wrapper = FSM::CoreAST::UnaryOp->new(operator => '!', operand => reference($f->{root}));
    is(FSM::CoreExpressionWidthSupport->infer_width($wrapper,
        source_reference_width => sub {{width => prepare($_[0]->signal)->{selected_width}}}), 1, 'scalar wrapper retains its own result width');
    ok(!defined prepare($f->{registry}{A}), 'an ordinary declared leaf cannot mint a literal helper observation');
};

subtest 'late source writes cannot escape the final whole-capture barrier' => sub {
    my $f = fixture();
    my $width = FSM::CoreAST::Signal->can('width');
    my $infer = FSM::CoreExpressionWidthSupport->can('infer_width');
    our $in_target = 0;
    my $fired = 0;
    no warnings 'redefine';
    local *FSM::CoreExpressionWidthSupport::infer_width = sub {
        my ($owner, $expr, %options) = @_;
        local $in_target = exists $options{unsized_literal_width};
        return $infer->(@_);
    };
    local *FSM::CoreAST::Signal::width = sub {
        my ($signal) = @_;
        if ($in_target && refaddr($signal) == refaddr($f->{registry}{B}) && !$fired++) {
            $f->{registry}{A}->set_attribute('is_output', 0);
        }
        return $width->(@_);
    };
    ok(!defined prepare($f->{root}), 'write to an earlier source during later target inference withholds');
    ok($fired, 'hostile write actually executes inside the target width walk');
};

subtest 'repeated typed edges and global expansion limits remain bounded' => sub {
    {
        my $levels = 3;
        my $adapter = FSM::Adapter::FSMGenFull->new;
        my $manager = $adapter->{signal_manager};
        my $builder = $adapter->{expression_builder};
        $manager->register_signal('A', width => 8);
        my $packet = $builder->_capture_intermediate_width_allocations(sub {
            my $root = $builder->parse_expression(['|', 'A', '256']);
            $root = $builder->finalize_nary_expression('^', [reference($root->signal), reference($root->signal)]) for 1 .. $levels;
            return $root;
        });
        $builder->_publish_intermediate_width_allocations($packet->{events}, $packet->{source_tree_events}, $packet->{source_literal_events});
        my $observation = prepare($packet->{value}->signal);
        {
            ok($observation, 'bounded repeated completed child occurrences prepare') or next;
            is($observation->{selected_width}, 32, 'repeated helper never borrows its placeholder width');
            is(scalar @{$observation->{literals}}, 8, 'all repeated literal occurrences conserve');
            is(scalar @{$observation->{leaves}}, 8, 'all original leaf occurrences conserve');
            my @root_edges = grep {$_->{parent_identity} eq $observation->{source_identity}} @{$observation->{reference_widths}};
            is(scalar @root_edges, 2, 'both actual parent reference slots retain membership');
            isnt($root_edges[0]{reference_identity}, $root_edges[1]{reference_identity}, 'repeated slots retain distinct typed identities');
            is($root_edges[0]{signal_identity}, $root_edges[1]{signal_identity}, 'shared helper retains one source lifetime');
            my $weak = $packet->{value}->signal; weaken($weak);
            $_->{fanout_signals} = [] for values %{$manager->{signal_registry}};
            undef $packet; undef $builder; undef $manager; undef $adapter;
            ok(!defined $weak, 'detached target observation adds no retained source owner graph');
            ok($json->encode($observation), 'observation remains JSON after source release');
        }
    }
    my $f = fixture();
    my $ast = $f->{child}->driving_ast;
    $ast = FSM::CoreAST::BinaryOp->new('|', $ast, $ast) for 1 .. 12;
    $f->{root}{driving_ast} = $ast;
    ok(!defined prepare($f->{root}), 'over-budget repeated actual AST expansion withholds boundedly');
    $f->{root}{driving_ast} = FSM::CoreAST::BinaryOp->new('|', reference($f->{root}), $f->{child}->driving_ast);
    ok(!defined prepare($f->{root}), 'actual source cycle withholds boundedly');
    ok(prepare(fixture()->{root}), 'bounded failure does not poison a fresh independent observation');
};

done_testing();
