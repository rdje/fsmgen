use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::VHDL;
use FSM::Backend::VerilogFamily::DeclarationCapture;
use FSM::Backend::VHDL::DirectDeclarationPlan;

my $json = JSON::PP->new->canonical;
open my $fh, '<', 't/data/ial0-direct-symbolic-storage.fsm' or die $!;
my $source = do {local $/; <$fh>}; close $fh or die $!;
sub fixture {
    my ($text) = @_; $text //= $source;
    my $m = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(scalar Lispish::multi(\$text));
    my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $sv;
    {local $dt->{declared_width_declaration_capture} = $capture; $sv = $dt->generate_systemverilog($m)}
    my $ids = FSM::HDL::FlattenedDT::Backend::VHDL::_plan_generated_vhdl_identifiers($sv);
    my $plan = FSM::Backend::VHDL::DirectDeclarationPlan->prepare(fsm_module => $m,
        assignment_analysis => $dt->{assignment_analysis}, declaration_capture => $capture->snapshot,
        identifier_map => $ids->{identifier_map});
    return ($ids->{text}, $plan);
}
sub parse {return FSM::HDL::FlattenedDT::Backend::VHDL::_parse_direct_declarations(@_)}
sub by_name {return {map {$_->{name} => $_} @{$_[0]{ports}}, @{$_[0]{signals}}}}

