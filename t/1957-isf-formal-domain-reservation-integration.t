#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use File::Temp qw(tempdir);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalIdentityPlan;
use FSM::Scheduler::ISF::FormalClauseResolver;
use FSM::Scheduler::ISF::PreparedFormalReservations;

my $s = FSM::Scheduler::ISF->new;
my $l = $s->{ir};
my $work = tempdir(CLEANUP => 1);
my $ordinal = 0;
my $base = <<'ISF';
(actor domain_integration
 (clock-domains (domain core (clock clk) (reset rst_n) :default)
                (domain aux (clock aux_clk) (reset aux_rst_n)))
 (interface (input start) (input data (width 4)) (input high_req) (input low_req)
  (output flag) (output done) (output notice) (output seen (width 12))
  (input aux_start (domain aux)) (input aux_data (width 8) (domain aux))
  (input aux_high_req (domain aux)) (input aux_low_req (domain aux))
  (output aux_flag (domain aux)) (output aux_done (domain aux)))
 (storage (var value_reg (width 12) (reset 3)))
 (resources (resource core_lane (kind rule_slot) (arbiter round_robin) (users high low))
            (resource aux_lane (kind rule_slot) (arbiter round_robin) (users aux_high aux_low)))
 (priority high over low) (priority aux_high over aux_low)
 (rule high high_req (flag 1)) (rule low low_req (flag 0))
 (rule aux_high (domain aux) aux_high_req (aux_flag 1))
 (rule aux_low (domain aux) aux_low_req (aux_flag 0))
 (transaction worker (ports (output result (width 12)))
  (set result value_reg) (complete notice))
 (transaction core_parent (ports (input payload (width 4)) (input value_reg (width 4)))
  (on start) (set payload data) (set value_reg payload) (wait value_reg)
  (spawn worker as job (bind (output result seen))) (await_all done) (complete done))
 (transaction aux_parent (domain aux) (ports (input payload (width 8)))
  (on aux_start) (set payload aux_data) (wait payload) (complete aux_done)))
