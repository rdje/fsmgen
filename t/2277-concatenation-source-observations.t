use strict;
use warnings;
no warnings 'once';
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr weaken);
use Lispish;
use FSM::CoreAST;
use FSM::HDL::ASTFactorization;
use FSM::HDL::FlattenedDT;
use FSM::Adapter::FSMGenFull;
use FSM::ConcatenationSourceObservationSupport;

my $api = 'FSM::ConcatenationSourceObservationSupport';
my $json = JSON::PP->new->canonical;
sub scope {
    my $a = FSM::CoreAST::Signal->new(name => 'A', width => 1);
    my $b = FSM::CoreAST::Signal->new(name => 'B', width => 3);
    my $other = FSM::CoreAST::Signal->new(name => 'OTHER', width => 7);
    my $literal = $_[0] // FSM::CoreAST::Literal->new('7');
    my $ast = FSM::CoreAST::Concatenation->new(
        FSM::CoreAST::SignalRef->new($a), FSM::CoreAST::Concatenation->new(
            FSM::CoreAST::SignalRef->new($b), $literal), FSM::CoreAST::SignalRef->new($a));
    my $factorizer = FSM::HDL::ASTFactorization->new;
    $factorizer->add_ast_expression($ast, $_) for qw(first second);
    my $result = $factorizer->analyze_and_factorize;
    my ($name) = grep { refaddr($result->{intermediate_signals}{$_}{ast}) == refaddr($ast) }
        keys %{$result->{intermediate_signals}};
    return {factorizer => $factorizer, signal_name => $name,
        fsm_module => FSM::CoreAST::FSMModule->new(name => 'source_frame',
            signals => {A => $a, B => $b, OTHER => $other}),
        assignment_analysis => {OTHER => {lhs_ast => FSM::CoreAST::SignalRef->new($other)}}};
}
sub capture { $api->capture(%{$_[0]}) }
sub current { $api->current(%{$_[0]}, holder => $_[1]) }

subtest 'ordered actual Core occurrences and raw literal/declaration fields preserve' => sub {
    my $args = scope();
    my $before = $json->encode($args->{fsm_module}->parameters);
    my $frame = capture($args);
    ok($frame, 'current original allocation supplies a source observation') or return;
    is_deeply($frame->{record}{source_names}, [qw(A B A)], 'duplicate ordered source slots preserve');
    is_deeply($frame->{record}{expression_tree}, ['concat', ['signal','A'],
        ['concat', ['signal','B'], ['literal',{value=>'7',width=>undef,radix=>'decimal'}]], ['signal','A']],
        'nesting and unknown raw literal width preserve independently');
    is($frame->{record}{source_signals}{A}{fields}{_width}, 1, 'raw numeric width one preserves without rank inference');
    is_deeply([sort keys %{$frame->{record}}], [qw(expression_tree kind source_names source_signals)],
        'observation supplies no sum, range or eligibility');
    is_deeply(current($args,$frame),$frame,'unchanged source revalidates exactly');
    my $copy = current($args,$frame);
    $copy->{record}{source_signals}{A}{fields}{_width} = 99;
    is(current($args,$copy),undef,'changed detached record cannot borrow the state');
    is_deeply(current($args,$frame),$frame,'returned nested records are detached');
    my $row = $args->{factorizer}{intermediate_signals}{$args->{signal_name}};
    $row->{width}=100; $row->{width_source}='cached_width';
    is_deeply(current($args,$frame),$frame,'independent candidate numeric selection does not rewrite source observations');
    is($json->encode($args->{fsm_module}->parameters),$before,'caller module maps preserve');
    my $explicit=capture(scope(FSM::CoreAST::Literal->new('0101',width=>4,radix=>'binary')));
    is_deeply($explicit->{record}{expression_tree}[2][2],
        ['literal',{value=>'0101',width=>4,radix=>'binary'}],'explicit literal spelling and width preserve independently');
    for my $change (
        sub {$_[0]{record}{source_signals}{A}{fields}{_width}='1'},
        sub {$_[0]{record}{source_names}=[('A') x 4097]},
        sub {$_[0]{record}{expression_tree}=$_[0]{record}},
        sub {$_[0]{extra}=1},
    ) {
        my $bad=$json->decode($json->encode($frame)); $change->($bad);
        is(current($args,$bad),undef,'changed JSON kind or malformed/unbounded/cyclic holder withholds');
        delete $bad->{record}{expression_tree};
    }
    # Raw unsupported eligibility stays visible; only the next source-proof
    # consumer may reject or establish its semantic meaning.
    $args->{fsm_module}{signals}{A}{signed}=1;
    $args->{fsm_module}{signals}{A}{declared_type_name}='OPAQUE';
    my $raw = capture($args);
    is($raw->{record}{source_signals}{A}{fields}{declared_type_name},'OPAQUE','type remains raw and unqualified');
    ok($raw->{record}{source_signals}{A}{fields}{signed},'signed state remains raw and unqualified');
};

