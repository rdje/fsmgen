package FSM::HDL::FlattenedDT::Backend::VHDL;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[VHDL.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

sub generate_vhdl ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    fsm_debug("[VHDL.pm][generate_vhdl()] Starting flattened DT direct VHDL generation for " . $fsm_module->name, 3);
    my $sv_hdl = $ctx->{orchestrator}->generate_systemverilog($fsm_module);
    return $self->convert_systemverilog_to_vhdl($sv_hdl);
}

sub convert_systemverilog_to_vhdl ($self, $sv_hdl) {
    confess _unsupported('aggregate struct outputs are outside the direct VHDL scaffold')
        if $sv_hdl =~ /\btypedef\s+struct\b/s;
    confess _unsupported('SystemVerilog logic declarations are outside the direct VHDL scaffold')
        if $sv_hdl =~ /^\s*logic\b/m;

    my $module = _parse_module($sv_hdl);
    my @generics = _parse_generics($module->{parameters});
    my @ports = _parse_ports($module->{ports});
    my $body = $module->{body};
    my @constants = _parse_constants($body);
    my @signals = _parse_signal_declarations($body, { map { $_->{name} => 1 } @ports });
    my %decls_by_name = map { $_->{name} => $_ } (@ports, @signals);
    my @assigns = _parse_continuous_assignments($body);
    my @processes = _parse_processes($body, \%decls_by_name);

    return _render_vhdl(
        module_name => $module->{name},
        generics => \@generics,
        ports => \@ports,
        constants => \@constants,
        signals => \@signals,
        assigns => \@assigns,
        processes => \@processes,
        decls_by_name => \%decls_by_name,
    );
}

sub _parse_module ($sv_hdl) {
    $sv_hdl =~ /\bmodule\s+([A-Za-z_][A-Za-z0-9_]*)\b/g
        or confess _unsupported('could not locate the generated module boundary');

    my $name = $1;
    my $pos = _skip_ws($sv_hdl, pos($sv_hdl));
    my $parameters = '';

    if (substr($sv_hdl, $pos, 1) eq '#') {
        $pos = _skip_ws($sv_hdl, $pos + 1);
        my $parameter_block = _consume_parenthesized($sv_hdl, $pos, 'parameter block');
        $parameters = $parameter_block->{content};
        $pos = _skip_ws($sv_hdl, $parameter_block->{next});
    }

    my $port_block = _consume_parenthesized($sv_hdl, $pos, 'port list');
    $pos = _skip_ws($sv_hdl, $port_block->{next});
    substr($sv_hdl, $pos, 1) eq ';'
        or confess _unsupported('could not locate the generated module boundary');
    $pos++;

    pos($sv_hdl) = $pos;
    $sv_hdl =~ /\G\s*(.*?)\nendmodule\b/gs
        or confess _unsupported('could not locate the generated module boundary');

    return {
        name => $name,
        parameters => $parameters,
        ports => $port_block->{content},
        body => $1,
    };
}

sub _parse_generics ($parameter_text) {
    my @generics;

    for my $raw_line (split /\n/, $parameter_text) {
        my $line = _strip_line_comment($raw_line);
        $line =~ s/^\s+|\s+$//g;
        $line =~ s/,\s*$//;
        next unless length $line;

        if ($line =~ /^parameter\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$/) {
            my $default = _sv_parameter_default_to_vhdl($2);
            push @generics, {
                name => $1,
                type => $default->{type},
                default => $default->{default},
            };
            next;
        }

        confess _unsupported("unsupported generated parameter declaration '$line'");
    }

    return @generics;
}

sub _parse_ports ($port_text) {
    my @ports;

    for my $raw_line (split /\n/, $port_text) {
        my $line = _strip_line_comment($raw_line);
        $line =~ s/^\s+|\s+$//g;
        $line =~ s/,\s*$//;
        next unless length $line;

        if ($line =~ /^input\s+wire\s+(?:\[(\d+):(\d+)\]\s+)?([A-Za-z_][A-Za-z0-9_]*)$/) {
            push @ports, _decl_hash(name => $3, direction => 'in', msb => $1, lsb => $2);
            next;
        }

        if ($line =~ /^output(?:\s+(?:reg|wire))?\s+(?:\[(\d+):(\d+)\]\s+)?([A-Za-z_][A-Za-z0-9_]*)$/) {
            push @ports, _decl_hash(name => $3, direction => 'out', msb => $1, lsb => $2);
            next;
        }

        confess _unsupported("unsupported generated port declaration '$line'");
    }

    return @ports;
}

