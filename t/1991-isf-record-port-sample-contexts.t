use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::ISFRecordPortContexts qw(validate_actor_record_contexts);
use FSM::Support::ISFRecordPortSamples qw(actor_has_record_input record_transaction_samples);

my $parser = FSM::Adapter::ISF->new;
my $json = JSON::PP->new->canonical;
my $source = <<'ISF';
(actor contexts
  (types (type frame (record (count (four_state (signed (bits 3)))) (ready bit))))
  (interface (input start) (output seen (width 3)) (output done))
  (storage (var packet (type frame)) (var held (type frame)))
  (transaction main (on start) (set seen packet.count) (complete done)))
ISF
my $ordinary = $parser->parse_source($source, 'sample-contexts.isf');
my $prepared = dclone($ordinary);
my $packet = shift @{$prepared->{storage}};
push @{$prepared->{interface}{inputs}}, {map {$_=>$packet->{$_}} qw(name width type type_spec)};

sub sample { ['sample',$_[0],'as',$_[1]] }
sub actor_with {
    my ($clauses) = @_;
    my $a = dclone($prepared);
    $a->{transactions}[0]{clauses} = $clauses;
    return $a;
}
sub accepts {
    my ($a, $label) = @_;
    my $before = $json->encode($a);
    my $ok = eval {validate_actor_record_contexts(actor=>$a); 1};
    ok($ok, $label) or diag($@);
    is($json->encode($a), $before, "$label preserves the complete actor");
}
sub refuses {
    my ($a, $pattern, $label) = @_;
    my $before = $json->encode($a);
    my $ok = eval {validate_actor_record_contexts(actor=>$a); 1};
    my ($line) = split /\n/, $@;
    ok(!$ok, "$label refuses");
    like($line // '', $pattern, "$label has the correct first-line cause");
    is($json->encode($a), $before, "$label preserves the complete actor");
}

subtest 'selector refuses malformed facts without autovivifying callers' => sub {
    my $empty = {};
    is(actor_has_record_input(actor=>$empty), 0, 'absent interface has no known record input');
    is_deeply($empty, {}, 'selection never invents an interface');
    for my $entry (undef, 'not_a_map', []) {
        my $a = {interface=>{inputs=>[$entry]}};
        my $before = $json->encode($a);
        my $ok = eval {actor_has_record_input(actor=>$a); 1};
        ok(!$ok, 'malformed declared entry refuses');
        like((split /\n/,$@)[0] // '', qr/record-input selection requires declared input maps/, 'failure names the entry shape');
        is($json->encode($a), $before, 'first selection preserves complete malformed caller JSON');
    }
    my $a = {interface=>{inputs=>[dclone($prepared->{interface}{inputs}[1]), undef]}};
    my $before = $json->encode($a);
    my $ok = eval {actor_has_record_input(actor=>$a); 1};
    ok(!$ok, 'a valid record prefix cannot hide a malformed remaining declaration');
    like((split /\n/,$@)[0], qr/record-input selection requires declared input maps/, 'complete input inventory is validated');
    is($json->encode($a), $before, 'failed suffix validation leaves the complete caller unchanged');
};

subtest 'selected explicit entry body and control samples feed real scalar bindings' => sub {
    ok(!actor_has_record_input(actor=>$ordinary), 'ordinary scalar/storage source is outside the input consumer');
    ok(actor_has_record_input(actor=>$prepared), 'actual supplied record-input role selects the consumer');
    for my $clauses (
        [['on','start',sample('packet.count','q')],['set','seen','q']],
        [sample('packet.count','q'),['update','seen','q[2:1]']],
        [['when','start',sample('packet.count','q'),['set','seen','q']]],
        [['switch','start',[1,sample('packet.count','q'),['set','seen','q']]]],
        [['while','start',sample('packet.ready','q'),['set','done','q']]],
        [['until','start',sample('packet.ready','q'),['set','done','q']]],
        [['repeat',2,sample('packet.count','q'),['drive','inline',['seen','q']]]],
        [sample('packet.count','q'),sample('q','again'),['set','seen','again']],
    ) {
        accepts(actor_with($clauses), 'selected explicit scalar sample context');
    }
};

subtest 'sample aliases cannot erase declaration roles or invalid scalar shapes' => sub {
    refuses(actor_with([sample('packet.count','q'),['set','seen','q.member']]),
        qr/member_on_non_record/, 'sample alias is a scalar rather than an inferred record');
    refuses(actor_with([sample('packet.count','q'),['set','seen','q[3]']]),
        qr/scalar_index_out_of_range/, 'sample alias has exact leaf width');
    refuses(actor_with([sample('packet','q')]), qr/whole record/, 'whole record snapshot');
    refuses(actor_with([sample('packet.count','packet')]), qr/cannot write declared input/, 'input target');
    refuses(actor_with([sample('packet.count','held')]), qr/collides with a declaration/, 'storage target');
    refuses(actor_with([sample('packet.missing','q')]), qr/unknown_member/, 'missing input member');
    refuses(actor_with([sample('packet.count','q'),sample('packet.ready','q')]),
        qr/requires the same resolved scalar type/, 'inconsistent repeated captures');
    refuses(actor_with([sample('q','earlier'),sample('packet.count','q')]),
        qr/uses record-derived alias 'q' before its declaration/, 'unresolved forward sample chain');
};

subtest 'nearest formals locals and explicit unknown aliases mask input layouts' => sub {
    my $a = actor_with([sample('packet[1:0]','q'),['set','seen','q']]);
    $a->{transactions}[0]{ports} = {inputs=>[],outputs=>[{name=>'packet',width=>2}]};
    accepts($a, 'scalar formal has its own sampled width and writable role');
    $a->{transactions}[0]{clauses} = [sample('packet.count','q')];
    refuses($a, qr/member_on_non_record/, 'scalar formal cannot borrow input layout');
    $a->{transactions}[0]{ports}{outputs}[0] = {name=>'packet',width=>1,type=>'unresolved'};
    accepts($a, 'unknown formal remains delegated');
    $a = actor_with([['local','local_word',['width',2]],sample('local_word','q'),['set','seen','q[1:0]']]);
    accepts($a, 'explicit local AST has its own sampled width');
    $a = actor_with([sample('not_declared','held'),sample('held.member','q')]);
    accepts($a, 'unknown sampled alias masks outer storage rather than borrowing its record type');
};

subtest 'port consumer delegates established packed storage and namespace samples' => sub {
    my $a = actor_with([sample('held','packed_q'),['set','held','packed_q']]);
    my $p = record_transaction_samples(actor=>$a,transaction=>$a->{transactions}[0],port_only=>1);
    is($p->{bindings}{packed_q}{type_spec}, undef, 'packed storage width/inference remains with its existing owner');
    is_deeply($p->{record_aliases}, {}, 'storage sampling gains no new record-input type carrier');
    accepts($a, 'existing storage-only packed sample and transfer context remains delegated');
    $a->{enum_symbols}{local} = {mode=>{BUSY=>1}};
    $a->{transactions}[0]{clauses} = [sample('mode.BUSY','enum_q')];
    accepts($a, 'enum sample remains with namespace/static-value validation');
    my $before = $json->encode($a);
    my $ok = eval {record_transaction_samples(actor=>$a,transaction=>$a->{transactions}[0],port_only=>[]); 1};
    ok(!$ok, 'malformed selection refuses');
    like((split /\n/,$@)[0], qr/port-only selection must be binary/, 'closed selection diagnostic');
    is($json->encode($a), $before, 'failed selection is detached');
};

subtest 'complete ordinary products and source admission remain unchanged' => sub {
    my $a = $parser->parse_source($source, 'sample-contexts.isf');
    my $before = $json->encode($a);
    my $lowered = $json->encode(FSM::Scheduler::ISF->new->lower($a));
    accepts($a, 'currently admitted scalar/storage actor');
    is($json->encode($a), $before, 'first context consumer preserves current source facts');
    is($json->encode(FSM::Scheduler::ISF->new->lower($a)), $lowered, 'complete scheduled object and actual emitted bytes unchanged');
    my $ok = eval {$parser->parse_source('(actor refused (types (type frame (record (data bit)))) (interface (input packet (type frame))) (transaction main (sample packet.data as q)))', 'refused.isf'); 1};
    ok(!$ok, 'authored record-input sample remains refused');
    like((split /\n/,$@)[0], qr/interface port 'packet' references aggregate type/, 'source boundary remains exact');
};

done_testing;
