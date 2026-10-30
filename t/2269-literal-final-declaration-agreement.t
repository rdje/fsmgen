use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::DirectDeclaredWidthSupport;
use FSM::Backend::VerilogFamily::DeclarationCapture;

my $json = JSON::PP->new->canonical;
sub copy {return $json->decode($json->encode($_[0]))}
sub fixture {
    my (%args) = @_;
    my ($w,$x) = ($args{wide} ? 64 : 1, $args{wide} ? 128 : 1);
    my $params = $args{fixed} ? '' : "(+params (W $w) (X $x))";
    my $sizes = $args{fixed} ? '(A 8) (B 64)' : '(A (param W)) (B (param X))';
    my $literal = $args{explicit} ? "9'b100000000" : '256';
    my $expression = $args{direct} ? "(| A $literal)" : "(^ (| A $literal) B)";
    my $text = "(?fsm:literal_final $params (+size $sizes (DATA 1) (OTHER 1))"
        ." (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $raw = scalar Lispish::multi(\$text);
    my $original = $json->encode($raw);
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm($raw);
    my $ctx = $args{ctx} // FSM::HDL::FlattenedDT->new;
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my @names = sort grep {exists $module->signals->{$_}{_source_literal_width_allocation}} keys %{$module->signals};
    my $core = copy({map {$_ => {width => $module->signals->{$_}{_width},
        holder => $module->signals->{$_}{_source_literal_width_allocation}}} @names});
    my $p = {ctx => $ctx, module => $module, capture => $capture, names => \@names};
    my $complete = FSM::Backend::VerilogFamily::DeclarationCapture->can('complete');
    {
        no warnings 'redefine';
        local *FSM::Backend::VerilogFamily::DeclarationCapture::complete = sub {
            $complete->(@_);
            $p->{snapshot} = $_[0]->snapshot;
            $args{probe}->($p) if $args{probe};
        };
        local $ctx->{declared_width_declaration_capture} = $capture;
        eval {$p->{hdl} = $ctx->generate_systemverilog($module); 1} or $p->{error} = $@;
    }
    is($json->encode($raw), $original, 'caller source kinds preserve');
    is_deeply(copy({map {$_ => {width => $module->signals->{$_}{_width},
        holder => $module->signals->{$_}{_source_literal_width_allocation}}} @names}), $core,
        'Core allocation and original nullable source policy preserve');
    return $p;
}
sub declarations {
    my ($p, %extra) = @_;
    return FSM::DirectDeclaredWidthSupport->prepare_declarations(fsm_module => $p->{module},
        assignment_analysis => $p->{ctx}{assignment_analysis}, target_language => 'systemverilog',
        %{$p->{snapshot}}, %extra);
}

subtest 'actual unknown Core widths agree with independently selected physical maxima' => sub {
    for my $fixed (0,1) {for my $direct (0,1) {for my $wide (0,1) {for my $explicit (0,1) {
        my $p = fixture(fixed => $fixed, direct => $direct, wide => $wide, explicit => $explicit);
        is($p->{error}, undef, 'actual final generation succeeds') or diag($p->{error});
        next if $p->{error};
        ok(eval {declarations($p)}, 'complete declaration validator independently rederives agreement') or diag($@);
        for my $name (@{$p->{names}}) {
            my $event = $p->{snapshot}{target_intermediates}{$name};
            my $parent = $event->{expression} !~ /(?:256|100000000)/;
            my $expected = $fixed ? ($parent ? 64 : $explicit ? 9 : 32)
                : $wide ? ($parent ? 128 : 64) : $explicit ? 9 : 32;
            is($p->{snapshot}{target_declarations}{$name}{width}, $expected,
                'physical helper matches independent literal/leaf algebra');
            if (!$explicit) {
                is($p->{module}{signals}{$name}{_width}, 1, 'unknown Core compatibility placeholder stays one');
                is($p->{module}{signals}{$name}{_source_literal_width_allocation}{record}{selected_width},
                    undef, 'exact Core source allocation remains unknown');
            }
        }
    }}}}
};

subtest 'placeholder equalities and ordinary width type state signedness mismatches refuse' => sub {
    fixture(direct => 1, probe => sub {
        my $p = shift;
        for my $change (
            sub {$_[0]{target_declarations}{$_[1]}{width} = 1},
            sub {$_[0]{target_declarations}{$_[1]}{width} = 31},
            sub {$_[0]{target_declarations}{$_[1]}{signed} = 1},
            sub {$_[0]{target_declarations}{$_[1]}{declared_type_name} = 'foreign'},
            sub {$_[0]{target_declarations}{$_[1]}{state_model} = 'foreign'},
            sub {$_[0]{target_declarations}{A}{width} = 32},
        ) {
            local $p->{snapshot} = copy($p->{snapshot});
            $change->($p->{snapshot},$p->{names}[0]);
            ok(!eval {declarations($p); 1}, 'invalid actual width/profile cannot borrow literal authority');
        }
        ok(!eval {declarations($p, target_language => 'vhdl'); 1},
            'Verilog-family literal agreement grants no VHDL exception');
    });
};

subtest 'last source observation cannot change an earlier proved literal' => sub {
    fixture(probe => sub {
        my $p = shift;
        my $literal = $p->{module}{signals}{$p->{names}[0]}{driving_ast}{operands}[1];
        local $literal->{value} = $literal->{value};
        my $current = FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport->can('current');
        my $fired = 0;
        {
            no warnings 'redefine';
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport::current = sub {
                my ($class,%args) = @_;
                my $result = $current->(@_);
                if ($args{signal}->name eq $p->{names}[-1]) {
                    $literal->{value} = '257'; ++$fired;
                }
                return $result;
            };
            ok(!eval {declarations($p);1}, 'late mutation returns no final agreement');
            like($@,qr/source changed during final proof/, 'whole-set raw barrier catches the late earlier-source write');
        }
        is($fired,1,'intervention follows the last source observation');
    });
};

done_testing();