sub _parse_constants ($body) {
    my @constants;

    while ($body =~ /^\s*localparam\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([^;]+);\s*$/mg) {
        my ($name, $expr) = ($1, $2);
        my $literal = _parse_sized_literal($expr)
            or confess _unsupported("unsupported localparam expression '$expr'");
        push @constants, {
            name => $name,
            type => _vhdl_type($literal->{width} - 1, 0),
            value => _literal_bits_value($literal, force_vector => 1),
        };
    }

    return @constants;
}

sub _parse_signal_declarations ($body, $port_names) {
    my @signals;

    for my $raw_line (split /\n/, $body) {
        my $line = _strip_line_comment($raw_line);
        $line =~ s/^\s+|\s+$//g;
        next unless length $line;

        next unless $line =~ /^(reg|wire)\s+(?:\[(\d+):(\d+)\]\s+)?(.+);$/;
        my ($kind, $msb, $lsb, $names_text) = ($1, $2, $3, $4);
        my @names = map {
            my $name = $_;
            $name =~ s/^\s+|\s+$//g;
            $name;
        } split /,/, $names_text;

        for my $name (@names) {
            confess _unsupported("unsupported generated declaration name '$name'")
                unless $name =~ /^[A-Za-z_][A-Za-z0-9_]*$/;
            next if $port_names->{$name};
            push @signals, _decl_hash(name => $name, kind => $kind, msb => $msb, lsb => $lsb);
        }
    }

    return @signals;
}

sub _parse_continuous_assignments ($body) {
    my @assigns;

    for my $raw_line (split /\n/, $body) {
        my $line = _strip_line_comment($raw_line);
        $line =~ s/^\s+|\s+$//g;
        next unless length $line;

        next unless $line =~ /^assign\s+([A-Za-z_][A-Za-z0-9_]*(?:\[[^\]]+\])?)\s*=\s*(.+);$/;
        my ($lhs, $expr) = ($1, $2);
        push @assigns, {
            raw_lhs => $lhs,
            lhs => _sv_lvalue_to_vhdl($lhs),
            expr => $expr,
        };
    }

    return @assigns;
}

sub _parse_processes ($body, $decls_by_name) {
    my @lines = split /\n/, $body;
    my @processes;

    for (my $idx = 0; $idx <= $#lines; $idx++) {
        next unless $lines[$idx] =~ /^\s*always_(?:comb|ff)\b/;

        my @block;
        my $depth = 0;
        while ($idx <= $#lines) {
            my $line = $lines[$idx];
            push @block, $line;
            my $without_comment = _strip_line_comment($line);
            my $begins = () = $without_comment =~ /\bbegin\b/g;
            my $ends = () = $without_comment =~ /\bend\b/g;
            $depth += $begins - $ends;
            last if @block > 1 && $depth <= 0;
            $idx++;
        }

        confess _unsupported('unterminated generated always block')
            if $depth != 0;

        my $header = $block[0];
        if ($header =~ /^\s*always_comb\s+begin\b/) {
            push @processes, {
                kind => 'comb',
                lines => [ _convert_comb_process($decls_by_name, @block) ],
            };
            next;
        }

        if ($header =~ /^\s*always_ff\s*@\(([^)]+)\)\s+begin\b/) {
            push @processes, {
                kind => 'ff',
                lines => [ _convert_ff_process($decls_by_name, $1, @block) ],
            };
            next;
        }

        confess _unsupported("unsupported generated always block header '$header'");
    }

    return @processes;
}

sub _convert_comb_process ($decls_by_name, @block) {
    my @out = ('  process(all) begin');
    my $indent_level = 0;

    for my $raw_line (@block[1 .. $#block - 1]) {
        my $line = _strip_line_comment($raw_line);
        $line =~ s/^\s+|\s+$//g;
        next unless length $line;

        if ($line =~ /^if\s*\((.+)\)\s+begin$/) {
            push @out, _indent(2 + $indent_level) . 'if ' . _sv_condition_to_vhdl($1) . ' then';
            $indent_level++;
            next;
        }

        if ($line =~ /^end$/) {
            $indent_level--;
            confess _unsupported('generated always_comb block closed more if statements than it opened')
                if $indent_level < 0;
            push @out, _indent(2 + $indent_level) . 'end if;';
            next;
        }

        if ($line =~ /^([A-Za-z_][A-Za-z0-9_]*(?:\[[^\]]+\])?)\s*=\s*(.+);$/) {
            push @out, _indent(2 + $indent_level) . _sv_lvalue_to_vhdl($1) . ' <= '
                . _sv_expr_to_vhdl($2, { decls_by_name => $decls_by_name, target_lhs => $1 }) . ';';
            next;
        }

        confess _unsupported("unsupported generated always_comb statement '$line'");
    }

    confess _unsupported('generated always_comb block left an if statement open')
        if $indent_level != 0;

    push @out, '  end process;';
    return @out;
}

