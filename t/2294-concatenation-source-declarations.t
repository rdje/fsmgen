use strict;
use warnings;
no warnings 'once';
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken refaddr);
use Digest::SHA qw(sha256_hex);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::DirectDeclaredWidthSupport;

my $direct = 'FSM::DirectDeclaredWidthSupport';
my $width = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport';
my $builder = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePreparedBlockSupport';
my $emitter = 'FSM::Backend::VerilogFamily::WidthExpressionEmitter';
my $build = $builder->can('build_prepared_consolidated_intermediate_block');
my $lower_sum = $emitter->can('lower_sum_range');
my $bind = $width->can('_bind_graph_inference_rows');
my $available = $direct->can('prepare_concatenation_declaration');
my $json = JSON::PP->new->canonical;
for my $path ('perl/FSM/DirectDeclaredWidthSupport.pm', 'perl/FSM/DirectConcatenationRangeSupport.pm') {
    next unless -f $path;
    open my $source, '<', $path or die "$path: $!";
    {local $/; diag("loaded $path sha256=" . sha256_hex(<$source>))}
    close $source;
}
sub copy { $json->decode($json->encode($_[0])) }
sub intent {
    my ($ctx, $name, $row, $language, %extra) = @_;
    return $direct->prepare_concatenation_declaration(flattened_dt => $ctx,
        signal_name => $name, signal_info => $row, target_language => $language,
        expression => $row->{rendered_expression}, %extra);
}
sub fixture {
    my (%options) = @_;
    my $backend = $options{backend} // FSM::HDL::FlattenedDT->new;
    my $params = $options{mutable} ? '(+params (W 1) (X 3))' : '';
    my ($a, $b) = $options{mutable} ? ('(param W)', '(param X)') : (1, 3);
    my $text = "(?fsm:concat_declaration $params (+size (A $a) (B $b) (DATA 5) (OTHER 4))"
        . ' (idle (<(concat A (concat B 0b1010) A) (= (DATA 1)))'
        . ' (<(concat B A) (= (OTHER 1))) (-> idle)))';
    my $raw = scalar Lispish::multi(\$text);
    my $before = $json->encode($raw);
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm($raw);
    my (%observed, $block, $weak, $error, $hdl);
    {
        no strict 'refs'; no warnings 'redefine';
        local *{"${width}::_bind_graph_inference_rows"} = sub {
            if ($options{preexisting_cache}) {
                for my $row (values %{$_[1]}) {
                    next unless ref($row->{ast}) eq 'FSM::CoreAST::Concatenation';
                    $row->{rendered_expression} = '{A}';
                    $row->{rendered_expression_source} = 'substituted_ast';
                }
            }
            return $bind->(@_);
        };
        local *{"${builder}::build_prepared_consolidated_intermediate_block"} = sub {
            my $result = $build->(@_);
            $block = $result;
            my $ctx = $_[0]{flattened_dt};
            my $rows = $result->{all_intermediate_signals};
            $weak = $rows; weaken($weak);
            my $owner = $ctx->{backend_sv_intermediate_width_support};
            for my $name (sort keys %$rows) {
                next unless ref($rows->{$name}{ast}) eq 'FSM::CoreAST::Concatenation';
                my $row = $rows->{$name};
                my $joined = $owner->factorized_concatenation_sum($name, $row);
                my ($plan, $failure);
                eval {$plan = intent($ctx, $name, $row, $options{language} // 'systemverilog'); 1}
                    or $failure = $@;
                $observed{$name} = {joined => $joined, plan => $plan, failure => $failure,
                    expression => $row->{rendered_expression}};
            }
            $options{prepared}->($ctx, $rows, \%observed) if $options{prepared};
            return $result;
        };
        eval {$hdl = ($options{language} // '') eq 'verilog'
            ? $backend->generate_verilog($module) : $backend->generate_systemverilog($module); 1}
            or $error = $@;
    }
    is($json->encode($raw), $before, 'complete caller input preserves');
    my $p = {backend => $backend, module => $module, observed => \%observed,
        block => $block, weak => $weak, error => $error, hdl => $hdl};
    weaken($p->{weak}) if $p->{weak};
    return $p;
}

subtest 'actual original completed rows supply detached source declaration intent' => sub {
    for my $mutable (0, 1) {
        for my $language (qw(systemverilog verilog)) {
            my $p = fixture(mutable => $mutable, language => $language);
            is(scalar(keys %{$p->{observed}}), 2, 'actual original candidate membership');
            for my $name (sort keys %{$p->{observed}}) {
                my $o = $p->{observed}{$name};
                ok($o->{joined}, 'existing completed sum is current independently of new helper availability');
                ok($o->{plan}, 'actual original completed row has source declaration intent');
                diag($o->{failure}) if !$o->{plan};
                next unless $o->{plan};
                my $plan = $o->{plan};
                is($plan->{kind}, 'concatenation_source_declaration', 'explicit source-only contract');
                is_deeply($plan->{allocation}, $o->{joined}{allocation}, 'original numeric allocation preserves');
                is_deeply($plan->{sum}, $o->{joined}{sum}, 'complete independent source sum preserves');
                is($plan->{target_language}, $language, 'actual target language is independent');
                is($plan->{source_profile}, 'systemverilog', 'original shared source profile preserves');
                is($plan->{expression}, $o->{expression}, 'exact selected original expression binds');
                my $nested = @{$plan->{sum}{terms}} == 4;
                is_deeply($plan->{source_names}, $nested ? [qw(A B A)] : [qw(B A)], 'ordered repeated source slots');
                is($plan->{width}, $nested ? '9' : '4', 'independent source width sum');
                is($plan->{is_vector}, 1, 'result remains packed');
                is($plan->{range_text}, $mutable ? $plan->{sum}{range_text} : undef, 'actual target renderer retains complete sum');
                like($plan->{expression}, qr/\{.*\bA\b.*\}/, 'actual native concatenation expression retained');
                my $owner = $p->{backend}{backend_sv_intermediate_width_support};
                my $row = $p->{block}{all_intermediate_signals}{$name};
                if (!$mutable) {
                    $plan->{sum}{terms}[0]{width} = 99;
                    is_deeply(scalar($owner->factorized_concatenation_sum($name, $row)),
                        $o->{joined}, 'editing detached result changes no source or holder');
                }
            }
            if ($mutable) {
                like($p->{error}, qr/requires proved symbolic sum range/, 'live mutable emission still refuses');
            } else {
                is($p->{error}, undef, 'fixed native generation preserves');
                delete $p->{block};
                ok(!defined($p->{weak}), 'intent results do not retain weak canonical row view');
            }
        }
    }
};

subtest 'source intent requires original completion row language and typed selection' => sub {
    plan skip_all => 'new helper absent' unless $available;
    fixture(mutable => 1, prepared => sub {
        my ($ctx, $rows, $observed) = @_;
        my ($name) = sort keys %$observed;
        my $row = $rows->{$name};
        for my $language (qw(sv v SV VERILOG)) {
            my $plan = intent($ctx, $name, $row, $language);
            is($plan->{target_language}, $language =~ /^(?:v|VERILOG)$/ ? 'verilog' : 'systemverilog', 'canonical target aliases');
        }
        for my $extra ({expression => '{A}'}, {expression => undef}, {expression => []},
            {target_language => 'vhdl'}, {signal_info => {%$row}}, {signal_name => 'foreign'}) {
            ok(!eval {intent($ctx, $name, $row, 'systemverilog', %$extra); 1}, 'missing/foreign/unsupported selected input refuses');
        }
        my $owner = $ctx->{backend_sv_intermediate_width_support};
        for my $field (qw(_width_inference_complete _concatenation_inference_events _concatenation_source_frames)) {
            local $owner->{$field};
            ok(!eval {intent($ctx, $name, $row, 'systemverilog'); 1}, 'missing original completed proof cannot mint intent');
        }
        {
            local $row->{rendered_expression_source} = 'stored_expression';
            ok(!eval {intent($ctx, $name, $row, 'systemverilog'); 1}, 'foreign fallback cache cannot supply typed intent');
        }
        ok(intent($ctx, $name, $row, 'systemverilog'), 'restored original state remains usable');
    });
};

subtest 'preexisting same-tag cache cannot substitute for actual typed rendering' => sub {
    plan skip_all => 'new helper absent' unless $available;
    my $p = fixture(preexisting_cache => 1);
    is(scalar(keys %{$p->{observed}}), 2, 'real original candidates still collect');
    for my $o (values %{$p->{observed}}) {
        ok($o->{joined}, 'original completed numeric/source sum alone does not prove cache provenance');
        is($o->{expression}, '{A}', 'actual cache bypass supplied the adversarial selected expression');
        ok(!$o->{plan}, 'preexisting same-tag wrong expression cannot supply source intent');
    }
};

subtest 'late callbacks cannot replace original equal holders or mutate source state' => sub {
    plan skip_all => 'new helper absent' unless $available;
    for my $mode (qw(event source event_map source_map row width epoch installed_owner early_renderer)) {
        fixture(mutable => 1, prepared => sub {
            my ($ctx, $rows, $observed) = @_;
            my ($name) = sort keys %$observed;
            my $row = $rows->{$name};
            my $owner = $ctx->{backend_sv_intermediate_width_support};
            my $original_renderer = $ctx->{enable_graph_ast_support};
            my $fired = 0;
            my $plan;
            {
                no strict 'refs'; no warnings 'redefine';
                local *{"${emitter}::lower_sum_range"} = sub {
                    my ($class, %args) = @_;
                    my $range = $lower_sum->(@_);
                    my $context = $mode eq 'early_renderer' ? 'Concatenation source sum' : "Concatenation '$name' declaration";
                    if (($args{context} // '') eq $context && !$fired++) {
                        $owner->{_concatenation_inference_events}{$name} = copy($owner->{_concatenation_inference_events}{$name}) if $mode eq 'event';
                        $owner->{_concatenation_source_frames}{$name} = copy($owner->{_concatenation_source_frames}{$name}) if $mode eq 'source';
                        $owner->{_concatenation_inference_events} = {%{$owner->{_concatenation_inference_events}}} if $mode eq 'event_map';
                        $owner->{_concatenation_source_frames} = {%{$owner->{_concatenation_source_frames}}} if $mode eq 'source_map';
                        $rows->{$name} = {%$row} if $mode eq 'row';
                        $ctx->{fsm_module}{signals}{B}{_width} = 17 if $mode eq 'width';
                        ++$owner->{_width_inference_epoch} if $mode eq 'epoch';
                        $ctx->{backend_sv_intermediate_width_support} = {%$owner} if $mode eq 'installed_owner';
                        $ctx->{enable_graph_ast_support} = bless({%$original_renderer}, ref($original_renderer)) if $mode eq 'early_renderer';
                    }
                    return $range;
                };
                eval {$plan = intent($ctx, $name, $row, 'systemverilog'); 1};
            }
            ok($fired, "$mode reaches actual target sum renderer callback");
            ok(!$plan, "$mode late mutation cannot refresh source intent");
            # Restore the installed owner for normal outer failure cleanup.
            $ctx->{backend_sv_intermediate_width_support} = $owner;
            $ctx->{enable_graph_ast_support} = $original_renderer;
        });
    }
};

subtest 'failure reset and clean backend reuse do not retain prior source intent' => sub {
    plan skip_all => 'new helper absent' unless $available;
    my $backend = FSM::HDL::FlattenedDT->new;
    my $failed = fixture(backend => $backend, mutable => 1);
    like($failed->{error}, qr/requires proved symbolic sum range/, 'actual old refusal consumes generation failure');
    for my $name (keys %{$failed->{observed}}) {
        my $row = $failed->{block}{all_intermediate_signals}{$name};
        ok(!eval {intent($backend, $name, $row, 'systemverilog'); 1}, 'failed completed proof cannot be reused');
    }
    my $clean = fixture(backend => $backend);
    is($clean->{error}, undef, 'same backend clean generation recovers');
    ok($_->{plan}, 'clean generation obtains its own original intent') for values %{$clean->{observed}};
};

done_testing();
