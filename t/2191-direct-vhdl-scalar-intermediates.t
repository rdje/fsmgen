use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::AST::Node;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::VHDL;
use FSM::Backend::VerilogFamily::DeclarationCapture;
use FSM::DirectDeclaredWidthSupport;

my $json = JSON::PP->new->canonical;
sub source {
    my ($width, $expression) = @_; $expression //= '(^ INPUT)';
    return "(?fsm:vhdl_scalar (+params (W $width)) (+interface (output DATA) (output OTHER))"
        .' (+size (INPUT (param W)) (DATA 1) (OTHER 1))'
        ." (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
}
sub parse {my ($s) = @_; FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(scalar Lispish::multi(\$s))}
sub copy {$json->decode($json->encode($_[0]))}
sub maps {
    my ($m) = @_;
    return $json->encode([$m->parameters, $m->parameter_default_sources, $m->parameter_default_bindings,
        {map {my $s = $m->signals->{$_}; $_ => [$s->width, $s->declared_width_source,
            $s->declared_width_binding, $s->declared_width_requirements]} keys %{$m->signals}}]);
}
sub captured {
    my ($text) = @_;
    my $m = parse($text); my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $sv; {local $dt->{declared_width_declaration_capture} = $capture; $sv = $dt->generate_systemverilog($m)}
    my $plan = FSM::DirectDeclaredWidthSupport->prepare_module(fsm_module => $m,
        assignment_analysis => $dt->{assignment_analysis}, target_language => 'systemverilog');
    return ($m, $dt, $sv, $capture->snapshot, $plan);
}

