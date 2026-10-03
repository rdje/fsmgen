use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use Storable qw(dclone);
use Test::More;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
my $base='docs/audits/formal-resource-cause-repair-20261003';
my $json=JSON::PP->new->canonical;
our $lowerer=FSM::Scheduler::ISF->new->{ir};
open my $fh,'-|','git','show','0dd4aea7ae402cf57ac3924e8d443a3d9b6b8749:t/1944-isf-formal-resource-products.t' or die $!;
my $test=do {local $/;<$fh>};close $fh or die $!;
my $start=index($test,'sub parse {');my $end=index($test,'sub prior_names {',$start);
my $reject_start=index($test,'sub rejected {');my $reject_end=index($test,"subtest '",$reject_start);
die 'exact helper blocks missing' unless $start>=0 && $end>$start && $reject_start>=0 && $reject_end>$reject_start;
our $observed;
{
    no warnings 'redefine';
    *main::like=sub ($$;$) {
        my ($error,$pattern,$label)=@_;my ($first)=split /\n/,$error;
        $observed={error=>$error,matched=>$error=~$pattern?1:0,primary_matched=>defined($first) && $first=~$pattern?1:0};
        return Test::More::like($error,$pattern,$label);
    };
}
eval substr($test,$start,$end-$start).substr($test,$reject_start,$reject_end-$reject_start);die $@ if $@;
my $base_source=source('rule_slot',3);
my $actor=parse($base_source);
my $helper=$lowerer->prepare_formal_source($actor)->{resource_signal_products}[0]{declaration}{name};
my @specs=(
    ['raw formal alias','isf_resource_round_robin_pointer_collision'],
    ['fixed','isf_resource_round_robin_pointer_collision'],
    ['unknown_user','isf_resource_unknown_user'],
    ['overlap','isf_resource_round_robin_user_overlap'],
    ['malformed name','isf_resource_round_robin_name_shape'],
    ['unsupported kind','isf_resource_unsupported_kind'],
);
my @rows;
for my $spec (@specs) {
    my ($id,$code)=@$spec;my $source=$base_source;my $input=dclone($actor);my $mutation;
    if ($id eq 'raw formal alias') {$source=~s/\bpayload\b/$helper/g;$input=parse($source);$input=$lowerer->prepare_formal_source($input)->{actor}}
    elsif ($id eq 'fixed') {push @{$input->{storage}[0]{signals}},{name=>$helper,width=>2};$mutation='append_fixed_pointer'}
    elsif ($id eq 'unknown_user') {$input->{resources}[0]{users}[0]='missing';$mutation='replace_first_user'}
    elsif ($id eq 'overlap') {my $extra=dclone($input->{resources}[0]);$extra->{name}='other';push @{$input->{resources}},$extra;$mutation='append_other_resource'}
    elsif ($id eq 'malformed name') {$input->{resources}[0]{name}='shared-bus';$mutation='malformed_resource_name'}
    else {$input->{resources}[0]{kind}='backlog_kind';$mutation='unsupported_resource_kind'}
    my $pattern=eval 'qr/'.$code.'/';die $@ if $@;
    for my $band (qw(current_fixture wrong_body primary_body_echo)) {
        my $submitted=dclone($input);
        $submitted->{transactions}[0]{clauses}[1]=[$band eq 'primary_body_echo'?$code:'unsupported_clause'] if $band ne 'current_fixture';
        my $before=dclone($submitted);$observed=undef;
        rejected($submitted,$pattern,"$id / $band");
        die 'actual consumer missing' unless $observed;
        is($observed->{matched},$band eq 'current_fixture'?1:0,"$id / $band cannot qualify an unrelated complete primary cause");
        is_deeply($submitted,$before,"$id / $band whole input unchanged");
        push @rows,{id=>$id,code=>$code,band=>$band,source=>$source,mutation=>$mutation,actor_before=>$before,actor_after=>$submitted,%$observed};
    }
}
open my $out,'>:raw',"$base/prior-helper-causes.json" or die $!;print {$out} $json->encode({helper_name=>$helper,rows=>\@rows}),"\n";close $out or die $!;
done_testing;
