use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
my $base='docs/audits/reusable-product-helper-causes-20261003';
my $json=JSON::PP->new->canonical;
my ($mode,$phase,@guards);
sub copy_value {
    my ($value)=@_;
    return [map {copy_value($_)} @$value] if ref($value) eq 'ARRAY';
    return {map {$_=>copy_value($value->{$_})} keys %$value} if ref($value) eq 'HASH';
    return $value;
}
my $original=FSM::Scheduler::ISF::LoweringIR->can('_ensure_atl_child_data_source_ports');
{
    no warnings 'redefine';
    *FSM::Scheduler::ISF::LoweringIR::_ensure_atl_child_data_source_ports=sub {
        my @args=@_;
        my $before=$json->decode($json->encode($args[3]));
        my $caller=$args[3];
        $args[3]=copy_value($args[3]) if $mode eq 'detached';
        my $result=$original->(@args);
        push @guards,{phase=>$phase,context=>$args[0],instance=>$args[1],
            before=>$before,after=>$json->decode($json->encode($caller))};
        return $result;
    };
}
my @rows;
for my $fixture (qw(atl_resolved_child_pin_egress_vector_multi_pipeline atl_two_child_vector_data_pipeline)) {
    open my $fh,'<:raw',"isf/$fixture.isf" or die $!;
    my $source=do {local $/;<$fh>};close $fh or die $!;
    for my $selected (qw(original detached)) {
        $mode=$selected;@guards=();
        my $actor=FSM::Adapter::ISF->new->parse_file("isf/$fixture.isf");
        my $before=$json->decode($json->encode($actor));
        my $l=FSM::Scheduler::ISF->new->{ir};
        $phase='prepare';my $prepared=$l->prepare_formal_source($actor);
        my $after_prepare=$json->decode($json->encode($actor));
        $phase='build';my $module=$l->build_module($actor);
        push @rows,{fixture=>$fixture,mode=>$selected,source=>$source,before=>$before,
            after_prepare=>$after_prepare,after_build=>$json->decode($json->encode($actor)),
            prepared=>$prepared,module=>$module,guards=>[@guards]};
    }
}
open my $out,'>:raw',"$base/guard-observations.json" or die $!;
print {$out} $json->encode({rows=>\@rows}),"\n" or die $!;close $out or die $!;
print "Captured actual admission guard and detached-value counterfactual without provider writes.\n";
