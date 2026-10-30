use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use FSM::HDL::FlattenedDT;
use FSM::ConcatenationSourceObservationSupport;

# Observe the already retained finite native producer, without adding source
# admission, HDL compilation, generic overrides or runtime execution.
my @observations;
my $json = JSON::PP->new->canonical;
my $collect = \&FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals;
my $native = '';
{
    no warnings 'redefine';
    local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals = sub {
        my ($owner, $module) = @_;
        my $rows = $collect->(@_);
        my $ctx = $owner->{flattened_dt};
        my @frames;
        for my $name (sort keys %$rows) {
            next unless ref($rows->{$name}{ast}) eq 'FSM::CoreAST::Concatenation';
            my %args = (factorizer => $ctx->{ast_factorizer}, signal_name => $name,
                fsm_module => $module, assignment_analysis => $ctx->{assignment_analysis});
            my $frame = FSM::ConcatenationSourceObservationSupport->capture(%args);
            die 'actual native source observation withheld' unless $frame;
            my $current = FSM::ConcatenationSourceObservationSupport->current(%args, holder => $frame);
            die 'actual native source observation changed' unless $current && $json->encode($current) eq $json->encode($frame);
            push @frames, {name => $name, frame => $frame, current => JSON::PP::true};
        }
        push @observations, {module => $module->name, frames => \@frames};
        return $rows;
    };
    open my $capture, '>', \$native or die $!;
    local *STDOUT = $capture;
    do './docs/audits/concat-guard-capture-20261030/probe.pl';
    die $@ if $@;
}
print $json->pretty->encode({native => decode_json($native), observations => \@observations});
