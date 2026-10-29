use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;

my $json = JSON::PP->new->canonical;
sub source {
    my ($width, $expression) = @_; $expression //= '(& A B C)';
    return "(?fsm:source_tree_publication (+params (W $width))"
        ." (+size (A (param W)) (B (param W)) (C (param W)) (DATA 1) (OTHER 1))"
        ." (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
}
sub parse_text {my ($a,$s) = @_; return $a->parse_fsm(scalar Lispish::multi(\$s))}
sub helpers {
    my ($adapter) = @_;
    return grep {$_->get_attribute('is_intermediate')} values %{$adapter->{signal_manager}{signal_registry}};
}
sub policies {
    my ($adapter) = @_;
    return grep {defined($_->source_bitwise_tree_width_allocation)} helpers($adapter);
}

subtest 'completed facade publishes detached actual source tree intent' => sub {
    for my $width (1,8) {
        for my $operator ('&','|','^') {
            my $adapter = FSM::Adapter::FSMGenFull->new;
            my $text = source($width, "($operator A B C)");
            my $raw = scalar Lispish::multi(\$text); my $before = $json->encode($raw);
            $adapter->parse_fsm($raw);
            my ($helper) = helpers($adapter);
            my $expected = {kind=>'source_bitwise_tree_operand_max', operator=>$operator, selected_width=>$width,
                source_names=>[qw(A B C)],
                expression_tree=>[$operator,[$operator,['signal','A'],['signal','B']],['signal','C']]};
            is_deeply($helper->source_bitwise_tree_width_allocation, $expected, 'actual complete source publishes original tree policy');
            is($helper->get_attribute('signal_role'), 'INTERNAL_INTERMEDIATE', 'publication follows canonical classification');
            is($json->encode($raw), $before, 'caller source AST and JSON kinds preserve');
            if (my $copy=$helper->source_bitwise_tree_width_allocation) {
                $copy->{expression_tree}[1][1][1]='FOREIGN';
                is_deeply($helper->source_bitwise_tree_width_allocation,$expected,'published nested policy detaches');
            }
            $adapter->{signal_manager}->register_signal('C',width=>$width);
            ok(!defined($helper->source_bitwise_tree_width_allocation), 'post-publication same-value third leaf write still revokes');
        }
    }
};

my $publisher = FSM::CoreAST::Signal->can('_publish_staged_source_bitwise_tree_width_allocation');
subtest 'direct Parser success publishes and failed reuse clears old or partial state' => sub {
    plan skip_all => 'completed source-tree publisher absent' unless $publisher;
    my $adapter=FSM::Adapter::FSMGenFull->new;my $text=source(8);
    $adapter->{parser}->parse_fsm(scalar Lispish::multi(\$text));
    my ($helper)=policies($adapter);
    ok($helper,'direct Parser owns source tree publication');
    ok(!defined($helper->get_attribute('signal_role')),'direct Parser retains its existing role boundary');
    ok(!eval {$adapter->{parser}->parse_fsm(['?unknown:bad']);1},'malformed direct root refuses');
    ok(!defined($helper->source_bitwise_tree_width_allocation),'previous externally held helper is cleared');
    parse_text($adapter,$text);
    my $bad=$text;$bad=~s/\(-> idle\)/(-> missing)/;
    ok(!eval {parse_text($adapter,$bad);1},'actual transition validation fails after birth');
    like($@,qr/missing|transition/i,'actual source diagnostic survives');
    is(scalar(policies($adapter)),0,'no previous or partial source-tree policy survives');
    parse_text($adapter,$text);
    is(scalar(policies($adapter)),1,'fresh retry publishes only its current tree');
};

