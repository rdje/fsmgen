use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::AST::Node;
use FSM::Backend::VerilogFamily::DeclarationCapture;
my $json=JSON::PP->new->canonical;
sub origin {return {kind=>'binary_arithmetic',operator=>$_[0]//'+',source_names=>$_[1]//['A','B']}}
sub policy {return {kind=>'binary_operand_max',operator=>'+',source_names=>['A','B'],selected_width=>8}}
sub binary {return FSM::AST::BinaryOp->new($_[0]//'+',FSM::AST::SignalRef->new('A'),FSM::AST::SignalRef->new('B'))}
sub row {return {name=>$_[0],width=>$_[1]//8,signed=>0}}
sub prepared {
    my($info,%options)=@_;my $ctx=FSM::HDL::FlattenedDT->new;my $capture=FSM::Backend::VerilogFamily::DeclarationCapture->new;
    $capture->begin_module('prepared');$capture->record_declaration('ports',row('A',8));$capture->record_declaration('ports',row('B',4));
    $ctx->{backend_sv_intermediate_recovery_support}=$options{recovery} if $options{recovery};
    local $ctx->{declared_width_declaration_capture}=$capture;
    my $block={sorted_signals=>['RESULT'],filtered_signals=>{RESULT=>$info}};
    my $hdl=$ctx->{backend_sv_consolidated_intermediate_declaration_support}->render_consolidated_intermediate_declarations($block);
    $hdl.=$ctx->{backend_sv_consolidated_intermediate_assignment_support}->render_consolidated_intermediate_assignments($block);
    $capture->complete;return($hdl,$capture->snapshot);
}
sub fixture {
    my(%options)=@_;my $source='(?fsm:arithmetic_events (+params (W 8)) (+size (A (param W)) (B (param W)) (DATA 1) (OTHER 1)) (idle (<(+ A B) (= (DATA 1)) (= (OTHER 1))) (-> idle)))';
    my $module=FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$source));
    my $ctx=FSM::HDL::FlattenedDT->new;my $capture=FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $collect_class='FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport';my $collect=$collect_class->can('collect_consolidated_intermediate_signals');
    my $width_class='FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport';my $lookup=$width_class->can('intermediate_width_allocation');
    my($name,$all,$changed,$hdl);
    {
        no warnings 'redefine';no strict 'refs';
        local *{"${collect_class}::collect_consolidated_intermediate_signals"}=sub {
            $all=$collect->(@_);($name)=grep {my $ast=$all->{$_}{ast};$ast && $ast->can('operator') && $ast->operator eq '+'} keys %$all;
            $options{collected}->($ctx,$name,$all) if $options{collected};return $all;
        };
        local *{"${width_class}::intermediate_width_allocation"}=sub {
            my $record=$lookup->(@_);
            if ($record && $options{during_lookup} && !$changed++) {$options{during_lookup}->($ctx)}
            return $record;
        };
        local $ctx->{declared_width_declaration_capture}=$capture;
        $hdl=$ctx->generate_systemverilog($module);
    }
    return {ctx=>$ctx,module=>$module,capture=>$capture,name=>$name,info=>$all->{$name},hdl=>$hdl,snapshot=>$capture->snapshot,changed=>$changed};
}
subtest 'actual selected arithmetic event joins current origin and policy for range consumption' => sub {
    my $p=fixture();my $name=$p->{name};
    is_deeply($p->{snapshot}{target_intermediates}{$name},{expression=>'A + B',arithmetic_origin=>origin(),width_allocation=>policy()},'actual emitter captures closed ordered origin and current allocation');
    like($p->{hdl},qr/^  wire \[\(W - 1\):0\] \Q$name\E;$/m,'qualified arithmetic consumer retains the symbolic helper range');
    is($p->{snapshot}{target_declarations}{$name}{width},8,'target event preserves its independently selected numeric width');
    my $copy=$p->{capture}->snapshot;
    $copy->{target_intermediates}{$name}{arithmetic_origin}{source_names}[0]='WRONG' if $copy->{target_intermediates}{$name}{arithmetic_origin};
    isnt($p->{capture}->snapshot->{target_intermediates}{$name}{arithmetic_origin}{source_names}[0]//'absent','WRONG','published target records detach');
    ok(!eval {$p->{ctx}->generate_vhdl($p->{module}); 1},
        'arithmetic target events do not extend symbolic VHDL admission');
    like($@, qr/requires a qualified scalar reduction origin/,
        'the existing scalar VHDL boundary owns the refusal');
};
subtest 'syntactic arithmetic origin preserves independent widths and rejects inconsistent AST/text' => sub {
    my($hdl,$snapshot)=prepared({width=>32,ast=>binary(),runtime_ast=>binary()});
    is_deeply($snapshot->{target_intermediates}{RESULT},{expression=>'A + B',arithmetic_origin=>origin()},'syntactic origin imposes no result-width equivalence');
    like($hdl,qr/wire \[31:0\] RESULT;/,'independent context width remains unchanged');
    for my $info (
        {width=>8,rendered_expression=>'A + B',runtime_ast_resolution_state=>'missing'},
        {width=>8,ast=>binary(),runtime_ast=>binary('-')},
        {width=>8,ast=>binary(),runtime_ast=>binary(),rendered_expression=>'A - B'},
        {width=>1,ast=>binary('=='),runtime_ast=>binary('==')},
        {width=>8,ast=>FSM::AST::BinaryOp->new('+',FSM::AST::SignalRef->new('A'),FSM::AST::Literal->new('3'))},
    ) {
        my($text,$event)=prepared($info);
        ok(!exists($event->{target_intermediates}{RESULT}{arithmetic_origin}),'stored-only, conflicting, scalar and literal shapes supply no arithmetic origin');
    }
    my(undef,$legacy)=prepared({width=>8,ast=>binary()},recovery=>bless({},'Local::OldArithmeticRecovery'));
    is_deeply($legacy->{target_intermediates}{RESULT},{expression=>'A + B'},'old recovery provider keeps its original event contract');
};
subtest 'closed arithmetic schemas and complete membership fail atomically' => sub {
    for my $bad (
        {kind=>'binary_arithmetic',operator=>'&',source_names=>['A','B']},
        {kind=>'binary_bitwise',operator=>'+',source_names=>['A','B']},
        {kind=>'binary_arithmetic',operator=>'+',source_names=>['A']},
        {kind=>'binary_arithmetic',operator=>'+',source_names=>['A','RESULT']},
        {kind=>'binary_arithmetic',operator=>'+',source_names=>['A','B'],extra=>1},
    ) {
        my $c=FSM::Backend::VerilogFamily::DeclarationCapture->new;$c->begin_module('bad');$c->record_intermediate_declaration(row('RESULT'));
        ok(!eval {$c->record_intermediate_assignment('RESULT',{expression=>'A + B',arithmetic_origin=>$bad});1},'malformed arithmetic origin refuses');
        ok(!eval {$c->snapshot;1},'malformed event exposes no completed snapshot');
    }
    for my $event (
        {expression=>'A + B',arithmetic_origin=>origin(),bitwise_origin=>{kind=>'binary_bitwise',operator=>'&',source_names=>['A','B']}},
        {expression=>'A + B',arithmetic_origin=>origin('-', ['A','B']),width_allocation=>policy()},
        {expression=>'A + B',width_allocation=>policy()},
        {expression=>'A + FOREIGN',arithmetic_origin=>origin('+',['A','FOREIGN'])},
    ) {
        my $c=FSM::Backend::VerilogFamily::DeclarationCapture->new;$c->begin_module('bad');$c->record_intermediate_declaration(row('RESULT'));
        $c->record_declaration('ports',row('A'));$c->record_declaration('ports',row('B'));
        ok(!eval {$c->record_intermediate_assignment('RESULT',$event);$c->complete;1},'conflicting/missing actual origin or member refuses');
        ok(!eval {$c->snapshot;1},'failed completion invalidates all events');
    }
};
subtest 'copied or revoked producer state cannot be published as current arithmetic policy' => sub {
    for my $change (
        sub {my($ctx,$name,$all)=@_;$all->{$name}={%{$all->{$name}}}},
        sub {my($ctx,$name,$all)=@_;$all->{$name}{width}=32;$all->{$name}{width_source}='independent'},
    ) {
        my $p=fixture(collected=>$change);
        ok(!exists($p->{snapshot}{target_intermediates}{$p->{name}}{width_allocation}),'copied identity or independent floor has no published policy');
    }
    my $p=fixture(during_lookup=>sub {my $a=$_[0]{fsm_module}->signals->{A};$a->set_attribute('width_declared',$a->get_attribute('width_declared'))});
    ok($p->{changed},'actual arithmetic publication reads current policy');
    ok(!exists($p->{snapshot}{target_intermediates}{$p->{name}}{width_allocation}),'final currentness recheck rejects matching source mutation during publication');
};
{package Local::OldArithmeticRecovery;sub render_intermediate_signal_expression {return 'A + B'}sub scalar_reduction_origin {return}sub binary_bitwise_origin {return}}
done_testing();
