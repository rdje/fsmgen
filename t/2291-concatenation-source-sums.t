use strict;
use warnings;
no warnings 'once';
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr weaken);
use Digest::SHA qw(sha256_hex);
use Lispish;
use FSM::CoreAST;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::ASTFactorization;
use FSM::HDL::FlattenedDT;
use FSM::ConcatenationSourceObservationSupport;
use FSM::ConcatenationSourceWidthSupport;

my $api = 'FSM::ConcatenationSourceWidthSupport';
my $observer = 'FSM::ConcatenationSourceObservationSupport';
my $path = 'perl/FSM/ConcatenationSourceWidthSupport.pm';
open my $source, '<', $path or die "$path: $!";
{local $/; diag('loaded ' . $path . ' sha256=' . sha256_hex(<$source>))}
close $source;
my $json = JSON::PP->new->canonical;
my $available = $api->can('prepare_sum') && $api->can('current_sum');
ok($available, 'separate original current source sum operations exist');
sub clone { $json->decode($json->encode($_[0])) }

sub fixture {
    my ($kind, $literal, $count) = @_;
    $kind //= 'independent';
    my $params = $kind eq 'fixed' ? '' : $kind eq 'equal' ? '(+params (W 1) (X 1))' : '(+params (W 1) (X 3))';
    my $a = $kind eq 'fixed' ? '1' : $kind eq 'arithmetic' ? '(+ (param W) 2)' : '(param W)';
    my $b = $kind =~ /\A(?:independent|arithmetic|equal)\z/ ? '(param X)' : '3';
    my $text = "(?fsm:concat_sum $params (+size (A $a) (B $b) (OTHER 7)) (idle (<(concat A B A) (= (OUT 1))) (<OTHER (= (OUT2 1))) (-> idle)))";
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$text));
    my $ast = $count ? FSM::CoreAST::Concatenation->new(
        map {FSM::CoreAST::SignalRef->new($module->{signals}{A})} 1..$count)
        : FSM::CoreAST::Concatenation->new(
            FSM::CoreAST::SignalRef->new($module->{signals}{A}),
            FSM::CoreAST::Concatenation->new(FSM::CoreAST::SignalRef->new($module->{signals}{B}),
                $literal // FSM::CoreAST::Literal->new('0101', width => 4, radix => 'binary')),
            FSM::CoreAST::SignalRef->new($module->{signals}{A}));
    my $owner = FSM::HDL::ASTFactorization->new;
    $owner->add_ast_expression($ast, $_) for qw(first second);
    my $rows = $owner->analyze_and_factorize->{intermediate_signals};
    my ($name) = grep {refaddr($rows->{$_}{ast}) == refaddr($ast)} keys %$rows;
    my $args = {factorizer => $owner, signal_name => $name, fsm_module => $module,
        assignment_analysis => {}, target_language => 'systemverilog'};
    $args->{observation} = $observer->capture(%$args) or die 'no original observation';
    $args->{holder} = $api->prepare(%$args);
    return $args;
}
sub prepare { $api->prepare_sum(%{$_[0]}) }
sub current { $api->current_sum(%{$_[0]}, holder => $_[1]) }
sub refuses {
    my ($args, $pattern, $message) = @_;
    ok(!eval {prepare($args); 1}, $message);
    like($@, $pattern, 'contextual original-source refusal');
}

# Independent interpretation of emitted syntax; golden widths use the original
# source's explicit two A slots, one B slot and literal size, not result terms.
sub expression {
    my ($tokens, $values) = @_;
    my $token = shift @$tokens;
    die 'missing token' unless defined $token;
    return 0 + $token if $token =~ /^\d+$/;
    return $values->{$token} if exists $values->{$token};
    die 'unexpected token' unless $token eq '(';
    my $left = expression($tokens, $values);
    my $op = shift @$tokens;
    my $right = expression($tokens, $values);
    die 'missing close' unless shift(@$tokens) eq ')';
    return $left + $right if $op eq '+';
    return $left - $right if $op eq '-';
    die 'unexpected operator';
}
sub range_width {
    my ($text, %values) = @_;
    die 'not packed' unless $text =~ /^\[(.*):0\] $/;
    my $body = $1;
    my @tokens = $body =~ /(\d+|[A-Z]\w*|[()+\-])/g;
    (my $compact = $body) =~ s/\s//g;
    die 'unrecognized text' unless join('', @tokens) eq $compact;
    my $width = expression(\@tokens, \%values) + 1;
    die 'unconsumed tokens' if @tokens;
    return $width;
}

