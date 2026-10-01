use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my %flags = (check => [qw(--strict --check --json)], semantic => [qw(--strict --emit-semantic-json)],
    schedule => ['--emit-schedule-json']);
my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
my $definition = '(record (kind (bits 2)) (payload (record (data (signed (four_state (bits 5))))'
    . ' (flags (list bit (two_state (bits 2)))))))';
write_file("$work/shared.fsm", '(?pkg:shared (+types (type frame ' . $definition . ')))');
my $package_before = sha256_hex(read_file("$work/shared.fsm"));
my @producers = qw(bin/fsmgen bin/fsmgen-mcp perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm
    perl/FSM/Support/ISFRecordPortContexts.pm perl/FSM/Support/ISFRecordPortScopes.pm
    perl/FSM/Scheduler/ISF/ChildStorageOwnership.pm);
my $producer_before = {map {$_ => sha256_hex(read_file($_))} @producers};

sub source {
    my ($body, %args) = @_;
    my $types = $args{imported} ? '(imports (package shared)) (types (type frame shared.frame))'
        : '(types (type frame ' . $definition . '))';
    my $domain = $args{foreign} ? 'aux' : 'core';
    my $width = $args{width} // 5;
    return '(actor contextual_records (clock-domains (domain core (clock clk) (reset (rst_n async active_low)) :default)'
        . ' (domain aux (clock aux_clk))) ' . $types
        . ' (enums (packet (OTHER 1)) (mode (ON 1)))'
        . ' (interface (input start) (input scalar (width 5)) (input mode (domain aux))'
        . " (input packet (type frame) (domain $domain)) (output seen (width $width)) (output whole (width 5)) (output flag) (output done))"
        . ' (storage (var held (type frame) (reset 5))) ' . $body . ')';
}
sub parent {return '(transaction main (domain core) (on start) ' . $_[0] . ' (complete done))'}
sub child {
    return '(transaction worker (domain core) (ports (output result (width ' . ($_[1] // 5) . '))) '
        . $_[0] . ' (complete done))'
        . ' (transaction main (domain core) (on start) (spawn worker as job (bind (output result seen)))'
        . ' (await_all done) (complete done))';
}

subtest 'actual parent and generated foreign paths retain the declared root owner' => sub {
    for my $path (
        ['nested', 'packet.payload.data', 5], ['slice', 'packet.payload.data[3:0]', 4],
        ['reverse', 'packet.payload.data[0:3]', 4], ['single', 'packet.payload.data[4:4]', 1],
        ['list', 'packet.payload.flags[0]', 1], ['list_slice', 'packet.payload.flags[1][1:0]', 2],
    ) {
        my ($name, $token, $width) = @$path;
        for my $generated (0, 1) {
            my $owner = $generated ? 'worker' : 'main';
            my $body = $generated ? child("(set result $token)", $width) : parent("(set seen $token)");
            refuses("foreign_${name}_$owner", source($body, foreign => 1, width => $width, imported => $generated),
                qr/clock-domain violation: transaction '\Q$owner\E' set clause read signal '\Q$token\E' owned by domain 'aux' from domain 'core' without a crossing primitive/);
        }
    }
    for my $generated (0, 1) {
        my $owner = $generated ? 'worker' : 'main';
        my $body = $generated ? child('(set held packet) (set result 0)') : parent('(set held packet)');
        refuses("foreign_copy_$owner", source($body, foreign => 1, imported => $generated),
            qr/clock-domain violation: transaction '\Q$owner\E' set clause read signal 'packet' owned by domain 'aux' from domain 'core'/);
    }
};

subtest 'authored domain control sample rule and drive contexts retain foreign ownership' => sub {
    for my $case (
        ['condition', parent('(when packet.payload.data (set seen 1))'), qr/transaction 'main'.*read signal/],
        ['body_sample', parent('(sample packet.payload.data as q) (set seen q)'), qr/transaction 'main' sample clause read signal/],
        ['entry_sample', '(transaction main (domain core) (on start (sample packet.payload.data as q))'
            . ' (set seen q) (complete done))', qr/transaction 'main' sample clause read signal/],
        ['rule', '(rule observe (domain core) 1 (seen packet.payload.data))', qr/rule 'observe'.*read signal/],
        ['inline_drive', parent('(drive (seen packet.payload.data))'), qr/transaction 'main'.*read signal/],
        ['named_drive', '(drive publish (seen packet.payload.data)) ' . parent('(drive publish)'), qr/drive 'publish' assignment read signal/],
    ) {
        refuses("foreign_$case->[0]", source($case->[1], foreign => 1, imported => 1),
            qr/clock-domain violation: $case->[2] 'packet.payload.data' owned by domain 'aux' from domain 'core'/);
    }
};

subtest 'domain and generated input roots and members remain read-only' => sub {
    for my $generated (0, 1) {
        for my $target ('packet', 'packet.payload.data') {
            my $rhs = $target eq 'packet' ? 'held' : '1';
            my $body = $generated ? child("(set $target $rhs) (set result 0)") : parent("(set $target $rhs)");
            refuses(($generated ? 'child' : 'parent') . ($target eq 'packet' ? '_input_root' : '_input_member'),
                source($body, imported => $generated), qr/cannot write declared input '\Q$target\E'/);
        }
    }
};

subtest 'nearest scalar declarations cannot borrow foreign record members' => sub {
    for my $token ('packet.payload.data', 'packet[0].payload.data', 'packet[0:0].payload.data') {
        (my $suffix = $token) =~ s/\W/_/g;
        my $formal = '(transaction worker (domain core) (ports (input packet (width 3)) (output result (width 5)))'
            . " (set result $token) (complete done))"
            . ' (transaction main (domain core) (on start) (spawn worker as job'
            . ' (bind (input packet scalar[2:0]) (output result seen))) (await_all done) (complete done))';
        refuses("formal_$suffix", source($formal, foreign => 1, imported => 1), qr/member_on_non_record/);
        my $drive = "(drive (publish packet) (seen $token)) " . child('(drive publish start) (set result 0)');
        refuses("drive_$suffix", source($drive, foreign => 1), qr/member_on_non_record/);
    }
    refuses('local_member', source(child('(local packet (width 3)) (set result packet.payload.data)'), foreign => 1),
        qr/member_on_non_record/);
    refuses('local_pin_collision', source(parent('(local packet (width 3)) (set seen packet[0])'), width => 1),
        qr/\(local packet \.\.\.\).*collides with interface port 'packet'/);
};

subtest 'explicit binding and sole whole writer boundaries remain closed' => sub {
    my $writer = '(transaction worker (domain core) (set held packet) (complete done))';
    my $spawn = '(transaction main (domain core) (on start) (spawn worker as job) (await_all done) (complete done))';
    refuses('parent_and_child_writer', source($writer . $spawn . ' (rule competing (domain core) start (held packet))', imported => 1),
        qr/parent writer and generated child writer/);
    (my $two = $spawn) =~ s/\(await_all done\)/(spawn worker as peer) (await_all done)/;
    refuses('competing_child_writers', source($writer . $two), qr/competing generated child writers/);
    (my $partial = $writer) =~ s/\(set held packet\)/(set held.payload.data packet.payload.data)/;
    refuses('unqualified_child_member_writer', source($partial . $spawn, imported => 1),
        qr/only full-width variable sequential writes are qualified/);
    my $unbound = '(transaction worker (domain core) (set seen packet.payload.data) (complete done))' . $spawn;
    refuses('unbound_child_output', source($unbound), qr/leaves child port 'core__job.seen' unconnected/, 1);
    refuses('aggregate_child_formal', source('(transaction worker (domain core) (ports (input payload (type frame))))'),
        qr/transaction 'worker' port 'payload' references aggregate type/);
};

subtest 'admitted scalar formal and drive slices retain exact local physical identities' => sub {
    my $formal = '(transaction main (domain core) (ports (input packet (width 3))) (on start)'
        . ' (set seen packet[2:0]) (complete done))';
    accepts('formal_slice', source($formal, foreign => 1, width => 3, imported => 1),
        qr/isf_port_main_packet\[2:0\]/, 3, 3);
    my $drive = '(drive (publish packet) (whole packet) (seen packet[3:0])) ' . parent('(drive publish scalar)');
    accepts('drive_slice', source($drive, foreign => 1, width => 4), qr/seen>\s+publish_packet\[3:0\]/, undef, 4);
    my $local = parent('(local count (width 3) (default 2)) (set count scalar[2:0]) (set seen count)');
    accepts('local_scalar', source($local, foreign => 1, width => 3), qr/\(count 3\)/, undef, 3);
    my $namespace = parent('(when mode.ON (set seen scalar))');
    accepts('foreign_scalar_namespace', source($namespace, foreign => 1, imported => 1), qr/mode\.ON/, undef, 5);

};

same({map {$_ => sha256_hex(read_file($_))} @producers}, $producer_before,
    'all actual public qualifications preserve exact named producer bytes');
done_testing;

sub refuses {
    my ($name, $text, $cause, $preview) = @_;
    my $path = fixture($name, $text);
    for my $kind (qw(check semantic)) {
        my $native = capture([$^X, 'bin/fsmgen', @{$flags{$kind}}, $path]);
        is($native->{exit_code}, 1, "$name $kind native refusal") or diag($native->{stdout} . $native->{stderr});
        is($native->{stderr}, '', "$name $kind clean machine-report stderr");
        my $report = eval {$json->decode($native->{stdout})};
        ok(ref($report) eq 'HASH', "$name $kind complete failure JSON") or diag($native->{stdout});
        next unless ref($report) eq 'HASH';
        $report = normalize_repository_paths($report, $root);
        ok(!$report->{success}, "$name $kind explicit failure");
        like(first_cause($report->{diagnostics}[0]{message} // ''), $cause, "$name $kind independent first cause");
        ok(exists($report->{diagnostics}[0]{code}), "$name $kind nullable diagnostic code retained");
        is($report->{source}{input}, $path, "$name $kind exact source provenance");
        ok(!exists($report->{source}{interface_ports}), "$name $kind no successful declaration snapshot");
        ok(!defined($report->{semantic}), "$name $kind no partial semantic success");
        ok(!$report->{generated_output}{emitted}, "$name $kind no emitted HDL");
        my $request = request($path, $kind);
        my $response = $api->handle_jsonrpc_request($request);
        ok(!$response->{error} && $response->{result}{isError}, "$name $kind API compiler-failure envelope")
            or diag($json->encode($response));
        next if $response->{error};
        same($response->{result}{structuredContent}{report}, $report, "$name $kind complete typed native/API failure equality");
        same($json->decode($response->{result}{content}[0]{text}), $response->{result}{structuredContent},
            "$name $kind complete text/structured failure equality");
        wire_equal($request, $response, "$name $kind");
    }
    if ($preview) {
        my $native = capture([$^X, 'bin/fsmgen', @{$flags{schedule}}, $path]);
        is($native->{exit_code}, 0, "$name existing pre-HDL schedule preview succeeds");
        is($native->{stderr}, '', "$name schedule preview stderr is clean");
        my $report = $json->decode($native->{stdout});
        $report = normalize_repository_paths($report, $root);
        is($report->{scheduled_fsm}, 'contextual_records_top.fsm', 'preview retains the intended top carrier');
        same($report->{clock_domains}[0]{child_instances},
            [{child => 'worker', instance => 'job', kind => 'spawn', owner => 'main'}],
            'preview retains the exact planned child identity without claiming C2 qualification');
        same($report->{compile_issues}, [], 'preview reports scheduler issues only, before later C2 validation');
        my $request = request($path, 'schedule');
        my $response = $api->handle_jsonrpc_request($request);
        ok(!$response->{error} && !$response->{result}{isError}, "$name schedule API retains its preview contract");
        same($response->{result}{structuredContent}{report}, $report, "$name entire typed native/API preview equality");
        same($json->decode($response->{result}{content}[0]{text}), $response->{result}{structuredContent},
            "$name complete preview text/structured equality");
        wire_equal($request, $response, "$name schedule preview");
    } else {
        my $native = capture([$^X, 'bin/fsmgen', @{$flags{schedule}}, $path]);
        isnt($native->{exit_code}, 0, "$name native schedule refusal") or diag($native->{stdout} . $native->{stderr});
        is($native->{stdout}, '', "$name no partial schedule JSON");
        like(first_cause($native->{stderr}), $cause, "$name schedule independent first cause");
        my $request = request($path, 'schedule');
        my $response = $api->handle_jsonrpc_request($request);
        same($response, {jsonrpc => '2.0', id => 1, error => {code => -32000,
            message => 'FSMGen command failed without a matching public failure report'}},
            "$name exact message-only schedule error with no result or data");
        wire_equal($request, $response, "$name schedule");
    }
    unchanged($path, $text, $name);
}

sub accepts {
    my ($name, $text, $identity, $formal_width, $seen_width) = @_;
    my $path = fixture($name, $text);
    my $actor = FSM::Adapter::ISF->new->parse_file($path);
    my $before = $json->encode($actor);
    my $expected_ports = [
        {name => 'start', direction => 'input', width => 1, domain => 'core'},
        {name => 'scalar', direction => 'input', width => 5, domain => 'core'},
        {name => 'mode', direction => 'input', width => 1, domain => 'aux'},
        {name => 'packet', direction => 'input', width => 10, domain => 'aux', type => 'frame', type_kind => 'record', fields => [
            {path => 'kind', width => 2, lsb => 8, msb => 9, signed => 0},
            {path => 'payload.data', width => 5, lsb => 3, msb => 7, signed => 1, state_model => 'four_state'},
            {path => 'payload.flags[0]', width => 1, lsb => 2, msb => 2, signed => 0},
            {path => 'payload.flags[1]', width => 2, lsb => 0, msb => 1, signed => 0, state_model => 'two_state'}]},
        {name => 'seen', direction => 'output', width => $seen_width, domain => 'core'},
        {name => 'whole', direction => 'output', width => 5, domain => 'core'},
        {name => 'flag', direction => 'output', width => 1, domain => 'core'},
        {name => 'done', direction => 'output', width => 1, domain => 'core'}];
    same($actor->{interface_port_metadata}, $expected_ports, "$name entire independently authored declaration/layout");
    my $product = FSM::Scheduler::ISF->new->lower($actor);
    is($json->encode($actor), $before, "$name complete caller facts unchanged");
    my $owner = $product->{files}{'contextual_records__domain_core.fsm'};
    like($owner, $identity, "$name literal physical scalar identity");
    unlike($owner, qr/\(packet frame\)/, "$name core does not inherit foreign record facts");
    like($product->{files}{'contextual_records__domain_aux.fsm'}, qr/\(packet frame\)/,
        "$name foreign record declaration remains only in aux");
    like($owner, qr/\(isf_port_main_packet \Q$formal_width\E\)/, "$name scalar formal width stays independent")
        if defined $formal_width;
    my $dir = "$work/$name";
    mkdir $dir or die $!;
    for my $file (sort keys %{$product->{files}}) {
        write_file("$dir/$file", $product->{files}{$file});
        my $checked = capture([$^X, 'bin/fsmgen', '--strict', '--check', '--json', "$dir/$file"]);
        is($checked->{exit_code}, 0, "$name actual $file strict replay") or diag($checked->{stdout} . $checked->{stderr});
    }
    for my $kind (qw(check semantic schedule)) {
        my $native = capture([$^X, 'bin/fsmgen', @{$flags{$kind}}, $path]);
        is($native->{exit_code}, 0, "$name $kind actual native success") or diag($native->{stdout} . $native->{stderr});
        is($native->{stderr}, '', "$name $kind clean machine-report stderr");
        my $report = eval {$json->decode($native->{stdout})};
        ok(ref($report) eq 'HASH', "$name $kind complete success JSON") or diag($native->{stdout});
        next unless ref($report) eq 'HASH';
        $report = normalize_repository_paths($report, $root);
        ok($report->{success}, "$name $kind explicit success") unless $kind eq 'schedule';
        my $ports = $kind eq 'schedule' ? $report->{interface_ports} : $report->{source}{interface_ports};
        same($ports, $expected_ports, "$name $kind entire independently authored interface snapshot");
        my $response = $api->handle_jsonrpc_request(request($path, $kind));
        ok(!$response->{error} && !$response->{result}{isError}, "$name $kind API success") or diag($json->encode($response));
        next if $response->{error};
        same($response->{result}{structuredContent}{report}, $report, "$name $kind complete typed native/API success equality");
        same($json->decode($response->{result}{content}[0]{text}), $response->{result}{structuredContent},
            "$name $kind complete text/structured success equality");
        wire_equal(request($path, $kind), $response, "$name $kind");
    }
    unchanged($path, $text, $name);
}

sub fixture {my $path = "$work/$_[0].isf"; write_file($path, $_[1]); return File::Spec->abs2rel($path, $root)}
sub unchanged {
    is(read_file($_[0]), $_[1], "$_[2] exact source bytes retained");
    is(sha256_hex(read_file("$work/shared.fsm")), $package_before, "$_[2] exact imported package bytes retained");
}
sub first_cause {
    my @lines = split /\n/, $_[0];
    shift @lines while @lines && $lines[0] =~ /\A(?:Source file|Parent composition source|Expected child source file|Search roots|Searched locations|Generated child source):/;
    return $lines[0] // '';
}
sub request {return {jsonrpc => '2.0', id => 1, method => 'tools/call',
    params => {name => $tools{$_[1]}, arguments => {source_id => $_[0]}}}}
sub same {is($json->encode($_[0]), $json->encode($_[1]), $_[2])}
sub capture {return FSM::Test::SourceQueryRunner::_capture($_[0], $_[1] // '')}
sub wire_equal {
    my ($request, $response, $name) = @_;
    my $wire = capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request) . "\n");
    is($wire->{exit_code}, 0, "$name actual newline transport succeeds");
    is($wire->{stderr}, '', "$name actual newline stderr is clean");
    like($wire->{stdout}, qr/\A[^\n]+\n\z/, "$name exactly one compact newline response");
    my $decoded = eval {$json->decode($wire->{stdout})};
    ok(ref($decoded) eq 'HASH', "$name newline response is complete JSON") or diag($wire->{stdout});
    same($decoded, $response, "$name entire typed API/newline equality") if ref($decoded) eq 'HASH';
}
sub read_file {open my $file, '<:raw', $_[0] or die $!; local $/; return <$file>}
sub write_file {open my $file, '>:raw', $_[0] or die $!; print {$file} $_[1] or die $!; close $file or die $!}
