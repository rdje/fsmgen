use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::VHDL;

my $json = JSON::PP->new->canonical;
sub source {
    my ($width, $op) = @_;
    return "(?fsm:vhdl_helpers (+params (W $width) (SAME $width))"
        .' (+size (DATA (param W)) (SOURCE (param W)) (FIXED 1) (BIT 1))'
        ." (idle ($op (DATA SOURCE)) (<= (FIXED BIT)) (-> idle)))";
}
sub parse {
    my ($text) = @_;
    return FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(scalar Lispish::multi(\$text));
}
sub captures {
    my ($m) = @_;
    return $json->encode([$m->parameters, $m->parameter_default_sources, $m->parameter_default_bindings,
        {map {my $s = $m->signals->{$_}; $_ => [$s->width, $s->declared_width_source,
            $s->declared_width_binding, $s->declared_width_requirements]} keys %{$m->signals}}]);
}

subtest 'actual unsigned register next/q helpers preserve target rank, transfers and zero resets' => sub {
    for my $width (1, 8) {
        for my $op ('<-', '<-=', '<=', '<=-', '<=+') {
            my $module = parse(source($width, $op));
            my $before = captures($module);
            my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
            my $hdl = eval {$dt->generate_vhdl($module)};
            ok(defined($hdl), "$op source generates paired helper VHDL at width $width") or diag $@;
            next unless defined($hdl);
            my $is_next = $op eq '<-' || $op eq '<-=';
            my $helper = $is_next ? 'DATA_next' : 'DATA_q';
            like($hdl, qr/^  signal \Q$helper\E : std_logic_vector\(\(W - 1\) downto 0\);$/m,
                'complete helper declaration keeps actual symbolic vector rank');
            like($hdl, qr/^  signal FIXED_q : std_logic;$/m, 'unrelated fixed helper stays scalar');
            my ($generics) = $hdl =~ /  generic \(\n(.*?)\n  \);/s;
            is($generics, "    SAME : integer := $width;\n    W : natural := $width", 'complete generic block preserves actual width root and independent default');
            my $input_target = $is_next ? $helper : 'DATA';
            my $input_assignment = "$input_target <= std_logic_vector(resize(unsigned(SOURCE), ${input_target}'length));";
            ok(index($hdl, $input_assignment) >= 0, 'actual whole-vector transfer uses destination length');
            my $reset_target = $is_next ? 'DATA' : $helper;
            my $zero = '0' x $width;
            my $reset_assignment = "$reset_target <= std_logic_vector(resize(unsigned'(\"$zero\"), ${reset_target}'length));";
            ok(index($hdl, $reset_assignment) >= 0, 'actual zero reset uses symbolic destination length');
            is(captures($module), $before, 'complete source maps/captures and JSON kinds conserve');
            is($dt->generate_vhdl($module), $hdl, 'reused backend supplies identical complete VHDL without stale paired declarations');
        }
    }
};

subtest 'pulse, computed, no-transition and raw symbolic profiles still refuse' => sub {
    for my $case (
        ['pulse', source(8, '<-') =~ s/\(-> idle\)/(<3 (PULSE 1)) (-> idle)/r, qr/auxiliary/],
        ['computed', source(8, '<-') =~ s/\(DATA SOURCE\)/(DATA (+ SOURCE SOURCE))/r, qr/intermediate|computed/],
        ['state hold', source(8, '<-') =~ s/ \(-> idle\)//r, qr/state.hold/],
    ) {
        my ($name, $text, $error) = @$case;
        my $module = parse($text); my $before = captures($module);
        ok(!eval {FSM::HDL::FlattenedDT->new(debug => 0)->generate_vhdl($module); 1}, "$name source returns no artifact");
        like($@, $error, 'the actual unsupported shape owns refusal');
        is(captures($module), $before, 'refusal preserves source/default/capture products');
    }
    my $module = parse(source(8, '<-'));
    my $sv = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($module);
    my $raw = FSM::HDL::FlattenedDT::Backend::VHDL->new(flattened_dt => {});
    ok(!eval {$raw->convert_systemverilog_to_vhdl($sv); 1}, 'raw symbolic text cannot borrow source profile admission');
    like($@, qr/unsupported generated port/, 'raw numeric parser boundary remains explicit');
};

subtest 'previous explicit output and alias-root helper refusal now generates actual paired source' => sub {
    open my $input, '<', 't/data/ial0-direct-symbolic-comb.fsm' or die $!;
    my $text = do {local $/; <$input>}; close $input or die $!;
    $text =~ s/\(= \(DATA INPUT_PORT\)\)/(<-= (DATA INPUT_PORT))/;
    my $module = parse($text);
    my $hdl = eval {FSM::HDL::FlattenedDT->new(debug => 0)->generate_vhdl($module)};
    ok(defined($hdl), 'exact previously refused source now supplies VHDL') or diag $@;
    return unless defined($hdl);
    like($hdl, qr/^  signal DATA_next : std_logic_vector\(\(COPY - 1\) downto 0\);$/m, 'actual alias root supplies the helper type');
    like($hdl, qr/next_DATA : out std_logic_vector\(\(COPY - 1\) downto 0\)/, 'generated source output retains the same alias without numeric freezing');
};

subtest 'actual admission guard refuses missing, foreign and malformed allocation origins' => sub {
    my $module = parse(source(1, '<-'));
    my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
    $dt->generate_systemverilog($module);
    my $source = FSM::DirectDeclaredWidthSupport->prepare_module(fsm_module => $module,
        assignment_analysis => $dt->{assignment_analysis}, target_language => 'systemverilog');
    my $original = FSM::Synthesis::EnableGraph::ModulePlanningSupport->can('build_internal_signal_declaration_plan');
    for my $change (
        sub {delete $_[0]{aux_width_origins}{DATA_next}},
        sub {$_[0]{aux_width_origins}{DATA_next}{source_name} = 'FOREIGN'},
        sub {$_[0]{aux_width_origins}{DATA_next}{kind} = 'pulse'},
        sub {$_[0]{aux_width_origins}{DATA_next}{extra} = 1},
        sub {$_[0]{aux_decls}{DATA_next} = 8},
    ) {
        no warnings 'redefine';
        local *FSM::Synthesis::EnableGraph::ModulePlanningSupport::build_internal_signal_declaration_plan = sub {
            my $plan = $original->(@_); $change->($plan); return $plan;
        };
        ok(!eval {FSM::HDL::FlattenedDT::Backend::VHDL::_validate_symbolic_generated_shapes($dt, $module, $source); 1},
            'unproved allocation cannot borrow the register profile');
        like($@, qr/auxiliary.*qualified register parent/, 'the actual parent-shape admission boundary refuses');
    }
};

subtest 'fixed source retains complete existing raw conversion products' => sub {
    my $text = source(8, '<-') =~ s/\(param W\)/8/gr;
    $text =~ s/\(\+params \(W 8\) \(SAME 8\)\)//;
    my $module = parse($text); my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
    my $sv = $dt->generate_systemverilog($module);
    my $raw = FSM::HDL::FlattenedDT::Backend::VHDL->new(flattened_dt => {})->convert_systemverilog_to_vhdl($sv);
    is($dt->generate_vhdl($module), $raw, 'whole fixed native/raw artifact remains equal');
};
done_testing();
