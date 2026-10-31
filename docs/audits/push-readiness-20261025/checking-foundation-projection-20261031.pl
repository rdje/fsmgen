use strict;
use warnings;
use lib 'perl', 't/lib';
use Digest::SHA qw(sha256_hex);
use JSON::PP;
use FSM::VIAL::ArchitectureScaleCheckingState;
use FSM::Test::AhbReference qw(checked_ahb_reference);
my $json = JSON::PP->new->canonical->utf8;
sub slurp {
    open my $stream, '<:raw', $_[0] or die "$!";
    local $/; return <$stream>;
}
my $construction = FSM::VIAL::ArchitectureScaleCheckingState::_publication_candidate({
    primary_axis => 'model_instances', level => 'gate_candidate_v1',
    reference_hial_text => slurp('ppif/ahb_lite_subordinate.ppif'),
    vial_source_text => slurp('vial/ahb_subordinate_base_output_arbitration.vial'),
});
my $actual = FSM::VIAL::ArchitectureScaleCheckingState->evaluate({construction => $construction});
my $reference = checked_ahb_reference();
die 'current bridge differs from independently checked public route'
    unless $actual->{stage_identities}{bridge_manifest_sha256} eq $reference->{report_sha256};
sub rerun {
    my ($value) = @_;
    return 'rerun/' . sha256_hex($json->encode({
        workload_identity => $value->{workload_identity}, stage_identities => $value->{stage_identities}}));
}
sub identity {
    my ($value) = @_;
    my $projection = $json->decode($json->encode($value));
    $projection->{evaluation_identity} = undef;
    delete $projection->{contract_discrepancies} unless @{$projection->{contract_discrepancies}};
    return 'checking-evaluation/' . sha256_hex($json->encode($projection));
}
my $old = $json->decode($json->encode($actual));
$old->{stage_identities}{bridge_manifest_sha256} = 'a4565d40507f369799adaf199b57a6695b12022d068ff9902cec1bdec1a71aca';
$old->{rerun_identity} = rerun($old);
$old->{evaluation_identity} = identity($old);
my $checks = {current_rerun => rerun($actual) eq $actual->{rerun_identity} ? 1 : 0,
    current_evaluation => identity($actual) eq $actual->{evaluation_identity} ? 1 : 0,
    historical_rerun => $old->{rerun_identity} eq 'rerun/ceefc4f30bd60d5d7af60a20ae278e35e1478dbc43a0f61010c8473462c69033' ? 1 : 0,
    historical_evaluation => $old->{evaluation_identity} eq 'checking-evaluation/9b6746001158e81fb6e4f55d5ede16c257d31c4f479495472665c000d5acd159' ? 1 : 0};
print $json->pretty->encode({actual => $actual, historical_projection => $old,
    current_reference => $reference->{report_sha256}, checks => $checks,
    scope => 'Exact legacy foundation tuple and evaluation recipes; only bridge identity and its dependent rerun/evaluation fields project. Public checked-AHB route separately freezes every non-provenance bridge field.'});
die 'projection failed' if grep {!$_} values %$checks;
package FSM::VIAL::ArchitectureScaleCheckingState;
sub _publication_candidate {
    return __PACKAGE__->_construct_candidate($_[0]);
}