subtest 'ordered original source contracts produce independent current sums' => sub {
    plan skip_all => 'source sum operations absent' unless $available;
    for my $kind (qw(fixed mixed independent equal arithmetic)) {
        for my $language (qw(systemverilog sv verilog v)) {
            my $args = fixture($kind);
            $args->{target_language} = $language;
            $args->{holder} = $api->prepare(%$args);
            my $before = $json->encode($args->{holder});
            my $sum = prepare($args);
            my $record = $sum->{record};
            is($record->{kind}, 'concatenation_source_sum', 'separate source sum identity');
            is($record->{width}, $kind eq 'arithmetic' ? '13' : $kind eq 'equal' ? '7' : '9', 'exact selected decimal-string sum');
            is_deeply([map {$_->{kind}} @{$record->{terms}}], [qw(signal signal literal signal)], 'nested tree flattens in original order');
            is_deeply([map {$_->{name}} grep {$_->{kind} eq 'signal'} @{$record->{terms}}], [qw(A B A)], 'repeated source slots preserve');
            is_deeply($record->{terms}[2]{literal}, {value=>'0101',width=>4,radix=>'binary'}, 'complete literal fields preserve');
            is($record->{terms}[0]{is_vector}, $kind eq 'fixed' ? 0 : 1, 'width-one operand retains its independent vector rank');
            is($record->{is_vector}, 1, 'concat result is packed');
            if ($kind eq 'fixed') {
                is($record->{profile}, 'fixed', 'fixed source sum');
                is($record->{range_text}, undef, 'fixed sum grants no generic range');
            } else {
                is($record->{profile}, 'symbolic', 'mutable source sum');
                for my $override ([1,1], [2,7], [16,1], [4,256]) {
                    my ($w,$x) = @$override;
                    my $want = 2 * ($kind eq 'arithmetic' ? $w+2 : $w) + ($kind eq 'mixed' ? 3 : $x) + 4;
                    is(range_width($record->{range_text}, W=>$w, X=>$x), $want, 'actual syntax follows independent source-slot oracle');
                }
            }
            is_deeply(current($args,$sum), $sum, 'complete original sum revalidates');
            is($json->encode($args->{holder}), $before, 'all original source holder bytes and kinds conserve');
            is_deeply($observer->current(%$args,holder=>$args->{observation}), $args->{observation}, 'complete live source raw state conserves');
        }
    }
    for my $radix (qw(binary decimal hex octal)) {
        my $args = fixture('independent',FSM::CoreAST::Literal->new('1',width=>'04',radix=>$radix));
        my $sum = prepare($args);
        is_deeply($sum->{record}{terms}[2]{literal},{value=>'1',width=>'04',radix=>$radix}, 'raw literal fields and scalar kinds preserve independently');
        is($sum->{record}{terms}[2]{width}, '4', 'separate positive decimal term width normalizes leading zeros');
        is_deeply(current($args,$sum),$sum,'literal normalization never changes original holder');
    }
    my $plain = fixture('fixed');
    $_->clear_declared_width_requirements for values %{$plain->{fsm_module}{signals}};
    $plain->{observation} = $observer->capture(%$plain);
    $plain->{holder} = $api->prepare(%$plain);
    is(prepare($plain)->{record}{width},'9','plain fixed Core widths need no invented parameter environment');
    my $args = fixture('independent',undef,32);
    is(range_width(prepare($args)->{record}{range_text}, W=>7),224,'bounded repeated original slots all contribute');
    refuses(fixture('independent',undef,33),qr/32 ordered width terms/,'over-bound original source arity refuses');
    refuses(fixture('fixed',FSM::CoreAST::Literal->new('7')),qr/explicit positive literal width/,'unknown literal width is not an invented target default');
    $args=fixture();$args->{target_language}='vhdl';$args->{holder}=$api->prepare(%$args);
    refuses($args,qr/Verilog-family/,'VHDL sum adaptation stays separately owned');
};

