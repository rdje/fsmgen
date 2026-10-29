use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use FSM::CoreAST;
use FSM::Adapter::FSMGenFull::SignalManager;

my $available = eval {require FSM::SourceLiteralWidthAllocationSupport; 1};
ok($available, 'source literal allocation holder is available') or diag $@;
unless ($available) {done_testing(); exit}
my $class = 'FSM::SourceLiteralWidthAllocationSupport';
my $json = JSON::PP->new->canonical;

sub fixture {
    my (%args) = @_;
    my $manager = FSM::Adapter::FSMGenFull::SignalManager->new;
    my $a = $manager->register_signal('A', width => $args{source_width} // 8);
    my $literal = FSM::CoreAST::Literal->new($args{value} // '256',
        width => $args{literal_width}, radix => $args{radix} // 'decimal');
    my $ast = FSM::CoreAST::BinaryOp->new('|', FSM::CoreAST::SignalRef->new($a), $literal);
    my $helper = $manager->register_signal('H', width => $args{result_width} // 1,
        type => 'wire', is_intermediate => 1);
    $helper->set_driving_ast($ast);
    my $record = {kind => 'source_literal_operand_max', selected_width => $args{selected_width},
        expression_tree => ['|', ['signal', 'A'],
            ['literal', {value => $args{value} // '256', width => $args{literal_width},
                radix => $args{radix} // 'decimal'}]]};
    return ($helper, $a, $literal, $record, $manager, $ast);
}

sub prepare {
    my ($helper, $record) = @_;
    return $class->prepare_core(signal => $helper, record => $record, track => 1);
}
sub current {
    my ($helper, $holder) = @_;
    return $class->current_core(signal => $helper, holder => $holder);
}

subtest 'raw literal allocation distinguishes unknown exact width from the nominal scalar' => sub {
    for my $bits (1, 8) {for my $value (256, '256') {
        my ($h, $a, $literal, $record) = fixture(source_width => $bits, value => $value);
        my $before = $json->encode([$literal->value, $literal->radix, $literal->width, $h->width]);
        my $input = $json->encode($record);
        my $holder = prepare($h, $record);
        is($json->encode(current($h, $holder)), $input, 'nullable exact width and raw JSON kinds preserve');
        is($h->width, 1, 'no backend default is assigned to Core');
        is($json->encode([$literal->value, $literal->radix, $literal->width, $h->width]), $before,
            'holder inspection does not rewrite source literal or selected nominal width');
        $record->{expression_tree}[2][1]{value} = 'changed';
        my $out = current($h, $holder); $out->{expression_tree}[2][1]{radix} = 'binary';
        is($json->encode(current($h, $holder)), $input, 'caller and returned nested records detach');
        ok(eval {$json->encode($holder); 1}, 'complete capsule contains plain JSON only');
    }}
    for my $case ([1, '100000000', 9, 'binary', 9], [16, 'F', 4, 'hex', 16],
                  [1, '7', 3, 'octal', 3], [8, '3', 2, 'decimal', 8]) {
        my ($source, $value, $size, $radix, $selected) = @$case;
        for my $selected_kind ($selected, "$selected") {
            my ($h, undef, undef, $record) = fixture(source_width => $source, value => $value,
                literal_width => $size, radix => $radix, result_width => $selected, selected_width => $selected_kind);
            is($json->encode(current($h, prepare($h, $record))), $json->encode($record),
                'explicit literal floor uses the exact source maximum and preserves selected-width kind');
        }
    }
};

subtest 'currentness includes matching writes and foreign identities without retaining owners' => sub {
    for my $write (
        sub {$_[4]->register_signal('H', width => 1)},
        sub {$_[4]->register_signal('A', width => 8)},
        sub {$_[0]->set_driving_ast($_[5])},
        sub {$_[0]->set_attribute('is_intermediate', 1)},
        sub {$_[1]->set_attribute('width_declared', undef)},
        sub {eval {$_[0]->set_declared_width_binding({})}},
        sub {eval {$_[0]->set_declared_width_requirements({})}},
        sub {$_[1]->add_constraint({kind => 'independent', width => 8})},
    ) {
        my @f = fixture(); my $holder = prepare($f[0], $f[3]);
        $write->(@f);
        ok(!defined(current($f[0], $holder)), 'relevant supported write revokes even matching state');
    }
    my @f = fixture(); my $holder = prepare($f[0], $f[3]);
    $f[4]->register_signal('H', attributes => {debug_label => 'unrelated'});
    is_deeply(current($f[0], $holder), $f[3], 'unrelated diagnostics preserve intent');
    my ($foreign) = fixture();
    ok(!defined(current($foreign, $holder)), 'equal foreign helper cannot borrow a capsule');
    # The ordinary Core AST web intentionally links a source's fanout back to
    # its helper. Break that fixture-owned cycle before testing holder ownership.
    $f[1]{fanout_signals} = [];
    my $weak = $f[0]; weaken($weak); @f = ();
    ok(!defined($weak), 'holder and lifetime identity table retain no helper owner');
    my ($replacement) = fixture();
    ok(!defined(current($replacement, $holder)), 'later equal allocation cannot borrow an earlier lifetime');
};

subtest 'actual AST data and literal kinds are part of the held state' => sub {
    for my $mutate (
        sub {$_[2]->{value} = 256},
        sub {$_[2]->{radix} = 'hex'},
        sub {$_[2]->{width} = 9},
        sub {$_[5]->{operator} = '^'},
        sub {$_[5]->{operands}[0] = FSM::CoreAST::SignalRef->new($_[1])},
        sub {$_[5]->{operands}[1] = FSM::CoreAST::Literal->new('256')},
        sub {$_[0]->{_width} = '1'},
        sub {$_[1]->{_width} = '8'},
        sub {$_[1]->{_declared_width_source} = {independent => 1}},
    ) {
        my @f = fixture(); my $holder = prepare($f[0], $f[3]);
        $mutate->(@f);
        ok(!defined(current($f[0], $holder)), 'shape identity raw literal or source constraint divergence withholds');
    }
};

subtest 'independent result constraints unknown shapes and invalid supplied intent withhold' => sub {
    for my $change (
        sub {$_[0]->{_width} = 8},
        sub {$_[0]->set_attribute('width_declared', 1)},
        sub {$_[0]->set_attribute('is_output', 1)},
        sub {$_[0]->{signed} = 1},
        sub {$_[0]->{_declared_width_source} = {}},
        sub {$_[5]->{operator} = '+'},
        sub {$_[5]->{operands}[0]{slice} = [0, 0]},
        sub {$_[1]->set_attribute('is_intermediate', 1)},
        sub {$_[5]->{operands}[1] = FSM::CoreAST::Expression->new(type => 'future')},
        sub {$_[5]->{operands}[0] = $_[5]},
    ) {
        my @f = fixture(); $change->(@f);
        ok(!eval {prepare($f[0], $f[3]); 1}, 'unqualified or independently constrained actual source refuses');
    }
    for my $change (
        sub {$_[0]{selected_width} = 32},
        sub {$_[0]{expression_tree}[2][1]{value} = 256},
        sub {$_[0]{expression_tree}[2][1]{extra} = 1},
        sub {$_[0]{extra} = 1},
        sub {$_[0]{kind} = 'binary_operand_max'},
    ) {
        my ($h, undef, undef, $record) = fixture(); $change->($record);
        ok(!eval {prepare($h, $record); 1}, 'forged width kind or raw source data cannot assert allocation');
    }
    my ($h, undef, undef, $record) = fixture();
    my $keys = join(',', sort keys %$h);
    ok(!defined(current($h, undef)), 'ordinary absent lookup withholds');
    is(join(',', sort keys %$h), $keys, 'lookup creates no signal fields');
    $record->{expression_tree}[1] = $record->{expression_tree};
    ok(!eval {$class->copy_record($record); 1}, 'cyclic supplied record refuses boundedly');
};

subtest 'a later source read cannot conceal an earlier matching write' => sub {
    for my $write_at (1, 4) {
        my @f = fixture(); my $holder = prepare($f[0], $f[3]);
        my $original = FSM::CoreAST::Literal->can('width');
        my $reads = 0;
        no warnings 'redefine';
        local *FSM::CoreAST::Literal::width = sub {
            $f[4]->register_signal('A', width => 8) if ++$reads == $write_at;
            return $original->(@_);
        };
        ok(!defined(current($f[0], $holder)),
            'complete barrier rejects a matching write during the first or final capture');
    }
};

subtest 'depth and occurrence budgets bound actual source and supplied tree walks' => sub {
    my ($h, $a, $literal, $record) = fixture();
    my $ast = $literal;
    my $tree = $record->{expression_tree}[2];
    for (1 .. FSM::CoreExpressionWidthSupport::MAX_DEPTH()) {
        $ast = FSM::CoreAST::BinaryOp->new('|', $ast, FSM::CoreAST::SignalRef->new($a));
        $tree = ['|', $tree, ['signal', 'A']];
    }
    $h->{driving_ast} = $ast; $record->{expression_tree} = $tree;
    is_deeply(current($h, prepare($h, $record)), $record, 'shared depth boundary is inclusive');
    $h->{driving_ast} = FSM::CoreAST::BinaryOp->new('|', $ast, FSM::CoreAST::SignalRef->new($a));
    $record->{expression_tree} = ['|', $tree, ['signal', 'A']];
    ok(!eval {prepare($h, $record); 1}, 'next source depth refuses');
    my $shared = $literal;
    my $shared_tree = ['literal', {value => '256', width => undef, radix => 'decimal'}];
    for (1 .. 12) {
        $shared = FSM::CoreAST::BinaryOp->new('|', $shared, $shared);
        $shared_tree = ['|', $shared_tree, $shared_tree];
    }
    $h->{driving_ast} = $shared;
    ok(!defined($class->_capture($h)), 'over-budget actual repeated occurrences withhold');
    $record->{expression_tree} = $shared_tree;
    ok(!eval {$class->copy_record($record); 1}, 'over-budget supplied repeated occurrences refuse');
    my ($fresh, undef, undef, $fresh_record) = fixture();
    is_deeply(current($fresh, prepare($fresh, $fresh_record)), $fresh_record, 'failed walks do not poison later preparation');
};

done_testing();