subtest 'actual symbolic declarations retain selected numeric bounds and distinct target type rank' => sub {
    for my $width (1, 8) {
        my $text = $source =~ s/\(W 1\)/(W $width)/r;
        my ($sv, $plan) = fixture($text);
        my $before = $json->encode($plan);
        my $parsed = parse($sv, $plan);
        my $decls = by_name($parsed);
        for my $row (['DATA', $width, 'COPY'], ['INPUT_PORT', $width, 'W'],
            ['SPARE', $width + 1, '(W + 1)'], ['next_DATA', $width, 'COPY']) {
            my ($name, $n, $expr) = @$row;
            is_deeply($decls->{$name}, {name => $name,
                ($name eq 'INPUT_PORT' ? (direction => 'in') : $name eq 'next_DATA' ? (direction => 'out') : (kind => 'reg')),
                signed => 0, scalar => 0, msb => $n - 1, lsb => 0,
                vhdl_range => "(($expr - 1) downto 0)",
                vhdl_type => "std_logic_vector(($expr - 1) downto 0)"},
                "$name complete independent parsed declaration at default $width");
        }
        is_deeply($decls->{TYPED}, {name => 'TYPED', kind => 'logic', signed => 1,
            scalar => 0, msb => '3', lsb => '0'}, 'static signed named type keeps old parser product');
        is_deeply($decls->{FIXED}, {name => 'FIXED', direction => 'in', msb => undef,
            lsb => undef, scalar => 1}, 'independent scalar keeps old product');
        is($json->encode($plan), $before, 'complete plan and JSON kinds are read-only');
        $parsed->{ports}[0]{name} = 'mutated';
        is($json->encode($plan), $before, 'returned declarations share no mutable plan graph');
    }
};
subtest 'physical mapping uses normalized names without changing lexical ownership' => sub {
    my $text = $source =~ s/direct_symbolic_storage/direct__symbolic_storage/r;
    $text =~ s/INPUT_PORT/_INPUT_PORT/g;
    my ($sv, $plan) = fixture($text);
    my $parsed = parse($sv, $plan);
    is($parsed->{module}{name}, 'direct_symbolic_storage', 'normalized module is parsed');
    ok(exists(by_name($parsed)->{INPUT_PORT}), 'normalized port joins original capture');
    is($plan->{source_scope}{owner}, 'direct__symbolic_storage', 'lexical owner remains original');
};
subtest 'complete text membership roles and exact symbolic spelling are required' => sub {
    my ($sv, $plan) = fixture();
    for my $case (
        ['missing port', sub {$_[0] =~ s/^.*input\s+wire .*INPUT_PORT,?\n//m}, qr/membership/],
        ['extra port', sub {$_[0] =~ s/(\n\);)/,\n    input wire FOREIGN$1/}, qr/membership/],
        ['wrong range', sub {$_[0] =~ s/\[\(W - 1\):0\]/[(COPY - 1):0]/}, qr/range/],
        ['equivalent spelling', sub {$_[0] =~ s/\[\(W - 1\):0\]/[W-1:0]/}, qr/range/],
        ['numeric substitute', sub {$_[0] =~ s/\[\(W - 1\):0\]/[0:0]/}, qr/range/],
        ['wrong signedness', sub {$_[0] =~ s/input\s+wire \[/input logic signed [/}, qr/signed/],
        ['missing storage', sub {$_[0] =~ s/^\s*reg .* DATA;\n//m}, qr/membership/],
        ['extra storage', sub {$_[0] =~ s/\nendmodule/\nwire FOREIGN;\nendmodule/}, qr/membership/],
        ['wrong role', sub {$_[0] =~ s/^\s*reg (.*) DATA;$/reg $1 INPUT_PORT;/m}, qr/role|duplicate|membership/],
        ['duplicate storage', sub {$_[0] =~ s/\nendmodule/\nreg [(COPY - 1):0] DATA;\nendmodule/}, qr/duplicate|membership/],
        ['foreign module', sub {$_[0] =~ s/module direct_symbolic_storage/module FOREIGN/}, qr/module/],
        ['wrong static width', sub {$_[0] =~ s/logic signed \[3:0\] TYPED/logic signed [4:0] TYPED/}, qr/width/],
        ['duplicate port', sub {$_[0] =~ s/(\n\);)/,\n    input wire FIXED$1/}, qr/duplicate/],
        ['missing fixed port', sub {$_[0] =~ s/^.*input\s+wire FIXED,\n//m}, qr/membership/],
    ) {
        my ($label, $mutate, $error) = @$case;
        my $changed = $sv; $mutate->($changed);
        isnt($changed, $sv, "$label control changes actual generated text");
        my $before = $json->encode($plan);
        ok(!eval {parse($changed, $plan); 1}, "$label refuses");
        like($@, $error, "$label explains its refusal");
        is($json->encode($plan), $before, "$label keeps the complete supplied plan");
    }
};
subtest 'missing and inconsistent prepared records cannot authorize text' => sub {
    my ($sv, $original) = fixture();
    for my $case (
        ['absent plan', sub {$_[0] = undef}, qr/prepared paired plan/],
        ['missing symbolic entry', sub {delete $_[0]{ranges}{INPUT_PORT}}, qr/unsupported generated port/],
        ['wrong planned role', sub {$_[0]{ranges}{DATA}{declaration_kind} = 'port'}, qr/role/],
        ['wrong selected width', sub {$_[0]{target_declarations}{DATA}{width} = 8}, qr/width/],
        ['foreign physical mapping', sub {$_[0]{target_namespace}{ports}[0] = 'FOREIGN'}, qr/membership/],
    ) {
        my ($label, $mutate, $error) = @$case;
        my $plan = $json->decode($json->encode($original)); $mutate->($plan);
        ok(!eval {parse($sv, $plan); 1}, "$label refuses");
        like($@, $error, "$label has a contextual refusal");
    }
};
subtest 'static declarations preserve complete legacy parser products' => sub {
    my $text = $source =~ s/\(param COPY\)/1/gr; $text =~ s/\(param W\)/1/g;
    my ($sv, $plan) = fixture($text);
    my $parsed = parse($sv, $plan);
    my $module = FSM::HDL::FlattenedDT::Backend::VHDL::_parse_module($sv);
    my %types = FSM::HDL::FlattenedDT::Backend::VHDL::_parse_packed_struct_typedef_widths($sv);
    my @ports = FSM::HDL::FlattenedDT::Backend::VHDL::_parse_ports($module->{ports}, \%types);
    my @signals = FSM::HDL::FlattenedDT::Backend::VHDL::_parse_signal_declarations($module->{body}, {map {$_->{name} => 1} @ports});
    is($json->encode($parsed->{ports}), $json->encode(\@ports), 'whole ordered static port records conserve with JSON kinds');
    is($json->encode($parsed->{signals}), $json->encode(\@signals), 'whole ordered static storage records conserve with JSON kinds');
};
subtest 'raw conversion and unqualified generated auxiliary shapes remain refused' => sub {
    my ($sv, $plan) = fixture();
    my $backend = FSM::HDL::FlattenedDT::Backend::VHDL->new(flattened_dt => {});
    ok(!eval {$backend->convert_systemverilog_to_vhdl($sv); 1}, 'raw symbolic text remains refused');
    like($@, qr/unsupported generated port declaration/, 'raw refusal still comes from bounded numeric parser');
    my $m = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(scalar Lispish::multi(\$source));
    ok(!eval {FSM::HDL::FlattenedDT->new(debug => 0)->generate_vhdl($m); 1}, 'unqualified symbolic register helpers return no artifact');
    like($@, qr/symbolic source auxiliary register shapes/, 'actual auxiliary allocation owns the source refusal');
};
done_testing();