sub _convert_ff_process ($decls_by_name, $sensitivity, @block) {
    my @inner = @block[1 .. $#block - 1];
    my $branches = _split_if_else_assignments($decls_by_name, @inner);
    my $reset_condition = $branches->{condition};
    my @reset_assigns = @{$branches->{reset_assigns}};
    my @clock_assigns = @{$branches->{clock_assigns}};

    if ($sensitivity =~ /^\s*posedge\s+([A-Za-z_][A-Za-z0-9_]*)\s*$/) {
        my $clock = $1;
        my @reset_lines = map { '        ' . $_ } @reset_assigns;
        my @clock_lines = map { '        ' . $_ } @clock_assigns;
        return (
            "  process($clock) begin",
            "    if rising_edge($clock) then",
            '      if ' . _sv_condition_to_vhdl($reset_condition) . ' then',
            @reset_lines,
            '      else',
            @clock_lines,
            '      end if;',
            '    end if;',
            '  end process;',
        );
    }

    if ($sensitivity =~ /^\s*posedge\s+([A-Za-z_][A-Za-z0-9_]*)\s+or\s+(posedge|negedge)\s+([A-Za-z_][A-Za-z0-9_]*)\s*$/) {
        my ($clock, $edge, $reset) = ($1, $2, $3);
        my $expected_reset = $edge eq 'negedge' ? "$reset = '0'" : "$reset = '1'";
        my $reset_vhdl = _sv_condition_to_vhdl($reset_condition);
        confess _unsupported("asynchronous reset condition '$reset_condition' does not match sensitivity '$sensitivity'")
            unless $reset_vhdl eq $expected_reset;

        my @reset_lines = map { '      ' . $_ } @reset_assigns;
        my @clock_lines = map { '      ' . $_ } @clock_assigns;
        return (
            "  process($clock, $reset) begin",
            "    if $reset_vhdl then",
            @reset_lines,
            "    elsif rising_edge($clock) then",
            @clock_lines,
            '    end if;',
            '  end process;',
        );
    }

    confess _unsupported("unsupported generated always_ff sensitivity '$sensitivity'");
}

sub _split_if_else_assignments ($decls_by_name, @inner) {
    confess _unsupported('empty generated always_ff body')
        unless @inner;

    my $first = _trim(_strip_line_comment(shift @inner));
    $first =~ /^if\s*\((.+)\)\s+begin$/
        or confess _unsupported("unsupported generated always_ff condition '$first'");
    my $condition = $1;

    my (@reset_raw_lines, @clock_raw_lines);
    my $target = \@reset_raw_lines;
    my $saw_else = 0;
    my $nested_depth = 0;

    for my $raw_line (@inner) {
        my $line = _trim(_strip_line_comment($raw_line));
        next unless length $line;

        if (!$saw_else && $nested_depth == 0 && $line =~ /^end\s+else\s+begin$/) {
            $target = \@clock_raw_lines;
            $saw_else = 1;
            next;
        }

        last if $saw_else && $nested_depth == 0 && $line eq 'end';

        push @{$target}, $raw_line;
        if ($line =~ /^if\s*\(.+\)\s+begin$/) {
            $nested_depth++;
        } elsif ($line eq 'end') {
            $nested_depth--;
            confess _unsupported('generated always_ff nested sequential block closed more if statements than it opened')
                if $nested_depth < 0;
        }
    }

    confess _unsupported('generated always_ff body missing else branch')
        unless $saw_else;
    confess _unsupported('generated always_ff nested sequential block left an if statement open')
        if $nested_depth != 0;

    return {
        condition => $condition,
        reset_assigns => [ _convert_sequential_branch_statements($decls_by_name, @reset_raw_lines) ],
        clock_assigns => [ _convert_sequential_branch_statements($decls_by_name, @clock_raw_lines) ],
    };
}

sub _convert_sequential_branch_statements ($decls_by_name, @raw_lines) {
    my @out;

    for (my $idx = 0; $idx <= $#raw_lines; $idx++) {
        my $line = _trim(_strip_line_comment($raw_lines[$idx]));
        next unless length $line;

        if ($line =~ /^if\s*\((.+)\)\s+begin$/) {
            my $condition = $1;
            my @nested_raw_lines;
            my $nested_depth = 1;
            $idx++;

            while ($idx <= $#raw_lines) {
                my $nested_line = _trim(_strip_line_comment($raw_lines[$idx]));
                if ($nested_line =~ /^end\s+else\s+begin$/) {
                    confess _unsupported("unsupported generated nested always_ff else branch '$nested_line'");
                }

                if ($nested_line =~ /^if\s*\(.+\)\s+begin$/) {
                    $nested_depth++;
                    push @nested_raw_lines, $raw_lines[$idx];
                    $idx++;
                    next;
                }

                if ($nested_line eq 'end') {
                    $nested_depth--;
                    last if $nested_depth == 0;
                    push @nested_raw_lines, $raw_lines[$idx];
                    $idx++;
                    next;
                }

                push @nested_raw_lines, $raw_lines[$idx];
                $idx++;
            }

            confess _unsupported('generated nested always_ff branch left an if statement open')
                if $nested_depth != 0;

            my @nested_lines = _convert_sequential_branch_statements($decls_by_name, @nested_raw_lines);
            push @out, 'if ' . _sv_condition_to_vhdl($condition) . ' then';
            push @out, map { '  ' . $_ } @nested_lines;
            push @out, 'end if;';
            next;
        }

        push @out, _convert_sequential_assignment($decls_by_name, $line);
    }

    return @out;
}

sub _convert_sequential_assignment ($decls_by_name, $line) {
    $line =~ /^([A-Za-z_][A-Za-z0-9_]*(?:\[[^\]]+\])?)\s*<=\s*(.+);$/
        or confess _unsupported("unsupported generated always_ff assignment '$line'");
    return _sv_lvalue_to_vhdl($1) . ' <= '
        . _sv_expr_to_vhdl($2, { decls_by_name => $decls_by_name, target_lhs => $1 }) . ';';
}

