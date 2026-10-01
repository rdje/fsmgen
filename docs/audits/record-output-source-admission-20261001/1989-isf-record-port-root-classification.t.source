use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Support::ISFRecordPortScopes qw(record_context_scope record_reference_root_kind);
use FSM::Support::ISFRecordPortValues qw(record_value_reference);
use FSM::Support::ISFRecordPortContexts qw(validate_actor_record_contexts);

my $parser = FSM::Adapter::ISF->new;
my $json = JSON::PP->new->canonical;
my $actor = $parser->parse_source(<<'ISF', 'root-controls.isf');
(actor roots
  (params (W 8)) (constants (K 1))
  (types (type frame (record (flag bit) (payload (bits 7)))) (type alias frame))
  (enums (mode (BUSY 1)) (packet (payload 1)))
  (interface (input start) (input mode) (output seen (width W)) (output done))
  (storage (var packet (type frame)) (var held (type alias)))
  (drive (publish packet) (seen packet))
  (transaction worker (ports (output packet (width 3)))
    (local count (width 2)) (set packet 1))
  (transaction main (on start) (set seen packet.payload) (complete done)))
ISF

sub classify {
    my ($context, $token) = @_;
    return record_reference_root_kind(context => $context, token => $token);
}
sub refuses {
    my ($run, $pattern, $name) = @_;
    my $ok = eval {$run->(); 1};
    my ($line) = split /\n/, $@;
    ok(!$ok, "$name refuses");
    like($line // '', $pattern, "$name names its first-line cause");
}

subtest 'actual declarations produce one coherent consumer projection' => sub {
    my $context = record_context_scope(actor => $actor);
    is_deeply([sort keys %$context], [qw(aggregate_roots enum_exclusion_roots namespaces roots rule_declared_roots scalar_parameter_roots)],
        'complete projection has only the selected consumer maps');
    is_deeply($context->{scalar_parameter_roots}, {}, 'outer actor statics do not invent lexical drive masks');
    is_deeply([sort keys %{$context->{roots}}], [qw(done held mode packet seen start)],
        'values are declarations rather than inferred assignment/constant names');
    is_deeply([sort keys %{$context->{aggregate_roots}}], [qw(held packet)], 'actor aggregates retain resolved identities');
    is_deeply($context->{enum_exclusion_roots}, {held => 1, packet => 1},
        'aggregate roots prevent namespace interpretation');
    is_deeply($context->{namespaces}, {mode => 1, packet => 1}, 'actual local enum families remain namespaces');
    is_deeply([sort keys %{$context->{rule_declared_roots}}], [qw(K W clk done held mode packet rst_n seen start)],
        'independent rule-declaration witness includes actor statics and system pins');
    is(classify($context, 'mode.BUSY'), 'namespace', 'scalar pin can share enum family name');
    is(classify($context, 'packet.payload'), 'declaration', 'declared record wins over same-named enum family');
    is(classify($context, 'packet.missing'), 'declaration', 'unknown member remains with declared path validator');
    is(classify($context, 'mode.MISSING'), 'namespace', 'unknown enum member remains with enum validator');
    is(classify($context, 'seen[3:0]'), 'declaration', 'scalar bit/slice root retains declaration');
    is(classify($context, 'not_declared.member'), undef, 'unknown namespace does not invent a declaration');
    is(classify($context, 17), undef, 'literal is not a declaration reference');
};

subtest 'nearest formal and local scopes suppress borrowed aggregate namespaces' => sub {
    my $context = record_context_scope(actor => $actor, transaction => $actor->{transactions}[0]);
    is_deeply([sort keys %{$context->{aggregate_roots}}], ['held'], 'scalar formal removes outer aggregate from traversal roots');
    is_deeply($context->{enum_exclusion_roots}, {held => 1, packet => 1},
        'shadowed outer record remains excluded from enum fallback');
    is(classify($context, 'packet.payload'), 'declaration', 'formal path is not borrowed enum token');
    refuses(sub {record_value_reference(scope => $context->{roots}, token => 'packet.payload',
        access => 'read', context => 'formal path')}, qr/member_on_non_record/, 'scalar formal member access');
    is_deeply([@{record_value_reference(scope => $context->{roots}, token => 'packet[2:1]',
        access => 'read', context => 'formal slice')}{qw(width low high)}], [2, 1, 2],
        'formal slice uses its independent local width');
    ok(exists($context->{roots}{count}) && !exists($context->{rule_declared_roots}{count}),
        'transaction local cannot become an actor rule read operand');
    my $unknown = dclone($actor->{transactions}[0]);
    $unknown->{ports}{outputs}[0] = {name => 'packet', width => 1, type => 'unresolved'};
    $context = record_context_scope(actor => $actor, transaction => $unknown);
    is($context->{roots}{packet}{type_spec}, undef, 'unresolved type stays unknown');
    is(classify($context, 'packet.payload'), 'declaration', 'unresolved formal still masks namespace and outer layout');
    is(record_value_reference(scope => $context->{roots}, token => 'packet.payload', access => 'read',
        context => 'unknown formal'), undef, 'unknown fact is delegated without invented type');
};

subtest 'drive and supplied record pin scopes retain real declaration roles' => sub {
    my $context = record_context_scope(actor => $actor, drive => $actor->{drives}{publish});
    is_deeply($context->{scalar_parameter_roots}, {packet => 1}, 'explicit drive formal supplies its exact scalar mask');
    is_deeply($context->{roots}{packet}, {role => 'local', type_spec => undef}, 'parameter masks outer record');
    is(classify($context, 'packet.payload'), 'declaration', 'untyped parameter cannot borrow enum member');
    my $prepared = dclone($actor);
    my $packet = shift @{$prepared->{storage}};
    push @{$prepared->{interface}{inputs}}, {map {$_ => $packet->{$_}} qw(name width type type_spec)};
    $context = record_context_scope(actor => $prepared);
    is($context->{roots}{packet}{role}, 'input', 'supplied record declaration keeps input role');
    is_deeply([sort keys %{$context->{aggregate_roots}}], [qw(held packet)], 'record pins and storage share resolved traversal facts');
    refuses(sub {record_value_reference(scope => $context->{roots}, token => 'packet.payload',
        access => 'write', context => 'input field')}, qr/cannot write declared input/, 'declared input field');
};

subtest 'package namespace and named-domain rules retain existing owners' => sub {
    my $supplied = dclone($actor);
    $supplied->{enum_symbols}{packages} = {shared => {mode => {BUSY => 1}}};
    $supplied->{constant_symbols}{packages} = {limits => {MAX => {kind => 'scalar', payload => 8}}};
    push @{$supplied->{interface}{inputs}}, {name => 'shared', width => 1}, {name => 'limits', width => 1};
    my $context = record_context_scope(actor => $supplied);
    is(classify($context, 'shared.mode.BUSY'), 'namespace', 'package enum is not a scalar-pin member');
    is(classify($context, 'limits.MAX'), 'namespace', 'package constant remains with existing static/value validator');
    my $work = tempdir(CLEANUP => 1);
    open my $file, '>', "$work/shared.fsm" or die $!;
    print {$file} '(?pkg:shared (+types (type frame (record (flag bit) (payload (bits 7)))))'
        . ' (+enums (mode (BUSY 1))) (+constants (MAX 8)))';
    close $file or die $!;
    my $imported = $parser->parse_source('(actor imported (imports (package shared))'
        . ' (interface (input shared) (output done)) (storage (var frame (type shared.frame)))'
        . ' (transaction main (complete done)))', "$work/imported.isf");
    $context = record_context_scope(actor => $imported);
    is(classify($context, 'shared.mode.BUSY'), 'namespace', 'actual imported enum remains in package namespace');
    is(classify($context, 'shared.MAX'), 'namespace', 'actual imported constant retains its package owner');
    is_deeply($context->{aggregate_roots}{frame}, record_context_scope(actor => $actor)->{aggregate_roots}{packet},
        'actual imported aggregate retains equivalent resolved traversal facts');
    my $named = $parser->parse_source('(actor named (clock-domains'
        . ' (domain core (clock core_clk) (reset (core_rst async active_low)) :default)'
        . ' (domain aux (clock aux_clk) (reset (aux_rst sync active_high))))'
        . ' (interface (input start) (output done)) (transaction main (on start) (complete done)))',
        'named-rule-roots.isf');
    $context = record_context_scope(actor => $named);
    is_deeply([sort keys %{$context->{rule_declared_roots}}], [qw(aux_clk aux_rst core_clk core_rst done start)],
        'independent named-domain clock/reset declaration witness');
    is_deeply([sort keys %{$context->{roots}}], [qw(done start)], 'system names are not invented value/type roots');
};

subtest 'fresh copied facts stay detached across every consumer map' => sub {
    for my $kind (qw(actor transaction drive)) {
        my $fresh = dclone($actor);
        my %selection;
        $selection{transaction} = $fresh->{transactions}[0] if $kind eq 'transaction';
        $selection{drive} = $fresh->{drives}{publish} if $kind eq 'drive';
        my $before = $json->encode($fresh);
        my $context = record_context_scope(actor => $fresh, %selection);
        is($json->encode($fresh), $before, 'first complete projection preserves caller JSON kinds');
        $context->{aggregate_roots}{held}{members}{payload}{width} = 999;
        $context->{rule_declared_roots}{invented} = 1;
        $context->{namespaces}{invented} = 1;
        is($json->encode($fresh), $before, 'mutating any projection leaves source facts unchanged');
        is($context->{roots}{held}{type_spec}{members}{payload}{width}, 7,
            'traversal map is detached from value map within projection');
    }
};

subtest 'closed context selection and current source admission remain unchanged' => sub {
    refuses(sub {record_context_scope(actor => $actor, transaction => $actor->{transactions}[0],
        drive => $actor->{drives}{publish})}, qr/cannot select both transaction and drive/, 'ambiguous lexical selection');
    refuses(sub {record_context_scope(actor => $actor, extra => 1)}, qr/unknown scope argument/, 'unknown context argument');
    refuses(sub {record_reference_root_kind(context => {}, token => 'packet')},
        qr/requires declaration context/, 'missing classification maps');
    my $before = $json->encode($actor);
    ok(validate_actor_record_contexts(actor => $actor), 'existing contextual consumer uses common projection');
    is($json->encode($actor), $before, 'complete parsed source unchanged');
    refuses(sub {$parser->parse_source('(actor refused (types (type frame (record (data bit))))'
        . ' (interface (output packet (type frame))) (transaction main (set packet.data 1)))', 'refused.isf')},
        qr/record output field writes are not yet admitted/, 'authored record output field writer still refused');
};

done_testing;
