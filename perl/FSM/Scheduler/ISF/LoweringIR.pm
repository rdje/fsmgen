package FSM::Scheduler::ISF::LoweringIR;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use POSIX qw(log);

sub new($class, %args) { bless { debug => ($args{debug} // 0) }, $class }

sub build_module($self, $actor) {
    my %spawned = $self->_collect_spawn_refs($actor);

    my %child_irs;
    for my $cname (keys %spawned) {
        my ($ct) = grep { $_->{name} eq $cname } @{$actor->{transactions}};
        next unless $ct;
        $child_irs{$cname} = $self->_build_child_ir($ct, $actor, $cname);
    }

    my $parent_ir = $self->_build_parent_ir($actor, \%spawned);
    $parent_ir->{children} = \%child_irs;
    return $parent_ir;
}

# --- Child IR (separate module) ---

sub _build_child_ir($self, $tx, $actor, $cname) {
    my ($states, $ctrs, $dts) = $self->_build_transaction($tx, $actor, 0);
    $states = [@$states]; $ctrs = { %$ctrs }; $dts = [@$dts];

    my $ports = $self->_build_ports($actor);
    {
        my %have = map { $_->{name} => 1 } @$ports;
        push @$ports, { name => 'start',      direction => 'input',  width => 1 } unless $have{start};
        push @$ports, { name => 'done',       direction => 'output', width => 1 } unless $have{done};
        push @$ports, { name => 'last_error',  direction => 'output', width => 1 } unless $have{last_error};
    }

    my $ir = {
        actor_name => $cname,
        clock      => $actor->{clock},
        reset      => $actor->{reset},
        watchdog   => $actor->{watchdog},
        ports      => $ports,
        states     => $states,
        dt_blocks  => $dts,
        counters   => $ctrs,
        children   => {},
    };

    # Inject entry state if missing (spawn targets need start handshake)
    if (!grep { $_->{kind} eq 'entry' } @{$ir->{states}}) {
        unshift @{$ir->{states}}, {
            name        => "${cname}_idle_0",
            kind        => 'entry',
            guard       => { port => 'start' },
            assignments => [],
            transitions => [],
        };
        # Link idle -> first state
        $ir->{states}[0]{transitions} = [{ target => $ir->{states}[1]{name}, condition => $ir->{states}[0]{guard} }];
    }

    my ($entry) = grep { $_->{kind} eq 'entry' } @{$ir->{states}};
    if ($entry) {
        $entry->{guard} = { port => 'start' };
        $entry->{transitions} = [];
        my ($n) = grep { $_->{kind} ne 'entry' && $_->{name} !~ /_timeout$/ } @{$ir->{states}};
        push @{$entry->{transitions}}, { target => $n->{name}, condition => $entry->{guard} } if $n;
    }
    return $ir;
}

# --- Parent IR (composition top, non-spawned transactions only) ---

sub _build_parent_ir($self, $actor, $spawned) {
    my @ports  = @{$self->_build_ports($actor)};
    my %ctrs;
    my @states;
    my @dts;
    my $ti = 0;

    for my $tx (@{$actor->{transactions}}) {
        next if $spawned->{$tx->{name}};
        my ($ss, $cs, $ds, $do, $sp) = $self->_build_transaction($tx, $actor, $ti++);
        push @states, @$ss;
        while (my ($k, $v) = each %$cs) { $ctrs{$k} = $v; }
        push @dts, @$ds;
        for my $c (@$do)  { $ctrs{"${c}_start"} = 1; $ctrs{"${c}_done"} = 1; }
        for my $s (@$sp)  { $ctrs{"$s->{instance}_start"} = 1; $ctrs{"$s->{instance}_done"} = 1; }
    }

    push @dts, $self->_build_rules($actor);
    $self->_wire_do_children(\@states, \%ctrs, $actor);

    return {
        actor_name => $actor->{actor_name},
        clock      => $actor->{clock},
        reset      => $actor->{reset},
        watchdog   => $actor->{watchdog},
        ports      => \@ports,
        states     => \@states,
        dt_blocks  => \@dts,
        counters   => \%ctrs,
        children   => {},
    };
}

sub _collect_spawn_refs($self, $actor) {
    my %s;
    for my $tx (@{$actor->{transactions}}) {
        for my $c (@{$tx->{clauses}}) {
            next unless ref($c) eq 'ARRAY' && $c->[0] eq 'spawn';
            $s{$c->[1]} = 1;
        }
    }
    return %s;
}

sub _build_ports($self, $actor) {
    my @p;
    for my $i (@{$actor->{interface}{inputs}})  { push @p, { name => $i->{name}, direction => 'input',  width => $i->{width} // 1 }; }
    for my $o (@{$actor->{interface}{outputs}}) { push @p, { name => $o->{name}, direction => 'output', width => $o->{width} // 1 }; }
    return \@p;
}

# --- Transaction → IR states ---
sub _build_transaction($self, $tx, $actor, $txi) {
    my $tn  = $tx->{name};
    my $wd  = $actor->{watchdog};
    my @st; my %ct; my @dt; my @ps; my @doc; my @spc; my @dps;
    my $si  = 0; my $ha = 0; my $wdc; my $lat;

    for my $cl (@{$tx->{clauses}}) {
        next unless ref($cl) eq 'ARRAY';
        my $k = $cl->[0];
        if    ($k eq 'on')       { push @st, _ir_on($cl, $tn, $si++); }
        elsif ($k eq 'drive')    { push @st, _ir_drive($cl, $tn, [splice @ps], $si++); }
        elsif ($k eq 'await')    { $ha=1; $wdc="${tn}_wd"; push @st, _ir_await($cl, $tn, $si++, $wd); }
        elsif ($k eq 'sample')   { push @ps, $cl; }
        elsif ($k eq 'complete') { push @st, _ir_complete($cl, $tn, $si++); }
        elsif ($k eq 'repeat')   { my ($rs,$rc) = _ir_repeat($cl,$tn,\$si,\@ps,$wd); push @st,@$rs; $ct{$rc}=8; }
        elsif ($k eq 'latency')  { $lat = _parse_latency($cl); }
        elsif ($k eq 'do')       { push @doc, $cl->[1]; push @st, _ir_do($cl,$tn,$si++); }
        elsif ($k eq 'spawn')    { push @spc, { child => $cl->[1], instance => $cl->[3] || "${tn}_${si}" }; push @dps, "$spc[-1]{instance}_done"; push @st, _ir_spawn($cl,$tn,$si++); }
        elsif ($k eq 'await_all') { push @st, _ir_sync_all($tn,$si++,\@dps); @dps = (); }
        elsif ($k eq 'await_any') { push @st, _ir_sync_any($tn,$si++,\@dps); @dps = (); }
    }

    if (@ps) { push @st, _ir_sample_state($tn, \@ps, $si++); }

    # Watchdog
    if ($ha && $wdc) {
        my $lim = $wd // 65536;
        $ct{$wdc} = int(log($lim)/log(2)) + 1;
        _inj_watchdog(\@st, $tn, $wdc, $lim, \%ct);
    }

    # Latency
    if ($lat) {
        my ($cc,$inc,$err,$cdt) = _inj_latency(\@st, $tn, $lat, $ha, \%ct);
        $ct{$cc} = int(log($lat->{max}//256)/log(2)) + 1;
        $ct{$inc} = 1; $ct{$err} = 1;
        push @dt, $cdt;
    }

    _link_states(\@st, $tn);
    $ct{can_accept} = 1;
    for my $s (@st) { next unless $s->{kind} eq 'entry'; unshift @{$s->{assignments}}, { lhs => 'can_accept', rhs => 1, op => '=' }; }
    return (\@st, \%ct, \@dt, \@doc, \@spc);
}

# --- Individual clause → IR ---
sub _ir_on      { my ($cl,$tn,$i)=@_; my $e=$cl->[1]; my @s; for my $j(2..$#$cl){my $x=$cl->[$j]; next unless ref($x)eq'ARRAY'&&$x->[0]eq'sample'; push @s,{port=>$x->[1],as_name=>$x->[3]}} my $guard=!ref($e) ? {port=>$e} : {expr=>$e}; {name=>"${tn}_idle_$i",kind=>'entry',guard=>$guard,samples=>\@s,assignments=>[],transitions=>[]} }
sub _ir_drive   { my ($cl,$tn,$ps,$i)=@_; my @a; for(@$ps){push @a,{lhs=>$_->[3],rhs=>$_->[1],op=>'<='}} for my $j(2..$#$cl){my$x=$cl->[$j];next unless ref($x)eq'ARRAY'&&@$x>=2;push @a,{lhs=>$x->[0],rhs=>$x->[1],op=>'='}} {name=>"${tn}_drive_$i",kind=>'sequential',assignments=>\@a,transitions=>[]} }
sub _ir_await   { my ($cl,$tn,$i,$wd)=@_; {name=>"${tn}_await_$i",kind=>'await',assignments=>[],transitions=>[],guard=>{port=>$cl->[1]},watchdog=>{name=>"${tn}_wd",limit=>$wd//65536}} }
sub _ir_complete{ my ($cl,$tn,$i)=@_; {name=>"${tn}_done_$i",kind=>'terminal',assignments=>[{lhs=>$cl->[1],rhs=>1,op=>'='}],transitions=>[]} }
sub _ir_sample_state { my ($tn,$ps,$i)=@_; my @a; for(@$ps){push @a,{lhs=>$_->[3],rhs=>$_->[1],op=>'<='}} {name=>"${tn}_sample_$i",kind=>'sequential',assignments=>\@a,transitions=>[]} }
sub _ir_placeholder{ my ($cl,$tn,$i)=@_; {name=>"${tn}_$cl->[0]_$i",kind=>'sequential',assignments=>[],transitions=>[]} }
sub _ir_do       { my ($cl,$tn,$i)=@_; my $c=$cl->[1]; {name=>"${tn}_do_$i",kind=>'await',assignments=>[{lhs=>"${c}_start",rhs=>1,op=>'='}],transitions=>[],guard=>{port=>"${c}_done"}} }
sub _ir_spawn    { my ($cl,$tn,$i)=@_; my $inst=$cl->[3]||"${tn}_$i"; {name=>"${tn}_spawn_$i",kind=>'sequential',assignments=>[{lhs=>"${inst}_start",rhs=>1,op=>'='}],transitions=>[]} }
sub _ir_sync_all { my ($tn,$i,$dps)=@_; {name=>"${tn}_await_all_$i",kind=>'sync_all',assignments=>[],transitions=>[],done_ports=>[@$dps]} }
sub _ir_sync_any { my ($tn,$i,$dps)=@_; {name=>"${tn}_await_any_$i",kind=>'sync_any',assignments=>[],transitions=>[],done_ports=>[@$dps]} }

sub _ir_repeat {
    my ($cl,$tn,$ir,$ps,$wd)=@_; my $ctr="${tn}_cnt"; my @s; my @lp;
    push @s, {name=>"${tn}_repeat_init_".$$ir++,kind=>'sequential',assignments=>[{lhs=>$ctr,rhs=>$cl->[1],op=>'<='}],transitions=>[]};
    for my $bc(@{$cl}[2..$#$cl]){next unless ref($bc)eq'ARRAY';my $bk=$bc->[0];
        if($bk eq'drive'){push @s,_ir_drive($bc,$tn,[splice @lp],$$ir++)}
        elsif($bk eq'await'){push @s,_ir_await($bc,$tn,$$ir++,$wd)}
        elsif($bk eq'sample'){push @lp,$bc}}
    if(@lp){push @s,_ir_sample_state($tn,\@lp,$$ir++)}
    my $fb=$s[0]{name};
    push @s, {name=>"${tn}_repeat_check_".$$ir++,kind=>'repeat_check',assignments=>[{lhs=>$ctr,rhs=>"(- $ctr 1)",op=>'<-'}],transitions=>[],loop_target=>$fb,counter=>$ctr};
    return (\@s,$ctr);
}

# --- Post-processing ---
sub _link_states {
    my ($st,$tn)=@_; return unless @$st; my $e=$st->[0]{name};
    for my $i(0..$#$st){my $s=$st->[$i];my $n=$i<$#$st?$st->[$i+1]{name}:undef;
        if($s->{kind}eq'entry'&&$n){push @{$s->{transitions}},{target=>$n,condition=>$s->{guard}}}
        elsif($s->{kind}eq'await'&&$n){push @{$s->{transitions}},{target=>$n,condition=>$s->{guard}};push @{$s->{transitions}},{target=>"${tn}_timeout",condition=>{signal=>$s->{watchdog}{name},op=>'=',value=>0}}}
        elsif($s->{kind}eq'repeat_check'){push @{$s->{transitions}},{target=>$s->{loop_target},condition=>{signal=>$s->{counter},op=>'!=',value=>0}};push @{$s->{transitions}},{target=>$n,condition=>{signal=>$s->{counter},op=>'=',value=>0}}if$n}
        elsif($s->{kind}eq'sequential'&&$n){push @{$s->{transitions}},{target=>$n}}
        elsif($s->{kind}eq'sync_all'&&$n){push @{$s->{transitions}},{target=>$n}}
        elsif($s->{kind}eq'sync_any'&&$n){push @{$s->{transitions}},{target=>$n}}
        elsif($s->{kind}eq'terminal'){push @{$s->{transitions}},{target=>$e}}}
}

sub _inj_watchdog {
    my ($st,$tn,$wn,$lim,$ctrs)=@_;
    $ctrs->{last_error} = 1;
    unshift @{$st->[0]{assignments}},{lhs=>$wn,rhs=>"(- $lim 1)",op=>'<='};
    push @$st,{name=>"${tn}_timeout",kind=>'terminal',assignments=>[{lhs=>'done',rhs=>1,op=>'='},{lhs=>'last_error',rhs=>1,op=>'='}],transitions=>[]};
}

sub _inj_latency {
    my ($st,$tn,$lat,$ha,$ctrs)=@_;
    $ctrs->{last_error} = 1; my $cc="${tn}_cc";my $inc="${tn}_inc";my $err="${tn}_lerr";my $min=$lat->{min}//1;my $max=$lat->{max}//256;
    unshift @{$st->[0]{assignments}},{lhs=>$cc,rhs=>0,op=>'<-'};
    for my $s(@$st){next if $s->{kind}eq'entry'||$s->{kind}eq'terminal'||$s->{name}=~/_timeout$/;unshift @{$s->{assignments}},{lhs=>$inc,rhs=>1,op=>'='}}
    my($done)=grep{$_->{kind}eq'terminal'&&$_->{name}!~/_timeout$/}@$st;
    if($done){push @{$done->{assignments}},{lhs=>$err,rhs=>1,op=>'=',guard=>{signal=>$cc,op=>'<',value=>$min}}}
    if(!$ha&&$max){my $mc="${tn}_max_chk";push @$st,{name=>$mc,kind=>'sequential',assignments=>[],transitions=>[{target=>"${tn}_timeout",condition=>{signal=>$cc,op=>'=',value=>$max}}]};
        push @$st,{name=>"${tn}_timeout",kind=>'terminal',assignments=>[{lhs=>$err,rhs=>1,op=>'='},{lhs=>'done',rhs=>1,op=>'='},{lhs=>'last_error',rhs=>1,op=>'='}],transitions=>[]}}
    my $dt={name=>"${tn}_cc_inc",kind=>'latency_counter',assignments=>[{lhs=>$cc,rhs=>"(+ $cc 1)",op=>'<-',guard=>{port=>$inc}}]};
    return ($cc,$inc,$err,$dt);
}

sub _build_rules {
    my ($self,$actor)=@_; my @d;
    for my $r(@{$actor->{rules}||[]}){my $c=$self->_rule_cond($r->{when});my @a;
        for my $ac(@{$r->{actions}}){next unless ref($ac)eq'ARRAY';my$a0=$ac->[0];
            if($a0 eq'trigger'){push @a,{lhs=>"$ac->[1]_start",rhs=>1,op=>'=',guard=>$c}}
            elsif($a0 eq'priority'){}
            else{push @a,{lhs=>$a0,rhs=>$ac->[1],op=>'=',guard=>$c}}}
        push @d,{name=>$r->{name},kind=>'rule',assignments=>\@a}}
    return @d;
}
sub _rule_cond { my($self,$w)=@_; return {port=>'1'} unless $w&&ref($w)eq'ARRAY'&&@$w>=2; {port=>$w->[1]} }
sub _parse_latency { my($self,$cl)=@_; my %r; for my $i(1..$#$cl){my $x=$cl->[$i];next unless ref($x)eq'ARRAY'&&@$x>=2;$r{$x->[0]}=$x->[1] if$x->[0]eq'min'||$x->[0]eq'max'}; \%r }

sub _wire_do_children {
    my ($self,$st,$ctrs,$actor)=@_;
    my %ctx = map { $_->{name} => 1 } @{$actor->{transactions}};
    my %need;
    for my $tx(@{$actor->{transactions}}){for my $cl(@{$tx->{clauses}}){next unless ref($cl)eq'ARRAY'&&$cl->[0]eq'do';$need{$cl->[1]}=1 if$ctx{$cl->[1]}}}
    for my $c(keys %need){my $s="${c}_start";my $d="${c}_done";
        my($en)=grep{$_->{name}=~/^${c}_idle_/}@$st;if($en){$en->{guard}={port=>$s};$en->{transitions}=[];my($nx)=grep{$_->{name}=~/^${c}_drive_/}@$st;push @{$en->{transitions}},{target=>$nx->{name},condition=>$en->{guard}}if$nx}
        my($tm)=grep{$_->{name}=~/^${c}_(?:done|complete)_/&&$_->{kind}eq'terminal'}@$st;unshift @{$tm->{assignments}},{lhs=>$d,rhs=>1,op=>'='}if$tm}
}

1;
