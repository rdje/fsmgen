use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::ISF;
use FSM::Adapter::FSMGenFull;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Scheduler::ISF::Emitter::FSM;
use FSM::ProjectDataLocality qw(create_project_tempdir);

my $json = JSON::PP->new->canonical;
my $dir = create_project_tempdir(purpose => 'bound-module-carriers');
my %capture;
sub copy { $json->decode($json->encode($_[0])) }
sub emit { FSM::Scheduler::ISF::Emitter::FSM->new->emit($_[0]) }
sub core {
    my ($label, $source) = @_;
    my $path = "$dir/$label.fsm";
    open my $out, '>', $path or die $!; print {$out} $source; close $out or die $!;
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $module = eval {$adapter->parse_fsm(scalar Lispish::multi($path))};
    ok($module, "$label emitted source parses through canonical IAL0") or diag($@);
    return $module ? $adapter : undef;
}

subtest 'actual generated module emits scoped widths, defaults and supporting declarations' => sub {
    my $actor = FSM::Adapter::ISF->new->parse_file('t/data/isf-width-symbols/bindings.isf');
    my $actor_before = $json->encode($actor);
    my $scheduler = FSM::Scheduler::ISF->new;
    my $ir = $scheduler->{ir}->build_module($actor);
    my $before = $json->encode($ir);
    my $child = $ir->{children}{worker};
    my $source = emit($child);
    like($source, qr/\(data \(param LOCAL_ALIAS\)\)/, 'width selects its actual local parameter');
    like($source, qr/\(response \(param BASE\)\)/, 'equal local default remains a distinct source selection');
    like($source, qr/\(fixed \(\+ FIXED 0\)\)/, 'static width avoids the same-named type namespace');
    like($source, qr/\(LOCAL_ALIAS BASE\)/, 'local default alias stays authored');
    like($source, qr/\(A isf_width_capture_5\)/, 'actor default reference uses its allocated capture');
    like($source, qr/\(isf_width_capture_5 8\)/, 'capture receives its selected default');
    like($source, qr/\(P isf_width_static_6\)/, 'static default does not borrow the same-named real parameter');
    like($source, qr/\(isf_width_static_6 8\)/, 'static support is an immutable constant');
    like($source, qr/\(LANES \(BASE isf_width_capture_5 FIXED isf_width_static_6 isf_width_static_4 \(8 SHADOW\)\)\)/,
        'nested defaults preserve scope, order and aggregate structure');
    my $cached = copy($child);
    $_->{width} = 999 for grep {$_->{name} eq 'data' || $_->{name} eq 'response'} @{$cached->{ports}};
    $_->{value} = 999 for @{$cached->{params}};
    is(emit($cached), $source, 'numeric width/default caches cannot replace captured canonical expressions');
    my $adapter = core('worker', $source);
    if ($adapter) {
        is($adapter->{signal_manager}->get_signal('data')->width, 4, 'actual local data default stays four');
        is($adapter->{signal_manager}->get_signal('fixed')->width, 8, 'actual static width stays eight instead of type width four');
        is($adapter->{signal_manager}->resolve_declared_parameter_payload('A')->{payload}, '8',
            'captured actor default differs from local four');
        is($adapter->{signal_manager}->resolve_declared_parameter_payload('SHADOW_ALIAS')->{payload}, '4',
            'real local shadow remains local');
    }
    my $files = $scheduler->lower($actor)->{files};
    ok(grep(index($_, '(data (param LOCAL_ALIAS))') >= 0, values %$files),
        'actual scheduler artifact emission calls the same canonical consumer');
    my $parent = $files->{'width_symbols.fsm'};
    like($parent, qr/\(isf_port_direct_payload \(param ACTOR_ALIAS\)\)/,
        'direct-formal local chain selects its actual actor source in the parent module');
    my $parent_adapter = core('parent_with_formals', $parent);
    if ($parent_adapter) {
        is($parent_adapter->{signal_manager}->get_signal('isf_port_direct_payload')->width, 8,
            'direct-formal captured width stays eight rather than generated-child local four');
    }
    is($json->encode($ir), $before, 'complete prepared IR keeps its JSON kinds and values');
    is($json->encode($actor), $actor_before, 'complete source caller keeps its JSON kinds and values');
    $capture{generated} = {source => $source, files => $files};
};

