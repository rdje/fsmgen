use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
my $json = JSON::PP->new->canonical;
sub source {
    my ($width, $expression, $extra) = @_;
    $expression //= '(& A B)'; $extra //= '';
    return "(?fsm:source_allocation (+params (W $width))"
        ." (+size (A (param W)) (B (param W)) (DATA 1) (OTHER 1) $extra)"
        ." (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
}
sub parse_text {my ($a, $s) = @_; $a->parse_fsm(scalar Lispish::multi(\$s))}
sub policies {
    my ($adapter) = @_;
    return grep {defined($_->intermediate_width_allocation)} values %{$adapter->{signal_manager}{signal_registry}};
}
sub helpers {my ($module) = @_; return grep {$_->get_attribute('is_intermediate')} values %{$module->signals}}
subtest 'complete facade success publishes actual detached birth policy' => sub {
    for my $width (1, 8) {
        for my $op ('&', '|', '^') {
            my $adapter = FSM::Adapter::FSMGenFull->new;
            my $text = source($width, "($op A B)");
            my $raw = scalar Lispish::multi(\$text); my $before = $json->encode($raw);
            my $module = $adapter->parse_fsm($raw); my ($h) = helpers($module);
            my $expected = {kind => 'binary_operand_max', operator => $op, source_names => ['A','B'], selected_width => $width};
            is_deeply($h->intermediate_width_allocation, $expected, 'actual successful facade publishes canonical selected max');
            is($h->get_attribute('signal_role'), 'INTERNAL_INTERMEDIATE', 'publication follows canonical classification');
            is($json->encode($raw), $before, 'caller source AST and JSON kinds preserve');
            if (my $record = $h->intermediate_width_allocation) {$record->{source_names}[0] = 'FOREIGN'}
            is_deeply($h->intermediate_width_allocation, $expected, 'published getter detaches');
            $adapter->{signal_manager}->register_signal('A', width => $width);
            ok(!defined($h->intermediate_width_allocation), 'post-publication matching source write still revokes');
        }
    }
};
subtest 'direct Parser publication, malformed roots and actual validation failures clear old policy' => sub {
    my $adapter = FSM::Adapter::FSMGenFull->new;
    my $text = source(8);
    my $module = $adapter->{parser}->parse_fsm(scalar Lispish::multi(\$text));
    my ($h) = grep {$_->get_attribute('is_intermediate')} values %{$adapter->{signal_manager}{signal_registry}};
    ok($h->intermediate_width_allocation, 'direct Parser owns completed source publication without role classification');
    ok(!defined($h->get_attribute('signal_role')), 'direct Parser role contract stays unchanged');
    ok(!eval {$adapter->{parser}->parse_fsm(['?unknown:bad']); 1}, 'direct malformed root refuses');
    ok(!defined($h->intermediate_width_allocation), 'externally held previous helper loses policy on failed direct reuse');
    parse_text($adapter, $text);
    my $bad = $text; $bad =~ s/\(-> idle\)/(-> missing)/;
    ok(!eval {parse_text($adapter, $bad); 1}, 'actual transition validation fails after helper birth');
    like($@, qr/missing|transition/i, 'actual source validation diagnostic survives');
    is(scalar(policies($adapter)), 0, 'no old or partial policy survives failed source');
    parse_text($adapter, $text);
    ok(scalar(policies($adapter)) > 0, 'fresh retry publishes only current births');
};
subtest 'facade role/interface failures never expose partial policy' => sub {
    for my $phase ('analyze_signal_roles', 'generate_fsm_interface') {
        my $adapter = FSM::Adapter::FSMGenFull->new;
        parse_text($adapter, source(8));
        my @previous = policies($adapter); my $inside;
        {
            no warnings 'redefine'; no strict 'refs';
            local *{"FSM::Adapter::FSMGenFull::SignalAnalyzer::$phase"} = sub {
                $inside = scalar policies($adapter); die "late $phase refusal\n";
            };
            ok(!eval {parse_text($adapter, source(8)); 1}, 'actual facade phase failure refuses');
        }
        is($inside, 0, 'Parser under facade defers publication until all phases finish');
        is(scalar(policies($adapter)), 0, 'facade failure clears all current registry policy');
        ok(!(grep {defined($_->intermediate_width_allocation)} @previous), 'previous caller-held helpers stay cleared');
        ok(!exists($adapter->{expression_builder}{_intermediate_width_allocation_capture}), 'failed facade discards local journal');
        parse_text($adapter, source(8));
        ok(scalar(policies($adapter)) > 0, 'facade retry publishes fresh policy');
    }
};
subtest 'publication failure clears even a record installed earlier in that same transaction' => sub {
    my $original = FSM::CoreAST::Signal->can('_publish_staged_intermediate_width_allocation');
    plan skip_all => 'source completion publisher absent' unless $original;
    for my $direct (0, 1) {
        my $adapter = FSM::Adapter::FSMGenFull->new;
        my $inside;
        {
            no warnings 'redefine';
            local *FSM::CoreAST::Signal::_publish_staged_intermediate_width_allocation = sub {
                my $self = shift; my $returned = $original->($self, @_);
                $inside = scalar policies($adapter); die "publication failure\n";
            };
            my $text = source(8);
            my $ok = eval {
                $direct ? $adapter->{parser}->parse_fsm(scalar Lispish::multi(\$text)) : parse_text($adapter, $text); 1;
            };
            ok(!$ok, 'source publication failure refuses through owning boundary');
            like($@, qr/publication failure/, 'original publisher error survives');
        }
        is($inside, 1, 'injected failure occurs after an actual installed record');
        is(scalar(policies($adapter)), 0, 'failure removes the actual partial record');
        parse_text($adapter, source(8));
        ok(scalar(policies($adapter)) > 0, 'retry after publication failure is fresh');
    }
};
subtest 'whole-reference profiles, nested dependency epochs and opaque names remain distinct' => sub {
    for my $expression ('(& A B A)', '(& A 3)', '(& A[7:0] B)') {
        my $adapter = FSM::Adapter::FSMGenFull->new;
        parse_text($adapter, source(8, $expression));
        is(scalar(policies($adapter)), 0, 'n-ary/literal/sliced helper remains unqualified');
    }
    my $nested = FSM::Adapter::FSMGenFull->new;
    parse_text($nested, source(8, '(& (& A B) B)'));
    is(scalar(policies($nested)), 2, 'publishing inner birth does not invalidate a current dependent outer birth');
    my $collision = FSM::Adapter::FSMGenFull->new;
    parse_text($collision, source(8, undef, '(intermediate_and_A_B_1 32)'));
    my $occupied = $collision->{signal_manager}->get_signal('intermediate_and_A_B_1');
    is($occupied->width, 32, 'actual occupied independent floor is preserved');
    ok(!defined($occupied->intermediate_width_allocation), 'authored opaque name borrows no birth policy');
    is(scalar(policies($collision)), 1, 'actual fresh-name successor publishes its own policy');
};
done_testing();
