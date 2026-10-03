use strict;
use warnings;
use Test::More;
use JSON::PP;
use Carp ();
use FSM::Support::ISFInterfacePortMetadata qw(capture_interface_port_metadata snapshot_interface_port_metadata);
my $base = 'docs/audits/interface-metadata-runtime-20261004';
my $json = JSON::PP->new->canonical;
open my $fh, '<:raw', 't/1983-isf-interface-port-metadata.t' or die $!;
my $test = do {local $/; <$fh>}; close $fh or die $!;
my $start = index($test, 'sub rejects {');
my $end = index($test, 'sub write_file {', $start);
die 'exact helper missing' unless $start >= 0 && $end > $start;
my $helper = substr($test, $start, $end - $start);
# Compile the complete unchanged helper before any producer invocation. No
# active eval-source frame is used as evidence for a wanted diagnostic.
eval $helper; die $@ if $@;
our ($captured, $observed);
my @rows;
{
    no warnings 'redefine';
    local *main::like = sub ($$;$) {
        my ($actual, $pattern, $label) = @_;
        my ($first) = split /\n/, $actual;
        $observed = {error => $actual, pattern => "$pattern",
            matched => $actual =~ $pattern ? 1 : 0,
            first_line_classified => defined($first)
                && $first =~ /\AInvalid ISF interface port metadata:/ ? 1 : 0};
        return Test::More::like($actual, $pattern, $label);
    };
    my @cases = (
        ['real_metadata', 0, 'ordinary metadata', 'snapshot'],
        ['earlier_storable', 0, 'ordinary earlier refusal', 'snapshot'],
        ['caller_label_echo', 1, 'Invalid ISF interface port metadata: caller label only', 'snapshot'],
        ['caller_argument_echo', 1, 'ordinary earlier refusal', 'capture'],
    );
    @cases = (['primary_file_location', 0, 'ordinary earlier refusal', 'snapshot']) if @ARGV;
    for my $case (@cases) {
        my ($id, $verbose, $label, $route) = @$case;
        local $Carp::Verbose = $verbose;
        my $input = $id eq 'real_metadata' ? [undef]
            : $route eq 'capture' ? {inputs => [], outputs => [], earlier_native => sub {1}}
            : [{earlier_native => sub {1}}];
        $captured = undef; $observed = undef;
        my $operation = sub {
            my $ok = eval {
                $route eq 'capture'
                    ? capture_interface_port_metadata($input, 'Invalid ISF interface port metadata: argument only')
                    : snapshot_interface_port_metadata($input);
                1;
            };
            my $error = $@;
            $captured = {accepted => $ok ? 1 : 0, error => $error};
            die $error unless $ok;
        };
        rejects($operation, $label);
        die 'actual native/consumer capture missing' unless $captured && $observed;
        push @rows, {id => $id, route => $route, carp_verbose => $verbose,
            label => $label, native => $captured, consumer => $observed};
    }
}
open my $out, '>:raw', "$base/" . (@ARGV ? "primary-location.json" : "controls.json") or die $!;
print {$out} $json->encode({helper => $helper, loaded_module => $INC{'FSM/Support/ISFInterfacePortMetadata.pm'}, rows => \@rows}), "\n" or die $!;
close $out or die $!;
done_testing;
