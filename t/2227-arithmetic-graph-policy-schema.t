use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use FSM::IntermediateWidthGraphPolicySupport;
use FSM::IntermediateWidthAllocationSupport;
use FSM::Backend::VerilogFamily::DeclarationCapture;
my $class = 'FSM::IntermediateWidthGraphPolicySupport';
my $json = JSON::PP->new->canonical;
sub policy {
    my ($selected) = @_;
    return {kind => 'arithmetic_graph_operand_max', operator => '+', source_names => ['AB','C'],
        expression_tree => ['+', ['+', ['signal','A'], ['signal','B']], ['signal','C']],
        selected_width => defined($selected) ? $selected : 8};
}
sub clone {return $json->decode($json->encode($_[0]))}
sub capture {
    my ($record, %options) = @_;
    my $c = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    $c->begin_module('graph_schema');
    my %widths = (A => 8, B => 4, C => 1, AB => 8, R => 8, %{$options{widths} // {}});
    for my $name (sort keys %widths) {
        next if $options{missing} && $options{missing} eq $name;
        my $row = {name => $name, width => $widths{$name}, signed => 0,
            %{$options{types}{$name} // {}}};
        if ($name eq 'R' || $name eq 'AB') {$c->record_intermediate_declaration($row)}
        else {$c->record_declaration($name =~ /\A[ABC]\z/ ? 'ports' : 'signals', $row)}
    }
    my $event = {expression => 'AB + C', arithmetic_origin => {kind => 'binary_arithmetic',
        operator => '+', source_names => ['AB','C']}, graph_width_allocation => $record,
        %{$options{event} // {}}};
    delete $event->{arithmetic_origin} if $options{no_origin};
    my $ok = eval {
        $c->record_intermediate_assignment('AB', {expression => 'A + B'}) unless ($options{missing} // '') eq 'AB';
        $c->record_intermediate_assignment('R', $event); $c->complete; 1
    };
    return ($ok, $c, $@, $event);
}
subtest 'closed graph records preserve kinds order duplicates and exact maxima' => sub {
    for my $op ('+', '-', '*', '/', '%') {
        my $p = policy; $p->{operator} = $op; $p->{expression_tree}[0] = $op;
        is($class->copy_record($p)->{operator}, $op, 'every canonical arithmetic root operator qualifies');
    }
    for my $selected (8, '0008', '18446744073709551618') {
        my $p = policy($selected);
        my $before = $json->encode($p);
        my $copy = $class->copy_record($p);
        is($json->encode($copy), $before, 'schema preserves supplied scalar JSON kinds');
        is($json->encode($p), $before, 'validation does not mutate caller data');
        is_deeply($class->leaf_names($copy), ['A','B','C'], 'original leaf order preserves');
        $copy->{expression_tree}[1][1][1] = 'WRONG';
        is($class->leaf_names($p)->[0], 'A', 'nested copy detaches');
    }
    my $duplicate = policy;
    $duplicate->{source_names} = ['AB','AB'];
    $duplicate->{expression_tree} = ['+', ['+', ['signal','A'], ['signal','B']], ['+', ['signal','A'], ['signal','B']]];
    is_deeply($class->leaf_names($duplicate), ['A','B','A','B'], 'duplicates are retained as ordered original slots');
    ok($class->matches_selected_widths($duplicate, 8, 8, 8), 'duplicate current edge slots qualify');
    ok($class->matches_leaf_widths($duplicate, 8, 8, 4, 8, 4), 'complete duplicate original vector qualifies');
    my $wide = policy('18446744073709551618');
    ok($class->matches_selected_widths($wide, '18446744073709551618', '18446744073709551617', '18446744073709551618'), 'current maximum compares exact decimal strings');
    ok($class->matches_leaf_widths($wide, '18446744073709551618', '18446744073709551616', '18446744073709551617', '18446744073709551618'), 'leaf maximum folds every exact decimal width');
    ok(!$class->matches_selected_widths(policy, 8, 8), 'omitted current slot refuses');
    ok(!$class->matches_leaf_widths(policy, 8, 8, 4), 'incomplete original vector refuses');
    ok(!$class->matches_leaf_widths(policy, 8, 1, 2, 16), 'later larger original leaf cannot be ignored');
};
subtest 'malformed whole logical literal and cyclic records cannot supply the graph schema' => sub {
    my @bad = (undef, {}, {%{policy()}, extra => 1}, {%{policy()}, kind => 'binary_operand_max'},
        {%{policy()}, operator => '-'}, {%{policy()}, source_names => ['AB']},
        {%{policy()}, source_names => ['AB','C[0]']}, {%{policy()}, selected_width => 0},
        {%{policy()}, selected_width => JSON::PP::true}, {%{policy()}, selected_width => '1.5'},
        {%{policy()}, expression_tree => ['+', ['signal','A'], ['signal','B']]},
        {%{policy()}, expression_tree => ['+', ['&', ['signal','A'], ['signal','B']], ['signal','C']]},
        {%{policy()}, expression_tree => ['+', ['+', ['signal','A'], ['literal',8]], ['signal','C']]});
    my $cyclic = ['+', ['signal','A'], undef]; $cyclic->[2] = $cyclic;
    push @bad, {%{policy()}, expression_tree => $cyclic};
    for my $p (@bad) {
        ok(!eval {$class->copy_record($p); 1}, 'malformed or unsupported schema refuses');
        like($@, qr/Graph width allocation/, 'refusal names the graph contract');
    }
    ok(!eval {FSM::IntermediateWidthAllocationSupport->copy_record(policy); 1}, 'existing binary schema still rejects graph records');
};
subtest 'invalid numeric vectors keep every slot and withhold without exceptions' => sub {
    my $binary = {kind => 'binary_operand_max', operator => '+', source_names => ['A','B'], selected_width => 8};
    for my $case (['missing', undef], ['array', []], ['boolean', JSON::PP::true],
        ['negative', '-1'], ['fraction', '1.5'], ['malformed', 'bad'], ['zero', 0]) {
        my ($label, $bad) = @$case;
        for my $call (
            sub {FSM::IntermediateWidthAllocationSupport->matches_selected_widths($binary, 8, 8, $bad)},
            sub {$class->matches_selected_widths(policy, 8, 8, $bad)},
            sub {$class->matches_leaf_widths(policy, 8, 8, $bad, 1)},
        ) {
            my $result = eval {$call->()};
            is($@, '', "$label width withholds without an arity exception");
            ok(!$result, "$label width cannot disappear from its required vector");
        }
    }
};
sub chain {
    my ($count) = @_;
    my $tree = ['signal','A'];
    $tree = ['+', $tree, ['signal','B']] for 1..$count;
    return $tree;
}
sub balanced {
    my ($levels) = @_;
    return ['signal','A'] unless $levels;
    return ['+', balanced($levels - 1), balanced($levels - 1)];
}
subtest 'published shared walk bounds refuse larger records before copying' => sub {
    ok(eval {$class->copy_record({%{policy()}, expression_tree => chain(64)}); 1}, 'documented binary depth boundary qualifies');
    ok(!eval {$class->copy_record({%{policy()}, expression_tree => chain(65)}); 1}, 'next binary depth refuses');
    my $inside = balanced(11);
    ok(eval {$class->copy_record({%{policy()}, expression_tree => $inside}); 1}, 'complete tree within the node budget qualifies');
    ok(!eval {$class->copy_record({%{policy()}, expression_tree => ['+', $inside, ['signal','B']]}); 1}, 'next full-tree node pair crosses the node budget');
};
subtest 'collector graph field joins exact origin all declarations and both maxima' => sub {
    for my $selected (8, '0008') {
        my ($ok, $c, $error, $event) = capture(policy($selected));
        ok($ok, 'closed graph field completes with actual numeric declarations') or diag $error;
        next unless $ok;
        is_deeply($c->snapshot->{target_intermediates}{R}, $event, 'graph field and JSON kinds detach unchanged');
        $event->{graph_width_allocation}{source_names}[0] = 'WRONG';
        is($c->snapshot->{target_intermediates}{R}{graph_width_allocation}{source_names}[0], 'AB', 'stored graph policy owns no caller array');
    }
    my $wide = '18446744073709551618';
    my ($ok, $c, $error) = capture(policy($wide), widths => {A => '18446744073709551616', B => '18446744073709551617', AB => '18446744073709551617', C => $wide, R => $wide});
    ok($ok, 'collector compares current and original-leaf widths exactly') or diag $error;
};
subtest 'unsupported graph metadata invalidates the complete collector transaction' => sub {
    my @cases = (
        {missing => 'A'}, {missing => 'AB'}, {types => {A => {signed => 1}}},
        {types => {AB => {state_model => 'enum'}}}, {types => {C => {declared_type_name => 'word_t'}}},
        {types => {R => {declared_type_spec => {kind => 'bits', width => 8}}}},
        {widths => {AB => 32, R => 32}, record => policy(32)},
        {widths => {A => 16}}, {widths => {R => 1}},
        {event => {arithmetic_origin => {kind => 'binary_arithmetic', operator => '+', source_names => ['C','AB']}}},
        {no_origin => 1},
        {event => {arithmetic_origin => {kind => 'binary_arithmetic', operator => '-', source_names => ['AB','C']}}},
        {event => {graph_width_allocation => undef}},
        {event => {width_allocation => {kind => 'binary_operand_max', operator => '+', source_names => ['AB','C'], selected_width => 8}}},
        {label => 'original leaf cannot be the result itself', record => {%{policy()},
            expression_tree => ['+', ['+', ['signal','R'], ['signal','B']], ['signal','C']]}},
        {label => 'graph intent requires a declared computed edge', record => {%{policy()}, source_names => ['A','B']},
            event => {expression => 'A + B', arithmetic_origin => {kind => 'binary_arithmetic', operator => '+', source_names => ['A','B']}}},
    );
    for my $case (@cases) {
        my %options = %$case;
        my $label = delete($options{label}) // 'missing typed conflicting or width-inconsistent graph data refuses';
        my $record = delete($options{record}) // policy;
        my ($ok, $c, $error) = capture($record, %options);
        ok(!$ok, $label);
        ok(!eval {$c->snapshot; 1}, 'failed collector exposes no partial snapshot');
    }
};
done_testing();
