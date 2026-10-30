use strict;
use warnings;
no warnings 'once';
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr weaken);
use Lispish;
use FSM::CoreAST;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::ASTFactorization;
use FSM::HDL::FlattenedDT;
use FSM::ConcatenationSourceObservationSupport;

my $api = 'FSM::ConcatenationSourceWidthSupport';
unless (eval "require $api; 1" && $api->can('prepare') && $api->can('current')) {
    fail('separate current independent concatenation source contracts exist');
    diag($@) if $@;
    done_testing();
    exit;
}
my $observer = 'FSM::ConcatenationSourceObservationSupport';
my $json = JSON::PP->new->canonical;
sub clone { $json->decode($json->encode($_[0])) }
sub fixture {
    my ($kind, $literal) = @_;
    $kind //= 'mixed';
    my $params = $kind eq 'fixed' ? '' : '(+params (W 1) (X 3))';
    my $a = $kind eq 'fixed' ? '1' : '(param W)';
    my $b = $kind eq 'independent' ? '(param X)' : '3';
    my $text = "(?fsm:concat_sources $params (+size (A $a) (B $b) (OTHER 7)) (idle (<(concat A B A) (= (OTHER 1))) (-> idle)))";
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$text));
    my $ast = FSM::CoreAST::Concatenation->new(
        FSM::CoreAST::SignalRef->new($module->{signals}{A}),
        FSM::CoreAST::Concatenation->new(FSM::CoreAST::SignalRef->new($module->{signals}{B}),
            $literal // FSM::CoreAST::Literal->new('0101', width => 4, radix => 'binary')),
        FSM::CoreAST::SignalRef->new($module->{signals}{A}));
    my $owner = FSM::HDL::ASTFactorization->new;
    $owner->add_ast_expression($ast, $_) for qw(first second);
    my $rows = $owner->analyze_and_factorize->{intermediate_signals};
    my ($name) = grep { refaddr($rows->{$_}{ast}) == refaddr($ast) } keys %$rows;
    my $args = {factorizer => $owner, signal_name => $name, fsm_module => $module,
        assignment_analysis => {}, target_language => 'systemverilog'};
    $args->{observation} = $observer->capture(%$args);
    die 'fixture has no original frame' unless $args->{observation};
    return $args;
}
sub prepare { $api->prepare(%{$_[0]}) }
sub current { $api->current(%{$_[0]}, holder => $_[1]) }
sub refuses {
    my ($args, $pattern, $message) = @_;
    my $ok = eval { prepare($args); 1 };
    ok(!$ok, $message);
    like($@, $pattern, 'contextual refusal identifies the source boundary');
}

subtest 'canonical independent fixed and mutable contracts preserve ordered rank and literal identity' => sub {
    for my $kind (qw(fixed mixed independent)) {
        my $args = fixture($kind);
        my $before = clone($args->{observation});
        my $plan = prepare($args);
        is($plan->{record}{kind}, 'concatenation_source_widths', 'source-only record');
        is_deeply($plan->{record}{source_names}, [qw(A B A)], 'repeated source slots keep their original order');
        is_deeply([map {$_->{width}} @{$plan->{record}{operands}}], [1,3,1], 'independent default widths preserve');
        is_deeply($plan->{record}{expression_tree}[2][2],
            ['literal', {value=>'0101',width=>4,radix=>'binary'}], 'literal fields stay independent of operand contracts');
        my ($a,$b,$again) = @{$plan->{record}{operands}};
        is($a->{is_vector}, $kind eq 'fixed' ? 0 : 1, 'symbolic width one keeps vector rank');
        is($b->{is_vector}, 1, 'independent wider operand keeps vector rank');
        is_deeply($a, $again, 'repeated contracts preserve without deleting duplicate slots');
        if ($kind ne 'fixed') {
            is_deeply($a->{width_plan}{width_contract}{expression}, ['param','W'], 'canonical W relationship retains');
            is_deeply($a->{width_plan}{parameter_references}, ['W'], 'actual parameter selection retains');
        }
        if ($kind eq 'independent') {
            is_deeply($b->{width_plan}{width_contract}{expression}, ['param','X'], 'independent X need not match W');
        } else { is($b->{width_plan}, undef, 'plain fixed declaration has no invented symbolic binding') }
        is_deeply(current($args,$plan), $plan, 'complete current plan revalidates');
        is_deeply($observer->current(%$args,holder=>$before),$before,'preparation preserves complete caller source state');
        $plan->{record}{operands}[0]{width}=99;
        is(current($args,$plan),undef,'changed output cannot borrow the original observation');
        ok(prepare($args),'detached output edit changes no producer');
        for my $language (qw(sv verilog v vhdl)) {
            local $args->{target_language}=$language;
            is(prepare($args)->{record}{target_language}, $language eq 'sv'?'systemverilog':$language eq 'v'?'verilog':$language,
                'canonical target alias and per-source range kernel apply');
        }
    }
    my $args=fixture('fixed',FSM::CoreAST::Literal->new('7'));
    is(prepare($args)->{record}{expression_tree}[2][2][1]{width},undef,'unknown literal width stays unknown; no sum is proved');
    my $plain=fixture('fixed');
    $_->clear_declared_width_requirements for values %{$plain->{fsm_module}{signals}};
    $plain->{observation}=$observer->capture(%$plain);
    ok(prepare($plain),'explicit plain Core widths retain a fixed source contract without parser metadata');
};

