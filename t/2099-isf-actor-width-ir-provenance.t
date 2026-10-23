use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use FSM::Test::WidthIR qw(width_ir_actor width_ir_products);
use FSM::Scheduler::ISF;

my $json = JSON::PP->new->canonical;
my $products = width_ir_products();
my $scope = {kind => 'actor', owner => 'width_ir'};

sub source {
    my ($token, $kind, $owner) = @_;
    return {token => $token, kind => $kind // 'actor_parameter', owner => $owner // 'width_ir'};
}

subtest 'physical actor declarations retain exact lexical associations' => sub {
    my %expected;
    for my $row (
        [data => 'W'], [alias_data => 'ALIAS'], [other_data => 'OTHER'],
        [fixed_data => 'FIXED', 'actor_constant'],
        [package_data => 'shared.WIDTH', 'package_constant', 'shared'],
        [collision_data => 'word_t'], [result => 'W'],
    ) {
        my ($name, @source) = @$row;
        $expected{$name} = {scope => $scope, source => source(@source),
            declaration => {kind => 'interface', name => $name,
                direction => $name eq 'result' ? 'output' : 'input'}};
    }
    for my $row (
        [saved => 'ALIAS'], [fixed_saved => 'FIXED', 'actor_constant'],
        [package_saved => 'shared.WIDTH', 'package_constant', 'shared'],
    ) {
        my ($name, @source) = @$row;
        $expected{$name} = {scope => $scope, source => source(@source),
            declaration => {kind => 'storage', storage_kind => 'var', name => $name}};
    }
    for my $index (0, 1) {
        $expected{"mem_$index"} = {scope => $scope, source => source('OTHER'),
            declaration => {kind => 'storage', storage_kind => 'bank', name => 'mem', index => $index}};
    }
    is($json->encode($products->{actor}{ir}{_width_declarations}), $json->encode(\%expected),
        'whole map binds only authored symbolic declarations to actual physical signals and bank indices');
    is_deeply($products->{plain}{ir}{_width_declarations}, {},
        'literal, implicit and named-type declarations gain no invented dependencies');
    is($products->{actor}{ir}{signal_widths}{collision_data}, 16,
        'scalar width namespace stays distinct from same-named eight-bit type');
    is($products->{actor}{ir}{signal_widths}{typed_data}, 8, 'named type stays unchanged');
    is($products->{actor}{ir}{reset_values}{saved}, 3, 'reset stays unchanged');
};

subtest 'canonical lexical environments preserve aliases, shadows and primitive kinds' => sub {
    my $expected = {
        actor => {owner => 'width_ir',
            params => [
                {name => 'W', value => '8'}, {name => 'ALIAS', value => 'W', resolved_value => '8'},
                {name => 'OTHER', value => '8'}, {name => 'D', value => '2'},
                {name => 'WD', value => '3'}, {name => 'word_t', value => '16'},
            ],
            constants => [{name => 'FIXED', value => '8', resolved_value => '8'}],
            package_imports => ['shared'],
            package_constants => {shared => {WIDTH => {kind => 'scalar', payload => 8}}},
            enum_symbols => {local => {}, packages => {shared => {}}},
        },
        transactions => {main => {owner => 'main', actor => 'width_ir', params => [
            {name => 'W', value => '4'}, {name => 'ALIAS', value => 'W', resolved_value => '4'},
        ]}},
    };
    is($json->encode($products->{actor}{ir}{_width_scopes}), $json->encode($expected),
        'complete scoped declarations preserve authored aliases separately from resolved defaults');
    is_deeply($products->{actor}{ir}{_width_static_uses}, {
        scope => $scope, watchdog => source('WD'), storage_depths => {mem => source('D')},
        library_overrides => {},
    }, 'watchdog and bank depth keep independent source slots beside width records');
    is_deeply($products->{plain}{ir}{_width_static_uses}, {
        scope => {kind => 'actor', owner => 'plain_width_ir'},
        storage_depths => {}, library_overrides => {},
    }, 'literal static uses acquire no source dependency');
};

subtest 'snapshots and source identity are detached from physical module names' => sub {
    my $actor = width_ir_actor('actor');
    is($actor->{_width_source_actor_name}, 'width_ir', 'parser captures original actor identity');
    $actor->{actor_name} = 'renamed_width_module';
    my $before = $json->encode($actor);
    my $lowerer = FSM::Scheduler::ISF->new->{ir};
    my $first = $lowerer->build_module($actor);
    my $second = $lowerer->build_module($actor);
    is($json->encode($actor), $before, 'both IR builds preserve complete caller and JSON kinds');
    is($first->{_width_scopes}{actor}{owner}, 'width_ir', 'scope uses original actor, not renamed module');
    is_deeply($first->{_width_declarations}{data}{scope}, $scope, 'declaration keeps original scope');
    my $second_before = $json->encode($second);
    $first->{_width_declarations}{mem_0}{source}{token} = 'WRONG';
    $first->{_width_scopes}{actor}{params}[0]{value} = '99';
    $first->{_width_scopes}{transactions}{main}{params}[0]{value} = '99';
    $first->{_width_scopes}{actor}{package_constants}{shared}{WIDTH}{payload} = 99;
    $first->{_width_static_uses}{storage_depths}{mem}{token} = 'WRONG';
    is($first->{_width_declarations}{mem_1}{source}{token}, 'OTHER', 'bank element sources are independent');
    is($first->{params}[0]{value}, '8', 'environment does not share old IR parameter records');
    is($json->encode($second), $second_before, 'independent returned modules share no mutable metadata');
    is($json->encode($actor), $before, 'metadata mutations cannot change source input');
    is($json->encode($lowerer->build_module($actor)), $second_before, 'fresh build is unaffected');
    for my $case (qw(actor plain)) {
        ok($products->{$case}{caller_unchanged}, "$case lower/report preserve whole caller");
        unlike($products->{$case}{report}, qr/_width_(?:scopes|declarations|static_uses|source_actor_name)/,
            "$case private metadata does not leak into schedule report");
        unlike(join('', values %{$products->{$case}{files}}), qr/_width_(?:scopes|declarations|static_uses|source_actor_name)/,
            "$case private metadata does not leak into carriers");
    }
};

done_testing;
