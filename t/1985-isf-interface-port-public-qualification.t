use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryCoverage qw(build_source_query_cohort);
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical->utf8;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my %flags = (check => [qw(--strict --check --json)], semantic => [qw(--strict --emit-semantic-json)],
             schedule => ['--emit-schedule-json']);
my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
my %supported = (
    'isf/interface_port_metadata.isf' => [
        p('start','input',1), {name=>'data',direction=>'input',width=>8,type=>'byte',type_kind=>'bits'},
        p('spare','output',2), p('done','output',1),
    ],
    'isf/apb_requester.isf' => [
        p('start','input',1), p('req_write','input',1), p('req_addr','input',32), p('req_wdata','input',32),
        p('PREADY','input',1), p('PRDATA','input',32), p('PSLVERR','input',1),
        p('done','output',1), p('last_read_data','output',32), p('last_error','output',1),
        p('PADDR','output',32), p('PWRITE','output',1), p('PWDATA','output',32), p('PSEL','output',1), p('PENABLE','output',1),
    ],
    'isf/verification_observation_metadata.isf' => [
        p('valid','input',1), p('data','input',8), p('ready','output',1), p('done','output',1),
    ],
    'isf/storage_fields.isf' => [
        p('start','input',1), p('wdata','input',8), p('done','output',1), p('control_out','output',8),
    ],
    'isf/storage_word_access.isf' => [
        p('start','input',1), p('wdata','input',8), p('done','output',1), p('status_out','output',8), p('control_out','output',8),
    ],
);

subtest 'every current supported ISF cohort row has independent declaration witnesses on all transports' => sub {
    my @rows = grep { $_->{file_kind} eq 'isf' } @{build_source_query_cohort()};
    is_deeply([sort map { $_->{source_id} } @rows], [sort keys %supported],
        'live catalog selection matches the independently reviewed sources; additions require witnesses');
    ok(grep($_->{id} eq 'feature.isf_declared_interface_metadata', map {@{$_->{catalog_entries}}} @rows),
        'declared-interface feature is owned by the supported source-query catalog');
    for my $row (@rows) {
        is_deeply($row->{query_kinds}, [qw(check semantic schedule)], 'complete current ISF query applicability');
        for my $kind (@{$row->{query_kinds}}) {
            my $report = query($row->{source_id}, $kind, 0);
            declarations($report, $kind, $supported{$row->{source_id}}, "$kind $row->{source_id}");
        }
    }
};

subtest 'local imported empty and domain declarations preserve complete transport products' => sub {
    write_file("$work/shared.fsm", '(?pkg:shared (+types (type byte (bits 8))))');
    my @cases = (
        ['local', '(actor local_ports (types (type nibble (bits 4))) (params (BUS_WIDTH 9))'
            . ' (interface (output spare (type nibble)) (input start) (input unused (width BUS_WIDTH)) (output done))'
            . ' (transaction main (on start) (complete done)))',
            [p('start','input',1), p('unused','input',9),
             {name=>'spare',direction=>'output',width=>4,type=>'nibble',type_kind=>'bits'}, p('done','output',1)]],
        ['imported', '(actor imported_ports (imports (package shared))'
            . ' (interface (input start) (input data (type shared.byte)) (output spare (type shared.byte)) (output done))'
            . ' (transaction main (on start) (complete done)))',
            [p('start','input',1), {name=>'data',direction=>'input',width=>8,type=>'shared.byte',type_kind=>'bits'},
             {name=>'spare',direction=>'output',width=>8,type=>'shared.byte',type_kind=>'bits'}, p('done','output',1)]],
        ['empty', '(actor empty_ports)', []],
        ['domains', '(actor domain_ports (clock-domains (domain core (clock clk) (reset rst_n) :default)'
            . ' (domain spare (clock spare_clk) (reset spare_rst_n)) (domain aux (clock aux_clk) (reset aux_rst_n)))'
            . ' (interface (output spare_output (width 3)) (input start) (output done)'
            . ' (input aux_input (width 2) (domain aux)) (output aux_output (width 2) (domain aux)))'
            . ' (transaction main (on start) (complete done)))',
            [{name=>'start',direction=>'input',width=>1,domain=>'core'},
             {name=>'aux_input',direction=>'input',width=>2,domain=>'aux'},
             {name=>'spare_output',direction=>'output',width=>3,domain=>'core'},
             {name=>'done',direction=>'output',width=>1,domain=>'core'},
             {name=>'aux_output',direction=>'output',width=>2,domain=>'aux'}]],
    );
    for my $case (@cases) {
        my $path = "$work/$case->[0].isf"; write_file($path, $case->[1]); $path =~ s/^\Q$root\E\///;
        for my $kind (qw(check semantic schedule)) {
            my $report = query($path, $kind, 0);
            declarations($report, $kind, $case->[2], "$case->[0] $kind");
            if ($kind eq 'schedule' && $case->[0] eq 'domains') {
                is_deeply([map {$_->{name}} @{$report->{clock_domains}}], [qw(core spare aux)], 'authored domain order');
                for my $domain (@{$report->{clock_domains}}) {
                    is_deeply($domain->{interface_ports}, [grep {$_->{domain} eq $domain->{name}} @{$case->[2]}],
                        'domain reports exact declarations, including a known empty owner');
                }
            }
        }
    }
};