subtest 'stale foreign source and unsupported semantic profiles refuse and do not refresh' => sub {
    for my $change (
        ['signed',sub {$_[0]{fsm_module}{signals}{A}{signed}=1}],
        ['state',sub {$_[0]{fsm_module}{signals}{A}{state_model}='foreign'}],
        ['named type',sub {$_[0]{fsm_module}{signals}{A}{declared_type_name}='foreign'}],
        ['type',sub {$_[0]{fsm_module}{signals}{A}{type}='opaque'}],
        ['constraint',sub {$_[0]{fsm_module}{signals}{A}{constraints}=[{kind=>'opaque'}]}],
        ['intermediate',sub {$_[0]{fsm_module}{signals}{A}{attributes}{is_intermediate}=1}],
        ['malformed computed',sub {$_[0]{fsm_module}{signals}{A}{driving_ast}='malformed'}],
        ['computed',sub {$_[0]{fsm_module}{signals}{A}{driving_ast}=FSM::CoreAST::Literal->new('1')}],
    ) {
        my $args=fixture('fixed');my $old=prepare($args);
        $change->[1]->($args);
        is(current($args,$old),undef,"$change->[0] revokes old plan");
        $args->{observation}=$observer->capture(%$args);
        refuses($args,qr/Direct concatenation source|Direct module/,"fresh $change->[0] profile remains unsupported");
    }
    for my $change (
        sub {$_[0]{fsm_module}{signals}{OTHER}{_width}=8},
        sub {$_[0]{fsm_module}{parameters}={%{$_[0]{fsm_module}{parameters}}}},
        sub {$_[0]{fsm_module}{signals}{A}{_intermediate_width_allocation_revision}=10},
        sub {$_[0]{fsm_module}{signals}{OTHER}{driving_ast}='malformed'},
        sub {$_[0]{fsm_module}{signals}{A}=FSM::CoreAST::Signal->new(name=>'A',width=>1)},
    ) {
        my $args=fixture();my $plan=prepare($args);$change->($args);
        refuses($args,qr/original current complete raw observation/,'stale observation refuses before canonical getters');
        is(current($args,$plan),undef,'old plan revalidation withholds');
        is(current($args,$plan),undef,'revalidation never refreshes stale state');
    }
    my $args=fixture('fixed');
    my $s=$args->{fsm_module}{signals}{A};
    my $requirements=$s->declared_width_requirements;
    push @{$requirements->{requirements}}, clone($requirements->{requirements}[0]);
    $s->set_declared_width_requirements($requirements);
    $args->{observation}=$observer->capture(%$args);
    refuses($args,qr/opaque or combined/,'equal selected widths do not excuse combined fixed declarations');
    $requirements->{requirements}=[{%{$requirements->{requirements}[0]},kind=>'generated'}];
    $s->set_declared_width_requirements($requirements);
    $args->{observation}=$observer->capture(%$args);
    refuses($args,qr/unproved fixed declaration/,'unattested generated floor is not a fixed source contract');
};

subtest 'complete raw barriers detect early and late getter mutation including nonoperand declarations' => sub {
    my $width=\&FSM::CoreAST::Signal::width;
    my $name=\&FSM::CoreAST::Signal::name;
    my $binding=\&FSM::CoreAST::Signal::declared_width_binding;
    for my $phase (qw(early canonical late)) {
        my $args=fixture();my $plan=prepare($args);
        my $fired=0;
        my $original_prepare=\&FSM::DirectDeclaredWidthSupport::prepare_module;
        my $inside=0;my $completed=0;
        {
            no warnings 'redefine';
            local *FSM::DirectDeclaredWidthSupport::prepare_module=sub {
                $inside=1;
                my $result=$original_prepare->(@_);$inside=0;$completed=1;return $result;
            };
            local *FSM::CoreAST::Signal::width=sub {
                my ($s)=@_;
                my $hit=$phase eq 'early'?!$inside&&!$completed:$phase eq 'canonical'?$inside:$completed;
                if ($hit && !$fired++) {$args->{fsm_module}{signals}{OTHER}{_width}=8}
                return $width->(@_);
            };
            refuses($args,qr/Direct concatenation source/,'nonoperand getter mutation cannot escape any phase');
        }
        ok($fired,"$phase semantic read was actually exercised");
        is(current($args,$plan),undef,'failed preparation cannot refresh earlier holder');
    }
    for my $getter (qw(name width declared_width_binding)) {
        my $args=fixture();my $called=0;
        {
            no warnings 'redefine';no strict 'refs';
            my $original= $getter eq 'name'?$name:$getter eq 'width'?$width:$binding;
            local *{"FSM::CoreAST::Signal::$getter"}=sub {
                my ($s)=@_;my $v=$original->(@_);
                if ($s->{name} eq 'A') {++$called; return $getter eq 'name'?'B':$getter eq 'width'?2:undef}
                return $v;
            };
            refuses($args,qr/semantic getters disagree/,'a mismatching getter value cannot replace raw source fields');
        }
        ok($called,"$getter positive control fired");
        ok(prepare($args),'read-only refusal permits clean retry after getter recovery');
    }
};

