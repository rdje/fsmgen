use strict;
use warnings;
use lib 'perl', 't/lib';
use JSON::PP;
use FSM::VIAL::ArchitectureScaleBackendEmission;
use FSM::Test::AhbReference qw(checked_ahb_reference);
sub slurp {
    open my $stream, '<:raw', $_[0] or die "$!";
    local $/; return <$stream>;
}
my $class = 'FSM::VIAL::ArchitectureScaleBackendEmission';
my $construction = $class->_publication_candidate({
    backend_profile => 'sv_portable_verilator', level => 'reference_v1',
    reference_hial_text => slurp('ppif/ahb_lite_subordinate.ppif'),
    reference_vial_text => slurp('vial/ahb_subordinate_base_output_arbitration.vial'),
});
my $built = $class->build({construction => $construction});
my $actual = eval {$class->_publication_foundation({construction => $construction})};
warn $@ if $@;
my $reference = checked_ahb_reference();
print JSON::PP->new->canonical->utf8->pretty->encode({
    actual => $actual, backend_inputs => $built->{backend_inputs},
    build_diagnostics => $built->{diagnostics}, bridge => $built->{bridge_manifest} ? $built->{bridge_manifest}->as_hashref : undef,
    reference => $reference,
    scope => 'Actual canonical route and independently checked current public bridge. Backend input and dependent historical identity causes are not assumed.'});
package FSM::VIAL::ArchitectureScaleBackendEmission;
sub _publication_candidate {return __PACKAGE__->_construct_candidate($_[1])}
sub _publication_foundation {return __PACKAGE__->_evaluate_foundation_candidate($_[1])}
