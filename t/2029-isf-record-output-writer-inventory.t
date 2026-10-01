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
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Scheduler::ISF::DomainSource qw(_domain_actor_for_scheduled_artifact);
use FSM::Support::ISFInterfacePortMetadata qw(capture_interface_port_metadata);
use FSM::Scheduler::ISF::RecordOutputWriters;
use FSM::Scheduler::ISF::PhysicalWriteTargets;

my $json = JSON::PP->new->canonical;
my $work = tempdir(CLEANUP => 1);
my $definition = '(record (tag (bits 2)) (payload (record (data (signed (four_state (bits 5)))) (flags (list bit (two_state (bits 2)))))))';
write_file('shared.fsm', '(?pkg:shared (+types (type frame ' . $definition . ')))');
my $fields = [
    {path=>'tag', width=>2, lsb=>8, msb=>9, signed=>0},
    {path=>'payload.data', width=>5, lsb=>3, msb=>7, signed=>1, state_model=>'four_state'},
    {path=>'payload.flags[0]', width=>1, lsb=>2, msb=>2, signed=>0},
    {path=>'payload.flags[1]', width=>2, lsb=>0, msb=>1, signed=>0, state_model=>'two_state'},
];
my ($base_actor, $base_ir);

subtest 'actual source-derived resolved output prototypes retain complete writer facts' => sub {
    for my $case (
        ['local', 'frame', '(types (type frame ' . $definition . '))'],
        ['imported', 'shared.frame', '(imports (package shared))'],
        ['alias', 'alias', '(imports (package shared)) (types (type alias shared.frame))'],
    ) {
        my ($name,$type,$types)=@$case;
        my ($actor,$ir)=resolved_output_prototype($name,$type,$types,
            '(transaction main (on start) (set packet held) (set packet held) (complete done))');
        my ($actor_before,$ir_before)=map {$json->encode($_)} ($actor,$ir);
        my $result=inventory($actor,$ir);
        is_deeply($result->{output_declarations},[{name=>'packet',direction=>'output',width=>10,
            type=>$type,type_kind=>'record',fields=>$fields}], "$name literal declared output layout");
        is(scalar @{$result->{writers}},2,"$name every actual repeated whole write is retained");
        for my $writer (@{$result->{writers}}) {
            is_deeply([@{$writer->{target}}{qw(module root low high width)}],[$name,'packet',0,9,10],
                "$name whole packed target is independent of spelling");
            is_deeply([@{$writer->{owner}}{qw(source_kind source_name container_kind)}],
                ['transaction','main','state'],"$name explicit source identity");
            is($writer->{assignment}{rhs},'held',"$name authored whole RHS retained");
            is($writer->{activation}{container_enable}{kind},'state_active',"$name state activation is explicit");
            is($writer->{activation}{target},'packet',"$name activation names the actual target");
        }
        is($json->encode($actor),$actor_before,"$name complete actor caller JSON is unchanged");
        is($json->encode($ir),$ir_before,"$name complete IR caller JSON is unchanged");
        my $renamed=dclone($ir);
        for my $state (@{$renamed->{states}}) {
            $state->{name}='opaque_container' if grep {$_->{lhs} eq 'packet'} @{$state->{assignments}};
        }
        my $owners=inventory($actor,$renamed)->{writers};
        is_deeply([map {$_->{owner}{source_name}} @$owners],['main','main'],
            "$name state spelling cannot change ownership");
        $result->{output_declarations}[0]{fields}[0]{width}=999;
        $result->{writers}[0]{assignment}{rhs}='corrupt';
        is($json->encode($actor),$actor_before,"$name returned nested mutation cannot edit actor");
        is($json->encode($ir),$ir_before,"$name returned nested mutation cannot edit IR");
        ($base_actor,$base_ir)=($actor,$ir) if $name eq 'local';
    }
};

