use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use Storable qw(dclone);
use Test::More;
use FSM::Scheduler::ISF;
my $base='docs/audits/formal-resource-helper-causes-20261003';
my $json=JSON::PP->new->canonical;
our $lowerer=FSM::Scheduler::ISF->new->{ir};
our ($bad_name,$observed);
open my $fh,'<:raw',"$base/causes.json" or die $!;
my $old=$json->decode(do {local $/;<$fh>});close $fh or die $!;
my $input=(grep {$_->{id} eq 'malformed name' && $_->{band} eq 'current_fixture'} @{$old->{rows}})[0];
open $fh,'<:raw','t/1944-isf-formal-resource-products.t' or die $!;
my $test=do {local $/;<$fh>};close $fh or die $!;
my $start=index($test,'eval {$lowerer->prepare_formal_source($bad_name)};');
my $end=index($test,'rejected($bad_name,',$start);
die 'direct canonical source assertion missing' unless $start>=0 && $end>$start;
my $consumer=substr($test,$start,$end-$start);
{
    no warnings 'redefine';
    *main::like=sub ($$;$) {
        my ($error,$pattern,$label)=@_;my ($first)=split /\n/,$error;
        $observed={error=>$error,matched=>$error=~$pattern?1:0,primary_matched=>defined($first) && $first=~$pattern?1:0};
        return Test::More::like($error,$pattern,$label);
    };
}
my @rows;
for my $band (qw(current_fixture wrong_body primary_body_echo)) {
    $bad_name=dclone($input->{actor_before});
    $bad_name->{transactions}[0]{clauses}[1]=[$band eq 'primary_body_echo'?'isf_resource_round_robin_name_shape':'unsupported_clause'] if $band ne 'current_fixture';
    my $before=dclone($bad_name);$observed=undef;
    eval $consumer;die $@ if $@;die 'direct capture missing' unless $observed;
    is($observed->{matched},$band eq 'current_fixture'?1:0,"$band direct resource cause safety");
    is_deeply($bad_name,$before,"$band direct actor unchanged");
    push @rows,{band=>$band,source=>$input->{source},actor_before=>$before,actor_after=>$bad_name,%$observed};
}
open my $out,'>:raw',"$base/direct-causes.json" or die $!;print {$out} $json->encode({rows=>\@rows}),"\n";close $out or die $!;
done_testing;
