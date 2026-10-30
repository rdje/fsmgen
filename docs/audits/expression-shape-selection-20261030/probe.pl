use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::Backend::VerilogFamily::DeclarationCapture;
use FSM::CoreExpressionWidthSupport;

# Native parse/generation only: no HDL compiler, override or runtime claim.
# Independent expectations follow expression shape, not helper names or totals.
my @cases = (
    ['concat', '(concat A B)', 11],
    ['slice', 'A[6:2]', 5],
    ['bit', 'A[2]', 1],
    ['shift_left', '(<< A AMOUNT)', 8],
    ['shift_right', '(>> A AMOUNT)', 8],
    ['shift_unsized_amount', '(<< A 1)', 8],
    ['concat_shift', '(concat (<< A AMOUNT) B)', 11],
);
my $json = JSON::PP->new->canonical;
my @results;
for my $mutable (0, 1) {
    for my $case (@cases) {
        my ($name, $expression, $expected) = @$case;
        my $parameters = $mutable ? '(+params (W 8))' : '';
        my $width = $mutable ? '(param W)' : '8';
        my $source = "(?fsm:shape_probe $parameters (+size (A $width) (B 3) (AMOUNT 64) (DATA 1) (OTHER 1))"
            ." (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
        my $raw = scalar Lispish::multi(\$source);
        my $caller_before = $json->encode($raw);
        my $adapter = FSM::Adapter::FSMGenFull->new;
        my $module = $adapter->parse_fsm($raw);
        my $parsed_expression = $expression =~ /^\(/ ? (scalar Lispish::multi(\$expression))->[0] : $expression;
        my $core_expression = $adapter->{expression_builder}->parse_expression($parsed_expression);
        my $selected = FSM::CoreExpressionWidthSupport->infer_width($core_expression);
        my $row = {case => $name, mutable => $mutable, source => $source,
            expression => $core_expression->to_systemverilog,
            expected_shape_width => $expected, core_exact_width => $selected, backends => {}};
        for my $language (qw(systemverilog verilog)) {
            my $backend = FSM::HDL::FlattenedDT->new;
            my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
            my ($hdl, $error);
            {
                local $backend->{declared_width_declaration_capture} = $capture;
                eval {$hdl = $language eq 'verilog' ? $backend->generate_verilog($module)
                    : $backend->generate_systemverilog($module); 1} or $error = $@;
            }
            # Retain the contextual first failure; machine paths/stack frames
            # are not part of the shared observation.
            $error =~ s/\n at .*\z//s if defined $error;
            my $snapshot = eval {$capture->snapshot};
            my $capture_error = $@ || undef;
            $capture_error =~ s/\n at .*\z//s if defined $capture_error;
            $row->{backends}{$language} = {error => $error, snapshot => $snapshot,
                capture_error => $capture_error,
                declarations => [grep {/\b(?:wire|reg|logic)\b/} split /\n/, $hdl // ''],
                assignments => [grep {/\bassign\b/} split /\n/, $hdl // '']};
        }
        die "caller source changed\n" unless $json->encode($raw) eq $caller_before;
        $row->{caller_preserved} = JSON::PP::true;
        push @results, $row;
    }
}
print $json->pretty->encode({schema_version => 1, cases => \@results});
