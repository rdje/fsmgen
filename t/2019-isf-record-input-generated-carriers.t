use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Temp qw(tempdir);
use File::Spec;
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $work = tempdir(CLEANUP => 1);
my $root = abs_path('.');
my $json = JSON::PP->new->canonical;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my %flags = (check => [qw(--strict --check --json)], semantic => [qw(--strict --emit-semantic-json)],
    schedule => ['--emit-schedule-json']);
my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
my $definition = '(record (kind (bits 2)) (payload (record'
    . ' (data (signed (four_state (bits 5)))) (flags (list bit (two_state (bits 2)))))))';
my $spec = {kind => 'record', width => 10, signed => 0, member_order => [qw(kind payload)], members => {
    kind => {kind => 'bits', width => 2, signed => 0},
    payload => {kind => 'record', width => 8, signed => 0, member_order => [qw(data flags)], members => {
        data => {kind => 'bits', width => 5, signed => 1, state_model => 'four_state'},
        flags => {kind => 'list', width => 3, signed => 0, items => [
            {kind => 'bit', width => 1, signed => 0},
            {kind => 'bits', width => 2, signed => 0, state_model => 'two_state'}]}}}}};
my $fields = [
    {path => 'kind', width => 2, lsb => 8, msb => 9, signed => 0},
    {path => 'payload.data', width => 5, lsb => 3, msb => 7, signed => 1, state_model => 'four_state'},
    {path => 'payload.flags[0]', width => 1, lsb => 2, msb => 2, signed => 0},
    {path => 'payload.flags[1]', width => 2, lsb => 0, msb => 1, signed => 0, state_model => 'two_state'}];
write_file("$work/shared.fsm", '(?pkg:shared (+types (type frame ' . $definition . ')))');