sub _render_vhdl (%args) {
    my $module_name = $args{module_name};
    my @lines = (
        "-- Flattened Decision Tree FSM: $module_name",
        "-- Generated by FSMGen direct VHDL scaffold",
        'library ieee;',
        'use ieee.std_logic_1164.all;',
        'use ieee.numeric_std.all;',
        '',
        "entity $module_name is",
    );

    if (@{$args{generics}}) {
        push @lines, '  generic (';
        for my $idx (0 .. $#{$args{generics}}) {
            my $generic = $args{generics}->[$idx];
            my $suffix = $idx == $#{$args{generics}} ? '' : ';';
            push @lines, sprintf(
                '    %s : %s := %s%s',
                $generic->{name},
                $generic->{type},
                $generic->{default},
                $suffix,
            );
        }
        push @lines, '  );';
    }

    if (@{$args{ports}}) {
        push @lines, '  port (';
        for my $idx (0 .. $#{$args{ports}}) {
            my $port = $args{ports}->[$idx];
            my $suffix = $idx == $#{$args{ports}} ? '' : ';';
            push @lines, sprintf(
                '    %s : %s %s%s',
                $port->{name},
                $port->{direction},
                _vhdl_type_for_decl($port),
                $suffix,
            );
        }
        push @lines, '  );';
    }

    push @lines,
        "end entity $module_name;",
        '',
        "architecture rtl of $module_name is";

    for my $constant (@{$args{constants}}) {
        push @lines, "  constant $constant->{name} : $constant->{type} := $constant->{value};";
    }
    push @lines, '' if @{$args{constants}} && @{$args{signals}};

    for my $signal (@{$args{signals}}) {
        push @lines, "  signal $signal->{name} : " . _vhdl_type_for_decl($signal) . ';';
    }

    push @lines, 'begin', '';

    for my $assign (@{$args{assigns}}) {
        my $expr = $assign->{expr};
        if ($expr =~ /==/) {
            push @lines, '  ' . $assign->{lhs} . " <= '1' when " . _sv_condition_to_vhdl($expr) . " else '0';";
        } else {
            push @lines, '  ' . $assign->{lhs} . ' <= '
                . _sv_expr_to_vhdl($expr, { decls_by_name => $args{decls_by_name}, target_lhs => $assign->{raw_lhs} }) . ';';
        }
    }

    push @lines, '' if @{$args{assigns}} && @{$args{processes}};
    for my $process (@{$args{processes}}) {
        push @lines, @{$process->{lines}}, '';
    }

    push @lines, 'end architecture rtl;';
    return join("\n", @lines) . "\n";
}

