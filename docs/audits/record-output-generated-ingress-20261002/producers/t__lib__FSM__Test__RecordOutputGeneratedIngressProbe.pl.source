use strict;
use warnings;
use lib 'perl', 't/lib';
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Temp qw(tempdir);
use JSON::PP;
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Scheduler::ISF::DomainSource qw(_domain_actor_for_scheduled_artifact);

my ($destination, @selected) = @ARGV;
my %selected = map {($_, 1)} @selected;
die "require an existing repository-relative capture directory\n"
    unless defined($destination) && -d $destination && $destination !~ m{\A/|(?:\A|/)\.\.(?:/|\z)};
my $root = abs_path('.');
my $json = JSON::PP->new->canonical->utf8;
$| = 1;
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my $sources = 'docs/audits/record-output-generated-ingress-20261002/sources';
mkdir $sources unless -d $sources;
my $definition = '(record (tag (bits 2)) (payload (signed (four_state (bits 3)))))';
write_fixture("$sources/shared.fsm", '(?pkg:shared (+types (type frame '.$definition.')))');
my @cases = (
    ['direct', '(transaction main (on start) (set packet held) (complete done))'],
    ['local_do', '(transaction worker (set packet held))'
        .' (transaction main (on start) (do worker) (complete done))'],
    ['spawn_writer', '(transaction worker (set packet held) (complete done))'
        .' (transaction main (on start) (spawn worker as one) (await_all done) (complete done))'],
    ['blocking_writer', '(transaction worker (params (MODE 0)) (set packet held) (complete done))'
        .' (transaction main (on start) (do worker (params (MODE 1))) (complete done))'],
    ['spawn_readers', '(transaction worker (ports (output result (width 3)))'
        .' (set result packet.payload) (complete done))'
        .' (transaction main (on start) (set packet held)'
        .' (spawn worker as left (bind (output result seen)))'
        .' (spawn worker as right (bind (output result again))) (await_all done) (complete done))'],
    ['storage_then_output', '(transaction worker (set held incoming) (complete done))'
        .' (transaction main (on start) (spawn worker as one) (await_all done) (set packet held) (complete done))'],
    ['unused_with_child', '(transaction worker (wait 1) (complete done))'
        .' (transaction main (on start) (spawn worker as one) (await_all done) (complete done))'],
    ['competing_children', '(transaction worker (set packet held) (complete done))'
        .' (transaction main (on start) (spawn worker as left) (spawn worker as right)'
        .' (await_all done) (complete done))'],
    ['formal_shadow', '(transaction worker (ports (output packet (width 3))) (set packet 3) (complete done))'
        .' (transaction main (on start) (spawn worker as one (bind (output packet seen)))'
        .' (await_all done) (complete done))'],
    ['imported_writer', '(transaction worker (set packet held) (complete done))'
        .' (transaction main (on start) (spawn worker as one) (await_all done) (complete done))', 'imported'],
    ['scalar_control', '(transaction worker (ports (output result (width 3)))'
        .' (set result held.payload) (complete done))'
        .' (transaction main (on start) (spawn worker as one (bind (output result seen)))'
        .' (await_all done) (complete done))', 'scalar'],
    ['scalar_writer', '(transaction worker (set packet incoming) (complete done))'
        .' (transaction main (on start) (spawn worker as one) (await_all done) (complete done))', 'scalar'],
    ['scalar_reader', '(transaction worker (ports (output result (width 3)))'
        .' (set result packet) (complete done))'
        .' (transaction main (on start) (spawn worker as one (bind (output result seen)))'
        .' (await_all done) (complete done))', 'scalar_reader'],
    ['input_control', '(transaction worker (ports (output result (width 3)))'
        .' (set result packet.payload) (complete done))'
        .' (transaction main (on start) (spawn worker as one (bind (output result seen)))'
        .' (await_all done) (complete done))', 'input'],
    ['domain_direct', '(transaction main (on start) (set packet held) (complete done))', 'domain'],
    ['domain_writer', '(transaction worker (set packet held) (complete done))'
        .' (transaction main (on start) (spawn worker as one) (await_all done) (complete done))', 'domain'],
    ['domain_readers', '(transaction worker (ports (output result (width 3)))'
        .' (set result packet.payload) (complete done))'
        .' (transaction main (on start) (set packet held)'
        .' (spawn worker as left (bind (output result seen)))'
        .' (spawn worker as right (bind (output result again))) (await_all done) (complete done))', 'domain'],
    ['imported_domain_blocking', '(transaction worker (params (MODE 0)) (set packet held) (complete done))'
        .' (transaction main (on start) (do worker (params (MODE 1))) (complete done))', 'imported_domain'],
);
for my $case (@cases) {
    my ($name, $body, $variant) = @$case;
    next if @selected && !$selected{$name};
    delete $selected{$name};
    my $imported = ($variant // q{}) =~ /imported/;
    my $domains = ($variant // q{}) =~ /domain/;
    my $scalar = ($variant // q{}) =~ /scalar/;
    my $module = 'generated_output_'.$name;
    my $type = $imported ? 'shared.frame' : 'frame';
    my $types = $imported ? '(imports (package shared))'
        : '(types (type frame '.$definition.'))';
    my $packet = $scalar ? '(width 5)' : '(type '.$type.')';
    my $incoming = $scalar ? '(width 5)' : '(type '.$type.')';
    $packet = '(width 3)' if ($variant // '') eq 'scalar_reader';
    my $owner = $domains ? ' (domain io)' : '';
    my $system = $domains ? '(clock-domains (domain idle (clock idle_clk) :default)'
        .' (domain io (clock clk) (reset (rst_n sync active_low))))'
        : '(clock clk) (reset (rst_n sync active_low))';
    if ($domains) {
        $body =~ s/\(transaction (\w+)/'(transaction '.$1.$owner/ge;
        $body .= ' (transaction idle_work (domain idle) (on unused) (wait 1))';
    }
    my $packet_role = ($variant // '') eq 'input' ? 'input' : 'output';
    my $source = '(actor '.$module.' '.$system.' '.$types
        .' (interface (input start'.$owner.') (input incoming '.$incoming.$owner.')'
        .' ('.$packet_role.' packet '.$packet.$owner.')'
        .' (output seen (width 3)'.$owner.') (output again (width 3)'.$owner.') (output done'.$owner.')'
        .($domains ? ' (input unused (domain idle))' : '').')'
        .' (storage (var held (type '.$type.') (reset 5)'.$owner.')) '.$body.')';
    my $path = "$sources/$name.isf";
    write_fixture($path, $source);
    my $actor = FSM::Adapter::ISF->new->parse_file($path);
    my $before = $json->encode($actor);
    my $scheduler = FSM::Scheduler::ISF->new;
    my $formal = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
    my $effective = $formal ? $formal->{actor} : $actor;
    my $ir = attempt(sub {$scheduler->{ir}->build_module($effective)});
    my $lower = attempt(sub {$scheduler->lower($actor)});
    my $report = attempt(sub {$json->decode($scheduler->report($actor))});
    my (%private, %domain_realizations);
    if ($ir->{success}) {
        my $module_ir = $ir->{value};
        if ((($module_ir->{domain_partition} || {})->{kind} // '') eq 'multi_domain') {
            my $partition = $module_ir->{domain_partition};
            for my $domain (@{$partition->{domains}}) {
                my $domain_actor = _domain_actor_for_scheduled_artifact($effective, $domain, $partition->{default_domain});
                my $domain_formal = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $domain_actor);
                my $domain_ir = attempt(sub {$scheduler->{ir}->build_module($domain_formal ? $domain_formal->{actor} : $domain_actor)});
                $domain_realizations{$domain->{name}} = {source => $domain_actor,
                    formal => $domain_formal, ir => $domain_ir,
                    private_carriers => $domain_ir->{success} ? private_carriers($scheduler, $domain_ir->{value}) : {}};
            }
        } else {
            %private = %{private_carriers($scheduler, $module_ir)};
        }
    }
    save("$name-private", {source => $source, source_id => $path, source_sha256 => sha256_hex($source),
        actor_before => $json->decode($before), actor_after => $actor, formal => $formal,
        ir => $ir, lower => $lower, report => $report, private_carriers => \%private,
        domain_realizations => \%domain_realizations});
    for my $kind (qw(check semantic schedule)) {
        save("$name-$kind", query($path, $kind));
    }
    print "$name complete source/IR/private/public capture\n";
}

die 'unknown selected case: '.join(', ', sort keys %selected) if keys %selected;

sub private_carriers {
    my ($scheduler, $ir) = @_;
    my %private;
    for my $entry ([$ir->{actor_name}, $ir],
        map {[$_, $ir->{children}{$_}]} sort keys %{$ir->{children} || {}}) {
        $private{$entry->[0]} = attempt(sub {$scheduler->{fsm_emitter}->emit($entry->[1])});
    }
    if (!grep {!$_->{success}} values %private) {
        my %files = map { ("$_.fsm", $private{$_}{value}) } keys %private;
        $private{top} = attempt(sub {$scheduler->{top_emitter}->emit($ir, \%files)});
    }
    return \%private;
}

# Preserve actual failed commands as well as successful JSON products. A
# schedule refusal intentionally has no native JSON report; its MCP envelope
# is still captured through the same public method and actual newline process.
sub query {
    my ($path, $kind) = @_;
    my %flags = (check => [qw(--strict --check --json)],
        semantic => [qw(--strict --emit-semantic-json)], schedule => ['--emit-schedule-json']);
    my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect',
        schedule => 'fsmgen_schedule_preview');
    my $before = FSM::Test::SourceQueryRunner::_producers($root);
    my $source_before = FSM::Test::SourceQueryRunner::_digest($path);
    local %ENV = %ENV;
    delete @ENV{qw(PERL5LIB PERL5OPT)};
    my $command = [$^X, 'bin/fsmgen', @{$flags{$kind}}, $path];
    my $native = FSM::Test::SourceQueryRunner::_capture($command, '');
    my $parsed = attempt(sub {$json->decode($native->{stdout})});
    my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call',
        params => {name => $tools{$kind}, arguments => {source_id => $path}}};
    my $api = $adapter->handle_jsonrpc_request($request);
    my $input = $json->encode($request)."\n";
    my $wire_command = [$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'];
    my $wire = FSM::Test::SourceQueryRunner::_capture($wire_command, $input);
    $wire->{response} = $json->decode($wire->{stdout});
    return {source_id => $path, query_kind => $kind, command => $command,
        native => $native, native_json => $parsed, request => $request, api => $api,
        wire_command => $wire_command, wire_input => $input, wire => $wire,
        source_sha256_before => $source_before,
        source_sha256_after => FSM::Test::SourceQueryRunner::_digest($path),
        producer_sha256_before => $before,
        producer_sha256_after => FSM::Test::SourceQueryRunner::_producers($root)};
}

sub attempt {
    my ($run) = @_;
    my ($value, $error);
    my $ok = eval {$value = $run->(); 1};
    $error = $@ unless $ok;
    return {success => $ok ? JSON::PP::true : JSON::PP::false, value => $value, error => $error};
}
sub save {write_file("$destination/$_[0].json", $json->encode(normalize_repository_paths($_[1], $root))."\n")}
sub write_file {open my $fh, '>:raw', $_[0] or die $!; print {$fh} $_[1] or die $!; close $fh or die $!}

# Fixed source fixtures are immutable once published; later diagnostic capture
# may read identical bytes but must never rewrite or extend their sealed scope.
sub write_fixture {
    my ($path, $text) = @_;
    if (-f $path) {
        open my $fh, '<:raw', $path or die $!;
        local $/;
        my $existing = <$fh>;
        close $fh or die $!;
        die "refuse to change existing ingress fixture: $path\n" unless $existing eq $text;
        return;
    }
    die "refuse to extend sealed ingress fixtures: $path\n"
        if -f 'docs/audits/record-output-generated-ingress-20261002/manifest.json';
    write_file($path, $text);
}
