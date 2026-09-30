use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Support::ISFInterfacePortMetadata qw(
    capture_interface_port_metadata snapshot_interface_port_metadata
    interface_port_metadata_contract
);

my $parser = FSM::Adapter::ISF->new;
my $json = JSON::PP->new->canonical;
my $actor = $parser->parse_source(<<'ISF', 'port-metadata.isf');
(actor port_metadata
  (types
    (type byte (bits 8))
    (type frame_t
      (record
        (subtype (bits 4))
        (payload (record
          (count (signed (four_state (bits 3))))
          (lanes (list (two_state bit) (bits 2))))))))
  (clock clk) (reset rst)
  (interface (output unused (width 2)) (input start)
             (input data (type byte)) (output done))
  (storage (var frame (type frame_t)))
  (transaction main (on start) (complete done)))
ISF

subtest 'declared scalar ports retain ordering and alias facts' => sub {
    my $expected = [
        {name => 'start', direction => 'input', width => 1},
        {name => 'data', direction => 'input', width => 8, type => 'byte', type_kind => 'bits'},
        {name => 'unused', direction => 'output', width => 2},
        {name => 'done', direction => 'output', width => 1},
    ];
    my $before = dclone($actor);
    my $actual = capture_interface_port_metadata($actor->{interface});
    is_deeply($actual, $expected, 'input order followed by output order, including unused declarations');
    is_deeply($json->decode($json->encode($actual)), $expected, 'closed result is JSON-safe');
    $actual->[1]{width} = 99;
    is_deeply($actor, $before, 'projection does not share parser objects');
    my $domain_interface = dclone($actor->{interface});
    $domain_interface->{inputs}[1]{domain} = 'aux';
    my $scoped = capture_interface_port_metadata($domain_interface, 'core');
    is_deeply([map { $_->{domain} } @$scoped], [qw(core aux core core)],
        'explicit domains override the declared default');
    is_deeply(capture_interface_port_metadata({inputs => [{name => 'data-lane', width => 2}], outputs => []}),
        [{name => 'data-lane', direction => 'input', width => 2}],
        'metadata preserves nonempty opaque port names without inventing source restrictions');
};

my $fields = [
    {path => 'subtype', width => 4, lsb => 6, msb => 9, signed => 0},
    {path => 'payload.count', width => 3, lsb => 3, msb => 5, signed => 1, state_model => 'four_state'},
    {path => 'payload.lanes[0]', width => 1, lsb => 2, msb => 2, signed => 0, state_model => 'two_state'},
    {path => 'payload.lanes[1]', width => 2, lsb => 0, msb => 1, signed => 0},
];
my $record_interface = {
    inputs => [{name => 'packet', width => 10, type => 'frame_t', type_spec => $actor->{storage}[0]{type_spec}}],
    outputs => [],
};
my $record = [{name => 'packet', direction => 'input', width => 10,
    type => 'frame_t', type_kind => 'record', fields => $fields}];

sub stringify_numeric_properties {
    my ($value) = @_;
    if (ref($value) eq 'HASH') {
        for my $key (keys %$value) {
            if ($key =~ /\A(?:width|lsb|msb|signed)\z/ && !ref($value->{$key})) {
                $value->{$key} = "$value->{$key}";
            } else {
                stringify_numeric_properties($value->{$key});
            }
        }
    } elsif (ref($value) eq 'ARRAY') {
        stringify_numeric_properties($_) for @$value;
    }
}