ISF
sub parse {FSM::Adapter::ISF->new->parse_source($_[0], 'domain_integration.isf')}
sub inventory {
    my ($p) = @_;
    return FSM::Scheduler::ISF::PreparedFormalReservations->collect($p)->{reserved_names};
}
sub prepare {
    no warnings 'redefine';
    local *FSM::Scheduler::ISF::LoweringIR::build_module = sub {die "preparation merged an executable parent\n"};
    return $l->prepare_formal_source($_[0]);
}
sub project {
    my ($p) = @_;
    my $actor = dclone($p->{actor});
    my $reserved = inventory($p);
    my $plan = FSM::Scheduler::ISF::FormalIdentityPlan->build($actor,
        generated_children => $p->{generated_children}, reserved_names => $reserved);
    for my $tx (@{$actor->{transactions}}) {
        next if $p->{pruned_transactions}{$tx->{name}};
        $tx = FSM::Scheduler::ISF::FormalClauseResolver->transaction($tx,
            plan => $plan, %{$p->{transactions}{$tx->{name}}})->{transaction};
    }
    return ($actor, $plan, $reserved);
}
sub declarations {
    my ($ir) = @_;
    return {map {$_ => 1} grep {defined $_} (
        (map {keys %{$ir->{$_} || {}}} qw(signal_widths counters storage_roles signal_type_refs reset_values output_defaults)),
        (map {$_->{name}} @{$ir->{ports} || []}, @{$ir->{explicit_interface_ports} || []},
            @{$ir->{constants} || []}, @{$ir->{params} || []}, @{$ir->{states} || []}, @{$ir->{dt_blocks} || []}),
        @{$ir->{explicit_internal_signals} || []}, $ir->{clock}, (($ir->{reset} || {})->{name} // ()),
    )};
}
sub qualify {
    my ($source, $label, $aux_owner, $expect_write) = @_;
    $aux_owner //= 'aux_parent';
    my $before = dclone($source);
    my $p = prepare($source);
    my ($physical, $plan, $reserved) = project($p);
    my $post = prepare($physical);
    my %private;
    for my $formal (@{$plan->{ordered}}) {
        my $name = $formal->{physical_name};
        if ($formal->{placement} eq 'direct_private') {
            ok(!$private{lc $name}++, "$label direct physical formals are portably unique");
            ok(!(grep {lc($_) eq lc($name)} keys %$reserved), "$label physical formal avoids prepared declarations");
        } else {
            is($name, $formal->{source_name}, "$label generated child public formal unchanged");
        }
    }
    my %complete = (%$reserved, map {$_->{physical_name} => 1} @{$plan->{ordered}});
    my %actual;
    my $build = \&FSM::Scheduler::ISF::LoweringIR::build_module;
    my $files;
    {
        no warnings 'redefine';
        local *FSM::Scheduler::ISF::LoweringIR::build_module = sub {
            my ($self, $actor) = @_;
            my $ir = $build->(@_);
            $actual{$actor->{_scheduled_domain_name}} = dclone($ir) if defined $actor->{_scheduled_domain_name};
            return $ir;
        };
        $files = $s->lower($physical)->{files};
    }
    is_deeply([sort keys %actual], ['aux', 'core'], "$label actual independent domains observed");
    for my $domain (qw(core aux)) {
        my $ir = $actual{$domain};
        my $local = $post->{domain_source_products}{$domain}{preparation};
        my $local_names = inventory($local);
        my $declared = declarations($ir);
        is_deeply([sort grep {!$complete{$_}} keys %$declared], [], "$label original products plus formal allocations cover final $domain declarations");
        is_deeply([sort grep {!$local_names->{$_}} keys %$declared], [], "$label physical re-preparation covers $domain independently");
        my @users = $domain eq 'core' ? qw(high low) : qw(aux_high aux_low);
        is_deeply([map {$_->{users}} @{$local->{actor}{resources}}], [\@users], "$label domain resource users are filtered before preparation");
        is_deeply($local->{actor}{priorities}, [[$users[0], 'over', $users[1]]], "$label priorities retain only local owners");
        for my $resource (@{$local->{resource_signal_products}}) {
            is($ir->{counters}{$resource->{declaration}{name}}, $resource->{declaration}{width}, "$label actual domain arbiter width comes from local product");
        }
        for my $formal (@{$plan->{ordered}}) {
            next unless $formal->{placement} eq 'direct_private';
            my $owns = ($domain eq 'core' && $formal->{transaction} eq 'core_parent')
                || ($domain eq 'aux' && $formal->{transaction} eq $aux_owner);
            if ($owns) {
                is($ir->{signal_widths}{$formal->{physical_name}}, $formal->{declaration}{width}, "$label $domain retains its own formal width");
            } else {
                ok(!exists $declared->{$formal->{physical_name}}, "$label sibling formal does not leak into $domain");
            }
        }
    }
    my $local_value = $plan->{formals}{core_parent}{value_reg}{physical_name};
    my $local_payload = $plan->{formals}{core_parent}{payload}{physical_name};
    is($actual{core}{signal_widths}{value_reg}, 12, "$label actor storage retains its independent width");
    my @writes = map {@{$_->{assignments} || []}} @{$actual{core}{states}}, @{$actual{core}{dt_blocks}};
    ok((grep {$_->{lhs} eq $local_value && $_->{rhs} eq $local_payload} @writes),
        "$label private assignment resolves both operands in its transaction");
    my @private_writes = map {@{$_->{assignments} || []}}
        grep {($_->{transaction} // '') eq 'core_parent'} @{$actual{core}{states}};
    ok(!(grep {$_->{lhs} eq 'value_reg'} @private_writes), "$label private assignment cannot write actor storage");
    if ($expect_write) {
        my $writes = $post->{domain_source_products}{core}{preparation}{parent_storage_write_products};
        ok(@{$writes->{ports}}, "$label actual child writer products are nonempty");
        my %ports = map {$_->{name} => $_} @{$actual{core}{ports}};
        is_deeply($ports{$_->{name}}, $_, "$label actual writer port matches domain preparation") for @{$writes->{ports}};
        my %dts = map {$_->{name} => $_} @{$actual{core}{dt_blocks}};
        is_deeply($dts{$_->{name}}, $_, "$label actual owner write DT matches domain preparation") for @{$writes->{dt_blocks}};
    }
    is($actual{core}{children}{worker}{actor_storage_reads}[0]{name}, 'value_reg', "$label generated child still reads actor-owned storage");
    is($actual{core}{children}{worker}{actor_storage_reads}[0]{width}, 12, "$label generated child read width remains actor-owned");
    is_deeply($source, $before, "$label preparation and projection leave source untouched");
    is_deeply($post->{actor}{interface}, $source->{interface}, "$label public interface unchanged");
    my $dir = "$work/" . ++$ordinal; mkdir $dir or die $!;
    for my $file (sort keys %$files) {
        open my $fh, '>', "$dir/$file" or die $!; print {$fh} $files->{$file}; close $fh or die $!;
    }
    my $check = FSM::Test::SourceQueryRunner::_capture([$^X,'bin/fsmgen','--strict','--check','--json',"$dir/$source->{actor_name}_top.fsm"], '');
    is($check->{exit_code}, 0, "$label complete projected composition strict-checks") or diag($check->{stdout}, $check->{stderr});
    return {map {$_->{transaction} . '.' . $_->{source_name} => $_->{physical_name}} @{$plan->{ordered}}};
}
subtest 'mixed widths, actor storage, generated handoffs and local arbitration compose' => sub {
    my $source = parse($base);
    my $names = qualify($source, 'source_order');
    for my $kind (qw(transactions domains rules)) {
        my $permuted = dclone($source);
        my $entries = $kind eq 'domains' ? $permuted->{clock_domains}{domains} : $permuted->{$kind};
        @$entries = reverse @$entries;
        is_deeply(qualify($permuted, "reversed_$kind"), $names, "$kind declaration order preserves lexical physical identities");
    }
};
subtest 'portable candidate collisions compose with domain projection' => sub {
    for my $pin (qw(isf_port_core_parent_payload ISF_PORT_CORE_PARENT_PAYLOAD)) {
        my $text = $base;
        $text =~ s/\(interface/(interface (input $pin)/;
        my $names = qualify(parse($text), "collision_$pin");
        isnt(lc $names->{'core_parent.payload'}, lc $pin, 'allocated formal avoids actual public candidate collision');
    }
};
subtest 'activation crossing products compose with generated-child and resource products' => sub {
    my $text = $base;
    $text =~ s/\(interface/(crossings (activation remote (from core) (to aux))) (interface/;
    $text =~ s/\(transaction aux_parent/\(transaction remote/;
    $text =~ s/\(on aux_start\) //;
    $text =~ s/\(domain aux\) \(ports \(input payload \(width 8\)\)\)/(domain aux)/;
    $text =~ s/\(set payload aux_data\) \(wait payload\)/(wait aux_data)/;
    $text =~ s/\(await_all done\) \(complete done\)/(await_all done) (do remote) (complete done)/;
    qualify(parse($text), 'activation_composed', 'remote');
};
subtest 'sole child writes and shared named pulses retain domain ownership' => sub {
    my $text = $base;
    $text =~ s/\(set result value_reg\)/(set result value_reg) (set value_reg 7)/;
    $text =~ s/\(await_all done\) \(complete done\)/(await_all done) (complete notice)/;
    qualify(parse($text), 'writer_and_named', 'aux_parent', 1);
    $text =~ s/\(rule high/(rule competing 1 (value_reg 0)) (rule high/;
    my $p = prepare(parse($text));
    ok(@{$p->{domain_source_products}{core}{preparation}{parent_storage_write_products}{ports}},
        'conflicting source retains only potential writer declarations');
    my ($physical) = project($p);
    eval {$s->lower($physical)};
    like($@, qr/Actor storage 'value_reg' has a parent writer and generated child writer 'job'/,
        'complete reservations do not admit competing parent ownership');
};
done_testing;
