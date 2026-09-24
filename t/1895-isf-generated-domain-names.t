#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use JSON::PP ();
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::HDLInstanceIdentifierPolicy;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical->utf8;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $normalize = \&FSM::Test::SourceQueryRunner::normalize_repository_paths;
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my $scheduler = FSM::Scheduler::ISF->new;
my $original = read_file('isf/clock_domain_event_crossing.isf');
my @cases;
for my $entry (
    ['control', 'source'], ['keyword_bus', 'bus'], ['keyword_case', 'BUS'],
    ['keyword_sv', 'interconnect'], ['cdc_collision', 'byte_ready_cdc'],
    ['case_pair', 'CORE'], ['public_input', 'bus_start'],
    ['public_output', 'core_seen'], ['clock_pin', 'bus_clk'], ['reset_pin', 'core_rst_n'],
) {
    my ($name, $domain) = @$entry;
    my $text = $original;
    $text =~ s/\(domain source(?=[ )])/(domain $domain/g;
    $text =~ s/\(from source /\(from $domain /g;
    push @cases, {name => $name, domain => $domain, text => $text};
}
my $cascade = $cases[1]{text};
$cascade =~ s/\(interface/(interface\n    (input bus_instance) (input bus_instance_2)/;
$cascade =~ s/\(on bus_start\)/(on bus_start) (await bus_instance) (await bus_instance_2)/;
push @cases, {name => 'suffix_cascade', domain => 'bus', text => $cascade};
my $activation = $original;
$activation =~ s/\(event byte_ready/(event worker_activation_start/;
$activation =~ s/\(clock-domains/(clock-domains\n    (domain worker_domain (clock worker_clk) (reset worker_rst_n))/;
$activation =~ s/\(crossings/(crossings\n    (activation worker (from source) (to worker_domain))/;
$activation =~ s/\(interface/(interface\n    (output worker_observed (domain worker_domain))/;
$activation =~ s/\(await byte_ready_ready\)/(await byte_ready_ready)\n    (do worker)/;
$activation =~ s/\(transaction core_consume/(transaction worker (domain worker_domain) (complete worker_observed))\n  (transaction core_consume/;
# Keep independently triggered transactions in separate domain FSMs. The
# original mixed-destination failure is retained and owned by .32.1.3.3.1.
push @cases, {name => 'event_activation', domains => [qw(worker_domain source core)], text => $activation};
my $dual = read_file('isf/clock_domain_dual_event_crossing.isf');
$dual =~ s/\(event core_ack/(event REQ_SEEN/;
push @cases, {name => 'case_events', domain => 'source', text => $dual};

for my $case (@cases) {
    my ($name, $text) = @{$case}{qw(name text)};
    subtest "$name preserves artifacts and public identities" => sub {
        my $path = "$work/$name.isf";
        write_file($path, $text);
        my $actor = FSM::Adapter::ISF->new->parse_file($path);
        my $lowered = $scheduler->lower($actor);
        is_deeply($scheduler->lower($actor), $lowered, 'allocation is deterministic and does not mutate the actor');
        my $schedule = $json->decode($scheduler->report($actor));
        is_deeply([map { $_->{name} } @{$schedule->{clock_domains}}], $case->{domains} || [$case->{domain}, 'core'],
            'logical domain names and order are preserved');
        ok(!(grep { exists $_->{instance} } @{$schedule->{clock_domains}}), 'private domain allocation is not added to the public schema');
        my $dir = "$work/$name";
        mkdir $dir or die $!;
        my $r = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', '--outdir', $dir, $path], '');
        is($r->{exit_code}, 0, 'real CLI materializes the complete strict composition') or diag($r->{stdout}, $r->{stderr});
        opendir my $dh, $dir or die $!;
        my @materialized = sort grep { /\.fsm\z/ } readdir $dh;
        closedir $dh;
        is_deeply(\@materialized, [sort keys %{$lowered->{files}}], 'filesystem preserves every public lowering artifact');
        my %folded;
        for my $file (sort keys %{$lowered->{files}}) {
            ok(!$folded{lc $file}++, "$file has a case-independent unique filename");
            is(read_file("$dir/$file"), $lowered->{files}{$file}, "$file retains exactly its own module contents");
            my $check = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', "$dir/$file"], '');
            is($check->{exit_code}, 0, "$file independently passes strict admission") or diag($check->{stdout}, $check->{stderr});
        }
        my $relative = File::Spec->abs2rel($path, $root);
        my %reports;
        for my $kind (qw(check semantic schedule)) {
            my %flags = (check => [qw(--strict --check --json)], semantic => [qw(--strict --emit-semantic-json)], schedule => ['--emit-schedule-json']);
            my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
            my $native = $capture->([$^X, 'bin/fsmgen', @{$flags{$kind}}, $relative], '');
            is($native->{exit_code}, 0, "$kind native query succeeds");
            $reports{$kind} = $normalize->($json->decode($native->{stdout}), $root);
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $tools{$kind}, arguments => {source_id => $relative}}};
            my $api = $adapter->handle_jsonrpc_request($request);
            ok(!$api->{result}{isError}, "$kind API succeeds");
            is_deeply($api->{result}{structuredContent}{report}, $reports{$kind}, "$kind complete native/API reports agree");
            my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
            is($wire->{exit_code}, 0, "$kind newline MCP process succeeds");
            is_deeply($json->decode($wire->{stdout}), $api, "$kind entire newline/API responses agree");
        }
        my $children = $reports{semantic}{semantic}{forward_ir}{intent_hir}{composition_children};
        ok(ref($children) eq 'ARRAY', 'semantic API exposes the structural children');
        $children ||= [];
        my %by_module = map { $_->{module_name} => $_ } @$children;
        my %labels;
        for my $child (@$children) {
            my $label = $child->{instance_name};
            ok(FSM::Support::HDLInstanceIdentifierPolicy->is_portable_instance_identifier($label), "$label is portable");
            ok(!$labels{lc $label}++, "$label is case-independently unique");
        }
        for my $domain (@{$reports{schedule}{clock_domains}}) {
            (my $module = $domain->{scheduled_fsm}) =~ s/\.fsm\z//;
            my $child = $by_module{$module};
            ok($child, "$domain->{name} joins through scheduled_fsm to its physical child");
            is($child->{source_name}, $module, 'composition source identity agrees with the artifact root');
        }
        for my $crossing (@{$reports{schedule}{crossings}}) {
            for my $prefix ($crossing->{kind} eq 'event' ? ('') : ('start_', 'done_')) {
                is($by_module{$crossing->{"${prefix}module"}}{instance_name}, $crossing->{"${prefix}instance"},
                    'reported crossing module/instance agrees with emitted composition');
            }
        }
        if ($name eq 'suffix_cascade') {
            is($by_module{'clock_domain_event_crossing__domain_bus'}{instance_name}, 'bus_instance_3',
                'allocation skips public pins that occupy keyword and numbered aliases');
        }
        if ($name eq 'event_activation') {
            my ($event, $activation) = @{$reports{schedule}{crossings}};
            is($event->{instance}, 'worker_activation_start_cdc', 'first event allocation stays stable');
            is($activation->{start_instance}, 'worker_activation_start_cdc_cdc', 'activation allocation avoids the event label');
        }
        # The existing oracle knows only public pins and expected event counts;
        # it never consumes the allocator or generated routes being tested.
        if ($name =~ /\A(?:keyword_bus|cdc_collision|case_pair|event_activation)\z/) {
            subtest 'renaming preserves externally observed CDC behavior' => sub {
                plan skip_all => 'Verilator runtime provider unavailable or not qualified'
                    unless can_run('verilator') && darwin_verilator_runtime_qualified();
                for my $language (qw(systemverilog verilog)) {
                    my $hdl = "$dir/$language.sv";
                    my $emit = $capture->([$^X, 'bin/fsmgen', '--strict', '--quiet', '--language', $language,
                        '--output', $hdl, $path], '');
                    is($emit->{exit_code}, 0, "$language strict HDL generation succeeds") or diag($emit->{stderr});
                    next if $emit->{exit_code};
                    my $compile = run_verilator_compile(['verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
                        ($name eq 'event_activation' ? ('-DEXTRA_WORKER_DOMAIN') : ()),
                        '-j', '1', '--top-module', 'reset_event_tb', '--Mdir', "$dir/obj_$language",
                        $hdl, 't/data/isf_reset_event_tb.sv']);
                    ok($compile->{ok}, "$language independent oracle builds") or diag($compile->{diagnostic}, $compile->{stderr});
                    next unless $compile->{ok};
                    my $runtime = run_generated_binary(["$dir/obj_$language/Vreset_event_tb"]);
                    ok($runtime->{ok}, "$language independent event/reset oracle passes") or diag($runtime->{diagnostic}, $runtime->{stdout}, $runtime->{stderr});
                    like($runtime->{stdout}, qr/ISF_RESET_EVENT_PASS/, "$language oracle reaches completion");
                }
            };
        }
    };
}
done_testing();
sub read_file {
    open my $fh, '<', $_[0] or die $!;
    my $text = do { local $/; <$fh> }; close $fh or die $!; return $text;
}
sub write_file {
    open my $fh, '>', $_[0] or die $!; print {$fh} $_[1] or die $!; close $fh or die $!;
}
