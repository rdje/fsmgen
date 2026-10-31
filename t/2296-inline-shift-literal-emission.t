use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::Backend::VerilogFamily::DeclarationCapture;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport;

my $literal = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport';
my $json = JSON::PP->new->canonical;
sub fixture {
    my (%args) = @_;
    my $params = $args{mutable} ? '(+params (W 8))' : '';
    my $width = $args{mutable} ? '(param W)' : 8;
    my $expression = $args{expression} // '(| (<< A 1) B)';
    # Self-updates exercise output marking, repeated sizing and reconciliation,
    # in addition to the guard-only consumer used by earlier literal tests.
    my $body = $args{assignment} ? "(<- (A> $expression))"
        : "(<$expression (= (DATA 1)) (= (OTHER 1)))";
    $body = "(<= (data A)) (<- (data $expression))" if $args{sampled};
    my $text = "(?fsm:inline_shift $params (+size (A $width) (B 1) (S 128) (DATA 1) (OTHER 1))"
        . " (idle $body (-> idle)))";
    my $raw = scalar Lispish::multi(\$text);
    my $original = $json->encode($raw);
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm($raw);
    is($json->encode($raw), $original, 'caller source stays unchanged');
    return $module;
}
sub generate {
    my ($module, %args) = @_;
    my $ctx = FSM::HDL::FlattenedDT->new;
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my ($hdl, $error);
    my $tail = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationTailSupport';
    my $original = $tail->can('generate_systemverilog_tail');
    {
        no strict 'refs'; no warnings 'redefine';
        local *{"${tail}::generate_systemverilog_tail"} = sub {
            my $result = $original->(@_);
            $args{late}->($module, $ctx) if $args{late};
            return $result;
        };
        local $ctx->{declared_width_declaration_capture} = $capture;
        eval {
            $hdl = $args{verilog} ? $ctx->generate_verilog($module)
                : $ctx->generate_systemverilog($module);
            1;
        } or $error = $@;
    }
    return {hdl => $hdl, error => $error, capture => $capture};
}
sub helpers {
    my ($module) = @_;
    return map {$module->signals->{$_}}
        grep {$module->signals->{$_}{attributes}{is_intermediate}}
        sort keys %{$module->signals};
}
sub refused {
    my ($result, $pattern) = @_;
    like($result->{error} // '', $pattern, 'original proof refuses the changed or unsupported source');
    ok(!defined($result->{hdl}), 'no HDL escapes refusal');
    ok(!eval {$result->{capture}->snapshot; 1}, 'partial declaration capture stays unavailable');
}

subtest 'amount widths do not become data widths in actual declarations' => sub {
    for my $operator ('<<', '>>') {
        for my $amount ('1', "128'd1", 'S') {
            for my $verilog (0, 1) {
                my $data = $amount eq 'S' ? "1'b0" : 'B';
                my $module = fixture(expression => "(| ($operator A $amount) $data)");
                my ($helper) = helpers($module);
                ok($helper->source_literal_width_allocation, 'original completed inline-shift source exists');
                my $observation = $literal->prepare(signal => $helper);
                is($observation->{selected_width}, '8', 'independent data maximum is eight');
                is($observation->{literal_floor}, $amount eq 'S' ? '1' : undef,
                    'only data literals supply a literal floor');
                my $result = generate($module, verilog => $verilog);
                is($result->{error}, undef, 'actual HDL generation succeeds') or diag($result->{error});
                next if $result->{error};
                my $name = $helper->name;
                is($result->{capture}->snapshot->{target_declarations}{$name}{width}, 8,
                    'physical declaration consumes only the data width');
                like($result->{hdl}, qr/^  wire \[7:0\] \Q$name\E;$/m, 'actual HDL declares the same vector');
                like($result->{hdl}, qr/\bA\s*\Q$operator\E/, 'actual expression retains the shift');
            }
        }
    }
};

subtest 'data literals and self-updates retain independent target sizing' => sub {
    for my $case (["(| (<< A 1) 0)", 32], ["(| (>> A 128'd1) 1'b0)", 8]) {
        my ($expression, $expected) = @$case;
        my $module = fixture(expression => $expression, assignment => 1);
        my ($helper) = helpers($module);
        my $record = $helper->source_literal_width_allocation;
        ok($record, 'self-update retains the original birth after ordinary parser operations');
        is($record->{selected_width}, $expected == 32 ? undef : 8,
            'Core unknown unsized result remains distinct from target sizing');
        my $result = generate($module);
        is($result->{error}, undef, 'self-update generation succeeds') or diag($result->{error});
        next if $result->{error};
        is($result->{capture}->snapshot->{target_declarations}{$helper->name}{width}, $expected,
            'data literal floor contributes while amount width does not');
    }
};

subtest 'amount edits remain in original and final currentness fences' => sub {
    for my $late (0, 1) {
        my $module = fixture;
        my ($helper) = helpers($module);
        my $change = sub {$helper->{driving_ast}{operands}[0]{operands}[1]{value} = 2};
        $change->() unless $late;
        refused(generate($module, $late ? (late => $change) : ()),
            $late ? qr/Direct literal emission requires complete current selected targets/
                : qr/Direct literal emission requires current completed source intent/);
    }
    my $module = fixture;
    $module->signals->{A}{signed} = 1;
    refused(generate($module), qr/Direct literal emission requires current completed source intent/);
};

subtest 'input-named storage joins the actual normalized assignment source' => sub {
    for my $replace_lhs (0, 1) {
        my $module = fixture(sampled => 1, expression => '(| (<< data 1) 0)');
        ok(!exists($module->signals->{data}), 'sampled storage is outside the module port/helper map');
        my ($helper) = helpers($module);
        my $result = generate($module, $replace_lhs ? (late => sub {
            my ($module, $ctx) = @_;
            my $entry = $ctx->{assignment_analysis}{data};
            $entry->{lhs_ast} = FSM::CoreAST::SignalRef->new($entry->{lhs_ast}->signal);
        }) : ());
        if ($replace_lhs) {
            refused($result, qr/Direct literal emitted declarations disagree with complete selected targets/);
        } else {
            is($result->{error}, undef, 'actual sampled storage generates') or diag($result->{error});
            next if $result->{error};
            is($result->{capture}->snapshot->{target_declarations}{$helper->name}{width}, 32,
                'original storage and independent data literal prove the helper width');
        }
    }
};

subtest 'mutable and standalone shift families gain no literal policy' => sub {
    my $module = fixture(mutable => 1);
    my ($helper) = helpers($module);
    ok(!$helper->source_literal_width_allocation, 'mutable data source remains outside this fixed profile');
    refused(generate($module), qr/Direct literal emission requires current completed source intent/);
    my $standalone = fixture(expression => '(<< A 1)');
    for my $signal (helpers($standalone)) {
        ok(!$signal->source_literal_width_allocation, 'standalone shift retains separate allocation ownership');
    }
};

done_testing();
