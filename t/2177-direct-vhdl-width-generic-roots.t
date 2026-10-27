use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::VHDL;
use FSM::Backend::VerilogFamily::DeclarationCapture;
use FSM::Backend::VHDL::DirectParameterEmitter;
use FSM::DirectDeclaredWidthSupport;

my $class = 'FSM::Backend::VHDL::DirectParameterEmitter';
my $json = JSON::PP->new->canonical;
sub fixture {
    my ($width, $params) = @_;
    $width //= '(param WIDTH)';
    $params //= q{(WIDTH 8) (SAME 8) (NEG -1) (_PAD 8'hA5)};
    my $text = "(?fsm:width_generic_roots (+params $params)"
        ." (+size (DATA $width) (SOURCE 8)) (idle (<-= (DATA SOURCE))))";
    my $m = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(scalar Lispish::multi(\$text));
    my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $sv;
    {local $dt->{declared_width_declaration_capture} = $capture; $sv = $dt->generate_systemverilog($m)}
    my $snapshot = $capture->snapshot;
    my $ns = $snapshot->{target_namespace};
    my $mapping = FSM::HDL::FlattenedDT::Backend::VHDL::_plan_generated_vhdl_identifiers($sv)->{identifier_map};
    $ns->{module_name} = $mapping->{$ns->{module_name}} // $ns->{module_name};
    for my $bucket (qw(parameter_names ports signals constants types)) {
        $ns->{$bucket} = [map {$mapping->{$_} // $_} @{$ns->{$bucket}}];
    }
    $ns->{identifier_map} = $mapping;
    my %declarations;
    for my $name (keys %{$snapshot->{target_declarations}}) {
        my $target = $mapping->{$name} // $name;
        $declarations{$target} = {%{$snapshot->{target_declarations}{$name}}, name => $target};
    }
    return {fsm_module => $m, target_language => 'vhdl', target_namespace => $ns,
        target_declarations => \%declarations, assignment_analysis => $dt->{assignment_analysis}};
}
sub prepare {return $class->lower_declarations(%{$_[0]})}
sub snapshot {
    my ($in) = @_;
    return $json->encode([$in->{target_namespace}, $in->{target_declarations},
        FSM::DirectDeclaredWidthSupport->prepare_module(%$in), $in->{fsm_module}->parameters,
        $in->{fsm_module}->parameter_default_sources, $in->{fsm_module}->parameter_default_bindings]);
}
subtest 'a width-only captured root becomes natural without borrowing equal static defaults' => sub {
    my $in = fixture();
    ok(!exists($in->{fsm_module}->signals->{DATA}), 'real assignment target is outside module membership');
    my $before = snapshot($in);
    my $plan = prepare($in);
    my $expected = {profile => 'mixed', source_scope => {kind => 'direct_module', owner => 'width_generic_roots'},
        parameter_order => [qw(NEG SAME WIDTH PAD)], static_parameters => [qw(NEG SAME PAD)],
        natural_declarations => [{name => 'WIDTH', type => 'natural', default_text => 8, parameter_references => []}]};
    is($json->encode($plan), $json->encode($expected), 'complete independent width-only profile keeps static negative/vector/equal-default controls');
    is(snapshot($in), $before, 'whole source/target records and JSON kinds preserve');
    $plan->{natural_declarations}[0]{name} = 'WRONG';
    is($json->encode(prepare($in)), $json->encode($expected), 'returned plans cannot rewrite source captures');
};
subtest 'width roots union with related default declarations in dependency order' => sub {
    my $in = fixture('(param WIDTH)', '(BASE 8) (COPY BASE) (WIDTH 8) (SAME 8)');
    is($json->encode(prepare($in)), $json->encode({profile => 'mixed',
        source_scope => {kind => 'direct_module', owner => 'width_generic_roots'},
        parameter_order => [qw(BASE COPY SAME WIDTH)], static_parameters => ['SAME'],
        natural_declarations => [
            {name => 'BASE', type => 'natural', default_text => 8, parameter_references => []},
            {name => 'COPY', type => 'natural', default_text => 'BASE', parameter_references => ['BASE']},
            {name => 'WIDTH', type => 'natural', default_text => 8, parameter_references => []},
        ]}), 'complete independently expected union/order/default declarations');
};
subtest 'unselected fixed widths and omitted opt-in inputs retain prior profiles' => sub {
    for my $width ('8', '(+ 8 0)') {
        my $in = fixture($width);
        my $with = prepare($in);
        delete @{$in}{qw(assignment_analysis target_declarations)};
        is($json->encode($with), $json->encode(prepare($in)), 'fixed declaration opts into no invented natural root');
        is_deeply($with->{natural_declarations}, [], 'equal literals remain independent');
    }
    my $in = fixture();
    delete @{$in}{qw(assignment_analysis target_declarations)};
    is_deeply(prepare($in)->{natural_declarations}, [], 'existing default-only caller keeps its static profile until integration');
};
subtest 'incomplete stale renamed and inconsistent width contracts refuse' => sub {
    for my $missing (qw(assignment_analysis target_declarations)) {
        my $in = fixture(); delete $in->{$missing};
        ok(!eval {prepare($in); 1}, 'one opt-in input cannot be silently ignored');
        like($@, qr/width.*(?:analysis|declarations|together)/, 'paired contract refusal is explicit');
    }
    my $in = fixture();
    $in->{assignment_analysis}{DATA}{lhs_ast}->signal->clear_declared_width_binding;
    ok(!eval {prepare($in); 1}, 'stale actual assignment capture cannot select a root');
    like($@, qr/coherent width binding/, 'stale binding refusal comes from canonical width proof');
    $in = fixture(); $in->{target_declarations}{DATA}{width} = 16;
    ok(!eval {prepare($in); 1}, 'same source cannot borrow mismatched target declaration width');
    like($@, qr/observed source width/, 'target disagreement is explicit');
    $in = fixture();
    $in->{target_namespace}{identifier_map}{WIDTH} = 'RENAMED_WIDTH';
    @{$in->{target_namespace}{parameter_names}} = map {$_ eq 'WIDTH' ? 'RENAMED_WIDTH' : $_} @{$in->{target_namespace}{parameter_names}};
    ok(!eval {prepare($in); 1}, 'selected width root renaming cannot become a static generic');
    like($@, qr/parameter.*renaming/, 'selected root mapping is checked');
};
done_testing();
