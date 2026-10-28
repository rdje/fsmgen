use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::DirectDeclaredWidthSupport;
my $class='FSM::DirectDeclaredWidthSupport';my $json=JSON::PP->new->canonical;
my $has_api=$class->can('prepare_binary_operand_relationship');
sub fixture {
    my($width,$left,$right,$extra)=@_;$left//='(param W)';$right//=$left;$extra//='';
    # A comparison references both source Signals without asking binary max
    # range admission to accept deliberately incompatible source contracts.
    my $text="(?fsm:operand_relation (+params (W $width) (COPY W) (SAME $width)) $extra (+size (A $left) (B $right) (DATA 1) (OTHER 1)) (idle (<(== A B) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $module=FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$text));my $ctx=FSM::HDL::FlattenedDT->new;$ctx->generate_systemverilog($module);
    return {fsm_module=>$module,assignment_analysis=>$ctx->{assignment_analysis},source_names=>['A','B'],target_language=>'systemverilog'};
}
sub prepare {$class->prepare_binary_operand_relationship(%{$_[0]})}
sub source_state {
    my($in)=@_;my $m=$in->{fsm_module};
    return $json->encode([$in->{source_names},$m->parameters,$m->parameter_default_sources,$m->parameter_default_bindings,
        {map {my $s=$m->signals->{$_};$_=>[$s->width,$s->signed,$s->declared_width_source,$s->declared_width_binding,$s->declared_width_requirements]} sort keys %{$m->signals}}]);
}
subtest 'actual same-root operands yield source-only identical mutable relationship' => sub {
    my $in=fixture(1);my $first=eval {prepare($in)};
    ok($first,'private source relationship preparation exists and succeeds') or diag $@;
    return unless $has_api;
    for my $language ('systemverilog','verilog','vhdl') {for my $width (1,8) {
        my $in=fixture($width);$in->{target_language}=$language;my $before=source_state($in);my $plan=prepare($in);
        is($plan->{profile},'symbolic','actual same mutable root remains symbolic');
        is_deeply($plan->{source_names},['A','B'],'ordered actual operand slots retain');
        is_deeply($plan->{operand_widths},[$width,$width],'observed widths retain');
        my $expected=$class->prepare_module(%$in)->{signals}{A}{width_plan};
        is_deeply($plan->{width_plan},$expected,'representative is the canonical proved operand range');
        is($plan->{width_plan}{is_vector},1,'default-one mutable width retains vector rank');
        is(source_state($in),$before,'complete caller source/default/binding/requirement kinds preserve');
        $plan->{width_plan}{width_contract}{expression}[1]='WRONG';
        is(prepare($in)->{width_plan}{width_contract}{expression}[1],'W','result deeply detaches');
    }}
};
subtest 'tree identity ordered roots and duplicate source slots preserve without algebraic guessing' => sub {
    plan skip_all=>'relationship API absent' unless $has_api;
    for my $expression ('(+ (param W) 1)','(+ (param W) (param W))') {
        my $in=fixture(8,$expression);my $plan=prepare($in);
        is_deeply($plan->{width_plan},$class->prepare_module(%$in)->{signals}{A}{width_plan},'complete arithmetic contract and repeated root order retain');
    }
    my $in=fixture(8);$in->{source_names}=['A','A'];my $plan=prepare($in);
    is_deeply($plan->{source_names},['A','A'],'duplicate actual operand slots preserve');
};
subtest 'independent aliases static floors and different trees refuse equal-default inference' => sub {
    plan skip_all=>'relationship API absent' unless $has_api;
    for my $right ('(param COPY)','(param SAME)','8','(+ (param W) 0)') {
        my $in=fixture(8,'(param W)',$right);my $before=source_state($in);
        ok(!eval {prepare($in);1},'equal observed width supplies no identical mutable relationship');
        like($@,qr/identical.*(?:mutable|relationship)|mutable.*contract/i,'refusal identifies the unproved relationship');
        is(source_state($in),$before,'refused proof preserves all caller state');
    }
    my $fixed=fixture(8,'8','4');my $plan=prepare($fixed);
    is($plan->{profile},'fixed','both independent static operands retain fixed profile');
    is_deeply($plan->{operand_widths},[8,4],'independent fixed widths stay separate');
    is($plan->{width_plan},undef,'fixed profile invents no symbolic range or allocation');
};
subtest 'missing typed constrained and stale actual objects refuse' => sub {
    plan skip_all=>'relationship API absent' unless $has_api;
    for my $case (
        ['arity',sub {$_[0]{source_names}=['A']}],['foreign',sub {$_[0]{source_names}=['A','FOREIGN']}],
        ['signed',sub {$_[0]{fsm_module}->signals->{A}{signed}=1}],
        ['state',sub {$_[0]{fsm_module}->signals->{A}{state_model}='enum'}],
        ['constraints',sub {$_[0]{fsm_module}->signals->{A}{constraints}=['opaque']}],
        ['parameter',sub {$_[0]{fsm_module}{parameters}{W}=9}],
    ) {
        my $in=fixture(8);$case->[1]->($in);ok(!eval {prepare($in);1},"$case->[0] source cannot gain relation");
    }
    my $in=fixture(8,'(param W)','word_t','(+types (type word_t (bits 8)))');
    ok(!eval {prepare($in);1},'named operand type stays outside plain profile');
};
done_testing();
