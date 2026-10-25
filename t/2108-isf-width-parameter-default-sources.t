use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;

my $json = JSON::PP->new->canonical;
open my $in, '<', 't/data/isf-width-parameter-default-sources.isf' or die $!;
my $fixture = do {local $/; <$in>};
close $in or die $!;
my %products;

for my $case (qw(actor constant literal)) {
    my $source = $fixture;
    my $token = $case eq 'actor' ? 'BASE' : $case eq 'constant' ? 'FIXED' : '8';
    $source =~ s/\(W BASE\)/(W $token)/;
    my $actor = FSM::Adapter::ISF->new->parse_source($source, 'width-default-sources.isf');
    my $before = $json->encode($actor);
    my $scheduler = FSM::Scheduler::ISF->new;
    my $context = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
    my $physical_before = $json->encode($context->{actor});
    my $ir = $scheduler->{ir}->build_module($context->{actor});
    my $files = $scheduler->lower($actor)->{files};
    my $report = $scheduler->report($actor);
    $products{$case} = $json->decode($json->encode({source => $source,
        actor => $actor, physical => $context->{actor}, ir => $ir, files => $files, report => $report}));

    subtest "$case defaults retain their actual sources rather than their equal numbers" => sub {
        my $expected = [{name => 'W', value => $token},
            {name => 'LOCAL_ALIAS', value => 'W'}, {name => 'EQUAL', value => '8'},
            {name => 'LANES', value => ['BASE', 'LOCAL_ALIAS', 'FIXED', ['8', 'BASE']]}];
        is($json->encode($ir->{_width_scopes}{transactions}{worker}{parameter_default_sources}),
            $json->encode($expected), 'parent scope keeps ordered original tokens and scalar kinds');
        is($json->encode($ir->{children}{worker}{_width_scopes}{transactions}{worker}{parameter_default_sources}),
            $json->encode($expected), 'selected generated scope keeps the same authored defaults');
        is_deeply([sort keys %{$ir->{children}{worker}{_width_scopes}{transactions}}], ['worker'],
            'generated scope excludes unrelated direct and parent transactions');
        is($json->encode($ir->{_width_scopes}{transactions}{direct}{parameter_default_sources}),
            '[{"name":"W","value":"ACTOR_ALIAS"},{"name":"LOCAL_ALIAS","value":"W"}]',
            'direct-formal preparation preserves its original actor alias and local chain');
        is_deeply($ir->{_width_scopes}{transactions}{parent}{parameter_default_sources}, [],
            'a transaction without params has no invented defaults');
        is($ir->{children}{worker}{params}[0]{value}, '8', 'executable child default stays literalized');
        is($json->encode($actor), $before, 'source caller and scalar kinds remain unchanged');
        is($json->encode($context->{actor}), $physical_before, 'physical caller remains unchanged');
        unlike($report, qr/parameter_default_sources/, 'private source records stay out of schedule JSON');

        my $sources = $ir->{_width_scopes}{transactions}{worker}{parameter_default_sources};
        if (ref($sources) eq 'ARRAY') {
            my $saved = $json->encode($scheduler->{ir}->build_module($context->{actor}));
            $sources->[0]{value} = 'WRONG';
            $sources->[3]{value}[3][1] = 'WRONG';
            is($ir->{children}{worker}{_width_scopes}{transactions}{worker}{parameter_default_sources}[0]{value},
                $token, 'parent and generated source records are detached');
            is($ir->{children}{worker}{_width_scopes}{transactions}{worker}{parameter_default_sources}[3]{value}[3][1],
                'BASE', 'nested source arrays are detached');
            is($ir->{_width_scopes}{transactions}{worker}{params}[0]{value}, '8',
                'canonical environment is detached from source metadata');
            is($json->encode($context->{actor}), $physical_before, 'source metadata cannot mutate physical input');
            is($json->encode($scheduler->{ir}->build_module($context->{actor})), $saved,
                'fresh constructor result remains exact');
        }
    };
}

subtest 'equal actor and constant defaults do not establish a common dependency' => sub {
    my $left = $json->decode($json->encode($products{actor}{ir}));
    my $right = $json->decode($json->encode($products{constant}{ir}));
    for my $ir ($left, $right) {
        # Project only the original-source and semantic-binding extensions to
        # compare the prior resolved IR; T2109 qualifies the new binding maps.
        for my $module ($ir, $ir->{children}{worker}) {
            delete $module->{_width_scopes}{actor}{parameter_default_bindings};
            for my $scope (values %{$module->{_width_scopes}{transactions}}) {
                delete $scope->{parameter_default_sources};
                delete $scope->{parameter_default_bindings};
            }
        }
    }
    is($json->encode($left), $json->encode($right), 'complete old IR cannot distinguish the two source dependencies');
    is($json->encode($products{actor}{files}), $json->encode($products{constant}{files}),
        'complete current carriers retain their intentional default behavior');
    is($products{actor}{report}, $products{constant}{report}, 'complete schedule reports retain the same public defaults');
};

if (defined $ENV{FSMGEN_WIDTH_DEFAULT_SOURCES_CAPTURE}) {
    open my $out, '>', $ENV{FSMGEN_WIDTH_DEFAULT_SOURCES_CAPTURE} or die $!;
    print {$out} $json->encode(\%products), "\n" or die $!;
    close $out or die $!;
}
done_testing;
