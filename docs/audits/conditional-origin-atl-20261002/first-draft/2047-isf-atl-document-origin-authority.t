use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use File::Spec;
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::ATLDocumentOriginAuthority;
use FSM::Adapter::ISF::Parser;

{
    package FSM::Test::ATLLateOriginMutation;
    use parent -norequire, 'FSM::Test::ATLDocumentOriginAuthority::Parser';
    sub _finalize_actor_crossings {
        my ($self, $actor, @args) = @_;
        my $result = $self->SUPER::_finalize_actor_crossings($actor, @args);
        if ($self->{mutation} eq 'target') {
            $actor->{_atl_actor_type_resolutions}{first_node}{actor}{transactions}[0]{clauses}[0][1] = 'forged_guard';
        } elsif ($self->{mutation} eq 'declaration') {
            $actor->{actor_network}{instances}[0]{name} = 'forged_instance';
        } elsif ($self->{mutation} eq 'coverage') {
            delete $actor->{_atl_actor_type_resolutions}{first_node};
        } else {die 'unknown late ATL mutation'}
        return $result;
    }
}

my $json = JSON::PP->new->canonical;
my @inputs = sort glob 'docs/audits/conditional-origin-library-20261002/current-bound/*.json';
is(scalar @inputs, 24, 'complete immutable conditional producer cohort');
for my $path (@inputs) {
    my $input = $json->decode(read_file($path));
    subtest "actual use and ATL producer scopes $input->{case}{name}" => sub {
        my ($label, $documents, $directory) = documents_for($input);
        local $ENV{FSMLIB} = $directory;
        my $ordinary = FSM::Adapter::ISF::Parser->new->parse_source($documents->{$label}, $label);
        my $before = $json->encode($ordinary);
        my $authority = FSM::Test::ATLDocumentOriginAuthority->from_documents($label, $documents, [$directory]);
        my $actor = $authority->actor;
        my $proof = $authority->proof;
        is($json->encode($actor), $before, 'complete canonical ordinary actors and kinds unchanged');
        ok($authority->validate($json->decode($json->encode($actor)), $json->decode($json->encode($proof))),
            'complete independently source-bound ATL reload');
        is(scalar @{$proof->{actors}}, 5, 'root plus actual separate use and ATL library constructors');
        is_deeply([map {$_->{actor_id}} @{$proof->{uses}}], $input->{case}{reuse} ? [1,1] : [1,2],
            'actual original use producer identities retained');
        is_deeply([map {$_->{actor_id}} @{$proof->{atl}}], $input->{case}{reuse} ? [3,3] : [3,4],
            'ATL actual rebuilt producers retained separately');
        is_deeply([map {$_->{instance}} @{$proof->{atl}}], ['first_node','second_node'], 'declared static instance identities');
        for my $i (0 .. 1) {
            my $edge = $proof->{atl}[$i];
            my $producer = $proof->{actors}[$edge->{actor_id}];
            my $use = $proof->{uses}[$i];
            is_deeply($edge->{path}, ['_atl_actor_type_resolutions',$edge->{instance},'actor'], 'literal complete canonical resolved actor path');
            is($edge->{instance_ordinal}, $i, 'authored declaration ordinal');
            is($json->encode($edge->{resolution}), $json->encode($actor->{_atl_actor_type_resolutions}{$edge->{instance}}),
                'whole actual resolved metadata retained');
            is($json->encode($edge->{declaration}), $json->encode($actor->{actor_network}{instances}[$i]),
                'whole actual static declaration retained');
            is($json->encode($edge->{resolution}{actor}), $json->encode($producer->{actor}), 'complete original actor matches actual canonical clone');
            is($json->encode($edge->{ledger}), $json->encode($producer->{ledger}), 'whole explicit source ledger follows exact ATL producer');
            is($producer->{source_label}, $edge->{resolution}{library_source}, 'exact original document edge');
            is($json->encode($edge->{resolution}{actor}), $json->encode($use->{target}), 'identical whole bodies retain distinct actual producer scopes');
            isnt($edge->{actor_id}, $use->{actor_id}, 'use and ATL constructor identities do not merge');
            is($json->encode([map {$_->{width}} @{$producer->{actor}{interface}{inputs}}]), '[1,1,"3","3"]',
                'literal original complete private width kinds');
        }
        my @controls;
        for my $name (qw(actor_identity actor_kind document producer_kind producer_swap source_operation type instance path coverage scope target)) {
            my ($bad_actor, $bad_proof) = ($json->decode($before), $json->decode($json->encode($proof)));
            mutate($name,$bad_actor,$bad_proof);
            my $submitted = $json->encode([$bad_actor,$bad_proof]);
            my $accepted = eval {$authority->validate($bad_actor,$bad_proof);1};
            my $diagnostic = $@;
            ok(!$accepted,"actual ATL $name mutation refuses");
            like($diagnostic,qr/differs from authoritative document set/,'precise independent complete authentication boundary');
            is($json->encode([$bad_actor,$bad_proof]),$submitted,'complete submitted products remain detached');
            push @controls,{name=>$name,actor=>$bad_actor,proof=>$bad_proof,accepted=>$accepted?1:0,diagnostic=>$diagnostic};
        }
        my $copy = $authority->proof;
        $copy->{atl}[0]{instance} = 'changed_view';
        is($json->encode($authority->proof),$json->encode($proof),'returned proof detached');
        is($json->encode($ordinary),$before,'complete ordinary original remains untouched');
        capture($input->{case}{name}, {case=>$input->{case},baseline_source=>$input->{source},label=>$label,
            documents=>$documents,search_roots=>[$directory],ordinary=>$ordinary,instrumented=>$actor,proof=>$proof,controls=>\@controls});
    };
}
subtest 'ATL alone retains complete canonical producer scopes' => sub {
    my $input = $json->decode(read_file($inputs[0]));
    my ($label,$documents,$directory)=documents_for($input,1);
    local $ENV{FSMLIB}=$directory;
    my $ordinary=FSM::Adapter::ISF::Parser->new->parse_source($documents->{$label},$label);
    my $authority=FSM::Test::ATLDocumentOriginAuthority->from_documents($label,$documents,[$directory]);
    my $proof=$authority->proof;
    is($json->encode($authority->actor),$json->encode($ordinary),'whole ordinary ATL-only product unchanged');
    is(scalar @{$proof->{actors}},3,'root and two actual ATL-only constructors');
    is_deeply($proof->{uses},[],'no invented reusable use provenance');
    is_deeply([map {$_->{actor_id}} @{$proof->{atl}}],[1,2],'exact ATL-only export selections');
    capture('atl-only',{case=>$input->{case},label=>$label,documents=>$documents,ordinary=>$ordinary,
        instrumented=>$authority->actor,proof=>$proof});
};
subtest 'canonical late ATL changes cannot publish stale origins' => sub {
    my $input=$json->decode(read_file($inputs[0]));
    my ($label,$documents,$directory)=documents_for($input);
    local $ENV{FSMLIB}=$directory;
    my @controls;
    for my $name (qw(target declaration coverage)) {
        my $parser=FSM::Test::ATLLateOriginMutation->new;
        $parser->{mutation}=$name;
        my $actor=eval{$parser->parse_documents($label,$documents)};
        my $diagnostic=$@;
        ok(!defined($actor),"actual late ATL $name change refuses before publication");
        like($diagnostic,qr/ATL origin final (?:target or instance identity|resolved actor coverage) differs/,'precise final ATL consistency boundary');
        push @controls,{name=>$name,actor=>$actor,declined_proof=>$parser->proof,diagnostic=>$diagnostic};
    }
    capture('finalization',{case=>$input->{case},label=>$label,documents=>$documents,controls=>\@controls});
};
subtest 'unqualified source authorities and the earlier provider remain closed' => sub {
    my $input=$json->decode(read_file($inputs[0]));
    my ($label,$documents,$directory)=documents_for($input);
    ok(!eval{FSM::Test::LibraryDocumentOriginAuthority->from_documents($label,$documents,[$directory]);1},'library-only provider still refuses ATL');
    like($@,qr/ATL source authority is not qualified/,'unchanged private predecessor boundary');
    for my $source ('(actor closed (instance child of Worker))','(actor closed (imports (package pkg)))') {
        ok(!eval{FSM::Test::ATLDocumentOriginAuthority->from_documents('closed.isf',{'closed.isf'=>$source},[]);1},'unqualified external/package context refuses');
        like($@,qr/(?:unresolved external actor authority|package source authority) is not qualified/,'precise private source boundary');
    }
};
done_testing;

