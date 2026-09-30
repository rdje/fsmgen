use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# Supply finalized record facts at the real parser phase boundary. This does
# not change source admission or replace any production validator.
{
    package RecordGatePipelineProbe;
    use parent 'FSM::Adapter::ISF::Parser';
    sub _finalize_actor_type_references {
        my ($self, $actor) = @_;
        $self->SUPER::_finalize_actor_type_references($actor);
        my ($packet) = grep { $_->{name} eq 'packet' } @{$actor->{storage}};
        $actor->{storage} = [grep { $_->{name} ne 'packet' } @{$actor->{storage}}];
        my %port = map { $_ => $packet->{$_} } qw(name width type type_spec);
        push @{$actor->{interface}{inputs}}, Storable::dclone(\%port);
        return 1;
    }
}

my $parser = FSM::Adapter::ISF->new;
my $probe = RecordGatePipelineProbe->new;
my $scheduler = FSM::Scheduler::ISF->new;
my $json = JSON::PP->new->canonical;
my $header = <<'ISF';
(actor record_gates
 (types (type frame (record (flag bit) (data (signed (four_state (bits 7))))))
  (type alias frame) (type other (record (flag bit) (data (bits 7)))))
 (enums (packet (OTHER 1)) (mode (ON 1)))
 (interface (input start) (input scalar (width 8)) (input mode) (output seen (width 8)) (output done))
 (storage (var packet (type frame)) (var held (type alias)) (var mismatch (type other)))
ISF
sub first_error {
    my ($run) = @_;
    my $ok = eval { $run->(); 1 };
    my ($line) = split /\n/, $@;
    return ($ok, $line // '');
}
sub pipeline {
    return $probe->parse_source($header . $_[0] . ')', 'record-gate-pipeline.isf');
}
sub supplied {
    my $actor = $parser->parse_source($header
        . '(transaction main (on start) (complete done)))', 'record-gate-supplied.isf');
    my $packet = shift @{$actor->{storage}};
    push @{$actor->{interface}{inputs}}, {map {$_ => $packet->{$_}} qw(name width type type_spec)};
    $actor->{transactions}[0]{clauses} = dclone($_[0]);
    return $actor;
}

subtest 'actual parser phases distinguish records from enum namespaces' => sub {
    for my $case (
        ['transaction leaf', '(transaction main (on start) (set seen packet.data) (complete done))'],
        ['update leaf', '(transaction main (on start) (update seen packet.data) (complete done))'],
        ['inline drive', '(transaction main (on start) (drive (seen packet.data)) (complete done))'],
        ['nested leaf', '(transaction main (on start) (when packet.flag (set seen packet.data[3:1])) (complete done))'],
        ['same type copy', '(transaction main (on start) (set held packet) (complete done))'],
        ['rule', '(rule observe packet.flag (seen packet.data))'],
        ['named drive', '(drive publish (seen packet.data)) (transaction main (on start) (drive publish) (complete done))'],
        ['scalar parameter mask', '(drive (publish packet) (seen packet)) (transaction main (on start) (drive publish scalar) (complete done))'],
        ['nearest scalar formal', '(transaction main (ports (input packet (width 3))) (on start) (set seen packet[2:1]) (complete done))'],
        ['sample', '(transaction main (on start (sample packet.data as held_leaf)) (set seen held_leaf) (complete done))'],
        ['scalar enum namespace', '(transaction main (on start) (when mode.ON (set seen packet.data)) (complete done))'],
    ) {
        my ($label, $body) = @$case;
        my ($ok, $error) = first_error(sub { pipeline($body) });
        ok($ok, "$label passes all actual parser phases") or diag($error);
    }
    my $actor;
    my ($metadata_ok, $metadata_error) = first_error(sub {
        $actor = pipeline('(rule observe packet.flag (seen packet.data))');
    });
    ok($metadata_ok, 'actual parser reaches its final metadata producer') or diag($metadata_error);
    if ($actor) {
        my ($port) = grep { $_->{name} eq 'packet' } @{$actor->{interface_port_metadata}};
        is_deeply([map { [@{$_}{qw(path width lsb msb signed)}] } @{$port->{fields}}],
            [['flag', 1, 7, 7, 0], ['data', 7, 0, 6, 1]], 'actual final metadata retains independently authored layout');
        is($port->{type_kind}, 'record', 'actual final metadata keeps record identity');
    }
    my ($ok, $error) = first_error(sub { pipeline('(rule observe missing (seen packet.data))') });
    ok(!$ok, 'undeclared ordinary rule operand remains refused');
    like($error, qr/has undeclared rule read operands/, 'existing rule operand validator still owns unknown tokens');
};

subtest 'actual parser phase gate rejects each selected invalid context' => sub {
    for my $case (
        ['unknown member', '(transaction main (on start) (set seen packet.missing))', qr/invalid declared path 'packet.missing': unknown_member/],
        ['input field write', '(transaction main (on start) (set packet.data 1))', qr/cannot write declared input 'packet.data'/],
        ['whole scalar', '(transaction main (on start) (when packet (set seen 1)))', qr/requires a scalar value.*whole record port/],
        ['mismatched copy', '(transaction main (on start) (set mismatch packet))', qr/requires the same resolved record type/],
        ['whole to scalar', '(transaction main (on start) (set seen packet))', qr/whole record port copy requires declared record roots/],
        ['operator member', '(transaction main (on start) (set seen (packet.data 1)))', qr/operator cannot use declared aggregate reference/],
        ['unsupported await', '(transaction main (on start) (await packet.flag))', qr/does not admit record port reference 'packet.flag'/],
        ['rule input write', '(rule observe start (packet.data 1))', qr/cannot write declared input 'packet.data'/],
        ['drive input write', '(drive publish (packet.data 1))', qr/cannot write declared input 'packet.data'/],
        ['sample input alias', '(transaction main (on start (sample scalar as packet)) (complete done))', qr/cannot write declared input 'packet'/],
        ['inline input write', '(transaction main (on start) (drive (packet.data 1)))', qr/cannot write declared input 'packet.data'/],
        ['masked formal member', '(transaction main (ports (input packet (width 3))) (on start) (set seen packet.data))', qr/member_on_non_record/],
    ) {
        my ($label, $body, $pattern) = @$case;
        my ($ok, $error) = first_error(sub { pipeline($body) });
        ok(!$ok, "$label refuses before a parsed success");
        like($error, $pattern, "$label names its first diagnostic cause");
    }
};

subtest 'formal and executable source preparation share contextual admission' => sub {
    my @cases = (
        ['input field write', [['set', 'packet.data', 1]], qr/cannot write declared input 'packet.data'/],
        ['unknown member', [['set', 'seen', 'packet.missing']], qr/unknown_member/],
        ['whole scalar', [['when', 'packet', ['set', 'seen', 1]]], qr/requires a scalar value.*whole record port/],
        ['mismatched copy', [['set', 'mismatch', 'packet']], qr/requires the same resolved record type/],
        ['unsupported wait', [['await', 'packet.flag']], qr/does not admit record port reference 'packet.flag'/],
    );
    for my $method (qw(prepare_formal_source build_module)) {
        for my $case (@cases) {
            my ($label, $clauses, $pattern) = @$case;
            my $actor = supplied($clauses);
            my $before = $json->encode($actor);
            my ($ok, $error) = first_error(sub { $scheduler->{ir}->$method($actor) });
            ok(!$ok, "$method $label refuses before a product");
            like($error, $pattern, "$method $label names its first cause");
            is($json->encode($actor), $before, "$method $label preserves complete caller JSON");
        }
        my $actor = supplied([['on', 'start'], ['set', 'held', 'packet'], ['set', 'seen', 'packet.data'], ['complete', 'done']]);
        my $before = $json->encode($actor);
        my ($ok, $error) = first_error(sub { $scheduler->{ir}->$method($actor) });
        ok($ok, "$method valid copy and scalar read pass") or diag($error);
        is($json->encode($actor), $before, "$method valid source stays detached");
    }
};

subtest 'ordinary public authoring still refuses record ports' => sub {
    my $source = $header;
    $source =~ s/\(var packet \(type frame\)\)//;
    $source =~ s/\(input start\)/\(input start\) \(input packet \(type frame\)\)/;
    my ($ok, $error) = first_error(sub { $parser->parse_source($source . ')', 'still-refused.isf') });
    ok(!$ok, 'public record source has no early partial admission');
    like($error, qr/interface port 'packet' references aggregate type 'frame'/,
        'existing aggregate-port refusal stays precise');
};

done_testing;