subtest 'detached holder edits and lifetime do not retain live owners' => sub {
    my $args=fixture();my $plan=prepare($args);
    for my $change (
        sub {$_[0]{record}{operands}[0]{width}='1'},
        sub {$_[0]{record}{source_names}=[('A')x4097]},
        sub {$_[0]{record}{expression_tree}=$_[0]{record}},
        sub {$_[0]{observation}{state}.='foreign'},
        sub {$_[0]{extra}=1},
    ) {
        my $bad=clone($plan);$change->($bad);
        is(current($args,$bad),undef,'wrong kinds or malformed cyclic/unbounded output withhold');
        delete $bad->{record}{expression_tree};
    }
    my ($weak_module,$weak_owner,$held);
    {my $args=fixture();$held=prepare($args);$weak_module=$args->{fsm_module};$weak_owner=$args->{factorizer};
        weaken($weak_module);weaken($weak_owner)}
    ok(!defined($weak_module)&&!defined($weak_owner),'prepared contract retains no module or allocator graph');
    ok($json->encode($held),'retained source contract remains plain JSON');
};

subtest 'actual fixed and mutable native guard contracts preserve inline RHS and emitted products' => sub {
    my $collect=\&FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals;
    for my $rhs (0,1) {
        for my $mutable (0,1) {
            my $params=$mutable?'(+params (W 1))':'';
            my $width=$mutable?'(param W)':'1';
            my $source="(?fsm:native_sources $params (+size (A $width) (B 3) (DATA ".($rhs?5:1).") (OTHER ".($rhs?5:1)."))"
                .($rhs?' (idle (= (DATA (concat A B A))) (= (OTHER (concat A B A))) (-> idle)))'
                    :' (idle (<(concat A B A) (= (DATA 1)) (= (OTHER 1))) (-> idle)))');
            my $caller=scalar Lispish::multi(\$source);my $before=$json->encode($caller);
            my $module=FSM::Adapter::FSMGenFull->new->parse_fsm($caller);
            my $backend=FSM::HDL::FlattenedDT->new;
            for my $language (qw(systemverilog verilog)) {
                my @plans;
                no warnings 'redefine';
                local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals=sub {
                    my ($owner,$actual)=@_;my $rows=$collect->(@_);my $ctx=$owner->{flattened_dt};
                    for my $name (sort keys %$rows) {
                        next unless ref($rows->{$name}{ast}) eq 'FSM::CoreAST::Concatenation';
                        my %args=(factorizer=>$ctx->{ast_factorizer},signal_name=>$name,
                            fsm_module=>$actual,assignment_analysis=>$ctx->{assignment_analysis},target_language=>$language);
                        $args{observation}=$observer->capture(%args);
                        my $plan=$api->prepare(%args);push @plans,$plan;
                        is_deeply($api->current(%args,holder=>$plan),$plan,'actual completed collection contracts revalidate');
                    }
                    return $rows;
                };
                my ($hdl,$error);
                eval {$hdl=$language eq 'verilog'?$backend->generate_verilog($module):$backend->generate_systemverilog($module);1} or $error=$@;
                if ($rhs) {is(scalar(@plans),0,'inline RHS exposes no invented candidate producer')}
                else {ok(@plans,'actual native guard allocation yields independent source contracts')}
                for my $plan (@plans) {
                    is_deeply($plan->{record}{source_names},[qw(A B A)],'actual native repeated slots preserve');
                    is($plan->{record}{operands}[0]{is_vector},$mutable?1:0,'actual width-one source rank follows its contract');
                }
                if ($mutable&&!$rhs) {like($error//'',qr/concatenation.*requires proved symbolic sum range/,'source proof grants no mutable sum emission')}
                else {is($error,undef,'existing fixed native generation preserves');like($hdl//'',qr/\{A, B, A\}/,'native expression preserves')}
                is($json->encode($caller),$before,'native caller product preserves');
            }
        }
    }
};
done_testing();
