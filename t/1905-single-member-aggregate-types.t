#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use File::Spec;
use JSON::PP ();
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Pipeline::HDLGenerator;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $bit = {kind => 'bit', width => 1, signed => 0};
my $byte = {kind => 'bits', width => 8, signed => 0};
my $record = {kind => 'record', width => 8, signed => 0,
    member_order => ['payload'], members => {payload => $byte}};
my $list = {kind => 'list', width => 8, signed => 0, items => [$byte]};
my @cases = (
    ['record_inline', '(type root_t (record (payload (bits 8))))', $record],
    ['record_forward', '(type root_t (record (payload byte_t))) (type byte_t (bits 8))', $record],
    ['list_inline', '(type root_t (list (bits 8)))', $list],
    ['list_forward', '(type root_t (list byte_t)) (type byte_t (bits 8))', $list],
    ['nested', '(type root_t (list (record (payload byte_t)))) (type byte_t (bits 8))',
        {kind => 'list', width => 8, signed => 0, items => [$record]}],
    ['nested_alias', '(type root_t (record (payload inner_t))) (type inner_t (list byte_t)) (type byte_t (bits 8))',
        {kind => 'record', width => 8, signed => 0, member_order => ['payload'], members => {payload => $list}}],
    ['list_scalar', '(type root_t (list bit))',
        {kind => 'list', width => 1, signed => 0, items => [$bit]}],
    ['record_scalar', '(type root_t (record (flag bit)))',
        {kind => 'record', width => 1, signed => 0, member_order => ['flag'], members => {flag => $bit}}],
    ['signed_leaf', '(type root_t (list (signed (bits 8))))',
        {kind => 'list', width => 8, signed => 0, items => [{%$byte, signed => 1}]}],
    ['multi_record', '(type root_t (record (payload (bits 8)) (flag bit)))',
        {kind => 'record', width => 9, signed => 0, member_order => [qw(payload flag)], members => {payload => $byte, flag => $bit}}],
    ['constructor_alias', '(type root_t (list bits byte_t)) (type bits bit) (type byte_t (bits 8))',
        {kind => 'list', width => 9, signed => 0, items => [$bit, $byte]}],
);
for my $case (@cases) {
    my ($name, $definitions, $expected) = @$case;
    subtest $name => sub {
        my $dir = "$work/$name";
        mkdir $dir or die $!;
        my $width = $expected->{width};
        my $source = actor_source($name, $definitions, $width);
        my $isf = write_file("$dir/source.isf", $source);
        my $actor = eval { FSM::Adapter::ISF->new->parse_file($isf) };
        ok($actor, 'normalized ISF type resolves') or do { diag($@); return };
        is_deeply($actor->{storage}[0]{type_spec}, $expected, 'exact authored aggregate shape and packed width');
        my $direct = write_file("$dir/direct.fsm", <<"FSM");
(?fsm:direct_$name
 (+system (clock clk) (sreset rst))
 (+types $definitions)
 (+size (IN root_t) (OUT root_t))
 (idle (OUT = IN)))
FSM
        my $pipeline = FSM::Pipeline::HDLGenerator->new(quiet => 1, target_language => 'systemverilog');
        my $direct_result = $pipeline->generate_hdl_from_file($direct);
        is_deeply($direct_result->{intent_hir}{symbol_contract}{types}{root_t}, $expected,
            'raw direct-root parsing preserves the same exact type');
        like($direct_result->{hdl_code}, qr/typedef struct packed/, 'direct aggregate remains a packed HDL type');
        my $lowered = FSM::Scheduler::ISF->new->lower($actor);
        my $replay = write_file("$dir/$name.fsm", $lowered->{files}{"$name.fsm"});
        my $replayed = $pipeline->generate_hdl_from_file($replay);
        is_deeply($replayed->{intent_hir}{symbol_contract}{types}{root_t}, $expected,
            'scheduled raw replay retains normalized source type identity');
        my $native = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $isf], '');
        is($native->{exit_code}, 0, 'native strict check accepts complete actor') or diag($native->{stdout}, $native->{stderr});
        unlike($native->{stderr}, qr/uninitialized|warning/i, 'no layout warnings');
    };
}