subtest 'record list malformed and unrelated sources retain their public boundaries' => sub {
    for my $case (
        ['record', '(actor refused (types (type frame (record (flag bit)))) (interface (input packet (type frame))))',
            qr/interface port 'packet' references aggregate type 'frame'/],
        ['list', '(actor refused (types (type array_t (list bit bit))) (interface (input packet (type array_t))))',
            qr/interface port 'packet' references aggregate type 'array_t'/],
        ['width', '(actor refused (interface (input packet (width UNKNOWN))))', qr/interface port 'packet' width token 'UNKNOWN'/],
    ) {
        my $path = "$work/$case->[0].isf"; write_file($path, $case->[1]); $path =~ s/^\Q$root\E\///;
        for my $kind (qw(check semantic)) {
            my $report = query($path, $kind, 1);
            ok(!exists($report->{source}{interface_ports}), 'failure cannot publish successful declarations');
            like($json->encode($report->{diagnostics}), $case->[2], 'failure names exact port/type/width boundary');
        }
        my $native = capture([$^X, 'bin/fsmgen', '--emit-schedule-json', $path]);
        isnt($native->{exit_code}, 0, 'native scheduling refuses source');
        is($native->{stdout}, '', 'no partial successful schedule');
        like($native->{stderr}, $case->[2], 'schedule retains contextual refusal');
        my $request = request($path, 'schedule');
        my $response = $api->handle_jsonrpc_request($request);
        ok($response->{error}, 'schedule keeps its existing transport error contract');
        wire_equal($request, $response);
    }
    for my $path ('t/corpus/direct_size_expression_widths.fsm', 'ppif/valid_ready_handshake.ppif') {
        for my $kind (qw(check semantic)) {
            my $report = query($path, $kind, 0);
            ok(!exists($report->{source}{interface_ports}), 'unrelated source format has no authored ISF declarations');
        }
    }
    is(query('ppif/valid_ready_handshake.ppif', 'schedule', 0)->{interface_ports}, undef,
        'generated PPIF scheduler actor has unknown authored ISF declaration evidence');
};

