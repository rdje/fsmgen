package FSM::Scheduler::ISF::LoweringIR;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use POSIX qw(log);
use Carp qw(confess);

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
    $self->_build_drive_dts($actor, \@dts, \%ctrs);

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

sub _build_signal_width_map {
    my ($actor, $tx) = @_;
    my %widths;
    for my $i (@{$actor->{interface}{inputs}})  { $widths{$i->{name}} = $i->{width} // 1; }
    for my $o (@{$actor->{interface}{outputs}}) { $widths{$o->{name}} = $o->{width} // 1; }
    _collect_sample_widths($tx->{clauses}, \%widths);
    _collect_data_widths($tx->{clauses}, \%widths);
    return \%widths;
}

sub _collect_sample_widths {
    my ($node, $widths) = @_;
    return unless ref($node) eq 'ARRAY';

    if (@$node >= 4 && $node->[0] eq 'sample' && $node->[2] eq 'as') {
        my ($source, $alias) = ($node->[1], $node->[3]);
        $widths->{$alias} = $widths->{$source} if exists $widths->{$source};
    }

    for my $child (@$node) {
        _collect_sample_widths($child, $widths) if ref($child) eq 'ARRAY';
    }
}

sub _collect_data_widths {
    my ($node, $widths) = @_;
    return unless ref($node) eq 'ARRAY';

    if (@$node >= 4 && $node->[0] eq 'assemble') {
        my ($target, @parts) = _parse_assemble_clause($node);
        my $total = 0;
        for my $part (@parts) {
            return unless exists $widths->{$part};
            $total += $widths->{$part};
        }
        $widths->{$target} = $total if $total > 0;
    }

    for my $child (@$node) {
        _collect_data_widths($child, $widths) if ref($child) eq 'ARRAY';
    }
}

sub _as_index {
    my ($cl, $start) = @_;
    for my $idx ($start .. $#$cl) {
        return $idx if defined $cl->[$idx] && !ref($cl->[$idx]) && $cl->[$idx] eq 'as';
    }
    return undef;
}

sub _parse_assemble_clause {
    my ($cl) = @_;
    my $as_idx = _as_index($cl, 2);
    confess "assemble requires '(assemble part... as target)'\n"
        unless defined $as_idx && $as_idx > 1 && $as_idx == $#$cl - 1;

    my @parts = @{$cl}[1 .. $as_idx - 1];
    my $target = $cl->[$as_idx + 1];
    confess "assemble target must be a scalar name\n" if ref($target);
    return ($target, @parts);
}

sub _parse_extract_clause {
    my ($cl) = @_;
    confess "extract requires '(extract word as field...)'\n"
        unless @$cl >= 4 && defined $cl->[2] && !ref($cl->[2]) && $cl->[2] eq 'as';

    my $word = $cl->[1];
    my @fields = @{$cl}[3 .. $#$cl];
    confess "extract word must be a scalar name\n" if ref($word);
    confess "extract requires at least one scalar field\n" unless @fields;
    for my $field (@fields) {
        confess "extract field must be a scalar name\n" if ref($field);
    }
    return ($word, @fields);
}

sub _register_counter_width {
    my ($counters, $name, $width) = @_;
    $width = 8 unless defined($width) && $width > 0;
    $counters->{$name} = $width
        if !defined($counters->{$name}) || $counters->{$name} < $width;
}

sub _repeat_count_width {
    my ($count, $widths) = @_;
    return 8 if ref($count);
    return $widths->{$count}
        if defined($count) && exists($widths->{$count}) && $widths->{$count} > 0;
    if (defined($count)) {
        my $literal_width = _literal_repeat_count_width($count);
        return $literal_width if defined $literal_width;
    }
    return 8;
}

sub _literal_repeat_count_width {
    my ($count) = @_;
    return undef unless defined($count) && !ref($count) && $count =~ /\A(?:\+)?([0-9]+)\z/;

    my $limit = 0 + $1;
    my $width = 1;
    my $max_value = 1;
    while ($max_value < $limit) {
        ++$width;
        $max_value = (2 ** $width) - 1;
    }
    return $width;
}

# --- Transaction → IR states ---
sub _build_transaction($self, $tx, $actor, $txi) {
    my $tn  = $tx->{name};
    my $wd  = $actor->{watchdog};
    my $drives = $actor->{drives} || {};
    my $widths = _build_signal_width_map($actor, $tx);
    my @st; my %ct; my @dt; my @ps; my @doc; my @spc; my @dps;
    my $si  = 0; my $ha = 0; my $wdc; my $lat;

    for my $cl (@{$tx->{clauses}}) {
        next unless ref($cl) eq 'ARRAY';
        my $k = $cl->[0];
        if    ($k eq 'on')       { push @st, _ir_on($cl, $tn, $si++); }
        elsif ($k eq 'drive')    {
            if (!ref($cl->[1]) && @$cl >= 2) {
                # Call: (drive name arg1 arg2 ...)
                my $name = $cl->[1];
                confess "Transaction '$tn': drive '$name' not defined\n" unless $drives->{$name};
                push @st, _ir_named_drive_call($cl, $tn, $si++, $drives->{$name}, [splice @ps]);
            } else {
                push @st, _ir_drive($cl, $tn, [splice @ps], $si++);
            }
        }
        elsif ($k eq 'await')    { $ha=1; $wdc="${tn}_wd"; my $wd_override = _parse_await_wd($cl); push @st, _ir_await($cl, $tn, $si++, $wd_override || $wd, [splice @ps]); }
        elsif ($k eq 'sample')   { push @ps, $cl; }
        elsif ($k eq 'update')      { push @st, _ir_update($cl,$tn,$si++); }
        elsif ($k eq 'phase')       { push @st, _ir_phase($cl,$tn,$si++); }
        elsif ($k eq 'shift_left')  { push @st, _ir_shift_left($cl,$tn,$si++); }
        elsif ($k eq 'shift_right') { push @st, _ir_shift_right($cl,$tn,$si++,$widths); }
        elsif ($k eq 'assemble')    { push @st, _ir_assemble($cl,$tn,$si++); }
        elsif ($k eq 'extract')     { push @st, _ir_extract($cl,$tn,$si++,$widths); }
        elsif ($k eq 'complete') { push @st, _ir_complete($cl, $tn, $si++); }
        elsif ($k eq 'when' && !@st) { push @st, _ir_when_activation($cl,$tn,$si++); }
        elsif ($k eq 'when')     {
            my ($ws) = _expand_when($cl,$tn,\$si,\@ps,$drives,$wd);
            push @st, @$ws;
        }
        elsif ($k eq 'switch')   {
            my ($ss) = _expand_switch($cl,$tn,\$si,\@ps,$drives,$wd,$widths,\%ct);
            push @st, @$ss;
        }
        elsif ($k eq 'repeat')   { my ($rs,$rc,$rw) = _ir_repeat($cl,$tn,\$si,\@ps,$wd,$drives,$widths); push @st,@$rs; _register_counter_width(\%ct,$rc,$rw); }
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

    _merge_sequential(\@st) if 0;  # disabled — needs more work
    _link_states(\@st, $tn);
    $ct{can_accept} = 1;
    for my $s (@st) { next unless $s->{kind} eq 'entry'; unshift @{$s->{assignments}}, { lhs => 'can_accept', rhs => 1, op => '=' }; }
    return (\@st, \%ct, \@dt, \@doc, \@spc);
}

# --- Individual clause → IR ---
sub _sample_assignments {
    my ($samples) = @_;
    my @assignments;

    for my $sample (@$samples) {
        next unless ref($sample) eq 'ARRAY' && @$sample >= 4;
        next unless $sample->[0] eq 'sample' && $sample->[2] eq 'as';
        push @assignments, { lhs => $sample->[3], rhs => $sample->[1], op => '<=' };
    }

    return @assignments;
}

sub _inline_on_samples {
    my ($cl) = @_;
    my @samples;

    for my $j (2 .. $#$cl) {
        my $sample = $cl->[$j];
        next unless ref($sample) eq 'ARRAY' && $sample->[0] eq 'sample';
        push @samples, $sample;
    }

    return _sample_assignments(\@samples);
}

sub _ir_on {
    my ($cl, $tn, $i) = @_;
    my $event = $cl->[1];
    my $guard = !ref($event) ? { port => $event } : { expr => $event };
    my @assignments = map { +{ %$_, guard => $guard } } _inline_on_samples($cl);

    return {
        name        => "${tn}_idle_$i",
        kind        => 'entry',
        guard       => $guard,
        assignments => \@assignments,
        transitions => [],
    };
}

sub _ir_when_activation {
    my ($cl, $tn, $i) = @_;
    my $event = $cl->[1];
    my $guard = !ref($event) ? { port => $event } : { expr => $event };
    my @assignments = map { +{ %$_, guard => $guard } } _inline_on_samples($cl);

    return {
        name        => "${tn}_idle_$i",
        kind        => 'entry',
        guard       => $guard,
        assignments => \@assignments,
        transitions => [],
    };
}
sub _ir_data_op  { my ($op,$cl,$tn,$i,$widths)=@_; $op eq'shift_left' ? _ir_shift_left($cl,$tn,$i) : $op eq'shift_right' ? _ir_shift_right($cl,$tn,$i,$widths) : $op eq'assemble' ? _ir_assemble($cl,$tn,$i) : $op eq'extract' ? _ir_extract($cl,$tn,$i,$widths) : _ir_update($cl,$tn,$i) }
sub _ir_named_drive_call {
    my ($cl, $tn, $i, $def, $pending_samples) = @_;
    my $name = $cl->[1];
    my @params = @{$def->{params}};
    my @assignments = (_sample_assignments($pending_samples || []), { lhs => "${name}_start", rhs => 1, op => '=' });

    for my $pi (0 .. $#params) {
        my $arg = $cl->[2 + $pi];
        confess "Transaction '$tn': drive '$name' missing actual for '$params[$pi]'\n"
            unless defined $arg;
        push @assignments, { lhs => "${name}_$params[$pi]", rhs => $arg, op => '=' };
    }

    return {
        name        => "${tn}_drive_$i",
        kind        => 'sequential',
        assignments => \@assignments,
        transitions => [],
    };
}
sub _ir_drive   { my ($cl,$tn,$ps,$i)=@_; my @a; for(@$ps){push @a,{lhs=>$_->[3],rhs=>$_->[1],op=>'<='}} for my $j(2..$#$cl){my$x=$cl->[$j];next unless ref($x)eq'ARRAY'&&@$x>=2;push @a,{lhs=>$x->[0],rhs=>$x->[1],op=>'='}} {name=>"${tn}_drive_$i",kind=>'sequential',assignments=>\@a,transitions=>[]} }
sub _ir_drive_call { my ($body,$tn,$ps,$i)=@_; return undef; }
sub _ir_await {
    my ($cl, $tn, $i, $wd, $pending_samples) = @_;
    my @assignments = _sample_assignments($pending_samples || []);

    return {
        name        => "${tn}_await_$i",
        kind        => 'await',
        assignments => \@assignments,
        transitions => [],
        guard       => { port => $cl->[1] },
        watchdog    => { name => "${tn}_wd", limit => $wd // 65536 },
    };
}
sub _ir_complete{ my ($cl,$tn,$i)=@_; {name=>"${tn}_done_$i",kind=>'terminal',assignments=>[{lhs=>$cl->[1],rhs=>1,op=>'<-'}],transitions=>[]} }
sub _ir_update   { my ($cl,$tn,$i)=@_; my$rhs=join(' ',@{$cl}[2..$#$cl]); {name=>"${tn}_update_$i",kind=>'sequential',assignments=>[{lhs=>$cl->[1],rhs=>$rhs,op=>'<-'}],transitions=>[]} }
sub _ir_shift_left { my ($cl,$tn,$i)=@_; my$reg=$cl->[1];my$bit=$cl->[2]; {name=>"${tn}_shift_$i",kind=>'sequential',assignments=>[{lhs=>$reg,rhs=>"(| (<< $reg 1) $bit)",op=>'<-'}],transitions=>[]} }
sub _ir_shift_right{ my ($cl,$tn,$i,$widths)=@_; my$reg=$cl->[1];my$bit=$cl->[2];my$insert=(defined($widths->{$reg})&&$widths->{$reg}>0)?$widths->{$reg}-1:'(- WIDTH 1)'; {name=>"${tn}_shift_$i",kind=>'sequential',assignments=>[{lhs=>$reg,rhs=>"(| (>> $reg 1) (<< $bit $insert))",op=>'<-'}],transitions=>[]} }
sub _ir_assemble  { my ($cl,$tn,$i)=@_; my($var,@parts)=_parse_assemble_clause($cl);my$rhs='(concat '.join(' ',@parts).')'; {name=>"${tn}_asm_$i",kind=>'sequential',assignments=>[{lhs=>$var,rhs=>$rhs,op=>'<-'}],transitions=>[]} }
sub _ir_extract {
    my ($cl, $tn, $i, $widths) = @_;
    my ($word, @fields) = _parse_extract_clause($cl);
    my @assignments;

    my $high;
    if (defined($widths->{$word}) && $widths->{$word} > 0) {
        $high = $widths->{$word} - 1;
    } else {
        my $total = 0;
        for my $field (@fields) {
            if (!defined($widths->{$field}) || $widths->{$field} <= 0) {
                $total = undef;
                last;
            }
            $total += $widths->{$field};
        }
        $high = $total - 1 if defined $total && $total > 0;
    }

    for my $field (@fields) {
        my $rhs;
        if (defined $high && defined($widths->{$field}) && $widths->{$field} > 0) {
            my $low = $high - $widths->{$field} + 1;
            $rhs = "(slice $word $high $low)";
            $high = $low - 1;
        } else {
            $rhs = "(slice $word $field HIGH $field LOW)";
            $high = undef;
        }
        push @assignments, { lhs => $field, rhs => $rhs, op => '<=' };
    }

    return {
        name        => "${tn}_ext_$i",
        kind        => 'sequential',
        assignments => \@assignments,
        transitions => [],
    };
}
sub _ir_sample_state { my ($tn,$ps,$i)=@_; my @a; for(@$ps){push @a,{lhs=>$_->[3],rhs=>$_->[1],op=>'<='}} {name=>"${tn}_sample_$i",kind=>'sequential',assignments=>\@a,transitions=>[]} }
sub _ir_phase { my ($cl,$tn,$i)=@_; my $name=$cl->[1]; {name=>"${tn}_phase_$i",kind=>'sequential',assignments=>[],transitions=>[],phase_name=>$name} }
sub _ir_placeholder{ my ($cl,$tn,$i)=@_; {name=>"${tn}_$cl->[0]_$i",kind=>'sequential',assignments=>[],transitions=>[]} }
sub _ir_do       { my ($cl,$tn,$i)=@_; my $c=$cl->[1]; {name=>"${tn}_do_$i",kind=>'await',assignments=>[{lhs=>"${c}_start",rhs=>1,op=>'='}],transitions=>[],guard=>{port=>"${c}_done"}} }
sub _ir_spawn    { my ($cl,$tn,$i)=@_; my $inst=$cl->[3]||"${tn}_$i"; {name=>"${tn}_spawn_$i",kind=>'sequential',assignments=>[{lhs=>"${inst}_start",rhs=>1,op=>'='}],transitions=>[]} }
sub _ir_when     { my ($cl,$tn,$i)=@_; {name=>"${tn}_when_$i",kind=>'branch',condition=>$cl->[1],body_clauses=>[@{$cl}[2..$#$cl]],assignments=>[],transitions=>[]} }
sub _expand_when { my ($cl,$tn,$ir,$ps,$drives,$wd)=@_; my @s; my $bstate=_ir_when($cl,$tn,$$ir++); push @s,$bstate; my @body_states; my @lp;
    for my $bc(@{$bstate->{body_clauses}}){next unless ref($bc)eq'ARRAY';my$bk=$bc->[0];
        if($bk eq'drive'){my$n=$bc->[1];confess qq{drive $n not defined} unless !ref($n)&&$drives->{$n};push @body_states,_ir_named_drive_call($bc,$tn,$$ir++,$drives->{$n},[splice @lp])}
        elsif($bk eq'await'){push @body_states,_ir_await($bc,$tn,$$ir++,$wd,[splice @lp])}
        elsif($bk eq'sample'){push @lp,$bc}
        elsif($bk eq'complete'){push @body_states,_ir_complete($bc,$tn,$$ir++)}}
    if(@lp){push @body_states,_ir_sample_state($tn,\@lp,$$ir++)}
    if(@body_states){$bstate->{true_target}=$body_states[0]{name};push @s,@body_states}
    return (\@s);
}

sub _expand_switch { my ($cl,$tn,$ir,$ps,$drives,$wd,$widths,$counters)=@_; my $signal=$cl->[1]; my @branches; my %seen_val; my @s;
    for my $i(2..$#$cl){my$br=$cl->[$i];next unless ref($br)eq'ARRAY'&&@$br>=2;my$val=$br->[0];my@bc=@{$br}[1..$#$br];
        confess "Switch '$tn': duplicate value '$val'\n" if$seen_val{$val}++;my@body_states;my@lp;
        for my $bc2(@bc){next unless ref($bc2)eq'ARRAY';my$bk2=$bc2->[0];
            if($bk2 eq'drive'){my$n=$bc2->[1];confess qq{drive $n not defined} unless !ref($n)&&$drives->{$n};push @body_states,_ir_named_drive_call($bc2,$tn,$$ir++,$drives->{$n},[splice @lp])}
            elsif($bk2 eq'await'){push @body_states,_ir_await($bc2,$tn,$$ir++,$wd,[splice @lp])}
            elsif($bk2 eq'sample'){push @lp,$bc2}
            elsif($bk2 eq'repeat'){my($rs,$rc,$rw)=_ir_repeat($bc2,$tn,$ir,\@lp,$wd,$drives,$widths);push @body_states,@$rs;_register_counter_width($counters,$rc,$rw) if $counters}
            elsif($bk2 eq'update'||$bk2 eq'shift_left'||$bk2 eq'shift_right'||$bk2 eq'assemble'||$bk2 eq'extract'){push @body_states,_ir_data_op($bk2,$bc2,$tn,$$ir++,$widths)}
            elsif($bk2 eq'when'){my($ws)=_expand_when($bc2,$tn,$ir,\@lp,$drives,$wd);push @body_states,@$ws}}
        if(@lp||!@body_states){push @body_states,_ir_sample_state($tn,\@lp,$$ir++)if@lp;push @body_states,{name=>"${tn}_switch_${val}_" . $$ir++,kind=>'sequential',assignments=>[],transitions=>[]}unless@body_states}
        push @branches,{value=>$val,body_start=>$body_states[0]{name}};push @s,@body_states}
    my $sw_name="${tn}_switch_" . $$ir++;
    my $bstate={name=>$sw_name,kind=>'switch',signal=>$signal,branches=>\@branches,assignments=>[],transitions=>[]};
    unshift @s,$bstate; return (\@s);
}
sub _ir_sync_all { my ($tn,$i,$dps)=@_; {name=>"${tn}_await_all_$i",kind=>'sync_all',assignments=>[],transitions=>[],done_ports=>[@$dps]} }
sub _ir_sync_any { my ($tn,$i,$dps)=@_; {name=>"${tn}_await_any_$i",kind=>'sync_any',assignments=>[],transitions=>[],done_ports=>[@$dps]} }

sub _ir_repeat {
    my ($cl,$tn,$ir,$ps,$wd,$drives,$widths)=@_; my $ctr="${tn}_cnt"; my @s; my @lp;
    my $width = _repeat_count_width($cl->[1], $widths);
    push @s, {name=>"${tn}_repeat_init_".$$ir++,kind=>'sequential',assignments=>[{lhs=>$ctr,rhs=>$cl->[1],op=>'<='}],transitions=>[]};
    for my $bc(@{$cl}[2..$#$cl]){next unless ref($bc)eq'ARRAY';my $bk=$bc->[0];
        if($bk eq'drive'){my$n=$bc->[1];if(!ref($n)&&$drives->{$n}){push @s,_ir_named_drive_call($bc,$tn,$$ir++,$drives->{$n},[splice @lp])}else{push @s,_ir_drive($bc,$tn,[splice @lp],$$ir++)}}
        elsif($bk eq'await'){push @s,_ir_await($bc,$tn,$$ir++,$wd,[splice @lp])}
        elsif($bk eq'sample'){push @lp,$bc}
        elsif($bk eq'update'||$bk eq'shift_left'||$bk eq'shift_right'||$bk eq'assemble'||$bk eq'extract'){push @s,_ir_data_op($bk,$bc,$tn,$$ir++,$widths)}}
    if(@lp){push @s,_ir_sample_state($tn,\@lp,$$ir++)}
    my $fb=$s[0]{name};
    push @s, {name=>"${tn}_repeat_check_".$$ir++,kind=>'repeat_check',assignments=>[{lhs=>$ctr,rhs=>"(- $ctr 1)",op=>'<-'}],transitions=>[],loop_target=>$fb,counter=>$ctr};
    return (\@s,$ctr,$width);
}

# --- Post-processing ---
sub _link_states {
    my ($st,$tn)=@_; return unless @$st; my $e=$st->[0]{name};
    for my $i(0..$#$st){my $s=$st->[$i];my $n=$i<$#$st?$st->[$i+1]{name}:undef;
        if($s->{kind}eq'entry'&&$n){push @{$s->{transitions}},{target=>$n,condition=>$s->{guard}}}
        elsif($s->{kind}eq'await'&&$n){push @{$s->{transitions}},{target=>$n,condition=>$s->{guard}};push @{$s->{transitions}},{target=>"${tn}_timeout",condition=>{signal=>$s->{watchdog}{name},op=>'=',value=>0}}}
        elsif($s->{kind}eq'repeat_check'){push @{$s->{transitions}},{target=>$s->{loop_target},condition=>{signal=>$s->{counter},op=>'!=',value=>0}};push @{$s->{transitions}},{target=>$n,condition=>{signal=>$s->{counter},op=>'=',value=>0}}if$n}
        elsif($s->{kind}eq'sequential'&&$n){push @{$s->{transitions}},{target=>$n}}
        elsif($s->{kind}eq'switch'){my$skip=undef;for(my$j=$i+1;$j<@$st;$j++){next if$st->[$j]{name}=~/_drive_|_await_|_sample_/; $skip=$st->[$j]{name};last} push @{$s->{transitions}},{target=>$skip||$e};for my$br(@{$s->{branches}}){push @{$s->{transitions}},{target=>$br->{body_start},condition=>{signal=>$s->{signal},value=>$br->{value}}}}}
        elsif($s->{kind}eq'sync_all'&&$n){push @{$s->{transitions}},{target=>$n}}
        elsif($s->{kind}eq'sync_any'&&$n){push @{$s->{transitions}},{target=>$n}}
        elsif($s->{kind}eq'terminal'){push @{$s->{transitions}},{target=>$e}}}
}

sub _inj_watchdog {
    my ($st,$tn,$wn,$lim,$ctrs)=@_;
    $ctrs->{last_error} = 1;
    unshift @{$st->[0]{assignments}},{lhs=>$wn,rhs=>"(- $lim 1)",op=>'<='};
    push @$st,{name=>"${tn}_timeout",kind=>'terminal',assignments=>[{lhs=>'done',rhs=>1,op=>'<-'},{lhs=>'last_error',rhs=>1,op=>'<-'}],transitions=>[]};
}

sub _inj_latency {
    my ($st,$tn,$lat,$ha,$ctrs)=@_;
    $ctrs->{last_error} = 1; my $cc="${tn}_cc";my $inc="${tn}_inc";my $err="${tn}_lerr";my $min=$lat->{min}//1;my $max=$lat->{max}//256;
    unshift @{$st->[0]{assignments}},{lhs=>$cc,rhs=>0,op=>'<-'};
    for my $s(@$st){next if $s->{kind}eq'entry'||$s->{kind}eq'terminal'||$s->{name}=~/_timeout$/;unshift @{$s->{assignments}},{lhs=>$inc,rhs=>1,op=>'='}}
    my($done)=grep{$_->{kind}eq'terminal'&&$_->{name}!~/_timeout$/}@$st;
    if($done){push @{$done->{assignments}},{lhs=>$err,rhs=>1,op=>'=',guard=>{signal=>$cc,op=>'<',value=>$min}}}
    if(!$ha&&$max){my $mc="${tn}_max_chk";push @$st,{name=>$mc,kind=>'sequential',assignments=>[],transitions=>[{target=>"${tn}_timeout",condition=>{signal=>$cc,op=>'=',value=>$max}}]};
        push @$st,{name=>"${tn}_timeout",kind=>'terminal',assignments=>[{lhs=>$err,rhs=>1,op=>'='},{lhs=>'done',rhs=>1,op=>'<-'},{lhs=>'last_error',rhs=>1,op=>'<-'}],transitions=>[]}}
    my $dt={name=>"${tn}_cc_inc",kind=>'latency_counter',assignments=>[{lhs=>$cc,rhs=>"(+ $cc 1)",op=>'<-',guard=>{port=>$inc}}]};
    return ($cc,$inc,$err,$dt);
}

sub _build_rules {
    my ($self,$actor)=@_; my @d;
    for my $r(@{$actor->{rules}||[]}){my $c=$self->_rule_cond($r->{when});my @a;
        for my $ac(@{$r->{actions}}){next unless ref($ac)eq'ARRAY';my$a0=$ac->[0];
            if($a0 eq'trigger'){push @a,{lhs=>"$ac->[1]_start",rhs=>1,op=>'<-',guard=>$c}}
            elsif($a0 eq'priority'){}
            else{push @a,{lhs=>$a0,rhs=>$ac->[1],op=>'<-',guard=>$c}}}
        push @d,{name=>$r->{name},kind=>'rule',assignments=>\@a}}
    return @d;
}
sub _rule_cond { my($self,$w)=@_; return {port=>'1'} unless $w&&ref($w)eq'ARRAY'&&@$w>=2; {port=>$w->[1]} }

sub _build_drive_dts {
    my ($self, $actor, $dts, $ctrs) = @_;
    my $drives = $actor->{drives} || {};
    for my $name (keys %$drives) {
        my $def = $drives->{$name};
        my $body = $def->{body};
        my @params = @{$def->{params}};
        my @assignments;

        # Build a map: formal param -> signal name
        my %param_signal;
        for my $p (@params) {
            $param_signal{$p} = "${name}_${p}";
            # Infer width from the port this parameter drives
            my $w = 1;
            for my $pair (@$body) {
                next unless ref($pair) eq 'ARRAY' && @$pair >= 2 && $pair->[1] eq $p;
                for my $port (@{$actor->{interface}{outputs}}) {
                    $w = $port->{width} if $port->{name} eq $pair->[0];
                }
            }
            $ctrs->{$param_signal{$p}} = $w;
        }

        for my $pair (@$body) {
            next unless ref($pair) eq 'ARRAY' && @$pair >= 2;
            my $lhs = $pair->[0];
            my $rhs = $pair->[1];
            # Substitute formal params in RHS
            if (exists $param_signal{$rhs}) {
                $rhs = $param_signal{$rhs};
            }
            push @assignments, { lhs => $lhs, rhs => $rhs, op => '<-', guard => { port => "${name}_start" } };
        }
        push @$dts, { name => $name, kind => 'drive', assignments => \@assignments };
        $ctrs->{"${name}_start"} = 1;
    }
}

sub _parse_latency { my($self,$cl)=@_; my %r; for my $i(1..$#$cl){my $x=$cl->[$i];next unless ref($x)eq'ARRAY'&&@$x>=2;$r{$x->[0]}=$x->[1] if$x->[0]eq'min'||$x->[0]eq'max'}; \%r }
sub _parse_await_wd { my($cl)=@_; for my $i(2..$#$cl){my$x=$cl->[$i];return$x->[1]if ref($x)eq'ARRAY'&&$x->[0]eq'watchdog'} undef }

sub _wire_do_children {
    my ($self,$st,$ctrs,$actor)=@_;
    my %ctx = map { $_->{name} => 1 } @{$actor->{transactions}};
    my %need;
    for my $tx(@{$actor->{transactions}}){for my $cl(@{$tx->{clauses}}){next unless ref($cl)eq'ARRAY'&&$cl->[0]eq'do';$need{$cl->[1]}=1 if$ctx{$cl->[1]}}}
    for my $c(keys %need){my $s="${c}_start";my $d="${c}_done";
        my($en)=grep{$_->{name}=~/^${c}_idle_/}@$st;if($en){$en->{guard}={port=>$s};$en->{transitions}=[];my($nx)=grep{$_->{name}=~/^${c}_drive_/}@$st;push @{$en->{transitions}},{target=>$nx->{name},condition=>$en->{guard}}if$nx}
        my($tm)=grep{$_->{name}=~/^${c}_(?:done|complete)_/&&$_->{kind}eq'terminal'}@$st;unshift @{$tm->{assignments}},{lhs=>$d,rhs=>1,op=>'<-'}if$tm}
}

sub _merge_sequential {
    my ($st) = @_;
    my @merged;
    for my $s (@$st) {
        if (@merged && $merged[-1]{kind} eq 'sequential' && $s->{kind} eq 'sequential'
            && $merged[-1]{name} !~ /_repeat_check/ && $merged[-1]{name} !~ /_repeat_init/
            && $s->{name} !~ /_repeat_init/) {
            push @{$merged[-1]{assignments}}, @{$s->{assignments}};
            $merged[-1]{transitions} = $s->{transitions};
            $merged[-1]{name} = $s->{name};
        } else {
            push @merged, $s;
        }
    }
    @$st = @merged;
}

1;