subtest 'imported raw package types coexist with flat local ISF aliases' => sub {
    my $dir = "$work/imported";
    mkdir $dir or die $!;
    write_file("$dir/shared.fsm", '(?pkg:shared (+types (type frame_t (record (payload byte_t))) (type byte_t (bits 8))))');
    my $source = actor_source('imported', '(type root_t (list (record (payload (bits 8)))))', 8);
    # Keep the imported type on the storage declaration; local definitions still
    # exercise the other layout in the same parse and emitted compilation unit.
    $source =~ s/\(clock clk\)/(imports (package shared)) (clock clk)/;
    $source =~ s/\(var value \(type root_t\)/\(var value (type shared.frame_t)/;
    my $path = write_file("$dir/source.isf", $source);
    my $actor = FSM::Adapter::ISF->new->parse_file($path);
    is_deeply($actor->{storage}[0]{type_spec}, $record, 'imported forward single-member record shape');
    my $result = FSM::Pipeline::HDLGenerator->new(quiet => 1)->generate_hdl_from_file($path);
    like($result->{hdl_code}, qr/logic \[7:0\] payload;/, 'imported member reaches generated HDL');
};

for my $case (
    ['missing_member_type', '(type root_t (record (payload)))', qr/malformed '\+types'/],
    ['duplicate_member', '(type root_t (record (payload bit) (payload bit)))', qr/malformed '\+types'/],
    ['empty_record', '(type root_t (record))', qr/malformed '\+types'/],
    ['empty_list', '(type root_t (list))', qr/malformed '\+types'/],
    ['invalid_width', '(type root_t (list (bits 0)))', qr/malformed '\+types'/],
    ['unknown_alias', '(type root_t (record (payload missing_t)))', qr/malformed '\+types'/],
    ['aggregate_overlay', '(type root_t (signed (list bit)))', qr/malformed '\+types'/],
    ['record_cycle', '(type root_t (record (payload other_t))) (type other_t root_t)', qr/Cycle: type 'root_t' -> type 'other_t' -> type 'root_t'/],
    ['list_cycle', '(type root_t (list (record (payload other_t)))) (type other_t root_t)', qr/Cycle: type 'root_t' -> type 'other_t' -> type 'root_t'/],
) {
    my ($name, $definitions, $diagnostic) = @$case;
    subtest "reject $name" => sub {
        my $source = actor_source($name, $definitions, 8);
        my $ok = eval { FSM::Adapter::ISF->new->parse_source($source, "$name.isf"); 1 };
        ok(!$ok, 'malformed or cyclic normalized aggregate is rejected');
        like($@, $diagnostic, 'specific type or dependency-cycle diagnostic');
    };
}

subtest 'native and MCP queries preserve repaired nested types and failures' => sub {
    my $root = abs_path('.');
    my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
    for my $case (
        ['positive', '(type root_t (list (record (payload byte_t)))) (type byte_t (bits 8))', 0],
        ['negative', '(type root_t (record (payload root_t)))', 1],
        ['unknown', '(type root_t (record (payload missing_t)))', 1],
    ) {
        my ($name, $definitions, $fails) = @$case;
        my $path = write_file("$work/api_$name.isf", actor_source("api_$name", $definitions, 8));
        my $relative = File::Spec->abs2rel($path, $root);
        for my $query (['check', [qw(--strict --check --json)], 'fsmgen_check'],
                       ['semantic', [qw(--strict --emit-semantic-json)], 'fsmgen_semantic_introspect']) {
            my ($kind, $flags, $tool) = @$query;
            my $native = $capture->([$^X, 'bin/fsmgen', @$flags, $relative], '');
            is(!!$native->{exit_code}, !!$fails, "$name native $kind status");
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $tool, arguments => {source_id => $relative}}};
            my $response = $api->handle_jsonrpc_request($request);
            my $report = FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}), $root);
            unlike($json->encode($report), qr/ARRAY\(0x|HASH\(0x|called at .* line \d+/, 'expected type failures expose no private stack frames');
            is_deeply($response->{result}{structuredContent}{report}, $report, "$name complete native/API $kind parity");
            my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
            is($wire->{exit_code}, 0, 'newline transport completed');
            is_deeply($json->decode($wire->{stdout}), $response, "$name complete newline/API $kind parity");
        }
    }
};
done_testing();

sub actor_source {
    my ($name, $definitions, $width) = @_;
    return <<"ISF";
(actor $name
 (types $definitions)
 (clock clk) (reset rst)
 (interface (input start) (input data (width $width)) (output result (width $width)))
 (storage (var value (type root_t) (reset 0)))
 (transaction main (on start) (set value data) (set result value)))
ISF
}
sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content;
    close $fh or die "close $path: $!";
    return $path;
}