subtest 'physical members, disjoint leaves and competing source rows are inventoried without admission' => sub {
    my $ir=dclone($base_ir);
    my @containers=grep {grep {$_->{lhs} eq 'packet'} @{$_->{assignments}}} @{$ir->{states}};
    $containers[0]{assignments}[0]{lhs}='packet.tag';
    $containers[1]{assignments}[0]{lhs}='packet.payload.flags[1]';
    my $rows=inventory($base_actor,$ir)->{writers};
    is_deeply([map {[@{$_->{target}}{qw(low high width)}]} @$rows],[[8,9,2],[0,1,2]],
        'literal nested members retain physical packed ranges');
    ok(!FSM::Scheduler::ISF::PhysicalWriteTargets->overlaps(map {$_->{target}} @$rows),
        'disjoint actual leaves do not overlap');
    my $whole=inventory($base_actor,$base_ir)->{writers}[0]{target};
    ok(FSM::Scheduler::ISF::PhysicalWriteTargets->overlaps($whole,$rows->[0]{target}),
        'whole root overlaps its member');
    my ($actor,$competing)=resolved_output_prototype('competing','frame','(types (type frame '.$definition.'))',
        '(transaction left (on start) (set packet held)) (transaction right (on other) (set packet held))');
    my $writers=inventory($actor,$competing)->{writers};
    is_deeply([sort map {$_->{owner}{source_name}} @$writers],['left','right'],
        'both actual owners remain even for identical RHS');
    ok(FSM::Scheduler::ISF::PhysicalWriteTargets->overlaps(map {$_->{target}} @$writers),
        'separate logical owners share one physical root');
    is_deeply($competing->{conflict_issues},[],'old empty conflict report is not converted into an admission claim');
    my ($other_actor,$other_ir)=resolved_output_prototype('other_module','frame','(types (type frame '.$definition.'))',
        '(transaction main (on start) (set packet held))');
    my $other=inventory($other_actor,$other_ir)->{writers}[0]{target};
    ok(!FSM::Scheduler::ISF::PhysicalWriteTargets->overlaps($whole,$other),
        'same root spelling in another actual module stays distinct');
};

subtest 'first-touch string widths and source-formal shadows preserve caller facts' => sub {
    my ($actor,$ir)=map {dclone($_)} ($base_actor,$base_ir);
    stringify_widths($actor);stringify_widths($ir);
    my ($a,$i)=map {$json->encode($_)} ($actor,$ir);
    ok(inventory($actor,$ir),'valid explicitly string-width facts inventory');
    is($json->encode($actor),$a,'first numeric reads cannot mutate actor JSON kinds');
    is($json->encode($ir),$i,'first numeric reads cannot mutate IR JSON kinds');
    my ($shadow_actor,$shadow_ir)=resolved_output_prototype('shadow','frame','(types (type frame '.$definition.'))',
        '(transaction main (ports (output packet (width 3))) (on start) (set packet 1) (complete done))');
    is_deeply(inventory($shadow_actor,$shadow_ir)->{writers},[],
        'private scalar formal spelling cannot become an actor record output writer');
};

subtest 'actual rule and named-drive DT assignments preserve their own activation and owners' => sub {
    for my $case (
        ['rule_writer', '(rule publish (when other) (set packet held))', 'rule', 'publish'],
        ['drive_writer', '(drive publish (packet held)) (transaction invoke (on start) (drive publish))', 'drive', 'publish'],
    ) {
        my ($name,$body,$kind,$owner)=@$case;
        my ($actor,$ir)=resolved_output_prototype($name,'frame','(types (type frame '.$definition.'))',$body);
        my ($a,$i)=map {$json->encode($_)} ($actor,$ir);
        my $writers=inventory($actor,$ir)->{writers};
        is(scalar @$writers,1,"$kind actual DT output assignment counted once");
        is_deeply([@{$writers->[0]{owner}}{qw(source_kind source_name container_kind)}],
            [$kind,$owner,'dt'],"$kind explicit DT source remains distinct from transaction states");
        my ($dt)=grep {grep {$_->{lhs} eq 'packet'} @{$_->{assignments}}} @{$ir->{dt_blocks}};
        is_deeply($writers->[0]{assignment},$dt->{assignments}[0],"$kind actual operator/RHS/guard record is retained");
        is_deeply($writers->[0]{activation}{container_enable}{guard}{raw},$dt->{dte_guard},
            "$kind actual header condition is retained independently");
        is($json->encode($actor),$a,"$kind source stays detached");
        is($json->encode($ir),$i,"$kind realized IR stays detached");
        my $bad=dclone($ir);
        delete $_->{source_owner} for @{$bad->{dt_blocks}};
        eval {inventory($actor,$bad)};
        like((split /\n/,$@)[0],qr/explicit DT source owner/,"$kind missing owner cannot be recovered from its name");
    }
};

