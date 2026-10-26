use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Composition::Parser;
use FSM::Composition::PackageImportResolver;
use FSM::Composition::GeneratedChildRealizer;
use FSM::Composition::RTLChildRealizer;
use FSM::Composition::RTLInterfaceLoader;
use FSM::Composition::RealizedInstance;
use FSM::Composition::Instance;
use FSM::Pipeline::HDLGenerator;
use FSM::Pipeline::SourceFrontend;
use FSM::SourcePathResolver;

my $json = JSON::PP->new->canonical;
sub copy { return $json->decode($json->encode($_[0])) }
my $path = 't/data/composition-top-child-bindings.fsm';
my $raw = Lispish::multi($path);
my $raw_before = $json->encode($raw);
my $spec = FSM::Composition::Parser->new->parse_source($raw);
my $resolver = FSM::SourcePathResolver->new;
FSM::Composition::PackageImportResolver->resolve_imports(
    composition_spec => $spec, fsm_file => $path, source_path_resolver => $resolver);
my $pipeline = FSM::Pipeline::HDLGenerator->new(quiet => 1, target_language => 'systemverilog');
my $loader = FSM::Composition::RTLInterfaceLoader->new(path_resolver => $resolver);
my %capture;

for my $instance (@{$spec->top->instances}) {
    my $kind = $instance->kind;
    subtest "$kind actual declarations preserve scoped records through realization" => sub {
        my $before = $json->encode($instance->parameter_overrides);
        my ($owner, %validation, $realized);
        if ($kind eq 'rtl') {
            $owner = 'FSM::Composition::RTLChildRealizer';
            my $loaded = $loader->load_interface(module_name => $instance->module_name,
                source_file => $path, embedded_raw_ast => $spec->raw_ast,
                top_symbols => $spec->top->top_symbols);
            %validation = (loaded_metadata => $loaded);
            $realized = $owner->realize_rtl_child_instance(instance => $instance,
                rtl_interface_loader => $loader, composition_spec => $spec, fsm_file => $path);
        } else {
            $owner = 'FSM::Composition::GeneratedChildRealizer';
            my $sources = $kind eq 'fsmc' ? $spec->embedded_fsm_sources : $spec->embedded_dt_sources;
            my $module = FSM::Pipeline::SourceFrontend->create_fsm_module(
                raw_ast => $sources->{$instance->source_name}, source_label => $instance->source_name,
                fsm_file => $path, source_path_resolver => $resolver);
            %validation = (child_module => $module, source_name => $instance->source_name,
                declared_child_kind => '?'.$kind);
            my $method = $kind eq 'fsmc' ? 'realize_fsmc_child_instance' : 'realize_dtc_child_instance';
            $realized = $owner->$method(instance => $instance, pipeline => $pipeline,
                composition_spec => $spec, fsm_file => $path, header => '?top:child_bindings',
                source_path_resolver => $resolver);
        }
        my $validated = $owner->validate_parameter_overrides(instance => $instance, %validation);
        my $records = $realized->parameter_overrides;
        is_deeply($records, $validated, 'actual realization preserves the complete validated list');
        is_deeply([map {$_->{name}} @$records], [map {$_->{name}} @{$instance->parameter_overrides}],
            'declaration validation preserves authored override order');
        my %by_name = map {$_->{name} => $_} @$records;
        is_deeply($by_name{WIDTH}{binding_expression}, {
            kind => 'parameter', parameter => 'W', token => 'W', suffix => '',
            scope => {kind => 'composition_top', owner => 'child_bindings'}},
            'real declaration retains W identity independently of equal numeric defaults');
        is($by_name{WIDTH}{value_text}, '16', 'canonical scalar validation cache remains available');
        is($by_name{WIDTH}{declaration_default_value_kind}, 'scalar', 'real child supplies scalar declaration kind');
        is($by_name{DATA}{declaration_default_value_kind}, 'list', 'real child supplies aggregate declaration kind');
        is($by_name{DATA}{declaration_default_value_width}, 16, 'real aggregate declaration supplies its packed width');
        is($by_name{DATA}{binding_expression}{parameter}, 'LANES', 'aggregate source identity remains separate from shape');
        for my $record (@$records) {
            my $original = (grep {$_->{name} eq $record->{name}} @{$instance->parameter_overrides})[0];
            my $without_declaration = copy($record);
            delete @{$without_declaration}{qw(declaration_default_value_kind declaration_default_value_width
                declaration_default_value_text declaration_default_value_payload declaration_default_value_type_spec
                declaration_default_source_expression)};
            is_deeply($without_declaration, $original, 'only actual declaration annotations extend the source record');
        }
        if ($kind eq 'fsmc') {
            is($by_name{EQUAL}{binding_expression}{parameter}, 'SAME', 'equal defaults retain distinct declared roots');
            ok(!exists($by_name{STATIC}{binding_expression}), 'literal-only control gains no parameter binding');
        }
        if ($kind eq 'dtc') {
            is($by_name{LEAF}{binding_expression}{suffix}, '[1]', 'actual DT child retains aggregate path selection');
        }
        is($json->encode($instance->parameter_overrides), $before, 'successful validation/realization leaves source records unchanged');
        $capture{$kind} = {source => $json->decode($before), validated => copy($validated), realized => copy($records)};

        # Exercise both ownership boundaries with the actual validated producer.
        my $carrier = FSM::Composition::RealizedInstance->new(parameter_overrides => $validated);
        $validated->[0]{binding_expression}{scope}{owner} = 'constructor_mutation';
        $records->[0]{binding_expression}{scope}{owner} = 'getter_mutation';
        is_deeply($carrier->parameter_overrides, $capture{$kind}{validated}, 'constructor detaches all nested binding/source records');
        is_deeply($realized->parameter_overrides, $capture{$kind}{realized}, 'getter detaches all nested binding/source records');

        for my $case (qw(unknown scalar_for_aggregate aggregate_for_scalar wrong_length)) {
            my $overrides = $instance->parameter_overrides;
            if ($case eq 'unknown') {
                $overrides->[0]{name} = 'MISSING';
            } elsif ($case eq 'scalar_for_aggregate') {
                my $scalar = copy($by_name{WIDTH}); $scalar->{name} = 'DATA'; $overrides = [$scalar];
            } elsif ($case eq 'aggregate_for_scalar') {
                my $aggregate = copy($by_name{DATA}); $aggregate->{name} = 'WIDTH'; $overrides = [$aggregate];
            } else {
                # A real canonical aggregate with a different length, not a forged kind tag.
                my $text = q{(?top:wrong_shape (+params (LANES (8'h01)))
                    (?rtl:u (module child_rtl) (params (DATA LANES))))};
                my $other = FSM::Composition::Parser->new->parse_source(scalar Lispish::multi(\$text));
                FSM::Composition::PackageImportResolver->resolve_imports(composition_spec => $other,
                    fsm_file => $path, source_path_resolver => $resolver);
                $overrides = $other->top->instances->[0]->parameter_overrides;
            }
            my $bad = FSM::Composition::Instance->new(kind => $kind, name => $instance->name,
                module_name => $instance->module_name, source_name => $instance->source_name,
                parameter_overrides => $overrides);
            my $bad_before = $json->encode($bad->parameter_overrides);
            my $ok = eval {$owner->validate_parameter_overrides(instance => $bad, %validation); 1};
            my $error = $@;
            $capture{$kind}{refusals}{$case} = {error => $error, input => $json->decode($bad_before), accepted => $ok ? 1 : 0};
            ok(!$ok, "$case refuses against the actual child declaration");
            like($error, $case eq 'unknown' ? qr/no matching.*declaration/ : qr/declares.*Aggregate parameter/s,
                "$case reports the declaration boundary");
            is($json->encode($bad->parameter_overrides), $bad_before, "$case refusal preserves source caller");
        }
    };
}
is($json->encode($raw), $raw_before, 'whole parsed source stays unchanged');
if (my $capture_path = $ENV{FSMGEN_CHILD_BINDING_CAPTURE}) {
    open my $out, '>', $capture_path or die $!;
    print {$out} $json->encode(\%capture), "\n" or die $!;
    close $out or die $!;
}
done_testing();
