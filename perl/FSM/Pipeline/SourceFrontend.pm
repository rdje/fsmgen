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
use FSM::Adapter::FSMGenFull::ExpressionBuilder;
use FSM::Adapter::FSMGenFull::SignalManager;
use FSM::Composition::Parser;
use FSM::Debug;
use FSM::Package::ImportResolver;
use FSM::Package::SignalManagerProjectionSupport;
use FSM::SourceClassifier;
use FSM::SourcePathResolver;
use Lispish;

sub parse_fsm_file ($class, %args) {
    my $fsm_file = $args{fsm_file}
        or confess "SourceFrontend requires an fsm_file";
    my $debug_level = $args{debug_level} // 0;

    fsm_trace_enter('Parse FSM file with Lispish', 2);
    fsm_debug("Parsing FSM file with Lispish parser", 1);

    my $source_text = $class->_slurp_fsm_file($fsm_file);
    my $prepared_source_text = $class->_protect_braces_inside_slash_tokens($source_text);

    my $raw_ast = Lispish::multi(\$prepared_source_text);

    $class->_restore_preserved_slash_token_braces($raw_ast);

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

sub _slurp_fsm_file ($class, $fsm_file) {
    open my $fh, '<', $fsm_file
        or confess "Error: Failed to open FSM file '$fsm_file': $!";
    local $/;
    my $source_text = <$fh>;
    close $fh
        or confess "Error: Failed to close FSM file '$fsm_file': $!";

    unless (defined $source_text && length $source_text) {
        confess "(Lispish::multi) -E- File '$fsm_file' is either empty or does not exit,";
    }

    return $source_text;
}

sub _protect_braces_inside_slash_tokens ($class, $source_text) {
    my $left_placeholder = $class->_slash_token_left_brace_placeholder;
    my $right_placeholder = $class->_slash_token_right_brace_placeholder;

    if (index($source_text, $left_placeholder) >= 0 || index($source_text, $right_placeholder) >= 0) {
        confess "Internal error: slash-token brace-preservation placeholder collision in FSM source";
    }

    my $protected = q{};
    my $index = 0;
    my $length = length($source_text);

    while ($index < $length) {
        my ($token, $end_index) = $class->_consume_slash_token($source_text, $index);
        if (defined $token) {
            $token =~ s/\{/$left_placeholder/g;
            $token =~ s/\}/$right_placeholder/g;
            $protected .= $token;
            $index = $end_index + 1;
            next;
        }

        $protected .= substr($source_text, $index, 1);
        $index++;
    }

    return $protected;
}

sub _consume_slash_token ($class, $source_text, $start_index) {
    return unless substr($source_text, $start_index, 1) eq '/';

    my $previous = $start_index > 0 ? substr($source_text, $start_index - 1, 1) : q{};
    return unless !length($previous) || $previous =~ /[\s\("\']/;

    my $length = length($source_text);
    my $slash_count = 0;
    my $end_index = undef;

    for (my $cursor = $start_index; $cursor < $length; $cursor++) {
        my $char = substr($source_text, $cursor, 1);
        next unless $char eq '/';

        $slash_count++;
        if ($slash_count == 3) {
            $end_index = $cursor;
            last;
        }
    }

    return unless defined $end_index;

    my $following = $end_index + 1 < $length ? substr($source_text, $end_index + 1, 1) : q{};
    return unless !length($following) || $following =~ /[\s\)"\';]/;

    return (substr($source_text, $start_index, $end_index - $start_index + 1), $end_index);
}

sub _restore_preserved_slash_token_braces ($class, $raw_ast) {
    return unless defined $raw_ast;

    if (ref($raw_ast) eq 'ARRAY') {
        for my $item (@$raw_ast) {
            if (ref($item)) {
                $class->_restore_preserved_slash_token_braces($item);
                next;
            }

            next unless defined $item;
            $item =~ s/\Q@{[$class->_slash_token_left_brace_placeholder]}\E/\{/g;
            $item =~ s/\Q@{[$class->_slash_token_right_brace_placeholder]}\E/\}/g;
        }
    }
}

sub _slash_token_left_brace_placeholder ($class) {
    return '__FSMGEN_SLASH_TOKEN_LBRACE_PLACEHOLDER_7AF5A6B7__';
}

sub _slash_token_right_brace_placeholder ($class) {
    return '__FSMGEN_SLASH_TOKEN_RBRACE_PLACEHOLDER_7AF5A6B7__';
}

sub classify_source_ast ($class, $raw_ast) {
    my $source_info = FSM::SourceClassifier::classify_source_ast($raw_ast);
    return $class->_augment_source_info_package_import_summary(
        raw_ast => $raw_ast,
        source_info => $source_info,
    );
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

sub _augment_source_info_package_import_summary ($class, %args) {
    my $source_info = $args{source_info} || {};
    my $package_imports = $class->_safe_source_package_imports(
        raw_ast => $args{raw_ast},
        source_info => $source_info,
    );
    return $source_info unless defined $package_imports;

    $source_info->{package_import_names} = [ @$package_imports ];
    $source_info->{package_import_count} = scalar(@$package_imports);
    return $source_info;
}

sub _safe_source_package_imports ($class, %args) {
    my $source_info = $args{source_info} || {};
    my $kind = $source_info->{kind} // '';

    if ($kind eq 'fsm' || $kind eq 'dt') {
        return $class->_safe_direct_root_package_imports(%args);
    }
    if ($kind eq 'composition') {
        return $class->_safe_composition_package_imports(%args);
    }
    if ($kind eq 'package') {
        return [];
    }

    return undef;
}

sub _safe_direct_root_package_imports ($class, %args) {
    my $source_info = $args{source_info}
        || FSM::SourceClassifier::classify_source_ast($args{raw_ast});
    my $body_items = $class->_direct_root_body_items(
        raw_ast => $args{raw_ast},
        source_info => $source_info,
    );
    return undef unless $body_items;

    my @package_imports;
    my $saw_import_block = 0;
    for my $item (@$body_items) {
        next unless ref($item) eq 'ARRAY';
        next unless defined($item->[0]) && !ref($item->[0]) && $item->[0] eq '+import';
        $saw_import_block = 1;

        my $imports_list = $item->[1];
        return undef unless ref($imports_list) eq 'ARRAY' && @$imports_list;

        for my $package_name (@$imports_list) {
            my $resolved_name = $class->_unwrap_scalar_token($package_name);
            return undef unless defined($resolved_name) && !ref($resolved_name) && $resolved_name =~ /\A[A-Za-z_]\w*\z/;
            push @package_imports, $resolved_name;
        }
    }

    return [] unless $saw_import_block;
    return \@package_imports;
}

sub _safe_composition_package_imports ($class, %args) {
    my $source_info = $args{source_info}
        || FSM::SourceClassifier::classify_source_ast($args{raw_ast});
    my $body_items = $class->_composition_body_items(
        raw_ast => $args{raw_ast},
        source_info => $source_info,
    );
    return undef unless $body_items;

    my @package_imports;
    my $saw_import_block = 0;
    for my $item (@$body_items) {
        next unless ref($item) eq 'ARRAY';
        next unless defined($item->[0]) && !ref($item->[0]) && $item->[0] eq '+import';
        $saw_import_block = 1;

        my $imports_list = $item->[1];
        return undef unless ref($imports_list) eq 'ARRAY' && @$imports_list;

        for my $package_name (@$imports_list) {
            my $resolved_name = $class->_unwrap_scalar_token($package_name);
            return undef unless defined($resolved_name) && !ref($resolved_name) && $resolved_name =~ /\A[A-Za-z_]\w*\z/;
            push @package_imports, $resolved_name;
        }
    }

    return [] unless $saw_import_block;
    return \@package_imports;
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

    if ($header =~ /^\?module:/) {
        confess
            "Strict mode rejects the legacy '?module:' direct-root alias for source '$source_label'. "
          . "Use the canonical '?mod:module_name' root form for module/entity-architecture roots, "
          . "or re-run without strict mode if you need compatibility with the current shared implementation path. "
          . "See docs/USER_GUIDE.md for the current strict-mode boundary.\n";
    }

    return if $header =~ /^\?mod:/;

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
            my $reset_issue = $class->_strict_system_reset_contract_issue($item);
            next unless $reset_issue;

            confess
                "Strict mode rejects the legacy or misleading '$reset_issue->{form}' +system spelling in source '$source_label'. "
              . "Use '(sreset reset)' for synchronous active-high reset or '(areset rst_n)' for asynchronous active-low reset, "
              . "or re-run without strict mode if you need legacy compatibility. "
              . "See docs/USER_GUIDE.md for the current strict-mode boundary.\n";
        }

        for my $item (@$body_items) {
            next unless $class->_is_legacy_compact_init_directive($item);

            confess
                "Strict mode rejects the legacy compact '(:= signal=value)' top-level directive in source '$source_label'. "
              . "Use the canonical '(:= (signal value))' form for strict-mode init/default metadata, "
              . "or re-run without strict mode if you still need the compact ':=' surface. "
              . "See docs/USER_GUIDE.md for the current strict-mode boundary.\n";
        }

        if (my $infix_issue = $class->_find_strict_infix_assignment_issue($body_items)) {
            confess
                "Strict mode rejects infix assignment '$infix_issue->{display}' in source '$source_label'. "
              . "Use the canonical pair form '$infix_issue->{canonical_hint}' for strict-mode assignment intent, "
              . "or re-run without strict mode if you still need infix assignment compatibility. "
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
    my $source_info = $args{source_info}
        || $class->classify_source_ast($raw_ast);
    my $source_header = $source_info->{header} // 'direct source';
    my $source_path_resolver = $args{source_path_resolver}
        // FSM::SourcePathResolver->new();
    my $frontend_context = ref($args{frontend_context}) eq 'HASH'
        ? $args{frontend_context}
        : undef;

    $class->enforce_strict_source_boundary(
        raw_ast => $raw_ast,
        strict_mode => ($args{strict_mode} // 0),
        source_label => $args{source_label},
    );

    fsm_trace_enter('Build semantic FSM module from raw AST', 2);
    fsm_debug("Creating semantic FSM module from raw AST", 1);

    my $signal_manager = FSM::Adapter::FSMGenFull::SignalManager->new(
        debug => ($debug_level > 0),
    );
    my $package_imports = $class->_direct_root_package_imports(
        raw_ast => $raw_ast,
        source_info => $source_info,
        source_label => ($args{source_label} // $source_header),
    );
    my $resolved_package_imports = {};
    if (@$package_imports) {
        $resolved_package_imports = FSM::Package::ImportResolver->resolve_imports(
            package_imports => $package_imports,
            embedded_package_sources => $class->collect_embedded_package_sources($raw_ast),
            fsm_file => $args{fsm_file},
            source_path_resolver => $source_path_resolver,
            owner_label => "Direct source '$source_header'" . (
                defined($args{fsm_file}) && length($args{fsm_file})
                    ? " in '$args{fsm_file}'"
                    : ''
            ),
            debug_level => $debug_level,
            docs_hint => " See docs/USER_GUIDE.md for the current package boundary.\n",
        );
        $class->_import_package_symbols_into_signal_manager(
            signal_manager => $signal_manager,
            resolved_package_imports => $resolved_package_imports,
            package_imports => $package_imports,
            debug_level => $debug_level,
        );
    }

    my $adapter = FSM::Adapter::FSMGenFull->new(
        debug => ($debug_level > 0),
        signal_manager => $signal_manager,
    );

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

    if (@$package_imports) {
        $fsm_module->{attributes}{package_imports} = [ @$package_imports ];
    }
    if ($frontend_context) {
        $frontend_context->{package_imports} = [ @$package_imports ];
        $frontend_context->{resolved_package_imports} = $resolved_package_imports;
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
            return ref($raw_ast->[1]) eq 'ARRAY' ? _clone($raw_ast->[1]) : undef;
        }

        if ($header eq '+fsm' && ref($raw_ast->[1]) eq 'ARRAY') {
            my @body = @{$raw_ast->[1]} > 1 ? @{$raw_ast->[1]}[1 .. $#{$raw_ast->[1]}] : ();
            return _clone(\@body);
        }
    }

    if (@$raw_ast > 0 && ref($raw_ast->[0]) eq 'ARRAY') {
        my $first = $raw_ast->[0];
        my $first_header = $first->[0];

        if (defined($first_header) && !ref($first_header) && $first_header =~ /^\?(?:fsm|dt|mod|module):/) {
            return ref($first->[1]) eq 'ARRAY' ? _clone($first->[1]) : undef;
        }

        if (defined($first_header) && !ref($first_header) && $first_header eq '+fsm') {
            if (@$raw_ast == 1) {
                my $payload = $first->[1];
                return [] unless ref($payload) eq 'ARRAY';
                my @body = @$payload > 1 ? @$payload[1 .. $#$payload] : ();
                return _clone(\@body);
            }

            my @body = @$raw_ast > 1 ? @$raw_ast[1 .. $#$raw_ast] : ();
            return _clone(\@body);
        }
    }

    return undef;
}

sub _composition_body_items ($class, %args) {
    my $raw_ast = $args{raw_ast};
    return undef unless ref($raw_ast) eq 'ARRAY';

    my $source_info = $args{source_info}
        || FSM::SourceClassifier::classify_source_ast($raw_ast);
    return undef unless ($source_info->{kind} // '') eq 'composition';

    my $header = $source_info->{header} // '';

    if (@$raw_ast > 0 && !ref($raw_ast->[0]) && $raw_ast->[0] eq $header) {
        return _clone($raw_ast->[1]) if @$raw_ast > 1 && ref($raw_ast->[1]) eq 'ARRAY';
    }

    for my $ast_node (@$raw_ast) {
        next unless ref($ast_node) eq 'ARRAY' && @$ast_node > 1;
        next if ref($ast_node->[0]);
        next unless $ast_node->[0] eq $header;
        return _clone($ast_node->[1]) if ref($ast_node->[1]) eq 'ARRAY';
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

sub _strict_system_reset_contract_issue ($class, $node) {
    return 0 unless ref($node) eq 'ARRAY';
    return 0 unless defined($node->[0]) && !ref($node->[0]) && $node->[0] eq '+system';
    return 0 unless ref($node->[1]) eq 'ARRAY';

    for my $entry (@{$node->[1]}) {
        next unless ref($entry) eq 'ARRAY';
        next unless defined($entry->[0]) && !ref($entry->[0]);
        my ($directive, $name) = @$entry;
        next unless defined($directive) && !ref($directive);
        next unless $directive eq 'sreset' || $directive eq 'areset' || $directive eq 'asreset';
        my $unwrapped_name = $class->_unwrap_scalar_token($name);
        my $reset_name = defined($unwrapped_name) && !ref($unwrapped_name) ? $unwrapped_name : 'unknown';
        my $form = "($directive $reset_name)";

        return { form => $form, reason => 'legacy_asreset_alias' }
            if $directive eq 'asreset';
        return { form => $form, reason => 'active_high_name_looks_active_low' }
            if $directive eq 'sreset' && $class->_looks_active_low_reset_name($reset_name);
        return { form => $form, reason => 'active_low_name_does_not_look_active_low' }
            if $directive eq 'areset' && !$class->_looks_active_low_reset_name($reset_name);
    }

    return 0;
}

sub _looks_active_low_reset_name ($class, $reset_name) {
    return defined($reset_name)
        && $reset_name =~ /(?:_n|n)\z/i;
}

sub _is_legacy_compact_init_directive ($class, $node) {
    return 0 unless ref($node) eq 'ARRAY';
    return 0 unless defined($node->[0]) && !ref($node->[0]) && $node->[0] eq ':=';
    for my $payload (@$node[1 .. $#$node]) {
        my $unwrapped = $class->_unwrap_scalar_token($payload);
        return 1
            if defined($unwrapped)
                && !ref($unwrapped)
                && $unwrapped =~ /\A[A-Za-z_]\w*=.+\z/;
    }
    return 0;
}

sub _find_strict_infix_assignment_issue ($class, $node) {
    return undef unless ref($node) eq 'ARRAY';

    if (my $issue = $class->_strict_infix_assignment_issue_for_action($node)) {
        return $issue;
    }

    for my $child (@$node) {
        next unless ref($child) eq 'ARRAY';
        if (my $issue = $class->_find_strict_infix_assignment_issue($child)) {
            return $issue;
        }
    }

    return undef;
}

sub _strict_infix_assignment_issue_for_action ($class, $node) {
    return undef unless ref($node) eq 'ARRAY' && @$node >= 2;

    my ($target, $spec) = @$node[0, 1];
    return undef if defined($target) && !ref($target) && $class->_is_assignment_operator_token($target);
    return undef unless $class->_is_strict_infix_assignment_target($target);
    return undef unless ref($spec) eq 'ARRAY' && @$spec >= 2;

    my $operator = $class->_unwrap_scalar_token($spec->[0]);
    return undef unless $class->_is_assignment_operator_token($operator);

    my $rhs = $class->_unwrap_scalar_token($spec->[1]);
    return {
        operator => $operator,
        target => $target,
        rhs => $rhs,
        display => $class->_render_infix_assignment_action($target, $spec),
        canonical_hint => $class->_render_canonical_assignment_pair_hint($operator, $target, $rhs),
    };
}

sub _is_strict_infix_assignment_target ($class, $target) {
    return 1 if defined($target) && !ref($target);

    my $unwrapped = $class->_unwrap_scalar_token($target);
    return 0 unless ref($unwrapped) eq 'ARRAY' && @$unwrapped;
    return 0 if ref($unwrapped->[0]);

    return $unwrapped->[0] eq 'concat' || $unwrapped->[0] eq 'cat';
}

sub _is_assignment_operator_token ($class, $token) {
    return defined($token)
        && !ref($token)
        && $token =~ /\A(?:=|<-|<-=|<=|<=\+|<[0-9]+)\z/;
}

sub _render_infix_assignment_action ($class, $target, $spec) {
    my @parts = (
        $class->_render_lispish_node($target),
        map { $class->_render_lispish_node($_) } @$spec,
    );
    return '(' . join(' ', @parts) . ')';
}

sub _render_canonical_assignment_pair_hint ($class, $operator, $target, $rhs) {
    return '('
        . $operator
        . ' ('
        . $class->_render_lispish_node($target)
        . ' '
        . $class->_render_lispish_node($rhs)
        . '))';
}

sub _render_lispish_node ($class, $node) {
    return 'undef' unless defined $node;
    return $node unless ref($node) eq 'ARRAY';
    return '()' unless @$node;

    if (@$node == 1) {
        return $class->_render_lispish_node($node->[0]);
    }

    if (@$node == 2 && defined($node->[0]) && !ref($node->[0]) && ref($node->[1]) eq 'ARRAY') {
        return '(' . join(' ', $node->[0], map { $class->_render_lispish_node($_) } @{$node->[1]}) . ')';
    }

    return '(' . join(' ', map { $class->_render_lispish_node($_) } @$node) . ')';
}

sub _direct_root_package_imports ($class, %args) {
    my $body_items = $class->_direct_root_body_items(%args);
    return [] unless $body_items;

    my $source_info = $args{source_info}
        || $class->classify_source_ast($args{raw_ast});
    my $source_label = $args{source_label} // ($source_info->{header} // 'source');

    my @package_imports;
    for my $item (@$body_items) {
        next unless ref($item) eq 'ARRAY';
        next unless defined($item->[0]) && !ref($item->[0]) && $item->[0] eq '+import';
        push @package_imports, @{ $class->_parse_direct_import_block($source_label, $item) };
    }

    return \@package_imports;
}

sub _parse_direct_import_block ($class, $source_label, $imports_ast) {
    my (undef, $imports_list) = @$imports_ast;

    confess
        "Malformed '+import' section in source '$source_label'. "
      . "The active contract supports '+import' only as a non-empty list of HDL-identifier-compatible package names. "
      . "See docs/USER_GUIDE.md for the current supported boundary.\n"
        unless ref($imports_list) eq 'ARRAY' && @$imports_list;

    my @package_names;
    for my $package_name (@$imports_list) {
        my $resolved_name = $class->_unwrap_scalar_token($package_name);
        confess
            "Malformed '+import' package name '$resolved_name' in source '$source_label'. "
          . "The active contract expects each imported package name to be an HDL-identifier-compatible bare name. "
          . "See docs/USER_GUIDE.md for the current supported boundary.\n"
            unless defined($resolved_name) && !ref($resolved_name) && $resolved_name =~ /\A[A-Za-z_]\w*\z/;
        push @package_names, $resolved_name;
    }

    return \@package_names;
}

sub collect_embedded_package_sources ($class, $raw_ast) {
    my %embedded_package_sources;
    return \%embedded_package_sources unless ref($raw_ast) eq 'ARRAY';

    for my $ast_node (@$raw_ast) {
        next unless ref($ast_node) eq 'ARRAY';
        next unless @$ast_node > 0;
        next if ref($ast_node->[0]);
        next unless $ast_node->[0] =~ /^\?pkg:/;
        my $package_name = $class->_decode_embedded_package_source_name($ast_node->[0]);
        next unless $package_name;
        $embedded_package_sources{$package_name} = _clone($ast_node);
    }

    return \%embedded_package_sources;
}

sub _decode_embedded_package_source_name ($class, $header) {
    return $1 if defined($header) && !ref($header) && $header =~ /\A\?pkg:([A-Za-z_]\w*)\z/;
    return undef;
}

sub _unwrap_scalar_token ($class, $value) {
    my $unwrapped = $value;
    while (ref($unwrapped) eq 'ARRAY' && @$unwrapped == 1) {
        $unwrapped = $unwrapped->[0];
    }
    return $unwrapped;
}

sub _clone ($value) {
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => _clone($value->{$_}) } keys %$value
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { _clone($_) } @$value ];
    }

    return $value;
}

sub _import_package_symbols_into_signal_manager ($class, %args) {
    my $signal_manager = $args{signal_manager}
        or confess "SourceFrontend requires a signal_manager to import package symbols";
    my $resolved_package_imports = $args{resolved_package_imports} || {};
    my $package_imports = $args{package_imports} || [sort keys %$resolved_package_imports];

    for my $package_name (@$package_imports) {
        my $package_spec = $resolved_package_imports->{$package_name} or next;
        my $symbols = $package_spec->symbols or next;
        FSM::Package::SignalManagerProjectionSupport->project_symbols_into_signal_manager(
            signal_manager => $signal_manager,
            symbols => $symbols,
            namespace_prefix => $package_name,
            debug_level => $args{debug_level} // 0,
        );
    }
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
