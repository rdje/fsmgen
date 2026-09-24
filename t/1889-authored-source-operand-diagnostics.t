#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP ();
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Pipeline::HDLGenerator;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical->utf8;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $normalize = \&FSM::Test::SourceQueryRunner::normalize_repository_paths;
my $source = <<'ISF';
(actor width_control
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (input VALID (width 8))
    (output A (width 8)) (output B (width 1)) (output done))
  (rule r_a (A VALID))
  (rule r_b (B VALID))
  (transaction tx (on start) (complete done)))
ISF
my $single = write_source('width-control.isf', $source);
my $multi = write_source('domain-width-control.isf', <<'ISF');
(actor domain_width_control
  (clock-domains
    (domain source (clock bus_clk) (reset (bus_rst_n async active_low)) :default)
    (domain core (clock core_clk) (reset (core_rst_n async active_low))))
  (crossings
    (event byte_ready (from source byte_ready_req)
      (to core byte_ready_pulse) (ready byte_ready_ready)))
  (interface
    (input bus_start (domain source))
    (input DATA (width 8) (domain source))
    (output FLAG (domain source))
    (output core_seen (domain core)))
  (transaction bus_capture (domain source) (on bus_start)
    (set FLAG DATA) (await byte_ready_ready) (complete byte_ready_req))
  (transaction core_consume (domain core) (on byte_ready_pulse) (complete core_seen)))
ISF
my %reports;

subtest 'lowered width failures retain authored source in all native modes' => sub {
    for my $path ($single, $multi) {
        for my $retained (0, 1) {
            my $outdir = "$work/retained-" . ($path eq $single ? 'single' : 'multi');
            my @destination = $retained ? ('--outdir', $outdir) : ();
            for my $kind (qw(check semantic human)) {
                my @flags = $kind eq 'check' ? ('--check', '--json')
                    : $kind eq 'semantic' ? ('--emit-semantic-json') : ('--quiet', '--output', "$work/rejected.sv");
                my $result = $capture->([$^X, 'bin/fsmgen', '--strict', @flags, @destination, $path], '');
                is($result->{exit_code}, 1, "$kind rejects declared width mismatch");
                is($result->{signal}, 0, 'ordinary failure, not a terminated process');
                if ($kind eq 'human') {
                    assert_width_message($result->{stderr}, $path);
                    next;
                }
                is($result->{stderr}, '', 'machine failure has no stderr');
                my $report = $json->decode($result->{stdout});
                ok(!$report->{success}, 'report says failure');
                is($report->{source}{resolved_path}, $path, 'report identifies authored source');
                is($report->{diagnostics}[0]{source_file}, $path, 'diagnostic identifies authored source');
                assert_width_message($report->{diagnostics}[0]{message}, $path);
                $reports{$path}{$kind} = $report unless $retained;
                if ($path eq $multi) {
                    is($report->{diagnostics}[0]{parent_composition_source}, $path,
                        'generated domain parent maps to the same authored actor');
                    like($report->{diagnostics}[0]{generated_child_source}, qr/\?fsmc/,
                        'generated domain child identity is retained');
                }
            }
        }
    }
};

subtest 'API and actual newline MCP preserve complete native failures' => sub {
    my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
    for my $path ($single, $multi) {
        my $relative = File::Spec->abs2rel($path, $root);
        for my $kind (qw(check semantic)) {
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $kind eq 'check' ? 'fsmgen_check' : 'fsmgen_semantic_introspect',
                arguments => {source_id => $relative}}};
            my $api = $adapter->handle_jsonrpc_request($request);
            ok($api->{result}{isError}, 'API returns the source failure as a tool result');
            my $expected = $normalize->($reports{$path}{$kind}, $root);
            $expected->{source}{input} = $relative;
            is_deeply($api->{result}{structuredContent}{report}, $expected, 'entire native/API report agrees');
            my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
            is($wire->{exit_code}, 0, 'MCP server handles failed source query normally');
            is($wire->{stderr}, '', 'MCP transport has no stderr');
            is_deeply($json->decode($wire->{stdout}), $api, 'actual newline response equals API response');
        }
    }
};

