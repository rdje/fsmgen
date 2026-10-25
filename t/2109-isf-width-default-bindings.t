use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;

my $json = JSON::PP->new->canonical;
my $fixture = 't/data/isf-width-default-bindings/bindings.isf';
my $actor = FSM::Adapter::ISF->new->parse_file($fixture);
$actor->{actor_name} = 'renamed_default_bindings';
my $before = $json->encode($actor);
my $scheduler = FSM::Scheduler::ISF->new;
my $context = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
my $physical_before = $json->encode($context->{actor});
my $ir = $scheduler->{ir}->build_module($context->{actor});
my $products = {actor => $actor, physical => $context->{actor}, ir => $ir,
    files => $scheduler->lower($actor)->{files}, report => $scheduler->report($actor)};
my $capture = $json->encode($products);

sub reference {my ($kind, $token) = @_; return {kind => $kind, token => $token}}
sub literal {return reference('literal', $_[0])}
sub list {return {kind => 'list', items => [@_]}}
my $actor_expected = {
    BASE => literal('8'), ACTOR_ALIAS => reference('actor_parameter', 'BASE'),
    C => reference('actor_constant', 'FIXED'),
    P => {kind => 'package_constant', owner => 'shared', token => 'shared.WIDTH'},
    E => reference('enum_member', 'mode.EIGHT'), PE => reference('enum_member', 'shared.mode.EIGHT'),
    LANES => list(reference('actor_parameter', 'BASE'), reference('actor_constant', 'FIXED'),
        {kind => 'package_constant', owner => 'shared', token => 'shared.WIDTH'},
        reference('enum_member', 'mode.EIGHT'), list(literal('8'), reference('actor_parameter', 'BASE'))),
};
my $worker_expected = {
    BASE => literal('4'), LOCAL_ALIAS => reference('transaction_parameter', 'BASE'),
    A => reference('actor_parameter', 'ACTOR_ALIAS'), C => reference('actor_constant', 'FIXED'),
    P => {kind => 'package_constant', owner => 'shared', token => 'shared.WIDTH'},
    E => reference('enum_member', 'mode.EIGHT'), PE => reference('enum_member', 'shared.mode.EIGHT'),
    SHADOW => literal('4'), SHADOW_ALIAS => reference('transaction_parameter', 'SHADOW'),
    LANES => list(reference('transaction_parameter', 'BASE'), reference('actor_parameter', 'ACTOR_ALIAS'),
        reference('actor_constant', 'FIXED'),
        {kind => 'package_constant', owner => 'shared', token => 'shared.WIDTH'},
        reference('enum_member', 'mode.EIGHT'), list(literal('8'), reference('transaction_parameter', 'SHADOW'))),
};

subtest 'canonical default resolution retains selected source kinds and exact tokens' => sub {
    is($json->encode($ir->{_width_scopes}{actor}{parameter_default_bindings}),
        $json->encode($actor_expected), 'actor map retains actual reference categories and scalar kinds');
    is($json->encode($ir->{_width_scopes}{transactions}{worker}{parameter_default_bindings}),
        $json->encode($worker_expected), 'parent transaction map keeps local shadowing and nested references');
    is($json->encode($ir->{children}{worker}{_width_scopes}{transactions}{worker}{parameter_default_bindings}),
        $json->encode($worker_expected), 'generated scope uses the same selected transaction bindings');
    is($json->encode($ir->{children}{worker}{_width_scopes}{actor}{parameter_default_bindings}),
        $json->encode($actor_expected), 'generated actor environment keeps original actor bindings');
    is_deeply($ir->{_width_scopes}{transactions}{direct}{parameter_default_bindings},
        {W => reference('actor_parameter', 'ACTOR_ALIAS'), LOCAL_ALIAS => reference('transaction_parameter', 'W')},
        'direct-formal projection preserves default binding identity');
    is_deeply($ir->{_width_scopes}{transactions}{parent}{parameter_default_bindings}, {},
        'no-param transaction has no invented references');
    is_deeply($ir->{_width_scopes}{module_parameters}, {kind => 'actor', owner => 'default_bindings'},
        'renamed module keeps the original lexical envelope');
    is_deeply([sort keys %{$ir->{children}{worker}{_width_scopes}{transactions}}], ['worker'],
        'generated binding environment excludes foreign transactions');
    is($json->encode($actor), $before, 'complete source caller remains unchanged');
    is($json->encode($context->{actor}), $physical_before, 'complete physical caller remains unchanged');
    unlike($products->{report}, qr/parameter_default_bindings/, 'private bindings stay out of schedule JSON');
};

subtest 'binding observations are detached from values and other lexical environments' => sub {
    my $bindings = $ir->{_width_scopes}{transactions}{worker}{parameter_default_bindings};
    if (ref($bindings) ne 'HASH') {fail('actual default binding map is required'); return}
    my $saved = $json->encode($scheduler->{ir}->build_module($context->{actor}));
    $bindings->{LOCAL_ALIAS}{kind} = 'WRONG';
    $bindings->{LANES}{items}[5]{items}[1]{token} = 'WRONG';
    is($ir->{children}{worker}{_width_scopes}{transactions}{worker}{parameter_default_bindings}{LOCAL_ALIAS}{kind},
        'transaction_parameter', 'parent and generated maps are detached');
    is($ir->{children}{worker}{_width_scopes}{transactions}{worker}{parameter_default_bindings}{LANES}{items}[5]{items}[1]{token},
        'SHADOW', 'nested binding trees are detached');
    is($ir->{_width_scopes}{transactions}{worker}{parameter_default_sources}[1]{value}, 'BASE',
        'original defaults remain detached from semantic observations');
    is($ir->{children}{worker}{params}[0]{value}, '4', 'executable defaults remain detached');
    is($json->encode($context->{actor}), $physical_before, 'binding mutation cannot alter physical source');
    is($json->encode($scheduler->{ir}->build_module($context->{actor})), $saved, 'fresh complete result remains exact');
};

subtest 'canonical forward and self default refusals remain intact' => sub {
    my $forward = $json->decode($before);
    $forward->{params}[0]{value} = 'FUTURE';
    push @{$forward->{params}}, {name => 'FUTURE', value => '8'};
    my $ok = eval {FSM::Scheduler::ISF->new->{ir}->build_module($forward); 1};
    ok(!$ok, 'forward actor default is refused');
    like($@, qr/must reference an earlier scalar actor parameter default/, 'actor refusal retains its canonical boundary');
    my $self = $json->decode($before);
    my ($worker) = grep {$_->{name} eq 'worker'} @{$self->{transactions}};
    my ($params) = grep {ref($_) eq 'ARRAY' && @$_ && $_->[0] eq 'params'} @{$worker->{clauses}};
    $params->[1][1] = 'BASE';
    $ok = eval {FSM::Scheduler::ISF->new->{ir}->build_module($self); 1};
    ok(!$ok, 'self-referencing local parameter cannot borrow an actor default');
    like($@, qr/must reference an earlier scalar transaction parameter default/, 'local refusal retains its canonical boundary');
};

if (defined $ENV{FSMGEN_WIDTH_DEFAULT_BINDINGS_CAPTURE}) {
    open my $out, '>', $ENV{FSMGEN_WIDTH_DEFAULT_BINDINGS_CAPTURE} or die $!;
    print {$out} $capture, "\n" or die $!;
    close $out or die $!;
}
done_testing;