subtest 'complete declaration scope and equal-state replacement revoke stale frames' => sub {
    my @changes = (
        ['operand width', sub {$_[0]{fsm_module}{signals}{A}{_width}=2}],
        ['nonoperand width', sub {$_[0]{fsm_module}{signals}{OTHER}{_width}=8}],
        ['raw revision', sub {$_[0]{fsm_module}{signals}{A}{_intermediate_width_allocation_revision}=1}],
        ['parameter scope', sub {$_[0]{fsm_module}{parameters}{W}={default=>1}}],
        ['equal parameter map', sub {$_[0]{fsm_module}{parameters}={}}],
        ['equal source map', sub {$_[0]{fsm_module}{signals}={%{$_[0]{fsm_module}{signals}}}}],
        ['equal constraints', sub {$_[0]{fsm_module}{signals}{OTHER}{constraints}=[]}],
        ['equal normalized row', sub {$_[0]{assignment_analysis}{OTHER}={%{$_[0]{assignment_analysis}{OTHER}}}}],
        ['equal normalized map', sub {$_[0]{assignment_analysis}={%{$_[0]{assignment_analysis}}}}],
        ['equal actual module', sub {$_[0]{fsm_module}=bless {%{$_[0]{fsm_module}}},'FSM::CoreAST::FSMModule'}],
        ['equal state list', sub {$_[0]{fsm_module}{states}=[]}],
        ['equal birth map', sub {$_[0]{factorizer}{_concatenation_width_births}={%{$_[0]{factorizer}{_concatenation_width_births}}}}],
        ['foreign same-name source', sub {$_[0]{fsm_module}{signals}{A}=FSM::CoreAST::Signal->new(name=>'A',width=>1)}],
        ['literal field', sub {$_[0]{factorizer}{intermediate_signals}{$_[0]{signal_name}}{ast}{operands}[1]{operands}[1]{width}=4}],
    );
    for my $change (@changes) {
        my $args=scope(); my $frame=capture($args);
        ok($frame,'control captured') or next;
        $change->[1]->($args);
        is(current($args,$frame),undef,"$change->[0] revokes the old observation");
        is(current($args,$frame),undef,'revalidation never refreshes stale state');
    }
    my $args=scope(); my $frame=capture($args);
    $args->{fsm_module}{signals}{A}=FSM::CoreAST::Signal->new(name=>'A',width=>1);
    is(capture($args),undef,'fresh capture also refuses foreign actual operand membership');
};

subtest 'raw observation invokes no source getters and withholds hostile data silently' => sub {
    my $args=scope();
    {
        no warnings 'redefine';
        local *FSM::CoreAST::Signal::width=sub {die 'width getter called'};
        local *FSM::CoreAST::Signal::name=sub {die 'name getter called'};
        local *FSM::CoreAST::Signal::declared_width_binding=sub {die 'binding getter called'};
        local *FSM::CoreAST::FSMModule::parameters=sub {die 'parameter getter called'};
        local *FSM::CoreAST::FSMModule::signals=sub {die 'source getter called'};
        local *FSM::CoreAST::SignalRef::signal=sub {die 'reference getter called'};
        local *FSM::CoreAST::Concatenation::operands=sub {die 'operand getter called'};
        my $frame=capture($args);
        ok($frame,'built-in raw observation runs without semantic getters');
        is_deeply(current($args,$frame),$frame,'current barrier also invokes no semantic getter');
    }
    for my $mutate (
        sub {$_[0]{assignment_analysis}=[]},
        sub {$_[0]{fsm_module}{signals}{A}{constraints}={cycle=>undef};
            $_[0]{fsm_module}{signals}{A}{constraints}{cycle}=$_[0]{fsm_module}{signals}{A}{constraints}},
        sub {$_[0]{fsm_module}{signals}{A}{constraints}=[(1)x4097]},
        sub {$_[0]{fsm_module}{signals}{A}{constraints}=bless {},'Local::ForeignDeclaration'},
        sub {bless $_[0]{fsm_module}{signals}{OTHER},'Local::ForeignSignal'},
        sub {bless $_[0]{fsm_module},'Local::ForeignModule'},
    ) {
        my $args=scope(); $mutate->($args);
        my ($value,$error);
        {local $SIG{__WARN__}=sub {die @_}; eval {$value=capture($args);1} or $error=$@;}
        is($error,undef,'unsupported data withholds silently');
        is($value,undef,'malformed cyclic over-bound or subclassed scope supplies no observation');
        delete $args->{fsm_module}{signals}{A}{constraints}; # release deliberate cycle
    }
    my $plain=FSM::HDL::ASTFactorization->new;
    my $keys=[sort keys %$plain];
    $args->{factorizer}=$plain;
    is(capture($args),undef,'a caller-made row without actual birth cannot supply an observation');
    is_deeply([sort keys %$plain],$keys,'lookup installs no tracking state');
    my ($weak_module,$weak_owner,$frame);
    {my $args=scope();$frame=capture($args);$weak_module=$args->{fsm_module};$weak_owner=$args->{factorizer};
        weaken($weak_module);weaken($weak_owner);}
    ok(!defined($weak_module)&&!defined($weak_owner),'retained frame owns no module or factorizer graph');
    ok($frame && $json->encode($frame),'frame stays plain readable JSON data');
};

