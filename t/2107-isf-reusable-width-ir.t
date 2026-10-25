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
if (defined $ENV{FSMGEN_REUSABLE_WIDTH_CAPTURE}) {
    open my $out, '>:raw', $ENV{FSMGEN_REUSABLE_WIDTH_CAPTURE} or die $!;
    print {$out} $json->encode(\%captures), "\n" or die $!;
    close $out or die $!;
}
done_testing;