sub mutate {
    my($name,$actor,$proof)=@_;
    if($name eq 'actor_identity'){$actor->{actor_name}='forged_actor'}
    elsif($name eq 'actor_kind'){$actor->{interface}{inputs}[0]{width}='1'}
    elsif($name eq 'document'){$proof->{atl}[0]{resolution}{library_source}='forged.isf'}
    elsif($name eq 'producer_kind'){$proof->{atl}[0]{actor_id}="$proof->{atl}[0]{actor_id}"}
    elsif($name eq 'producer_swap'){$proof->{atl}[0]{actor_id}=1}
    elsif($name eq 'source_operation'){$proof->{atl}[0]{ledger}{catalog}[0]{operation}='forged_operation'}
    elsif($name eq 'type'){$proof->{atl}[0]{declaration}{actor_type}='lib.forged'}
    elsif($name eq 'instance'){$proof->{atl}[0]{declaration}{name}='forged_instance'}
    elsif($name eq 'path'){$proof->{atl}[0]{path}[1]='second_node'}
    elsif($name eq 'coverage'){pop @{$proof->{atl}}}
    elsif($name eq 'scope'){$proof->{atl_resolutions}[0]{exports}{worker}=1}
    elsif($name eq 'target'){$proof->{atl}[0]{resolution}{actor}{transactions}[0]{clauses}[0]=['forged_target']}
    else{die 'unknown ATL control'}
}
sub documents_for {
    my($input,$atl_only)=@_;
    my $directory=File::Spec->abs2rel(tempdir(CLEANUP=>1));
    my $label="$directory/authority-root.isf";
    my $forms=source_forms($input->{source});
    my %documents;
    for my $form(@$forms){
        if($form->[0] eq 'actor'){
            @$form=grep{!(ref($_) eq 'ARRAY' && $_->[0] eq 'use')}@$form if $atl_only;
            my $second=$input->{case}{twins}?'other_lib.worker':$input->{case}{reuse}?'lib.worker':'lib.mirror';
            push @$form,['instance','first_node','of','lib.worker'],['instance','second_node','of',$second];
            $documents{$label}=source_form($form);
        }else{
            die 'unexpected fixture root' unless $form->[0] eq 'library';
            my $path="$directory/$form->[1].isf";
            $documents{$path}=source_form($form);write_file($path,$documents{$path});
        }
    }
    return($label,\%documents,$directory);
}
sub source_forms {
    my($source)=@_;my @tokens=$source=~/\(|\)|[^\s()]+/g;my(@roots,@stack);
    for my $token(@tokens){
        if($token eq '('){my$form=[];push @{(@stack?$stack[-1]:\@roots)},$form;push @stack,$form}
        elsif($token eq ')'){die 'unmatched fixture close' unless @stack;pop @stack}
        else{die 'non-list fixture root' unless @stack;push @{$stack[-1]},$token}
    }
    die 'unclosed fixture form' if @stack;return \@roots;
}
sub source_form {die 'undefined fixture atom' unless defined $_[0];ref($_[0]) eq 'ARRAY'?'('.join(' ',map{source_form($_)}@{$_[0]}).')':$_[0]}
sub read_file {open my$f,'<:raw',$_[0] or die$!;local$/;my$s=<$f>;close$f or die$!;$s}
sub write_file {open my$f,'>:raw',$_[0] or die$!;print{$f}$_[1] or die$!;close$f or die$!}
sub capture {return unless $ENV{FSMGEN_ATL_ORIGIN_CAPTURE};write_file("$ENV{FSMGEN_ATL_ORIGIN_CAPTURE}/$_[0].json",$json->encode($_[1])."\n")}
