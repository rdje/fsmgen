use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use FSM::Test::FormalWidthIR qw(formal_width_actor formal_width_products);
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;

my $json = JSON::PP->new->canonical;
my $products = formal_width_products();
my @rows = (
    ['left', 'data', 'isf_port_left_data_formal', 'input', 'ALIAS', 'transaction_parameter', 'left', 4],
    ['left', 'saved', 'isf_port_left_saved', 'input', 'W', 'transaction_parameter', 'left', 4],
    ['left', 'equal_data', 'isf_port_left_equal_data', 'input', 'OTHER', 'transaction_parameter', 'left', 4],
    ['left', 'inherited_data', 'isf_port_left_inherited_data', 'input', 'ACTOR_ALIAS', 'actor_parameter', 'formal_width_ir', 8],
    ['left', 'fixed_data', 'isf_port_left_fixed_data', 'input', 'FIXED', 'actor_constant', 'formal_width_ir', 8],
    ['left', 'package_data', 'isf_port_left_package_data', 'input', 'shared.WIDTH', 'package_constant', 'shared', 8],
    ['left', 'collision_data', 'isf_port_left_collision_data', 'input', 'word_t', 'transaction_parameter', 'left', 4],
    ['left', 'N', 'isf_port_left_N', 'input', 'W', 'transaction_parameter', 'left', 4],
    ['left', 'result', 'isf_port_left_result', 'output', 'W', 'transaction_parameter', 'left', 4],
    ['right', 'data', 'isf_port_right_data', 'input', 'ALIAS', 'transaction_parameter', 'right', 6],
    ['right', 'result', 'isf_port_right_result', 'output', 'W', 'transaction_parameter', 'right', 6],
);

sub expected_formal {
    my ($actor, $tx, $name, $direction, $token, $kind, $owner) = @_;
    return {scope => {kind => 'transaction', actor => $actor, owner => $tx},
        source => {token => $token, kind => $kind, owner => $owner},
        declaration => {kind => 'transaction_port', name => $name, direction => $direction,
            identity => ['transaction_port', $actor, $tx, $name]}};
}

subtest 'actual direct-formal allocations retain literal independent source associations' => sub {
    my $ir = $products->{scopes}{ir};
    my %expected;
    for my $name (qw(data N result)) {
        $expected{$name} = {scope => {kind => 'actor', owner => 'formal_width_ir'},
            source => {token => 'W', kind => 'actor_parameter', owner => 'formal_width_ir'},
            declaration => {kind => 'interface', name => $name, direction => $name eq 'result' ? 'output' : 'input'}};
    }
    $expected{saved} = {scope => {kind => 'actor', owner => 'formal_width_ir'},
        source => {token => 'ACTOR_ALIAS', kind => 'actor_parameter', owner => 'formal_width_ir'},
        declaration => {kind => 'storage', storage_kind => 'var', name => 'saved'}};
    for my $row (@rows) {
        my ($tx, $name, $physical, $direction, $token, $kind, $owner, $width) = @$row;
        $expected{$physical} = expected_formal('formal_width_ir', $tx, $name, $direction, $token, $kind, $owner);
        is($products->{scopes}{context}{plan}{formals}{$tx}{$name}{physical_name}, $physical,
            "$tx.$name has the independently expected actual allocation");
        is($ir->{signal_widths}{$physical}, $width, "$tx.$name keeps its actual width");
        is($ir->{storage_roles}{$physical}, 'transaction_port', "$tx.$name stays a private formal");
    }
    is($json->encode($ir->{_width_declarations}), $json->encode(\%expected),
        'complete map binds original declarations, scopes and source kinds to actual physical keys');
    is($ir->{signal_widths}{isf_port_left_data}, 1, 'reserved actor signal keeps its own width');
    is($ir->{signal_widths}{isf_port_left_typed_data}, 8, 'named type keeps its separate eight-bit meaning');
    is_deeply($products->{literals}{ir}{_width_declarations}, {},
        'literal, implicit and named-type formals gain no symbolic dependencies');
};