sub _decl_hash (%args) {
    my ($msb, $lsb) = ($args{msb}, $args{lsb});
    return {
        %args,
        scalar => (defined($msb) && defined($lsb)) ? 0 : 1,
        msb => $msb,
        lsb => $lsb,
    };
}

sub _vhdl_type_for_decl ($decl) {
    return 'std_logic' if $decl->{scalar};
    return _vhdl_type($decl->{msb}, $decl->{lsb});
}

sub _vhdl_type ($msb, $lsb) {
    confess _unsupported("unsupported vector range [$msb:$lsb]")
        unless defined($msb) && defined($lsb) && $msb =~ /^\d+$/ && $lsb =~ /^\d+$/;
    return "std_logic_vector($msb downto $lsb)";
}

sub _sv_lvalue_to_vhdl ($lhs) {
    my $converted = $lhs;
    $converted =~ s/\[([0-9]+):([0-9]+)\]/($1 downto $2)/g;
    $converted =~ s/\[([0-9]+)\]/($1)/g;
    return $converted;
}

sub _sv_condition_to_vhdl ($expr) {
    my $trimmed = _trim($expr);

    if ($trimmed =~ /^!([A-Za-z_][A-Za-z0-9_]*)$/) {
        return "$1 = '0'";
    }

    if ($trimmed =~ /^[A-Za-z_][A-Za-z0-9_]*$/) {
        return "$trimmed = '1'";
    }

    my $converted = _sv_expr_to_vhdl($trimmed);
    return $converted if $converted =~ /=/;
    return "($converted) = '1'";
}

sub _sv_expr_to_vhdl ($expr, $ctx = {}) {
    my $trimmed = _trim($expr);
    return _simple_arithmetic_to_vhdl($trimmed, $ctx)
        if _has_arithmetic_operator($trimmed);

    my $converted = $trimmed;
    $converted = _convert_concat_braces($converted);
    $converted =~ s/\b([A-Za-z_][A-Za-z0-9_]*)\[([0-9]+):([0-9]+)\]/$1($2 downto $3)/g;
    $converted =~ s/\b([A-Za-z_][A-Za-z0-9_]*)\[([0-9]+)\]/$1($2)/g;
    $converted =~ s/\b([0-9]+)'([bdhBDH])([0-9A-Fa-f_xXzZ]+)\b/_literal_match_to_vhdl($1, lc($2), $3)/ge;
    $converted =~ s/==/=/g;
    $converted =~ s/&&/ and /g;
    $converted =~ s/\|\|/ or /g;
    $converted =~ s/\s+\|\s+/ or /g;
    $converted =~ s/(?<![<>=!])!(?=\s*[A-Za-z_]) /not /gx;
    $converted =~ s/\s*&\s*/ and /g;
    $converted =~ s/__FSMGEN_CONCAT__/&/g;
    $converted =~ s/\s+/ /g;
    confess _unsupported("arithmetic expression '$expr' is outside the direct VHDL scaffold")
        if $converted =~ /[+\-*\/%]/ || $converted =~ /\bmod\b/i;
    return _trim($converted);
}

sub _has_arithmetic_operator ($expr) {
    return 1 if $expr =~ /[+\-*\/%]/;
    return 1 if $expr =~ /\^/;
    return 1 if $expr =~ /\bmod\b/i;
    return 0;
}

