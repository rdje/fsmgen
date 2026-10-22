use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical;
my $signed = {kind => 'bits', width => 3, signed => 1, state_model => 'four_state'};
my $flag = {kind => 'bit', width => 1, signed => 0, state_model => 'two_state'};
my $plain = {kind => 'bits', width => 5, signed => 0};
my @cases = (
    {name => 'signed_chain', source => 'packet.count', spec => $signed, op => '^'},
    {name => 'two_state_chain', source => 'packet.ready', spec => $flag, op => '&'},
    {name => 'unspecified_chain', source => 'packet.plain', spec => $plain, op => '|'},
    {name => 'signed_storage', source => 'held.count', spec => $signed, op => '^', direct => 1},
    {name => 'literal_local', source => 'tmp', spec => $plain, op => '|', local => 1},
);
my $header = <<'ISF';
(actor operand_types
 (clock clk) (reset (rst_n sync active_low))
 (types (type frame (record
   (count (four_state (signed (bits 3))))
   (ready (two_state bit)) (plain (bits 5)))))
 (interface (input start) (input packet (type frame)) (output out) (output done))
 (storage (var held (type frame) (reset 0)))
ISF

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
sub semantic_nets {
    my ($report) = @_;
    return {map {$_->{name} => $_}
        @{$report->{semantic}{forward_ir}{structural_rtl_ir}{nets}}};
}
sub native_report {
    my ($path, $flags, $label) = @_;
    my $result = capture([$^X, 'bin/fsmgen', @$flags, $path]);
    my $ok = is($result->{exit_code}, 0, "$label succeeds");
    diag($result->{stdout}, $result->{stderr}) unless $ok;
    return unless $ok;
    is($result->{stderr}, '', "$label clean stderr");
    return normalize_repository_paths($json->decode($result->{stdout}), $root);
}

for my $case (@cases) {
    my $prefix = $case->{local} ? '(local tmp (width 5) (init 3)) ' : '';
    $prefix .= "(sample $case->{source} as q) (sample q as again) " unless $case->{direct};
    my $operand = $case->{direct} ? $case->{source} : 'again';
    my $index = $case->{direct} ? 1 : $case->{local} ? 4 : 3;
    $case->{expected} = [{owner_kind => 'transaction', owner => 'main',
        context => "transaction 'main' clause[$index] set RHS", kind => 'unary',
        operator => $case->{op}, operand => $operand,
        operand_width => $case->{spec}{width}, result_width => 1}];
    for my $variant (qw(baseline reduction)) {
        my $rhs = $variant eq 'baseline' ? "$operand\[0]" : "($case->{op} $operand)";
        $case->{$variant} = write_file("$case->{name}-$variant.isf", $header
            . "(transaction main (on start) $prefix(set out $rhs) (complete done)))\n");
    }
}

for my $case (@cases) {
    subtest "$case->{name} actual source carrier and semantic types" => sub {
        my $baseline = native_report($case->{baseline}, [qw(--strict --check --json)], 'ordinary source');
        return unless $baseline;
        my $actor = FSM::Adapter::ISF->new->parse_file($case->{reduction});
        my $before = $json->encode($actor);
        my $scheduler = FSM::Scheduler::ISF->new;
        my $lowered = $scheduler->lower($actor);
        my $report = $json->decode($scheduler->report($actor));
        is($json->encode($actor), $before, 'lowering and report preserve complete source data and kinds');
        same($report->{reductions}, $case->{expected}, 'source widths and identities match independent declarations');
        my $carrier = $lowered->{files}{'operand_types.fsm'};
        ok(defined($carrier), 'actual emitted module is present');
        return unless defined $carrier;
        my $path = write_file("$case->{name}.fsm", $carrier);
        my $replay = native_report($path, [qw(--strict --check --json)], 'complete carrier strict replay');
        return unless $replay;
        my $semantic = native_report($path, [qw(--strict --emit-semantic-json)], 'actual carrier semantics');
        return unless $semantic;
        my $nets = semantic_nets($semantic);
        if ($case->{direct}) {
            same($nets->{held}{declared_type_spec}{members}{count}, $signed,
                'actual storage net retains the signed four-state member');
        } elsif (!$case->{local}) {
            for my $alias (qw(q again)) {
                my $type_name = $nets->{$alias}{declared_type_name};
                ok(defined($type_name), "$alias has an actual declared private type");
                same($semantic->{semantic}{symbol_contract}{types}{$type_name}, $case->{spec},
                    "$alias canonical type retains exact kind width signedness and state presence");
                same($nets->{$alias}{declared_type_spec}, $case->{spec},
                    "$alias actual semantic net has the independently specified type");
                unlike($carrier, qr/\((?:input|output) \Q$alias\E\)/, "$alias stays private");
            }
        } else {
            for my $alias (qw(tmp q again)) {
                is($nets->{$alias}{width}, 5, "$alias retains the declared local width");
                is($nets->{$alias}{signed}, 0, "$alias remains unsigned");
                ok(!exists($nets->{$alias}{state_model}), "$alias gains no authored state model");
            }
        }
        $case->{carrier} = $carrier;
        $case->{ready} = 1;
        $report->{reductions}[0]{operand_width} = 99;
        $lowered->{files}{'operand_types.fsm'} = 'changed returned carrier';
        is($json->encode($actor), $before, 'returned product mutations preserve complete caller kinds');
        same($json->decode($scheduler->report($actor))->{reductions}, $case->{expected},
            'new source report is detached from mutated returned inventory');
        is($scheduler->lower($actor)->{files}{'operand_types.fsm'}, $carrier,
            'new carrier is detached from mutated returned carrier');
    };
}

subtest 'actual wrong carrier types falsify width-only preservation' => sub {
    my $case = $cases[0];
    plan skip_all => 'actual signed carrier prerequisite failed' unless $case->{ready};
    for my $control (
        ['unsigned', '(four_state (bits 3))'],
        ['two_state', '(two_state (signed (bits 3)))'],
    ) {
        my ($name, $replacement) = @$control;
        my $wrong = $case->{carrier};
        is($wrong =~ s/\(type _isf_sample_again \(four_state \(signed \(bits 3\)\)\)\)/
            "(type _isf_sample_again $replacement)"/e, 1, "$name changes the actual sample type only");
        my $path = write_file("wrong-$name.fsm", $wrong);
        my $report = native_report($path, [qw(--strict --emit-semantic-json)], "$name control carrier");
        next unless $report;
        my $nets = semantic_nets($report);
        is($nets->{again}{width}, 3, "$name keeps the same width and therefore evades a width-only oracle");
        isnt($json->encode($nets->{again}{declared_type_spec}), $json->encode($signed),
            "$name actual semantic type is rejected by the independent full-type witness");
        same($nets->{q}{declared_type_spec}, $signed, "$name leaves the other same-width sample untouched");
    }
};

subtest 'complete native API and newline products retain actual operand types' => sub {
    my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
    for my $case (@cases) {
        next unless $case->{ready};
        for my $mode (
            [check => [qw(--strict --check --json)], 'fsmgen_check'],
            [semantic => [qw(--strict --emit-semantic-json)], 'fsmgen_semantic_introspect'],
            [schedule => ['--emit-schedule-json'], 'fsmgen_schedule_preview'],
        ) {
            my ($kind, $flags, $tool) = @$mode;
            my $label = "$case->{name} $kind";
            my $report = native_report($case->{reduction}, $flags, "$label native");
            next unless $report;
            same($kind eq 'schedule' ? $report->{reductions} : $report->{source}{reductions},
                $case->{expected}, "$label independent authored records");
            if ($kind eq 'semantic' && !$case->{direct} && !$case->{local}) {
                my $nets = semantic_nets($report);
                same($nets->{again}{declared_type_spec}, $case->{spec}, "$label actual source semantic net type");
            }
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $tool, arguments => {source_id => $case->{reduction}}}};
            my $response = $api->handle_jsonrpc_request($request);
            my $ok = ok(!$response->{error} && ref($response->{result}) eq 'HASH'
                && !$response->{result}{isError} && ref($response->{result}{structuredContent}) eq 'HASH',
                "$label API succeeds");
            diag($json->encode($response)) unless $ok;
            next unless $ok;
            same($response->{result}{structuredContent}{report}, $report, "$label complete native/API equality");
            same($json->decode($response->{result}{content}[0]{text}), $response->{result}{structuredContent},
                "$label complete text/structured equality");
            my $wire = capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request) . "\n");
            is($wire->{exit_code}, 0, "$label newline process succeeds");
            is($wire->{stderr}, '', "$label newline clean stderr");
            like($wire->{stdout}, qr/\A[^\n]+\n\z/, "$label one compact newline response");
            same($json->decode($wire->{stdout}), $response, "$label complete API/newline equality");
        }
    }
};

done_testing();
