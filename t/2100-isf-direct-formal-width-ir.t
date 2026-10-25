use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use FSM::Test::FormalWidthIR qw(formal_width_actor formal_width_products);
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Adapter::ISF;

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
    is_deeply([sort keys %{$row->{ir}{children}{worker}{_width_declarations}}], [qw(child_data response)],
        'generated child declarations remain exclusively in their own module');
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

my %domain_captures;
subtest 'domain selection preserves lexical widths across independent defaults' => sub {
    open my $in, '<:raw', 't/data/isf-formal-width-ir/domains.isf' or die $!;
    my $fixture = do {local $/; <$in>};
    close $in or die $!;
    for my $default (qw(core aux)) {
        my $source = $fixture;
        if ($default eq 'aux') {
            $source =~ s/\) :default/)/;
            $source =~ s/\(reset aux_rst_n\)\)/\(reset aux_rst_n\) :default\)/;
        }
        my $actor = FSM::Adapter::ISF->new->parse_source($source, 'domain-width-ir.isf');
        my $before = $json->encode($actor);
        my $scheduler = FSM::Scheduler::ISF->new;
        my $context = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
        my $physical_before = $json->encode($context->{actor});
        my $root = $scheduler->{ir}->build_module($context->{actor});
        is($root->{domain_partition}{default_domain}, $default, 'actual partition uses the selected default');
        my $realizations = $scheduler->_multi_domain_realizations($context->{actor}, $root->{domain_partition});
        FSM::Scheduler::ISF::FormalLowering->verify($context,
            {map {$_->{ir}{actor_name} => $_->{ir}} @$realizations});
        $domain_captures{$default} = $json->decode($json->encode({source => $source,
            actor => $actor, context => $context, root => $root, realizations => $realizations}));
        is_deeply([sort map {$_->{domain}{name}} @$realizations], [qw(aux core)],
            'complete actual realization membership has no invented or omitted domains');
        for my $row (['core', 'core_tx', 'data', 'result', 'saved', 'W', '4'],
                     ['aux', 'aux_tx', 'aux_data', 'aux_result', 'aux_saved', 'ALIAS', '6']) {
            my ($domain, $tx, $input, $output, $storage, $token, $local_width) = @$row;
            my ($realization) = grep {$_->{domain}{name} eq $domain} @$realizations;
            my $ir = $realization->{ir};
            my %expected;
            for my $entry ([$input, 'input', $token], [$output, 'output', 'W']) {
                $expected{$entry->[0]} = {scope => {kind => 'actor', owner => 'domain_widths'},
                    source => {token => $entry->[2], kind => 'actor_parameter', owner => 'domain_widths'},
                    declaration => {kind => 'interface', name => $entry->[0], direction => $entry->[1]}};
            }
            $expected{$storage} = {scope => {kind => 'actor', owner => 'domain_widths'},
                source => {token => $token, kind => 'actor_parameter', owner => 'domain_widths'},
                declaration => {kind => 'storage', storage_kind => 'var', name => $storage}};
            my $formal = "isf_port_${tx}_payload";
            $expected{$formal} = expected_formal('domain_widths', $tx, 'payload', 'input',
                'W', 'transaction_parameter', $tx);
            is_deeply($ir->{_width_declarations}, \%expected,
                "$domain complete source inventory excludes sibling declarations and physical-owner guesses");
            is($ir->{actor_name}, "domain_widths__domain_$domain", 'physical module retains distinct domain identity');
            is_deeply($ir->{_width_scopes}{module_parameters},
                {kind => 'actor', owner => 'domain_widths'}, 'domain module params keep the original actor owner');
            is_deeply($ir->{_width_scopes}{transactions}, {$tx => {owner => $tx, actor => 'domain_widths',
                params => [{name => 'W', value => $local_width}],
                parameter_default_sources => [{name => 'W', value => $local_width}]}},
                'only local transaction environment and original defaults are retained');
            is_deeply($ir->{_width_scopes}{actor}{params}, [{name => 'W', value => '8'},
                {name => 'ALIAS', value => 'W', resolved_value => '8'}], 'actor alias and defaults remain lexical');
            is($ir->{signal_widths}{$formal}, $local_width, 'actual formal retains local shadow width');
            is($ir->{signal_widths}{$input}, 8, 'actual actor input keeps independent default width');
            my $prepared = $context->{prepared}{domain_source_products}{$domain}{preparation}{actor};
            is_deeply([map {$_->{name}} @{$prepared->{transactions}}], [$tx], 'canonical domain preparation excludes foreign transactions');
            my ($port) = grep {$_->{name} eq $input} @{$prepared->{interface}{inputs}};
            is_deeply($port->{_width_declaration}, {token => $token, kind => 'actor_parameter', owner => 'domain_widths'},
                'original domain preparation retains the exact authored source');
        }
        is($json->encode($actor), $before, 'source caller and primitive kinds remain exact');
        is($json->encode($context->{actor}), $physical_before, 'physical preparation remains exact');
        my $saved = $json->encode($realizations);
        my %by_domain = map {$_->{domain}{name} => $_} @$realizations;
        my $aux = $json->encode($by_domain{aux});
        $by_domain{core}{ir}{_width_declarations}{data}{source}{owner} = 'WRONG';
        $by_domain{core}{ir}{_width_scopes}{actor}{params}[0]{value} = '99';
        is($by_domain{core}{ir}{params}[0]{value}, '8', 'executable parameters are detached');
        is($json->encode($by_domain{aux}), $aux, 'other domain remains detached');
        is($json->encode($context->{actor}), $physical_before, 'domain metadata cannot mutate its physical caller');
        is($json->encode($scheduler->_multi_domain_realizations($context->{actor}, $root->{domain_partition})), $saved,
            'fresh domain realizations remain exact');
    }
};

if (defined $ENV{FSMGEN_DOMAIN_WIDTH_CAPTURE}) {
    open my $out, '>:raw', $ENV{FSMGEN_DOMAIN_WIDTH_CAPTURE} or die $!;
    print {$out} $json->encode(\%domain_captures), "\n" or die $!;
    close $out or die $!;
}
done_testing;
