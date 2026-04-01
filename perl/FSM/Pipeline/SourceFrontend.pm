package FSM::Pipeline::SourceFrontend;

=head1 NAME

FSM::Pipeline::SourceFrontend - Frontend owner for source parsing and semantic module creation

=head1 DESCRIPTION

Owns the bounded source-frontend family that was still sitting inline in
C<FSM::Pipeline::HDLGenerator>. This package parses one C<.fsm> file with the
Lispish reader, classifies the top-level source kind, parses composition
sources into typed composition specs, and turns direct-root raw AST into the
semantic FSM/DT module used by later pipeline stages.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use Data::Dumper;
use FSM::Adapter::FSMGenFull;
use FSM::Composition::Parser;
use FSM::Debug;
use FSM::SourceClassifier;
use Lispish;

sub parse_fsm_file ($class, %args) {
    my $fsm_file = $args{fsm_file}
        or confess "SourceFrontend requires an fsm_file";
    my $debug_level = $args{debug_level} // 0;

    fsm_trace_enter('Parse FSM file with Lispish', 2);
    fsm_debug("Parsing FSM file with Lispish parser", 1);

    my $raw_ast = Lispish::multi($fsm_file);

    unless ($raw_ast) {
        fsm_trace_decision(0, "Lispish parser returned undefined AST for '$fsm_file'", 1);
        confess "Error: Failed to parse FSM file with Lispish\n";
    }

    if ($debug_level > 0) {
        fsm_debug("Raw AST structure:", 2);
        if ($debug_level >= 3) {
            local $Data::Dumper::Maxdepth = 0;
            local $Data::Dumper::Indent = 1;
            my $dumped = Dumper($raw_ast);
            fsm_debug("Full raw AST dump:\n$dumped", 3);
        }
    }

    fsm_debug("FSM file parsed successfully", 1);
    fsm_trace_exit('FSM file parsed', 2);
    return $raw_ast;
}

sub classify_source_ast ($class, $raw_ast) {
    return FSM::SourceClassifier::classify_source_ast($raw_ast);
}

sub parse_composition_source ($class, %args) {
    my $raw_ast = $args{raw_ast}
        or confess "SourceFrontend requires a raw_ast";
    my $debug_level = $args{debug_level} // 0;

    my $parser = FSM::Composition::Parser->new(
        debug => ($debug_level > 0),
    );
    return $parser->parse_source($raw_ast);
}

sub enforce_strict_source_boundary ($class, %args) {
    return unless $args{strict_mode};

    my $source_info = $args{source_info}
        || $class->classify_source_ast($args{raw_ast});
    my $header = $source_info->{header} // '';
    my $source_label = $args{source_label} // ($header || 'source');

    if ($header eq '+fsm') {
        confess
            "Strict mode rejects the legacy '+fsm' root family for source '$source_label'. "
          . "Use the modern '?fsm:module_name' root form instead of '+fsm', "
          . "or re-run without strict mode if you need legacy compatibility. "
          . "See docs/USER_GUIDE.md for the current strict-mode boundary.\n";
    }

    my $body_items = $class->_direct_root_body_items(
        raw_ast => $args{raw_ast},
        source_info => $source_info,
    );
    if ($body_items) {
        for my $item (@$body_items) {
            next unless $class->_is_legacy_empty_size_section($item);

            confess
                "Strict mode rejects the legacy empty '(+size)' section in source '$source_label'. "
              . "Remove the empty section or replace it with explicit '(+size (signal width) ...)' entries, "
              . "or re-run without strict mode if you need legacy compatibility. "
              . "See docs/USER_GUIDE.md for the current strict-mode boundary.\n";
        }

        for my $item (@$body_items) {
            next unless $class->_has_legacy_asreset_system_entry($item);

            confess
                "Strict mode rejects the legacy '(asreset rstn)' +system spelling in source '$source_label'. "
              . "Use the canonical '(sreset rstn)' form inside '+system', "
              . "or re-run without strict mode if you need legacy compatibility. "
              . "See docs/USER_GUIDE.md for the current strict-mode boundary.\n";
        }
    }
}

sub enforce_strict_generated_child_source_boundary ($class, %args) {
    return unless $args{strict_mode};

    my $declared_child_kind = $args{declared_child_kind}
        or confess "SourceFrontend requires a declared_child_kind";
    my $source_info = $args{source_info}
        || $class->classify_source_ast($args{raw_ast});
    my $header = $source_info->{header} // '';
    my $source_label = $args{source_label} // ($header || 'source');

    if ($declared_child_kind eq '?fsmc' && $header eq '+fsm') {
        confess
            "Strict mode rejects the legacy '+fsm' root family as the root of '$declared_child_kind' source '$source_label'. "
          . "Use the canonical '?fsm:source_name' root form for FSM child sources, "
          . "or re-run without strict mode if you need legacy compatibility. "
          . "See docs/USER_GUIDE.md for the current strict-mode boundary.\n";
    }

    if ($declared_child_kind eq '?dtc' && $header =~ /^\?(?:mod|module):/) {
        confess
            "Strict mode rejects '$header' as the root of '$declared_child_kind' source '$source_label'. "
          . "Use the canonical '?dt:source_name' root form for standalone-DT child sources, "
          . "or re-run without strict mode if you need compatibility with the current shared implementation path. "
          . "See docs/USER_GUIDE.md for the current strict-mode boundary.\n";
    }
}

