use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use FSM::IntermediateWidthAllocationSupport;
use FSM::IntermediateWidthGraphPolicySupport;

my $json = JSON::PP->new->canonical;
my $available = eval {require FSM::SourceBitwiseTreePolicySupport; 1};
my $load_error = $@;

sub record {
    my ($width, $operator, @names) = @_;
    $width //= 8; $operator //= '&'; @names = qw(A B C) unless @names;
    my @slots = @names;
    my $tree = ['signal', shift @names];
    $tree = [$operator, $tree, ['signal', $_]] for @names;
    return {kind => 'source_bitwise_tree_operand_max', operator => $operator,
        source_names => \@slots, expression_tree => $tree, selected_width => $width};
}

subtest 'source tree data has a separate schema owner' => sub {
    ok($available, 'source bitwise tree policy owner is available') or diag $load_error;
    my $r = record();
    ok(!eval {FSM::IntermediateWidthAllocationSupport->copy_record($r); 1},
        'binary two-slot schema does not accept source tree data');
    ok(!eval {FSM::IntermediateWidthGraphPolicySupport->copy_record($r); 1},
        'computed arithmetic graph schema does not accept source tree data');
};

subtest 'ordered trees, duplicates and scalar JSON kinds detach' => sub {
    plan skip_all => 'new schema absent' unless $available;
    for my $operator ('&', '|', '^') {
        for my $width (1, '8') {
            my $input = record($width, $operator, qw(A B A));
            my $before = $json->encode($input);
            my $copy = FSM::SourceBitwiseTreePolicySupport->copy_record($input);
            is($json->encode($copy), $before, 'complete record and width kind preserve');
            is($json->encode($input), $before, 'caller data stays exact');
            is_deeply(FSM::SourceBitwiseTreePolicySupport->leaf_names($copy), [qw(A B A)],
                'leaf slots retain order and duplicates');
            $copy->{expression_tree}[1][1][1] = 'FOREIGN';
            is($json->encode($input), $before, 'returned nested tree does not alias caller input');
            my $names = FSM::SourceBitwiseTreePolicySupport->leaf_names($input);
            $names->[0] = 'WRONG';
            is_deeply($input->{source_names}, [qw(A B A)], 'returned leaf vector detaches');
        }
    }
    my $mixed = record(8, '|', qw(A B C A));
    $mixed->{expression_tree} = ['|', ['&', ['signal','A'], ['signal','B']],
        ['^', ['signal','C'], ['signal','A']]];
    is_deeply(FSM::SourceBitwiseTreePolicySupport->copy_record($mixed), $mixed,
        'mixed canonical bitwise nodes retain their original topology');
};

subtest 'closed shape rejects wrong slots, families and unsupported nodes' => sub {
    plan skip_all => 'new schema absent' unless $available;
    for my $bad (
        {}, [], {%{record()}, extra => 1}, {%{record()}, kind => 'arithmetic_graph_operand_max'},
        {%{record()}, operator => '|'}, {%{record()}, source_names => [qw(B A C)]},
        {%{record()}, source_names => [qw(A B A)]}, {%{record()}, source_names => [qw(A B)]},
        {%{record()}, expression_tree => ['+', ['signal','A'], ['signal','B']]},
        {%{record()}, expression_tree => ['!', ['signal','A']]},
        {%{record()}, expression_tree => ['&', ['signal','A'], ['literal',8]]},
        {%{record()}, source_names => ['A','B','bad.name']}, record(8,'&',qw(A B)),
        {%{record()}, selected_width => 0}, {%{record()}, selected_width => '1.5'},
        {%{record()}, selected_width => JSON::PP::true},
    ) {
        ok(!eval {FSM::SourceBitwiseTreePolicySupport->copy_record($bad); 1},
            'unproved or malformed tree record refuses');
    }
    my $cycle = record();
    $cycle->{expression_tree}[1] = $cycle->{expression_tree};
    ok(!eval {FSM::SourceBitwiseTreePolicySupport->copy_record($cycle); 1},
        'cyclic caller tree refuses before JSON encoding');
};

subtest 'existing walk limits include the boundary and reject adjacent excess' => sub {
    plan skip_all => 'new schema absent' unless $available;
    is(FSM::IntermediateWidthGraphPolicySupport::MAX_BINARY_LEVELS(), 64, 'depth ceiling is unchanged');
    is(FSM::IntermediateWidthGraphPolicySupport::MAX_TREE_NODES(), 4096, 'node ceiling is unchanged');
    ok(eval {FSM::SourceBitwiseTreePolicySupport->copy_record(record(8,'&',('A') x 65)); 1},
        'sixty-four binary levels qualify') or diag $@;
    ok(!eval {FSM::SourceBitwiseTreePolicySupport->copy_record(record(8,'&',('A') x 66)); 1},
        'one additional binary level refuses');
    my $tree = ['signal','A'];
    $tree = ['&', $tree, $tree] for 1..11;
    my $r = {%{record()}, expression_tree => $tree, source_names => [('A') x 2048]};
    ok(eval {FSM::SourceBitwiseTreePolicySupport->copy_record($r); 1},
        '4095 visited nodes, including shared subtree slots, qualify') or diag $@;
    $r->{expression_tree} = ['&', $tree, ['signal','A']];
    push @{$r->{source_names}}, 'A';
    ok(!eval {FSM::SourceBitwiseTreePolicySupport->copy_record($r); 1},
        '4097 visited nodes exceed the unchanged budget');
};

subtest 'numeric consistency keeps independent widths and exact decimal maxima' => sub {
    plan skip_all => 'new schema absent' unless $available;
    ok(FSM::SourceBitwiseTreePolicySupport->matches_selected_widths(record('8'), 8, 2, 8, 4),
        'independent fixed operands satisfy their exact maximum');
    ok(!FSM::SourceBitwiseTreePolicySupport->matches_selected_widths(record(), 9, 2, 8, 4),
        'contextual result widening is independent and refuses');
    ok(!FSM::SourceBitwiseTreePolicySupport->matches_selected_widths(record(), 8, 8, 8),
        'missing leaf width refuses');
    for my $widths ([8,undef,4], [8,[],4], [8,0,4], [8,JSON::PP::true,4]) {
        my $value = eval {FSM::SourceBitwiseTreePolicySupport->matches_selected_widths(record(), 8, @$widths)};
        is($@, '', 'invalid numeric input withholds without a malformed-record error');
        ok(!$value, 'invalid leaf width cannot disappear from its slot');
    }
    my $big = '18446744073709551617';
    ok(FSM::SourceBitwiseTreePolicySupport->matches_selected_widths(record($big), $big,
        '18446744073709551616', '1', $big), 'maxima remain exact beyond native precision');
    ok(!FSM::SourceBitwiseTreePolicySupport->matches_selected_widths(record($big),
        '18446744073709551616', '18446744073709551616', '1', $big),
        'adjacent large result cannot borrow numeric equality');
};

done_testing();
