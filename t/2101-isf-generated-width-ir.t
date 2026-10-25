use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use FSM::Test::GeneratedWidthIR qw(generated_width_actor generated_width_products);
use FSM::Scheduler::ISF;

my $json = JSON::PP->new->canonical;
my $products = generated_width_products();
my $actor_name = 'generated_width_ir';

sub formal {
    my ($tx, $name, $direction, $token, $kind, $owner) = @_;
    return {scope => {kind => 'transaction', actor => $actor_name, owner => $tx},
        source => {token => $token, kind => $kind, owner => $owner},
        declaration => {kind => 'transaction_port', name => $name, direction => $direction,
            identity => ['transaction_port', $actor_name, $tx, $name]}};
}

sub expected_worker {
    my %expected;
    for my $row (
        [payload => 'ACTOR_ALIAS', 'actor_parameter', $actor_name],
        [data => 'W', 'transaction_parameter', 'worker'],
        [unused_formal => 'ALIAS', 'transaction_parameter', 'worker'],
        [saved => 'OTHER', 'transaction_parameter', 'worker'],
        [fixed => 'FIXED', 'actor_constant', $actor_name],
        [response => 'ALIAS', 'transaction_parameter', 'worker'],
        [inherited => 'ACTOR_ALIAS', 'actor_parameter', $actor_name],
        [from_storage => 'ACTOR_ALIAS', 'actor_parameter', $actor_name],
    ) {
        my ($name, $token, $kind, $owner) = @$row;
        $expected{$name} = formal('worker', $name, $name =~ /^(?:response|inherited|from_storage)$/ ? 'output' : 'input', $token, $kind, $owner);
    }
    for my $name (qw(pin)) {
        $expected{$name} = {scope => {kind => 'actor', owner => $actor_name},
            source => {token => 'W', kind => 'actor_parameter', owner => $actor_name},
            declaration => {kind => 'interface', name => $name, direction => $name eq 'pin' ? 'input' : 'output'}};
    }
    $expected{stored} = {scope => {kind => 'actor', owner => $actor_name},
        source => {token => 'ACTOR_ALIAS', kind => 'actor_parameter', owner => $actor_name},
        declaration => {kind => 'storage', storage_kind => 'var', name => 'stored'}};
    return \%expected;
}

subtest 'final generated ports retain exact original sources and shadows' => sub {
    my $ir = $products->{generated}{ir};
    my $child = $ir->{children}{worker};
    is($json->encode($child->{_width_declarations}), $json->encode(expected_worker()),
        'complete map keeps formals, selected inherited pins and actual storage-read port');
    my %ports = map { $_->{name} => $_->{width} } @{$child->{ports}};
    is_deeply(\%ports, {payload => 8, data => 4, unused_formal => 4, saved => 4,
        fixed => 8, typed => 8, literal => 8, response => 4, pin => 8,
        inherited => 8, from_storage => 8, stored => 8, start => 1, done => 1},
        'independent physical membership preserves all ordinary default widths');
    is_deeply($child->{declared_storage}, [], 'actor storage is owned by the parent');
    is_deeply($ir->{children}{sibling}{_width_declarations}, {
        data => formal('sibling', 'data', 'input', 'ALIAS', 'transaction_parameter', 'sibling'),
        response => formal('sibling', 'response', 'output', 'W', 'transaction_parameter', 'sibling')},
        'sibling has only its own actual declarations');
    is_deeply($products->{plain}{ir}{children}{worker}{_width_declarations}, {},
        'literal, implicit and named-type declarations acquire no symbolic association');
};

subtest 'actor and selected transaction environments remain distinct from child params' => sub {
    my $child = $products->{generated}{ir}{children}{worker};
    is($json->encode($child->{_width_scopes}{actor}{params}),
        '[{"name":"W","value":"8"},{"name":"ACTOR_ALIAS","resolved_value":"8","value":"W"},{"name":"OTHER","value":"8"}]',
        'inherited declarations keep actor aliases and defaults even though child W is four');
    is($json->encode($child->{_width_scopes}{transactions}),
        '{"worker":{"actor":"generated_width_ir","owner":"worker","parameter_default_sources":[{"name":"W","value":"4"},{"name":"ALIAS","value":"W"},{"name":"OTHER","value":"4"}],"params":[{"name":"W","value":"4"},{"name":"ALIAS","resolved_value":"4","value":"W"},{"name":"OTHER","value":"4"}]}}',
        'child has only the selected transaction environment with exact aliases and kinds');
    is($json->encode($child->{params}), $json->encode($child->{_width_scopes}{transactions}{worker}{params}),
        'executable child params keep their established local semantics');
    is($products->{generated}{ir}{children}{sibling}{_width_scopes}{transactions}{sibling}{params}[0]{value}, '6',
        'sibling scope retains its independent default');
};

