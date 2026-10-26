use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Composition::Parser;
use FSM::Composition::PackageImportResolver;
use FSM::SourcePathResolver;
use FSM::IR::StructuralRTLIR;
use FSM::Backend::VerilogFamily::StructuralRTLIREmitter;
use FSM::Backend::VHDL::StructuralRTLIREmitter;

my $json = JSON::PP->new->canonical;
my %capture;
sub copy {return $json->decode($json->encode($_[0]))}
my $path = 't/data/composition-top-instance-bindings.fsm';
my $spec = FSM::Composition::Parser->new->parse_source(scalar Lispish::multi($path));
FSM::Composition::PackageImportResolver->resolve_imports(composition_spec => $spec,
    fsm_file => $path, source_path_resolver => FSM::SourcePathResolver->new);
my ($rtl) = grep {$_->kind eq 'rtl'} @{$spec->top->instances};
my ($binding) = grep {$_->{name} eq 'WIDTH'} @{$rtl->parameter_overrides};
ok(ref($binding->{binding_expression}) eq 'HASH', 'probe uses an actual scoped symbolic source record');
$capture{source_binding} = copy($binding);

for my $language (qw(systemverilog verilog vhdl)) {
    subtest "$language refuses pending semantic bindings rather than freezing their cache" => sub {
        my $emitter = $language eq 'vhdl' ? 'FSM::Backend::VHDL::StructuralRTLIREmitter'
            : 'FSM::Backend::VerilogFamily::StructuralRTLIREmitter';
        my $structural = {module_name => $spec->top->name, source_root_kind => 'top',
            target_language => $language, ports => [], nets => [], instances => [{kind => 'rtl',
                instance_name => $rtl->name, module_name => $rtl->module_name,
                interface_ports => [], port_bindings => [], parameter_overrides => [copy($binding)]}],
            auxiliary_assignments => []};
        my $literal = copy($structural);my $override = $literal->{instances}[0]{parameter_overrides}[0];
        delete $override->{binding_expression};$override->{raw_value} = '16';$override->{raw_value_ast} = ['16'];
        my $literal_before = $json->encode($literal);
        my $literal_text = $emitter->emit_module($literal);
        like($literal_text, $language eq 'vhdl' ? qr/WIDTH\s*=>\s*16/ : qr/\.WIDTH\(16\)/,
            'ordinary literal cache still emits through its existing profile');
        is($json->encode($literal), $literal_before, 'ordinary literal caller stays unchanged');
        $capture{literal}{$language} = {input => $literal, output => $literal_text};
        for my $kind (qw(hash object)) {
            my $input = $kind eq 'object' ? FSM::IR::StructuralRTLIR->new(%{copy($structural)}) : copy($structural);
            my $before = $json->encode($kind eq 'object' ? $input->as_hashref : $input);
            my $output;
            my $ok = eval {$output = $emitter->emit_module($input);1};my $error = $@;
            ok(!$ok, "$kind input cannot emit an unrelated constant for W");
            like($error, qr/symbolic parameter binding.*blocked.*lowering/s, "$kind input names the pending semantic lowering boundary");
            is($json->encode($kind eq 'object' ? $input->as_hashref : $input), $before, "$kind refusal preserves the whole caller");
            $capture{bound}{$language}{$kind} = {ok => $ok ? 1 : 0, error => $error, output => $output,
                input_before => $json->decode($before)};
        }
    };
}

if (my $out_path = $ENV{FSMGEN_STRUCTURAL_BINDING_CAPTURE}) {
    open my $out, '>', $out_path or die $!;print {$out} $json->encode(\%capture), "\n" or die $!;close $out or die $!;
}
done_testing();