subtest 'facade role and interface failures never expose premature source tree policy' => sub {
    plan skip_all => 'completed source-tree publisher absent' unless $publisher;
    for my $phase ('analyze_signal_roles','generate_fsm_interface') {
        my $adapter=FSM::Adapter::FSMGenFull->new;parse_text($adapter,source(8));
        my @previous=policies($adapter);my $inside;
        {
            no warnings 'redefine';no strict 'refs';
            local *{"FSM::Adapter::FSMGenFull::SignalAnalyzer::$phase"}=sub {
                $inside=scalar policies($adapter);die "late $phase refusal\n";
            };
            ok(!eval {parse_text($adapter,source(8));1},'actual late facade phase refuses');
            like($@,qr/late \Q$phase\E refusal/,'original late-phase error survives');
        }
        is($inside,0,'Parser under facade defers source-tree publication through late phases');
        is(scalar(policies($adapter)),0,'late failure clears current source-tree policies');
        ok(!(grep {defined($_->source_bitwise_tree_width_allocation)} @previous),'caller-held previous policies stay cleared');
        ok(!exists($adapter->{expression_builder}{_source_bitwise_tree_width_allocation_capture}),'failed facade drops tree journal');
        parse_text($adapter,source(8));
        is(scalar(policies($adapter)),1,'same adapter fresh retry recovers');
    }
};

subtest 'publication failure clears a genuinely installed partial source tree policy' => sub {
    plan skip_all => 'completed source-tree publisher absent' unless $publisher;
    for my $direct (0,1) {
        my $adapter=FSM::Adapter::FSMGenFull->new;my $inside;
        {
            no warnings 'redefine';
            local *FSM::CoreAST::Signal::_publish_staged_source_bitwise_tree_width_allocation=sub {
                my $self=shift;my $returned=$publisher->($self,@_);
                $inside=scalar policies($adapter);die "tree publication failure\n";
            };
            my $text=source(8);
            ok(!eval {$direct ? $adapter->{parser}->parse_fsm(scalar Lispish::multi(\$text)) : parse_text($adapter,$text);1},
                'actual owning transaction propagates publication failure');
            like($@,qr/tree publication failure/,'publisher error survives');
        }
        is($inside,1,'failure occurs after an actual installed source-tree record');
        is(scalar(policies($adapter)),0,'owning transaction removes the partial record');
        parse_text($adapter,source(8));
        is(scalar(policies($adapter)),1,'retry after partial installation starts fresh');
    }
};

subtest 'current registry is checked at completion and foreign rows cannot borrow birth' => sub {
    plan skip_all => 'completed source-tree publisher absent' unless $publisher;
    my $adapter=FSM::Adapter::FSMGenFull->new;
    my $original=FSM::Adapter::FSMGenFull::ExpressionBuilder->can('_publish_intermediate_width_allocations');
    {
        no warnings 'redefine';
        local *FSM::Adapter::FSMGenFull::ExpressionBuilder::_publish_intermediate_width_allocations=sub {
            my $builder=shift;
            $adapter->{signal_manager}{signal_registry}{C}=FSM::CoreAST::Signal->new(name=>'C',width=>8);
            return $original->($builder,@_);
        };
        parse_text($adapter,source(8));
    }
    is(scalar(policies($adapter)),0,'same-name equal-width foreign registry source withholds completed intent');
    parse_text($adapter,source(8));
    is(scalar(policies($adapter)),1,'fresh actual association restores completed policy');
};

subtest 'publication is revision-neutral across actual dependent source and binary helpers' => sub {
    plan skip_all => 'completed source-tree publisher absent' unless $publisher;
    for my $case (
        ['(& (| A B C) B C)',2,0],
        ['(& (| A B C) B)',1,1],
        ['(& (| A B) B C)',1,1],
        ['(!& A B C)',1,0],
    ) {
        my ($expression,$trees,$binary)=@$case;
        my $adapter=FSM::Adapter::FSMGenFull->new;my @revisions;
        {
            no warnings 'redefine';
            local *FSM::CoreAST::Signal::_publish_staged_source_bitwise_tree_width_allocation=sub {
                my $self=shift;my $before=$self->_intermediate_width_allocation_revision;
                my $returned=$publisher->($self,@_);
                push @revisions,[$before,$self->_intermediate_width_allocation_revision];
                return $returned;
            };
            parse_text($adapter,source(8,$expression));
        }
        is(scalar(policies($adapter)),$trees,'all current dependent source-tree policies survive publication');
        is(scalar(grep {defined($_->intermediate_width_allocation)} helpers($adapter)),$binary,'existing dependent binary policies remain current');
        ok(@revisions && !(grep {$_->[0] != $_->[1]} @revisions),'actual source publication adds no semantic revision');
    }
};

done_testing();
