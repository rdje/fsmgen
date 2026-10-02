use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use Carp qw(confess);
use Storable qw(dclone);
use JSON::PP;
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Package::PayloadTypeSupport;
use FSM::Support::ISFRecordPortValues qw(
    record_value_scope record_value_reference validate_record_port_copy
);

my $parser = FSM::Adapter::ISF->new;
my $actor = $parser->parse_source(<<'ISF', 'record-value-controls.isf');
(actor controls
  (types
    (type frame (record (flag bit) (data (bits 7))))
    (type alias frame)
    (type renamed (record (tag bit) (data (bits 7))))
    (type reordered (record (data (bits 7)) (flag bit)))
    (type signed_data (record (flag bit) (data (signed (bits 7)))))
    (type four (record (flag bit) (data (four_state (bits 7)))))
    (type two (record (flag bit) (data (two_state (bits 7)))))
    (type bit_kind (record (flag (bits 1)) (data (bits 7))))
    (type nested (record (header (bits 2))
      (body (record (count (signed (four_state (bits 3))))
        (lanes (list (two_state bit) (bits 2)))))))
    (type flat (record (header (bits 2)) (count (signed (four_state (bits 3))))
      (lane0 (two_state bit)) (lane1 (bits 2))))
    (type lanes (list bit (bits 2))))
  (interface (input start) (output done))
  (storage (var a (type frame)) (var b (type alias)) (var c (type renamed))
    (var d (type reordered)) (var e (type signed_data)) (var f (type four))
    (var g (type two)) (var h (type bit_kind)) (var i (type nested))
    (var j (type flat)) (var k (type lanes)))
  (transaction main (on start) (complete done)))
ISF
my %types = map { $_->{type} => $_->{type_spec} } @{$actor->{storage}};
my $scalar = {kind => 'bits', width => 7, signed => 0};

subtest 'validation preserves caller JSON kinds on first touch' => sub {
    my $json = JSON::PP->new->canonical;
    my $string_frame = $json->decode('{"kind":"record","width":"8","signed":0,"member_order":["flag","data"],'
        . '"members":{"flag":{"kind":"bit","width":"1","signed":0},'
        . '"data":{"kind":"bits","width":"7","signed":0}}}');
    my $roots = {packet => {role => 'input', type_spec => $string_frame}};
    my $before = $json->encode($roots);
    record_value_scope(outer => $roots, local => {});
    is($json->encode($roots), $before, 'scope validation retains original typed JSON');
    my $scope = {packet => {role => 'input', type_spec => $json->decode($before)->{packet}{type_spec}}};
    $before = $json->encode($scope);
    record_value_reference(scope => $scope, token => 'packet.data', access => 'read', context => 'first touch');
    is($json->encode($scope), $before, 'reference validation retains original typed JSON');
    my $source = {root => 'packet', role => 'input', path_text => '', width => '8',
        type_spec => $json->decode($before)->{packet}{type_spec}};
    my $target = dclone($source);
    @{$target}{qw(root role)} = ('held', 'storage');
    $before = $json->encode([$source, $target]);
    validate_record_port_copy(source => $source, target => $target, context => 'first touch');
    is($json->encode([$source, $target]), $before, 'copy validation retains original typed JSON');
};

