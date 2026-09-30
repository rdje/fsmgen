use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::DomainSource qw(_domain_actor_for_scheduled_artifact);
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $json = JSON::PP->new->canonical;
my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $audit = 'docs/audits/storage-word-access-20260930';
my $baseline = $json->decode(read_file("$audit/baseline.json"));
my $parser = FSM::Adapter::ISF->new;
my $scheduler = FSM::Scheduler::ISF->new;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my @tokens = qw(ro rw wo w1c w0c rc rs warl wpri reserved);

subtest 'word and field facts stay independent for both scalar spellings' => sub {
    for my $kind (qw(var variable)) {
        for my $token (@tokens) {
            my $source = source("($kind value_reg (width 8) (access $token)"
                . ' (fields (field low (bits 1 0) (access wo)) (field high (bits 7 2))))');
            my $actor = $parser->parse_source($source, 'word.isf');
            is($actor->{storage}[0]{access}, $token, "$kind retains word $token");
            my $report = report($actor);
            my $entry = storage($report, 'value_reg');
            is($entry->{access}, $token, 'schedule reports the authored word fact');
            is($entry->{fields}[0]{access}, 'wo', 'field fact does not need to match word');
            ok(!exists $entry->{fields}[1]{access}, 'word fact is not inherited by an unstated field');
            my $without = $source;
            $without =~ s/\(access \Q$token\E\)//;
            my $control = $parser->parse_source($without, 'word.isf');
            my $expected = report($control);
            storage($expected, 'value_reg')->{access} = $token;
            is_deeply($report, $expected, 'access is the only schedule difference');
            is_deeply($scheduler->lower($actor)->{files}, $scheduler->lower($control)->{files},
                'complete scheduled artifacts unchanged');
            $entry->{access} = 'changed';
            is($actor->{storage}[0]{access}, $token, 'report does not mutate source');
        }
    }
    my $actor = $parser->parse_source(source('(var value_reg (width 8) (access ro))'), 'word.isf');
    ok(!exists storage(report($actor), 'value_reg')->{fields}, 'word access does not invent fields');
};

subtest 'malformed access, unsupported carriers and non-tokens fail contextually' => sub {
    for my $case (
        ['(access sometimes)', qr/unknown access token 'sometimes'/],
        ['(access RO)', qr/unknown access token 'RO'/],
        ['(access 0)', qr/unknown access token '0'/],
        ['(access)', qr/access requires/],
        ['(access ())', qr/access requires/],
        ['(access (ro))', qr/access requires/],
        ['(access ro rw)', qr/access requires/],
        ['(access ro) (access ro)', qr/duplicate 'access'/],
    ) {
        for my $kind (qw(var variable)) {
            my $ok = eval { $parser->parse_source(source("($kind value_reg (width 8) $case->[0])"), 'bad.isf'); 1 };
            ok(!$ok, "$kind $case->[0] rejected");
            like($@, qr/storage 'value_reg'/, 'diagnostic names storage');
            like($@, $case->[1], 'diagnostic explains malformed or unknown token');
        }
    }
    for my $entry ('(bank value_reg (width 8) (depth 2) (access ro))',
                   '(var value_reg (type byte_t) (access rw))') {
        my $ok = eval { $parser->parse_source(source($entry), 'bad.isf'); 1 };
        ok(!$ok, 'unsupported carrier rejected');
        like($@, qr/storage .*'value_reg'.*access.*(?:bank|width|typed)/, 'carrier boundary names storage and access');
    }
};

subtest 'supplied controls and new word forms preserve all hardware products' => sub {
    for my $case (qw(baseline-good whole-word-field register-access register-access-with-fields unknown-token)) {
        my $path = "$audit/$case.isf";
        my $failure = $case eq 'unknown-token';
        my $control = exists $baseline->{$case} ? $case : 'baseline-good';
        for my $query (qw(check semantic schedule)) {
            my $actual = public_query($path, $query, $failure);
            next if $failure;
            my $expected = dclone($baseline->{$control}{queries}{$query}{report});
            $expected = relocate($expected, "$audit/$control.isf", $path);
            if ($query eq 'schedule' && $case eq 'register-access') {
                storage($expected, 'status')->{access} = 'ro';
            } elsif ($query eq 'schedule' && $case eq 'register-access-with-fields') {
                storage($expected, 'control')->{access} = 'rw';
            }
            is_deeply($actual, $expected, "$case $query exact previous product plus only authored access");
        }
        for my $flags ([qw(--check --json)], ['--emit-semantic-json']) {
            my $r = capture([$^X, 'bin/fsmgen', @$flags, $path]);
            is($r->{exit_code}, $failure ? 1 : 0, 'default mode keeps the same admission outcome');
            my $report = $json->decode($r->{stdout});
            is(!!$report->{success}, !$failure, 'default report outcome');
            like($json->encode($report->{diagnostics}), qr/storage 'status'.*sometimes/, 'default failure names storage and token') if $failure;
        }
        next if $failure;
        my $actor = $parser->parse_file($path);
        is_deeply($scheduler->lower($actor)->{files}, $baseline->{$control}{scheduled_files},
            'complete actual scheduled carrier equals pre-change control');
        for my $language (qw(systemverilog verilog)) {
            my $output = "$work/$case-$language." . ($language eq 'verilog' ? 'v' : 'sv');
            my $r = capture([$^X, 'bin/fsmgen', '--language', $language, '--output', $output, $path]);
            is($r->{exit_code}, 0, "$case $language emission succeeds");
            is($r->{stderr}, '', 'HDL emission stderr clean');
            is(without_date(read_file($output)), without_date($baseline->{$control}{generated}{$language}{hdl}),
                'complete HDL and reset behavior unchanged except date banner');
        }
    }
};

