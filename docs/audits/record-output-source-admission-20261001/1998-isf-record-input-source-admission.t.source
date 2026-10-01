use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $parser = FSM::Adapter::ISF->new;
my $scheduler = FSM::Scheduler::ISF->new;
my $json = JSON::PP->new->canonical;
my $work = tempdir(CLEANUP => 1);
my $header = <<'ISF';
(actor records
 (types (type frame (record (kind (bits 2))
   (payload (record (data (signed (four_state (bits 5))))
    (flags (list bit (two_state (bits 2))))))))
  (type alias frame)
  (type other (record (kind (bits 2))
   (payload (record (data (four_state (bits 5))) (flags (list bit (two_state (bits 2)))))))))
 (enums (packet (OTHER 1)) (mode (ON 1)))
 (interface (input start) (input scalar (width 5)) (input mode)
  (input packet (type frame)) (output seen (width 5)) (output sliced (width 3)) (output tag (width 2)) (output done))
 (storage (var held (type alias)) (var mismatch (type other)))
ISF
my $fields = [
    {path => 'kind', width => 2, lsb => 8, msb => 9, signed => 0},
    {path => 'payload.data', width => 5, lsb => 3, msb => 7, signed => 1, state_model => 'four_state'},
    {path => 'payload.flags[0]', width => 1, lsb => 2, msb => 2, signed => 0},
    {path => 'payload.flags[1]', width => 2, lsb => 0, msb => 1, signed => 0, state_model => 'two_state'},
];
sub write_file {
    my ($path, $text) = @_;
    open my $file, '>', $path or die $!;
    print {$file} $text;
    close $file or die $!;
}
sub source { return $header . $_[0] . ')'; }
sub qualify {
    my ($name, $text, $type) = @_;
    my $path = "$work/$name.isf";
    write_file($path, $text);
    my $actor;
    my $ok = eval { $actor = $parser->parse_source($text, $path); 1 };
    my ($error) = split /\n/, $@;
    ok($ok, "$name actual authored source parses") or diag($error // '');
    return unless $ok;
    my $before = $json->encode($actor);
    my ($port) = grep { $_->{name} eq 'packet' } @{$actor->{interface_port_metadata}};
    is_deeply($port, {name => 'packet', direction => 'input', width => 10,
        type => $type, type_kind => 'record', fields => $fields}, "$name complete independently expected input declaration");
    my $result;
    $ok = eval { $result = $scheduler->lower($actor); 1 };
    ($error) = split /\n/, $@;
    ok($ok, "$name actual authored source lowers") or diag($error // '');
    is($json->encode($actor), $before, "$name complete caller JSON stays unchanged");
    return unless $ok;
    my $report = $json->decode($scheduler->report($actor));
    is_deeply([grep {$_->{name} eq 'packet'} @{$report->{interface_ports}}], [$port], "$name actual schedule retains exact record declaration");
    my $dir = "$work/$name";
    mkdir $dir or die $!;
    write_file("$dir/$_", $result->{files}{$_}) for sort keys %{$result->{files}};
    for my $file (sort keys %{$result->{files}}) {
        my $fsm = $result->{files}{$file};
        open my $native, '-|', './bin/fsmgen', '--quiet', '--strict', '--check', '--json', "$dir/$file" or die $!;
        my $output = do {local $/; <$native>};
        close $native;
        my $exit = $? >> 8;
        is($exit, 0, "$name actual $file strictly replays") or diag($output);
        ok($json->decode($output)->{success}, "$name $file reports strict success");
        like($fsm, qr/\(packet \Q$type\E\)/, "$name typed record input reuses the authored alias")
            if $file eq 'records.fsm';
    }
    # Check the authored source too; carrier success alone cannot prove ingress.
    open my $native, '-|', './bin/fsmgen', '--quiet', '--strict', '--check', '--json', $path or die $!;
    my $output = do {local $/; <$native>};
    close $native;
    is($? >> 8, 0, "$name original authored source succeeds natively") or diag($output);
    my $native_report = $json->decode($output);
    ok($native_report->{success}, "$name native source reports complete success");
    is_deeply([grep {$_->{name} eq 'packet'} @{$native_report->{source}{interface_ports}}], [$port],
        "$name native source retains independently expected full metadata");
}
sub refuses {
    my ($text, $pattern, $label) = @_;
    my $ok = eval {
        my $actor = $parser->parse_source($text, 'record-input-negative.isf');
        $scheduler->lower($actor);
        1;
    };
    my ($error) = split /\n/, $@;
    ok(!$ok, "$label refuses before successful lowering");
    like($error // '', $pattern, "$label names the first contextual cause");
}

subtest 'authored local record input contexts use exact packed facts' => sub {
    qualify('copy', source('(transaction main (on start) (set held packet) (set seen packet.payload.data) (complete done))'), 'frame');
    qualify('leaves', source('(transaction main (on start) (when mode.ON (set sliced packet.payload.data[3:1]))'
        . ' (when packet.payload.flags[1] (update tag packet.kind)) (complete done))'), 'frame');
    qualify('sample', source('(transaction main (on start (sample packet.payload.data as held_leaf))'
        . ' (set seen held_leaf) (complete done))'), 'frame');
    qualify('rule', source('(rule observe packet.payload.flags[0] (seen packet.payload.data))'), 'frame');
    qualify('drive', source('(drive publish (seen packet.payload.data))'
        . ' (transaction main (on start) (drive publish) (complete done))'), 'frame');
    qualify('generated', source('(transaction worker (ports (output result (width 5))) (set result packet.payload.data) (complete done))'
        . ' (transaction main (on start) (spawn worker as job (bind (output result seen))) (await_all done) (complete done))'), 'frame');
    qualify('unused', source('(transaction main (on start) (set seen scalar) (complete done))'), 'frame');
};

subtest 'actual imported aliases preserve the same resolved identity' => sub {
    write_file("$work/shared.fsm", '(?pkg:shared (+types (type frame (record (kind (bits 2))'
        . ' (payload (record (data (signed (four_state (bits 5)))) (flags (list bit (two_state (bits 2))))))))))');
    my $text = $header;
    my $start = index($text, ' (types');
    my $end = index($text, ' (enums');
    substr($text, $start, $end - $start, ' (imports (package shared))' . "\n");
    $text =~ s/\(type (?:frame|alias|other)\)/(type shared.frame)/g;
    qualify('imported', $text . '(transaction main (on start) (set held packet) (set seen packet.payload.data) (complete done)))', 'shared.frame');
};

subtest 'first authored source admission has every mandatory negative gate' => sub {
    for my $case (
        ['unknown member', '(set seen packet.missing)', qr/unknown_member/],
        ['out of range', '(set seen packet.payload.flags[1][2])', qr/scalar_index_out_of_range/],
        ['subaggregate scalar', '(set seen packet.payload)', qr/requires a scalar leaf.*resolves to record/],
        ['input field target', '(set packet.payload.data 1)', qr/cannot write declared input/],
        ['input whole target', '(set packet held)', qr/cannot write declared input/],
        ['equal width mismatch', '(set mismatch packet)', qr/requires the same resolved record type/],
        ['whole to scalar', '(set seen packet)', qr/whole record port copy requires declared record roots/],
        ['whole arithmetic', '(set seen (+ packet 1))', qr/requires a scalar value.*whole record port/],
        ['whole condition', '(when packet (set seen 1))', qr/requires a scalar value.*whole record port/],
        ['member operator', '(set seen (packet.payload.data 1))', qr/operator cannot use declared aggregate reference/],
        ['whole sample', '(sample packet as q)', qr/scalar.*whole record|whole record.*scalar/],
        ['input alias', '(sample scalar as packet)', qr/cannot write declared input/],
        ['unsupported trigger', '(await packet.payload.flags[0])', qr/does not admit record port reference/],
    ) {
        refuses(source('(transaction main (on start) ' . $case->[1] . ')'), $case->[2], $case->[0]);
    }
    my $foreign = $header;
    $foreign =~ s/\(actor records/\(actor records (clock-domains (domain core (clock clk) :default) (domain aux (clock aux_clk)))/;
    $foreign =~ s/\(input packet \(type frame\)\)/\(input packet (type frame) (domain aux)\)/;
    refuses($foreign . '(transaction main (on start) (set seen packet.payload.data)))',
        qr/clock-domain violation: .* read signal 'packet.payload.data' owned by domain 'aux' from domain 'core'/,
        'authored foreign record leaf');
};

subtest 'unbound generated outputs remain closed for record and ordinary sources' => sub {
    my $unbound = source('(transaction worker (set seen packet.payload.data) (complete done))'
        . ' (transaction main (on start) (spawn worker as job) (await_all done) (complete done))');
    my $ordinary = $unbound;
    $ordinary =~ s/\(input packet \(type frame\)\)/(input packet (width 10))/;
    $ordinary =~ s/packet\.payload\.data/scalar/g;
    for my $case (['record', $unbound], ['ordinary', $ordinary]) {
        my $path = "$work/unbound-$case->[0].isf";
        write_file($path, $case->[1]);
        open my $native, '-|', './bin/fsmgen', '--quiet', '--strict', '--check', '--json', $path or die $!;
        my $output = do {local $/; <$native>};
        close $native;
        is($? >> 8, 1, "$case->[0] unbound generated output refuses natively");
        my $report = $json->decode($output);
        ok(!$report->{success}, "$case->[0] unbound output cannot report source success");
        ok(!$report->{generated_output}{emitted}, "$case->[0] unbound output emits no HDL");
        like($report->{diagnostics}[0]{message}, qr/leaves child port 'job.seen' unconnected/,
            "$case->[0] first native diagnostic retains existing explicit child binding contract");
    }
};

subtest 'unqualified aggregate carriers and unknown aliases stay closed' => sub {
    for my $case (
        ['output field', '(actor refused (types (type frame (record (flag bit)))) (interface (output packet (type frame))) (transaction main (set packet.flag 1)))', qr/record output field writes are not yet admitted/],
        ['root list', '(actor refused (types (type lanes (list bit bit))) (interface (input packet (type lanes))))', qr/interface port 'packet' references aggregate type/],
        ['transaction', '(actor refused (types (type frame (record (flag bit)))) (transaction main (ports (input packet (type frame)))))', qr/transaction 'main' port 'packet' references aggregate type/],
        ['unknown alias', '(actor refused (interface (input packet (type missing))))', qr/interface port 'packet' references unknown type 'missing'/],
        ['width and type', '(actor refused (interface (input packet (type missing) (width 8))))', qr/cannot specify both/],
    ) {
        refuses($case->[1], $case->[2], $case->[0]);
    }
};

done_testing;
