use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr blessed);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);
use FSM::Adapter::ISF;
use FSM::Support::ISFInterfacePortMetadata qw(
    capture_interface_port_metadata snapshot_interface_port_metadata
    interface_port_metadata_contract
);

sub source_value_copy {
    my ($value, $copies) = @_;
    return $value unless ref($value);
    die 'unexpected source reference' if blessed($value)
        || (ref($value) ne 'HASH' && ref($value) ne 'ARRAY');
    $copies ||= {};
    my $address = refaddr($value);
    return $copies->{$address} if exists $copies->{$address};
    my $copy = ref($value) eq 'HASH' ? {} : [];
    $copies->{$address} = $copy;
    if (ref($value) eq 'HASH') {
        $copy->{$_} = source_value_copy($value->{$_}, $copies) for keys %$value;
    } else {
        push @$copy, source_value_copy($_, $copies) for @$value;
    }
    return $copy;
}

sub snapshot_graph {
    my ($value, $seen, $path) = @_;
    return $value unless ref($value);
    die 'unqualified native graph reference' if blessed($value);
    $seen ||= {}; $path //= '';
    my $address = refaddr($value);
    return ['reference', $seen->{$address}] if exists $seen->{$address};
    $seen->{$address} = $path;
    if (ref($value) eq 'HASH') {
        my %out;
        for my $key (sort keys %$value) {
            my $escaped = $key; $escaped =~ s/~/~0/g; $escaped =~ s{/}{~1}g;
            $out{$key} = snapshot_graph($value->{$key}, $seen, "$path/$escaped");
        }
        return ['hash', \%out];
    }
    return ['array', [map {snapshot_graph($value->[$_], $seen, "$path/$_")} 0..$#$value]]
        if ref($value) eq 'ARRAY';
    die 'unqualified native graph reference';
}

sub input_snapshot {JSON::PP->new->canonical->encode(snapshot_graph($_[0]))}

sub source_references {
    my @pending = ($_[0]);
    my %seen;
    while (@pending) {
        my $value = pop @pending;
        next unless ref($value);
        die 'unexpected source reference' if blessed($value)
            || (ref($value) ne 'HASH' && ref($value) ne 'ARRAY');
        my $address = refaddr($value);
        next if exists $seen{$address};
        $seen{$address} = 1;
        push @pending, ref($value) eq 'HASH' ? values(%$value) : @$value;
    }
    return \%seen;
}

sub source_copy {
    my ($value, $label) = @_;
    my $before = input_snapshot($value);
    my $original = source_references($value);
    my $copy = source_value_copy($value);
    my $copied = source_references($copy);
    my $shared = grep {exists $original->{$_}} keys %$copied;
    is(input_snapshot($value), $before, "$label copy preserves original kinds and sharing");
    is(input_snapshot($copy), $before, "$label copy preserves kinds and sharing");
    is(scalar(keys %$copied), scalar(keys %$original), "$label copy preserves reference population");
    is($shared, 0, "$label copy is isolated from source");
    return $copy;
}

# Compare complete primitive kinds as well as values in finite public products.
sub is_metadata {
    my ($actual, $expected, $label) = @_;
    is(input_snapshot($actual), input_snapshot($expected), $label);
}

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
    my $before = input_snapshot($actor);
    my $actual = capture_interface_port_metadata($actor->{interface});
    is_metadata($actual, $expected, 'input order followed by output order, including unused declarations');
    is_metadata($json->decode($json->encode($actual)), $expected, 'closed result is JSON-safe');
    $actual->[1]{width} = 99;
    is(input_snapshot($actor), $before, 'projection does not share parser objects');
    my $domain_interface = source_copy($actor->{interface}, 'domain interface');
    $domain_interface->{inputs}[1]{domain} = 'aux';
    my $scoped = capture_interface_port_metadata($domain_interface, 'core');
    is_deeply([map { $_->{domain} } @$scoped], [qw(core aux core core)],
        'explicit domains override the declared default');
    is_metadata(capture_interface_port_metadata({inputs => [{name => 'data-lane', width => 2}], outputs => []}),
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
        my $value=source_copy($template, "$name numeric seed");
        stringify_numeric_properties($value);
        my $before=$json->encode($value);
        my $actual=$produce->($value);
        is($json->encode($value),$before,"$name preserves original scalar kinds on its first read");
        is_metadata($actual,$record,"$name still returns the same independently expected numeric layout");
        $actual->[0]{fields}[0]{width}=99;
        is($json->encode($value),$before,"$name output mutation cannot reach source facts");
        $value=source_copy($template, "$name refused numeric seed");
        stringify_numeric_properties($value);
        if ($name eq 'capture') {
            push @{$value->{outputs}}, {name=>'invalid',width=>'bad'};
        } else {
            push @$value,undef;
        }
        $before=$json->encode($value);
        my $ok=eval {$produce->($value);1};
        my $error = $@;
        my $reason = $name eq 'capture' ? 'invalid declared port width' : 'expected port metadata entry';
        ok(!$ok,"$name rejects a malformed suffix after valid numeric facts");
        ok(diagnostic_cause_matches($error, "Invalid ISF interface port metadata: $reason"),
            "$name retains a classified first diagnostic");
        is($json->encode($value),$before,"$name refused first read cannot mutate valid prefix facts");
    }
};

subtest 'resolved record preparation preserves independently expected leaf ranges' => sub {
    my $before = input_snapshot($record_interface);
    my $actual = capture_interface_port_metadata($record_interface);
    is_metadata($actual, $record, 'nested record/list leaves have authored order and exact packed ranges');
    $actual->[0]{fields}[0]{lsb} = 0;
    is(input_snapshot($record_interface), $before, 'nested type objects remain detached');
    my $copy = snapshot_interface_port_metadata($record);
    $copy->[0]{fields}[1]{state_model} = 'two_state';
    is($record->[0]{fields}[1]{state_model}, 'four_state', 'snapshot does not share nested fields');
    my $ok = eval { $parser->parse_source(
        '(actor refused (types (type packet_t (record (flag bit))))'
        . ' (interface (output packet (type packet_t)) (output done))'
        . ' (transaction main (set packet.flag 1) (complete done)))', 'field-refused.isf'); 1 };
    my $error = $@;
    ok(!$ok, 'record output field writer remains deferred');
    ok(diagnostic_cause_matches($error,
        "Invalid ISF record context: transaction 'main' set target record output field writes are not yet admitted; "
        . "target 'packet.flag' requires output-field writer qualification"),
        'existing authored-field refusal remains precise');
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
    is_metadata($ports->[0], {name => 'data', direction => 'input', width => 8,
        type => 'shared.byte', type_kind => 'bits'}, 'imported scalar alias is not flattened to an anonymous width');
    my $prepared = capture_interface_port_metadata({inputs => [{name => 'packet', width => 3,
        type => 'shared.packet_t', type_spec => $parsed->{storage}[0]{type_spec}}], outputs => []});
    is($prepared->[0]{type}, 'shared.packet_t', 'record producer retains imported alias');
    is_metadata($prepared->[0]{fields}, [
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
        sub { push @{$_[0]}, source_copy($_[0][0], 'duplicate metadata entry') },
    ) {
        my $value = source_copy($record, 'malformed snapshot seed');
        $change->($value);
        push @bad, $value;
    }
    push @bad, [{name => 'out', direction => 'output', width => 1},
        {name => 'in', direction => 'input', width => 1}];
    push @bad, [{name => 'scalar', direction => 'input', width => 'bad'}],
        [{name => 'scalar', direction => 'input', width => 8, type => 'byte', type_kind => 'unknown'}];
    my @reasons = (
        'expected port metadata array',
        'expected port metadata entry',
        'missing metadata key',
        'missing metadata key',
        'unknown metadata key',
        'invalid or duplicate port name',
        'invalid direction',
        'invalid port width',
        'invalid port width',
        'invalid domain',
        'invalid domain',
        'invalid type alias',
        'invalid type alias',
        'invalid resolved type kind',
        'type facts require an alias',
        'record requires scalar field metadata',
        'record requires scalar field metadata',
        'unknown metadata key',
        'invalid or duplicate field path',
        'invalid or duplicate field path',
        'field ranges do not form ordered packed layout',
        'field ranges do not form ordered packed layout',
        'field ranges do not form ordered packed layout',
        'field ranges do not form ordered packed layout',
        'record field layout does not cover the port',
        'invalid scalar field signed property',
        'invalid scalar field state model',
        'invalid or duplicate port name',
        'inputs must precede outputs',
        'invalid port width',
        'invalid resolved type kind',
    );
    is(scalar @bad, scalar @reasons, 'every malformed snapshot declares its complete intended cause');
    for my $index (0 .. $#bad) {
        my $bad = $bad[$index];
        rejects(sub { snapshot_interface_port_metadata($bad) }, "malformed snapshot $index", $bad, $reasons[$index]);
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
        my $value = source_copy($record_interface, 'invalid producer seed');
        $change->($value);
        push @bad, $value;
    }
    my $cycle = {kind => 'record', width => 1, member_order => ['loop'], members => {}};
    $cycle->{members}{loop} = $cycle;
    push @bad, {inputs => [{name => 'cycle', width => 1, type => 'cycle_t', type_spec => $cycle}], outputs => []};
    my @reasons = (
        'expected inputs array',
        'expected declared port',
        'invalid declared port name',
        'invalid declared port width',
        "port 'packet' type width disagrees",
        "port 'packet' lacks resolved type",
        'resolved aggregate width disagrees with members',
        'invalid or duplicate record member',
        'invalid resolved state model',
        'invalid resolved signed property',
        "port 'packet' has type facts without an alias",
        'list-root interface metadata remains unsupported',
        'cyclic resolved type',
    );
    is(scalar @bad, scalar @reasons, 'every invalid producer input declares its complete intended cause');
    for my $index (0 .. $#bad) {
        my $bad = $bad[$index];
        rejects(sub { capture_interface_port_metadata($bad) }, 'invalid producer input', undef, $reasons[$index]);
    }
    delete $cycle->{members}{loop};
};

done_testing();

sub rejects {
    my ($operation, $label, $value, $reason) = @_;
    die 'expected metadata cause is required' unless defined($reason) && !ref($reason) && length($reason);
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $ok = eval { $operation->(); 1 };
    my $error = $@;
    diag($json->encode($value)) if $ok && defined $value;
    ok(!$ok, "$label fails closed");
    ok(diagnostic_cause_matches($error, "Invalid ISF interface port metadata: $reason"),
        'contextual bounded diagnostic');
    is_deeply(\@warnings, [], 'invalid metadata does not emit incidental Perl warnings');
}

sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die $!;
    print {$fh} $text or die $!;
    close $fh or die $!;
}
