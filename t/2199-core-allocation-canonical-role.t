use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
my $json=JSON::PP->new->canonical;
sub parsed {
    my ($width,$op)=@_;
    my $source="(?fsm:canonical_role (+params (W $width)) (+size (A (param W)) (B (param W)) (DATA 1) (OTHER 1))"
        ." (idle (<($op A B) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    return FSM::Adapter::FSMGenFull->new(debug=>0)->parse_fsm(scalar Lispish::multi(\$source));
}
sub helper {my ($module)=@_;return grep {$_->get_attribute('is_intermediate')} values %{$module->signals}}
subtest 'actual facade helper roles qualify the explicit allocation holder without publication' => sub {
    for my $width (1,8) {for my $op ('&','|','^') {
        my $module=parsed($width,$op);my @helpers=helper($module);is(scalar(@helpers),1,'actual parser creates one helper');
        my $signal=$helpers[0];is($signal->get_attribute('signal_role'),'INTERNAL_INTERMEDIATE','actual classifier supplies canonical uppercase role');
        ok(!defined($signal->intermediate_width_allocation),'parser publication remains inactive before explicit supplied contract');
        my $before=$json->encode([$module->parameters,$module->parameter_default_sources,$module->parameter_default_bindings,
            $signal->width,$signal->attributes]);
        my $record={kind=>'binary_operand_max',operator=>$op,source_names=>['A','B'],selected_width=>$width};
        ok(eval {$signal->set_intermediate_width_allocation($record);1},'actual classified helper accepts the explicit matching contract') or diag $@;
        is_deeply($signal->intermediate_width_allocation,$record,'actual current source object retains the detached record');
        is($json->encode([$module->parameters,$module->parameter_default_sources,$module->parameter_default_bindings,
            $signal->width,$signal->attributes]),$before,'source parameter/role/width values and JSON kinds preserve');
    }}
};
subtest 'canonical role writes revoke and conflicting actual roles remain withheld' => sub {
    my ($signal)=helper(parsed(8,'&'));
    my $record={kind=>'binary_operand_max',operator=>'&',source_names=>['A','B'],selected_width=>8};
    my $installed=eval {$signal->set_intermediate_width_allocation($record);1};
    ok($installed,'canonical role is eligible before lifecycle control') or diag $@;
    $signal->set_attribute('signal_role','INTERNAL_INTERMEDIATE');
    ok(!defined($signal->intermediate_width_allocation),'matching canonical role assignment revokes the old record');
    for my $role ('INPUT','OUTPUT','INTERNAL','UNKNOWN') {
        $signal->set_attribute('signal_role',$role);
        ok(!eval {$signal->set_intermediate_width_allocation($record);1},'conflicting role cannot borrow intermediate allocation');
        ok(!defined($signal->intermediate_width_allocation),'refused role exposes no old record');
    }
};
done_testing();
