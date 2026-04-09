package FSM::Backend::VerilogFamily::StructuralRTLIREmitter;

=head1 NAME

FSM::Backend::VerilogFamily::StructuralRTLIREmitter - Verilog-family structural RTL IR emitter

=head1 DESCRIPTION

Emits Verilog-family HDL text by walking the extracted forward
C<StructuralRTLIR> layer. This package is the beginning of the planned split
where backend text generation consumes structural connectivity rather than
re-deriving structure inside the pipeline coordinator.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::IR::StructuralRTLIR::ConnectionExpr qw(binding_expr_text);
use FSM::Package::PayloadTypeSupport;

sub emit_module ($class, $structural_rtl_ir) {
    my $structural = blessed($structural_rtl_ir) && $structural_rtl_ir->can('as_hashref')
        ? $structural_rtl_ir->as_hashref
        : ref($structural_rtl_ir) eq 'HASH'
            ? $structural_rtl_ir
            : {};

    my $target_language = $structural->{target_language} // 'systemverilog';
    confess "StructuralRTLIR verilog-family emitter only supports systemverilog/verilog target_language values"
        unless $target_language =~ /^(?:systemverilog|sv|verilog|v)$/;

    my $top_name = $structural->{module_name}
        // confess "StructuralRTLIR verilog-family emitter requires module_name";
    my @ports = @{$structural->{ports} || []};
    my @nets = @{$structural->{nets} || []};
    my @instances = @{$structural->{instances} || []};
    my @auxiliary_assignments = @{$structural->{auxiliary_assignments} || []};
    my ($typedef_lines, $aggregate_typedef_lookup) = _collect_declared_aggregate_typedefs(\@ports, \@nets);

    my @port_lines = map { _render_port_line($_, $aggregate_typedef_lookup) } @ports;

    my @net_lines = map { _render_net_line($_, $aggregate_typedef_lookup) } @nets;

    my @instance_blocks = map {
        my $instance = $_;
        my @connection_lines = map {
            sprintf("        .%s(%s)", $_->{port_name}, binding_expr_text($_, $target_language))
        } @{$instance->{port_bindings} || []};

        join("\n",
            "    ".$instance->{module_name}." ".$instance->{instance_name}." (",
            join(",\n", @connection_lines),
            "    );",
        );
    } @instances;

    my @body_lines;
    push @body_lines, @$typedef_lines, "" if @$typedef_lines;
    push @body_lines,
        "module $top_name (",
        join(",\n", @port_lines),
        ");";

    push @body_lines, "", @net_lines if @net_lines;
    push @body_lines, "", @auxiliary_assignments if @auxiliary_assignments;
    push @body_lines, "", join("\n\n", @instance_blocks), "" if @instance_blocks;
    push @body_lines, "endmodule";

    return join("\n", @body_lines);
}

