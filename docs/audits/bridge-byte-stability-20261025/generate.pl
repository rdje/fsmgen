use strict; use warnings;
use FSM::Pipeline::HDLGenerator;
use File::Spec;
use Cwd qw(getcwd);
my $path=File::Spec->catfile(getcwd(),'t','..','fsm','ahb_lite_subordinate.fsm');
for my $language (qw(systemverilog vhdl)) {
 my $result=FSM::Pipeline::HDLGenerator->new(debug_level=>0,target_language=>$language,quiet=>1,strict_mode=>1)->generate_hdl_from_file($path);
 my $text=$result->{hdl_code};
 $text =~ s{^// Date: .*\n}{// Date: <normalized>\n}m if $language eq 'systemverilog';
 open my $out,'>:raw',"$ARGV[0]/$language.txt" or die $!;
 print {$out} $text; close $out or die $!;
}
