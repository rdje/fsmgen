package FSM::Backend::VerilogFamily::TypeDeclarationSupport;

=head1 NAME

FSM::Backend::VerilogFamily::TypeDeclarationSupport - Shared Verilog-family type declaration rendering helpers

=head1 DESCRIPTION

Owns backend-owned SystemVerilog typedef rendering for semantic FSMGen type
contracts. This keeps direct generated-module emission and structural
composition emission on one aggregate-type lowering contract instead of letting
each backend surface invent its own packed typedef rules.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Package::PayloadTypeSupport;

sub typedef_state ($class) {
    return {
        lookup => {},
        used_typedef_names => {},
    };
}

sub collect_declared_aggregate_typedefs ($class, $entries, $state = undef) {
    $state //= $class->typedef_state;
    $state->{lookup} //= {};
    $state->{used_typedef_names} //= {};

    my @typedef_lines;
    for my $entry (@{$entries || []}) {
        next unless ref($entry) eq 'HASH';

        my $declared_type_name = $entry->{declared_type_name};
        my $declared_type_spec = $entry->{declared_type_spec};
        next unless defined($declared_type_name) && !ref($declared_type_name);
        next unless $class->is_aggregate_type_spec($declared_type_spec);

        my $key = $class->_aggregate_typedef_lookup_key($declared_type_name, $declared_type_spec);
        next if exists $state->{lookup}{$key};

        my $typedef_name = $class->_unique_typedef_name($declared_type_name, $state->{used_typedef_names});
        $state->{lookup}{$key} = $typedef_name;
        push @typedef_lines, $class->_render_aggregate_typedef_lines($typedef_name, $declared_type_name, $declared_type_spec), "";
    }

    pop @typedef_lines if @typedef_lines && $typedef_lines[-1] eq '';
    return (\@typedef_lines, $state->{lookup}, $state);
}

sub aggregate_typedef_name_for ($class, $entry, $aggregate_typedef_lookup) {
    return undef unless ref($entry) eq 'HASH' && ref($aggregate_typedef_lookup) eq 'HASH';

    my $declared_type_name = $entry->{declared_type_name};
    my $declared_type_spec = $entry->{declared_type_spec};
    return undef unless defined($declared_type_name) && !ref($declared_type_name);
    return undef unless $class->is_aggregate_type_spec($declared_type_spec);

    my $key = $class->_aggregate_typedef_lookup_key($declared_type_name, $declared_type_spec);
    return $aggregate_typedef_lookup->{$key};
}

sub is_aggregate_type_spec ($class, $type_spec) {
    return 0 unless ref($type_spec) eq 'HASH';
    my $kind = $type_spec->{kind} || '';
    return ($kind eq 'list' || $kind eq 'record') ? 1 : 0;
}

sub render_scalar_data_type ($class, $type_spec) {
    my $kind = ref($type_spec) eq 'HASH' ? ($type_spec->{kind} || '') : '';
    my $state_model = ref($type_spec) eq 'HASH' ? $type_spec->{state_model} : undef;
    my $state_keyword = $class->state_model_keyword($state_model) // 'logic';
    my $signed = (ref($type_spec) eq 'HASH' && ($type_spec->{signed} // 0)) ? ' signed' : '';

    return "${state_keyword}${signed}" if $kind eq 'bit';

    if ($kind eq 'bits') {
        my $width = $type_spec->{width} || 1;
        return sprintf("%s%s [%d:0]", $state_keyword, $signed, $width - 1);
    }

    confess "scalar type renderer only supports bit/bits kinds";
}

sub state_model_keyword ($class, $state_model) {
    return undef unless defined $state_model && !ref($state_model);
    return 'bit' if $state_model eq 'two_state';
    return 'logic' if $state_model eq 'four_state';
    return undef;
}

sub _aggregate_typedef_lookup_key ($class, $declared_type_name, $declared_type_spec) {
    return join("\n", $declared_type_name, FSM::Package::PayloadTypeSupport->type_spec_label($declared_type_spec));
}

sub _unique_typedef_name ($class, $declared_type_name, $used_typedef_names) {
    my $base = $declared_type_name;
    $base =~ s/[^A-Za-z0-9_]+/__/g;
    $base = "_$base" if $base !~ /\A[A-Za-z_]/;
    $base .= '__fsmgen_t';

    my $candidate = $base;
    my $suffix = 2;
    while ($used_typedef_names->{$candidate}) {
        $candidate = "${base}_${suffix}";
        $suffix++;
    }

    $used_typedef_names->{$candidate} = 1;
    return $candidate;
}

sub _render_aggregate_typedef_lines ($class, $typedef_name, $declared_type_name, $declared_type_spec) {
    my @lines = ("typedef struct packed {");
    push @lines, $class->_render_aggregate_member_lines($declared_type_spec, '    ');
    push @lines, "} $typedef_name; // $declared_type_name";
    return @lines;
}

sub _render_aggregate_member_lines ($class, $type_spec, $indent) {
    my $kind = ref($type_spec) eq 'HASH' ? ($type_spec->{kind} || '') : '';

    if ($kind eq 'list') {
        my $items = $type_spec->{items} || [];
        my @lines;
        for my $index (0 .. $#$items) {
            my $item_spec = $items->[$index];
            push @lines, $class->_render_type_field_lines($item_spec, "item_$index", $indent);
        }
        return @lines;
    }

    if ($kind eq 'record') {
        my @lines;
        for my $member_name (@{ $type_spec->{member_order} || [] }) {
            my $member_spec = ($type_spec->{members} || {})->{$member_name};
            push @lines, $class->_render_type_field_lines($member_spec, $member_name, $indent);
        }
        return @lines;
    }

    confess "aggregate typedef rendering requires list/record type specs";
}

sub _render_type_field_lines ($class, $type_spec, $field_name, $indent) {
    my $kind = ref($type_spec) eq 'HASH' ? ($type_spec->{kind} || '') : '';

    if ($kind eq 'bit' || $kind eq 'bits') {
        return sprintf("%s%s %s;", $indent, $class->render_scalar_data_type($type_spec), $field_name);
    }

    if ($kind eq 'list' || $kind eq 'record') {
        my @lines = ("${indent}struct packed {");
        push @lines, $class->_render_aggregate_member_lines($type_spec, $indent . '    ');
        push @lines, "${indent}} $field_name;";
        return @lines;
    }

    confess "unsupported aggregate member type kind '$kind' during Verilog-family typedef rendering";
}

1;

__END__

=head1 METHODS

=head2 typedef_state

Creates one reusable typedef collection state for a module emission run.

=head2 collect_declared_aggregate_typedefs

Collects new packed typedef lines for entries that preserve aggregate
C<declared_type_name> / C<declared_type_spec> contracts.

=head2 aggregate_typedef_name_for

Returns the already-collected typedef name for one typed entry.

=head2 render_scalar_data_type

Renders the scalar leaf data type used inside generated packed typedefs.

=cut
