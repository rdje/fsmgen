#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);

sub source {
    my ($declaration) = @_;
    return "(actor local_admission (clock clk) (reset (rst_n async active_low))\n"
        . "(interface (input start) (output done) (output result (width 4)))\n"
        . "(transaction main (on start) $declaration (set result scratch) (complete done)))\n";
}
sub lower {
    my ($text) = @_;
    my $actor = FSM::Adapter::ISF->new->parse_source($text, 'local_admission.isf');
    return FSM::Scheduler::ISF->new->lower($actor);
}

my @malformed = (
    ['unknown', '(local scratch (width 4) (defualt 3))', qr/unsupported local option 'defualt'/],
    ['bare', '(local scratch (width 4) reset)', qr/local options require/],
    ['empty', '(local scratch (width 4) ())', qr/local options require/],
    ['missing_value', '(local scratch (width 4) (reset))', qr/local options require/],
    ['trailing_value', '(local scratch (width 4 5))', qr/local options require/],
    ['nested_head', '(local scratch (width 4) ((reset) 1))', qr/local options require/],
    ['duplicate_width', '(local scratch (width 4) (width 3))', qr/duplicate local 'width' option/],
    ['duplicate_default', '(local scratch (width 4) (default 1) (default 2))', qr/duplicate local initialization option/],
    ['duplicate_init', '(local scratch (width 4) (init 1) (init 2))', qr/duplicate local initialization option/],
    ['mixed_init', '(local scratch (width 4) (default 1) (init 2))', qr/duplicate local initialization option/],
    ['reverse_init', '(local scratch (width 4) (init 1) (default 2))', qr/duplicate local initialization option/],
    ['duplicate_reset', '(local scratch (width 4) (reset 1) (reset 2))', qr/duplicate local 'reset' option/],
    ['missing_width', '(local scratch)', qr/requires a '\(width N\)' with a positive integer/],
    ['zero_width', '(local scratch (width 0))', qr/requires a '\(width N\)' with a positive integer/],
    ['wide_default', '(local scratch (width 4) (default 16))', qr/default value does not fit/],
    ['wide_reset', '(local scratch (width 4) (reset 16))', qr/reset value does not fit/],
    ['negative_init', '(local scratch (width 4) (init -1))', qr/requires a non-negative integer literal/],
    ['expression_reset', '(local scratch (width 4) (reset (+ 1 2)))', qr/requires a non-negative integer literal/],
    ['bad_name', '(local scratch-bad (width 4))', qr/local.*(?:scalar HDL identifier|invalid)/],
    ['missing_name', '(local)', qr/local.*requires a name/],
);
for my $case (@malformed) {
    my ($label, $decl, $pattern) = @$case;
    subtest $label => sub {
        my $ok = eval {lower(source($decl)); 1};
        ok(!$ok, 'malformed declaration rejected');
        like($@, $pattern, 'source-specific diagnostic');
    };
}

subtest 'valid option ordering, synonyms and independent reset remain unchanged' => sub {
    for my $initializer ('default', 'init') {
        my $text = source("(local scratch (reset 9) ($initializer 3) (width 4))");
        my $actor = FSM::Adapter::ISF->new->parse_source($text, 'local_admission.isf');
        my $before = dclone($actor);
        my $lowered = FSM::Scheduler::ISF->new->lower($actor);
        is_deeply($actor, $before, "$initializer lowering does not mutate source");
        my $fsm = $lowered->{files}{'local_admission.fsm'};
        like($fsm, qr/\(scratch 4 \(reset 9\)\)/, 'hardware reset retained');
        like($fsm, qr/\(scratch 3\)/, 'separate entry initialization retained');
        my $path = write_file("$work/$initializer.fsm", $fsm);
        my $checked = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
        is($checked->{exit_code}, 0, 'valid carrier strict replay') or diag($checked->{stdout}, $checked->{stderr});
    }
};

subtest 'existing local collisions and pruning remain source-owned' => sub {
    for my $case (
        ['(local result (width 4))', qr/collides with interface port 'result'/],
        ['(local scratch (width 4)) (local scratch (width 4))', qr/collides with an already-declared signal 'scratch'/],
        ['(ports (input scratch (width 4))) (local scratch (width 4))', qr/collides with an already-declared signal 'scratch'/],
        ['(repeat 0 (local scratch (width 4)))', qr/unsupported '\(local .*repeat body/],
    ) {
        my $ok = eval {lower(source($case->[0])); 1};
        ok(!$ok, 'invalid scope rejected');
        like($@, $case->[1], 'existing source diagnostic retained');
    }
    my $text = '(actor pruned_local (interface (input start) (output done)) '
        . '(transaction main (on start) (repeat COUNT (do worker)) (complete done)) '
        . '(transaction worker (local scratch (width 4) (defualt 3)) (set scratch 1)))';
    (my $zero = $text) =~ s/COUNT/0/;
    my $pruned = eval {lower($zero)};
    ok($pruned, 'unreachable zero-only target keeps existing admission') or diag($@);
    unlike($pruned->{files}{'pruned_local.fsm'} // '', qr/worker_idle/, 'pruned target emits no controller');
    (my $live = $text) =~ s/COUNT/1/;
    my $ok = eval {lower($live); 1};
    ok(!$ok, 'live target validates local options');
    like($@, qr/unsupported local option 'defualt'/, 'live target cannot hide malformed declaration');
};

for my $case (['bad', '(local scratch (width 4) (defualt 3))', 0],
              ['good', '(local scratch (width 4) (init 3) (reset 9))', 1]) {
    my ($name, $decl, $success) = @$case;
    subtest "$name complete public reports" => sub {
        my $file = write_file("$work/$name.isf", source($decl));
        my $relative = File::Spec->abs2rel($file, $root);
        for my $query (
            [[qw(--strict --check --json)], 'fsmgen_check'],
            [[qw(--strict --emit-semantic-json)], 'fsmgen_semantic_introspect'],
            [['--emit-schedule-json'], 'fsmgen_schedule_preview'],
        ) {
            my ($flags, $tool) = @$query;
            my $native = $capture->([$^X, 'bin/fsmgen', @$flags, $relative], '');
            if (!$success && $tool eq 'fsmgen_schedule_preview') {
                isnt($native->{exit_code}, 0, 'native schedule rejects malformed declaration');
            } else {
                is($native->{exit_code}, $success ? 0 : 1, "$tool source admission status");
            }
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $tool, arguments => {source_id => $relative}}};
            my $response = $api->handle_jsonrpc_request($request);
            if (!$success && $tool eq 'fsmgen_schedule_preview') {
                is($native->{stdout}, '', 'schedule failure does not publish a partial report');
                like($native->{stderr}, qr/unsupported local option 'defualt'/, 'native schedule diagnostic');
                is($response->{error}{code}, -32000, 'schedule API retains failure code');
                like($response->{error}{message}, qr/failed without a matching public failure report/, 'API preserves message-only schedule boundary');
                ok(!exists $response->{error}{data}, 'schedule error has no raw payload');
            } else {
                my $report = FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}), $root);
                like($report->{diagnostics}[0]{message}, qr/unsupported local option 'defualt'/, 'native malformed-option diagnostic') unless $success;
                is_deeply($response->{result}{structuredContent}{report}, $report, "$tool complete native/API parity");
            }
            my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
            is($wire->{exit_code}, 0, "$tool newline protocol success");
            is_deeply($json->decode($wire->{stdout}), $response, "$tool complete newline/API parity");
        }
    };
}
done_testing;

sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $text or die "write $path: $!";
    close $fh or die "close $path: $!";
    return $path;
}