sub _simple_arithmetic_to_vhdl ($expr, $ctx) {
    my $unsupported = sub {
        confess _unsupported("arithmetic expression '$expr' is outside the direct VHDL scaffold");
    };

    my $operator;
    my @operators = map { lc($_) eq 'mod' ? '%' : $_ } $expr =~ /(\bmod\b|[+*^\/%]|-)/ig;
    my %operator_seen = map { $_ => 1 } @operators;
    if (!@operators || keys(%operator_seen) != 1) {
        $unsupported->();
    }
    else {
        ($operator) = keys %operator_seen;
    }

    my $separator;
    if ($operator eq '+') {
        $separator = qr/\s*\+\s*/;
    }
    elsif ($operator eq '-') {
        $separator = qr/\s*-\s*/;
    }
    elsif ($operator eq '*') {
        $separator = qr/\s*\*\s*/;
    }
    elsif ($operator eq '^') {
        $separator = qr/\s*\^\s*/;
    }
    elsif ($operator eq '/') {
        $separator = qr/\s*\/\s*/;
    }
    elsif ($operator eq '%') {
        $separator = qr/\s*(?:%|\bmod\b)\s*/i;
    }

    my @operand_names = split $separator, $expr;
    $unsupported->()
        unless @operand_names >= 2;
    for my $operand_name (@operand_names) {
        $unsupported->()
            unless $operand_name =~ /^[A-Za-z_][A-Za-z0-9_]*$/;
    }

    my $decls_by_name = $ctx->{decls_by_name} || {};
    my $target_decl = _decl_for_lvalue($ctx->{target_lhs}, $decls_by_name)
        or $unsupported->();

    my $target_width = _decl_width($target_decl);
    if (($operator eq '+' || $operator eq '-' || $operator eq '*') && $target_decl->{scalar}) {
        $unsupported->()
            unless $operator eq '*' || $operator eq '+' || $operator eq '-';
        my @scalar_operands;
        for my $operand_name (@operand_names) {
            my $operand_decl = $decls_by_name->{$operand_name}
                or $unsupported->();
            $unsupported->()
                unless $operand_decl->{scalar};
            push @scalar_operands, $operand_name;
        }
        return join($operator eq '*' ? ' and ' : ' xor ', @scalar_operands);
    }

    my @converted_operands;
    for my $operand_name (@operand_names) {
        my $operand_decl = $decls_by_name->{$operand_name}
            or $unsupported->();
        my $operand_width = _decl_width($operand_decl);
        if ($operator eq '^') {
            $unsupported->()
                if $target_width != $operand_width;
            push @converted_operands, $operand_name;
            next;
        }

        $unsupported->()
            if $target_decl->{scalar} || $operand_decl->{scalar} || $target_width != $operand_width;
        push @converted_operands, "unsigned($operand_name)";
    }

    return join(' xor ', @converted_operands)
        if $operator eq '^';

    my $vhdl_operator = $operator eq '%' ? 'mod' : $operator;
    my $converted_expression = join(" $vhdl_operator ", @converted_operands);
    return "std_logic_vector(resize($converted_expression, $target_width))"
        if $operator eq '*' || $operator eq '/' || $operator eq '%';

    return "std_logic_vector($converted_expression)";
}

sub _decl_for_lvalue ($lhs, $decls_by_name) {
    return undef unless defined $lhs;
    my $name = $lhs;
    $name =~ s/\[.*\]\z//;
    return $decls_by_name->{$name};
}

sub _decl_width ($decl) {
    return 1 if $decl->{scalar};
    return abs($decl->{msb} - $decl->{lsb}) + 1;
}

sub _convert_concat_braces ($expr) {
    my $converted = $expr;
    while ($converted =~ /\{([^{}]+)\}/) {
        my $inner = $1;
        my @parts = map { _trim($_) } split /,/, $inner;
        confess _unsupported("unsupported empty concatenation '{$inner}'")
            unless @parts;
        my $replacement = '(' . join(' __FSMGEN_CONCAT__ ', @parts) . ')';
        $converted =~ s/\{\Q$inner\E\}/$replacement/;
    }
    confess _unsupported("unsupported nested concatenation expression '$expr'")
        if $converted =~ /[{}]/;
    return $converted;
}

sub _parse_sized_literal ($expr) {
    my $trimmed = _trim($expr);
    return undef unless $trimmed =~ /^([0-9]+)'([bdhBDH])([0-9A-Fa-f_xXzZ]+)$/;
    return {
        width => $1 + 0,
        base => lc($2),
        digits => $3,
    };
}

sub _literal_match_to_vhdl ($width, $base, $digits) {
    return _literal_bits_value({
        width => $width + 0,
        base => $base,
        digits => $digits,
    });
}

