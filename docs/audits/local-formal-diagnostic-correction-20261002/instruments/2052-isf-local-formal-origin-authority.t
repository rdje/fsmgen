use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Carp qw(confess);
use File::Path qw(make_path);
use FSM::Adapter::ISF::Parser;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Test::LocalFormalOriginAuthority;

my $json = JSON::PP->new->canonical;
my $capture = $ENV{FSMGEN_LOCAL_FORMAL_ORIGIN_CAPTURE};
my $class = $ENV{FSMGEN_LOCAL_FORMAL_ORIGIN_CLASS} || 'FSM::Test::LocalFormalOriginAuthority';
my $header = '(actor formal_origin (clock clk) (reset rst_n)'
    . ' (interface (input start) (input allow) (input payload (width 3))'
    . ' (input other (width 3)) (output result (width 3)) (output done)) ';
my $ports = '(ports (input allow) (input payload (width 3)) (input other (width 3)) (output result (width 3)))';
my ($a, $p, $o, $r) = map {"isf_port_main_$_"} qw(allow payload other result);
my $set = ['set', $r, $p];
my @cases = (
    ['select', '(select result allow payload other)',
        [['when',$a,$set],['when',['!',$a],['set',$r,$o]]], ['select','select']],
    ['min', '(min result payload other)',
        [['when',['<=',$p,$o],$set],['when',['!',['<=',$p,$o]],['set',$r,$o]]], ['min','min']],
    ['max', '(max result payload other)',
        [['when',['>=',$p,$o],$set],['when',['!',['>=',$p,$o]],['set',$r,$o]]], ['max','max']],
    ['cond', '(cond (allow (set result payload)) (else (set result other)))',
        [['when',$a,$set],['when',['!',$a],['set',$r,$o]]], ['cond','cond']],
    ['when-bit', '(when-bit payload 1 (set result other))',
        [['when',['!=',['&',$p,"3'd2"],"3'd0"],['set',$r,$o]]], ['when-bit']],
    ['unless-bit', '(unless-bit payload 1 (set result other))',
        [['when',['==',['&',$p,"3'd2"],"3'd0"],['set',$r,$o]]], ['unless-bit']],
    ['when-field', '(when-field payload (bits 2 1) 1 (set result other))',
        [['when',['==',['&',$p,"3'd6"],"3'd2"],['set',$r,$o]]], ['when-field']],
    ['unless-field', '(unless-field payload (bits 2 1) 1 (set result other))',
        [['when',['!=',['&',$p,"3'd6"],"3'd2"],['set',$r,$o]]], ['unless-field']],
    ['authored', '(when allow (set result payload)) (when (! allow) (set result other))',
        [['when',$a,$set],['when',['!',$a],['set',$r,$o]]], ['when','when']],
    ['nested', '(when allow (select result allow payload other))',
        [['when',$a,['when',$a,$set],['when',['!',$a],['set',$r,$o]]]], ['when','select','select']],
    ['local', '(sample payload as captured) (when captured (set result other))',
        [['sample',$p,'as','captured'],['when','captured',['set',$r,$o]]], ['when']],
);
my %products;
for my $case (@cases) {
    my ($name,$body,$expected,$operations) = @$case;
    my $source = $header . "(transaction main $ports (on start) $body (complete done)))";
    subtest "actual formal origin $name" => sub {
        $products{$name} = qualify($name, $source,
            [['on','start'],@$expected,['complete','done']], $operations);
    };
}

subtest 'equal physical actors do not authorize a different original operation' => sub {
    is($json->encode($products{select}{context}), $json->encode($products{authored}{context}),
        'whole prepared/physical actor/plan products are identical');
    isnt($json->encode($products{select}{proof}), $json->encode($products{authored}{proof}),
        'original operations and source/catalog identities remain different');
    my $auth = $class->from_source($products{select}{source}, 'select.isf');
    refuses(sub {$auth->validate($products{authored}{context},$products{authored}{proof})},
        qr/proof differs from authoritative source/, 'equal-body origin transplant');
};

