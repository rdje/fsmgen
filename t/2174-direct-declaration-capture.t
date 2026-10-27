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
my $class = 'FSM::Backend::VerilogFamily::DeclarationCapture';
ok(eval {require FSM::Backend::VerilogFamily::DeclarationCapture; 1}, 'opt-in actual declaration collector exists')
    or do {done_testing(); exit};
my $json = JSON::PP->new->canonical;
my @products;
sub module_from {
    my ($text) = @_;
    return FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(scalar Lispish::multi(\$text));
}
sub normalize_date {my ($s) = @_; $s =~ s{^// Date:.*$}{// Date: <generation-time>}mg; return $s}
sub actual_names {
    my ($hdl) = @_;
    my $parsed = FSM::HDL::FlattenedDT::Backend::VHDL::_parse_module($hdl);
    my %types = FSM::HDL::FlattenedDT::Backend::VHDL::_parse_packed_struct_typedef_widths($hdl);
    # The converter supports aggregate outputs, not aggregate inputs. Keep
    # that bounded production API unchanged; this test separately recognizes
    # only an input whose complete actual typedef was independently parsed.
    my @typed_inputs;
    my @plain_ports;
    for my $line (split /\n/, $parsed->{ports}) {
        if ($line =~ /^\s*input\s+(\w+)\s+(\w+)\s*,?\s*$/ && exists $types{$1}) {
            push @typed_inputs, {name => $2};
        } else {push @plain_ports, $line}
    }
    my @ports = (@typed_inputs, FSM::HDL::FlattenedDT::Backend::VHDL::_parse_ports(join("\n", @plain_ports), \%types));
    my @signals = FSM::HDL::FlattenedDT::Backend::VHDL::_parse_signal_declarations($parsed->{body}, {map {$_->{name} => 1} @ports});
    my @constants = FSM::HDL::FlattenedDT::Backend::VHDL::_parse_constants($parsed->{body});
    my @parameters = FSM::HDL::FlattenedDT::Backend::VHDL::_parse_generics($parsed->{parameters});
    return {module_name => $parsed->{name}, identifier_map => {},
        parameter_names => [map {$_->{name}} @parameters], ports => [sort map {$_->{name}} @ports],
        signals => [sort map {$_->{name}} @signals], constants => [sort map {$_->{name}} @constants], types => [sort keys %types]};
}
sub generate_captured {
    my ($dt, $m, $capture) = @_;
    local $dt->{declared_width_declaration_capture} = $capture;
    return $dt->generate_systemverilog($m);
}
my $source = q{(?fsm:decl_capture (+params (W 8) (COPY W)) (+size (DATA 8) (SOURCE 8)) (idle (<-= (DATA (+ SOURCE 8'd1)))))};
subtest 'actual emitted membership and numeric metadata capture without changing HDL' => sub {
    for my $text ($source,
        '(?fsm:aggregate_capture (+types (type frame_t (record (payload (bits 8))))) (+size (DATA frame_t) (OUT 8)) (idle (= (OUT DATA))))') {
        my $module = module_from($text); my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
        my $before = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($module);
        my $capture = $class->new;
        my $hdl = generate_captured($dt, $module, $capture);
        is(normalize_date($hdl), normalize_date($before), 'whole ordinary artifact conserves; only Date is outside comparison');
        my $snapshot = $capture->snapshot;
        push @products, {source => $text, baseline_hdl => $before, captured_hdl => $hdl,
            snapshot => $json->decode($json->encode($snapshot))};
        is($json->encode($snapshot->{target_namespace}), $json->encode(actual_names($hdl)), 'complete actual emitter membership matches independent existing converter parser');
        my $name = $module->name eq 'decl_capture' ? 'next_DATA' : 'DATA';
        my $record = $snapshot->{target_declarations}{$name};
        is($record->{width}, 8, 'actual declaration selected width is captured');
        is($record->{signed}, 0, 'actual unsigned declaration is captured');
        if ($name eq 'DATA') {
            is($record->{declared_type_name}, 'frame_t', 'actual aggregate type name retained');
            is_deeply($record->{declared_type_spec}, $module->signals->{DATA}->declared_type_spec, 'complete canonical backend type metadata retained');
        } else {
            is_deeply($record, {name => 'next_DATA', width => 8, signed => 0,
                state_model => undef, declared_type_name => undef, declared_type_spec => undef}, 'whole independently expected propagated output declaration');
        }
        $snapshot->{target_declarations}{$name}{width} = 999;
        is($capture->snapshot->{target_declarations}{$name}{width}, 8, 'returned snapshots cannot rewrite collector');
        ok(!exists($dt->{declared_width_declaration_capture}), 'localized opt-in leaves no caller flag behind');
    }
};
subtest 'actual prepared intermediate owner publishes its selected width' => sub {
    my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
    my $capture = $class->new; $capture->begin_module('prepared_intermediates');
    local $dt->{declared_width_declaration_capture} = $capture;
    my $hdl = $dt->{backend_sv_consolidated_intermediate_declaration_support}
        ->render_consolidated_intermediate_declarations({sorted_signals => ['prepared_vector'],
            filtered_signals => {prepared_vector => {width => 8}}});
    $capture->complete;
    is($hdl, "  wire [7:0] prepared_vector;\n", 'whole independent actual prepared-owner declaration');
    is_deeply($capture->snapshot->{target_declarations}{prepared_vector},
        {name => 'prepared_vector', width => 8, signed => 0, state_model => undef,
            declared_type_name => undef, declared_type_spec => undef}, 'whole selected numeric row from the actual shared width resolver');
};
subtest 'generation failures and reuse never expose a prior completed namespace' => sub {
    my $capture = $class->new; my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
    generate_captured($dt, module_from($source), $capture);
    my $bad = module_from('(?fsm:bad_decl_capture (+size (DATA 8) (SOURCE 1)) (idle (= (DATA SOURCE))))');
    ok(!eval {generate_captured($dt, $bad, $capture); 1}, 'actual operand failure interrupts generation');
    ok(!eval {$capture->snapshot; 1}, 'failed generation cannot expose old or partial namespace');
    like($@, qr/completed.*declaration|declaration.*complete/i, 'completion boundary is explicit');
    generate_captured($dt, module_from('(?fsm:fresh_capture (+size (RESULT 1)) (idle (= (RESULT 0))))'), $capture);
    is($capture->snapshot->{target_namespace}{module_name}, 'fresh_capture', 'retry publishes only the new actual module');
    ok(!grep($_ eq 'COPY', @{$capture->snapshot->{target_namespace}{parameter_names}}), 'older parameter membership is absent');
};
subtest 'collector transaction records remain plain and fail closed' => sub {
    my $capture = $class->new;
    ok(!eval {$capture->snapshot; 1}, 'new collector supplies no fabricated completed result');
    $capture->begin_module('bare');
    my $row = {name => 'DATA', width => 1, signed => 0, state_model => undef, declared_type_name => undef, declared_type_spec => undef};
    $capture->record_declaration('ports', $row); $row->{width} = 99;
    $capture->complete;
    is($capture->snapshot->{target_declarations}{DATA}{width}, 1, 'input records detach');
    $capture->begin_module('duplicate');
    $capture->record_declaration('ports', {name => 'DATA', width => 1, signed => 0});
    ok(!eval {$capture->record_name('constants', 'DATA'); 1}, 'duplicate actual namespace owners refuse');
    ok(!eval {$capture->snapshot; 1}, 'refused transaction supplies no old result');
    $capture->begin_module('incomplete'); $capture->record_name('ports', 'MISSING_ROW');
    ok(!eval {$capture->complete; 1}, 'incomplete numeric membership cannot complete');
    my $held; my $weak;
    {my $c = $class->new; $weak = $c; weaken($weak); $c->begin_module('plain'); $c->complete; $held = $c->snapshot}
    ok(!defined($weak), 'held plain snapshot retains no collector owner');
    is_deeply($held->{target_namespace}{ports}, [], 'independent empty declaration category stays empty');
};
if (my $path = $ENV{FSMGEN_DECLARATION_CAPTURE_RECEIPT}) {
    open my $out, '>', $path or die $!;
    print {$out} $json->encode(\@products), "\n";
    close $out or die $!;
}
done_testing();