subtest 'lexical aliases and count/value namespaces stay separate' => sub {
    my $row = $products->{scopes};
    my $scopes = $row->{ir}{_width_scopes};
    is($json->encode($scopes->{actor}{params}),
        '[{"name":"W","value":"8"},{"name":"ACTOR_ALIAS","resolved_value":"8","value":"W"},{"name":"OTHER","value":"8"},{"name":"word_t","value":"16"}]',
        'actor defaults retain the authored alias and primitive kinds');
    is($json->encode($scopes->{transactions}{left}{params}),
        '[{"name":"W","value":"4"},{"name":"ALIAS","resolved_value":"4","value":"W"},{"name":"OTHER","value":"4"},{"name":"word_t","value":"4"},{"name":"N","value":"2"}]',
        'left scope retains distinct equal defaults, aliases and count default');
    is($json->encode($scopes->{transactions}{right}{params}),
        '[{"name":"W","value":"6"},{"name":"ALIAS","resolved_value":"6","value":"W"}]',
        'sibling scope keeps its own defaults');
    my $repeat = $row->{context}{actor}{transactions}[0]{clauses}[3];
    is_deeply($repeat, ['repeat', 'N', ['update', 'isf_port_left_result', 'isf_port_left_N']],
        'static count token stays distinct from the same-spelled runtime formal in the body');
    is($row->{ir}{signal_widths}{N}, 8, 'actor pin keeps eight bits');
    is($row->{ir}{signal_widths}{isf_port_left_N}, 4, 'private value formal keeps four bits');
};

subtest 'parent capture excludes generated-child formals' => sub {
    my $row = $products->{mixed};
    is_deeply($row->{ir}{_width_declarations}{isf_port_parent_data},
        expected_formal('mixed_formal_width_ir', 'parent', 'data', 'input', 'ALIAS', 'actor_parameter', 'mixed_formal_width_ir'),
        'actual direct parent formal retains its actor-derived alias');
    is_deeply([sort keys %{$row->{ir}{_width_declarations}}], [qw(data isf_port_parent_data)],
        'parent has only its authored actor port and live direct formal');
    ok(!exists $row->{ir}{children}{worker}{_width_declarations},
        'generated child propagation stays with its own successor');
};

subtest 'formal metadata is detached from original inputs, sibling results and old IR records' => sub {
    for my $case (qw(scopes literals mixed)) {
        ok($products->{$case}{caller_unchanged}, "$case preserves the whole source caller and kinds");
        ok($products->{$case}{physical_unchanged}, "$case preserves the whole physical caller and kinds");
        unlike($products->{$case}{report}, qr/_width_(?:scopes|declarations|static_uses|source_actor_name)/,
            "$case private metadata stays out of schedule JSON");
    }
    my $source = formal_width_actor('scopes');
    my $scheduler = FSM::Scheduler::ISF->new;
    my $context = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $source);
    # Renaming a prepared physical module must not rename lexical identities.
    $context->{actor}{actor_name} = 'renamed_formal_width_module';
    my $before = $json->encode($context->{actor});
    my $first = $scheduler->{ir}->build_module($context->{actor});
    my $second = $scheduler->{ir}->build_module($context->{actor});
    my $second_before = $json->encode($second);
    my $data = $first->{_width_declarations}{isf_port_left_data_formal};
    is_deeply($data, expected_formal('formal_width_ir', 'left', 'data', 'input', 'ALIAS', 'transaction_parameter', 'left'),
        'actual allocation mark and original actor survive a physical module rename');
    $data->{declaration}{identity}[3] = 'WRONG';
    $data->{source}{token} = 'WRONG';
    $data->{scope}{owner} = 'WRONG';
    $first->{_width_scopes}{transactions}{left}{params}[0]{value} = '99';
    is($first->{_width_scopes}{transactions}{right}{params}[0]{value}, '6', 'sibling lexical environment stays detached');
    is($first->{_width_declarations}{isf_port_right_data}{source}{token}, 'ALIAS', 'sibling source stays detached');
    is($json->encode($context->{actor}), $before, 'metadata mutation cannot change physical source/identity marks');
    is($json->encode($second), $second_before, 'another returned module remains unchanged');
    is($json->encode($scheduler->{ir}->build_module($context->{actor})), $second_before, 'fresh module retains original complete data');
};

done_testing;