subtest 'sibling formal ownership is explicit even with equal source spelling' => sub {
    my $source = $header
        . "(transaction main $ports (on start) (select result allow payload other) (complete done))"
        . "(transaction sibling $ports (on start) (select result allow payload other) (complete done)))";
    my $auth = $class->from_source($source, 'siblings.isf');
    my ($context,$proof) = ($auth->context,$auth->proof);
    ordinary($source,$context);
    is_deeply([map {$_->{transaction}} @{$proof->{entries}}], [qw(main main sibling sibling)],
        'actual transaction input reference selects each lexical owner');
    is_deeply($context->{actor}{transactions}[1]{clauses},
        [['on','start'],['when','isf_port_sibling_allow',['set','isf_port_sibling_result','isf_port_sibling_payload']],
            ['when',['!','isf_port_sibling_allow'],['set','isf_port_sibling_result','isf_port_sibling_other']],['complete','done']],
        'literal sibling physical clauses use only sibling endpoints');
    capture('siblings',{source=>$source,context=>$context,proof=>$proof});
};

subtest 'actual nested inline calls retain the original producer and call frames' => sub {
    my $source = $header
        . '(proc inner (params (c)) (select result c payload other))'
        . '(proc outer (params (c)) (call inner c))'
        . "(transaction main $ports (on start) (call outer allow) (complete done)))";
    my $product = qualify('calls',$source,
        [['on','start'],['when',$a,$set],['when',['!',$a],['set',$r,$o]],['complete','done']], ['select','select']);
    is_deeply([map {[map {$_->{procedure}} @{$_->{origin}{calls}}]} @{$product->{proof}{entries}}],
        [[qw(outer inner)],[qw(outer inner)]], 'literal nested call association remains ordered');
};

subtest 'first authored activation and macro sample conserve existing behavior' => sub {
    for my $body ('(when allow (sample payload as captured))', '(when-bit payload 1 (sample payload as captured))') {
        my $name = $body =~ /when-bit/ ? 'first_macro_sample' : 'first_authored_sample';
        my $guard = $body =~ /when-bit/ ? ['!=',['&',$p,"3'd2"],"3'd0"] : $a;
        my $source = $header . "(transaction main $ports $body (complete done)))";
        qualify($name,$source,[['when',$guard,['sample',$p,'as','captured']],['complete','done']],
            [$body =~ /when-bit/ ? 'when-bit' : 'when']);
    }
};

subtest 'first assignment and inline cond keep exact canonical declines' => sub {
    for my $body ('(select result allow payload other)', '(call choose allow)') {
        my $proc = $body =~ /call/ ? '(proc choose (params (c)) (cond (c (set result payload)) (else (set result other))))' : '';
        my $source = $header . $proc . "(transaction main $ports $body (complete done)))";
        my $actor = FSM::Adapter::ISF::Parser->new->parse_source($source,'decline.isf');
        my $scheduler = FSM::Scheduler::ISF->new;
        my $canonical = eval {FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir},$actor);1};
        my $error = $@;
        ok(!$canonical, 'existing real formal preparation declines');
        my $observed = eval {$class->from_source($source,'decline.isf');1};
        my $observed_error = $@;
        ok(!$observed, 'private authority cannot broaden existing admission');
        if ($body =~ /call/) {
            like($observed_error,qr/residual normalization is not qualified/,'unresolved producer remains explicit');
        } else {
            is(first_line($observed_error),first_line($error),'exact canonical diagnostic conserved');
        }
        capture($body =~ /call/ ? 'decline_cond' : 'decline_first',
            {source=>$source,actor=>$actor,canonical_error=>$error,observed_error=>$observed_error});
    }
};

subtest 'actual missing clone association fails before a proof is frozen' => sub {
    refuses(sub {FSM::Test::LocalFormalOriginAuthority::DropClone->from_source($products{select}{source},'select.isf')},
        qr/conditional clone association missing/, 'actual clone callback lost');
    refuses(sub {FSM::Test::LocalFormalOriginAuthority::DropStorable->from_source($products{select}{source},'select.isf')},
        qr/conditional clone association missing/, 'actual Storable callback lost');
};

