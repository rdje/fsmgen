use strict;
use warnings;
use JSON::PP;
my $base='docs/audits/local-formal-helper-causes-20261003';
my $json=JSON::PP->new->canonical;
sub read_json {open my $fh,'<:raw',$_[0] or die $!;my $raw=do {local $/;<$fh>};close $fh or die $!;return $json->decode($raw)}
my $bound=read_json("$base/bindings.json");my $source=$bound->{sources}{'t/2052-isf-local-formal-origin-authority.t'};
my ($header)=$source=~/(my \$header =.*?;)/s;my ($ports)=$source=~/(my \$ports =.*?;)/s;
die 'missing fixture header/ports' unless defined $header && defined $ports;
my $code=$header."\n".$ports."\n";
for my $name (qw(imports network generated domain plain)) {
    my ($statement)=$source=~/(my \$$name =.*?;)/s;die "missing $name" unless defined $statement;$code.=$statement."\n";
}
$code.='{imports=>$imports,network=>$network,generated=>$generated,domain=>$domain,plain=>$plain}';
my $inputs=eval $code;die $@ if $@;
my $select=read_json("$base/products/select.json");my $authored=read_json("$base/products/authored.json");
my %result=('equal-body origin transplant'=>{api=>'validate',authority_source=>$select->{source},authority_label=>'select.isf',context=>$authored->{context},proof=>$authored->{proof}});
for my $name ('actual clone callback lost','actual Storable callback lost') {
    $result{$name}={api=>'from_source',class=>'FSM::Test::LocalFormalOriginAuthority::'.($name=~/Storable/ ? 'DropStorable':'DropClone'),source=>$select->{source},label=>'select.isf'};
}
my @cases=(['imported producer boundary','imports','imports.isf'],['actor network boundary','network','network.isf'],['generated transaction boundary','generated','generated.isf'],['domain constructor boundary','domain','domain.isf'],['no formal preparation boundary','plain','plain.isf']);
for my $case (@cases) {my ($name,$key,$label)=@$case;$result{$name}={api=>'from_source',class=>'FSM::Test::LocalFormalOriginAuthority',source=>$inputs->{$key},label=>$label}}
open my $fh,'>:raw',"$base/positive_inputs.json" or die $!;print {$fh} $json->encode(\%result),"\n" or die $!;close $fh or die $!;
print "Full positive API inputs materialized from exact current fixture expressions and whole source products.\n";
