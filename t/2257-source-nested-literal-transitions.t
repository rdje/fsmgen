use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr);
use FSM::CoreAST;
use FSM::SourceLiteralWidthAllocationSupport;
use FSM::Adapter::FSMGenFull;

my $class = 'FSM::SourceLiteralWidthAllocationSupport';
my $json = JSON::PP->new->canonical;
sub binary { FSM::CoreAST::BinaryOp->new(@_) }
sub reference { FSM::CoreAST::SignalRef->new($_[0]) }
sub intent { +{kind => 'source_literal_operand_max', selected_width => $_[0], expression_tree => $_[1]} }
sub helper {
    my ($m, $name, $ast, $width) = @_;
    my $h = $m->register_signal($name, width => $width, type => 'wire', is_intermediate => 1);
    $h->set_driving_ast($ast); return $h;
}
sub fixture {
    my (%args) = @_;
    my $adapter = FSM::Adapter::FSMGenFull->new;
    my $m = $adapter->{signal_manager};
    my $a = $m->register_signal('A', width => $args{bits} // 8,
        (defined($args{width_source}) ? (_declared_width_source => $args{width_source}) : ()));
    my $b = $m->register_signal('B', width => 16, width_declared => 1);
    my $size = $args{sized} ? 9 : undef;
    my $literal = FSM::CoreAST::Literal->new($args{value} // '256', width => $size, radix => 'decimal');
    my $child = helper($m, 'CHILD', binary('|', reference($a), $literal), $size // 1);
    my $child_record = intent($size, ['|', ['signal', 'A'], ['literal', {value => $args{value} // '256', width => $size, radix => 'decimal'}]]);
    my %holders = (CHILD => $class->prepare_core(signal => $child, record => $child_record, track => 1));
    my $children = {phase => 'birth', lookup => sub {$holders{$_[0]->signal->name}}};
    my $parent = helper($m, 'PARENT', binary('^', reference($child), reference($b)), $size ? 16 : 1);
    my $record = intent($size ? 16 : undef, ['^', $child_record->{expression_tree}, ['signal', 'B']]);
    $holders{PARENT} = $class->prepare_core(signal => $parent, record => $record, track => 1, children => $children);
    my $root = helper($m, 'ROOT', binary('&', reference($parent), reference($parent)), $size ? 16 : 1);
    my $root_record = intent($size ? 16 : undef, ['&', $record->{expression_tree}, $record->{expression_tree}]);
    $holders{ROOT} = $class->prepare_core(signal => $root, record => $root_record, track => 1, children => $children);
    return {adapter => $adapter, m => $m, a => $a, b => $b, literal => $literal, child => $child,
        parent => $parent, root => $root, holders => \%holders, children => $children,
        records => {CHILD => $child_record, PARENT => $record, ROOT => $root_record}};
}
sub advance {
    my ($f, $name, $changed, $revision, $transition, $children) = @_;
    return $class->advance_core(signal => $f->{m}->get_signal($name), holder => $f->{holders}{$name},
        changed_signal => $changed, revision => $revision, transition => $transition,
        children => $children // $f->{children});
}
sub role_change {
    my ($f, $signal, $role) = @_;
    my $revision = $signal->_intermediate_width_allocation_revision;
    $signal->set_attribute('signal_role', $role);
    return ($revision, {kind => 'role', attribute => 'signal_role', value => $role});
}
sub refresh_all {
    my ($f, $changed, $revision, $operation) = @_;
    my %next;
    for my $name (qw(CHILD PARENT ROOT)) {
        my $h = advance($f, $name, $changed, $revision, $operation);
        $f->{holders}{$name} = $h if $h;
        $next{$name} = $h;
    }
    return \%next;
}

subtest 'one exact named leaf role write crosses each nested repeated child edge' => sub {
    for my $bits (1, 8) {for my $sized (0, 1) {for my $value (256, '256', "\x{E9}", "\x{2603}") {
        my $f = fixture(bits => $bits, sized => $sized, value => $value);
        my $before = $json->decode($json->encode($f->{holders}));
        my $literal = $json->encode([$f->{literal}->value, $f->{literal}->width, $f->{literal}->radix]);
        my ($revision, $operation) = role_change($f, $f->{a}, 'INPUT');
        my $next = refresh_all($f, $f->{a}, $revision, $operation);
        for my $name (qw(CHILD PARENT ROOT)) {
            ok($next->{$name}, 'exact nested transition carries ' . $name) or next;
            is_deeply($class->current_core(signal => $f->{m}->get_signal($name), holder => $next->{$name}, children => $f->{children}),
                $f->{records}{$name}, 'transported holder is current with unchanged raw source intent');
            ok(!defined($class->current_core(signal => $f->{m}->get_signal($name), holder => $before->{$name}, children => $f->{children})),
                'escaped old capsule remains stale');
        }
        is($json->encode([$f->{literal}->value, $f->{literal}->width, $f->{literal}->radix]), $literal, 'literal JSON kinds and explicit size preserve');
        is($f->{b}->width, 16, 'independent floor stays authored');
    }}}
};

subtest 'completed phase uses actual refreshed installed child and preserves its original epoch proof' => sub {
    my $f = fixture();
    ok($f->{child}->_publish_staged_source_literal_width_allocation($f->{holders}{CHILD}), 'install actual completed direct child');
    my $completed = {phase => 'completed'};
    $f->{holders}{PARENT} = $class->prepare_core(signal => $f->{parent}, record => $f->{records}{PARENT}, track => 1, children => $completed);
    my ($revision, $operation) = role_change($f, $f->{a}, 'INPUT');
    my $child = advance($f, 'CHILD', $f->{a}, $revision, $operation);
    ok($child && $f->{child}->_publish_staged_source_literal_width_allocation($child), 'refresh actual completed child by its named delta');
    my $parent = advance($f, 'PARENT', $f->{a}, $revision, $operation, $completed);
    ok($parent, 'completed parent accepts the same exact child epoch transition');
    my $current = $class->current_core(signal => $f->{parent}, holder => $parent, children => $completed);
    is_deeply($current, $f->{records}{PARENT}, 'completed transported parent is current');
    ok(!advance($f, 'PARENT', $f->{a}, $revision, $operation, $f->{children}), 'birth phase cannot renew a completed parent');
};

subtest 'named matching reference and generated helper role writes retain nested ownership' => sub {
    for my $helper_role (0, 1) {
        my $f = fixture();
        my $signal = $helper_role ? $f->{child} : $f->{a};
        my $revision = $signal->_intermediate_width_allocation_revision;
        my ($attribute, $value) = $helper_role ? ('signal_role', 'INTERNAL_INTERMEDIATE') : ('is_output', 0);
        $signal->set_attribute($attribute, $value);
        my $next = refresh_all($f, $signal, $revision, {kind => 'role', attribute => $attribute, value => $value});
        ok($next->{$_}, 'named reference/helper operation carries ' . $_) for qw(CHILD PARENT ROOT);
    }
};

subtest 'a refreshed current child cannot hide an unrelated record kind or independent source change' => sub {
    for my $change (
        sub {$_[0]{holders}{CHILD}{record}{selected_width} = '9'},
        sub {$_[0]{a}{_declared_width_source} = {independent => 8}},
        sub {$_[0]{child}{driving_ast}{operands}[1]{value} = '257'},
    ) {
        my $f = fixture(sized => 1);
        my ($revision, $operation) = role_change($f, $f->{a}, 'INPUT');
        my $child = advance($f, 'CHILD', $f->{a}, $revision, $operation);
        ok($child, 'legitimate direct child transition prepares before hostile change');
        $f->{holders}{CHILD} = $child;
        $change->($f);
        if ($f->{literal}->value eq '257') {
            $f->{records}{CHILD}{expression_tree}[2][1]{value} = '257';
        }
        # Explicit local re-preparation can make a new child current. It cannot
        # license that unrelated change across an original parent edge.
        $f->{holders}{CHILD} = $class->prepare_core(signal => $f->{child},
            record => $f->{literal}->value eq '257' ? $f->{records}{CHILD} : $f->{holders}{CHILD}{record}, track => 1);
        ok($class->current_core(signal => $f->{child}, holder => $f->{holders}{CHILD}), 'replacement child is independently current');
        ok(!advance($f, 'PARENT', $f->{a}, $revision, $operation), 'original parent child capsule binds every unrelated raw/kind byte');
    }
};

subtest 'extra matching failed foreign and late writes cannot transport a stale parent' => sub {
    for my $change (
        sub {$_[0]{a}->set_attribute('signal_role', 'INPUT')},
        sub {eval {$_[0]{a}->set_declared_width_binding({})}},
        sub {$_[0]{holders}{CHILD} = fixture()->{holders}{CHILD}},
        sub {$_[0]{m}->get_signal('B')->{_declared_width_source} = {independent => 16}},
    ) {
        my $f = fixture();
        my ($revision, $operation) = role_change($f, $f->{a}, 'INPUT');
        my $child = advance($f, 'CHILD', $f->{a}, $revision, $operation);
        $f->{holders}{CHILD} = $child if $child;
        $change->($f);
        ok(!advance($f, 'PARENT', $f->{a}, $revision, $operation), 'extra stale failed or foreign proof withholds');
    }
    my $f = fixture();
    my ($revision, $operation) = role_change($f, $f->{a}, 'INPUT');
    $f->{holders}{CHILD} = advance($f, 'CHILD', $f->{a}, $revision, $operation);
    my $late = {phase => 'birth', lookup => sub {
        $f->{parent}->set_attribute('signal_role', 'INTERNAL_INTERMEDIATE');
        $f->{holders}{CHILD};
    }};
    ok(!advance($f, 'PARENT', $f->{a}, $revision, $operation, $late), 'late getter/lookup writes remain fenced during transport');
};

subtest 'actual mutable leaf requirement and binding payloads cross nested holders exactly' => sub {
    my $text = '(?fsm:metadata (+params (W 8)) (+size (A (param W)) (B (param W)) (DATA 1) (OTHER 1))'
        .' (idle (<(| A B 256) (= (DATA 1)) (= (OTHER 1))) (-> idle)))';
    require Lispish;
    my $adapter = FSM::Adapter::FSMGenFull->new;
    $adapter->parse_fsm(scalar Lispish::multi(\$text));
    my $actual = $adapter->{signal_manager}->get_signal('A');
    for my $kind (qw(requirements binding)) {
        my $method = 'declared_width_' . $kind;
        my $record = $actual->$method;
        ok($record, 'actual completed source supplies metadata payload');
        my $f = fixture(width_source => $actual->declared_width_source);
        my $before = $json->encode($record);
        my $revision = $f->{a}->_intermediate_width_allocation_revision;
        my $setter = 'set_declared_width_' . $kind;
        $f->{a}->$setter($record);
        my $next = refresh_all($f, $f->{a}, $revision, {kind => $kind, record => $record});
        ok($next->{ROOT}, 'actual named metadata payload crosses all nested slots');
        is($json->encode($f->{a}->$method), $before, 'metadata and caller JSON kinds preserve');
    }
};

done_testing();