sub create_fsm_module ($class, %args) {
    my $raw_ast = $args{raw_ast}
        or confess "SourceFrontend requires a raw_ast";
    my $debug_level = $args{debug_level} // 0;

    $class->enforce_strict_source_boundary(
        raw_ast => $raw_ast,
        strict_mode => ($args{strict_mode} // 0),
        source_label => $args{source_label},
    );

    fsm_trace_enter('Build semantic FSM module from raw AST', 2);
    fsm_debug("Creating semantic FSM module from raw AST", 1);

    my $adapter = FSM::Adapter::FSMGenFull->new(debug => ($debug_level > 0));

    my $fsm_module;
    eval {
        $fsm_module = $adapter->parse_fsm($raw_ast);
    };

    if ($@) {
        fsm_trace_decision(0, 'Adapter parse_fsm() raised exception', 1);
        confess "Error parsing FSM with adapter: $@\n";
    }

    unless ($fsm_module) {
        fsm_trace_decision(0, 'Adapter parse_fsm() returned undefined module', 1);
        confess "Error: Failed to create FSM module\n";
    }

    if ($debug_level > 1 && $fsm_module) {
        fsm_debug("Semantic FSM module created successfully", 1);
        if ($debug_level >= 3) {
            local $Data::Dumper::Maxdepth = 0;
            local $Data::Dumper::Indent = 1;
            my $dumped = Dumper($fsm_module);
            fsm_debug("Full FSM module AST dump:\n$dumped", 3);
        }
    }

    fsm_debug("FSM module created successfully", 1);
    fsm_trace_exit('Semantic FSM module created', 2);
    return $fsm_module;
}

sub _direct_root_body_items ($class, %args) {
    my $raw_ast = $args{raw_ast};
    return undef unless ref($raw_ast) eq 'ARRAY';

    my $source_info = $args{source_info}
        || $class->classify_source_ast($raw_ast);
    my $kind = $source_info->{kind} // '';
    return undef unless $kind eq 'fsm' || $kind eq 'dt';

    my $header = $source_info->{header} // '';

    if (@$raw_ast > 0 && !ref($raw_ast->[0])) {
        if ($header =~ /^\?(?:fsm|dt|mod|module):/) {
            return ref($raw_ast->[1]) eq 'ARRAY' ? $raw_ast->[1] : undef;
        }

        if ($header eq '+fsm' && ref($raw_ast->[1]) eq 'ARRAY') {
            my @body = @{$raw_ast->[1]} > 1 ? @{$raw_ast->[1]}[1 .. $#{$raw_ast->[1]}] : ();
            return \@body;
        }
    }

    if (@$raw_ast > 0 && ref($raw_ast->[0]) eq 'ARRAY') {
        my $first = $raw_ast->[0];
        my $first_header = $first->[0];

        if (defined($first_header) && !ref($first_header) && $first_header =~ /^\?(?:fsm|dt|mod|module):/) {
            return ref($first->[1]) eq 'ARRAY' ? $first->[1] : undef;
        }

        if (defined($first_header) && !ref($first_header) && $first_header eq '+fsm') {
            if (@$raw_ast == 1) {
                my $payload = $first->[1];
                return [] unless ref($payload) eq 'ARRAY';
                my @body = @$payload > 1 ? @$payload[1 .. $#$payload] : ();
                return \@body;
            }

            my @body = @$raw_ast > 1 ? @$raw_ast[1 .. $#$raw_ast] : ();
            return \@body;
        }
    }

    return undef;
}

sub _is_legacy_empty_size_section ($class, $node) {
    return 0 unless ref($node) eq 'ARRAY';
    return 0 unless defined($node->[0]) && !ref($node->[0]) && $node->[0] eq '+size';
    return 1 if @$node == 1;
    return 1 if @$node == 2 && !defined($node->[1]);
    return 0;
}

sub _has_legacy_asreset_system_entry ($class, $node) {
    return 0 unless ref($node) eq 'ARRAY';
    return 0 unless defined($node->[0]) && !ref($node->[0]) && $node->[0] eq '+system';
    return 0 unless ref($node->[1]) eq 'ARRAY';

    for my $entry (@{$node->[1]}) {
        next unless ref($entry) eq 'ARRAY';
        next unless defined($entry->[0]) && !ref($entry->[0]);
        return 1 if $entry->[0] eq 'asreset';
    }

    return 0;
}

1;

__END__

=head1 METHODS

=head2 parse_fsm_file

Parses one C<.fsm> file with the Lispish reader and returns the raw AST.

=head2 classify_source_ast

Classifies one raw AST into the current direct-root or composition source kind
surface.

=head2 parse_composition_source

Parses one already-classified composition raw AST into the typed composition
spec consumed by the composition generation path.

=head2 create_fsm_module

Builds one semantic FSM/DT module from a direct-root raw AST through the
current C<FSMGenFull> adapter.

=head2 enforce_strict_source_boundary

Checks the current strict-mode root-family boundary for one direct-root source
before semantic module creation.

=head2 enforce_strict_generated_child_source_boundary

Checks the current strict-mode boundary for one generated composition child
source before semantic child realization continues.

=cut