subtest 'actual domain realization matches selected source and packed output declaration' => sub {
    my $source='(actor output_domains (types (type frame '.$definition.'))'
        .' (clock-domains (domain core (clock clk) :default) (domain bus (clock bus_clk)))'
        .' (interface (input start (domain core)) (input other (domain bus))'
        .' (output done (domain core)) (output packet (width 10) (domain bus)))'
        .' (storage (var held (type frame) (domain bus)))'
        .' (transaction main (domain core) (on start) (set done 1))'
        .' (transaction worker (domain bus) (on other) (set packet held)))';
    my $actor=prepare_output_actor(write_file('output_domains.isf',$source),'frame');
    my $scheduler=FSM::Scheduler::ISF->new;
    my $ir=$scheduler->{ir}->build_module($actor);
    my ($a,$i)=map {$json->encode($_)} ($actor,$ir);
    my $realizations=$scheduler->_multi_domain_realizations($actor,$ir->{domain_partition});
    for my $r (@$realizations) {
        my $selected=_domain_actor_for_scheduled_artifact($actor,$r->{domain},$ir->{domain_partition}{default_domain});
        my $result=inventory($selected,$r->{ir});
        if($r->{domain}{name} eq 'bus') {
            is(scalar @{$result->{writers}},1,'selected bus module accounts actual output write');
            is_deeply([@{$result->{writers}[0]{owner}}{qw(module domain source_name)}],
                [$r->{ir}{actor_name},'bus','worker'],'owner joins actual emitted module and bus source');
            is($result->{output_declarations}[0]{domain},'bus','explicit output domain remains source metadata');
            my $bad=dclone($selected);$bad->{transactions}[0]{domain}='core';
            eval {inventory($bad,$r->{ir})};
            like((split /\n/,$@)[0],qr/crosses the actual clock-domain/,'foreign owner domain refuses');
        } else {
            is_deeply($result->{writers},[],'other actual domain does not invent a record output');
        }
    }
    is($json->encode($actor),$a,'domain source selection does not mutate complete original actor');
    is($json->encode($ir),$i,'domain selection does not mutate complete pre-partition IR');
};

