use strict;
use warnings;
use lib 'perl';
use Test::More;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::Backend::VerilogFamily::DeclarationCapture;
subtest 'remaining top-level duplicate and negated bitwise families preserve actual range and original slots' => sub {
    for my $case (['(| A A C)','|',[qw(A A C)]],['(^ A B A)','^',[qw(A B A)]],['(!& A B C)','&',[qw(A B C)]]) {
        for my $width (1,8) {
            my $text="(?fsm:family_closure (+params (W $width))"
                .' (+size (A (param W)) (B (param W)) (C (param W)) (DATA 1) (OTHER 1))'
                ." (idle (<$case->[0] (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
            my $module=FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$text));
            my $ctx=FSM::HDL::FlattenedDT->new;
            my $capture=FSM::Backend::VerilogFamily::DeclarationCapture->new;
            my ($hdl,$error);
            {
                local $ctx->{declared_width_declaration_capture}=$capture;
                eval {$hdl=$width==1 ? $ctx->generate_verilog($module) : $ctx->generate_systemverilog($module);1} or $error=$@;
            }
            is($error,undef,"actual $case->[0] generates at width $width") or diag $error;
            next if $error;
            my $snapshot=$capture->snapshot;
            my @roots=grep {exists($snapshot->{target_intermediates}{$_}{source_tree_width_allocation})}
                keys %{$snapshot->{target_intermediates}};
            is(scalar @roots,1,'fixture has one source bitwise base helper');
            my $name=$roots[0]; my $event=$snapshot->{target_intermediates}{$name};
            is($event->{source_tree_origin}{operator},$case->[1],'authored base operator preserves');
            is_deeply($event->{source_tree_origin}{source_names},$case->[2],'authored duplicate and ordered slots preserve');
            my @leaves=map {['signal',$_]} @{$case->[2]};
            is_deeply($event->{source_tree_origin}{expression_tree},[$case->[1],[$case->[1],@leaves[0,1]],$leaves[2]],
                'actual complete original association remains left-folded');
            is($snapshot->{target_declarations}{$name}{width},$width,'native numeric metadata stays the selected width');
            like($hdl,qr/^  wire \[\(W - 1\):0\] \Q$name\E;$/m,'actual helper keeps the parameter-dependent vector range');
            if ($case->[0]=~/^\(!/) {
                my @zero_tests=grep {
                    my $e=$snapshot->{target_intermediates}{$_}{expression};
                    defined($e) && ($e eq "!$name" || $e eq "(~|$name)");
                } keys %{$snapshot->{target_intermediates}};
                ok(@zero_tests,'negated base has an actual whole-value scalar zero test');
                is($snapshot->{target_declarations}{$_}{width},1,'logical negation result remains scalar') for @zero_tests;
            }
        }
    }
};
done_testing();
