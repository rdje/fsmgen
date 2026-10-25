use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $json = JSON::PP->new->canonical;
my %captures;
for my $case (qw(library atl)) {
    my $actor = FSM::Adapter::ISF->new->parse_file("t/data/isf-reusable-width-ir/$case.isf");
    my $before = $json->encode($actor);
    my $lowerer = FSM::Scheduler::ISF->new->{ir};
    my $ir = $lowerer->build_module($actor);
    $captures{$case} = {actor => $json->decode($before), ir => $json->decode($json->encode($ir))};
    subtest "$case constructors preserve source defaults and selected instances" => sub {
        my @sources = $case eq 'library' ? @{$actor->{library_uses}}
            : map {$actor->{_atl_actor_type_resolutions}{$_}} qw(first second);
        for my $index (0 .. $#sources) {
            my $source = $sources[$index];
            my $child = $ir->{children}{$source->{module}};
            my $scope = $child->{_width_scopes}{instance};
            is_deeply($child->{_width_scopes}{module_parameters}, {kind => 'actor', owner => 'child'},
                'reusable module parameters belong to the source export, independent of selected instances');
            my $overridden = $case eq 'library' && $index == 0;
            is_deeply($scope, {
                kind => $case eq 'library' ? 'library_use' : 'atl_static_instance',
                parent_actor => $case eq 'library' ? 'library_widths' : 'atl_widths',
                owner => 'child', library => 'widths', export => 'child',
                instance => $index == 0 ? 'first' : 'second',
                module => $source->{module}, library_source => $source->{library_source},
                parameters => [
                    {name => 'WIDTH', source => $overridden ? 'override' : 'default', value => $overridden ? '16' : '8'},
                    {name => 'ALIAS', source => 'default', value => 'WIDTH'},
                    {name => 'OTHER', source => 'default', value => '8'},
                ],
                parameter_overrides => $overridden ? [{name => 'WIDTH', value => '16'}] : [],
                parameter_override_sources => $overridden
                    ? [{name => 'WIDTH', value => 'LIMIT', owner => 'library_widths'}] : [],
            }, "$source->{instance} has exact source and constructor-selected records");
            is($json->encode($child->{_width_scopes}{actor}{params}),
                '[{"name":"WIDTH","value":"8"},{"name":"ALIAS","resolved_value":"8","value":"WIDTH"},{"name":"OTHER","value":"8"}]',
                'source defaults and resolved default alias remain separate');
            is_deeply([map {[$_->{name}, $_->{width}]} grep {$_->{name} eq 'data' || $_->{name} eq 'result'} @{$child->{ports}}],
                [['data', 8], ['result', 8]], 'shape stays at existing defaults; no specialization is inferred');
            is_deeply($child->{_width_declarations}{data}{source},
                {token => 'WIDTH', kind => 'actor_parameter', owner => 'child'},
                'declaration owner is the source export, not the module name');
        }
        is($json->encode($actor), $before, 'complete caller and primitive kinds remain unchanged');
        my $saved = $json->encode($lowerer->build_module($actor));
        my $first = $ir->{children}{$sources[0]{module}};
        my $second = $ir->{children}{$sources[1]{module}};
        my $sibling = $json->encode($second);
        if (ref($first->{_width_scopes}{instance}) eq 'HASH') {
            $first->{_width_scopes}{instance}{parameters}[0]{value} = '99';
            $first->{_width_scopes}{instance}{parameter_overrides}[0]{value} = '99'
                if $case eq 'library';
            $first->{_width_scopes}{instance}{parameter_override_sources}[0]{value} = 'WRONG'
                if $case eq 'library';
            $first->{_width_scopes}{actor}{params}[0]{value} = '99';
            is($first->{params}[0]{value}, '8', 'executable defaults are detached');
            is($json->encode($second), $sibling, 'sibling metadata is detached');
            is($json->encode($actor), $before, 'source/override records remain detached');
            is($json->encode($lowerer->build_module($actor)), $saved, 'fresh result remains detached');
        }
    };
}
subtest 'generated instance selections stay distinct from shared module defaults' => sub {
    my $actor = FSM::Adapter::ISF->new->parse_file('t/data/isf-reusable-width-ir/generated-instances.isf');
    my $before = $json->encode($actor);
    my $lowerer = FSM::Scheduler::ISF->new->{ir};
    my $ir = $lowerer->build_module($actor);
    $captures{generated} = {actor => $json->decode($before), ir => $json->decode($json->encode($ir))};
    my %expected;
    for my $row (
        ['first', 'spawn', 'parent', 'transaction', 'BASE', 'LIMIT', '16', ['1', '2']],
        ['second', 'spawn', 'parent', 'transaction', 'SAME', '3', '3'],
        ['parent_worker_do_0', 'do', 'parent', 'transaction', 'BASE', '4', '4'],
        ['parent_worker_repeat_do_0', 'do', 'parent', 'transaction', '8', '5', '5'],
        ['parent_worker_cond_do_0', 'do', 'parent', 'transaction', 'SAME', '6', '6'],
        ['kick_worker_trigger_0', 'trigger', 'kick', 'rule', 'BASE', 'LIMIT', '16'],
    ) {
        my ($instance, $kind, $owner, $owner_kind, $width, $control, $value, $lanes) = @$row;
        my @overrides = ({name => 'WIDTH', value => '8'}, {name => 'CONTROL', value => $value});
        my @sources = ({name => 'WIDTH', value => $width, owner => 'generated_instances'},
            {name => 'CONTROL', value => $control, owner => 'generated_instances'});
        if ($lanes) {
            push @overrides, {name => 'LANES', value => $lanes};
            push @sources, {name => 'LANES', value => $lanes, owner => 'generated_instances'};
        }
        $expected{$instance} = {
            kind => 'generated_activation', parent_actor => 'generated_instances',
            source_actor => 'generated_instances', child => 'worker', instance => $instance,
            activation_kind => $kind, context => {owner => $owner, kind => $owner_kind},
            parameters => [{name => 'WIDTH', source => 'override', value => '8'},
                {name => 'ALIAS', source => 'default', value => 'WIDTH'},
                {name => 'CONTROL', source => 'override', value => $value},
                {name => 'LANES', source => $lanes ? 'override' : 'default', value => $lanes || ['0', '0']}],
            parameter_overrides => \@overrides, parameter_override_sources => \@sources,
        };
    }
    $expected{defaults} = {
        kind => 'generated_activation', parent_actor => 'generated_instances',
        source_actor => 'generated_instances', child => 'worker', instance => 'defaults',
        activation_kind => 'spawn', context => {owner => 'parent', kind => 'transaction'},
        parameters => [{name => 'WIDTH', source => 'default', value => '8'},
            {name => 'ALIAS', source => 'default', value => 'WIDTH'},
            {name => 'CONTROL', source => 'default', value => '0'},
            {name => 'LANES', source => 'default', value => ['0', '0']}],
        parameter_overrides => [], parameter_override_sources => [],
    };
    my $instances = $ir->{_width_scopes}{generated_instances};
    is_deeply($instances, \%expected, 'complete independently named spawn/do/repeat/conditional/rule selections');
    is_deeply([sort keys %{$ir->{children}}], ['worker'], 'all actual instances share one child module');
    is_deeply($ir->{children}{worker}{params}, [
        {name => 'WIDTH', value => '8'}, {name => 'ALIAS', value => 'WIDTH', resolved_value => '8'},
        {name => 'CONTROL', value => '0'}, {name => 'LANES', value => ['0', '0']}],
        'complete executable module defaults are independent of instance selections');
    is_deeply($ir->{children}{worker}{_width_declarations}{data}{source},
        {token => 'WIDTH', kind => 'transaction_parameter', owner => 'worker'},
        'actual port retains the local width source');
    is($json->encode($actor), $before, 'complete caller and primitive kinds survive');
    unlike($json->encode($ir->{spawn_instances}), qr/_width_/, 'executable instance records retain no private capture fields');
    if (ref($instances) eq 'HASH') {
        my $saved = $json->encode($lowerer->build_module($actor));
        my $second = $json->encode($instances->{second});
        $instances->{first}{parameter_override_sources}[0]{value} = 'WRONG';
        $instances->{first}{parameter_override_sources}[2]{value}[0] = '99';
        $instances->{first}{parameter_overrides}[2]{value}[1] = '99';
        $instances->{first}{parameters}[3]{value}[0] = '99';
        is($instances->{first}{parameters}[3]{value}[1], '2', 'selected values and resolved override arrays are detached');
        is($instances->{first}{parameter_overrides}[2]{value}[0], '1', 'authored and resolved arrays are detached');
        is($ir->{spawn_instances}[0]{parameter_overrides}[2]{value}[1], '2', 'executable overrides are detached');
        is($json->encode($instances->{second}), $second, 'sibling metadata stays detached');
        is($json->encode($actor), $before, 'authored clauses stay detached');
        is($json->encode($lowerer->build_module($actor)), $saved, 'fresh constructor result stays detached');
    }
};

if (defined $ENV{FSMGEN_REUSABLE_WIDTH_CAPTURE}) {
    open my $out, '>:raw', $ENV{FSMGEN_REUSABLE_WIDTH_CAPTURE} or die $!;
    print {$out} $json->encode(\%captures), "\n" or die $!;
    close $out or die $!;
}
done_testing;
