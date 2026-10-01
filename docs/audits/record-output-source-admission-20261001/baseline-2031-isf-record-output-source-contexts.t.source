use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use FSM::Adapter::ISF;
use FSM::Adapter::ISF::Parser;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Support::ISFInterfacePortMetadata qw(capture_interface_port_metadata);
use FSM::Support::ISFRecordPortSamples qw(actor_has_record_input record_transaction_samples);
use FSM::Support::ISFRecordPortContexts qw(validate_actor_record_contexts);

my $json = JSON::PP->new->canonical;
my $definition = '(record (tag (bits 2)) (payload (signed (four_state (bits 3)))))';

subtest 'shared module source gate cannot bypass whole-copy identity or field qualification' => sub {
    for my $case (
        ['literal whole target',[['on','start'],['set','packet',0]],qr/whole record port copy requires declared record roots/],
        ['unqualified field target',[['on','start'],['set','packet.payload',1]],qr/record output field writes are not yet admitted/],
    ) {
        my ($name,$body,$reason) = @$case;
        my $actor = resolved_output_prototype($body);
        my $ok = eval {build($actor);1};
        my ($first) = split /\n/,$@;
        ok(!$ok,"$name refuses before module publication");
        like($first // '',$reason,"$name identifies the mandatory source contract");
    }
};

subtest 'complete record-port selection covers output-only mixed and malformed facts without mutation' => sub {
    my $actor = resolved_output_prototype([]);
    ok(!actor_has_record_input(actor=>$actor),'legacy input selection does not invent an input');
    ok(selected($actor),'output-only resolved declaration selects record source gates');
    my $mixed = dclone($actor);
    push @{$mixed->{interface}{inputs}},{name=>'incoming',width=>5,type=>'frame',type_spec=>dclone($actor->{storage}[0]{type_spec})};
    ok(actor_has_record_input(actor=>$mixed),'actual added resolved input retains legacy selection');
    ok(selected($mixed),'mixed actor selects the complete port gate');
    for my $bad (undef,'not a map',[]) {
        my $malformed = dclone($mixed);
        push @{$malformed->{interface}{outputs}},$bad;
        my $before = $json->encode($malformed);
        my $ok = eval {selected($malformed);1};
        ok(!$ok,'known record prefix cannot conceal a malformed output suffix');
        like((split /\n/,$@)[0] // '',qr/declared output maps/,'output shape is the primary refusal');
        is($json->encode($malformed),$before,'first selection preserves complete malformed caller JSON');
    }
    my $empty = {};
    is(selected($empty),0,'absent declarations provide no known record port');
    is_deeply($empty,{},'selection does not autovivify an interface');
};

subtest 'output scalar samples retain exact private type and mandatory alias safety' => sub {
    my $actor = resolved_output_prototype([['on','start'],['sample','packet.payload','as','captured'],['set','seen','captured']]);
    my $ir = build($actor);
    my $type = $ir->{signal_type_refs}{captured};
    ok(defined($type),'actual output-derived sample acquires its private type reference');
    my ($decl) = grep {$_->[1] eq $type} @{$ir->{type_declarations}};
    is_deeply($decl,['type',$type,['four_state',['signed',['bits',3]]]],
        'literal signed three-bit four-state declaration is preserved');
    is($ir->{counters}{captured},3,'actual sample alias declares its exact scalar width');
    for my $case (
        [[['sample','packet.payload','as','q'],['set','seen','q.member']],qr/member_on_non_record/],
        [[['sample','packet.payload','as','q'],['set','seen','q[3]']],qr/scalar_index_out_of_range/],
        [[['sample','packet.payload','as','packet']],qr/collides with a declaration/],
        [[['sample','packet','as','q']],qr/whole record/],
    ) {
        my $bad = resolved_output_prototype($case->[0]);
        eval {build($bad)};
        like((split /\n/,$@)[0] // '',$case->[1],'output-only samples cannot erase scalar or declaration facts');
    }
};

subtest 'whole-output policy preserves prepared facts scalar slices and nearest shadows' => sub {
    my $actor = resolved_output_prototype([['set','packet.payload',1]]);
    ok(validate_actor_record_contexts(actor=>$actor),'prepared toolkit retains its output-field facts');
    eval {validate_actor_record_contexts(actor=>$actor,whole_output_writes_only=>1)};
    like((split /\n/,$@)[0] // '',qr/record output field writes are not yet admitted/,
        'source policy confines current whole-output delivery');
    my $sliced = resolved_output_prototype([['set','seen[1:0]',1]]);
    ok(validate_actor_record_contexts(actor=>$sliced,whole_output_writes_only=>1),
        'scalar output slices retain their existing expression owner');
    my $shadow = resolved_output_prototype([['set','seen','packet.payload']]);
    $shadow->{transactions}[0]{ports}={inputs=>[],outputs=>[{name=>'packet',width=>2}]};
    eval {validate_actor_record_contexts(actor=>$shadow,whole_output_writes_only=>1)};
    like((split /\n/,$@)[0] // '',qr/member_on_non_record/,'scalar formal cannot borrow outer output layout');
    my $drive = resolved_output_prototype([]);
    $drive->{drives}={publish=>{params=>['packet'],body=>[['seen','packet.payload']]}};
    eval {validate_actor_record_contexts(actor=>$drive,whole_output_writes_only=>1)};
    like((split /\n/,$@)[0] // '',qr/member_on_non_record/,'scalar drive parameter cannot borrow outer output layout');
    for my $bad (undef,[],2) {
        eval {validate_actor_record_contexts(actor=>$actor,whole_output_writes_only=>$bad)};
        like((split /\n/,$@)[0] // '',qr/source-write policy must be binary/,'malformed source policy refuses');
    }
    eval {record_transaction_samples(actor=>$actor,transaction=>$actor->{transactions}[0],port_only=>2)};
    like((split /\n/,$@)[0] // '',qr/port-only selection must be binary/,
        'existing malformed scalar sample selection retains its primary policy reason');
};

subtest 'output record roots participate in real clock-domain access validation' => sub {
    my $actor = resolved_output_prototype([['on','start'],['set','seen','packet.payload']],'core');
    eval {build($actor)};
    is((split /\n/,$@)[0] // '',"ISF clock-domain violation: transaction 'main' set clause read signal 'packet.payload' owned by domain 'bus' from domain 'core' without a crossing primitive",
        'actual bus-owned output leaf cannot bypass core access checks');
    my $same = resolved_output_prototype([['on','other'],['set','packet','held']],'bus');
    ok(build($same),'same-domain whole output copy remains a valid resolved prototype');
};

subtest 'caller first-touch and authored output declaration boundary remain exact' => sub {
    my $actor = resolved_output_prototype([['on','start'],['set','packet','held']]);
    stringify_widths($actor);
    my $before = $json->encode($actor);
    ok(validate_actor_record_contexts(actor=>$actor,whole_output_writes_only=>1),
        'string-width output-only source facts validate');
    is($json->encode($actor),$before,'first source validation preserves complete caller JSON kinds');
    my $source='(actor closed (types (type frame '.$definition.')) (interface (output packet (type frame))))';
    eval {FSM::Adapter::ISF->new->parse_source($source,'closed.isf')};
    like((split /\n/,$@)[0] // '',qr/interface port 'packet' references aggregate type 'frame'/,
        'preparation does not open authored output declarations');
};
done_testing;

sub resolved_output_prototype {
    my ($clauses,$domain) = @_;
    my $domains = defined $domain;
    my $clock = $domains ? '(clock-domains (domain core (clock clk) :default) (domain bus (clock bus_clk)))' : '(clock clk)';
    my $core = $domains ? '(domain core)' : '';
    my $bus = $domains ? '(domain bus)' : '';
    my $source='(actor output_contexts '.$clock.' (types (type frame '.$definition.'))'
        ." (interface (input start $core) (input other $bus) (output seen (width 3) $core) (output placeholder (width 5) $bus) (output done $core))"
        ." (storage (var packet (type frame) $bus) (var held (type frame) $bus))"
        .' (transaction main))';
    my $actor=FSM::Adapter::ISF->new->parse_source($source,'output_contexts.isf');
    # The actual source already validates packed storage paths. Project its
    # resolved declaration into the private output role; do not parse record
    # member syntax as if the original scalar placeholder had that layout.
    my $declaration=shift @{$actor->{storage}};
    my ($port)=grep {$_->{name} eq 'placeholder'} @{$actor->{interface}{outputs}};
    %$port=map {$_=>dclone_value($declaration->{$_})}
        grep {exists $declaration->{$_}} qw(name width type type_spec domain);
    # Prototype clauses are explicit caller facts after role projection. They
    # do not widen authored storage-sample or output grammar boundaries.
    $actor->{transactions}[0]{clauses}=dclone($clauses);
    $actor->{transactions}[0]{domain}=$domain if $domains;
    $actor->{interface_port_metadata}=capture_interface_port_metadata($actor->{interface},($actor->{clock_domains} || {})->{default});
    return $actor;
}
sub dclone_value {ref($_[0]) ? dclone($_[0]) : $_[0]}
sub selected {FSM::Support::ISFRecordPortSamples::actor_has_record_port(actor=>$_[0])}
sub build {
    my ($actor)=@_;
    my $scheduler=FSM::Scheduler::ISF->new;
    my $formal=FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir},$actor);
    return $scheduler->{ir}->build_module($formal ? $formal->{actor} : $actor);
}
sub stringify_widths {
    my ($node)=@_;
    if(ref($node) eq 'HASH') {
        for my $key(keys %$node) {
            $node->{$key}=''.$node->{$key} if $key eq 'width' && defined($node->{$key}) && !ref($node->{$key});
            stringify_widths($node->{$key});
        }
    } elsif(ref($node) eq 'ARRAY') {stringify_widths($_) for @$node}
}