subtest 'unqualified producer scopes remain explicitly closed' => sub {
    my $imports = '(library lib (actor worker (transaction run (wait 1))))'
        . $header . '(imports (library lib as imported))'
        . "(transaction main $ports (on start) (select result allow payload other) (complete done)))";
    refuses(sub {$class->from_source($imports,'imports.isf')},
        qr/imported source authority is not qualified/,'imported producer boundary');
    my $network = $header . '(instance remote of external_worker)'
        . "(transaction main $ports (on start) (select result allow payload other) (complete done)))";
    refuses(sub {$class->from_source($network,'network.isf')},
        qr/reusable\/network scope is not qualified/,'actor network boundary');
    my $generated = $header . '(transaction worker (params (MODE 1)) (wait 1))'
        . "(transaction main $ports (on start) (do worker (params (MODE 1))) (select result allow payload other) (complete done)))";
    refuses(sub {$class->from_source($generated,'generated.isf')},
        qr/generated specialization is not qualified/,'generated transaction boundary');
    my $domain = '(actor domains (clock-domains (domain core (clock clk) :default))'
        . '(interface (input start) (input allow) (input payload (width 3))'
        . ' (input other (width 3)) (output result (width 3)) (output done))'
        . "(transaction main $ports (on start) (select result allow payload other) (complete done)))";
    refuses(sub {$class->from_source($domain,'domain.isf')},
        qr/domain scope is not qualified/,'domain constructor boundary');
    my $plain = $header . '(transaction main (on start) (select result allow payload other) (complete done)))';
    refuses(sub {$class->from_source($plain,'plain.isf')},
        qr/requires an unprojected direct formal/,'no formal preparation boundary');
};

subtest 'caller regex text cannot authenticate an unrelated Carp diagnostic' => sub {
    my $error = unrelated_refusal(qr/expected_refusal_marker/);
    like($error,qr/expected_refusal_marker/,'actual Carp stack contains caller regex text');
    is(first_line($error),'unrelated failure','literal actual first diagnostic line');
    ok(!diagnostic_matches($error,qr/expected_refusal_marker/),
        'first-line matcher rejects the echoed caller expectation');
    capture('diagnostic_echo',{error=>$error,expected=>'expected_refusal_marker',
        matched=>diagnostic_matches($error,qr/expected_refusal_marker/)?1:0});
};
done_testing;

