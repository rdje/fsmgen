use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::ISFRecordPortContexts qw(validate_actor_record_contexts);
use FSM::Support::ISFInterfacePortMetadata qw(capture_interface_port_metadata);

my $parser=FSM::Adapter::ISF->new;
my $scheduler=FSM::Scheduler::ISF->new;
my $json=JSON::PP->new->canonical;
my $work=tempdir(CLEANUP=>1);
my $header=<<'ISF';
(actor record_domains
 (clock-domains (domain core (clock clk) :default) (domain aux (clock aux_clk)))
 (types (type frame (record (payload (record (count (bits 8))
    (flags (list bit (bits 2))))))))
 (enums (mode (OFF 0) (ON 1)))
 (interface (input start) (input ack) (input data (width 8)) (input mode)
  (output seen (width 8)) (output flag_seen) (output done))
 (storage (var packet (type frame) (domain aux)) (var held (type frame)))
ISF
sub prepared {
    my ($body,$domain)=@_;
    my $drive=$body =~ /\(drive publish / ? ' (drive (publish value) (seen value))' : '';
    my $actor=$parser->parse_source($header.$drive.$body.')','record-domains.isf');
    return promote_packet($actor,$domain);
}
sub promote_packet {
    my ($actor,$domain)=@_;
    my $packet=shift @{$actor->{storage}};
    my %input=map {$_=>$packet->{$_}} qw(name width type type_spec domain);
    $input{domain}=$domain if defined $domain;
    push @{$actor->{interface}{inputs}},\%input;
    $actor->{interface_port_metadata}=capture_interface_port_metadata($actor->{interface},$actor->{clock_domains}{default});
    return $actor;
}
sub error {
    my ($actor)=@_;
    my $before=$json->encode($actor);
    my $ok=eval {$scheduler->lower($actor);1};
    my ($line)=split /\n/,$@;
    is($json->encode($actor),$before,'complete supplied caller facts stay unchanged');
    return $ok ? '' : $line // '';
}
sub replay {
    my ($actor,$label)=@_;
    my $before=$json->encode($actor);
    my $product=$scheduler->lower($actor);
    is($json->encode($actor),$before,"$label preserves complete caller facts");
    for my $name (sort keys %{$product->{files}}) {
        open my $f,'>',"$work/$name" or die $!;
        print {$f} $product->{files}{$name}; close $f or die $!;
        open my $cli,'-|','./bin/fsmgen','--quiet','--strict','--check','--json',"$work/$name" or die $!;
        my $out=do {local $/;<$cli>};close $cli;
        my $exit=$? >> 8;
        diag($out) if $exit;
        is($exit,0,"$label actual $name strictly replays");
        ok($json->decode($out)->{success},"$label replay returns success");
    }
    return $product;
}
sub rename_tokens {
    my ($value,$old,$new)=@_;
    return unless ref($value) eq 'ARRAY';
    for my $item (@$value) {
        if (ref($item)) {rename_tokens($item,$old,$new)}
        elsif (defined($item)) {$item =~ s/\A\Q$old\E(?=\[|\z)/$new/}
    }
}

subtest 'prepared foreign record paths refuse with exact authored ownership' => sub {
    for my $case (
        ['nested member','packet.payload.count'],
        ['scalar slice','packet.payload.count[3:0]'],
        ['reversed scalar slice','packet.payload.count[0:3]'],
        ['single-bit slice','packet.payload.count[7:7]'],
        ['list leaf','packet.payload.flags[0]'],
        ['nested list scalar slice','packet.payload.flags[1][1:0]'],
    ) {
        my ($label,$token)=@$case;
        my $actor=prepared("(transaction main (on start) (set seen $token) (complete done))");
        ok(validate_actor_record_contexts(actor=>$actor),"$label is a valid selected scalar leaf");
        like(error($actor),qr/clock-domain violation: transaction 'main' set clause read signal '\Q$token\E' owned by domain 'aux' from domain 'core' without a crossing primitive/,
            "$label cannot lose its declared root domain");
    }
    my $copy=prepared('(transaction main (on start) (set held packet) (complete done))');
    ok(validate_actor_record_contexts(actor=>$copy),'whole copy is an independently valid same-type input read');
    like(error($copy),qr/clock-domain violation: .* read signal 'packet' owned by domain 'aux' from domain 'core'/,'whole copy preserves its existing domain refusal');
};

subtest 'capture control rule and drive reads share record root protection' => sub {
    for my $case (
        ['control','(transaction main (on start) (when packet.payload.count (set seen 1)) (complete done))'],
        ['named drive','(transaction main (on start) (drive publish packet.payload.count) (complete done))'],
        ['inline drive','(transaction main (on start) (drive (seen packet.payload.count)) (complete done))'],
        ['rule guard','(rule observe packet.payload.count (seen 1))'],
        ['rule RHS','(rule observe 1 (seen packet.payload.count))'],
    ) {
        my ($label,$body)=@$case;
        my $actor=prepared($body);
        ok(validate_actor_record_contexts(actor=>$actor),"$label has valid scalar contexts");
        like(error($actor),qr/clock-domain violation: .* read signal 'packet.payload.count' owned by domain 'aux' from domain 'core'/,
            "$label inherits the declared record domain");
    }
    for my $entry (0,1) {
        my $actor=prepared($entry
            ? '(transaction main (on start (sample ack as q)) (set seen q) (complete done))'
            : '(transaction main (on start) (sample ack as q) (set seen q) (complete done))');
        my $sample=$entry ? $actor->{transactions}[0]{clauses}[0][2] : $actor->{transactions}[0]{clauses}[1];
        $sample->[1]='packet.payload.count';
        ok(validate_actor_record_contexts(actor=>$actor),'selected leaf sample facts qualify');
        like(error($actor),qr/clock-domain violation: transaction 'main' sample clause read signal 'packet.payload.count' owned by domain 'aux' from domain 'core'/,
            $entry ? 'entry sample cannot cross domains' : 'body sample cannot cross domains');
    }
};

subtest 'used named drive bodies inherit the actual record root domain' => sub {
    my $actor=prepared('(drive capture (seen packet.payload.count))'
        . ' (transaction main (on start) (drive capture) (complete done))');
    ok(validate_actor_record_contexts(actor=>$actor),'selected named drive body is a valid leaf read');
    like(error($actor),qr/clock-domain violation: drive 'capture' assignment read signal 'packet.payload.count' owned by domain 'aux' from domain 'core'/,
        'used drive body cannot borrow a foreign input member');
};

subtest 'same-domain nested paths preserve complete partition and actual carriers' => sub {
    my $actor=prepared('(transaction main (on start) (set held packet)
        (when mode.ON (set seen packet.payload.count))
        (when packet.payload.count[3:0] (set seen packet.payload.count))
        (when packet.payload.flags[1][1:0] (set seen packet.payload.count)) (complete done))','core');
    ok(validate_actor_record_contexts(actor=>$actor),'same-domain copy and nested reads qualify');
    my $result=replay($actor,'same domain');
    my $report=$json->decode($scheduler->report($actor));
    my %domains=map {$_->{name}=>$_} @{$report->{clock_domains}};
    is_deeply([map {$_->{name}} grep {$_->{direction} eq 'input'} @{$domains{core}{interface_ports}}],[qw(start ack data mode packet)],
        'resolved record input belongs only to its actual domain snapshot');
    is_deeply($domains{aux}{interface_ports},[],'unrelated domain gains no record input');
    like($result->{files}{'record_domains__domain_core.fsm'},qr/\(packet frame\)/,'actual owning carrier retains packed record type');
};

subtest 'nearest scalar formals retain local ownership without outer record borrowing' => sub {
    my $actor=prepared('(transaction main (ports (input value (width 3)))
        (on start) (set flag_seen value[0]) (complete done))');
    $actor->{transactions}[0]{ports}{inputs}[0]{name}='packet';
    rename_tokens($actor->{transactions}[0]{clauses},'value','packet');
    ok(validate_actor_record_contexts(actor=>$actor),'actual nearest scalar formal slice qualifies');
    my $result=replay($actor,'formal shadow');
    like($result->{files}{'record_domains__domain_core.fsm'},qr/isf_port_main_packet\[0\]/,
        'actual physical formal slice retains its distinct identity');
    unlike($result->{files}{'record_domains__domain_core.fsm'},qr/\(packet frame\)/,
        'local domain does not borrow the foreign actor record carrier');
};

subtest 'foreign scalar enum namespace retains its distinct constant identity' => sub {
    my $actor=prepared('(transaction main (on start) (when mode.ON (set seen data)) (complete done))','core');
    my ($mode)=grep {$_->{name} eq 'mode'} @{$actor->{interface}{inputs}};
    $mode->{domain}='aux';
    $actor->{interface_port_metadata}=capture_interface_port_metadata($actor->{interface},'core');
    ok(validate_actor_record_contexts(actor=>$actor),'enum constant stays outside scalar pin traversal');
    replay($actor,'enum namespace');
};

subtest 'actual imported record roots and foreign package namespace pins remain distinct' => sub {
    open my $pkg,'>',"$work/shared.fsm" or die $!;
    print {$pkg} '(?pkg:shared (+types (type frame (record (payload (record (count (bits 8))'
        . ' (flags (list bit (bits 2)))))))) (+enums (mode (ON 1))) (+constants (MAX 8)))';
    close $pkg or die $!;
    my $source=$header;
    my $first=index($source,' (types');
    my $last=index($source,' (enums',$first);
    substr($source,$first,$last-$first)=" (imports (package shared))\n";
    $source =~ s/\(type frame\)/(type shared.frame)/g;
    $source =~ s/\(input mode\)/(input mode) (input shared (domain aux))/;
    $source .= '(transaction main (on start) (when shared.mode.ON (set seen packet.payload.count)) (complete done)))';
    my $ordinary=$parser->parse_source($source,"$work/imported.isf");
    my $foreign=promote_packet($ordinary);
    ok(validate_actor_record_contexts(actor=>$foreign),'actual imported leaf and package enum qualify');
    like(error($foreign),qr/clock-domain violation: .* read signal 'packet.payload.count' owned by domain 'aux' from domain 'core'/,
        'imported alias cannot erase the declared foreign root');
    my $actor=promote_packet($parser->parse_source($source,"$work/imported.isf"),'core');
    ok(validate_actor_record_contexts(actor=>$actor),'same-domain imported record and foreign scalar package pin qualify');
    replay($actor,'imported namespace');
};

done_testing;
