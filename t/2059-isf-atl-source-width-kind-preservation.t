use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);

my $json = JSON::PP->new->canonical;
my @captures;
my @fixtures = (
    ['atl_resolved_child_pin_egress_vector_multi_pipeline', 'worker', 'publish_result'],
    ['atl_two_child_vector_data_pipeline', 'reader', 'forward_payload'],
);
for my $fixture (@fixtures) {
    my ($name, $instance, $drive) = @$fixture;
    my $path = "isf/$name.isf";
    open my $fh, '<:raw', $path or die $!;
    my $source = do {local $/; <$fh>};
    close $fh or die $!;
    for my $band (qw(ordinary wrong_width missing_output)) {
        for my $method (qw(prepare_formal_source build_module)) {
            my $actor = FSM::Adapter::ISF->new->parse_file($path);
            my $outputs = $actor->{_atl_actor_type_resolutions}{$instance}{actor}{interface}{outputs};
            $outputs->[0]{width} = '7' if $band eq 'wrong_width';
            shift @$outputs if $band eq 'missing_output';

            # Snapshot the original before any API or clone can change Perl's
            # numeric flags. Complete serialization checks values and JSON kinds.
            my $before = $json->encode($actor);
            my $lowerer = FSM::Scheduler::ISF->new->{ir};
            my $result;
            my $accepted = eval {$result = $lowerer->$method($actor); 1};
            my $error = $@;
            my $label = "$name / $band / $method";
            is($accepted ? 1 : 0, $band eq 'ordinary' ? 1 : 0, "$label admission");
            is($json->encode($actor), $before, "$label preserves complete caller and kinds");
            if ($band eq 'ordinary') {
                is($error, '', "$label has no error");
                is($method eq 'prepare_formal_source' ? $result->{actor}{actor_name} : $result->{actor_name},
                    $name, "$label retains actual result identity");
            } else {
                my $expected = "ATL generated top for actor '$name' "
                    . "data movement '$drive' requires a child output port 'payload' "
                    . "on " . ($instance eq 'reader' ? 'source instance' : 'instance') . " '$instance'";
                ok(diagnostic_cause_matches($error, $expected), "$label complete output admission cause")
                    or diag($error);
                ok(!defined($result), "$label returns no partial result");
            }
            push @captures, {
                fixture => $name, instance => $instance, drive => $drive,
                band => $band, method => $method, source => $source,
                original => $json->decode($before),
                actor => $json->decode($json->encode($actor)),
                accepted => $accepted ? 1 : 0, error => $error, result => $result,
            };
        }
    }
}
if (defined $ENV{FSMGEN_ATL_WIDTH_KIND_CAPTURE}) {
    open my $out, '>:raw', $ENV{FSMGEN_ATL_WIDTH_KIND_CAPTURE} or die $!;
    print {$out} $json->encode({rows => \@captures}), "\n" or die $!;
    close $out or die $!;
}
done_testing;
