use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use FSM::Test::LocalFormalOriginAuthority;
my $base='docs/audits/local-formal-helper-causes-20261003';
my $json=JSON::PP->new->canonical;
sub read_json {open my $fh,'<:raw',$_[0] or die $!;my $raw=do {local $/;<$fh>};close $fh or die $!;return $json->decode($raw)}
my $bindings=read_json("$base/bindings.json");
eval 'package CurrentFormalHelper;'.$bindings->{helper};die $@ if $@;
eval $bindings->{packages};die $@ if $@;
delete $ENV{FSMGEN_FORMAL_DIAGNOSTIC_FULL_STACK};
my $select=read_json("$base/products/select.json");
my $authored=read_json("$base/products/authored.json");
my $auth=FSM::Test::LocalFormalOriginAuthority->from_source($select->{source},'select.isf');
my @rows;
for my $caller (@{$bindings->{callers}}) {
    my $id=$caller->{name};my $file=$id;$file=~s/[^a-zA-Z0-9_-]/_/g;
    my $positive=read_json("$base/products/$file.json");
    my $literal=$caller->{pattern};$literal=~s{\\/}{/}g;
    my $validator=$id eq 'equal-body origin transplant';
    my $class=$id eq 'actual clone callback lost' ? 'FSM::Test::LocalFormalOriginAuthority::DropClone'
        : $id eq 'actual Storable callback lost' ? 'FSM::Test::LocalFormalOriginAuthority::DropStorable'
        : 'FSM::Test::LocalFormalOriginAuthority';
    my @bands=$validator ? qw(positive wrong_context wrong_input_echo wrong_input_plain)
        : qw(positive wrong_source_plain wrong_source_echo wrong_label_echo);
    for my $band (@bands) {
        my ($accepted,$error,$input);
        if ($band eq 'positive') {
            ($accepted,$error)=@{$positive}{qw(accepted error)};
            $input={capture=>"products/$file.json",statement=>$caller->{statement},source_phase=>'fresh current T2052 real producer capture'};
        } elsif ($validator) {
            my $context=$json->decode($json->encode($authored->{context}));
            my $proof=$json->decode($json->encode($authored->{proof}));
            my $mutation;
            if ($band eq 'wrong_context') {$context->{actor}{name}='forged';$mutation={path=>['actor','name'],value=>'forged'}}
            else {my $class_name=$band eq 'wrong_input_echo' ? $literal : 'unrelated_object';$context->{extra}=bless {},$class_name;$mutation={path=>['extra'],perl_kind=>'blessed_hash',class=>$class_name,contents=>{}}}
            $input={api=>'validate',base_context=>$authored->{context},proof=>$authored->{proof},mutation=>$mutation};
            # No expected regex argument is introduced into the failing API stack.
            $accepted=eval {$auth->validate($context,$proof);1};$error=$@;
        } else {
            my $source=$band eq 'wrong_source_echo' ? "; $literal\n(not_actor)" : '(not_actor)';
            my $label=$band eq 'wrong_label_echo' ? "$literal.isf" : 'wrong.isf';
            $input={api=>'from_source',class=>$class,source=>$source,label=>$label};
            $accepted=eval {$class->from_source($source,$label);1};$error=$@;
        }
        # Compile and invoke the exact consumer only after the real failure.
        my $pattern=eval 'qr/'.$caller->{pattern}.'/';die $@ if $@;
        my $matched=CurrentFormalHelper::diagnostic_matches($error,$pattern)?1:0;
        my $first=CurrentFormalHelper::first_line($error);
        my $expected=$band eq 'positive' ? 1:0;
        ok(!$accepted,"$id / $band actually refuses");
        is($matched,$expected,"$id / $band names the actual cause");
        push @rows,{id=>$id,site=>$caller->{path}.':'.$caller->{line},band=>$band,input=>$input,error=>$error,first_line=>$first,accepted=>$accepted?1:0,matched=>$matched,expected=>$expected,pattern=>$caller->{pattern},full_trace_matched=>$error=~$pattern?1:0};
    }
}
open my $fh,'>:raw',"$base/causes.json" or die $!;print {$fh} $json->encode({rows=>\@rows}),"\n" or die $!;close $fh or die $!;
done_testing;
