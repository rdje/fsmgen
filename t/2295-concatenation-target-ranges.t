use strict;
use warnings;
no warnings 'once';
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use Digest::SHA qw(sha256_hex);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::DirectDeclaredWidthSupport;
use FSM::Backend::VerilogFamily::DeclarationCapture;

my $direct = 'FSM::DirectDeclaredWidthSupport';
my $builder = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePreparedBlockSupport';
my $emitter = 'FSM::Backend::VerilogFamily::WidthExpressionEmitter';
my $build = $builder->can('build_prepared_consolidated_intermediate_block');
my $lower_sum = $emitter->can('lower_sum_range');
my $available = $direct->can('prepare_concatenation_intermediate_range');
my $json = JSON::PP->new->canonical;
for my $path ('perl/FSM/DirectDeclaredWidthSupport.pm', 'perl/FSM/DirectConcatenationRangeSupport.pm') {
    open my $source, '<', $path or die "$path: $!";
    {local $/; diag("loaded $path sha256=" . sha256_hex(<$source>))}
    close $source;
}
sub copy { $json->decode($json->encode($_[0])) }
sub prepare {
    my ($ctx, $name, $row, $targets, $language) = @_;
    return $direct->prepare_concatenation_intermediate_range(flattened_dt => $ctx,
        signal_name => $name, signal_info => $row, expression => $row->{rendered_expression},
        target_language => $language // 'systemverilog', %$targets);
}
sub fixture {
    my (%options) = @_;
    my ($a, $b) = $options{mutable} ? ('(param W)', '(param X)') : (1, 3);
    my $text = "(?fsm:concat_target (+params (W 1) (X 3)) (+size (A $a) (B $b) (DATA 5) (OTHER 4))"
        . ' (idle (<(concat A (concat B 0b1010) A) (= (DATA 1)))'
        . ' (<(concat B A) (= (OTHER 1))) (-> idle)))';
    my $raw = scalar Lispish::multi(\$text);
    my $before = $json->encode($raw);
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm($raw);
    my $ctx = $options{backend} // FSM::HDL::FlattenedDT->new;
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my ($block, $error, $hdl);
    {
        no strict 'refs'; no warnings 'redefine';
        local *{"${builder}::build_prepared_consolidated_intermediate_block"} = sub {
            $block = $build->(@_);
            $options{prepared}->($ctx, $block->{all_intermediate_signals}) if $options{prepared};
            return $block;
        };
        local $ctx->{declared_width_declaration_capture} = $capture;
        eval {$hdl = ($options{language} // '') eq 'verilog'
            ? $ctx->generate_verilog($module) : $ctx->generate_systemverilog($module); 1} or $error = $@;
    }
    is($json->encode($raw), $before, 'complete native caller preserves');
    return {ctx => $ctx, block => $block, error => $error, hdl => $hdl,
        targets => $error ? undef : {map {$_ => $capture->snapshot->{$_}} qw(target_namespace target_declarations)}};
}
sub names { sort grep {ref($_[0]{$_}{ast}) eq 'FSM::CoreAST::Concatenation'} keys %{$_[0]} }

# These are actual fixed emission records. The mutable path still refuses
# emission, so it uses proposed target records with the same physical numeric
# declarations, never a claim that mutable HDL already emitted those ranges.
my $native = fixture();
is($native->{error}, undef, 'native fixed target producer completes');
my $targets = $native->{targets};

subtest 'complete independent physical target agrees with original source intent' => sub {
    for my $mutable (0, 1) {
        for my $language (qw(systemverilog verilog)) {
            my $p = fixture(mutable => $mutable, language => $language, prepared => sub {
                my ($ctx, $rows) = @_;
                my @names = names($rows);
                is(scalar(@names), 2, 'actual original candidate membership');
                for my $name (names($rows)) {
                    my $joined = $ctx->{backend_sv_intermediate_width_support}->factorized_concatenation_sum($name, $rows->{$name});
                    ok($joined, 'original completed source sum exists independently of new API');
                    my $before = $json->encode($targets);
                    my $plan = eval {prepare($ctx, $name, $rows->{$name}, $targets, $language)};
                    ok($plan, 'complete physical concatenation target prepares') or diag($@);
                    next unless $plan;
                    my $intent = $direct->prepare_concatenation_declaration(flattened_dt => $ctx,
                        signal_name => $name, signal_info => $rows->{$name}, expression => $rows->{$name}{rendered_expression},
                        target_language => $language);
                    my %root = %$plan; delete @root{qw(operand_targets target_namespace target_declarations)};
                    is_deeply(\%root, $intent, 'independent target root equals complete separate source intent');
                    is_deeply($plan->{operand_targets}, $intent->{source_names}, 'ordered repeated physical operand slots preserve');
                    is($plan->{sum}{terms}[0]{is_vector}, $mutable || $plan->{sum}{terms}[0]{width} > 1 ? 1 : 0,
                        'independent mutable width-one operand retains packed rank');
                    is($json->encode($targets), $before, 'complete target inputs and JSON kinds preserve');
                    my $saved = copy($plan);
                    $plan->{target_declarations}{A}{width} = 91;
                    is_deeply(prepare($ctx, $name, $rows->{$name}, $targets, $language), $saved, 'complete plans detach from callers and original proof');
                    if ($mutable) {
                        my $nested = @{$plan->{sum}{terms}} == 4;
                        for my $values ([1,3], [7,2], [2,11]) {
                            my ($w, $x) = @$values;
                            my $range = $saved->{range_text};
                            $range =~ s/\bW\b/$w/g; $range =~ s/\bX\b/$x/g;
                            $range =~ s/^\[//; $range =~ s/:0\]\s*$//;
                            like($range, qr/\A[0-9+()\s-]+\z/, 'emitted arithmetic has only explicit independent width terms');
                            my $actual = eval $range;
                            is($actual + 1, $nested ? 2*$w+$x+4 : $w+$x,
                                'independently interpreted range follows original source-slot weights under overrides');
                        }
                    }
                }
            });
            $mutable ? like($p->{error}, qr/requires proved symbolic sum range/, 'live mutable emitter remains separately refused')
                : is($p->{error}, undef, 'native fixed generation preserves');
        }
    }
};

subtest 'complete namespace and each selected declaration require independent agreement' => sub {
    plan skip_all => 'new helper absent' unless $available;
    fixture(mutable => 1, prepared => sub {
        my ($ctx, $rows) = @_;
        my ($name) = names($rows);
        my $wrong = copy($targets);
        ++$wrong->{target_declarations}{$name}{width};
        ok(!eval {prepare($ctx, $name, $rows->{$name}, $wrong); 1},
            'wrong result width cannot use a correct source sum');
        my @changes = (
            sub {$_[0]{target_namespace}{module_name} = 'foreign'},
            sub {push @{$_[0]{target_namespace}{constants}}, 'A'},
            sub {pop @{$_[0]{target_namespace}{parameter_names}}},
            sub {$_[0]{target_namespace}{identifier_map}{A} = 'B'},
            sub {$_[0]{target_namespace}{identifier_map}{$name} = 'foreign'},
            sub {my $t = shift; @{$t->{target_namespace}{signals}} = grep {$_ ne $name} @{$t->{target_namespace}{signals}};
                push @{$t->{target_namespace}{ports}}, $name},
            sub {delete $_[0]{target_declarations}{OTHER}},
            sub {$_[0]{target_declarations}{$name}{width}++},
            sub {$_[0]{target_declarations}{A}{width}++},
            sub {$_[0]{target_declarations}{A}{signed} = 1},
            sub {$_[0]{target_declarations}{$name}{signed} = 1},
            sub {$_[0]{target_declarations}{A}{state_model} = 'state'},
            sub {$_[0]{target_declarations}{$name}{declared_type_name} = 'foreign_type'},
            sub {$_[0]{target_declarations}{$name}{width_origin} = {kind => 'register_next', source_name => 'A'}},
            sub {$_[0]{target_namespace}{signals} = []},
            sub {$_[0]{target_namespace}{extra} = bless({}, 'HostileTarget')},
            sub {$_[0]{target_namespace}{extra} = $_[0]{target_namespace}},
            sub {$_[0]{target_namespace}{extra} = [1 .. 4097]},
        );
        for my $change (@changes) {
            my $t = copy($targets); $change->($t);
            ok(!eval {prepare($ctx, $name, $rows->{$name}, $t); 1}, 'incoherent complete physical target refuses');
            ok(length($@), 'refusal has a diagnostic');
        }
        ok(prepare($ctx, $name, $rows->{$name}, $targets), 'unchanged original proof remains usable');
    });
};

subtest 'final callbacks cannot hide changed physical identities or source holders behind equal ranges' => sub {
    plan skip_all => 'new helper absent' unless $available;
    for my $mode (qw(target_value target_identity operand_identity namespace_identity event_identity source_identity
        row source_width owner renderer)) {
        fixture(mutable => 1, prepared => sub {
            my ($ctx, $rows) = @_;
            my ($name) = names($rows);
            my $t = copy($targets);
            my $owner = $ctx->{backend_sv_intermediate_width_support};
            my $renderer = $ctx->{enable_graph_ast_support};
            my ($reads, $fired, $result) = (0, 0);
            {
                no strict 'refs'; no warnings 'redefine';
                local *{"${emitter}::lower_sum_range"} = sub {
                    my ($class, %args) = @_;
                    my $range = $lower_sum->(@_);
                    if (($args{context} // '') eq "Concatenation '$name' physical target" && ++$reads == 2) {
                        ++$fired;
                        $t->{target_declarations}{OTHER}{extra} = JSON::PP::true if $mode eq 'target_value';
                        $t->{target_declarations}{$name} = copy($t->{target_declarations}{$name}) if $mode eq 'target_identity';
                        $t->{target_declarations}{A} = copy($t->{target_declarations}{A}) if $mode eq 'operand_identity';
                        $t->{target_namespace}{signals} = [@{$t->{target_namespace}{signals}}] if $mode eq 'namespace_identity';
                        $owner->{_concatenation_inference_events}{$name} = copy($owner->{_concatenation_inference_events}{$name}) if $mode eq 'event_identity';
                        $owner->{_concatenation_source_frames}{$name} = copy($owner->{_concatenation_source_frames}{$name}) if $mode eq 'source_identity';
                        $rows->{$name} = {%{$rows->{$name}}} if $mode eq 'row';
                        $ctx->{fsm_module}{signals}{A}{_width} = 19 if $mode eq 'source_width';
                        $ctx->{backend_sv_intermediate_width_support} = {%$owner} if $mode eq 'owner';
                        $ctx->{enable_graph_ast_support} = bless({%$renderer}, ref($renderer)) if $mode eq 'renderer';
                    }
                    return $range;
                };
                $result = eval {prepare($ctx, $name, $rows->{$name}, $t)};
            }
            is($fired, 1, "$mode reaches final physical target callback");
            ok(!$result, "$mode final mutation refuses equal target ranges");
            $ctx->{backend_sv_intermediate_width_support} = $owner;
            $ctx->{enable_graph_ast_support} = $renderer;
        });
    }
};

subtest 'detached plans retain no canonical row view and failed proof cannot survive clean reuse' => sub {
    plan skip_all => 'new helper absent' unless $available;
    my ($plan, $weak);
    my $p = fixture(prepared => sub {
        my ($ctx, $rows) = @_;
        $weak = $rows; weaken($weak);
        my ($name) = names($rows);
        $plan = prepare($ctx, $name, $rows->{$name}, $targets);
    });
    ok($plan, 'actual fixed plan prepares');
    delete $p->{block};
    ok(!defined($weak), 'retained detached plan owns no canonical row view');
    my ($failed_name, $failed_row);
    my $failed = fixture(backend => $p->{ctx}, mutable => 1, prepared => sub {
        my ($ctx, $rows) = @_;
        ($failed_name) = names($rows); $failed_row = $rows->{$failed_name};
        ok(prepare($ctx, $failed_name, $failed_row, $targets), 'new epoch has independent current target plan');
    });
    like($failed->{error}, qr/requires proved symbolic sum range/, 'actual separate emitter refusal clears proof');
    ok(!eval {prepare($failed->{ctx}, $failed_name, $failed_row, $targets); 1}, 'failed original completed proof cannot be revived');
    my $clean = fixture(backend => $p->{ctx});
    is($clean->{error}, undef, 'same backend clean native generation recovers');
};

done_testing();
