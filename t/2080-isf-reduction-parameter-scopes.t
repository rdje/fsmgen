use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;
use FSM::Support::ISFReductions qw(capture_actor_reductions);
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical;
my $lowerer = FSM::Scheduler::ISF::LoweringIR->new;
my (%paths, %expected);
my $ready = 1;
sub capture { FSM::Test::SourceQueryRunner::_capture($_[0], $_[1] // '') }
sub same { is($json->encode($_[0]), $json->encode($_[1]), $_[2]); }
sub write_file {
    my ($name, $text) = @_;
    my $path = "$work/$name";
    open my $fh, '>', $path or die $!; print {$fh} $text; close $fh or die $!;
    $path =~ s/\A\Q$root\E\///;
    return $path;
}
sub header {
    '(actor count_scopes (clock clk) (reset (rst_n sync active_low)) '
        . '(interface (input start) (input count (width 8)) (output out) (output done)) ';
}
for my $kind (qw(actorpin formal)) {
    my $formal = $kind eq 'formal' ? "(ports (input count (width 4))) " : '';
    my $init = $kind eq 'formal' ? "(set count 4'd5) " : '';
    for my $variant (qw(baseline reduction)) {
        my $rhs = $variant eq 'baseline' ? 'count[0]' : '(^ count)';
        $paths{$kind}{$variant} = write_file("$kind-$variant.isf", header()
            . "(transaction main $formal(params (count 2)) (on start) $init"
            . "(wait count) (set out $rhs) (complete done)))");
    }
    $expected{$kind} = [{owner_kind=>'transaction', owner=>'main',
        context=>"transaction 'main' clause[".($kind eq 'formal' ? 4 : 3)."] set RHS",
        kind=>'unary', operator=>'^', operand=>'count',
        operand_width=>$kind eq 'formal' ? 4 : 8, result_width=>1}];
}

for my $kind (qw(actorpin formal)) {
    subtest "$kind runtime reduction keeps its declared scope beside a static count" => sub {
        my $baseline = capture([$^X, 'bin/fsmgen', qw(--strict --check --json), $paths{$kind}{baseline}]);
        is($baseline->{exit_code}, 0, 'otherwise identical ordinary-read baseline passes');
        my $actor = eval { FSM::Adapter::ISF->new->parse_file($paths{$kind}{reduction}) };
        my $error = $@;
        my $ok = ok($actor, 'runtime reduction parses independently of same-named count parameter');
        $ready &&= $ok; diag($error) unless $ok; return unless $ok;
        my $before = $json->encode($actor);
        my $scheduler = FSM::Scheduler::ISF->new;
        my $lowered = $scheduler->lower($actor);
        my $report = $json->decode($scheduler->report($actor));
        same($report->{reductions}, $expected{$kind}, 'authored runtime width and source identity');
        is_deeply([map {{kind=>$_->{count_kind}, cycles=>$_->{cycles}, source=>$_->{count_source}}}
            @{$report->{transaction_waits}}], [{kind=>'static', cycles=>2, source=>'count'}],
            'standalone wait retains independent static parameter value');
        my $carrier = write_file("$kind.fsm", $lowered->{files}{'count_scopes.fsm'});
        my $check = capture([$^X, 'bin/fsmgen', qw(--strict --check --json), $carrier]);
        my $replayed = is($check->{exit_code}, 0, 'actual carrier strictly replays');
        $ready &&= $replayed; diag($check->{stdout}, $check->{stderr}) unless $replayed;
        is($json->encode($actor), $before, 'lowering/report preserve complete source values and JSON kinds');
    };
}

subtest 'generated parameters remain static instead of borrowing actor declarations' => sub {
    my $source = '(actor generated_scopes (clock clk) (reset (rst_n sync active_low)) '
        . '(interface (input start) (input COUNT (width 8)) (input data (width 3)) (output out) (output done)) '
        . '(transaction main (on start) (spawn worker as job (bind (input value data) (output result out))) (await_all done)) '
        . '(transaction worker (ports (input value (width 3)) (output result)) (params (COUNT 2)) '
        . '(wait COUNT) (set result (^ value))))';
    my $path = write_file('generated.isf', $source);
    my $actor = FSM::Adapter::ISF->new->parse_file($path);
    my $scheduler = FSM::Scheduler::ISF->new;
    my $lowered = $scheduler->lower($actor);
    my $records = capture_actor_reductions(actor=>$actor, transaction=>'worker');
    is_deeply($records, [{owner_kind=>'transaction', owner=>'worker',
        context=>"transaction 'worker' clause[2] set RHS", kind=>'unary', operator=>'^',
        operand=>'value', operand_width=>3, result_width=>1}], 'selected child retains actual declared port scope');
    for my $name (sort keys %{$lowered->{files}}) {
        my $carrier = write_file($name, $lowered->{files}{$name});
        my $check = capture([$^X, 'bin/fsmgen', qw(--strict --check --json), $carrier]);
        is($check->{exit_code}, 0, "$name actual generated carrier replays") or diag($check->{stdout}, $check->{stderr});
    }
    $source =~ s/\(\^ value\)/(^ COUNT)/;
    my $bad = write_file('generated-static.isf', $source);
    my $check = capture([$^X, 'bin/fsmgen', qw(--strict --check --json), $bad]);
    isnt($check->{exit_code}, 0, 'generated expression parameter refuses despite actor wire width');
    my $report = $json->decode($check->{stdout});
    is_deeply([map {$_->{message}} @{$report->{diagnostics}}],
        ["Invalid ISF reductions: transaction 'worker' clause[2] set RHS reduction '^' operand 'COUNT' is not a declared packed scalar signal"],
        'complete generated-static refusal identifies the original operand');
    ok(!exists $report->{source}{reductions}, 'failure carries no invented inventory');
};

subtest 'canonical live placement and detached static namespaces agree' => sub {
    for my $case (
        [local_do=>'(do worker)', '', 0],
        [spawn=>'(spawn worker as job)', '', 1],
        [generated_do=>'(do worker (params (count 2)))', '', 1],
        [nested_do=>'(when start (do worker (params (count 2))))', '', 1],
        [dead_spawn=>'(repeat 0 (spawn worker as job))', '', 0],
        [dead_constant=>'(repeat ZERO (spawn worker as job))', '', 0],
        [rule=>'', '(rule launch start (trigger worker (params (count 2))))', 1],
    ) {
        my ($name, $action, $rule, $generated) = @$case;
        my $source = header() . '(constants (C 1) (ZERO 0)) (params (A 2)) (enums (mode (BUSY 1))) '
            . "(transaction main (on start) $action (complete done)) "
            . '(transaction worker (params (count 2)) (on start) (wait count) (set out count[0])) '
            . "$rule)";
        my $actor = FSM::Adapter::ISF->new->parse_source($source, "$name.isf");
        my $before = $json->encode($actor);
        my $scope = $lowerer->expression_static_scopes($actor);
        my $actor_static = {C=>1, ZERO=>1, A=>1, 'mode.BUSY'=>1};
        is_deeply($scope, {actor=>$actor_static, transactions=>{main=>$actor_static,
            worker=>{%$actor_static, $generated ? (count=>1) : ()}}},
            "$name uses live canonical placement without conflating count symbols");
        is($json->encode($actor), $before, "$name query preserves complete caller data and kinds");
        $scope->{transactions}{worker}{C} = 0;
        is($scope->{actor}{C}, 1, "$name returned actor namespace is independent");
        is($scope->{transactions}{main}{C}, 1, "$name sibling namespaces are independent");
    }
    my $actor = FSM::Adapter::ISF->new->parse_file($paths{actorpin}{baseline});
    for my $selection (undef, '', 'missing', []) {
        my $ok = eval {capture_actor_reductions(actor=>$actor, transaction=>$selection); 1};
        ok(!$ok, 'malformed or absent selected transaction refuses');
        like($@, qr/actor capture requires a declared selected transaction/, 'selection refusal is contextual');
    }
};

subtest 'actor statics and unknown operands retain their complete refusal' => sub {
    for my $case ([parameter=>'(params (count 2)) ', 'count'],
        [constant=>'(constants (count 2)) ', 'count'], [unknown=>'', 'missing']) {
        my ($name, $declarations, $operand) = @$case;
        my $source = header().$declarations
            . "(transaction main (on start) (set out (^ $operand)) (complete done)))";
        my $path = write_file("bad-$name.isf", $source);
        my $check = capture([$^X, 'bin/fsmgen', qw(--strict --check --json), $path]);
        isnt($check->{exit_code}, 0, "$name cannot borrow runtime width");
        my $report = $json->decode($check->{stdout});
        is_deeply([map {$_->{message}} @{$report->{diagnostics}}],
            ["Invalid ISF reductions: transaction 'main' clause[1] set RHS reduction '^' operand '$operand' is not a declared packed scalar signal"],
            "$name retains its complete intended cause");
        ok(!exists $report->{source}{reductions}, "$name invents no successful inventory");
    }
    my $with_enum = header().'(enums (mode (BUSY 1))) '
        . '(transaction main (params (count 2)) (on start) (wait count) (set out (^ count)) (complete done)))';
    my $actor = FSM::Adapter::ISF->new->parse_source($with_enum, 'enum-control.isf');
    same($actor->{reduction_metadata}, $expected{actorpin},
        'unrelated qualified static identities do not become invalid declaration roots');
};

subtest 'actual domain recapture keeps each runtime formal and static wait distinct' => sub {
    my $source = <<'ISF';
(actor domain_count_scopes
 (clock-domains (domain core (clock clk) (reset rst_n) :default)
  (domain aux (clock aux_clk) (reset aux_rst_n)))
 (interface (input start) (output out) (output done)
  (input aux_start (domain aux)) (output aux_out (domain aux)) (output aux_done (domain aux)))
 (transaction main (ports (input count (width 4))) (params (count 2))
  (on start) (set count 4'd5) (wait count) (set out (^ count)) (complete done))
 (transaction aux_main (domain aux) (ports (input count (width 3))) (params (count 3))
  (on aux_start) (set count 3'd5) (wait count) (set aux_out (& count)) (complete aux_done)))
ISF
    my $actor = FSM::Adapter::ISF->new->parse_source($source, 'domain-count-scopes.isf');
    my $before = $json->encode($actor);
    my $scheduler = FSM::Scheduler::ISF->new;
    my $lowered = $scheduler->lower($actor);
    my (%domain_reports, $report);
    my $report_hash = \&FSM::Scheduler::ISF::Emitter::JSON::report_hash;
    {
        no warnings 'redefine';
        local *FSM::Scheduler::ISF::Emitter::JSON::report_hash = sub {
            my $value = $report_hash->(@_);
            $domain_reports{$_[1]->{actor_name}} = dclone($value);
            return $value;
        };
        $report = $json->decode($scheduler->report($actor));
    }
    is(scalar @{$report->{clock_domains}}, 2, 'both actual domain realizations are reported');
    for my $domain (@{$report->{clock_domains}}) {
        (my $module = $domain->{scheduled_fsm}) =~ s/\.fsm\z//;
        my $local = $domain_reports{$module};
        ok($local, "$domain->{name} actual report producer is observed");
        my $core = $domain->{name} eq 'core';
        my $name = $core ? 'main' : 'aux_main';
        is_deeply($local->{reductions}, [{owner_kind=>'transaction', owner=>$name,
            context=>"transaction '$name' clause[4] set RHS", kind=>'unary',
            operator=>$core ? '^' : '&', operand=>'count', operand_width=>$core ? 4 : 3, result_width=>1}],
            "$domain->{name} authored source reduction keeps nearest formal width");
        is_deeply([map {$_->{cycles}} @{$local->{transaction_waits}}], [$core ? 2 : 3],
            "$domain->{name} standalone count remains static");
    }
    for my $name (sort keys %{$lowered->{files}}) {
        my $carrier = write_file($name, $lowered->{files}{$name});
        my $check = capture([$^X, 'bin/fsmgen', qw(--strict --check --json), $carrier]);
        is($check->{exit_code}, 0, "$name actual domain carrier replays") or diag($check->{stdout}, $check->{stderr});
    }
    is($json->encode($actor), $before, 'domain lowering/report preserve all original source kinds');
};

subtest 'complete native API and actual newline products preserve direct runtime/count separation' => sub {
    plan skip_all=>'source/carrier prerequisite is red' unless $ready;
    my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root=>$root, workspace_root=>$root);
    for my $kind (qw(actorpin formal)) {
        for my $mode ([check=>[qw(--strict --check --json)], 'fsmgen_check'],
            [semantic=>[qw(--strict --emit-semantic-json)], 'fsmgen_semantic_introspect'],
            [schedule=>['--emit-schedule-json'], 'fsmgen_schedule_preview']) {
            my ($name, $flags, $tool) = @$mode;
            my $native = capture([$^X, 'bin/fsmgen', @$flags, $paths{$kind}{reduction}]);
            my $ok = is($native->{exit_code}, 0, "$kind $name native success");
            diag($native->{stdout}, $native->{stderr}) unless $ok; next unless $ok;
            is($native->{stderr}, '', "$kind $name native stderr clean");
            my $report = normalize_repository_paths($json->decode($native->{stdout}), $root);
            same($name eq 'schedule' ? $report->{reductions} : $report->{source}{reductions},
                $expected{$kind}, "$kind $name independent source records");
            my $request = {jsonrpc=>'2.0', id=>1, method=>'tools/call', params=>{name=>$tool,
                arguments=>{source_id=>$paths{$kind}{reduction}}}};
            my $response = $api->handle_jsonrpc_request($request);
            my $success = ok(!$response->{error} && ref($response->{result}) eq 'HASH'
                && !$response->{result}{isError} && ref($response->{result}{structuredContent}) eq 'HASH'
                && ref($response->{result}{structuredContent}{report}) eq 'HASH', "$kind $name API success");
            diag($json->encode($response)) unless $success; next unless $success;
            same($response->{result}{structuredContent}{report}, $report, "$kind $name complete native/API equality");
            same($json->decode($response->{result}{content}[0]{text}), $response->{result}{structuredContent},
                "$kind $name text/structured equality");
            my $wire = capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
            is($wire->{exit_code}, 0, "$kind $name newline success");
            is($wire->{stderr}, '', "$kind $name newline stderr clean");
            like($wire->{stdout}, qr/\A[^\n]+\n\z/, "$kind $name one compact newline response");
            same($json->decode($wire->{stdout}), $response, "$kind $name complete API/newline equality");
        }
    }
};

done_testing;
