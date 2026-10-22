use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr);
use Storable qw(dclone);
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Adapter::FSMGenFull;
use FSM::Adapter::FSMGenFull::SignalManager;
use FSM::Adapter::FSMGenFull::ExpressionBuilder;
use FSM::HDL::FlattenedDT;
use FSM::Support::SemanticIntrospectionMCPAdapter;
use Lispish;

# ISF-REDUCTION-DELIVERY.1.2.3.2.1: ordinary XOR factoring must not
# turn an authored input into a generated, internally driven helper.
# These checks inspect real native products and AST ownership, without
# executing an external HDL compiler or simulator.
my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical;
sub capture { FSM::Test::SourceQueryRunner::_capture($_[0], $_[1] // '') }
sub same { is($json->encode($_[0]), $json->encode($_[1]), $_[2]) }
sub write_file {
    my ($name, $text) = @_;
    my $path = "$work/$name";
    open my $fh, '>', $path or die $!;
    print {$fh} $text;
    close $fh or die $!;
    $path =~ s/\A\Q$root\E\///;
    return $path;
}
my $source = <<'ISF';
(actor namespace_capture
 (clock clk) (reset (rst_n sync active_low))
 (interface (input start) (input data (width 8)) (input other (width 8))
  (input intermediate_xor_data_other_1 (width 8))
  (input intermediate_complex_expr_2)
  (output copied_vector (width 8)) (output copied_bit)
  (output combined (width 8)) (output parity) (output done))
 (transaction main (on start) (complete done))
 (rule copy_vector start (copied_vector intermediate_xor_data_other_1))
 (rule copy_bit start (copied_bit intermediate_complex_expr_2))
 (rule binary start (combined (^ data other)))
 (rule unrolled start (parity (^ data[0] data[1] data[2] data[3]
   data[4] data[5] data[6] data[7]))))
ISF
my $renamed = $source;
$renamed =~ s/intermediate_xor_data_other_1/external_vector/g;
$renamed =~ s/intermediate_complex_expr_2/external_bit/g;
my $reduction = $source;
$reduction =~ s/\(output done\)/(output reduced (width 3)) (output done)/;
$reduction =~ s/\)\s*\z/ (rule reduce start (reduced (concat (^ data) (\& data) (| data)))))\n/;
my @cases = (
    {name => 'ordinary', text => $source,
        vector => 'intermediate_xor_data_other_1', bit => 'intermediate_complex_expr_2'},
    {name => 'renamed', text => $renamed, vector => 'external_vector', bit => 'external_bit'},
    {name => 'reduction', text => $reduction,
        vector => 'intermediate_xor_data_other_1', bit => 'intermediate_complex_expr_2'},
);
$_->{path} = write_file("$_->{name}.isf", $_->{text}) for @cases;

subtest 'occupied identities cannot be reused or promoted into helpers' => sub {
    my $manager = FSM::Adapter::FSMGenFull::SignalManager->new;
    my $builder = FSM::Adapter::FSMGenFull::ExpressionBuilder->new(signal_manager => $manager);
    $manager->register_signal($_, width => 8) for qw(data other);
    my @original = map {
        $manager->register_signal("intermediate_xor_data_other_$_", width => 3,
            signal_role => 'INPUT', width_declared => 1)
    } 1..3;
    my $before = [map {dclone($_->attributes)} @original];
    my $actual = $builder->parse_expression(['^', 'data', 'other']);
    is($actual->signal->name, 'intermediate_xor_data_other_4', 'skip the complete occupied suffix run');
    for my $i (0..$#original) {
        isnt(refaddr($actual->signal), refaddr($original[$i]), 'helper owns a different signal object');
        is($original[$i]->width, 3, 'authored width remains unchanged');
        same($original[$i]->attributes, $before->[$i], 'authored role and complete attributes unchanged');
        ok(!defined($original[$i]->driving_ast), 'authored input acquires no driver');
    }
    is($actual->signal->driving_ast->to_systemverilog, 'data ^ other', 'new helper retains the actual operand expression');
    my $next = $builder->parse_expression(['^', 'data', 'other']);
    is($next->signal->name, 'intermediate_xor_data_other_5', 'later helpers remain distinct');

    # Zero-valued declarations are occupied identities, independently of
    # their resolution/value. Exercise each authoritative namespace owner.
    my $symbols = FSM::Adapter::FSMGenFull::SignalManager->new;
    my $names = FSM::Adapter::FSMGenFull::ExpressionBuilder->new(signal_manager => $symbols);
    my $prefix = 'intermediate_xor_data_other_';
    $symbols->register_signal($prefix.'1', width => 1);
    $symbols->store_constant($prefix.'2', FSM::CoreAST::Literal->new('0'));
    $symbols->record_constant_definition($prefix.'3');
    $symbols->store_enum($prefix.'4', {ZERO => 0});
    $symbols->store_define($prefix.'5', FSM::CoreAST::Literal->new('0'));
    $symbols->store_param($prefix.'6', 0);
    $symbols->store_type($prefix.'7', {kind => 'bits', width => 1});
    $symbols->store_aggregate_symbol($prefix.'8', {zero => 0});
    my @operands = map {FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name => $_))} qw(data other);
    is($names->generate_intermediate_signal('^', \@operands), $prefix.'9',
        'all declared symbol kinds reserve their names, including zero values');
};

