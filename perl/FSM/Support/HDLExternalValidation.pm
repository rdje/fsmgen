package FSM::Support::HDLExternalValidation;

=head1 NAME

FSM::Support::HDLExternalValidation - Optional external SystemVerilog lint and synthesis validation

=head1 DESCRIPTION

Owns the bounded external-tool validation lane for generated SystemVerilog.
FSMGen still performs semantic and pre-generation checks internally; this
support package runs Verilator and Yosys after emission. Verilator checks that
the rendered text is valid lint-clean SystemVerilog. Yosys checks that the
same text can be turned into a structural netlist-like design, deliberately
without running the ABC mapping/optimization algorithm unless the caller
explicitly opts into the bounded ABC mapping probe.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use Exporter qw(import);
use IPC::Cmd qw(can_run run);

our @EXPORT_OK = qw(
    hdl_external_validation_abc_tool_candidates
    hdl_external_validation_required_tools
    hdl_external_validation_tools
    missing_systemverilog_validation_tools
    validate_systemverilog_file
);

sub hdl_external_validation_required_tools () {
    return qw(verilator yosys);
}

sub hdl_external_validation_abc_tool_candidates () {
    return qw(yosys-abc berkeley-abc abc);
}

sub hdl_external_validation_tools () {
    my ($abc_tool, $abc_path) = _first_available_tool(hdl_external_validation_abc_tool_candidates());
    return {
        verilator => can_run('verilator'),
        yosys => can_run('yosys'),
        abc_mapping => $abc_path,
        abc_mapping_tool => $abc_tool,
    };
}

sub missing_systemverilog_validation_tools () {
    my $tools = hdl_external_validation_tools();
    return sort grep { !$tools->{$_} } hdl_external_validation_required_tools();
}

sub validate_systemverilog_file (%args) {
    my $source_file = $args{source_file}
        or die "[HDLExternalValidation.pm][validate_systemverilog_file()] Missing required 'source_file'";
    my $top_module = $args{top_module}
        or die "[HDLExternalValidation.pm][validate_systemverilog_file()] Missing required 'top_module'";
    my $abc_mapping = $args{abc_mapping} ? 1 : 0;

    die "[HDLExternalValidation.pm][validate_systemverilog_file()] Source file does not exist: $source_file"
        unless -f $source_file;

    my $tools = hdl_external_validation_tools();
    my @missing = sort grep { !$tools->{$_} } qw(verilator yosys);
    push @missing, 'abc_mapping'
        if $abc_mapping && !$tools->{abc_mapping};
    die "[HDLExternalValidation.pm][validate_systemverilog_file()] Missing external HDL validation tool(s): "
        . join(', ', @missing)
        if @missing;

    my @steps;
    push @steps, _run_step(
        name => 'verilator_lint',
        command => [
            $tools->{verilator},
            '--lint-only',
            '--sv',
            $source_file,
        ],
    );

    my $yosys_stage = $abc_mapping
        ? 'synth -top ' . _yosys_identifier($top_module)
        : 'synth -noabc -top ' . _yosys_identifier($top_module);
    my $yosys_script = join '; ',
        'read_verilog -sv -noautowire ' . _yosys_quote($source_file),
        $yosys_stage,
        'stat';
    push @steps, _run_step(
        name => $abc_mapping ? 'yosys_abc_synthesis' : 'yosys_synthesis',
        command => [
            $tools->{yosys},
            '-p',
            $yosys_script,
        ],
    );

    return {
        ok => 1,
        source_file => $source_file,
        top_module => $top_module,
        steps => \@steps,
    };
}

sub _run_step (%args) {
    my $name = $args{name};
    my $command = $args{command};

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => $command,
        verbose => 0,
    );
    my $stdout = join('', @{$stdout_buf || []});
    my $stderr = join('', @{$stderr_buf || []});

    unless ($success) {
        die _format_step_failure(
            name => $name,
            command => $command,
            error_message => $error_message,
            stdout => $stdout,
            stderr => $stderr,
        );
    }

    return {
        name => $name,
        command => [@$command],
        stdout => $stdout,
        stderr => $stderr,
    };
}

sub _format_step_failure (%args) {
    my $text = "External HDL validation step '$args{name}' failed\n";
    $text .= "Command: " . join(' ', map { _shellish($_) } @{$args{command} || []}) . "\n";
    $text .= "Reason: $args{error_message}\n"
        if defined($args{error_message}) && length($args{error_message});
    $text .= "stdout:\n$args{stdout}\n"
        if defined($args{stdout}) && length($args{stdout});
    $text .= "stderr:\n$args{stderr}\n"
        if defined($args{stderr}) && length($args{stderr});
    return $text;
}

sub _yosys_quote ($text) {
    $text =~ s/\\/\\\\/g;
    $text =~ s/"/\\"/g;
    return qq("$text");
}

sub _yosys_identifier ($text) {
    die "[HDLExternalValidation.pm][_yosys_identifier()] Unsupported top-module identifier '$text'"
        unless defined($text) && $text =~ /^[A-Za-z_]\w*\z/;
    return $text;
}

sub _first_available_tool (@tool_names) {
    for my $tool_name (@tool_names) {
        my $path = can_run($tool_name);
        return ($tool_name, $path) if $path;
    }
    return (undef, undef);
}

sub _shellish ($text) {
    return "''" unless defined($text) && length($text);
    return $text if $text =~ /^[A-Za-z0-9_\/.:\-+=,\@]+\z/;
    $text =~ s/'/'"'"'/g;
    return "'$text'";
}

1;

__END__

=head1 FUNCTIONS

=head2 hdl_external_validation_tools

Returns the discovered required C<verilator> and C<yosys> executable paths, or
false values for tools that are not available on C<PATH>. It also reports the
first optional ABC mapping executable discovered from
C<hdl_external_validation_abc_tool_candidates> under C<abc_mapping>, plus the
matching command spelling under C<abc_mapping_tool>. The ABC mapping tool is
reported for planning/contract visibility only; it is not required and is not
run by default C<validate_systemverilog_file> calls.

=head2 hdl_external_validation_required_tools

Returns the tool keys that are required for the shipped external SystemVerilog
validation lane. This remains C<verilator> and C<yosys>.

=head2 hdl_external_validation_abc_tool_candidates

Returns the optional ABC mapping executable command names probed by
C<hdl_external_validation_tools>, in priority order.

=head2 missing_systemverilog_validation_tools

Returns the sorted list of required SystemVerilog validation tools that are
not currently available.

=head2 validate_systemverilog_file(%args)

Runs Verilator lint and ABC-free Yosys structural synthesis over one generated
SystemVerilog file. Required arguments are C<source_file> and C<top_module>.
The Yosys pass uses C<read_verilog -sv -noautowire>, C<synth -noabc -top>,
and C<stat>. The C<-noabc> guard is intentional: this lane proves FSMGen did
not emit garbage HDL and that Yosys can lower it into structural logic, while
leaving ABC timeout/optimization edge cases for a later dedicated hardening
lane.

Passing C<abc_mapping =E<gt> 1> enables the explicit opt-in ABC mapping probe.
That mode requires the optional C<abc_mapping> tool discovery to succeed and
uses C<synth -top> instead of C<synth -noabc -top>. The default CLI validation
path remains ABC-free.

=cut