subtest 'metadata follows domain storage ownership without changing carriers' => sub {
    my $text = <<'ISF';
(actor access_domains
 (clock-domains (domain core (clock clk) (reset rst_n) :default)
                (domain aux (clock aux_clk) (reset aux_rst_n)))
 (interface (input start) (output done) (input aux_start (domain aux)) (output aux_done (domain aux)))
 (storage (var core_reg (width 8) (access ro))
          (variable aux_reg (width 8) (domain aux) (access w1c)))
 (transaction main (on start) (set core_reg 1) (complete done))
 (transaction other (domain aux) (on aux_start) (set aux_reg 2) (complete aux_done)))
ISF
    my $actor = $parser->parse_source($text, 'domains.isf');
    my $ir = $scheduler->{ir}->build_module($actor);
    my %expected = (core => ['core_reg', 'ro'], aux => ['aux_reg', 'w1c']);
    for my $domain (@{$ir->{domain_partition}{domains}}) {
        my $selected = _domain_actor_for_scheduled_artifact($actor, $domain, $ir->{domain_partition}{default_domain});
        my ($name, $access) = @{$expected{$domain->{name}}};
        is_deeply([map { [$_->{name}, $_->{access}] } @{$selected->{storage}}], [[$name, $access]],
            'domain source selects only its independently authored fact');
        is(storage(report($selected), $name)->{access}, $access, 'domain report retains access');
    }
    my $without = $text; $without =~ s/\(access (?:ro|w1c)\)//g;
    my $control = $parser->parse_source($without, 'domains.isf');
    is_deeply($scheduler->lower($actor)->{files}, $scheduler->lower($control)->{files}, 'all domain FSM files unchanged');
    my $path = "$work/domains.isf"; write_file($path, $text); $path =~ s/^\Q$root\E\///;
    my $schedule = public_query($path, 'schedule', 0);
    is_deeply($schedule, report($control), 'existing multi-domain public shape remains unchanged');
    is_deeply($schedule->{inferred_storage}, [], 'top owns no domain storage metadata');
    is_deeply([map { $_->{storage} } @{$schedule->{clock_domains}}],
        [['core_reg'], ['aux_reg']], 'existing domain views publish names only; detail gap owned by SEM .38.3');
};

subtest 'non-token and carrier refusals retain complete public diagnostics' => sub {
    my @cases = (
        ['duplicate', '(var value_reg (width 8) (access ro) (access rw))', qr/storage 'value_reg'.*duplicate 'access'/],
        ['malformed', '(var value_reg (width 8) (access (ro)))', qr/storage 'value_reg'.*access requires/],
        ['bank', '(bank value_reg (width 8) (depth 2) (access ro))', qr/storage 'value_reg'.*access.*bank/],
        ['typed', '(var value_reg (type byte_t) (access ro))', qr/storage 'value_reg'.*access.*typed/],
    );
    for my $case (@cases) {
        my $path = "$work/$case->[0].isf";
        write_file($path, source($case->[1]));
        $path =~ s/^\Q$root\E\///;
        public_query($path, $_, 1, $case->[2]) for qw(check semantic schedule);
        my $default = capture([$^X, 'bin/fsmgen', '--check', '--json', $path]);
        is($default->{exit_code}, 1, 'default check also refuses malformed/carrier form');
        like($default->{stdout}, $case->[2], 'default diagnostic retains contextual cause');
    }
};