subtest 'discovery remains complete through native API and actual newline' => sub {
    my $native = capture([$^X, 'bin/fsmgen', '--capability-manifest']);
    is($native->{exit_code}, 0, 'native discovery succeeds');
    is($native->{stderr}, '', 'native discovery stderr clean');
    my $manifest = build_capability_manifest();
    same($json->decode($native->{stdout}), $manifest, 'complete native/in-process discovery equality');
    for my $section (qw(diagnostics semantic_exports embedding)) {
        my $request = {jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{
            name=>'fsmgen_capability_query',arguments=>{section=>$section}}};
        my $response = $api->handle_jsonrpc_request($request);
        ok(!$response->{error} && !$response->{result}{isError}, 'API discovery succeeds');
        same($response->{result}{structuredContent}{payload}, $manifest->{$section}, 'complete API discovery section equality');
        wire_equal($request, $response);
    }
};

subtest 'identical corrupt metadata cannot pass independent declaration expectations' => sub {
    my $expected = $supported{'isf/storage_fields.isf'};
    for my $change (sub { pop @{$_[0]} }, sub { $_[0][0]{width}=2 }, sub { $_[0][0]{width}='1' },
                    sub { $_[0][0]{direction}='output' }, sub { @{$_[0]}=reverse @{$_[0]} },
                    sub { $_[0][0]{private}=1 }) {
        my $bad = $json->decode($json->encode($expected)); $change->($bad);
        my @copies = map {$json->decode($json->encode($bad))} 1..3;
        same($copies[0], $copies[1], 'corrupt native/API parity can still pass');
        same($copies[1], $copies[2], 'corrupt newline parity can still pass');
        isnt(sha256_hex($json->encode($bad)), sha256_hex($json->encode($expected)),
            'independent typed expectation rejects shared field loss, width, role, order or private data');
    }
};

done_testing();
sub p { return {name=>$_[0],direction=>$_[1],width=>$_[2]}; }
sub same { is(sha256_hex($json->encode($_[0])), sha256_hex($json->encode($_[1])), $_[2]); }
sub declarations {
    my ($report,$kind,$expected,$label)=@_;
    my $ports = $kind eq 'schedule' ? $report->{interface_ports} : $report->{source}{interface_ports};
    same($ports, $expected, "$label complete independently expected typed declarations");
}
sub request { return {jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{name=>$tools{$_[1]},arguments=>{source_id=>$_[0]}}}; }
sub query {
    my ($path,$kind,$failure)=@_;
    my $before = sha256_hex(read_file($path));
    my $native = capture([$^X,'bin/fsmgen',@{$flags{$kind}},$path]);
    is($native->{exit_code},$failure?1:0,"$kind $path expected native admission");
    is($native->{stderr},'','native machine-report stderr clean');
    my $report = normalize_repository_paths($json->decode($native->{stdout}),$root);
    my $request = request($path,$kind);
    my $response = $api->handle_jsonrpc_request($request);
    ok(!$response->{error},'report query retains a complete tool result');
    is(!!$response->{result}{isError},!!$failure,'tool admission outcome matches native');
    same($response->{result}{structuredContent}{report},$report,'complete typed native/API report equality');
    same($json->decode($response->{result}{content}[0]{text}),$response->{result}{structuredContent},
        'complete text/structured equality');
    wire_equal($request,$response);
    is(sha256_hex(read_file($path)),$before,'all query transports preserve source bytes');
    return $report;
}
sub wire_equal {
    my ($request,$response)=@_;
    my $wire = capture([$^X,'bin/fsmgen-mcp','--workspace-root','.'],$json->encode($request)."\n");
    is($wire->{exit_code},0,'actual newline transport succeeds');
    is($wire->{stderr},'','newline stderr clean');
    like($wire->{stdout},qr/\A[^\n]+\n\z/,'one compact response per actual newline');
    same($json->decode($wire->{stdout}),$response,'complete typed API/newline response equality');
}
sub capture { FSM::Test::SourceQueryRunner::_capture($_[0],$_[1] // '') }
sub read_file { open my $fh,'<:raw',$_[0] or die $!; local $/; return <$fh>; }
sub write_file { open my $fh,'>:raw',$_[0] or die $!; print {$fh} $_[1] or die $!; close $fh or die $!; }