subtest 'missing or mismatched source, module, role, layout and owner facts refuse primarily' => sub {
    for my $case (
        ['module',sub {$_[1]{actor_name}='foreign'},qr/matching source\/module/],
        ['unknown interface',sub {delete $_[0]{interface}},qr/known declared interface/],
        ['missing resolved type',sub {delete $_[0]{interface}{outputs}[0]{type_spec}},qr/lacks resolved type/],
        ['missing port',sub {$_[1]{ports}=[grep {$_->{name} ne 'packet'} @{$_[1]{ports}}]},qr/lacks its realized output port/],
        ['wrong role',sub {(grep {$_->{name} eq 'packet'} @{$_[1]{ports}})[0]{direction}='input'},qr/lacks its realized output port/],
        ['wrong width',sub {(grep {$_->{name} eq 'packet'} @{$_[1]{ports}})[0]{width}=9},qr/realized width/],
        ['wrong alias',sub {(grep {$_->{name} eq 'packet'} @{$_[1]{ports}})[0]{type}='different'},qr/emitted type token/],
        ['wrong resolved layout',sub {my $port=(grep {$_->{name} eq 'packet'} @{$_[1]{ports}})[0];$port->{type_spec}=dclone($_[0]{interface}{outputs}[0]{type_spec});$port->{type_spec}{members}{tag}{signed}=1},qr/realized type/],
        ['unknown member',sub {(grep {grep {$_->{lhs} eq 'packet'} @{$_->{assignments}}} @{$_[1]{states}})[0]{assignments}[0]{lhs}='packet.missing'},qr/unknown_member/],
        ['missing owner',sub {delete $_->{transaction} for @{$_[1]{states}}},qr/explicit source identity/],
        ['missing assignments',sub {delete $_[1]{states}[0]{assignments}},qr/assignments/],
        ['mixed domains',sub {$_[1]{domain_partition}={kind=>'multi_domain'}},qr/realized clock-domain/],
        ['generated mapping',sub {$_[1]{children}={worker=>{}}},qr/generated record-output mappings/],
    ) {
        my ($name,$mutate,$reason)=@$case;
        my ($actor,$ir)=map {dclone($_)} ($base_actor,$base_ir);
        $mutate->($actor,$ir);
        my $ok=eval {inventory($actor,$ir);1};
        my ($first)=split /\n/,$@;
        ok(!$ok,"$name refuses");
        like($first // '',$reason,"$name primary reason is independent of implementation stack");
    }
};

subtest 'authored record output stays closed and scalar/source controls stay unchanged' => sub {
    my $text='(actor closed (types (type frame '.$definition.')) (interface (output packet (type frame))))';
    my $ok=eval {FSM::Adapter::ISF->new->parse_source($text,'closed_output.isf');1};
    my ($first)=split /\n/,$@;
    ok(!$ok,'preparation does not admit authored record output');
    like($first // '',qr/interface port 'packet' references aggregate type 'frame'/,'current precise source boundary remains');
    my $actor=FSM::Adapter::ISF->new->parse_source('(actor scalar (clock clk) (interface (input start) (output packet (width 3))) (transaction main (on start) (set packet 1)))','scalar.isf');
    my $ir=FSM::Scheduler::ISF->new->{ir}->build_module($actor);
    is_deeply(inventory($actor,$ir),{module=>'scalar',output_declarations=>[],writers=>[]},
        'unrelated scalar outputs are not promoted into record facts');
};
done_testing;

sub resolved_output_prototype {
    my ($name,$type,$types,$body)=@_;
    my $source="(actor $name (clock clk) $types"
        . ' (interface (input start) (input other) (output packet (width 10)) (output done))'
        . " (storage (var held (type $type))) $body)";
    my $path=write_file("$name.isf",$source);
    my $actor=prepare_output_actor($path,$type);
    return ($actor,FSM::Scheduler::ISF->new->{ir}->build_module($actor));
}
sub prepare_output_actor {
    my ($path,$type)=@_;
    my $actor=FSM::Adapter::ISF->new->parse_file($path);
    # This prepared resolved declaration comes from the actual storage resolver.
    # It is a prototype for the private inventory, not new authored source support.
    my ($port)=grep {$_->{name} eq 'packet'} @{$actor->{interface}{outputs}};
    $port->{type}=$type;$port->{type_spec}=dclone($actor->{storage}[0]{type_spec});
    $port->{width}=$port->{type_spec}{width};
    $actor->{interface_port_metadata}=capture_interface_port_metadata($actor->{interface},($actor->{clock_domains} || {})->{default});
    my $scheduler=FSM::Scheduler::ISF->new;
    my $formal=FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir},$actor);
    $actor=$formal->{actor} if $formal;
    return $actor;
}
sub inventory {FSM::Scheduler::ISF::RecordOutputWriters->inventory(actor=>$_[0],ir=>$_[1])}
sub write_file {
    my ($name,$text)=@_;my $path="$work/$name";
    open my $fh,'>:raw',$path or die $!;print {$fh} $text or die $!;close $fh or die $!;return $path;
}
sub stringify_widths {
    my ($node)=@_;
    if(ref($node) eq 'HASH') {
        for my $key(keys %$node) {
            $node->{$key}="".$node->{$key} if $key eq 'width' && defined($node->{$key}) && !ref($node->{$key});
            stringify_widths($node->{$key});
        }
    } elsif(ref($node) eq 'ARRAY') {stringify_widths($_) for @$node}
}