sub scope_for {
    my ($source_type, $target_type, $local) = @_;
    return record_value_scope(outer => {
        packet => {role => 'input', type_spec => $source_type},
        held => {role => 'storage', type_spec => $target_type},
        output => {role => 'output', type_spec => $target_type},
        scalar => {role => 'output', type_spec => $scalar},
    }, local => $local || {});
}
sub reference {
    my ($scope, $token, $access, $whole) = @_;
    return record_value_reference(scope => $scope, token => $token,
        access => $access || 'read', allow_whole => $whole || 0, context => 'control');
}
sub copy {
    my ($scope, $source, $target) = @_;
    return validate_record_port_copy(source => reference($scope, $source, 'read', 1),
        target => reference($scope, $target, 'write', 1), context => 'copy control');
}
sub refuses {
    my ($run, $pattern, $name) = @_;
    my $ok = eval { $run->(); 1 };
    my $diagnostic = diagnostic_line($@);
    ok(!$ok, "$name refuses");
    like($diagnostic, $pattern, "$name names the cause in its diagnostic line");
}
sub diagnostic_line { (split /\n/, $_[0] // '')[0] // '' }
sub wrong_cause_with_pattern_in_stack {
    my ($expected) = @_;
    eval { confess "Deliberately wrong diagnostic\n" };
    return $@;
}

subtest 'diagnostic oracle rejects an expected pattern present only in the stack' => sub {
    my $error = wrong_cause_with_pattern_in_stack(qr/expected_cause_only_in_argument/);
    like($error, qr/expected_cause_only_in_argument/, 'known bad full trace contains the caller pattern');
    is(diagnostic_line($error), 'Deliberately wrong diagnostic', 'oracle selects the actual message');
    unlike(diagnostic_line($error), qr/expected_cause_only_in_argument/,
        'the same false cause cannot satisfy the diagnostic oracle');
};

subtest 'resolved alias identity and allowed root roles' => sub {
    my $scope = scope_for($types{frame}, $types{alias});
    ok(copy($scope, 'packet', 'held'), 'input to owner storage accepts resolved alias equivalence');
    ok(copy($scope, 'held', 'output'), 'prepared storage to output contract accepts identity');
    ok(copy($scope, 'packet', 'output'), 'prepared input to output contract accepts identity');
    my $source = reference($scope, 'packet', 'read', 1);
    my $target = reference($scope, 'packet', 'read', 1);
    refuses(sub { validate_record_port_copy(source => $source, target => $target,
        context => 'forged write') }, qr/forged write cannot write declared input 'packet'/,
        'copy independently enforces target role');
    refuses(sub { reference($scope, 'packet', 'write', 1) }, qr/cannot write declared input 'packet'/,
        'whole input target');
    refuses(sub { reference($scope, 'packet.data', 'write') }, qr/cannot write declared input 'packet.data'/,
        'scalar input target');
    ok(reference($scope, 'output.data', 'write'), 'prepared scalar output target retains allowed role');
    my $before = dclone($actor);
    $scope->{packet}{type_spec}{members}{data}{width} = 99;
    is_deeply($actor, $before, 'prepared scope does not share parser types');
};

subtest 'same packed width does not establish record identity' => sub {
    for my $name (qw(renamed reordered signed_data four two bit_kind)) {
        is($types{$name}{width}, 8, "$name has independently expected equal packed width");
        my $scope = scope_for($types{frame}, $types{$name});
        refuses(sub { copy($scope, 'packet', 'held') }, qr/requires the same resolved record type/,
            "$name copy identity");
    }
    my $scope = scope_for($types{four}, $types{two});
    refuses(sub { copy($scope, 'packet', 'held') }, qr/requires the same resolved record type/,
        'explicit state-model difference');
    for my $name (qw(signed_data four two bit_kind)) {
        ok(FSM::Package::PayloadTypeSupport->payload_compatible_with_type_spec($types{frame}, $types{$name}),
            "$name retains the established payload compatibility contract");
    }
    my $nested_scope = scope_for($types{nested}, $types{flat});
    is($types{nested}{width}, 8, 'independent nested packed width');
    is($types{flat}{width}, 8, 'independent flattened packed width');
    refuses(sub { copy($nested_scope, 'packet', 'held') }, qr/requires the same resolved record type/,
        'nested shape cannot be flattened for copy identity');
    my $swapped = dclone($types{nested});
    @{$swapped->{members}{body}{members}{lanes}{items}} =
        reverse @{$swapped->{members}{body}{members}{lanes}{items}};
    my $list_scope = scope_for($types{nested}, $swapped);
    refuses(sub { copy($list_scope, 'packet', 'held') }, qr/requires the same resolved record type/,
        'nested list item order retains type identity');
};

subtest 'core scalar paths retain exact packed range and property facts' => sub {
    my $scope = scope_for($types{nested}, $types{nested});
    is_deeply(reference($scope, 'packet.body.count'), {
        root => 'packet', role => 'input', path_text => '.body.count',
        type_spec => {kind => 'bits', width => 3, signed => 1, state_model => 'four_state'},
        width => 3, low => 3, high => 5,
    }, 'independent nested signed/four-state leaf range');
    is_deeply(reference($scope, 'packet.body.lanes[0]'), {
        root => 'packet', role => 'input', path_text => '.body.lanes[0]',
        type_spec => {kind => 'bit', width => 1, signed => 0, state_model => 'two_state'},
        width => 1, low => 2, high => 2,
    }, 'independent nested list-item leaf range');
    my $leaf = reference($scope, 'packet.body.count');
    $leaf->{type_spec}{signed} = 0;
    is(reference($scope, 'packet.body.count')->{type_spec}{signed}, 1,
        'leaf results do not share scope facts');
    for my $pair (
        ['packet', qr/requires a scalar value/],
        ['packet.body', qr/requires a scalar leaf/],
        ['packet.body.lanes', qr/requires a scalar leaf/],
        ['packet.unknown', qr/invalid declared path.*unknown_member/],
        ['packet.body.lanes[2]', qr/invalid declared path.*list_index_out_of_range/],
        ['packet.body.count[3]', qr/invalid declared path.*scalar_index_out_of_range/],
        ['packet..count', qr/invalid declared path.*parse_error/],
    ) {
        refuses(sub { reference($scope, $pair->[0]) }, $pair->[1], $pair->[0]);
    }
    refuses(sub { reference($scope, 'held.body', 'write', 1) }, qr/requires a scalar leaf/,
        'whole-value permission does not allow subaggregate writes');
};

subtest 'nearest lexical declarations mask outer type and role facts' => sub {
    my $unresolved = scope_for($types{frame}, $types{frame}, {
        packet => {role => 'local', type_spec => undef},
    });
    is(reference($unresolved, 'packet.data'), undef, 'unresolved local masks the outer record type');
    my $formal = scope_for($types{frame}, $types{frame}, {
        packet => {role => 'output', type_spec => $types{nested}},
    });
    my $leaf = reference($formal, 'packet.body.count', 'write');
    is($leaf->{role}, 'output', 'nearest formal output is writable despite outer input name');
    is($leaf->{width}, 3, 'formal type owns local path width');
    refuses(sub { reference($formal, 'packet.data') }, qr/unknown_member/,
        'formal does not borrow an outer member');
    my $scalar_shadow = scope_for($types{frame}, $types{frame}, {
        packet => {role => 'local', type_spec => $scalar},
    });
    is(reference($scalar_shadow, 'packet', 'write')->{width}, 7,
        'scalar local retains its width and writable role');
    refuses(sub { reference($scalar_shadow, 'packet.data') }, qr/member_on_non_record/,
        'scalar local cannot borrow an outer record');
    is_deeply(reference($scalar_shadow, 'packet[5:3]', 'write'), {
        root => 'packet', role => 'local', path_text => '[5:3]',
        type_spec => {kind => 'bits', width => 3, signed => 0},
        width => 3, low => 3, high => 5,
    }, 'scalar local slice retains core range and writable local role');
    is(reference($scalar_shadow, 'packet[0]')->{width}, 1,
        'scalar local bit index stays scalar');
    my $unresolved_input = scope_for($types{frame}, $types{frame}, {
        packet => {role => 'input', type_spec => undef},
    });
    refuses(sub { reference($unresolved_input, 'packet', 'write') }, qr/cannot write declared input/,
        'an unresolved type cannot erase a known input role');
    is(reference($formal, 'mode.BUSY'), undef, 'unrelated enum roots stay with existing enum validation');
    is(reference($formal, 'shared.CONSTANT'), undef, 'unrelated package roots stay with package validation');
};

subtest 'record copy gates preserve existing scalar and storage-only contracts' => sub {
    my $scope = scope_for($types{frame}, $types{signed_data});
    $scope->{old} = {role => 'storage', type_spec => dclone($types{frame})};
    is(copy($scope, 'old', 'held'), 0, 'different storage-only types use the prior assignment contract');
    is(copy($scope, 'scalar', 'scalar'), 0, 'scalar ports introduce no record copy obligation');
    is(validate_record_port_copy(source => undef, target => undef, context => 'literal'), 0,
        'unrelated literal/expression handling remains with caller');
    refuses(sub { copy($scope, 'scalar', 'output') }, qr/requires declared record roots/,
        'equal/unequal scalar carrier is not a record copy');
    refuses(sub { validate_record_port_copy(source => undef,
        target => reference($scope, 'output', 'write', 1), context => 'expression') },
        qr/requires declared record roots/, 'record target cannot treat an expression as a same-type root');
    $scope->{lanes} = {role => 'storage', type_spec => dclone($types{lanes})};
    is(reference($scope, 'lanes[1]')->{width}, 2, 'existing list storage scalar leaves remain resolvable');
    refuses(sub { copy($scope, 'lanes', 'output') }, qr/requires declared record roots/,
        'root list is not a same-type record copy');
};

subtest 'imported and local aliases with identical resolved records match' => sub {
    my $work = tempdir(CLEANUP => 1);
    open my $file, '>', "$work/shared.fsm" or die $!;
    print {$file} '(?pkg:shared (+types (type frame (record (flag bit) (data (bits 7))))))';
    close $file or die $!;
    my $imported = $parser->parse_source('(actor imported (imports (package shared))'
        . ' (interface (output done)) (storage (var value (type shared.frame)))'
        . ' (transaction main (complete done)))', "$work/imported.isf");
    my $scope = scope_for($imported->{storage}[0]{type_spec}, $types{frame});
    ok(copy($scope, 'packet', 'held'), 'package spelling does not affect resolved identity');
};

subtest 'closed malformed facts fail before comparison or path traversal' => sub {
    for my $pair (
        ['unknown key', sub { $_[0]{extra} = 1 }, qr/unknown facts/],
        ['bad root width', sub { $_[0]{width} = 9 }, qr/width disagrees/],
        ['bad scalar signed', sub { $_[0]{members}{data}{signed} = 2 }, qr/signed property/],
        ['missing signed', sub { delete $_[0]{members}{data}{signed} }, qr/lacks required facts/],
        ['aggregate signed', sub { $_[0]{signed} = 1 }, qr/scalar signed overlay/],
        ['aggregate state', sub { $_[0]{state_model} = 'two_state' }, qr/unknown facts/],
        ['bad state', sub { $_[0]{members}{data}{state_model} = 'unknown' }, qr/state model/],
        ['duplicate order', sub { $_[0]{member_order} = [qw(flag flag)] }, qr/duplicate record member/],
        ['unlisted member', sub { $_[0]{members}{extra} = dclone($scalar) }, qr/inventory disagrees/],
        ['cyclic member', sub { $_[0]{members}{data} = $_[0] }, qr/cyclic resolved type/],
        ['deferred kind', sub { $_[0]{kind} = 'deferred_imported_alias' }, qr/unsupported resolved type kind/],
    ) {
        my $spec = dclone($types{frame});
        $pair->[1]->($spec);
        refuses(sub { scope_for($spec, $types{frame}) }, $pair->[2], $pair->[0]);
    }
    refuses(sub { record_value_scope(outer => {packet => {role => 'inout', type_spec => $types{frame}}},
        local => {}) }, qr/invalid role/, 'unknown role');
    refuses(sub { record_value_scope(outer => {}, local => {}, surprise => 1) }, qr/unknown facts/,
        'unknown scope argument');
    my $scope = scope_for($types{frame}, $types{frame});
    refuses(sub { record_value_reference(scope => $scope, token => 'packet', access => 'read',
        context => 'permission', allow_whole => 2) }, qr/whole-value permission/,
        'nonbinary whole-value permission');
    my $value = reference($scope, 'packet', 'read', 1);
    $value->{width} = 9;
    refuses(sub { validate_record_port_copy(source => $value,
        target => reference($scope, 'held', 'write', 1), context => 'hostile') }, qr/width disagrees/,
        'contradictory copy descriptor');
};

subtest 'output member writes and list-root source carriers remain closed' => sub {
    for my $pair (
        ['output', 'frame', '(set value.flag 1)', qr/record output field writes are not yet admitted/],
        ['input', 'lanes', '(complete done)', qr/interface port 'value' references aggregate type/],
    ) {
        my ($direction, $type, $clause, $pattern) = @$pair;
        my $source = '(actor refused (types (type frame (record (flag bit))) (type lanes (list bit bit)))'
            . " (interface ($direction value (type $type)) (output done))"
            . " (transaction main $clause))";
        refuses(sub { $parser->parse_source($source, 'still-refused.isf') }, $pattern,
            "$direction $type source");
    }
};

done_testing;
