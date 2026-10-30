use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::Backend::VerilogFamily::DeclarationCapture;

my $json = JSON::PP->new->canonical;

sub source_profile {
    my ($module) = @_;
    return $json->encode({parameters => $module->parameters,
        defaults => $module->parameter_default_sources,
        bindings => $module->parameter_default_bindings,
        signals => {map {
            my $signal = $module->signals->{$_};
            $_ => {width => $signal->width, binding => $signal->declared_width_binding,
                requirements => $signal->declared_width_requirements,
                expression => $signal->driving_ast ? $signal->driving_ast->to_systemverilog : undef}
        } sort keys %{$module->signals}}});
}

subtest 'scalar wrappers retain their result rank and generic vector children' => sub {
    my @cases = (
        {source => '(== A B)', scalar => 'A == B'},
        {source => '(! A)', operand => 'A'},
        {source => '(! (+ A B))', vector => 'A + B'},
        {source => '(!& A B)', vector => 'A & B'},
        {source => '(== (+ A B) C)', vector => 'A + B', compare => 1},
    );
    for my $case (@cases) {for my $bits (1, 8) {
        my $source = "(?fsm:scalar_closure (+params (W $bits))"
            .' (+size (A (param W)) (B (param W)) (C (param W)) (DATA 1) (OTHER 1))'
            ." (idle (<$case->{source} (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
        my $raw = scalar Lispish::multi(\$source);
        my $before = $json->encode($raw);
        my $module = FSM::Adapter::FSMGenFull->new->parse_fsm($raw);
        my $core_before = source_profile($module);
        for my $language (qw(systemverilog verilog)) {
            my $ctx = FSM::HDL::FlattenedDT->new;
            my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
            my ($hdl, $error);
            {
                local $ctx->{declared_width_declaration_capture} = $capture;
                eval {$hdl = $language eq 'verilog' ? $ctx->generate_verilog($module)
                    : $ctx->generate_systemverilog($module); 1} or $error = $@;
            }
            is($error, undef, "$language $case->{source} at W=$bits") or diag($error);
            next if $error;
            my $snapshot = $capture->snapshot;
            my %assignments = $hdl =~ /^  assign (\w+) = ([^;]+);/mg;
            my $operand = $case->{operand};
            if ($case->{vector}) {
                my @vectors = grep {$assignments{$_} eq $case->{vector}} keys %assignments;
                is(scalar(@vectors), 1, 'complete vector child expression preserves source operands');
                next unless @vectors == 1;
                $operand = $vectors[0];
                like($hdl, qr/^  wire \[\(W - 1\):0\] \Q$operand\E;$/m,
                    'actual vector child retains its parameter range even at default one');
                is($snapshot->{target_declarations}{$operand}{width}, $bits,
                    'vector child numeric capture agrees with selected source width');
            }
            my @scalars = grep {
                my $text = $assignments{$_};
                $case->{scalar} ? $text eq $case->{scalar}
                    : $case->{compare} ? $text eq "$operand == C"
                    : $text eq "!$operand" || $text eq "(~|$operand)"
            } keys %assignments;
            is(scalar(@scalars), 1, 'complete scalar expression preserves comparison or whole-value NOT');
            next unless @scalars == 1;
            my $name = $scalars[0];
            like($hdl, qr/^  wire \Q$name\E;$/m, 'actual scalar result has no borrowed vector range');
            is($snapshot->{target_declarations}{$name}{width}, 1, 'complete target capture retains scalar result width');
            ok(!scalar(grep {exists($snapshot->{target_intermediates}{$name}{$_})}
                    qw(width_allocation graph_width_allocation source_tree_width_allocation)),
                'scalar result does not acquire a vector maximum allocation');
            is(source_profile($module), $core_before, 'Core widths expressions and parameter bindings conserve');
            is($json->encode($raw), $before, 'complete original caller source kinds conserve');
        }
    }}
};

done_testing();