sub inspect_generated {
    my ($hdl, $vector, $bit, $label) = @_;
    for my $input ($vector, $bit) {
        unlike($hdl, qr/^\s*wire\s+(?:\[[^\]]+\]\s+)?\Q$input\E\s*;/m,
            "$label no internal redeclaration of $input");
        unlike($hdl, qr/^\s*assign\s+\Q$input\E\s*=/m, "$label no internal driver for $input");
    }
    like($hdl, qr/input\s+wire\s+\[7:0\]\s+\Q$vector\E\s*,/, "$label external vector port retains width");
    like($hdl, qr/input\s+wire\s+\Q$bit\E\s*,/, "$label external bit port remains scalar");
    like($hdl, qr/copied_vector_next\s*=\s*\Q$vector\E\s*;/, "$label copied vector reads the authored input");
    like($hdl, qr/copied_bit_next\s*=\s*\Q$bit\E\s*;/, "$label copied bit reads the authored input");
    my ($helper) = $hdl =~ /^\s*assign\s+(\w+)\s*=\s*data \^ other\s*;/m;
    ok(defined($helper), "$label actual binary expression has a helper");
    isnt($helper, $vector, "$label computed binary and authored input identities differ");
    like($hdl, qr/if \((\w+)\) begin\s+combined_next = \Q$helper\E;/,
        "$label actual output mux uses the computed helper under its enable");
    like($hdl, qr/^\s*assign\s+\w+\s*=\s*data\[0\] \^ data\[1\] \^ data\[2\] \^ data\[3\] \^ data\[4\] \^ data\[5\] \^ data\[6\] \^ data\[7\];/m,
        "$label unchanged unrolled expression retains all bits");
}

subtest 'native inputs, canonical carriers and real generated muxes preserve distinct ownership' => sub {
    for my $case (@cases) {
        my $actor = FSM::Adapter::ISF->new->parse_file($case->{path});
        my $before = $json->encode($actor);
        my $lowered = FSM::Scheduler::ISF->new->lower($actor);
        is($json->encode($actor), $before, "$case->{name} lowering preserves complete caller data/kinds");
        my ($carrier) = values %{$lowered->{files}};
        my $carrier_path = write_file("$case->{name}.fsm", $carrier);
        for my $path ($case->{path}, $carrier_path) {
            my $semantic = capture([$^X, 'bin/fsmgen', qw(--strict --emit-semantic-json), $path]);
            is($semantic->{exit_code}, 0, "$path native semantic succeeds") or diag($semantic->{stderr});
            my $report = $json->decode($semantic->{stdout});
            my $inputs = $report->{semantic}{signal_analysis}{inputs};
            my @expected = map {+{name => $_->[0], width => $_->[1], direction => 'input', signed => 0}}
                (['start', 1], ['data', 8], ['other', 8], [$case->{vector}, 8], [$case->{bit}, 1]);
            same([sort {$a->{name} cmp $b->{name}} @$inputs],
                [sort {$a->{name} cmp $b->{name}} @expected],
                "$path literal declared input inventory survives factoring");
            my $hdl_path = "$work/$case->{name}-" . ($path eq $case->{path} ? 'source' : 'carrier') . '.sv';
            my $generated = capture([$^X, 'bin/fsmgen', '--strict', '--output', $hdl_path, $path]);
            is($generated->{exit_code}, 0, "$path native SV generation succeeds") or diag($generated->{stderr});
            next if $generated->{exit_code};
            open my $fh, '<', $hdl_path or die $!;
            my $hdl = do {local $/; <$fh>};
            close $fh or die $!;
            inspect_generated($hdl, $case->{vector}, $case->{bit}, $path);
        }
        # Exercise declarations after state bodies through the actual emitted
        # carrier AST. The parser's header prepass must remain order independent.
        my $parsed = Lispish::multi(\$carrier);
        my $module_ast = $parsed->[0];
        my @header = grep {ref($_) eq 'ARRAY' && $_->[0] =~ /^\+(?:size|interface)$/} @{$module_ast->[1]};
        my @rest = grep {!(ref($_) eq 'ARRAY' && $_->[0] =~ /^\+(?:size|interface)$/)} @{$module_ast->[1]};
        ok(@header > 0, 'source-order control moves real emitted declaration sections');
        my $reordered = [$module_ast->[0], [@rest, @header]];
        my $module = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm([$reordered]);
        inspect_generated(FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($module),
            $case->{vector}, $case->{bit}, "$case->{name} reordered carrier");
    }
};

subtest 'complete native, API and newline reports agree for ordinary and reduction sources' => sub {
    my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
    for my $case (@cases[0,2]) {
        for my $mode (
            [[qw(--strict --check --json)], 'fsmgen_check'],
            [[qw(--strict --emit-semantic-json)], 'fsmgen_semantic_introspect'],
            [['--emit-schedule-json'], 'fsmgen_schedule_preview'],
        ) {
            my ($flags, $tool) = @$mode;
            my $native = capture([$^X, 'bin/fsmgen', @$flags, $case->{path}]);
            is($native->{exit_code}, 0, "$case->{name} $tool native success");
            is($native->{stderr}, '', 'native stderr remains clean');
            my $report = normalize_repository_paths($json->decode($native->{stdout}), $root);
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $tool, arguments => {source_id => $case->{path}}}};
            my $response = $api->handle_jsonrpc_request($request);
            my $result = $response->{result};
            ok(ref($result) eq 'HASH' && !$result->{isError}, 'API reports success');
            same($result->{structuredContent}{report}, $report, 'complete native/API report equality');
            same($json->decode($result->{content}[0]{text}), $result->{structuredContent}, 'complete serialized/structured envelope equality');
            my $wire = capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
            is($wire->{exit_code}, 0, 'actual newline process settles');
            is($wire->{stderr}, '', 'newline stderr remains clean');
            like($wire->{stdout}, qr/\A[^\n]+\n\z/, 'one compact newline response');
            same($json->decode($wire->{stdout}), $response, 'complete API/newline response equality');
        }
    }
};

done_testing();
