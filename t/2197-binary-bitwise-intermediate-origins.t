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

my $json = JSON::PP->new->canonical;
sub row {{name=>$_[0],width=>$_[1] // 8,signed=>0}}
sub binary {FSM::AST::BinaryOp->new($_[0],FSM::AST::SignalRef->new($_[1] // 'A'),FSM::AST::SignalRef->new($_[2] // 'B'))}
sub origin {{kind=>'binary_bitwise',operator=>$_[0] // '&',source_names=>$_[1] // ['A','B']}}
sub normalized {my ($text)=@_;$text =~ s{^// Date:.*$}{// Date: <time>}mg;$text}
sub prepared {
    my ($info) = @_;
    my $dt=FSM::HDL::FlattenedDT->new(debug=>0);my $capture=FSM::Backend::VerilogFamily::DeclarationCapture->new;
    $capture->begin_module('prepared');$capture->record_declaration('ports',row('A'));$capture->record_declaration('ports',row('B'));
    local $dt->{declared_width_declaration_capture}=$capture;
    my $block={sorted_signals=>['unrelated_name'],filtered_signals=>{unrelated_name=>$info}};
    my $hdl=$dt->{backend_sv_consolidated_intermediate_declaration_support}->render_consolidated_intermediate_declarations($block);
    $hdl.=$dt->{backend_sv_consolidated_intermediate_assignment_support}->render_consolidated_intermediate_assignments($block);
    $capture->complete;return ($hdl,$capture->snapshot);
}

subtest 'actual source declarations and assignments capture both ordered operands without changing HDL' => sub {
    for my $width (1,8) {
        for my $op ('&','|','^') {
            my $source="(?fsm:binary_origins (+params (W $width)) (+size (A (param W)) (B (param W)) (DATA 1) (OTHER 1))"
                ." (idle (<($op A B) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
            my $module=FSM::Adapter::FSMGenFull->new(debug=>0)->parse_fsm(scalar Lispish::multi(\$source));
            my $before=$json->encode([$module->parameters,$module->parameter_default_sources,$module->parameter_default_bindings,
                {map {my $s=$module->signals->{$_};$_=>[$s->width,$s->declared_width_binding,$s->declared_width_requirements]} keys %{$module->signals}}]);
            my $dt=FSM::HDL::FlattenedDT->new(debug=>0);my $ordinary=$dt->generate_systemverilog($module);
            my $capture=FSM::Backend::VerilogFamily::DeclarationCapture->new;my $hdl;
            {local $dt->{declared_width_declaration_capture}=$capture;$hdl=$dt->generate_systemverilog($module)}
            is(normalized($hdl),normalized($ordinary),'complete ordinary/captured source HDL conserves apart from Date');
            my ($name)=$hdl =~ /^  assign (\w+) = A \Q$op\E B; \/\/ Source: fsmgen_parsing$/m;
            ok(defined($name),'actual source emits the two-operand bitwise intermediate');
            my $snapshot=$capture->snapshot;
            is_deeply($snapshot->{target_intermediates}{$name},{expression=>"A $op B",bitwise_origin=>origin($op),width_allocation=>{kind=>'binary_operand_max',operator=>$op,source_names=>['A','B'],selected_width=>$width}},
                'actual selected expression, operands and current allocation policy retain');
            is($snapshot->{target_declarations}{$name}{width},$width,'actual result selected numeric width remains unchanged');
            is($json->encode([$module->parameters,$module->parameter_default_sources,$module->parameter_default_bindings,
                {map {my $s=$module->signals->{$_};$_=>[$s->width,$s->declared_width_binding,$s->declared_width_requirements]} keys %{$module->signals}}]),$before,
                'complete source maps, bindings, requirements, widths and JSON kinds preserve');
            $snapshot->{target_intermediates}{$name}{bitwise_origin}{source_names}[0]='WRONG';
            is($capture->snapshot->{target_intermediates}{$name}{bitwise_origin}{source_names}[0],'A','returned ordered origin deeply detaches');
        }
    }
};

subtest 'actual defining/runtime/cached AST association is required independently of rendered text' => sub {
    my ($hdl,$snapshot)=prepared({width=>8,ast=>binary('&'),runtime_ast=>binary('&')});
    is_deeply($snapshot->{target_intermediates}{unrelated_name}{bitwise_origin},origin('&'),
        'arbitrary allocated result name retains its actual AST relationship');
    my ($wide_hdl,$wide)=prepared({width=>32,ast=>binary('&'),runtime_ast=>binary('&')});
    like($wide_hdl,qr/^  wire \[31:0\] unrelated_name;$/m,'existing context-widened prepared declaration remains valid');
    is($wide->{target_declarations}{unrelated_name}{width},32,'selected result width remains an independent captured constraint');
    is_deeply($wide->{target_intermediates}{unrelated_name}{bitwise_origin},origin('&'),'syntactic origin does not assert an intrinsic width maximum');
    for my $info (
        {width=>8,rendered_expression=>'A & B',runtime_ast_resolution_state=>'missing'},
        {width=>8,ast=>binary('&'),runtime_ast=>binary('&'),rendered_expression=>'A | B'},
        {width=>8,ast=>binary('&'),runtime_ast=>binary('|')},
        {width=>8,ast=>binary('&'),runtime_ast=>binary('&'),defining_ast=>binary('&','B','A')},
        {width=>1,ast=>binary('&&'),runtime_ast=>binary('&&')},
        {width=>8,ast=>FSM::AST::BinaryOp->new('&',FSM::AST::SignalRef->new('A'),FSM::AST::Literal->new("8'b1"))},
        {width=>8,ast=>FSM::AST::BinaryOp->new('&',binary('|'),FSM::AST::SignalRef->new('A'))},
    ) {
        my ($actual,$event)=prepared($info);my ($expression)=$actual =~ /^  assign unrelated_name = (.*); \/\/ Source:/m;
        is_deeply($event->{target_intermediates}{unrelated_name},{expression=>$expression},
            'stored-only, stale, conflicting, logical, literal and compound shapes gain no bitwise origin');
    }
};

subtest 'collector preserves duplicate slots and independent selected widths without proving equivalence' => sub {
    for my $case ([['A','B'],8,1,8],[['B','A'],1,8,8],[['A','A'],8,1,8],[['A','B'],8,8,32],[['A','B'],8,8,1]) {
        my ($names,$aw,$bw,$rw)=@$case;my $capture=FSM::Backend::VerilogFamily::DeclarationCapture->new;
        $capture->begin_module('events');$capture->record_intermediate_declaration(row('RESULT',$rw));
        $capture->record_declaration('ports',row('A',$aw));$capture->record_declaration('ports',row('B',$bw));
        my $event={expression=>join(' & ',@$names),bitwise_origin=>origin('&',$names)};
        ok(eval {$capture->record_intermediate_assignment('RESULT',$event);$capture->complete;1},
            'actual membership and independent selected result width can be captured without equivalence') or diag $@;
        next unless eval {$capture->snapshot;1};
        is_deeply($capture->snapshot->{target_intermediates}{RESULT},$event,'all ordered operand slots and independent widths survive');
        $event->{bitwise_origin}{source_names}[0]='WRONG';
        isnt($capture->snapshot->{target_intermediates}{RESULT}{bitwise_origin}{source_names}[0],'WRONG','input event deeply detaches');
    }
};

subtest 'closed schemas and actual operand declarations fail atomically' => sub {
    my @bad=(
        {kind=>'binary_bitwise',operator=>'&&',source_names=>['A','B']},
        {kind=>'binary_bitwise',operator=>'&',source_names=>['A']},
        {kind=>'binary_bitwise',operator=>'&',source_names=>{}},
        {kind=>'binary_bitwise',operator=>'&',source_names=>['A','RESULT']},
        {kind=>'binary_bitwise',operator=>'&',source_names=>['A','bad-name']},
        {kind=>'binary_bitwise',operator=>'&',source_names=>['A','B'],extra=>1},
    );
    for my $bad (@bad) {
        my $capture=FSM::Backend::VerilogFamily::DeclarationCapture->new;$capture->begin_module('invalid');
        $capture->record_intermediate_declaration(row('RESULT'));
        ok(!eval {$capture->record_intermediate_assignment('RESULT',{expression=>'A & B',bitwise_origin=>$bad});1},'malformed typed origin refuses');
        ok(!eval {$capture->snapshot;1},'malformed event exposes no old or partial snapshot');
    }
    for my $case (['FOREIGN',8]) {
        my ($other,$rw)=@$case;my $capture=FSM::Backend::VerilogFamily::DeclarationCapture->new;
        $capture->begin_module('incomplete');$capture->record_intermediate_declaration(row('RESULT',$rw));
        $capture->record_declaration('ports',row('A'));$capture->record_declaration('ports',row('B'));
        my $ok=eval {$capture->record_intermediate_assignment('RESULT',{expression=>"A & $other",bitwise_origin=>origin('&',['A',$other])});$capture->complete;1};
        ok(!$ok,'missing actual operand refuses');
        like($@,qr/bitwise.*(?:operand|width)/i,'the actual event contract names its failure');
        ok(!eval {$capture->snapshot;1},'completion failure invalidates the whole transaction');
    }
    my $capture=FSM::Backend::VerilogFamily::DeclarationCapture->new;$capture->begin_module('conflict');
    $capture->record_intermediate_declaration(row('RESULT',1));
    ok(!eval {$capture->record_intermediate_assignment('RESULT',{expression=>'A & B',bitwise_origin=>origin,
        reduction_origin=>{kind=>'scalar_reduction',operator=>'&',source_name=>'A'}});1},'one assignment cannot claim incompatible origin families');
};
subtest 'syntactic binary origin does not admit non-scalar symbolic VHDL' => sub {
    my $source='(?fsm:binary_withheld (+params (W 8)) (+size (A (param W)) (B (param W)) (DATA 1) (OTHER 1))'
        .' (idle (<(& A B) (= (DATA 1)) (= (OTHER 1))) (-> idle)))';
    my $module=FSM::Adapter::FSMGenFull->new(debug=>0)->parse_fsm(scalar Lispish::multi(\$source));
    ok(!eval {FSM::HDL::FlattenedDT->new(debug=>0)->generate_vhdl($module);1},'actual symbolic binary VHDL remains withheld');
    like($@,qr/intermediate.*scalar reduction/i,'the existing scalar-only source guard names the missing qualification');
};
done_testing();