subtest 'direct sources and library failures keep physical source identity' => sub {
    for my $path (abs_path('t/corpus/direct_rhs_concat_width_mismatch.fsm'),
                  "$work/retained-single/width_control.fsm") {
        ok(-f $path, 'direct source exists, including retained lowering artifact');
        my $pipeline = FSM::Pipeline::HDLGenerator->new(quiet => 1);
        ok(!eval { $pipeline->generate_hdl_from_file($path); 1 }, 'library refuses the width mismatch');
        like($@, qr/Source file: '\Q$path\E'/, 'library reports the file it was actually given');
        unlike($@, qr/OperandContractValidationSupport|validate_pre_generation_operand_contract/, 'library reason excludes implementation names');
        my $result = $capture->([$^X, 'bin/fsmgen', '--check', '--json', $path], '');
        is($result->{exit_code}, 1, 'direct CLI refuses mismatch');
        my $report = $json->decode($result->{stdout});
        is($report->{source}{resolved_path}, $path, 'direct request source is unchanged');
        is($report->{diagnostics}[0]{source_file}, $path, 'direct diagnostic is not guessed from a lowering directory');
        if ($path =~ /direct_rhs_concat/) {
            is($report->{diagnostics}[0]{code}, 'FSMGEN_DIRECT_RHS_WIDTH_MISMATCH', 'existing stable code survives prefix cleanup');
        }
    }
};

subtest 'real external child identity and lookup targets survive projection' => sub {
    my $child = write_source('wrong-kind.fsm', '(?fsm:wrong_kind (idle (OUT = 1)))');
    my $top = write_source('parent.fsm', '(?top:parent (?ports:io OUT>) (?dtc:child wrong-kind))');
    my $result = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $top], '');
    is($result->{exit_code}, 1, 'wrong-kind external child is refused');
    my $d = $json->decode($result->{stdout})->{diagnostics}[0];
    is($d->{source_file}, $child, 'authored child remains the blame source');
    is($d->{parent_composition_source}, $top, 'parent remains separate');
    like($d->{generated_child_source}, qr/\?dtc/, 'child kind is preserved');
    my $missing = write_source('missing-parent.fsm', '(?top:missing_parent (?ports:io OUT>) (?fsmc:child missing_src))');
    $result = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $missing], '');
    is($result->{exit_code}, 1, 'missing external child is refused');
    $d = $json->decode($result->{stdout})->{diagnostics}[0];
    is($d->{source_file}, $missing, 'lookup failure blames the authored parent');
    like($d->{expected_child_source_file}, qr/missing_src\.fsm/, 'expected physical lookup target is preserved');
};

subtest 'shared PPIF handoff preserves source and successful controls still pass' => sub {
    for my $retained (0, 1) {
        local $ENV{FSM_TEST_EXTENSION_FAIL_STAGE} = 'after_parse_source';
        my @destination = $retained ? ('--outdir', "$work/ppif-lowered") : ();
        my $path = abs_path('ppif/axi_aw_valid_ready.ppif');
        my $result = $capture->([$^X, '-It/lib', 'bin/fsmgen', '--strict', '--check', '--json',
            '--extension-module', 'FSM::TestExtension::Exploding', @destination, $path], '');
        is($result->{exit_code}, 1, 'injected public extension failure reaches PPIF handoff');
        my $d = $json->decode($result->{stdout})->{diagnostics}[0];
        is($d->{source_file}, $path, 'PPIF diagnostic retains authored origin');
        like($d->{message}, qr/Source file: '\Q$path\E'/, 'PPIF embedded source has same origin');
        like($d->{message}, qr/Exploding test extension forced failure/, 'extension reason is preserved');
    }
    my $valid = $source;
    $valid =~ s/\(output B \(width 1\)\)/(output B (width 8))/;
    for my $path (write_source('valid.isf', $valid), abs_path('ppif/axi_aw_valid_ready.ppif')) {
        my $result = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
        is($result->{exit_code}, 0, 'valid source still passes');
        my $report = $json->decode($result->{stdout});
        ok($report->{success}, 'valid report says success');
        is($report->{source}{resolved_path}, $path, 'successful source identity is unchanged');
    }
};

done_testing();

sub assert_width_message {
    my ($text, $path) = @_;
    like($text, qr/Source file: '\Q$path\E'/, 'embedded message points to authored source');
    like($text, qr/incompatible width 8 for LHS width 1.*implicit truncation/s, 'widths and actionable reason survive');
    unlike($text, qr/OperandContractValidationSupport|validate_pre_generation_operand_contract|ial1-lowering|\bat .* line \d+/, 'no backend implementation or temporary source leakage');
}
sub write_source {
    my ($name, $text) = @_;
    my $path = "$work/$name";
    open my $fh, '>', $path or die $!;
    print {$fh} $text or die $!;
    close $fh or die $!;
    return $path;
}
