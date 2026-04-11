package FSM::Composition::RTLChildRealizer;

=head1 NAME

FSM::Composition::RTLChildRealizer - Realizer for external RTL composition children

=head1 DESCRIPTION

Owns the bounded C<?rtl> child-realization family for composition. This
package takes already-loaded `.rtlif` interface metadata, projects it into the
active realized-child runtime carrier, and preserves the metadata provenance
needed by later planning and reporting layers.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::RealizedInstance;
use FSM::Package::PayloadTypeSupport;

sub realize_rtl_child_instance ($class, %args) {
    my $rtl_interface_loader = $args{rtl_interface_loader}
        or confess "RTLChildRealizer requires an rtl_interface_loader";
    my $instance = $args{instance}
        or confess "RTLChildRealizer requires an instance";
    my $fsm_file = $args{fsm_file}
        or confess "RTLChildRealizer requires an fsm_file";
    my $composition_spec = $args{composition_spec};

    my $module_name = $instance->module_name;
    my $loaded = $rtl_interface_loader->load_interface(
        module_name => $module_name,
        source_file => $fsm_file,
        embedded_raw_ast => $composition_spec ? $composition_spec->raw_ast : undef,
    );
    my $parameter_overrides = $class->validate_parameter_overrides(
        instance => $instance,
        loaded_metadata => $loaded,
    );

    return FSM::Composition::RealizedInstance->new(
        kind => 'rtl',
        instance_name => ($instance->name // $module_name),
        module_name => $module_name,
        source_name => undef,
        interface_ports => $loaded->{interface_ports},
        parameter_overrides => $parameter_overrides,
        module_info => {
            module_name => $module_name,
            metadata_path => $loaded->{metadata_path},
            interface_kind => 'rtl_external',
            parameter_declarations => _clone($loaded->{parameter_declarations} || []),
        },
        hdl_code => undef,
    );
}

sub validate_parameter_overrides ($class, %args) {
    my $instance = $args{instance}
        or confess "RTLChildRealizer requires an instance";
    my $loaded_metadata = $args{loaded_metadata}
        or confess "RTLChildRealizer requires loaded_metadata";

    my @overrides = @{$instance->parameter_overrides || []};
    return [] unless @overrides;

    my $module_name = $instance->module_name;
    my $instance_name = $instance->name // $module_name;
    my $metadata_path = $loaded_metadata->{metadata_path} // 'unknown';
    my %declared_parameters = map {
        (($_->{name} // '') => $_)
    } @{$loaded_metadata->{parameter_declarations} || []};

    for my $override (@overrides) {
        my $name = $override->{name} // '';
        confess
            "Composition references external RTL instance '$instance_name' of module '$module_name', ".
            "but RTL parameter/generic override validation is blocked because override '$name' has no matching declaration in interface metadata '$metadata_path'. ".
            "Declare the parameter/generic in '(params (NAME default_value) ...)' under '?rtlif:$module_name' before overriding it from '?rtl:$instance_name'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless exists $declared_parameters{$name};

        my $declaration = $declared_parameters{$name};
        $class->validate_parameter_override_type_shape(
            module_name => $module_name,
            instance_name => $instance_name,
            metadata_path => $metadata_path,
            declaration => $declaration,
            override => $override,
        );
    }

    return _clone(\@overrides);
}

sub validate_parameter_override_type_shape ($class, %args) {
    my $module_name = $args{module_name} // 'unknown';
    my $instance_name = $args{instance_name} // $module_name;
    my $metadata_path = $args{metadata_path} // 'unknown';
    my $declaration = $args{declaration}
        or confess "RTLChildRealizer requires a declaration";
    my $override = $args{override}
        or confess "RTLChildRealizer requires an override";
    my $name = $override->{name} // $declaration->{name} // 'unknown';

    my $decl_kind = $declaration->{default_value_kind} // 'scalar';
    my $override_kind = $override->{value_kind} // 'scalar';
    return 1 if $decl_kind eq 'scalar' && $override_kind eq 'scalar';

    my $decl_label = _value_type_label($declaration->{default_value_type_spec}, $decl_kind);
    my $override_label = _value_type_label($override->{value_type_spec}, $override_kind);
    confess
        "Composition references external RTL instance '$instance_name' of module '$module_name', ".
        "but RTL parameter/generic override validation is blocked because override '$name' uses $override_label while interface metadata '$metadata_path' declares $decl_label. ".
        "Aggregate parameter/generic overrides must match the aggregate shape inferred from the '.rtlif' default value; scalar numeric parameters remain width-flexible. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless $decl_kind ne 'scalar' && $override_kind ne 'scalar';

    my $decl_spec = $declaration->{default_value_type_spec};
    my $override_spec = $override->{value_type_spec};
    confess
        "Composition references external RTL instance '$instance_name' of module '$module_name', ".
        "but RTL parameter/generic override validation is blocked because override '$name' uses $override_label while interface metadata '$metadata_path' declares $decl_label. ".
        "Aggregate parameter/generic overrides must match the aggregate shape inferred from the '.rtlif' default value before backend emission. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless FSM::Package::PayloadTypeSupport->payload_compatible_with_type_spec($override_spec, $decl_spec);

    return 1;
}

sub _value_type_label ($type_spec, $fallback_kind) {
    return FSM::Package::PayloadTypeSupport->type_spec_label($type_spec)
        if ref($type_spec) eq 'HASH';
    return $fallback_kind // 'unknown';
}

sub _clone ($value) {
    return undef unless defined $value;
    if (ref($value) eq 'HASH') {
        return { map { $_ => _clone($value->{$_}) } keys %$value };
    }
    if (ref($value) eq 'ARRAY') {
        return [ map { _clone($_) } @$value ];
    }
    return $value;
}

1;

__END__

=head1 METHODS

=head2 realize_rtl_child_instance

Loads one external RTL child interface through the active `.rtlif` loader and
returns the normalized L<FSM::Composition::RealizedInstance> used by later
composition planning/reporting code.

=head2 validate_parameter_overrides

Validates that every C<?rtl> instance override names a parameter/generic
declared by the loaded C<.rtlif> contract, checks aggregate override shapes
against the aggregate type inferred from the C<.rtlif> default value, then
returns a cloned override list.

=cut
