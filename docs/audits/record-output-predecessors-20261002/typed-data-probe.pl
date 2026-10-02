use strict;use warnings;
use lib 'perl';
use JSON::PP;use Scalar::Util qw(blessed reftype refaddr);
use FSM::Adapter::ISF;use FSM::Scheduler::ISF;use FSM::Pipeline::HDLGenerator;
my $json=JSON::PP->new->canonical;my %classes;my $nodes=0;
for my $path(qw(isf/record_input.isf isf/record_input_children.isf isf/storage_fields.isf isf/storage_word_access.isf t/data/isf_record_input_generated_domains_runtime.isf t/data/isf_record_input_generated_blocking_runtime.isf)) {
 my $a=FSM::Adapter::ISF->new->parse_file($path);my $s=FSM::Scheduler::ISF->new;
 my $l=$s->lower($a);my $r=$json->decode($s->report($a));
 my $f=FSM::Pipeline::HDLGenerator->new(target_language=>'systemverilog',quiet=>1,strict_mode=>1)->generate_hdl_from_file($path);
 my $value=snapshot({actor=>$a,lower=>$l,report=>$r,facade_source_info=>$f->{source_info}},$path,{},0);
 $json->encode($value);
}
die "Missing actual composition classes\n" unless $classes{'FSM::Composition::Spec'} && $classes{'FSM::Composition::Top'};
print "Complete tagged data snapshots serialize without null substitution; classes: ",join(',',sort keys %classes),".\n";
sub snapshot {
 my($v,$path,$active,$depth)=@_;return $v if !ref($v) || JSON::PP::is_bool($v);
 die "Data census bound exceeded\n" if ++$nodes>50000 || $depth>500;
 my $address=refaddr($v);die "Cyclic data at $path\n" if $active->{$address};local $active->{$address}=1;
 my $kind=reftype($v);my $data;
 if($kind eq 'HASH') {$data={map {$_=>snapshot($v->{$_},"$path.$_",$active,$depth+1)} keys %$v};}
 elsif($kind eq 'ARRAY') {$data=[map {snapshot($v->[$_],"$path\[$_\]",$active,$depth+1)} 0..$#$v];}
 else {die "Non-data $kind at $path\n";}
 if(my $class=blessed($v)) {
  ++$classes{$class};print "$path: $class $kind full fields ",join(',',sort keys %$v),"\n" if $kind eq 'HASH';
  if($class eq 'FSM::Composition::Spec') {
   for my $key(qw(embedded_dt_sources embedded_fsm_sources embedded_package_sources raw_ast top)) {
    my $public=snapshot($v->$key(),"public.$key",{},$depth+1);
    die "Getter fidelity mismatch $key\n" unless $json->encode($public) eq $json->encode($data->{$key});
   }
  }
  return {capture_class=>$class,capture_kind=>$kind,capture_data=>$data};
 }
 return $data;
}