subtest 'ordinary actor emits a complete runnable default-preserving example' => sub {
    my $actor = FSM::Adapter::ISF->new->parse_file('t/data/isf-bound-width-carrier-demo.isf');
    my $files = FSM::Scheduler::ISF->new->lower($actor)->{files};
    my $source = $files->{'width_carrier_demo.fsm'};
    like($source, qr/\(WIDTH BASE\)/, 'ordinary actor keeps the declared alias');
    like($source, qr/\(data \(param WIDTH\)\)/, 'ordinary data width retains the selected alias');
    like($source, qr/\(result \(param WIDTH\)\)/, 'ordinary result width retains the same selected alias');
    my $adapter = core('ordinary_actor', $source);
    is($adapter->{signal_manager}->get_signal('data')->width, 8, 'ordinary default remains eight') if $adapter;
    $capture{ordinary} = $source;
};

subtest 'reusable and physical domain modules use their existing scoped plans' => sub {
    for my $case (qw(library atl)) {
        my $actor = FSM::Adapter::ISF->new->parse_file("t/data/isf-reusable-width-ir/$case.isf");
        my $ir = FSM::Scheduler::ISF->new->{ir}->build_module($actor);
        my $before = $json->encode($ir);
        for my $name (sort keys %{$ir->{children}}) {
            my $source = emit($ir->{children}{$name});
            like($source, qr/\(data \(param WIDTH\)\)/, "$case source export owns its data width");
            like($source, qr/\(result \(param ALIAS\)\)/, "$case result preserves its alias selection");
            like($source, qr/\(ALIAS WIDTH\)/, "$case module default is independent of instance selections");
            core("${case}_$name", $source);
            $capture{$case}{$name} = $source;
        }
        is($json->encode($ir), $before, "$case whole IR remains unchanged");
    }
    my $actor = FSM::Adapter::ISF->new->parse_file('t/data/isf-formal-width-ir/domains.isf');
    my $scheduler = FSM::Scheduler::ISF->new;
    my $formal = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
    my $physical = $formal ? $formal->{actor} : $actor;
    my $ir = $scheduler->{ir}->build_module($physical);
    my $domains = $scheduler->_multi_domain_realizations($physical, $ir->{domain_partition});
    for my $real (@$domains) {
        my $module = $real->{ir}; my $before = $json->encode($module);
        my $source = emit($module);
        like($source, qr/\(ALIAS W\)/, 'physical domain rename preserves the source default alias');
        like($source, qr/\((?:data|aux_data) \(param (?:W|ALIAS)\)\)/,
            'domain port keeps its authored parameter selection');
        core('domain_'.$real->{domain}{name}, $source);
        is($json->encode($module), $before, 'physical module keeps its complete JSON kinds and values');
        $capture{domains}{$real->{domain}{name}} = $source;
    }
};

subtest 'literal widths, declared types, resets and absent plans retain existing output' => sub {
    open my $in, '<', 't/data/isf-formal-width-ir/literals.isf' or die $!;
    my $text = do {local $/; <$in>}; close $in or die $!;
    $text =~ s/\(transaction main/(storage (var saved (width 8) (reset 1)))\n  (transaction main/;
    my $actor = FSM::Adapter::ISF->new->parse_source($text, 'literal-carrier-control.isf');
    my $scheduler = FSM::Scheduler::ISF->new;
    my $formal = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
    my $ir = $scheduler->{ir}->build_module($formal ? $formal->{actor} : $actor);
    my $before = $json->encode($ir);
    my $without = copy($ir); delete $without->{_width_symbols};
    my $source = emit($ir);
    is($source, emit($without), 'literal/type-only source is byte-identical with and without the optional plan');
    like($source, qr/\(saved 8 \(reset 1\)\)/, 'storage reset suffix stays independent of width lowering');
    like($source, qr/word_t/, 'declared type source is retained');
    core('literal_control', $source);
    is($json->encode($ir), $before, 'literal control cannot gain autovivified private fields');
    my $bare_before = $json->encode($without); emit($without);
    is($json->encode($without), $bare_before, 'legacy IR without a plan remains unchanged');
    $capture{literal} = $source;
};

if (my $path = $ENV{FSMGEN_MODULE_CARRIER_CAPTURE}) {
    open my $out, '>', $path or die $!; print {$out} $json->encode(\%capture), "\n" or die $!;
    close $out or die $!;
}
done_testing;