subtest 'capture and snapshot detach before first numeric read on valid and refused facts' => sub {
    for my $case (
        ['capture',\&capture_interface_port_metadata,$record_interface],
        ['snapshot',\&snapshot_interface_port_metadata,$record],
    ) {
        my ($name,$produce,$template) = @$case;
        my $value=dclone($template);
        stringify_numeric_properties($value);
        my $before=$json->encode($value);
        my $actual=$produce->($value);
        is($json->encode($value),$before,"$name preserves original scalar kinds on its first read");
        is_deeply($actual,$record,"$name still returns the same independently expected numeric layout");
        $actual->[0]{fields}[0]{width}=99;
        is($json->encode($value),$before,"$name output mutation cannot reach source facts");
        $value=dclone($template);
        stringify_numeric_properties($value);
        if ($name eq 'capture') {
            push @{$value->{outputs}}, {name=>'invalid',width=>'bad'};
        } else {
            push @$value,undef;
        }
        $before=$json->encode($value);
        my $ok=eval {$produce->($value);1};
        my ($line)=split /\n/,$@;
        ok(!$ok,"$name rejects a malformed suffix after valid numeric facts");
        like($line // '',qr/\AInvalid ISF interface port metadata:/,"$name retains a classified first diagnostic");
        is($json->encode($value),$before,"$name refused first read cannot mutate valid prefix facts");
    }
};

subtest 'resolved record preparation preserves independently expected leaf ranges' => sub {
    my $before = dclone($record_interface);
    my $actual = capture_interface_port_metadata($record_interface);
    is_deeply($actual, $record, 'nested record/list leaves have authored order and exact packed ranges');
    $actual->[0]{fields}[0]{lsb} = 0;
    is_deeply($record_interface, $before, 'nested type objects remain detached');
    my $copy = snapshot_interface_port_metadata($record);
    $copy->[0]{fields}[1]{state_model} = 'two_state';
    is($record->[0]{fields}[1]{state_model}, 'four_state', 'snapshot does not share nested fields');
    my $ok = eval { $parser->parse_source(
        '(actor refused (types (type packet_t (record (flag bit))))'
        . ' (interface (input packet (type packet_t)) (output done))'
        . ' (transaction main (complete done)))', 'still-refused.isf'); 1 };
    ok(!$ok, 'producer controls do not admit record source ports');
    like($@, qr/interface port 'packet' references aggregate type 'packet_t'/,
        'existing authored-port refusal remains precise');
};

subtest 'imported scalar and record aliases retain qualified identity' => sub {
    my $work = tempdir(CLEANUP => 1);
    write_file("$work/shared.fsm", '(?pkg:shared (+types (type byte (bits 8))'
        . ' (type packet_t (record (code (bits 2)) (flag bit)))))');
    my $path = "$work/imported.isf";
    write_file($path, '(actor imported (imports (package shared)) (clock clk) (reset rst)'
        . ' (interface (input data (type shared.byte)) (output done))'
        . ' (storage (var packet (type shared.packet_t))) (transaction main (complete done)))');
    my $parsed = $parser->parse_file($path);
    my $ports = capture_interface_port_metadata($parsed->{interface});
    is_deeply($ports->[0], {name => 'data', direction => 'input', width => 8,
        type => 'shared.byte', type_kind => 'bits'}, 'imported scalar alias is not flattened to an anonymous width');
    my $prepared = capture_interface_port_metadata({inputs => [{name => 'packet', width => 3,
        type => 'shared.packet_t', type_spec => $parsed->{storage}[0]{type_spec}}], outputs => []});
    is($prepared->[0]{type}, 'shared.packet_t', 'record producer retains imported alias');
    is_deeply($prepared->[0]{fields}, [
        {path => 'code', width => 2, lsb => 1, msb => 2, signed => 0},
        {path => 'flag', width => 1, lsb => 0, msb => 0, signed => 0},
    ], 'independent imported layout oracle');
};

subtest 'unknown and known empty metadata stay distinct' => sub {
    is(capture_interface_port_metadata(undef), undef, 'absent declarations are unknown');
    is(snapshot_interface_port_metadata(undef), undef, 'unknown snapshot remains null');
    is_deeply(capture_interface_port_metadata({inputs => [], outputs => []}), [], 'known empty declarations remain empty');
    is_deeply(snapshot_interface_port_metadata([]), [], 'known empty snapshot remains empty');
    my $contract = interface_port_metadata_contract();
    is_deeply($contract->{entry_keys}, [qw(name direction width)], 'required entry keys match decision 0113');
    is_deeply($contract->{optional_entry_keys}, [qw(type type_kind domain fields)], 'optional entry keys match the selected schema');
    is_deeply($contract->{field_keys}, [qw(path width lsb msb signed)], 'scalar field key family is explicit');
    is_deeply($contract->{type_kind_values}, [qw(bit bits record)], 'list roots remain outside the selected contract');
    $contract->{entry_keys}[0] = 'changed';
    is(interface_port_metadata_contract()->{entry_keys}[0], 'name', 'discovery values are detached');
};

subtest 'closed snapshots reject malformed and contradictory metadata' => sub {
    my @bad = ({}, [undef], [{}]);
    for my $change (
        sub { delete $_[0][0]{name} }, sub { $_[0][0]{extra} = [] },
        sub { $_[0][0]{name} = '' }, sub { $_[0][0]{direction} = 'inout' },
        sub { $_[0][0]{width} = 0 }, sub { $_[0][0]{width} = 'bad' },
        sub { $_[0][0]{domain} = [] }, sub { $_[0][0]{domain} = 'bad-domain' },
        sub { $_[0][0]{type} = [] }, sub { $_[0][0]{type} = 'bad-alias' },
        sub { $_[0][0]{type_kind} = 'list' },
        sub { delete $_[0][0]{type} }, sub { delete $_[0][0]{fields} },
        sub { $_[0][0]{fields} = [] }, sub { $_[0][0]{fields}[0]{extra} = 1 },
        sub { $_[0][0]{fields}[0]{path} = [] }, sub { $_[0][0]{fields}[1]{path} = 'subtype' },
        sub { $_[0][0]{fields}[0]{msb} = 8 }, sub { $_[0][0]{fields}[0]{lsb} = 5 },
        sub { $_[0][0]{fields}[0]{lsb} = 'bad' }, sub { $_[0][0]{fields}[0]{width} = 'bad' },
        sub { $_[0][0]{fields}[-1]{lsb} = 1; $_[0][0]{fields}[-1]{width} = 1 },
        sub { $_[0][0]{fields}[0]{signed} = 2 }, sub { $_[0][0]{fields}[0]{state_model} = 'unknown' },
        sub { push @{$_[0]}, dclone($_[0][0]) },
    ) {
        my $value = dclone($record);
        $change->($value);
        push @bad, $value;
    }
    push @bad, [{name => 'out', direction => 'output', width => 1},
        {name => 'in', direction => 'input', width => 1}];
    push @bad, [{name => 'scalar', direction => 'input', width => 'bad'}],
        [{name => 'scalar', direction => 'input', width => 8, type => 'byte', type_kind => 'unknown'}];
    for my $index (0 .. $#bad) {
        my $bad = $bad[$index];
        rejects(sub { snapshot_interface_port_metadata($bad) }, "malformed snapshot $index", $bad);
    }
};

subtest 'producer rejects inconsistent resolved declarations without warnings' => sub {
    my @bad = ({}, {inputs => [undef], outputs => []});
    for my $change (
        sub { $_[0]{inputs}[0]{name} = undef }, sub { $_[0]{inputs}[0]{width} = 'bad' },
        sub { $_[0]{inputs}[0]{width} = 9 }, sub { delete $_[0]{inputs}[0]{type_spec} },
        sub { $_[0]{inputs}[0]{type_spec}{width} = 9 },
        sub { $_[0]{inputs}[0]{type_spec}{member_order} = ['subtype', 'subtype'] },
        sub { $_[0]{inputs}[0]{type_spec}{members}{subtype}{state_model} = [] },
        sub { $_[0]{inputs}[0]{type_spec}{members}{subtype}{signed} = [] },
        sub { delete $_[0]{inputs}[0]{type} },
        sub { $_[0]{inputs}[0]{type_spec} = {kind => 'list', width => 1, items => [{kind => 'bit', width => 1}]} },
    ) {
        my $value = dclone($record_interface);
        $change->($value);
        push @bad, $value;
    }
    my $cycle = {kind => 'record', width => 1, member_order => ['loop'], members => {}};
    $cycle->{members}{loop} = $cycle;
    push @bad, {inputs => [{name => 'cycle', width => 1, type => 'cycle_t', type_spec => $cycle}], outputs => []};
    for my $bad (@bad) { rejects(sub { capture_interface_port_metadata($bad) }, 'invalid producer input'); }
    delete $cycle->{members}{loop};
};

done_testing();

sub rejects {
    my ($operation, $label, $value) = @_;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $ok = eval { $operation->(); 1 };
    diag($json->encode($value)) if $ok && defined $value;
    ok(!$ok, "$label fails closed");
    like($@, qr/Invalid ISF interface port metadata:/, 'contextual bounded diagnostic');
    is_deeply(\@warnings, [], 'invalid metadata does not emit incidental Perl warnings');
}

sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die $!;
    print {$fh} $text or die $!;
    close $fh or die $!;
}
