use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::VHDL;
use FSM::Backend::VerilogFamily::DeclarationCapture;
use FSM::DirectDeclaredWidthSupport;

my $class = 'FSM::Backend::VHDL::DirectDeclarationPlan';
my $json = JSON::PP->new->canonical;
open my $fh, '<', 't/data/ial0-direct-symbolic-storage.fsm' or die $!;
my $source = do {local $/; <$fh>};
close $fh or die $!;
sub fixture {
    my ($text) = @_;
    $text //= $source;
    my $m = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(scalar Lispish::multi(\$text));
    my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $sv;
    {local $dt->{declared_width_declaration_capture} = $capture; $sv = $dt->generate_systemverilog($m)}
    my $identifiers = FSM::HDL::FlattenedDT::Backend::VHDL::_plan_generated_vhdl_identifiers($sv);
    return {fsm_module => $m, assignment_analysis => $dt->{assignment_analysis},
        declaration_capture => $capture->snapshot, identifier_map => $identifiers->{identifier_map}};
}
sub prepare {
    require FSM::Backend::VHDL::DirectDeclarationPlan;
    return $class->prepare(%{$_[0]});
}
sub snapshot {
    my ($in) = @_;
    return $json->encode([$in->{declaration_capture}, $in->{identifier_map},
        FSM::DirectDeclaredWidthSupport->prepare_module(fsm_module => $in->{fsm_module},
            assignment_analysis => $in->{assignment_analysis}, target_language => 'systemverilog')]);
}
sub expected_ranges {
    my ($width, $input) = @_;
    $input //= 'INPUT_PORT';
    my %expected;
    for my $row (
        ['DATA', 'signal', $width, 'COPY', 0],
        [$input, 'port', $width, 'W', 0],
        ['SPARE', 'signal', $width + 1, '(W + 1)', 0],
        ['next_DATA', 'port', $width, 'COPY', 0],
    ) {
        my ($name, $role, $n, $expression, $signed) = @$row;
        $expected{$name} = {source_name => $name, declaration_kind => $role,
            width => $n, signed => $signed, is_vector => 1,
            source_range => "[($expression - 1):0] ",
            target_range => "(($expression - 1) downto 0)",
            target_type => "std_logic_vector(($expression - 1) downto 0)"};
    }
    return \%expected;
}
subtest 'actual port/storage captures retain source spelling numeric bounds and target rank' => sub {
    for my $width (1, 8) {
        my $text = $source =~ s/\(W 1\)/(W $width)/r;
        my $in = fixture($text);
        ok(!exists($in->{fsm_module}->signals->{DATA}), 'assignment-only actual storage is included');
        my $before = snapshot($in);
        my $plan = prepare($in);
        is($json->encode($plan->{ranges}), $json->encode(expected_ranges($width)), 'whole independent paired range/type table');
        is_deeply($plan->{generic_plan}{natural_declarations}, [
            {name => 'W', type => 'natural', default_text => $width, parameter_references => []},
            {name => 'COPY', type => 'natural', default_text => 'W', parameter_references => ['W']},
        ], 'width-selected generics preserve actual default dependency order');
        is_deeply($plan->{source_scope}, {kind => 'direct_module', owner => 'direct_symbolic_storage'}, 'original lexical scope');
        is($plan->{target_declarations}{TYPED}{width}, 4, 'fixed signed named type keeps numeric metadata');
        is($plan->{target_declarations}{TYPED}{signed}, 1, 'fixed signed metadata preserves');
        ok(!exists($plan->{ranges}{TYPED}) && !exists($plan->{ranges}{FIXED}), 'fixed and type rows acquire no symbolic range');
        is(snapshot($in), $before, 'complete caller source/target JSON kinds preserve');
        $plan->{ranges}{DATA}{width} = 99;
        $plan->{target_declarations}{TYPED}{width} = 99;
        is($json->encode(prepare($in)->{ranges}), $json->encode(expected_ranges($width)), 'result mutation cannot change subsequent preparation');
        is(snapshot($in), $before, 'result mutation cannot change caller captures');
    }
};
subtest 'physical mappings stay distinct from lexical owners' => sub {
    my $text = $source =~ s/direct_symbolic_storage/direct__symbolic_storage/r;
    $text =~ s/INPUT_PORT/_INPUT_PORT/g;
    my $in = fixture($text);
    my $plan = prepare($in);
    my $expected = expected_ranges(1);
    $expected->{INPUT_PORT}{source_name} = '_INPUT_PORT';
    is($json->encode($plan->{ranges}), $json->encode($expected), 'actual normalized Signal mapping joins paired rows');
    is($plan->{target_namespace}{module_name}, 'direct_symbolic_storage', 'physical target module is normalized');
    is($plan->{source_scope}{owner}, 'direct__symbolic_storage', 'lexical source owner is never normalized');
};
subtest 'static preparation keeps empty ranges and complete detached declaration records' => sub {
    my $text = $source =~ s/\(param COPY\)/1/gr;
    $text =~ s/\(param W\)/1/g;
    my $in = fixture($text);
    my $plan = prepare($in);
    is_deeply($plan->{ranges}, {}, 'literal and static arithmetic have no symbolic relationship');
    is($plan->{profile}, 'fixed', 'static source profile stays fixed');
    is($json->encode($plan->{target_declarations}), $json->encode($in->{declaration_capture}{target_declarations}), 'complete static selected metadata retains all kinds');
};
subtest 'missing stale foreign and conflicting inputs cannot authorize a range' => sub {
    for my $case (
        ['missing capture', sub {delete $_[0]{declaration_capture}}, qr/capture/],
        ['missing mapping', sub {delete $_[0]{identifier_map}}, qr/mapping/],
        ['missing declaration', sub {delete $_[0]{declaration_capture}{target_declarations}{DATA}}, qr/membership/],
        ['wrong width', sub {$_[0]{declaration_capture}{target_declarations}{DATA}{width} = 8}, qr/width/],
        ['duplicate role', sub {
            my $ns = $_[0]{declaration_capture}{target_namespace};
            push @{$ns->{ports}}, 'DATA';
        }, qr/collid/],
        ['stale binding', sub {$_[0]{assignment_analysis}{DATA}{lhs_ast}->signal->clear_declared_width_binding}, qr/coherent width binding/],
        ['foreign module', sub {$_[0]{declaration_capture}{target_namespace}{module_name} = 'FOREIGN'}, qr/module/],
        ['selected root rename', sub {$_[0]{identifier_map}{W} = 'RENAMED'}, qr/renaming/],
        ['target collision', sub {$_[0]{identifier_map}{DATA} = 'input_port'}, qr/collid/],
    ) {
        my ($label, $mutate, $error) = @$case;
        my $in = fixture(); $mutate->($in);
        my $before = $json->encode([$in->{declaration_capture}, $in->{identifier_map}]);
        ok(!eval {prepare($in); 1}, "$label refuses");
        like($@, $error, "$label has a contextual refusal");
        is($json->encode([$in->{declaration_capture}, $in->{identifier_map}]), $before, "$label keeps supplied target records");
    }
};
subtest 'raw converter admission is unchanged' => sub {
    my $raw = 'module raw(input wire [(W - 1):0] DATA);' . "\nendmodule\n";
    my $backend = FSM::HDL::FlattenedDT::Backend::VHDL->new(flattened_dt => {});
    ok(!eval {$backend->convert_systemverilog_to_vhdl($raw); 1}, 'raw symbolic range still refuses');
    like($@, qr/unsupported generated port declaration/, 'raw refusal names bounded parser');
};
subtest 'held plans retain no caller capture mapping or module owner' => sub {
    my ($weak_capture, $weak_mapping, $weak_module, $held);
    {
        my $in = fixture();
        # The independently owned backend cycle (.25) is outside this helper.
        # Use an actual Core copy never installed in that backend, retaining
        # the same actual Signals and canonical source observations.
        my $original = $in->{fsm_module};
        $in->{fsm_module} = FSM::CoreAST::FSMModule->new(name => $original->name,
            signals => $original->signals, parameters => $original->parameters,
            _parameter_default_sources => $original->parameter_default_sources,
            _parameter_default_bindings => $original->parameter_default_bindings);
        $weak_capture = $in->{declaration_capture}; weaken($weak_capture);
        $weak_mapping = $in->{identifier_map}; weaken($weak_mapping);
        $weak_module = $in->{fsm_module}; weaken($weak_module);
        $held = prepare($in);
    }
    ok(!defined($weak_capture) && !defined($weak_mapping) && !defined($weak_module), 'held plain result retains no caller owners');
    is($json->encode($held->{ranges}), $json->encode(expected_ranges(1)), 'held plan remains complete and usable');
};
done_testing();
