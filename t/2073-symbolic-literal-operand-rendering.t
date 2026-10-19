use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use Digest::SHA qw(sha256_hex);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::ExpressionNamer;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::OperandContractValidationSupport;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical;
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);

for my $case (
    ['xz', 'const_3bx01', 3, "3'bx01"],
    ['mixed', 'const_8b10_Xz_0011', 8, "8'b10Xz0011"],
    ['binary', 'const_3b001', 3, "3'b1"],
    ['collision', 'const_3bx01', 3, "3'bx01"],
) {
    my ($name, $token, $width, $expected) = @$case;
    for my $format (qw(fsm isf)) {
        subtest "$name $format literal through public queries and HDL emission" => sub {
            my $path = source($name, $format, $token, $width);
            # The primary literal qualifies every transport. Other spellings
            # and the signal-name collision exercise the same native backend.
            for my $kind ($name eq 'xz' ? qw(check semantic) : ()) {
                my @flags = $kind eq 'check' ? qw(--strict --check --json) : qw(--strict --emit-semantic-json);
                my $before = sha256_hex(read_file($path));
                my $native = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', '--quiet', @flags, $path], '');
                is($native->{exit_code}, 0, "$kind native admission")
                    or diag($native->{stdout}, $native->{stderr});
                my $report = normalize_repository_paths($json->decode($native->{stdout}), $root);
                my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                    name => $kind eq 'check' ? 'fsmgen_check' : 'fsmgen_semantic_introspect',
                    arguments => {source_id => $path}}};
                my $response = $adapter->handle_jsonrpc_request($request);
                ok(!$response->{error}, "$kind API request succeeds");
                my $api = $response->{result};
                my $wire = FSM::Test::SourceQueryRunner::_capture(
                    [$^X, 'bin/fsmgen-mcp', '--workspace-root', $root], $json->encode($request)."\n");
                my $stdio = $json->decode($wire->{stdout});
                ok(!$api->{isError}, "$kind API admission");
                is($json->encode(normalize_repository_paths($api->{structuredContent}{report}, $root)),
                   $json->encode($report), "$kind complete native/API equality");
                is($wire->{exit_code}, 0, "$kind newline process completes");
                ok(!$stdio->{error} && !$stdio->{result}{isError}, "$kind actual newline admission");
                is($json->encode(normalize_repository_paths($stdio->{result}, $root)),
                   $json->encode(normalize_repository_paths($api, $root)), "$kind complete API/newline equality");
                is(sha256_hex(read_file($path)), $before, 'query source bytes preserve');
            }
            my $out = "$work/$name-$format.sv";
            my $emission = FSM::Test::SourceQueryRunner::_capture(
                [$^X, 'bin/fsmgen', '--quiet', '--strict', '--output', $out, $path], '');
            is($emission->{exit_code}, 0, 'SystemVerilog text emission succeeds')
                or diag($emission->{stdout}, $emission->{stderr});
            if (-f $out) {
                like(read_file($out), qr/^\s*result_next\s*=\s*\Q$expected\E\s*;/m,
                    'the actual result assignment preserves the independently expected literal');
            } else {
                fail('expected HDL file exists');
            }
        };
    }
}

subtest 'the operand inventory still distinguishes missing signals from literals' => sub {
    my $validator = FSM::HDL::FlattenedDT::Backend::SystemVerilog::OperandContractValidationSupport->new(
        flattened_dt => {expr_namer => FSM::ExpressionNamer->new});
    my $inventory = {map {$_ => {}} qw(top_level_signals localparam_names parameter_names
        declared_internal_signals explicit_internal_signals assigned_internal_signals)};
    my @violations;
    $validator->_validate_named_expression('test RHS', 'x01', $inventory, \@violations);
    is_deeply(\@violations, ["test RHS references undeclared internal operand 'x01'"],
        'a genuinely missing signal still fails the unchanged validator');
    @violations = ();
    $validator->_validate_named_expression('test RHS', "3'bx01", $inventory, \@violations);
    is_deeply(\@violations, [], 'a rendered symbolic literal contributes no signal operands');
};

done_testing;

sub source {
    my ($name, $format, $token, $width) = @_;
    my $path = "$work/$name.$format";
    my $fsm_collision = $name eq 'collision' ? '(input x01)' : '';
    my $size_collision = $name eq 'collision' ? '(x01 3)' : '';
    my $isf_collision = $name eq 'collision' ? '(input x01 (width 3))' : '';
    my $text = $format eq 'fsm' ? <<"FSM" : <<"ISF";
(?fsm:literal_$name
 (+system (clock clk) (sreset rst_n active_low))
 (+interface (input start) (output result) $fsm_collision)
 (+size (start 1) (result $width) $size_collision)
 (idle (<- (result> $token))))
FSM
(actor literal_$name
 (clock clk) (reset rst_n)
 (interface (input start) (output result (width $width)) (output done) $isf_collision)
 (transaction main (on start) (set result $token) (complete done)))
ISF
    open my $fh, '>:raw', $path or die $!;
    print {$fh} $text or die $!;
    close $fh or die $!;
    $path =~ s/^\Q$root\E\///;
    return $path;
}

sub read_file {
    open my $fh, '<:raw', $_[0] or die $!;
    local $/;
    return <$fh>;
}