subtest 'stale foreign and changed source or sum holders cannot refresh' => sub {
    plan skip_all => 'source sum operations absent' unless $available;
    for my $change (
        sub {$_[0]{fsm_module}{signals}{OTHER}{_width}=8},
        sub {$_[0]{fsm_module}{parameters}={%{$_[0]{fsm_module}{parameters}}}},
        sub {$_[0]{fsm_module}{signals}{A}{_intermediate_width_allocation_revision}=10},
        sub {$_[0]{fsm_module}{signals}{A}{signed}=1},
        sub {$_[0]{fsm_module}{signals}{A}{declared_type_name}='foreign'},
        sub {$_[0]{fsm_module}{signals}{A}{constraints}=[{kind=>'opaque'}]},
        sub {$_[0]{fsm_module}{signals}{A}=FSM::CoreAST::Signal->new(name=>'A',width=>1)},
    ) {
        my $args=fixture();my $sum=prepare($args);$change->($args);
        refuses($args,qr/original current independent source holder/,'stale source observation cannot be recaptured');
        is(current($args,$sum),undef,'original sum revokes after complete-scope change');
        is(current($args,$sum),undef,'repeated revalidation never refreshes stale state');
    }
    my $args=fixture();my $sum=prepare($args);
    for my $change (
        sub {$_[0]{record}{width}=9},
        sub {pop @{$_[0]{record}{terms}}},
        sub {$_[0]{record}{range_text}='[(W - 1):0] '},
        sub {$_[0]{sources}{record}{operands}[0]{width}=99},
        sub {$_[0]{sources}{observation}{state}.='foreign'},
        sub {$_[0]{extra}=1},
        sub {$_[0]{record}{terms}=$_[0]},
    ) {
        my $bad=clone($sum);$change->($bad);
        is(current($args,$bad),undef,'changed detached result including kinds or cycles withholds');
    }
    my $foreign=fixture();
    is(current($foreign,$sum),undef,'equal-valued foreign module/allocator cannot borrow a sum');
    is_deeply(current($args,$sum),$sum,'read-only hostile holder checks permit clean recovery');
};

subtest 'late environment getters cannot change earlier sources or hide raw divergence' => sub {
    plan skip_all => 'source sum operations absent' unless $available;
    my $proof=\&FSM::ParameterDefaultEnvironmentSupport::prove_binding_observations;
    my $getter=\&FSM::CoreAST::Signal::width;
    for my $mode (qw(nonoperand parameter getter_lie)) {
        my $args=fixture();my $sum=prepare($args);my $calls=0;my $fired=0;my $late=0;
        is(ref($args->{fsm_module}{signals}{OTHER}),'FSM::CoreAST::Signal','late control starts with an actual nonoperand declaration');
        {
            no warnings 'redefine';
            local *FSM::ParameterDefaultEnvironmentSupport::prove_binding_observations=sub {
                my $result=$proof->(@_);
                # First invocation is source revalidation; second is the sum's
                # own environment proof after it has accepted the original holder.
                if (++$calls==2) {
                    $fired=1;
                    $args->{fsm_module}{signals}{OTHER}{_width}=8 if $mode eq 'nonoperand';
                    $args->{fsm_module}{parameters}{W}{value_payload}{payload}='2' if $mode eq 'parameter';
                    $late=1;
                }
                return $result;
            };
            local *FSM::CoreAST::Signal::width=sub {
                my ($signal)=@_;
                return 2 if $late && $mode eq 'getter_lie' && $signal->{name} eq 'A';
                return $getter->(@_);
            };
            refuses($args,qr/Direct concatenation source/,'late source/environment read cannot bless inconsistent scope');
        }
        ok($fired,'actual second canonical environment proof was exercised');
        if ($mode eq 'getter_lie') {is_deeply(current($args,$sum),$sum,'getter-only refusal recovers after original implementation returns')}
        else {is(current($args,$sum),undef,'persistent mutation revokes the original sum')}
    }
    my $args=fixture();my $sum=prepare($args);my $fired=0;
    my $render=\&FSM::Backend::VerilogFamily::WidthExpressionEmitter::lower_sum_range;
    {
        no warnings 'redefine';
        local *FSM::Backend::VerilogFamily::WidthExpressionEmitter::lower_sum_range=sub {
            my $result=$render->(@_);
            $args->{fsm_module}{signals}{OTHER}{_width}=8;
            $fired=1;
            return $result;
        };
        refuses($args,qr/original current complete raw observation/,'final raw barrier rejects a late render callback mutation');
    }
    ok($fired,'actual prepared-sum rendering callback was exercised');
    is(current($args,$sum),undef,'late raw change cannot retain the old sum');
};

