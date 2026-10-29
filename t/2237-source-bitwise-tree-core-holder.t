use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use FSM::CoreAST;
use FSM::Adapter::FSMGenFull::SignalManager;
use FSM::SourceBitwiseTreeWidthSupport;

my $json = JSON::PP->new->canonical;
sub record {
    my ($width, $operator) = @_; $width //= '8'; $operator //= '&';
    return {kind => 'source_bitwise_tree_operand_max', operator => $operator,
        source_names => [qw(A B C)], selected_width => $width,
        expression_tree => [$operator, [$operator, ['signal','A'], ['signal','B']], ['signal','C']]};
}
sub fixture {
    my ($width, $operator) = @_; $width //= 8; $operator //= '&';
    my $manager = FSM::Adapter::FSMGenFull::SignalManager->new;
    my @sources = map {$manager->register_signal($_, width => $width)} qw(A B C);
    my @refs = map {FSM::CoreAST::SignalRef->new($_)} @sources;
    my $inner = FSM::CoreAST::BinaryOp->new($operator, @refs[0,1]);
    my $ast = FSM::CoreAST::BinaryOp->new($operator, $inner, $refs[2]);
    my $h = $manager->register_signal('H', width => $width, type => 'wire', is_intermediate => 1);
    $h->set_driving_ast($ast);
    return {manager => $manager, sources => \@sources, refs => \@refs, inner => $inner, ast => $ast, h => $h};
}
sub capsule {return $json->decode($json->encode($_[0]{h}{_source_bitwise_tree_width_allocation}))}
sub install {$_[0]{h}->set_source_bitwise_tree_width_allocation($_[1] // record())}

subtest 'explicit current tree intent detaches and ordinary lookup installs nothing' => sub {
    for my $operator ('&','|','^') {
        for my $width (1,8) {
            my $f = fixture($width,$operator); my $h = $f->{h};
            my $keys = join(',',sort keys %$h);
            is($h->source_bitwise_tree_width_allocation, undef, 'matching widths create no tree intent');
            $h->clear_intermediate_width_allocation;
            is(join(',',sort keys %$h), $keys, 'ordinary getter/clear adds no fields');
            my $input = record("$width",$operator); my $before = $json->encode($input);
            is(install($f,$input), $h, 'explicit installation preserves chaining');
            is($json->encode($h->source_bitwise_tree_width_allocation), $before, 'policy preserves complete tree and JSON kinds');
            is($json->encode($input), $before, 'caller policy is unchanged');
            ok(!defined($h->intermediate_width_allocation), 'binary getter does not acquire source tree policy');
            my $copy = $h->source_bitwise_tree_width_allocation;
            $copy->{expression_tree}[1][1][1] = 'FOREIGN';
            is($json->encode($h->source_bitwise_tree_width_allocation), $before, 'returned nested policy detaches');
            $h->set_attribute('debug_label','unrelated');
            is($json->encode($h->source_bitwise_tree_width_allocation), $before, 'unrelated diagnostic data preserves intent');
        }
    }
};

subtest 'actual repeated nodes and leaf slots retain their own identities' => sub {
    my $f = fixture();
    $f->{h}->set_driving_ast(FSM::CoreAST::BinaryOp->new('&',$f->{inner},$f->{inner}));
    my $r = record();
    $r->{source_names} = [qw(A B A B)];
    $r->{expression_tree} = ['&', ['&',['signal','A'],['signal','B']], ['&',['signal','A'],['signal','B']]];
    ok(eval {install($f,$r); 1}, 'shared subtree is not mistaken for a cycle') or diag $@;
    is_deeply($f->{h}->source_bitwise_tree_width_allocation, $r, 'all repeated slots preserve');
    my $mixed = fixture(); $mixed->{ast}{operator} = '|'; $mixed->{inner}{operator} = '^';
    my $m = record(); $m->{operator} = '|'; $m->{expression_tree}[0] = '|'; $m->{expression_tree}[1][0] = '^';
    ok(eval {install($mixed,$m); 1}, 'actual mixed bitwise topology qualifies') or diag $@;
};

subtest 'supported matching-state writes revoke escaped old capsules' => sub {
    for my $write (
        sub {$_[0]{h}->set_driving_ast($_[0]{ast})},
        sub {$_[0]{h}->set_attribute('is_intermediate',1)},
        sub {$_[0]{manager}->register_signal('H',width=>8)},
        sub {$_[0]{manager}->register_signal('C',width=>8)},
        sub {$_[0]{sources}[0]->set_attribute('signal_role','INPUT')},
        sub {$_[0]{h}->add_constraint({kind=>'independent_floor',width=>8})},
    ) {
        my $f = fixture(); install($f); my $old = capsule($f);
        $write->($f);
        ok(!defined($f->{h}->source_bitwise_tree_width_allocation), 'relevant write revokes current intent');
        $f->{h}{_source_bitwise_tree_width_allocation} = $old;
        ok(!defined($f->{h}->source_bitwise_tree_width_allocation), 'escaped previous state cannot revive after write');
    }
};

subtest 'foreign owners and private tree/reference/profile changes withhold' => sub {
    my $f = fixture(); install($f); my $old = capsule($f);
    my $other = fixture(); install($other);
    $other->{h}{_source_bitwise_tree_width_allocation} = $old;
    ok(!defined($other->{h}->source_bitwise_tree_width_allocation), 'equal-width foreign root cannot borrow holder');
    for my $change (
        sub {$_[0]{h}{_width}=9},
        sub {$_[0]{sources}[2]{_width}=9},
        sub {$_[0]{inner}{operator}='|'},
        sub {$_[0]{ast}{operands}[1]=FSM::CoreAST::SignalRef->new($_[0]{sources}[2])},
        sub {$_[0]{sources}[1]{attributes}{signal_role}='INPUT'},
        sub {my $f=shift; $f->{h}{driving_ast}=FSM::CoreAST::BinaryOp->new('&',
            FSM::CoreAST::BinaryOp->new('&',map {FSM::CoreAST::SignalRef->new($_)} @{$f->{sources}}[0,1]),
            FSM::CoreAST::SignalRef->new($f->{sources}[2]))},
        sub {delete $_[0]{sources}[2]{_intermediate_width_allocation_revision}},
    ) {
        my $f = fixture(); install($f); $change->($f);
        ok(!defined($f->{h}->source_bitwise_tree_width_allocation), 'private relevant divergence cannot retain old intent');
    }
};

subtest 'a supported source write during validation cannot escape the final recheck' => sub {
    my $f = fixture();
    install($f);
    my $original = FSM::CoreAST::Signal->can('width');
    my $fired = 0;
    {
        no warnings 'redefine';
        local *FSM::CoreAST::Signal::width = sub {
            my $self = shift;
            if (!$fired && $self == $f->{sources}[2]) {
                $fired = 1;
                $f->{manager}->register_signal('A', width => 8);
            }
            return $original->($self,@_);
        };
        ok(!defined($f->{h}->source_bitwise_tree_width_allocation), 'late matching source write withholds current intent');
    }
    ok($fired,'mutation occurs inside the actual validation read');
};

subtest 'ineligible or malformed replacement clears intent and exact maxima preserve' => sub {
    for my $bad ({}, {%{record()},extra=>1}, {%{record()},selected_width=>9}) {
        my $f=fixture(); install($f);
        ok(!eval {install($f,$bad);1}, 'malformed or incoherent replacement refuses');
        ok(!defined($f->{h}->source_bitwise_tree_width_allocation), 'failed replacement exposes no old policy');
    }
    for my $change (
        sub {$_[0]{h}->set_attribute('width_declared',1)},
        sub {$_[0]{h}->set_attribute('signal_role','OUTPUT')},
        sub {$_[0]{manager}->register_signal('B',signed=>1)},
        sub {$_[0]{manager}->register_signal('B',state_model=>'binary')},
        sub {$_[0]{sources}[2]->add_constraint({kind=>'opaque'})},
        sub {$_[0]{sources}[2]{_intermediate_width_allocation_revision}=[]},
        sub {$_[0]{sources}[2]{_intermediate_width_allocation_revision}=-1},
        sub {$_[0]{ast}{operands}[1]=FSM::CoreAST::SignalRef->new($_[0]{sources}[2],slice=>[0,0])},
        sub {$_[0]{ast}{operands}[1]=FSM::CoreAST::Literal->new('1',width=>8)},
        sub {$_[0]{ast}{operands}[0]=$_[0]{ast}},
        sub {$_[0]{ast}{operands}[1]=FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name=>'A',width=>8))},
    ) {
        my $f=fixture(); $change->($f);
        ok(!eval {install($f);1}, 'unproved typed/source/context profile refuses');
    }
    my $big='18446744073709551617';my $f=fixture($big);
    $f->{manager}->register_signal('A',width=>'18446744073709551616');
    ok(eval {install($f,record($big));1}, 'Core maximum remains exact beyond native precision') or diag $@;
    is_deeply($f->{h}->source_bitwise_tree_width_allocation,record($big),'large decimal kind preserves');
};

subtest 'retained plain holder owns no Core graph and later lifetimes have fresh identities' => sub {
    my $f=fixture();install($f);my $held=capsule($f);
    ok(eval {$json->encode($held);1},'complete private holder remains plain JSON');
    my $old_identity=$json->decode($held->{state})->{signal}{identity_token};
    my ($weak_h,$weak_a)=($f->{h},$f->{sources}[0]);weaken($weak_h);weaken($weak_a);
    $_->{fanout_signals}=[] for @{$f->{sources}}; # independent legacy fanout cycle
    undef $f;
    ok(!defined($weak_h) && !defined($weak_a),'retained holder and weak identity table retain neither owner');
    my $next=fixture();install($next);
    my $new_identity=$json->decode(capsule($next)->{state})->{signal}{identity_token};
    isnt($new_identity,$old_identity,'a later Core lifetime never reuses its old identity token');
};

done_testing();