subtest 'module parameter ownership comes from constructors even when parameter lists coincide' => sub {
    my $root = $products->{generated}{ir};
    is_deeply($root->{_width_scopes}{module_parameters},
        {kind => 'actor', owner => 'generated_width_ir'}, 'parent parameters belong to the source actor');
    is_deeply($root->{children}{worker}{_width_scopes}{module_parameters},
        {kind => 'transaction', actor => 'generated_width_ir', owner => 'worker'},
        'generated module parameters belong to the selected transaction');
    is_deeply($root->{children}{sibling}{_width_scopes}{module_parameters},
        {kind => 'transaction', actor => 'generated_width_ir', owner => 'sibling'},
        'sibling parameters have their own lexical owner');

    open my $in, '<', 't/data/isf-generated-width-ir/generated.isf' or die $!;
    my $source = do {local $/; <$in>};
    close $in or die $!;
    $source =~ s/ACTOR_ALIAS/ALIAS/g;
    $source =~ s/\(transaction worker \(params \(W 4\) \(ALIAS W\) \(OTHER 4\)\)/
        (transaction worker (params (W 8) (ALIAS W) (OTHER 8))/;
    $source =~ s/\(output result \(width 4\)\)/(output result (width 8))/;
    my $actor = FSM::Adapter::ISF->new->parse_source($source, 'coincident-width-owners.isf');
    $actor->{actor_name} = 'renamed_equal_width_module';
    my $before = $json->encode($actor);
    my $lowerer = FSM::Scheduler::ISF->new->{ir};
    my $ir = $lowerer->build_module($actor);
    is($ir->{params}[0]{value}, '8', 'actor parameter has the selected equal default');
    is($ir->{children}{worker}{params}[0]{value}, '8', 'transaction parameter has the same default');
    is($json->encode($ir->{params}), $json->encode($ir->{children}{worker}{params}),
        'complete executable parameter lists and scalar kinds coincide');
    is_deeply($ir->{_width_scopes}{module_parameters}, {kind => 'actor', owner => 'generated_width_ir'},
        'renamed actor parameters retain their original lexical owner');
    is_deeply($ir->{children}{worker}{_width_scopes}{module_parameters},
        {kind => 'transaction', actor => 'generated_width_ir', owner => 'worker'},
        'equal parameter lists cannot change transaction ownership');
    my $saved = $json->encode($lowerer->build_module($actor));
    if (ref($ir->{children}{worker}{_width_scopes}{module_parameters}) eq 'HASH') {
        $ir->{children}{worker}{_width_scopes}{module_parameters}{owner} = 'WRONG';
        is($ir->{_width_scopes}{module_parameters}{owner}, 'generated_width_ir', 'parent ownership is detached');
        is($ir->{children}{sibling}{_width_scopes}{module_parameters}{owner}, 'sibling',
            'sibling ownership is detached');
        is($json->encode($actor), $before, 'ownership cannot mutate source callers or scalar kinds');
        is($json->encode($lowerer->build_module($actor)), $saved, 'fresh ownership remains exact');
    }
};

subtest 'all generated metadata is isolated from inputs, siblings and executable records' => sub {
    for my $case (qw(generated plain)) {
        ok($products->{$case}{caller_unchanged}, "$case preserves complete source callers and kinds");
        unlike($products->{$case}{report}, qr/_width_(?:declarations|scopes|static_uses)/,
            "$case schedule remains sanitized");
    }
    my $source = generated_width_actor('generated');
    $source->{actor_name} = 'renamed_generated_width_module';
    my $before = $json->encode($source);
    my $lowerer = FSM::Scheduler::ISF->new->{ir};
    my $first = $lowerer->build_module($source);
    my $second = $lowerer->build_module($source);
    my $saved = $json->encode($second);
    my $child = $first->{children}{worker};
    is($json->encode($child->{_width_declarations}), $json->encode(expected_worker()),
        'physical parent rename preserves original lexical identities');
    is_deeply($first->{_width_scopes}{module_parameters},
        {kind => 'actor', owner => 'generated_width_ir'}, 'renamed parent keeps its source parameter owner');
    is_deeply($child->{_width_scopes}{module_parameters},
        {kind => 'transaction', actor => 'generated_width_ir', owner => 'worker'},
        'renamed parent cannot rename child lexical ownership');
    $child->{_width_declarations}{data}{source}{owner} = 'WRONG';
    $child->{_width_declarations}{payload}{declaration}{identity}[3] = 'WRONG';
    $child->{_width_scopes}{actor}{params}[0]{value} = '99';
    $child->{_width_scopes}{transactions}{worker}{params}[0]{value} = '99';
    is($child->{params}[0]{value}, '4', 'executable child params are detached');
    is($first->{_width_scopes}{actor}{params}[0]{value}, '8', 'parent metadata is detached');
    is($first->{children}{sibling}{_width_scopes}{actor}{params}[0]{value}, '8', 'sibling metadata is detached');
    is($json->encode($source), $before, 'original input remains byte/kind exact');
    is($json->encode($second), $saved, 'another returned module remains exact');
    is($json->encode($lowerer->build_module($source)), $saved, 'fresh module remains exact');
};

done_testing;