sub _literal_bits_value ($literal, %opts) {
    my $width = $literal->{width};
    my $bits = _literal_bits($literal);
    confess _unsupported("literal width $width cannot represent '$literal->{digits}'")
        if length($bits) > $width;
    $bits = ('0' x ($width - length($bits))) . $bits;

    return "'$bits'" if $width == 1 && !$opts{force_vector};
    return qq{"$bits"};
}

sub _literal_bits ($literal) {
    my ($base, $digits) = ($literal->{base}, $literal->{digits});
    confess _unsupported("literal '$digits' uses x/z bits outside the direct VHDL scaffold")
        if $digits =~ /[xz]/i;
    $digits =~ s/_//g;

    return $digits if $base eq 'b';

    if ($base eq 'd') {
        confess _unsupported("negative decimal literals are outside the direct VHDL scaffold")
            unless $digits =~ /^\d+$/;
        return sprintf('%b', $digits);
    }

    if ($base eq 'h') {
        my %hex = (
            0 => '0000', 1 => '0001', 2 => '0010', 3 => '0011',
            4 => '0100', 5 => '0101', 6 => '0110', 7 => '0111',
            8 => '1000', 9 => '1001', a => '1010', b => '1011',
            c => '1100', d => '1101', e => '1110', f => '1111',
        );
        my $bits = join '', map { $hex{lc($_)} } split //, $digits;
        $bits =~ s/^0+(?=.)//;
        return $bits;
    }

    confess _unsupported("unsupported literal base '$base'");
}

sub _sv_parameter_default_to_vhdl ($expr) {
    my $converted = _trim($expr);
    my $literal = _parse_sized_literal($converted);
    if ($literal) {
        return {
            type => $literal->{width} == 1 ? 'std_logic' : _vhdl_type($literal->{width} - 1, 0),
            default => _literal_bits_value($literal),
        };
    }

    return {
        type => 'integer',
        default => _sv_integer_expr_to_vhdl($expr),
    };
}

sub _sv_integer_expr_to_vhdl ($expr) {
    my $converted = _trim($expr);
    $converted =~ s/\b([0-9]+)'([bdhBDH])([0-9A-Fa-f_xXzZ]+)\b/_literal_integer_match_to_vhdl($1, lc($2), $3)/ge;
    confess _unsupported("unsupported parameter expression '$expr'")
        unless length $converted;
    confess _unsupported("unsupported parameter expression '$expr'")
        unless $converted =~ /\A[A-Za-z0-9_()\s+\-*\/%]+\z/;

    $converted =~ s/%/ mod /g;
    $converted =~ s/\+\s*-(?=\s*(?:[0-9]|[A-Za-z_]))/- /g;
    $converted =~ s/\s+/ /g;
    return _trim($converted);
}

sub _literal_integer_match_to_vhdl ($width, $base, $digits) {
    return _literal_integer_value({
        width => $width + 0,
        base => $base,
        digits => $digits,
    });
}

sub _literal_integer_value ($literal) {
    my $bits = _literal_bits($literal);
    my $value = 0;
    for my $bit (split //, $bits) {
        $value = ($value * 2) + ($bit eq '1' ? 1 : 0);
    }
    return $value;
}

sub _skip_ws ($text, $pos) {
    $pos++ while $pos < length($text) && substr($text, $pos, 1) =~ /\s/;
    return $pos;
}

sub _consume_parenthesized ($text, $pos, $label) {
    substr($text, $pos, 1) eq '('
        or confess _unsupported("could not locate the generated module $label");

    my $depth = 0;
    my $start = $pos + 1;
    for (my $idx = $pos; $idx < length($text); $idx++) {
        my $char = substr($text, $idx, 1);
        if ($char eq '(') {
            $depth++;
            next;
        }
        if ($char eq ')') {
            $depth--;
            if ($depth == 0) {
                return {
                    content => substr($text, $start, $idx - $start),
                    next => $idx + 1,
                };
            }
            confess _unsupported("generated module $label closed more parentheses than it opened")
                if $depth < 0;
        }
    }

    confess _unsupported("unterminated generated module $label");
}

sub _strip_line_comment ($line) {
    $line =~ s{//.*$}{};
    return $line;
}

sub _trim ($text) {
    $text =~ s/^\s+|\s+$//g;
    return $text;
}

sub _indent ($level) {
    return '  ' x $level;
}

sub _unsupported ($message) {
    return "[VHDL.pm][direct scaffold] Unsupported generated SystemVerilog shape for direct VHDL backend: $message";
}

1;
