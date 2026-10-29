use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr weaken);
use FSM::CoreAST;
use FSM::SourceLiteralWidthAllocationSupport;
use FSM::Adapter::FSMGenFull::SignalManager;

my $class = 'FSM::SourceLiteralWidthAllocationSupport';
my $json = JSON::PP->new->canonical;
sub binary { FSM::CoreAST::BinaryOp->new(@_) }
sub reference { FSM::CoreAST::SignalRef->new($_[0]) }
sub helper {
    my ($manager, $name, $ast, $width) = @_;
    my $signal = $manager->register_signal($name, width => $width, type => 'wire', is_intermediate => 1);
    $signal->set_driving_ast($ast);
    return $signal;
}
sub intent { +{kind => 'source_literal_operand_max', selected_width => $_[0], expression_tree => $_[1]} }
sub fixture {
    my (%args) = @_;
    my $manager = FSM::Adapter::FSMGenFull::SignalManager->new;
    my $a = $manager->register_signal('A', width => $args{source_width} // 8);
    my $b = $manager->register_signal('B', width => $args{floor} // 16, width_declared => 1);
    my $literal = FSM::CoreAST::Literal->new($args{value} // '256', width => $args{size}, radix => 'decimal');
    my $exact = defined($args{size}) ? (($args{source_width} // 8) > $args{size} ? $args{source_width} // 8 : $args{size}) : undef;
    my $child = helper($manager, 'CHILD', binary('|', reference($a), $literal), $exact // 1);
    my $record = intent($exact, ['|', ['signal', 'A'], ['literal', {value => $args{value} // '256', width => $args{size}, radix => 'decimal'}]]);
    my $holder = $class->prepare_core(signal => $child, record => $record, track => 1);
    my $left = reference($child);
    my $right = $args{shared} ? reference($child) : reference($b);
    my $width = defined($exact) ? ($args{shared} || $exact > ($args{floor} // 16) ? $exact : $args{floor} // 16) : undef;
    my $parent = helper($manager, 'PARENT', binary('^', $left, $right), $width // 1);
    my $parent_record = intent($width, ['^', $record->{expression_tree}, $args{shared} ? $record->{expression_tree} : ['signal', 'B']]);
    return {manager => $manager, a => $a, b => $b, literal => $literal, child => $child,
        child_record => $record, child_holder => $holder, left => $left, right => $right,
        parent => $parent, record => $parent_record};
}
sub birth {
    my ($f) = @_;
    return {phase => 'birth', lookup => sub {
        my ($ref) = @_;
        return unless refaddr($ref->signal) == refaddr($f->{child});
        return $f->{child_holder};
    }};
}
sub prepare {
    my ($f, $children) = @_;
    return $class->prepare_core(signal => $f->{parent}, record => $f->{record}, track => 1, children => $children);
}
sub current {
    my ($f, $holder, $children) = @_;
    return $class->current_core(signal => $f->{parent}, holder => $holder, children => $children);
}

subtest 'explicit nested birth holders preserve unknown width and independent source floors' => sub {
    for my $bits (1, 8) {for my $size (undef, 9) {for my $value (256, '256') {
        my $f = fixture(source_width => $bits, size => $size, value => $value);
        my $children = birth($f);
        my $before = $json->encode([$f->{child_record}, $f->{record}, $f->{a}->width, $f->{b}->width, $f->{literal}->value]);
        my $holder = eval {prepare($f, $children)};
        ok($holder, 'actual typed child with current birth prepares') or diag $@;
        next unless $holder;
        is($json->encode(current($f, $holder, $children)), $json->encode($f->{record}), 'expanded source raw kinds and exact nullable width preserve');
        is($f->{parent}->width, defined($size) ? 16 : 1, 'unknown source never borrows a nominal child or independent floor');
        is($json->encode([$f->{child_record}, $f->{record}, $f->{a}->width, $f->{b}->width, $f->{literal}->value]), $before,
            'source literals independent declaration and caller data remain unchanged');
        my $out = current($f, $holder, $children);
        $out->{expression_tree}[1][2][1]{value} = 'changed';
        is_deeply(current($f, $holder, $children), $f->{record}, 'nested return data detaches');
        ok(eval {$json->encode($holder); 1}, 'stored nested holder is plain JSON');
        ok(!eval {$class->prepare_core(signal => $f->{parent}, record => $f->{record}, track => 1); 1}, 'default direct boundary still rejects generated child references');
    }}}
};

subtest 'completed lookup requires actual installed policy and never borrows provisional intent' => sub {
    my $f = fixture();
    ok(!eval {prepare($f, {phase => 'completed'}); 1}, 'an unpublished birth is not completed child policy');
    ok($f->{child}->_publish_staged_source_literal_width_allocation($f->{child_holder}), 'actual child publication succeeds');
    my $holder = eval {prepare($f, {phase => 'completed'})};
    ok($holder, 'actual installed completed policy prepares') or diag $@;
    return unless $holder;
    is_deeply(current($f, $holder, {phase => 'completed'}), $f->{record}, 'completed currentness uses actual child field');
    ok(!defined(current($f, $holder, birth($f))), 'birth lookup cannot impersonate completed relationship');
    delete $f->{child}{_source_literal_width_allocation};
    ok(!defined(current($f, $holder, {phase => 'completed'})), 'removing installed child policy revokes completed parent proof');
    for my $bad ({}, {phase => 'future'}, {phase => 'birth'}, {phase => 'birth', lookup => 1},
        {phase => 'completed', lookup => sub {$f->{child_holder}}}, {phase => 'completed', extra => 1}) {
        ok(!eval {prepare($f, $bad); 1}, 'malformed or mixed phase contract refuses');
    }
    $f = fixture();
    $f->{child}->_publish_staged_source_literal_width_allocation($f->{child_holder});
    $holder = prepare($f, {phase => 'completed'});
    my $original = FSM::CoreAST::Literal->can('width');
    my $reads = 0;
    no warnings 'redefine';
    local *FSM::CoreAST::Literal::width = sub {
        delete $f->{child}{_source_literal_width_allocation} if ++$reads == 4;
        return $original->(@_);
    };
    ok(!defined(current($f, $holder, {phase => 'completed'})),
        'removing installed policy during the final child read cannot escape the completed barrier');
};

subtest 'each repeated child edge is bound separately from expanded source text' => sub {
    my $f = fixture(shared => 1, size => 9);
    my $children = birth($f);
    my $holder = eval {prepare($f, $children)};
    ok($holder, 'shared current child is not a cycle') or diag $@;
    return unless $holder;
    my $state = $json->decode($holder->{state});
    is(scalar @{$state->{children}}, 2, 'ordered edges remain explicit');
    isnt($state->{children}[0]{reference_identity}, $state->{children}[1]{reference_identity}, 'actual typed reference slots have distinct identities');
    is($state->{children}[0]{signal_identity}, $state->{children}[1]{signal_identity}, 'both slots name the same actual child lifetime');
    is_deeply($holder->{record}{expression_tree}[1], $holder->{record}{expression_tree}[2], 'expanded text retains both occurrences');
    $f->{parent}{driving_ast}{operands}[1] = reference($f->{child});
    ok(!defined(current($f, $holder, $children)), 'equal replacement reference cannot borrow an old edge identity');
};

subtest 'missing foreign stale independently constrained and late changed child state withholds' => sub {
    for my $change (
        sub {$_[0]{child_holder} = undef},
        sub {$_[0]{child_holder} = fixture()->{child_holder}},
        sub {$_[0]{manager}->register_signal('CHILD', width => 1)},
        sub {$_[0]{manager}->register_signal('A', width => 8)},
        sub {$_[0]{child}->set_attribute('width_declared', 1)},
        sub {eval {$_[0]{child}->set_declared_width_binding({})}},
        sub {$_[0]{literal}{value} = 256},
        sub {$_[0]{a}{_declared_width_source} = {independent => 1}},
        sub {$_[0]{parent}{driving_ast}{operands}[0] = reference(fixture()->{child})},
    ) {
        my $f = fixture(); my $children = birth($f); my $holder = eval {prepare($f, $children)};
        ok($holder, 'valid nested predecessor prepares') or diag $@;
        next unless $holder;
        $change->($f);
        ok(!defined(current($f, $holder, $children)), 'changed child ownership or source state withholds');
    }
    my $f = fixture(shared => 1); my $children = birth($f); my $holder = eval {prepare($f, $children)};
    ok($holder, 'late-write fixture prepares') or diag $@;
    return unless $holder;
    my $calls = 0;
    my $late = {phase => 'birth', lookup => sub {
        $f->{manager}->register_signal('PARENT', width => 1) if ++$calls == 4;
        $f->{child_holder};
    }};
    ok(!defined(current($f, $holder, $late)), 'matching parent write on the final child lookup cannot escape the complete barrier');
    my $fresh = fixture(); my $lookup = {phase => 'birth', lookup => sub {die "lookup failure\n"}};
    ok(!eval {prepare($fresh, $lookup); 1}, 'lookup exceptions refuse preparation');
    is_deeply(current($fresh, prepare($fresh, birth($fresh)), birth($fresh)), $fresh->{record}, 'failed capture leaves fresh reuse usable');
    my $collision = fixture();
    $collision->{b}{name} = 'A';
    $collision->{record}{expression_tree}[2] = ['signal', 'A'];
    ok(!eval {prepare($collision, birth($collision)); 1},
        'expanded equal names cannot conceal distinct original independent leaf identities');
};

subtest 'one global walk bounds helper expansion rather than resetting at every child' => sub {
    my $f = fixture();
    my %holders = (CHILD => $f->{child_holder});
    my $children = {phase => 'birth', lookup => sub {$holders{$_[0]->signal->name}}};
    my ($child, $record) = @{$f}{qw(child child_record)};
    for my $level (2 .. 32) {
        my $parent = helper($f->{manager}, 'LEVEL_' . $level, binary('|', reference($child), reference($f->{a})), 1);
        my $next = intent(undef, ['|', $record->{expression_tree}, ['signal', 'A']]);
        my $holder = eval {$class->prepare_core(signal => $parent, record => $next, track => 1, children => $children)};
        ok($holder, 'combined depth admits level ' . $level) or diag $@;
        return unless $holder;
        $holders{$parent->name} = $holder; ($child, $record) = ($parent, $next);
    }
    my $over = helper($f->{manager}, 'OVER_DEPTH', binary('|', reference($child), reference($f->{a})), 1);
    ok(!eval {$class->prepare_core(signal => $over, record => intent(undef, ['|', $record->{expression_tree}, ['signal', 'A']]), track => 1, children => $children); 1}, 'next cross-helper depth refuses');
    my $cyclic = fixture();
    my $parent_holder = prepare($cyclic, birth($cyclic));
    $cyclic->{child}{driving_ast}{operands}[0] = reference($cyclic->{parent});
    my $lookups = 0;
    my $cycle_lookup = {phase => 'birth', lookup => sub {
        ++$lookups;
        return refaddr($_[0]->signal) == refaddr($cyclic->{child})
            ? $cyclic->{child_holder} : $parent_holder;
    }};
    ok(!eval {prepare($cyclic, $cycle_lookup); 1}, 'actual helper cycle with supplied capsules refuses');
    is($lookups, 2, 'active helper path rejects the genuine back edge before another expansion');

    $f = fixture(); %holders = (CHILD => $f->{child_holder});
    ($child, $record) = @{$f}{qw(child child_record)};
    for my $level (2 .. 11) {
        my $parent = helper($f->{manager}, 'SHARED_' . $level, binary('^', reference($child), reference($child)), 1);
        my $next = intent(undef, ['^', $record->{expression_tree}, $record->{expression_tree}]);
        my $holder = eval {$class->prepare_core(signal => $parent, record => $next, track => 1, children => $children)};
        if ($level < 11) {
            ok($holder, 'repeated occurrences admit level ' . $level) or diag $@;
            return unless $holder;
            $holders{$parent->name} = $holder; ($child, $record) = ($parent, $next);
        } else {
            ok(!$holder, 'global occurrence budget refuses even when each child holder is locally bounded');
        }
    }
};

subtest 'nested holder and phase lookup leave no extra owner graph' => sub {
    my $f = fixture(); my $children = birth($f); my $holder = eval {prepare($f, $children)};
    ok($holder, 'weak ownership fixture prepares') or diag $@;
    return unless $holder;
    my $weak = $f->{child}; weaken($weak);
    # Existing Core fanout cycles are separately owned; break only this fixture's web.
    $_->{fanout_signals} = [] for values %{$f->{manager}{signal_registry}};
    undef $children; undef $f;
    ok(!defined $weak, 'detached nested capsule retains no child or independent leaf');
    my $replacement = fixture();
    ok(!defined(current($replacement, $holder, birth($replacement))), 'later equal graph lifetime cannot inherit a capsule');
};

done_testing();
