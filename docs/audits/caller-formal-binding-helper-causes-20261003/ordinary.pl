use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF::LoweringIR;
my $base='docs/audits/caller-formal-binding-helper-causes-20261003';
my $json=JSON::PP->new->canonical;
open my $fh,'<:raw',"$base/causes.json" or die $!;my $rows=$json->decode(do {local $/;<$fh>})->{rows};close $fh or die $!;
my @products;
for my $row (grep {$_->{band} eq 'current_fixture' && $_->{id}=~/^shadow\//} @$rows) {
 my $actor=FSM::Adapter::ISF->new->parse_source($row->{source},'binding_scope.isf');
 my $before=$json->encode($actor);
 my $lowerer=FSM::Scheduler::ISF::LoweringIR->new;
 my $accepted=eval {$lowerer->_validate_transaction_port_bindings($actor);1};my $error=$@;
 die $error unless $accepted;die 'source mutation' unless $json->encode($actor) eq $before;
 my $prepared=$lowerer->prepare_formal_source($actor);
 die 'preparation source mutation' unless $json->encode($actor) eq $before;
 die 'prepared actor drift' unless $json->encode($prepared->{actor}) eq $before;
 push @products,{id=>$row->{id},source=>$row->{source},actor=>$actor,prepared=>$prepared};
}
open my $out,'>:raw',"$base/products.json" or die $!;print {$out} $json->encode({rows=>\@products}),"\n";close $out or die $!;
print 'PASS ordinary ',scalar(@products),' complete shadow actors/preparation/binding records and source isolation.',"\n";