sub _render_port_line ($port, $aggregate_typedef_lookup) {
    my $typedef_name = _aggregate_typedef_name_for($port, $aggregate_typedef_lookup);
    return sprintf("    %s %s %s", $port->{direction}, $typedef_name, $port->{name})
        if defined $typedef_name;

    my $width = ($port->{width} || 1) > 1 ? sprintf("[%d:0] ", $port->{width} - 1) : '';
    my $signed = ($port->{signed} // 0) ? 'signed ' : '';
    my $state_model = _state_model_keyword($port->{state_model});
    my $type_prefix = defined($state_model) ? "${state_model} ${signed}" : $signed;
    return sprintf("    %s %s%s%s", $port->{direction}, $type_prefix, $width, $port->{name});
}

sub _render_net_line ($net, $aggregate_typedef_lookup) {
    my $typedef_name = _aggregate_typedef_name_for($net, $aggregate_typedef_lookup);
    if (defined $typedef_name) {
        my $declaration_keyword = $net->{declaration_keyword} // 'wire';
        return $declaration_keyword eq 'wire'
            ? sprintf("    wire %s %s;", $typedef_name, $net->{name})
            : sprintf("    %s %s;", $typedef_name, $net->{name});
    }

    my $width = ($net->{width} || 1) > 1 ? sprintf("[%d:0] ", $net->{width} - 1) : '';
    my $signed = ($net->{signed} // 0) ? 'signed ' : '';
    my $declaration_keyword = $net->{declaration_keyword} // 'wire';
    my $state_model = _state_model_keyword($net->{state_model});
    my $type_prefix = $declaration_keyword eq 'wire'
        ? (defined($state_model) ? "${state_model} ${signed}" : $signed)
        : $signed;
    return sprintf("    %s %s%s%s;", $declaration_keyword, $type_prefix, $width, $net->{name});
}

sub _aggregate_typedef_name_for ($entry, $aggregate_typedef_lookup) {
    return undef unless ref($entry) eq 'HASH' && ref($aggregate_typedef_lookup) eq 'HASH';

    my $declared_type_name = $entry->{declared_type_name};
    my $declared_type_spec = $entry->{declared_type_spec};
    return undef unless defined($declared_type_name) && !ref($declared_type_name);
    return undef unless _is_aggregate_type_spec($declared_type_spec);

    my $key = _aggregate_typedef_lookup_key($declared_type_name, $declared_type_spec);
    return $aggregate_typedef_lookup->{$key};
}

sub _collect_declared_aggregate_typedefs ($ports, $nets) {
    my %aggregate_typedef_lookup;
    my %used_typedef_names;
    my @typedef_lines;

    for my $entry (@{$ports || []}, @{$nets || []}) {
        next unless ref($entry) eq 'HASH';

        my $declared_type_name = $entry->{declared_type_name};
        my $declared_type_spec = $entry->{declared_type_spec};
        next unless defined($declared_type_name) && !ref($declared_type_name);
        next unless _is_aggregate_type_spec($declared_type_spec);

        my $key = _aggregate_typedef_lookup_key($declared_type_name, $declared_type_spec);
        next if exists $aggregate_typedef_lookup{$key};

        my $typedef_name = _unique_typedef_name($declared_type_name, \%used_typedef_names);
        $aggregate_typedef_lookup{$key} = $typedef_name;
        push @typedef_lines, _render_aggregate_typedef_lines($typedef_name, $declared_type_name, $declared_type_spec), "";
    }

    pop @typedef_lines if @typedef_lines && $typedef_lines[-1] eq '';
    return (\@typedef_lines, \%aggregate_typedef_lookup);
}

sub _aggregate_typedef_lookup_key ($declared_type_name, $declared_type_spec) {
    return join("\n", $declared_type_name, FSM::Package::PayloadTypeSupport->type_spec_label($declared_type_spec));
}

sub _is_aggregate_type_spec ($type_spec) {
    return 0 unless ref($type_spec) eq 'HASH';
    my $kind = $type_spec->{kind} || '';
    return ($kind eq 'list' || $kind eq 'record') ? 1 : 0;
}

sub _unique_typedef_name ($declared_type_name, $used_typedef_names) {
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

sub _render_aggregate_typedef_lines ($typedef_name, $declared_type_name, $declared_type_spec) {
    my @lines = ("typedef struct packed {");
    push @lines, _render_aggregate_member_lines($declared_type_spec, '    ');
    push @lines, "} $typedef_name; // $declared_type_name";
    return @lines;
}

sub _render_aggregate_member_lines ($type_spec, $indent) {
    my $kind = ref($type_spec) eq 'HASH' ? ($type_spec->{kind} || '') : '';

    if ($kind eq 'list') {
        my $items = $type_spec->{items} || [];
        my @lines;
        for my $index (0 .. $#$items) {
            my $item_spec = $items->[$index];
            push @lines, _render_type_field_lines($item_spec, "item_$index", $indent);
        }
        return @lines;
    }

    if ($kind eq 'record') {
        my @lines;
        for my $member_name (@{ $type_spec->{member_order} || [] }) {
            my $member_spec = ($type_spec->{members} || {})->{$member_name};
            push @lines, _render_type_field_lines($member_spec, $member_name, $indent);
        }
        return @lines;
    }

    confess "aggregate typedef rendering requires list/record type specs";
}

sub _render_type_field_lines ($type_spec, $field_name, $indent) {
    my $kind = ref($type_spec) eq 'HASH' ? ($type_spec->{kind} || '') : '';

    if ($kind eq 'bit' || $kind eq 'bits') {
        return sprintf("%s%s %s;", $indent, _render_scalar_data_type($type_spec), $field_name);
    }

    if ($kind eq 'list' || $kind eq 'record') {
        my @lines = ("${indent}struct packed {");
        push @lines, _render_aggregate_member_lines($type_spec, $indent . '    ');
        push @lines, "${indent}} $field_name;";
        return @lines;
    }

    confess "unsupported aggregate member type kind '$kind' during structural typedef rendering";
}

sub _render_scalar_data_type ($type_spec) {
    my $kind = ref($type_spec) eq 'HASH' ? ($type_spec->{kind} || '') : '';
    my $state_keyword = _state_model_keyword($type_spec->{state_model}) // 'logic';
    my $signed = ($type_spec->{signed} // 0) ? ' signed' : '';

    return "${state_keyword}${signed}" if $kind eq 'bit';

    if ($kind eq 'bits') {
        my $width = $type_spec->{width} || 1;
        return sprintf("%s%s [%d:0]", $state_keyword, $signed, $width - 1);
    }

    confess "scalar type renderer only supports bit/bits kinds";
}

sub _state_model_keyword ($state_model) {
    return undef unless defined $state_model && !ref($state_model);
    return 'bit' if $state_model eq 'two_state';
    return 'logic' if $state_model eq 'four_state';
    return undef;
}

1;

__END__

=head1 METHODS

=head2 emit_module

Renders one structural RTL IR module into SystemVerilog or Verilog-family text
using the explicit structural ports, nets, instances, bindings, and auxiliary
assignments already present in the IR.

=cut