subtest 'public discovery and supported fixture expose the report contract' => sub {
    my $manifest = build_capability_manifest();
    is_deeply($manifest->{embedding}{isf_public_interface}{schedule_report_storage_optional_keys},
        [qw(role type type_kind width fields access)], 'exact optional storage keys advertised');
    like($manifest->{embedding}{isf_public_interface}{schedule_report_storage_width_shape},
        qr/word.*access.*independent/s, 'metadata independence is discoverable');
    my $native = capture([$^X, 'bin/fsmgen', '--capability-manifest']);
    is($native->{exit_code}, 0, 'native capabilities succeed');
    is_deeply($json->decode($native->{stdout}), $manifest, 'full native/in-process capabilities agree');
    my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
        name => 'fsmgen_capability_query', arguments => {section => 'embedding'}}};
    my $response = $api->handle_jsonrpc_request($request);
    is_deeply($response->{result}{structuredContent}{payload}, $manifest->{embedding}, 'API embedding contract agrees');
    my $wire = capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
    is($wire->{exit_code}, 0, 'newline capability succeeds');
    is_deeply($json->decode($wire->{stdout}), $response, 'complete newline capability agrees');
    for my $query (qw(check semantic schedule)) {
        my $report = public_query('isf/storage_word_access.isf', $query, 0);
        if ($query eq 'schedule') {
            is(storage($report, 'status')->{access}, 'ro', 'fixture word access survives');
            is(storage($report, 'control')->{access}, 'rw', 'fixture word access with fields survives');
        } else {
            ok($report->{support_accounting}{matched}, 'public fixture is support-accounted');
        }
    }
};

done_testing();

sub source {
    return '(actor access_word (types (type byte_t (bits 8))) (clock clk) (reset rst_n)'
        . ' (interface (input start) (output done)) (storage ' . $_[0] . ')'
        . ' (transaction main (on start) (set value_reg 1) (complete done)))';
}
sub report { $json->decode($scheduler->report($_[0])) }
sub storage { my ($r,$name)=@_; my ($v)=grep {$_->{name} eq $name} @{$r->{inferred_storage}}; return $v }
sub capture { FSM::Test::SourceQueryRunner::_capture($_[0], $_[1] // '') }
sub normalize { FSM::Test::SourceQueryRunner::normalize_repository_paths($_[0], $root) }
sub read_file { open my $fh, '<', $_[0] or die "$_[0]: $!"; local $/; return <$fh> }
sub write_file { open my $fh, '>', $_[0] or die $!; print {$fh} $_[1] or die $!; close $fh or die $! }
sub without_date { my $v=shift; $v =~ s/^\/\/ Date:[^\n]*\n//mg; return $v }
sub relocate {
    my ($v,$old,$new)=@_;
    return {map {$_ => relocate($v->{$_},$old,$new)} keys %$v} if ref($v) eq 'HASH';
    return [map {relocate($_,$old,$new)} @$v] if ref($v) eq 'ARRAY';
    return $v if !defined($v) || ref($v);
    my $text="$v"; $text =~ s/\Q$old\E/$new/g; return $text;
}
sub public_query {
    my ($path,$query,$failure,$diagnostic)=@_;
    $diagnostic //= qr/storage 'status'.*sometimes/;
    my %flags=(check=>[qw(--strict --check --json)],semantic=>[qw(--strict --emit-semantic-json)],schedule=>['--emit-schedule-json']);
    my %tools=(check=>'fsmgen_check',semantic=>'fsmgen_semantic_introspect',schedule=>'fsmgen_schedule_preview');
    my $r=capture([$^X,'bin/fsmgen',@{$flags{$query}},$path]);
    is(!!$r->{exit_code},!!$failure,"$query native outcome");
    my $request={jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{name=>$tools{$query},arguments=>{source_id=>$path}}};
    my $response=$api->handle_jsonrpc_request($request);
    my $wire=capture([$^X,'bin/fsmgen-mcp','--workspace-root','.'],$json->encode($request)."\n");
    is($wire->{exit_code},0,'newline transport succeeds');
    is($wire->{stderr},'','newline stderr clean');
    is_deeply($json->decode($wire->{stdout}),$response,'complete API/newline equality');
    if ($failure && $query eq 'schedule') {
        is($r->{stdout},'','refused schedule has no report');
        like($r->{stderr},$diagnostic,'schedule failure retains contextual cause');
        ok($response->{error},'API retains schedule failure envelope');
        return;
    }
    is($r->{stderr},'','machine report stderr clean');
    my $report=normalize($json->decode($r->{stdout}));
    is_deeply($report,$response->{result}{structuredContent}{report},'complete native/API equality');
    is_deeply($json->decode($response->{result}{content}[0]{text}),$response->{result}{structuredContent},'textual content equals structured content');
    is(!!$response->{result}{isError},!!$failure,'API error flag retains outcome');
    like($json->encode($report->{diagnostics}),$diagnostic,'failure retains contextual cause') if $failure;
    return $report;
}