sub qualify {
    my ($name,$source,$clauses,$operations) = @_;
    my $auth = $class->from_source($source,"$name.isf");
    my ($context,$proof) = ($auth->context,$auth->proof);
    ordinary($source,$context);
    is($json->encode($context->{actor}{transactions}[0]{clauses}),$json->encode($clauses),
        'independently written whole physical clause oracle including primitive kinds');
    is_deeply([map {$proof->{source_ledger}{catalog}[$_->{origin}{catalog_id}]{operation}} @{$proof->{entries}}],
        $operations,'literal source operation identity');
    for my $entry (@{$proof->{entries}}) {
        is_deeply($entry->{lineage},[qw(lowering_ir storable)],'actual selected LoweringIR then Storable clone lineage');
        is_deeply($entry->{formals}{payload}{identity},['transaction_port','formal_origin','main','payload'],
            'literal original formal identity remains explicit');
        is($entry->{formals}{payload}{physical_name},$p,'literal private formal endpoint');
        is_deeply($entry->{formals}{result}{identity},['transaction_port','formal_origin','main','result'],
            'literal original output formal identity');
        is($entry->{formals}{result}{direction},'output','output role retained');
    }
    ok($auth->validate(clone($context),clone($proof)), 'complete opaque reconstruction authenticates');
    my @controls;
    for my $kind (qw(origin path scope target coverage scalar_kind plan extra)) {
        my ($bad_context,$bad_proof) = (clone($context),clone($proof));
        if ($kind eq 'origin') {$bad_proof->{entries}[0]{origin}{catalog_id}=999}
        elsif ($kind eq 'path') {$bad_proof->{entries}[0]{physical_path}[1]=999}
        elsif ($kind eq 'scope') {$bad_proof->{entries}[0]{transaction}='sibling'}
        elsif ($kind eq 'target') {$bad_proof->{entries}[0]{after}[1]='forged'}
        elsif ($kind eq 'coverage') {pop @{$bad_proof->{entries}}}
        elsif ($kind eq 'scalar_kind') {$bad_proof->{entries}[0]{source_entry}="0"}
        elsif ($kind eq 'plan') {$bad_context->{plan}{formals}{main}{payload}{identity}[2]='sibling'}
        elsif ($kind eq 'extra') {$bad_proof->{unknown}=1}
        my $before=$json->encode([$bad_context,$bad_proof]);
        my $accepted=eval {$auth->validate($bad_context,$bad_proof);1};
        my $error=$@;
        ok(!$accepted,"actual $kind forgery refused");
        like(first_line($error),qr/differs from authoritative source/,'independent complete source authority');
        is($json->encode([$bad_context,$bad_proof]),$before,'validation leaves submitted kinds untouched');
        push @controls,{kind=>$kind,context=>$bad_context,proof=>$bad_proof,error=>$error,accepted=>$accepted?1:0};
    }
    my ($view,$proof_view)=($auth->context,$auth->proof);
    $view->{actor}{transactions}[0]{name}='forged';
    $proof_view->{entries}[0]{transaction}='forged';
    is($json->encode([$auth->context,$auth->proof]),$json->encode([$context,$proof]),'returned complete views detach');
    my $product={source=>$source,context=>$context,proof=>$proof,controls=>\@controls,
        literal_clauses=>$clauses,literal_operations=>$operations};
    capture($name,$product);
    return $product;
}
sub ordinary {
    my ($source,$observed) = @_;
    my $actor=FSM::Adapter::ISF::Parser->new->parse_source($source,'ordinary.isf');
    my $before=$json->encode($actor);
    my $scheduler=FSM::Scheduler::ISF->new;
    my $ordinary=FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir},$actor);
    is($json->encode($observed),$json->encode($ordinary),'complete ordinary preparation/physical actor/plan and kinds conserved');
    is($json->encode($actor),$before,'complete canonical caller remains unchanged');
}
sub refuses {
    my ($operation,$pattern,$name)=@_;
    my $accepted=eval {$operation->();1};
    my $error=$@;
    ok(!$accepted,$name);
    ok(diagnostic_matches($error,$pattern),'exact first-line refusal mechanism');
    capture($name,{accepted=>$accepted?1:0,error=>$error});
}
sub clone {$json->decode($json->encode($_[0]))}
sub first_line {$_[0] =~ /\A([^\n]*)/ ? $1 : ''}
sub diagnostic_matches {
    my ($error,$pattern)=@_;
    my $subject=$ENV{FSMGEN_FORMAL_DIAGNOSTIC_FULL_STACK} ? $error : first_line($error);
    return $subject =~ $pattern ? 1 : 0;
}
sub unrelated_refusal {
    my ($pattern)=@_;
    eval {confess "unrelated failure\n"};
    return $@;
}
sub capture {
    my ($name,$product)=@_;
    return unless defined $capture;
    $name =~ s/[^a-zA-Z0-9_-]/_/g;
    make_path($capture);
    open my $fh,'>',"$capture/$name.json" or die $!;
    print {$fh} $json->encode($product),"\n";
    close $fh or die $!;
}

package FSM::Test::LocalFormalOriginAuthority::DropClone;
use parent 'FSM::Test::LocalFormalOriginAuthority';
sub _carry_clone {
    my ($self,$old,$new,$stage)=@_;
    my $association=$self->_association($old);
    return if $association && exists $association->{entry};
    return $self->SUPER::_carry_clone($old,$new,$stage);
}

package FSM::Test::LocalFormalOriginAuthority::Bypass;
use parent 'FSM::Test::LocalFormalOriginAuthority';
sub _authenticate {return 1}

package FSM::Test::LocalFormalOriginAuthority::DropStorable;
use parent 'FSM::Test::LocalFormalOriginAuthority';
sub _carry_clone {
    my ($self,$old,$new,$stage)=@_;
    my $association=$self->_association($old);
    return if $stage eq 'storable' && $association && exists $association->{entry};
    return $self->SUPER::_carry_clone($old,$new,$stage);
}