subtest 'declared metadata and ordered AST limits retain exact admissible boundaries' => sub {
    my $args=scope();
    $args->{fsm_module}{signals}{OTHER}{declared_type_name}='X' x 4096;
    ok(capture($args),'exact raw scalar character boundary remains observable');
    $args->{fsm_module}{signals}{OTHER}{declared_type_name}.='X';
    is(capture($args),undef,'one excess character withholds the complete scope');
    delete $args->{fsm_module}{signals}{OTHER}{declared_type_name};
    my $nested=1; $nested=[$nested] for 1..64;
    $args->{fsm_module}{signals}{OTHER}{constraints}=$nested;
    ok(capture($args),'exact raw-data depth boundary remains observable');
    $args->{fsm_module}{signals}{OTHER}{constraints}=[$nested];
    is(capture($args),undef,'one excess raw-data level withholds');
    $args->{fsm_module}{signals}{OTHER}{constraints}=[];
    my $leaf=FSM::CoreAST::SignalRef->new($args->{fsm_module}{signals}{A});
    my $ast=FSM::CoreAST::Concatenation->new(($leaf)x4095);
    my $owner=FSM::HDL::ASTFactorization->new;
    $owner->add_ast_expression($ast,$_) for qw(first second);
    my $rows=$owner->analyze_and_factorize->{intermediate_signals};
    my ($name)=grep {refaddr($rows->{$_}{ast})==refaddr($ast)} keys %$rows;
    @{$args}{qw(factorizer signal_name)}=($owner,$name);
    my $frame=capture($args);
    is(scalar(@{$frame->{record}{source_names}}),4095,'exact AST occurrence budget preserves every repeated slot');
    is_deeply(current($args,$frame),$frame,'bounded current comparison preserves the complete large record');
    push @{$ast->{operands}},$leaf;
    is(capture($args),undef,'one excess ordered occurrence withholds without partial data');
};

subtest 'actual guard frames and inline RHS retain their native producer boundaries' => sub {
    my $collect=\&FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals;
    for my $rhs (0,1) {
        for my $mutable (0,1) {
            my $params=$mutable?'(+params (W 1))':'';
            my $width=$mutable?'(param W)':'1';
            my $source="(?fsm:source_observe $params (+size (A $width) (B 3) (DATA ".($rhs?5:1).") (OTHER ".($rhs?5:1)."))"
                .($rhs?' (idle (= (DATA (concat A B A))) (= (OTHER (concat A B A))) (-> idle)))'
                    :' (idle (<(concat A B A) (= (DATA 1)) (= (OTHER 1))) (-> idle)))');
            my $raw=scalar Lispish::multi(\$source);
            my $before=$json->encode($raw);
            my $module=FSM::Adapter::FSMGenFull->new->parse_fsm($raw);
            my $backend=FSM::HDL::FlattenedDT->new;
            for my $language (qw(systemverilog verilog)) {
                my @observed;
                no warnings 'redefine';
                local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals=sub {
                    my ($owner,$actual)=@_;my $rows=$collect->(@_);my $ctx=$owner->{flattened_dt};
                    for my $name (sort keys %$rows) {
                        next unless ref($rows->{$name}{ast}) eq 'FSM::CoreAST::Concatenation';
                        my %args=(factorizer=>$ctx->{ast_factorizer},signal_name=>$name,
                            fsm_module=>$actual,assignment_analysis=>$ctx->{assignment_analysis});
                        my $frame=$api->capture(%args);
                        push @observed,$frame;
                        is_deeply($api->current(%args,holder=>$frame),$frame,'actual completed collection observation revalidates');
                    }
                    return $rows;
                };
                my ($hdl,$error);
                eval {$hdl=$language eq 'verilog'?$backend->generate_verilog($module):$backend->generate_systemverilog($module);1} or $error=$@;
                if ($rhs) {is(scalar(@observed),0,'inline RHS profile supplies no factorizer concat allocation')}
                else {ok(@observed,'actual native guard producer exposes concatenation rows')}
                for my $frame (@observed) {
                    ok($frame,'actual Core scope qualifies for raw observation') or next;
                    is_deeply($frame->{record}{source_names},[qw(A B A)],'actual repeated source slots conserve');
                    my $fields=$frame->{record}{source_signals}{A}{fields};
                    is($fields->{_width},1,'actual default width one remains raw');
                    ok($fields->{_declared_width_requirements},'independent actual declaration requirements retain');
                    ok($fields->{_declared_width_binding},'captured source binding retains') if $mutable;
                }
                if ($mutable && !$rhs) {like($error//'',qr/concatenation.*requires proved symbolic sum range/,'source observation grants no mutable sum admission')}
                else {is($error,undef,'fixed native generation preserves');like($hdl//'',qr/\{A, B, A\}/,'fixed full ordered expression preserves')}
                is($json->encode($raw),$before,'complete native caller product preserves');
            }
        }
    }
};
done_testing();
