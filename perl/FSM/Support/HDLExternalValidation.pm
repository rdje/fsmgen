package FSM::Support::HDLExternalValidation;

=head1 NAME

FSM::Support::HDLExternalValidation - Optional external SystemVerilog lint and synthesis validation

=head1 DESCRIPTION

Owns the bounded external-tool validation lane for generated SystemVerilog.
FSMGen still performs semantic and pre-generation checks internally; this
support package runs Verilator and Yosys after emission. Verilator checks that
the rendered text is valid lint-clean SystemVerilog. Yosys checks that the
same text can be turned into a structural netlist-like design, deliberately
without running the ABC mapping/optimization algorithm.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use Exporter qw(import);
use IPC::Cmd qw(can_run run);

our @EXPORT_OK = qw(
    hdl_external_validation_tools
    missing_systemverilog_validation_tools
    validate_systemverilog_file
);

sub hdl_external_validation_tools () {
    return {
        verilator => can_run('verilator'),
        yosys => can_run('yosys'),
    };
}

sub missing_systemverilog_validation_tools () {
    my $tools = hdl_external_validation_tools();
    return sort grep { !$tools->{$_} } qw(verilator yosys);
}

sub validate_systemverilog_file (%args) {
    my $source_file = $args{source_file}
        or die "[HDLExternalValidation.pm][validate_systemverilog_file()] Missing required 'source_file'";
    my $top_module = $args{top_module}
        or die "[HDLExternalValidation.pm][validate_systemverilog_file()] Missing required 'top_module'";

    die "[HDLExternalValidation.pm][validate_systemverilog_file()] Source file does not exist: $source_file"
        unless -f $source_file;

    my $tools = hdl_external_validation_tools();
    my @missing = sort grep { !$tools->{$_} } qw(verilator yosys);
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

    my $yosys_script = join '; ',
        'read_verilog -sv -noautowire ' . _yosys_quote($source_file),
        'synth -noabc -top ' . _yosys_identifier($top_module),
        'stat';
    push @steps, _run_step(
        name => 'yosys_synthesis',
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

Returns the discovered C<verilator> and C<yosys> executable paths, or false
values for tools that are not available on C<PATH>.

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

=cut