for my $case (
    ['local_readers', 0, 0, 0, 0], ['imported_readers', 0, 1, 0, 0],
    ['domain_readers', 1, 0, 0, 0], ['imported_domain_readers', 1, 1, 0, 0],
    ['domain_writer', 1, 0, 1, 0], ['imported_domain_do_writer', 1, 1, 1, 1],
) {
    my ($name, $domains, $imported, $writer, $blocking) = @$case;
    subtest $name => sub {
        my $base_type = $imported ? 'shared.frame' : 'frame';
        my $types = $imported ? '(imports (package shared)) (types (type alias shared.frame))'
            : '(types (type frame ' . $definition . ') (type alias frame))';
        my $owner = $domains ? '(domain io)' : '';
        my $unused_owner = $domains ? '(domain idle)' : '';
        my $system = $domains ? '(clock-domains (domain idle (clock idle_clk) :default)'
            . ' (domain io (clock clk) (reset (rst_n async active_low))))'
            : '(clock clk) (reset (rst_n async active_low))';
        my $worker = '(transaction worker ' . $owner . ' (params (MODE 0))'
            . ' (ports (output result (width 5))) (wait 2)'
            . ($writer ? ' (set held packet)' : '')
            . ' (set result packet.payload.data) (complete done))';
        my $calls = $blocking ? '(do worker (params (MODE 1)) (bind (output result seen)))'
            : '(spawn worker as left (bind (output result seen)))'
                . ($writer ? '' : ' (spawn worker as right (params (MODE 2)) (bind (output result again)))')
                . ' (await_all done)';
        my $text = '(actor ' . $name . ' ' . $system . ' ' . $types
            . ' (interface (input start ' . $owner . ') (input packet (type alias) ' . $owner . ')'
            . ' (input unused (type ' . $base_type . ') ' . $unused_owner . ')'
            . ' (output seen (width 5) ' . $owner . ') (output again (width 5) ' . $owner . ')'
            . ' (output done ' . $owner . '))'
            . ' (storage (var held (type ' . $base_type . ') (reset 5) ' . $owner . ')) '
            . $worker . ' (transaction main ' . $owner . ' (on start)'
            . ($writer ? '' : ' (set held packet)') . ' ' . $calls . ' (complete done)))';
        my $source = "$work/$name.isf";
        write_file($source, $text);
        my $actor = FSM::Adapter::ISF->new->parse_file($source);
        my $before = $json->encode($actor);
        my @ports = (port('start', 'input', 1), record_port('packet', 'alias'),
            record_port('unused', $base_type), port('seen', 'output', 5),
            port('again', 'output', 5), port('done', 'output', 1));
        if ($domains) {$_->{domain} = $_->{name} eq 'unused' ? 'idle' : 'io' for @ports}
        same($actor->{interface_port_metadata}, \@ports, 'every authored port and packed range is independently expected');
        for my $value (@{$actor->{interface}{inputs}}, @{$actor->{storage}}) {
            next unless $value->{name} =~ /\A(?:packet|unused|held)\z/;
            same($value->{type_spec}, $spec, "$value->{name} has the entire independently authored recursive type");
        }
        my $scheduler = FSM::Scheduler::ISF->new;
        my $product = $scheduler->lower($actor);
        my $report = $json->decode($scheduler->report($actor));
        is($json->encode($actor), $before, 'complete caller kinds and facts survive lower and report');
        same($report->{interface_ports}, \@ports, 'schedule has only complete authored declarations');
        my $parent = $domains ? "${name}__domain_io" : $name;
        my $child = $domains ? "${parent}__child_worker" : 'worker';
        my @instances = $blocking ? ('main_worker_do_0') : $writer ? ('left') : qw(left right);
        my @files = ("$parent.fsm", "$child.fsm", "${name}_top.fsm",
            $domains ? ("${name}__domain_idle.fsm") : ());
        same([sort keys %{$product->{files}}], [sort @files], 'one definition is reused without missing or extra artifacts');
        my $parent_text = $product->{files}{"$parent.fsm"};
        my $child_text = $product->{files}{"$child.fsm"};
        like($parent_text, qr/\(packet alias\)/, 'owner input remains a typed packed root');
        like($parent_text, qr/\(held \Q$base_type\E \(reset 5\)\)/, 'only owner stores and resets the packed register');
        like($child_text, qr/\(packet alias\)/, 'actual child inherits the packed alias');
        unlike($child_text, qr/\(held \Q$base_type\E|\(internal held\)|\(input unused\)/,
            'child has no copied owner register or unread inherited declaration');
        like($child_text, qr/\(clock clk\)\s*\(areset rst_n\)/, 'child retains exactly its owning clock and reset');
        like($child_text, qr/\(result> packet\.payload\.data\)/, 'child reads the live scalar member without inferred capture');
        my @child_roles = ('(input start)', '(input packet)', '(output done)', '(output result)',
            $writer ? ('(output isf_write_held_data)', '(output isf_write_held_enable)') : (),
            '(internal isf_child_start_seen)');
        my ($interface) = $child_text =~ /\(\+interface\n(.*?)\n  \)/s;
        same([map {s/^\s+|\s+$//gr} split /\n/, $interface // ''], \@child_roles,
            'complete child interface has exact private roles');
        if ($writer) {
            like($child_text, qr/\(isf_write_held_data \Q$base_type\E\)/, 'private write data preserves storage alias');
            like($child_text, qr/\(= \(isf_write_held_data> packet\)\)/, 'whole copy uses the original packed input');
            like($child_text, qr/\(= \(isf_write_held_enable> 1\)\)/, 'write has an explicit enable at its original state');
        } else {like($parent_text, qr/\(<- \(held packet\)\)/, 'parent whole copy retains the original assignment');}
        my $top = $product->{files}{"${name}_top.fsm"};
        my ($ports_block) = $top =~ /\(\?ports:public_io\n(.*?)\n  \)/s;
        my @public = ($domains ? ('idle_clk') : (), qw(clk rst_n start packet<10 unused<10 seen>5 again>5 done>));
        same([map {s/^\s+|\s+$//gr} split /\n/, $ports_block // ''], \@public,
            'complete public top exposes exactly authored pins and clocks/resets');
        my $parent_instance = $domains ? 'io' : $name;
        my @links = (['start', "$parent_instance.start"], ['packet', "$parent_instance.packet"],
            $domains ? () : (['unused', "$parent_instance.unused"]),
            ["$parent_instance.seen", 'seen'], ["$parent_instance.again", 'again'], ["$parent_instance.done", 'done']);
        for my $instance (@instances) {
            my $physical = $domains ? "io__$instance" : $instance;
            like($top, qr/\(\?fsmc:\Q$physical\E \Q$child\E(?:\s|\))/, 'each instance uses the one correctly typed definition');
            push @links, ['packet', "$physical.packet"];
            push @links, ["$physical.isf_write_held_data", "$parent_instance.isf_write_${instance}_held_data"],
                ["$physical.isf_write_held_enable", "$parent_instance.isf_write_${instance}_held_enable"] if $writer;
            push @links, ["$parent_instance.${instance}_start", "$physical.start"],
                ["$physical.done", "$parent_instance.${instance}_done"],
                ["$physical.result", "$parent_instance.${instance}_result"];
        }
        push @links, ['unused', 'idle.unused'] if $domains;
        my ($top_root) = $top =~ /\A(\(\?top:.*?\n\))/s;
        my @actual_links = ($top_root // '') =~ /^    \(([^()\n]+ [^()\n]+)\)$/mg;
        same([sort @actual_links], [sort map {join ' ', @$_} @links], 'complete private and public wiring has exact endpoints');
        if ($domains) {
            same($report->{inferred_storage}, [], 'outer top has no domain-owned registers');
            my %owned = map {$_->{name} => $_} @{$report->{clock_domains}};
            same($owned{idle}{interface_ports}, [$ports[2]], 'unused declaration remains only in its real domain');
            same($owned{io}{interface_ports}, [@ports[0,1,3,4,5]], 'all live declarations remain only in their owning domain');
            same($owned{idle}{inferred_storage}, [], 'idle sibling has no inferred state');
            is($owned{idle}{reset}, undef, 'clock-only sibling has no reset');
            same($owned{io}{reset}, {name => 'rst_n', kind => 'async', polarity => 'active_low'}, 'exact authored owner reset');
            same([grep {($_->{role}//'') eq 'actor_storage'} @{$owned{io}{inferred_storage}}],
                [{name => 'held', kind => 'register', role => 'actor_storage', width => 10,
                    type => $base_type, type_kind => 'record'}], 'complete owned storage excludes public inputs');
        }
        public_products($source, \@ports, $spec, $base_type, $domains, \@instances, $writer);
        mkdir "$work/$name" or die $!;
        for my $file (sort keys %{$product->{files}}) {
            my $path = "$work/$name/$file";
            write_file($path, $product->{files}{$file});
            my $checked = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
            is($checked->{exit_code}, 0, "$file actual strict public replay") or diag($checked->{stdout} . $checked->{stderr});
            is($checked->{stderr}, '', "$file clean machine-report stderr");
            ok($json->decode($checked->{stdout})->{success}, "$file complete success");
        }
        is(read_file($source), $text, 'original authored source stays byte exact');
    };
}

subtest 'maintained imported named-domain example retains its literal declarations' => sub {
    my $source = 'isf/record_input_children.isf';
    my $original = read_file($source);
    my $package_original = read_file('isf/record_input_types.fsm');
    my $actor = FSM::Adapter::ISF->new->parse_file($source);
    my $before = $json->encode($actor);
    my $record = {name => 'packet', direction => 'input', width => 6, type => 'frame',
        type_kind => 'record', domain => 'io', fields => [
            {path => 'flag', width => 1, lsb => 5, msb => 5, signed => 0},
            {path => 'data', width => 5, lsb => 0, msb => 4, signed => 1, state_model => 'four_state'}]};
    my @expected = (port('start', 'input', 1), $record,
        {%{dclone($record)}, name => 'unused', domain => 'idle'}, port('seen', 'output', 5),
        port('again', 'output', 5), port('done', 'output', 1));
    $_->{domain} //= 'io' for @expected;
    same($actor->{interface_port_metadata}, \@expected, 'all maintained pins, aliases, ranges and domains are literal');
    my $maintained_spec = {kind => 'record', width => 6, signed => 0, member_order => [qw(flag data)], members => {
        flag => {kind => 'bit', width => 1, signed => 0},
        data => {kind => 'bits', width => 5, signed => 1, state_model => 'four_state'}}};
    my $product = FSM::Scheduler::ISF->new->lower($actor);
    is($json->encode($actor), $before, 'maintained actor is unchanged');
    public_products($source, \@expected, $maintained_spec, 'frame', 1, [qw(left right)], 0);
    mkdir "$work/maintained" or die $!;
    for my $file (sort keys %{$product->{files}}) {
        my $path = "$work/maintained/$file";
        write_file($path, $product->{files}{$file});
        my $result = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
        is($result->{exit_code}, 0, "$file maintained actual strict replay") or diag($result->{stdout} . $result->{stderr});
        ok($json->decode($result->{stdout})->{success}, "$file maintained complete success");
    }
    is(read_file($source), $original, 'maintained source bytes stay exact');
    is(read_file('isf/record_input_types.fsm'), $package_original, 'shared package bytes stay exact');
};

subtest 'independent typed ownership witnesses reject shared corrupted products' => sub {
    my $expected = [record_port('packet', 'alias'), record_port('unused', 'frame')];
    $expected->[0]{domain} = 'io';
    $expected->[1]{domain} = 'idle';
    for my $corrupt (
        sub {$_[0][0]{domain} = 'idle'}, sub {pop @{$_[0]}},
        sub {$_[0][0]{width} = '10'}, sub {delete $_[0][0]{type}},
        sub {$_[0][0]{fields}[1]{signed} = 0},
        sub {$_[0][0]{fields}[1]{state_model} = 'two_state'},
        sub {$_[0][0]{fields}[1]{lsb} = 0},
    ) {
        my $bad = dclone($expected);
        $corrupt->($bad);
        my @transports = map {dclone($bad)} 1..3;
        same($transports[0], $transports[1], 'shared corrupt native/API projection still has parity');
        same($transports[1], $transports[2], 'shared corrupt API/newline projection still has parity');
        isnt($json->encode($bad), $json->encode($expected), 'literal typed ownership witness detects the shared corruption');
    }
};

done_testing;
sub public_products {
    my ($path, $ports, $type, $storage_type, $domains, $instances, $writer) = @_;
    my $relative = File::Spec->abs2rel($path, $root);
    my ($packet) = grep {$_->{name} eq 'packet'} @$ports;
    my ($unused) = grep {$_->{name} eq 'unused'} @$ports;
    my @producers = qw(bin/fsmgen bin/fsmgen-mcp perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm
        perl/FSM/Composition/GeneratedChildRealizer.pm);
    my $producer_before = {map {$_ => sha256_hex(read_file($_))} @producers};
    my $reset_provenance = $domains ? [{domain => 'idle', origin => 'domain_absent'},
        {domain => 'io', origin => 'explicit'}] : [{domain => undef, origin => 'explicit'}];
    for my $kind (qw(check semantic schedule)) {
        my $native = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', @{$flags{$kind}}, $relative], '');
        is($native->{exit_code}, 0, "$kind actual authored native product succeeds") or diag($native->{stdout} . $native->{stderr});
        is($native->{stderr}, '', "$kind native machine-report stderr is clean");
        my $report = eval {$json->decode($native->{stdout})};
        ok(ref($report) eq 'HASH', "$kind complete native JSON product") or diag($native->{stdout});
        next unless ref($report) eq 'HASH';
        $report = normalize_repository_paths($report, $root);
        my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
            name => $tools{$kind}, arguments => {source_id => $relative}}};
        my $response = $api->handle_jsonrpc_request($request);
        ok(!$response->{error} && !$response->{result}{isError}, "$kind actual public API succeeds")
            or diag($json->encode($response));
        next if $response->{error};
        same($response->{result}{structuredContent}{report}, $report, "$kind complete typed native/API equality");
        same($json->decode($response->{result}{content}[0]{text}), $response->{result}{structuredContent},
            "$kind complete text/structured equality");
        my $wire = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'],
            $json->encode($request) . "\n");
        is($wire->{exit_code}, 0, "$kind actual newline succeeds");
        is($wire->{stderr}, '', "$kind actual newline stderr is clean");
        like($wire->{stdout}, qr/\A[^\n]+\n\z/, "$kind exactly one compact newline response");
        my $decoded = eval {$json->decode($wire->{stdout})};
        ok(ref($decoded) eq 'HASH', "$kind complete newline JSON product") or diag($wire->{stdout});
        same($decoded, $response, "$kind entire typed API/newline response equality") if ref($decoded) eq 'HASH';
        same($kind eq 'schedule' ? $report->{interface_ports} : $report->{source}{interface_ports},
            $ports, "$kind entire independently expected authored declaration/layout");
        if ($kind ne 'schedule') {
            ok($report->{success}, "$kind complete success envelope");
            is($report->{source}{input}, $relative, "$kind exact authored source provenance");
        }
        same($kind eq 'schedule' ? $report->{reset_provenance} : $report->{source}{reset_provenance},
            $reset_provenance, "$kind exact authored reset provenance without an implicit sibling reset");
        if ($kind eq 'schedule' && $domains) {
            my %owned = map {$_->{name} => $_} @{$report->{clock_domains}};
            same($owned{idle}{interface_ports}, [$unused], 'public schedule keeps the unused declaration in idle only');
            same($owned{io}{interface_ports}, [grep {$_->{name} ne 'unused'} @$ports],
                'public schedule keeps every live declaration in io only');
            is($owned{idle}{clock}, 'idle_clk', 'public idle clock remains authored');
            is($owned{idle}{reset}, undef, 'public clock-only sibling has no reset');
            is($owned{io}{clock}, 'clk', 'public owner clock remains authored');
            same($owned{io}{reset}, {name => 'rst_n', kind => 'async', polarity => 'active_low'},
                'public owner reset has the exact authored kind and polarity');
        }
        next unless $kind eq 'semantic' && $report->{success};
        my $hir = $report->{semantic}{forward_ir}{intent_hir};
        my @physical_inputs = ($domains ? ({name => 'idle_clk', direction => 'input', width => 1, signed => 0}) : (),
            map {{name => $_, direction => 'input', width => 1, signed => 0}} qw(clk rst_n start));
        push @physical_inputs, map {{name => $_->{name}, direction => 'input', width => $_->{width}, signed => 0}} ($packet, $unused);
        same($hir->{signal_analysis}{inputs}, \@physical_inputs, 'outer physical inputs are exact vectors, without invented record keys');
        same($hir->{signal_analysis}{outputs}, [map {{name => $_->{name}, direction => 'output', width => $_->{width}, signed => 0}}
            grep {$_->{direction} eq 'output'} @$ports], 'outer physical outputs contain no private handoffs');
        my @children = @{$hir->{composition_children}};
        my $parent = $domains ? 'io' : $report->{semantic}{module}{name} =~ s/_top\z//r;
        my @identities = ($domains ? ('idle') : (), $parent, map {$domains ? "io__$_" : $_} @$instances);
        same([map {$_->{instance_name}} @children], \@identities, 'every actual semantic instance and reused definition is present in order');
        for my $child (@children) {
            my $name = $child->{instance_name} eq 'idle' ? 'unused' : 'packet';
            my $alias = $name eq 'unused' ? $storage_type : $packet->{type};
            my $expected = {name => $name, direction => 'input', width => $type->{width}, signed => 0,
                declared_type_name => $alias, declared_type_spec => dclone($type)};
            same([grep {$_->{name} eq $name} @{$child->{intent_hir}{signal_analysis}{inputs}}], [$expected],
                'complete child HIR input retains its literal recursive record identity');
            same([grep {$_->{name} eq $name} @{$child->{structural_rtl_ir}{ports}}], [{%$expected, type => 'wire'}],
                'complete typed child structural port retains that same literal identity');
            same($child->{intent_hir}{explicit_system_contract}, $child->{instance_name} eq 'idle'
                ? {clock => 'idle_clk', reset => undef, reset_active_level => undef, reset_keyword => undef, reset_kind => undef}
                : {clock => 'clk', reset => 'rst_n', reset_active_level => 0, reset_keyword => 'areset', reset_kind => 'async'},
                'each public child HIR retains only its owning authored clock/reset contract');
            if ($writer && $child->{instance_name} ne $parent && $child->{instance_name} ne 'idle') {
                same([grep {$_->{name} eq 'isf_write_held_data'} @{$child->{intent_hir}{signal_analysis}{outputs}}],
                    [{%$expected, name => 'isf_write_held_data', direction => 'output', declared_type_name => $storage_type}],
                    'semantic private write data retains its complete target type');
            }
        }
    }
    same({map {$_ => sha256_hex(read_file($_))} @producers}, $producer_before,
        'all real native/API/newline queries preserve exact named public producer bytes');
}
sub port {return {name => $_[0], direction => $_[1], width => 0 + $_[2]}}
sub record_port {return {name => $_[0], direction => 'input', width => 10,
    type => $_[1], type_kind => 'record', fields => dclone($fields)}}
sub same {is($json->encode($_[0]), $json->encode($_[1]), $_[2])}
sub read_file {open my $file, '<:raw', $_[0] or die $!; local $/; return <$file>}
sub write_file {open my $file, '>:raw', $_[0] or die $!; print {$file} $_[1] or die $!; close $file or die $!}
