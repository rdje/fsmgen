use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use Digest::SHA qw(sha256_hex);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Pipeline::HDLGenerator;

my $work = tempdir(CLEANUP => 1);
my $direct_prefix = '[VHDL.pm][direct scaffold] Unsupported generated SystemVerilog shape for direct VHDL backend: ';
my $mixed_member = qr/^Error generating HDL: \Q$direct_prefix\Eunsupported packed struct member 'logic signed \[4:0\] data; struct packed \{ bit item_0; '/;
my $record_input = qr/^Error generating HDL: \Q$direct_prefix\Eunsupported generated port declaration 'input fsmgen_m[1-9][0-9]*_link_rx_lmp_t_fsmgen_t lmp_in'/;
my @refusals = (
    ['t/data/isf_record_input_runtime.isf', $mixed_member],
    ['t/data/isf_record_input_generated_domains_runtime.isf', composition_reason('packed_input_generated_domains_top')],
    ['t/data/isf_record_input_generated_blocking_runtime.isf', composition_reason('packed_input_generated_blocking_top')],
    ['docs/audits/specforge-aggregate-intake-20260930/record-port.isf', $record_input],
    ['docs/audits/specforge-aggregate-intake-20260930/record-port-field-guard.isf', $record_input],
);
my @controls = (
    ['docs/audits/specforge-aggregate-intake-20260930/baseline-good.isf',
        qr/entity link_rx is/, qr/subtype_in\s+:\s+in std_logic_vector\(3 downto 0\)/],
    ['t/corpus/direct_aggregate_constant_target_autogrowth.fsm',
        qr/entity direct_aggregate_constant_target_autogrowth is/,
        qr/OUT_FRAME\s+:\s+out std_logic_vector\(4 downto 0\)/],
);
my @paths = (map {$_->[0]} @refusals, @controls);
push @paths, qw(bin/fsmgen perl/FSM/Pipeline/HDLGenerator.pm
    perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm
    perl/FSM/Backend/VHDL/StructuralRTLIREmitter.pm
    perl/FSM/Composition/PlanBuilder.pm
    perl/FSM/Adapter/ISF/Parser.pm perl/FSM/Scheduler/ISF/LoweringIR.pm
    perl/FSM/Support/ISFPublicInterfaceContract.pm);
my $before = {map {$_ => sha256_hex(read_file($_))} @paths};
my @observed;

for my $i (0..$#refusals) {
    my ($source,$reason) = @{$refusals[$i]};
    subtest "VHDL profile refuses $source before publication" => sub {
        my $existing = "$work/existing_$i.vhd";
        write_file($existing, "EXISTING DESTINATION\n");
        my $native = capture([$^X,'bin/fsmgen','--strict','--quiet','--language','vhdl',
            '--output',$existing,$source]);
        ok(refused($native,$reason),'native exit, signal and first diagnostic establish exact refusal')
            or diag($native->{stdout},$native->{stderr});
        is(read_file($existing),"EXISTING DESTINATION\n",'existing destination remains byte-exact');
        unlike($native->{stdout},qr/\b(?:entity|architecture|module|typedef)\b/,
            'native failure publishes no HDL payload');
        my $missing = "$work/missing_$i.vhd";
        my $absent = capture([$^X,'bin/fsmgen','--strict','--quiet','--language','vhdl',
            '--output',$missing,$source]);
        ok(refused($absent,$reason),'same profile refuses absent destination') or diag($absent->{stderr});
        ok(!-e $missing,'failure creates no destination');
        my ($product,$error);
        eval {$product=FSM::Pipeline::HDLGenerator->new(debug_level=>0,target_language=>'vhdl',quiet=>1)
            ->generate_hdl_from_file($source);1} or $error=$@;
        ok(!defined($product),'public pipeline returns no partial successful product');
        like(primary_diagnostic($error // ''),$reason,'public pipeline retains the same precise primary reason');
        push @observed, [$native,$reason];
    };
}

for my $i (0..$#controls) {
    my ($source,$entity,$port) = @{$controls[$i]};
    subtest "supported VHDL control $source remains admitted" => sub {
        my $output = "$work/control_$i.vhd";
        my $native=capture([$^X,'bin/fsmgen','--strict','--quiet','--language','vhdl','--output',$output,$source]);
        is($native->{exit_code},0,'native control emits successfully') or diag($native->{stderr});
        is($native->{signal},0,'native control ends normally');
        is($native->{stderr},'','native control stderr is clean');
        my $text=read_file($output);
        like($text,$entity,'independently named entity emitted');
        like($text,$port,'independently sized scalar or packed-vector declaration emitted');
        unlike($text,qr/\b(?:module|typedef|always_ff|always_comb)\b/,'control emits VHDL scaffold syntax');
        my $product=FSM::Pipeline::HDLGenerator->new(debug_level=>0,target_language=>'vhdl',quiet=>1)
            ->generate_hdl_from_file($source);
        like($product->{hdl_code},$entity,'public pipeline admits supported control');
        like($product->{hdl_code},$port,'public pipeline preserves independent declaration');
        if ($i == 1) {
            like($text,qr/OUT_LANES\s+<=\s+"10101";/,'existing packed-output constant keeps exact literal');
        }
    };
}

subtest 'refusal oracle rejects false success and stack-only expected text' => sub {
    for my $row (@observed) {
        my ($native,$reason)=@$row;
        ok(refused($native,$reason),'actual selected negative calibrates oracle');
        ok(!refused({%$native,exit_code=>0},$reason),'zero exit never qualifies refusal');
        ok(!refused({%$native,signal=>9},$reason),'signal failure never qualifies profile refusal');
        ok(!refused({%$native,stderr=>"Error generating HDL: unrelated failure\n\t".primary_diagnostic($native->{stderr})},$reason),
            'expected reason only in later stack text never qualifies');
        ok(!refused({%$native,stderr=>''},$reason),'missing diagnostic never qualifies');
    }
};

is_deeply({map {$_ => sha256_hex(read_file($_))} @paths},$before,
    'complete selected sources and named producer bytes remain unchanged');
done_testing;

sub composition_reason {
    my ($top)=@_;
    return qr/^Composition source '\?top:\Q$top\E' .*Target language 'vhdl' is not implemented for this composition shape yet: generated-child composition VHDL is outside the bounded C2 scalar-autowire\/scalar-bitstring-one-bit-aggregate-generic and APB\/C4 generated-FSM structural-top leaves\. See docs\/COMPOSITION_SCOPE\.md and docs\/COMPOSITION_LEGACY_MAPPING\.md\.\z/;
}
sub primary_diagnostic {
    my ($error)=@_;
    my @lines=split /\n/,$error;
    shift @lines if @lines && $lines[0] =~ /^Source file: /;
    return $lines[0] // '';
}
sub refused { my($result,$reason)=@_; return $result->{exit_code} == 1 && $result->{signal} == 0
    && primary_diagnostic($result->{stderr}) =~ $reason ? 1 : 0; }
sub capture { FSM::Test::SourceQueryRunner::_capture($_[0],''); }
sub read_file {open my $fh,'<:raw',$_[0] or die $!;local $/;my $s=<$fh>;close $fh or die $!;return $s;}
sub write_file {open my $fh,'>:raw',$_[0] or die $!;print {$fh} $_[1] or die $!;close $fh or die $!;}
