use strict;
use warnings;
use lib 'perl';
use Test::More;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::DirectDeclaredWidthSupport;
use FSM::Backend::VerilogFamily::DeclarationCapture;

my $text = q{(?fsm:literal_atomic (+params (W 1) (X 1))
 (+size (A (param W)) (B (param X)) (DATA 1) (OTHER 1))
 (idle (<(^ (| A 256) B) (= (DATA 1)) (= (OTHER 1))) (-> idle)))};
my $ctx = FSM::HDL::FlattenedDT->new;
my $full = FSM::DirectDeclaredWidthSupport->can('prepare_declarations');
my $current = FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport->can('current');

subtest 'a failed final literal observation invalidates capture and permits fresh reuse' => sub {
    for my $corrupt (1,0) {
        my $input = $text;
        my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$input));
        my @names = sort grep {exists $module->signals->{$_}{_source_literal_width_allocation}} keys %{$module->signals};
        is(scalar(@names),2,'actual nested source supplies two distinct literal helpers');
        my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
        my ($hdl,$error,$fired);
        {
            no warnings 'redefine';
            local *FSM::DirectDeclaredWidthSupport::prepare_declarations = sub {
                local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport::current = sub {
                    my ($class,%args) = @_;
                    my $result = $current->(@_);
                    if ($corrupt && !$fired && $args{signal}->name eq $names[-1]) {
                        $module->signals->{$names[0]}{driving_ast}{operands}[1]{value} = '257';
                        ++$fired;
                    }
                    return $result;
                };
                return $full->(@_);
            };
            local $ctx->{declared_width_declaration_capture} = $capture;
            eval {$hdl = $ctx->generate_systemverilog($module);1} or $error = $@;
        }
        if ($corrupt) {
            is($fired,1,'intervention follows the last final declaration source observation');
            like($error // '',qr/source changed during final proof/,'final raw agreement rejects the earlier literal mutation');
            ok(!defined($hdl),'no HDL escapes a failed final agreement');
            ok(!eval {$capture->snapshot;1},'failed final agreement invalidates completed capture');
        } else {
            is($error,undef,'fresh same-backend generation succeeds') or diag($error);
            ok(defined($hdl) && eval {$capture->snapshot;1},'fresh generation returns HDL and complete capture');
            like($hdl,qr/A \| 256/,'fresh source expression has no failed-run residue');
        }
        ok(!exists($ctx->{direct_declared_width_emitted_literal_ranges})
            && !exists($ctx->{direct_declared_width_emitted_literal_assignments}),
            'generation-local ledgers leave no backend residue');
    }
};
done_testing();