subtest 'actual native guard source sums and detached lifetime preserve backend boundary' => sub {
    plan skip_all => 'source sum operations absent' unless $available;
    my $collect=\&FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals;
    for my $mutable (0,1) {
        my $params=$mutable?'(+params (W 1) (X 3))':'';
        my ($a,$b)=$mutable?('(param W)','(param X)'):(1,3);
        my $text="(?fsm:native_sum $params (+size (A $a) (B $b) (DATA 1)) (idle (<(concat A B A) (= (DATA 1))) (-> idle)))";
        my $caller=scalar Lispish::multi(\$text);my $before=$json->encode($caller);
        my $module=FSM::Adapter::FSMGenFull->new->parse_fsm($caller);
        for my $language (qw(systemverilog verilog)) {
            my @sums;
            no warnings 'redefine';
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals=sub {
                my ($owner,$actual)=@_;my $rows=$collect->(@_);my $ctx=$owner->{flattened_dt};
                for my $name (sort keys %$rows) {
                    next unless ref($rows->{$name}{ast}) eq 'FSM::CoreAST::Concatenation';
                    my %args=(factorizer=>$ctx->{ast_factorizer},signal_name=>$name,fsm_module=>$actual,
                        assignment_analysis=>$ctx->{assignment_analysis},target_language=>$language);
                    $args{observation}=$observer->capture(%args);
                    $args{holder}=$api->prepare(%args);
                    push @sums,$api->prepare_sum(%args);
                }
                return $rows;
            };
            my $backend=FSM::HDL::FlattenedDT->new;my ($hdl,$error);
            eval {$hdl=$language eq 'verilog'?$backend->generate_verilog($module):$backend->generate_systemverilog($module);1} or $error=$@;
            ok(@sums,'actual guard source sum is observed at native collection');
            for my $sum (@sums) {
                is($sum->{record}{width},'5','actual native ordered source sum');
                is(range_width($sum->{record}{range_text},W=>2,X=>7),11,'actual native independent source ranges retain') if $mutable;
            }
            if ($mutable) {like($error,qr/requires proved symbolic sum range/,'source-only sum grants no target emission authority')}
            else {ok(defined($hdl)&&!$error,'fixed numeric generation remains supported')}
            is($json->encode($caller),$before,'whole native caller source preserves');
        }
    }
    my ($weak_module,$weak_owner,$held);
    {my $args=fixture();$held=prepare($args);$weak_module=$args->{fsm_module};$weak_owner=$args->{factorizer};
        weaken($weak_module);weaken($weak_owner)}
    ok(!defined($weak_module)&&!defined($weak_owner),'source sum retains no module or allocator owner');
    ok($json->encode($held),'escaped source sum remains plain JSON');
};

done_testing();