subtest 'actual generic whole unsigned reductions retain scalar intermediates and vector operand rank' => sub {
    my %helper = ('^' => 'xor', '&' => 'and', '|' => 'or');
    for my $width (1, 8) {
        for my $op ('^', '&', '|') {
            my ($m, $dt, $sv, $snapshot) = captured(source($width, "($op INPUT)"));
            my ($name) = keys %{$snapshot->{target_intermediates}};
            my $before = maps($m);
            my $hdl = eval {$dt->generate_vhdl($m)};
            ok(defined($hdl), "$op source supplies paired scalar VHDL at operand default $width") or diag $@;
            next unless defined($hdl);
            like($hdl, qr/^    INPUT : in std_logic_vector\(\(W - 1\) downto 0\)[;,]?$/m,
                'complete generic operand declaration keeps vector rank even at default one');
            like($hdl, qr/^  signal \Q$name\E : std_logic;$/m, 'complete result declaration is scalar');
            like($hdl, qr/^  \Q$name\E <= \(fsmgen_direct_vhdl_reduce_\Q$helper{$op}\E\(INPUT\)\);$/m,
                'actual emitted operation reduces the whole generic operand');
            like($hdl, qr/for index in value'range loop/, 'fold uses actual operand range rather than selected default');
            for my $output ('data', 'other') {
                like($hdl, qr/^  idle_\Q$output\E_1_en <= idle_en and \Q$name\E;$/m,
                    'actual selector retains state gating and the reduction predicate');
            }
            is(maps($m), $before, 'complete caller maps, capture values and JSON kinds conserve');
            is($dt->generate_vhdl($m), $hdl, 'reused backend retains the complete paired product');
        }
    }
};

subtest 'actual admission refuses missing stale foreign conflicting and non-scalar event relationships' => sub {
    my ($m, $dt, $sv, $snapshot, $plan) = captured(source(1));
    my ($name) = keys %{$snapshot->{target_intermediates}};
    my $before = maps($m);
    my $before_records = $json->encode([$snapshot, $plan]);
    for my $change (
        sub {delete $_[0]{target_intermediates}},
        sub {$_[0]{target_intermediates} = {}},
        sub {$_[0]{target_intermediates}{PHANTOM} = copy($_[0]{target_intermediates}{$name})},
        sub {delete $_[0]{target_intermediates}{$name}{expression}},
        sub {$_[0]{target_intermediates}{$name}{expression} = '(!INPUT)'},
        sub {delete $_[0]{target_intermediates}{$name}{reduction_origin}},
        sub {$_[0]{target_intermediates}{$name}{reduction_origin}{source_name} = 'FOREIGN'},
        sub {$_[0]{target_intermediates}{$name}{reduction_origin}{operator} = '|'},
        sub {$_[0]{target_intermediates}{$name}{reduction_origin}{extra} = 1},
        sub {$_[0]{target_declarations}{$name}{width} = 8},
        sub {$_[0]{target_declarations}{$name}{name} = 'FORGED'},
        sub {$_[0]{target_namespace}{signals} = [grep {$_ ne $name} @{$_[0]{target_namespace}{signals}}]},
        sub {$_[0]{target_declarations}{INPUT}{signed} = 1},
        sub {$_[0]{target_declarations}{INPUT}{width} = 8},
    ) {
        my $bad = copy($snapshot); $change->($bad);
        ok(!eval {FSM::HDL::FlattenedDT::Backend::VHDL::_validate_symbolic_generated_shapes($dt, $m, $plan, $bad); 1},
            'unproved actual event cannot borrow the scalar profile');
        like($@, qr/intermediate|reduction/i, 'actual scalar relationship owns the refusal');
    }
    {
        local $dt->{intermediate_signals}{$name} = {%{$dt->{intermediate_signals}{$name}},
            runtime_ast => FSM::AST::UnaryOp->new('|', FSM::AST::SignalRef->new('INPUT'))};
        ok(!eval {FSM::HDL::FlattenedDT::Backend::VHDL::_validate_symbolic_generated_shapes($dt, $m, $plan, $snapshot); 1},
            'late same-width runtime AST change cannot borrow a captured operation');
        like($@, qr/intermediate|reduction/i, 'late runtime disagreement is explicit');
    }
    is(maps($m), $before, 'all refusals preserve complete source maps and JSON kinds');
    is($json->encode([$snapshot, $plan]), $before_records, 'guard preserves complete original snapshot/plan JSON kinds');
};

subtest 'source-aware conversion binds captured expressions to actual continuous assignments before mapping' => sub {
    my ($m, $dt, $sv, $snapshot) = captured(source(8));
    my ($name) = keys %{$snapshot->{target_intermediates}};
    my $line = "  assign $name = (^(INPUT)); // Source: ast_factorization\n";
    ok(index($sv, $line) >= 0, 'retained complete native assignment is the mutation boundary');
    my @bad = ($sv =~ s/\Q$line\E//r, $sv =~ s/\Q$line\E/$line$line/r,
        $sv =~ s/\Q$line\E/  assign $name = (|(INPUT)); \/\/ Source: ast_factorization\n/r);
    for my $bad (@bad) {
        ok(!eval {$dt->{backend_vhdl}->_convert_systemverilog_to_vhdl($bad, $m, $snapshot); 1},
            'missing duplicate or same-width changed emitted operation supplies no paired artifact');
        like($@, qr/intermediate.*assignment|assignment.*intermediate/i, 'exact emitted-assignment boundary is named');
    }
};

subtest 'logical and compound origins, pulse helpers and raw symbolic text retain precise refusals' => sub {
    ok(!eval {FSM::HDL::FlattenedDT->new(debug => 0)->generate_vhdl(parse(source(8, '(! INPUT)'))); 1},
        'unqualified actual logical intermediate supplies no VHDL');
    like($@, qr/intermediate|computed/i, 'logical origin remains explicitly unsupported');
    ok(!eval {parse(source(8, '(^ (& INPUT INPUT))')); 1}, 'compound reduction retains its earlier source refusal');
    like($@, qr/requires a declared positive.width packed scalar signal/i, 'source operand contract owns compound refusal');
    for my $type ('(bits 8)', '(four_state (signed (bits 8)))') {
        my $typed = source(8);
        $typed =~ s/\(\+size /(+types (type word $type)) (+size (EXTRA (param W)) /;
        $typed =~ s/\(INPUT \(param W\)\)/(INPUT word)/;
        $typed =~ s/\(\+interface /(+interface (input EXTRA) /;
        ok(!eval {FSM::HDL::FlattenedDT->new(debug => 0)->generate_vhdl(parse($typed)); 1}, 'named or signed operand cannot borrow the plain unsigned profile');
        like($@, qr/intermediate.*plain unsigned/i, 'actual operand type owns refusal');
    }
    my $pulse = source(8) =~ s/\(-> idle\)/(<3 (PULSE 1)) (-> idle)/r;
    ok(!eval {FSM::HDL::FlattenedDT->new(debug => 0)->generate_vhdl(parse($pulse)); 1}, 'scalar origin cannot qualify an unrelated pulse allocation');
    like($@, qr/auxiliary/, 'actual pulse family owns refusal');
    my ($m, $dt, $sv) = captured(source(8));
    ok(!eval {FSM::HDL::FlattenedDT::Backend::VHDL->new(flattened_dt => {})->convert_systemverilog_to_vhdl($sv); 1},
        'raw symbolic conversion has no source relationship authority');
    like($@, qr/unsupported generated port/, 'raw numeric declaration boundary remains unchanged');
};

subtest 'fixed source retains complete raw conversion equality' => sub {
    my $text = source(8) =~ s/\(param W\)/8/gr; $text =~ s/\(\+params \(W 8\)\)//;
    my $m = parse($text); my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
    my $sv = $dt->generate_systemverilog($m);
    my $raw = FSM::HDL::FlattenedDT::Backend::VHDL->new(flattened_dt => {})->convert_systemverilog_to_vhdl($sv);
    is($dt->generate_vhdl($m), $raw, 'whole fixed paired/raw VHDL artifact conserves');
};
done_testing();
