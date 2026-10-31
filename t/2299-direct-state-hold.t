use strict;
use warnings;
use Test::More;
use JSON::PP;
use FindBin;
use lib "$FindBin::Bin/../perl";
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;

sub parse {
    my ($text) = @_;
    return FSM::Adapter::FSMGenFull->new(debug => 0)
        ->parse_fsm(scalar Lispish::multi(\$text));
}
sub source {
    my ($symbolic, $states) = @_;
    return '(?fsm:hold_case (+system (clock clk) (sreset reset)) '
        . ($symbolic ? '(+params (W 8)) ' : '')
        . '(+interface (input INPUT_PORT) (output DATA_PORT)) '
        . '(+size (INPUT_PORT ' . ($symbolic ? '(param W)' : '8') . ') '
        . '(DATA_PORT ' . ($symbolic ? '(param W)' : '8') . ')) '
        . ($states // '(idle (= (DATA_PORT INPUT_PORT)))') . ')';
}
my $json = JSON::PP->new->canonical;
sub stable_sv {
    my ($text) = @_;
    my $count = $text =~ s{^// Date: [^\n]+\n}{// Date: <generation timestamp>\n}mg;
    die 'Expected exactly one generated date header' unless $count == 1;
    return $text;
}

subtest 'regular states without transitions receive one explicit feedback mux' => sub {
    for my $symbolic (0, 1) {
        for my $states (undef, '(idle (= (DATA_PORT INPUT_PORT))) (waiting (= (DATA_PORT 0)))') {
            my $module = parse(source($symbolic, $states));
            my $before = $json->encode([$module->parameters, $module->parameter_default_sources,
                $module->parameter_default_bindings, [map {$_->declared_width_binding}
                    values %{$module->signals}]]);
            my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
            my $sv = $dt->generate_systemverilog($module);
            is(scalar(() = $sv =~ /next_state = current_state;/g), 1, 'one feedback drive exists');
            like($sv, qr/if \(reset\) begin\s+current_state <= IDLE;/s, 'reset state is unchanged');
            ok(!exists($dt->{assignment_analysis}{next_state}), 'no authored transition is invented');
            my $vhdl = eval {$dt->generate_vhdl($module)};
            ok(defined($vhdl), 'current source generates VHDL') or diag $@;
            if (defined $vhdl) {
                like($vhdl, qr/next_state <= current_state;/, 'VHDL retains feedback');
                like($vhdl, qr/if reset = '1' then\s+current_state <= IDLE;/s,
                    'VHDL retains reset state');
            }
            is($json->encode([$module->parameters, $module->parameter_default_sources,
                $module->parameter_default_bindings, [map {$_->declared_width_binding}
                    values %{$module->signals}]]), $before, 'source binding captures conserve');
            is(stable_sv($dt->generate_systemverilog($module)), stable_sv($sv),
                'fresh reuse preserves SV except its generation timestamp');
        }
    }
};

subtest 'real conditional transitions and decision-tree roots keep their ownership' => sub {
    my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
    $dt->generate_systemverilog(parse(source(0)));
    my $transition = parse(source(0, '(idle (<INPUT_PORT (-> waiting))) (waiting (-> idle))'));
    my $sv = $dt->generate_systemverilog($transition);
    ok(exists($dt->{assignment_analysis}{next_state}), 'real transition family remains authoritative');
    ok(!defined($dt->{implicit_state_hold}), 'prior implicit hold witness is cleared');
    like($sv, qr/next_state = current_state;/, 'conditional mux retains its existing hold default');
    like($sv, qr/next_state = WAITING;/, 'authored destination remains emitted');
    my $tree = parse(source(0, '(-comb (= (DATA_PORT INPUT_PORT)))'));
    my $tree_sv = $dt->generate_systemverilog($tree);
    unlike($tree_sv, qr/\b(?:current_state|next_state)\b/, 'DT-only root gains no state registers or feedback');
    ok(!defined($dt->{implicit_state_hold}), 'DT-only root gains no hold witness');
};

subtest 'symbolic VHDL requires the actual current emitted hold witness' => sub {
    my $module = parse(source(1));
    my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
    my $owner = 'FSM::Synthesis::EnableGraph::AssignmentSupport';
    my $original = $owner->can('generate_signal_assignments');
    for my $control (
        sub {delete $_[0]{implicit_state_hold}},
        sub {$_[0]{implicit_state_hold}{width} = 2},
        sub {$_[0]{implicit_state_hold}{rhs} = 'FOREIGN'},
    ) {
        no warnings 'redefine';
        local *FSM::Synthesis::EnableGraph::AssignmentSupport::generate_signal_assignments = sub {
            my ($self, @args) = @_;
            my $text = $original->($self, @args);
            $control->($self->{flattened_dt});
            return $text;
        };
        my $hdl = eval {$dt->generate_vhdl($module)};
        ok(!defined($hdl), 'missing or foreign hold witness refuses before an artifact returns');
        like($@, qr/state.hold/, 'the diagnostic identifies the state-hold contract');
    }
};

done_testing();
