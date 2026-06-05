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
    my @ports = _parse_ports($module->{ports});
    my $body = $module->{body};
    my @constants = _parse_constants($body);
    my @signals = _parse_signal_declarations($body, { map { $_->{name} => 1 } @ports });
    my @assigns = _parse_continuous_assignments($body);
    my @processes = _parse_processes($body);

    return _render_vhdl(
        module_name => $module->{name},
        ports => \@ports,
        constants => \@constants,
        signals => \@signals,
        assigns => \@assigns,
        processes => \@processes,
    );
}

sub _parse_module ($sv_hdl) {
    $sv_hdl =~ /\bmodule\s+([A-Za-z_][A-Za-z0-9_]*)\s*\((.*?)\n\);\s*(.*?)\nendmodule\b/s
        or confess _unsupported('could not locate the generated module boundary');

    return {
        name => $1,
        ports => $2,
        body => $3,
    };
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
            lhs => _sv_lvalue_to_vhdl($lhs),
            expr => $expr,
        };
    }

    return @assigns;
}

sub _parse_processes ($body) {
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
                lines => [ _convert_comb_process(@block) ],
            };
            next;
        }

        if ($header =~ /^\s*always_ff\s*@\(([^)]+)\)\s+begin\b/) {
            push @processes, {
                kind => 'ff',
                lines => [ _convert_ff_process($1, @block) ],
            };
            next;
        }

        confess _unsupported("unsupported generated always block header '$header'");
    }

    return @processes;
}

sub _convert_comb_process (@block) {
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
            push @out, _indent(2 + $indent_level) . _sv_lvalue_to_vhdl($1) . ' <= ' . _sv_expr_to_vhdl($2) . ';';
            next;
        }

        confess _unsupported("unsupported generated always_comb statement '$line'");
    }

    confess _unsupported('generated always_comb block left an if statement open')
        if $indent_level != 0;

    push @out, '  end process;';
    return @out;
}

sub _convert_ff_process ($sensitivity, @block) {
    my @inner = @block[1 .. $#block - 1];
    my $branches = _split_if_else_assignments(@inner);
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

sub _split_if_else_assignments (@inner) {
    confess _unsupported('empty generated always_ff body')
        unless @inner;

    my $first = _trim(_strip_line_comment(shift @inner));
    $first =~ /^if\s*\((.+)\)\s+begin$/
        or confess _unsupported("unsupported generated always_ff condition '$first'");
    my $condition = $1;

    my (@reset_lines, @clock_lines);
    my $target = \@reset_lines;
    my $saw_else = 0;

    for my $raw_line (@inner) {
        my $line = _trim(_strip_line_comment($raw_line));
        next unless length $line;

        if ($line =~ /^end\s+else\s+begin$/) {
            $target = \@clock_lines;
            $saw_else = 1;
            next;
        }

        last if $line eq 'end';

        push @{$target}, _convert_sequential_assignment($line);
    }

    confess _unsupported('generated always_ff body missing else branch')
        unless $saw_else;

    return {
        condition => $condition,
        reset_assigns => \@reset_lines,
        clock_assigns => \@clock_lines,
    };
}

sub _convert_sequential_assignment ($line) {
    $line =~ /^([A-Za-z_][A-Za-z0-9_]*(?:\[[^\]]+\])?)\s*<=\s*(.+);$/
        or confess _unsupported("unsupported generated always_ff assignment '$line'");
    return _sv_lvalue_to_vhdl($1) . ' <= ' . _sv_expr_to_vhdl($2) . ';';
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
            push @lines, '  ' . $assign->{lhs} . ' <= ' . _sv_expr_to_vhdl($expr) . ';';
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

sub _sv_expr_to_vhdl ($expr) {
    my $converted = _trim($expr);
    $converted = _convert_concat_braces($converted);
    $converted =~ s/\b([A-Za-z_][A-Za-z0-9_]*)\[([0-9]+):([0-9]+)\]/$1($2 downto $3)/g;
    $converted =~ s/\b([A-Za-z_][A-Za-z0-9_]*)\[([0-9]+)\]/$1($2)/g;
    $converted =~ s/\b([0-9]+)'([bdhBDH])([0-9A-Fa-f_xXzZ]+)\b/_literal_match_to_vhdl($1, lc($2), $3)/ge;
    $converted =~ s/==/=/g;
    $converted =~ s/&&/ and /g;
    $converted =~ s/\|\|/ or /g;
    $converted =~ s/(?<![<>=!])!(?=\s*[A-Za-z_]) /not /gx;
    $converted =~ s/\s*&\s*/ and /g;
    $converted =~ s/__FSMGEN_CONCAT__/&/g;
    $converted =~ s/\s+/ /g;
    return _trim($converted);
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
