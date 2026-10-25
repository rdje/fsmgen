use strict; use warnings;
use FSM::VIAL::ArchitectureScaleBridgeFanout;
use FSM::HIAL::VIALBridge::Builder;
use Digest::SHA qw(sha256_hex);
use JSON::PP;
my $json=JSON::PP->new->canonical(1)->utf8(1);
sub read_raw { open my $f,'<:raw',$_[0] or die $!; local $/; return <$f>; }
sub write_raw { open my $f,'>:raw',$_[0] or die $!; print {$f} $_[1]; close $f or die $!; }
my $construction=FSM::VIAL::ArchitectureScaleBridgeFanout->construct({primary_axis=>'selected_units',level=>'reference_v1',reference_hial_text=>read_raw('ppif/ahb_lite_subordinate.ppif'),reference_vial_text=>read_raw('vial/ahb_subordinate_base_output_arbitration.vial')});
my $build=FSM::HIAL::VIALBridge::Builder->can('build_ial2_via_ial1');
my @reports;
my $evaluation;
{
 no warnings 'redefine';
 local *FSM::HIAL::VIALBridge::Builder::build_ial2_via_ial1=sub {
  my $r=$build->(@_); die $json->encode($r->{diagnostics}) unless $r->{ok};
  push @reports,$json->encode($r->{report});
  write_raw("$ARGV[0]/generated.fsm",$_[1]{generated_ial0}{text});
  return $r;
 };
 $evaluation=FSM::VIAL::ArchitectureScaleBridgeFanout->evaluate({construction=>$construction});
}
die $json->encode($evaluation) unless $evaluation->{ok};
die 'Missing independent reports' unless @reports==2 && $reports[0] eq $reports[1];
die 'Captured report hash disagrees' unless sha256_hex($reports[0]) eq $evaluation->{report_sha256};
write_raw("$ARGV[0]/report.json",$reports[0]);
write_raw("$ARGV[0]/evaluation.json",$json->encode($evaluation));
print $evaluation->{report_sha256},"\n";
