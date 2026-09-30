use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::ISFRecordPortSamples qw(record_transaction_samples record_sample_type_products);

my $parser = FSM::Adapter::ISF->new;
my $json = JSON::PP->new->canonical;
my $source = <<'ISF';
(actor samples
  (types
    (type leaf (record (count (four_state (signed (bits 3)))) (ready (two_state bit))))
    (type frame (record (tag (bits 2)) (nested leaf) (lanes (list bit (bits 2)))))
    (type alias frame))
  (enums (mode (BUSY 1)))
  (interface (input start) (input mode) (output seen (width 3)) (output done))
  (storage (var packet (type frame) (reset 0)) (var held (type alias)))
  (transaction worker (ports (output packet (width 2)))
    (local count (width 3)) (set packet 1))
  (transaction main (on start) (set seen packet.nested.count) (complete done)))
ISF
my $actor = $parser->parse_source($source, 'sample-facts.isf');

sub sample_plan {
    my ($a, $clauses, $tx) = @_;
    $tx = dclone($tx || $a->{transactions}[1]);
    $tx->{clauses} = $clauses;
    return record_transaction_samples(actor => $a, transaction => $tx);
}
sub sample { ['sample', $_[0], 'as', $_[1]] }
sub refuses {
    my ($run, $pattern, $name) = @_;
    my $ok = eval {$run->(); 1};
    my ($line) = split /\n/, $@;
    ok(!$ok, "$name refuses");
    like($line // '', $pattern, "$name names the first-line cause");
}
sub render {
    my ($value) = @_;
    return ref($value) eq 'ARRAY' ? '(' . join(' ', map {render($_)} @$value) . ')' : $value;
}

subtest 'independent packed-layout and scalar-property witnesses' => sub {
    my $p = sample_plan($actor, [
        ['on', 'start', sample('packet.nested.count', 'count_q')],
        sample('packet.nested.ready', 'ready_q'),
        ['when', 'mode', sample('packet.lanes[1][1:0]', 'lane_q')],
        ['switch', 'mode', [1, sample('packet.tag', 'tag_q')]],
        ['repeat', 2, sample('count_q', 'again_q')],
    ]);
    is_deeply([map {[$_->{source}, $_->{alias}, $_->{record_derived}]} @{$p->{samples}}],
        [['packet.nested.count','count_q',1], ['packet.nested.ready','ready_q',1],
         ['packet.lanes[1][1:0]','lane_q',1], ['packet.tag','tag_q',1], ['count_q','again_q',1]],
        'entry/body/branches preserve authored order and chained record-leaf provenance');
    is_deeply([map {[@{$_->{reference}}{qw(width low high)}]} @{$p->{samples}}[0..3]],
        [[3,4,6], [1,3,3], [2,0,1], [2,7,8]], 'independent nine-bit packed layout');
    is_deeply($p->{bindings}{count_q}, {role=>'local', type_spec=>{kind=>'bits',width=>3,signed=>1,state_model=>'four_state'}},
        'signed four-state scalar facts survive sampling');
    is_deeply($p->{bindings}{ready_q}, {role=>'local', type_spec=>{kind=>'bit',width=>1,signed=>0,state_model=>'two_state'}},
        'bit kind and explicit two-state property survive');
    is_deeply($p->{bindings}{again_q}, $p->{bindings}{count_q}, 'explicit sampled alias has the same detached scalar type');
    ok(!exists($p->{bindings}{lane_q}{type_spec}{state_model}), 'unspecified state model stays unspecified');
};

subtest 'actual lexical masks and namespaces do not lend a record layout' => sub {
    my $p = sample_plan($actor, [['local','count',['width',3]], sample('packet[1:0]', 'p_q'), sample('count', 'c_q')], $actor->{transactions}[0]);
    is_deeply([map {$_->{reference}{width}} @{$p->{samples}}], [2,3], 'formal and explicit local widths are nearest');
    is_deeply($p->{record_aliases}, {}, 'scalar shadows do not invent record provenance');
    refuses(sub {sample_plan($actor, [sample('packet.nested.count','q')], $actor->{transactions}[0])},
        qr/member_on_non_record/, 'scalar formal member');
    my $unknown = dclone($actor->{transactions}[0]);
    $unknown->{ports}{outputs}[0] = {name=>'packet',width=>1,type=>'unresolved'};
    $p = sample_plan($actor, [sample('packet.nested.count','q')], $unknown);
    is($p->{bindings}{q}{type_spec}, undef, 'unknown formal masks outer record without placeholder inference');
    $p = sample_plan($actor, [sample('mode.BUSY','enum_q'), sample('not_declared','packet'), sample('packet.nested.count','q')]);
    is($p->{bindings}{enum_q}{type_spec}, undef, 'enum token retains existing namespace/static validation owner');
    is($p->{bindings}{q}{type_spec}, undef, 'explicit unknown sample alias masks old record facts');
};

subtest 'whole aggregates paths roles and inconsistent aliases fail precisely' => sub {
    for my $case (
        ['packet', qr/whole record/], ['packet.nested', qr/requires a scalar leaf/],
        ['packet.lanes', qr/requires a scalar leaf/], ['packet.missing', qr/unknown_member/],
        ['packet.lanes[2]', qr/index_out_of_range/],
    ) {
        refuses(sub {sample_plan($actor, [sample($case->[0],'q')])}, $case->[1], $case->[0]);
    }
    for my $alias (qw(packet held seen count)) {
        my $tx = dclone($actor->{transactions}[1]);
        unshift @{$tx->{clauses}}, ['local','count',['width',3]];
        refuses(sub {sample_plan($actor, [@{$tx->{clauses}},sample('packet.nested.count',$alias)],$tx)},
            qr/collides with a declaration/, "private alias $alias");
    }
    refuses(sub {sample_plan($actor, [sample('packet.tag','start')])}, qr/cannot write declared input/, 'input alias');
    my $prepared = dclone($actor);
    my $packet = shift @{$prepared->{storage}};
    push @{$prepared->{interface}{inputs}}, {map {$_=>$packet->{$_}} qw(name width type type_spec)};
    my $read = sample_plan($prepared, [sample('packet.nested.count','q')]);
    is($read->{samples}[0]{reference}{role}, 'input', 'supplied record input retains readable declared role');
    refuses(sub {sample_plan($prepared, [sample('packet.nested.count','packet')])},
        qr/cannot write declared input/, 'supplied record input target');
    refuses(sub {sample_plan($actor, [sample('packet.tag','q'),sample('packet.nested.count','q')])},
        qr/requires the same resolved scalar type/, 'different width/type repeated sample');
    refuses(sub {sample_plan($actor, [sample('packet.nested.count','q'),sample('not_declared','q')])},
        qr/requires the same resolved scalar type/, 'unknown repeated sample');
    my $collision = dclone($actor);
    push @{$collision->{interface}{inputs}}, {name=>'scalar',width=>2};
    refuses(sub {sample_plan($collision, [sample('scalar','held'),sample('packet.tag','held')])},
        qr/collides with a declaration/, 'prior scalar sample cannot erase an authored storage collision');
    my $p = sample_plan($actor, [sample('packet.tag','q'),sample('held.tag','q')]);
    is(scalar(@{$p->{samples}}), 2, 'same resolved scalar type permits repeated explicit captures');
    refuses(sub {sample_plan($actor, [['sample','packet.tag','as',['q']]])}, qr/requires '\(sample scalar as identifier\)'/, 'malformed sample');
};

subtest 'private core scalar type products are deterministic and collision-safe' => sub {
    my $p = sample_plan($actor, [sample('packet.nested.count','count_q'),sample('packet.nested.ready','ready_q'),sample('packet.tag','tag_q')]);
    my %args = (bindings=>$p->{bindings}, record_aliases=>$p->{record_aliases}, reserved_names=>['_isf_sample_count_q','_isf_sample_count_q_1']);
    my $types = record_sample_type_products(%args);
    is_deeply($types, {
        type_declarations=>[
            ['type','_isf_sample_count_q_2',['four_state',['signed',['bits',3]]]],
            ['type','_isf_sample_ready_q',['two_state','bit']],
            ['type','_isf_sample_tag_q',['bits',2]],
        ],
        signal_type_refs=>{count_q=>'_isf_sample_count_q_2',ready_q=>'_isf_sample_ready_q',tag_q=>'_isf_sample_tag_q'},
        signal_widths=>{count_q=>3,ready_q=>1,tag_q=>2},
    }, 'independently authored complete carrier product has no reset/default leakage');
    is_deeply(record_sample_type_products(%args), $types, 'same reserved names produce the same declaration identity');
    my $declarations = join(' ', map {render($_)} @{$types->{type_declarations}});
    my $storage = join(' ', map {'(var '.$_.' (type '.$types->{signal_type_refs}{$_}.'))'} sort keys %{$types->{signal_type_refs}});
    my $a = $parser->parse_source('(actor type_contract (types '.$declarations.') (storage '.$storage.') (transaction main (wait 1)))', 'private-type-contract.isf');
    for my $entry (@{$a->{storage}}) {
        is_deeply($entry->{type_spec}, $p->{bindings}{$entry->{name}}{type_spec}, 'actual public type resolver reconstructs the exact selected scalar facts');
    }
    refuses(sub {record_sample_type_products(%args, extra=>1)}, qr/unknown sample argument/, 'unknown type-product argument');
    refuses(sub {record_sample_type_products(%args, record_aliases=>{count_q=>[]})}, qr/requires a local sample binding/, 'malformed record-alias fact');
};

subtest 'imported aliases and first-read caller facts are detached' => sub {
    my $work = tempdir(CLEANUP=>1);
    open my $f, '>', "$work/shared.fsm" or die $!;
    print {$f} '(?pkg:shared (+types (type frame (record (data (four_state (signed (bits 3))))))))';
    close $f or die $!;
    my $a = $parser->parse_source('(actor imported (imports (package shared)) (storage (var packet (type shared.frame))) (transaction main (wait 1)))', "$work/imported.isf");
    my $p = sample_plan($a, [sample('packet.data','q')], $a->{transactions}[0]);
    is_deeply($p->{bindings}{q}{type_spec}, {kind=>'bits',width=>3,signed=>1,state_model=>'four_state'}, 'actual imported leaf has exact scalar properties');
    my $fresh = dclone($actor);
    my $tx = dclone($fresh->{transactions}[1]);
    $tx->{clauses} = [sample('packet.nested.count','q')];
    my $before = $json->encode([$fresh,$tx]);
    $p = record_transaction_samples(actor=>$fresh,transaction=>$tx);
    is($json->encode([$fresh,$tx]), $before, 'first plan preserves complete copied caller JSON kinds');
    $p->{record_aliases}{q} = '1';
    $p->{bindings}{q}{type_spec}{width} = '3';
    $before = $json->encode($p);
    my $products = record_sample_type_products(bindings=>$p->{bindings},record_aliases=>$p->{record_aliases},reserved_names=>[]);
    is($json->encode($p), $before, 'first type projection preserves string-valued width and provenance facts');
    $products->{type_declarations}[0][2][1][1][1] = 999;
    is($json->encode($p), $before, 'mutating generated declaration does not mutate facts');
    $p->{samples}[0]{reference}{type_spec}{width} = 999;
    is($p->{bindings}{q}{type_spec}{width}, '3', 'sample reference and binding are detached sibling maps');
};

subtest 'preparation does not mutate complete currently admitted products' => sub {
    my $a = $parser->parse_source($source, 'sample-facts.isf');
    my $before = $json->encode($a);
    my $lowered = $json->encode(FSM::Scheduler::ISF->new->lower($a));
    record_transaction_samples(actor=>$a,transaction=>$a->{transactions}[1]);
    is($json->encode($a), $before, 'complete parsed object unchanged');
    is($json->encode(FSM::Scheduler::ISF->new->lower($a)), $lowered, 'complete scheduled object and emitted bytes unchanged');
    refuses(sub {$parser->parse_source('(actor refused (types (type frame (record (data bit)))) (interface (input packet (type frame))))', 'refused.isf')},
        qr/interface port 'packet' references aggregate type/, 'authored record input remains refused');
};

done_testing;
