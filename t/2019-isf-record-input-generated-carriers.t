use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical;
my $definition = '(record (kind (bits 2)) (payload (record'
    . ' (data (signed (four_state (bits 5)))) (flags (list bit (two_state (bits 2)))))))';
my $spec = {kind => 'record', width => 10, signed => 0, member_order => [qw(kind payload)], members => {
    kind => {kind => 'bits', width => 2, signed => 0},
    payload => {kind => 'record', width => 8, signed => 0, member_order => [qw(data flags)], members => {
        data => {kind => 'bits', width => 5, signed => 1, state_model => 'four_state'},
        flags => {kind => 'list', width => 3, signed => 0, items => [
            {kind => 'bit', width => 1, signed => 0},
            {kind => 'bits', width => 2, signed => 0, state_model => 'two_state'}]}}}}};
my $fields = [
    {path => 'kind', width => 2, lsb => 8, msb => 9, signed => 0},
    {path => 'payload.data', width => 5, lsb => 3, msb => 7, signed => 1, state_model => 'four_state'},
    {path => 'payload.flags[0]', width => 1, lsb => 2, msb => 2, signed => 0},
    {path => 'payload.flags[1]', width => 2, lsb => 0, msb => 1, signed => 0, state_model => 'two_state'}];
write_file("$work/shared.fsm", '(?pkg:shared (+types (type frame ' . $definition . ')))');

for my $case (
    ['local_readers', 0, 0, 0, 0], ['imported_readers', 0, 1, 0, 0],
    ['domain_readers', 1, 0, 0, 0], ['imported_domain_readers', 1, 1, 0, 0],
    ['domain_writer', 1, 0, 1, 0], ['imported_domain_do_writer', 1, 1, 1, 1],
) {
    my ($name, $domains, $imported, $writer, $blocking) = @$case;
    subtest $name => sub {
        my $base_type = $imported ? 'shared.frame' : 'frame';
        my $types = $imported ? '(imports (package shared)) (types (type alias shared.frame))'
            : '(types (type frame ' . $definition . ') (type alias frame))';
        my $owner = $domains ? '(domain io)' : '';
        my $unused_owner = $domains ? '(domain idle)' : '';
        my $system = $domains ? '(clock-domains (domain idle (clock idle_clk) :default)'
            . ' (domain io (clock clk) (reset (rst_n async active_low))))'
            : '(clock clk) (reset (rst_n async active_low))';
        my $worker = '(transaction worker ' . $owner . ' (params (MODE 0))'
            . ' (ports (output result (width 5))) (wait 2)'
            . ($writer ? ' (set held packet)' : '')
            . ' (set result packet.payload.data) (complete done))';
        my $calls = $blocking ? '(do worker (params (MODE 1)) (bind (output result seen)))'
            : '(spawn worker as left (bind (output result seen)))'
                . ($writer ? '' : ' (spawn worker as right (params (MODE 2)) (bind (output result again)))')
                . ' (await_all done)';
        my $text = '(actor ' . $name . ' ' . $system . ' ' . $types
            . ' (interface (input start ' . $owner . ') (input packet (type alias) ' . $owner . ')'
            . ' (input unused (type ' . $base_type . ') ' . $unused_owner . ')'
            . ' (output seen (width 5) ' . $owner . ') (output again (width 5) ' . $owner . ')'
            . ' (output done ' . $owner . '))'
            . ' (storage (var held (type ' . $base_type . ') (reset 5) ' . $owner . ')) '
            . $worker . ' (transaction main ' . $owner . ' (on start)'
            . ($writer ? '' : ' (set held packet)') . ' ' . $calls . ' (complete done)))';
        my $source = "$work/$name.isf";
        write_file($source, $text);
        my $actor = FSM::Adapter::ISF->new->parse_file($source);
        my $before = $json->encode($actor);
        my @ports = (port('start', 'input', 1), record_port('packet', 'alias'),
            record_port('unused', $base_type), port('seen', 'output', 5),
            port('again', 'output', 5), port('done', 'output', 1));
        if ($domains) {$_->{domain} = $_->{name} eq 'unused' ? 'idle' : 'io' for @ports}
        same($actor->{interface_port_metadata}, \@ports, 'every authored port and packed range is independently expected');
        for my $value (@{$actor->{interface}{inputs}}, @{$actor->{storage}}) {
            next unless $value->{name} =~ /\A(?:packet|unused|held)\z/;
            same($value->{type_spec}, $spec, "$value->{name} has the entire independently authored recursive type");
        }
        my $scheduler = FSM::Scheduler::ISF->new;
        my $product = $scheduler->lower($actor);
        my $report = $json->decode($scheduler->report($actor));
        is($json->encode($actor), $before, 'complete caller kinds and facts survive lower and report');
        same($report->{interface_ports}, \@ports, 'schedule has only complete authored declarations');
        my $parent = $domains ? "${name}__domain_io" : $name;
        my $child = $domains ? "${parent}__child_worker" : 'worker';
        my @instances = $blocking ? ('main_worker_do_0') : $writer ? ('left') : qw(left right);
        my @files = ("$parent.fsm", "$child.fsm", "${name}_top.fsm",
            $domains ? ("${name}__domain_idle.fsm") : ());
        same([sort keys %{$product->{files}}], [sort @files], 'one definition is reused without missing or extra artifacts');
        my $parent_text = $product->{files}{"$parent.fsm"};
        my $child_text = $product->{files}{"$child.fsm"};
        like($parent_text, qr/\(packet alias\)/, 'owner input remains a typed packed root');
        like($parent_text, qr/\(held \Q$base_type\E \(reset 5\)\)/, 'only owner stores and resets the packed register');
        like($child_text, qr/\(packet alias\)/, 'actual child inherits the packed alias');
        unlike($child_text, qr/\(held \Q$base_type\E|\(internal held\)|\(input unused\)/,
            'child has no copied owner register or unread inherited declaration');
        like($child_text, qr/\(clock clk\)\s*\(areset rst_n\)/, 'child retains exactly its owning clock and reset');
        like($child_text, qr/\(result> packet\.payload\.data\)/, 'child reads the live scalar member without inferred capture');
        my @child_roles = ('(input start)', '(input packet)', '(output done)', '(output result)',
            $writer ? ('(output isf_write_held_data)', '(output isf_write_held_enable)') : (),
            '(internal isf_child_start_seen)');
        my ($interface) = $child_text =~ /\(\+interface\n(.*?)\n  \)/s;
        same([map {s/^\s+|\s+$//gr} split /\n/, $interface // ''], \@child_roles,
            'complete child interface has exact private roles');
        if ($writer) {
            like($child_text, qr/\(isf_write_held_data \Q$base_type\E\)/, 'private write data preserves storage alias');
            like($child_text, qr/\(= \(isf_write_held_data> packet\)\)/, 'whole copy uses the original packed input');
            like($child_text, qr/\(= \(isf_write_held_enable> 1\)\)/, 'write has an explicit enable at its original state');
        } else {like($parent_text, qr/\(<- \(held packet\)\)/, 'parent whole copy retains the original assignment');}
        my $top = $product->{files}{"${name}_top.fsm"};
        my ($ports_block) = $top =~ /\(\?ports:public_io\n(.*?)\n  \)/s;
        my @public = ($domains ? ('idle_clk') : (), qw(clk rst_n start packet<10 unused<10 seen>5 again>5 done>));
        same([map {s/^\s+|\s+$//gr} split /\n/, $ports_block // ''], \@public,
            'complete public top exposes exactly authored pins and clocks/resets');
        my $parent_instance = $domains ? 'io' : $name;
        my @links = (['start', "$parent_instance.start"], ['packet', "$parent_instance.packet"],
            $domains ? () : (['unused', "$parent_instance.unused"]),
            ["$parent_instance.seen", 'seen'], ["$parent_instance.again", 'again'], ["$parent_instance.done", 'done']);
        for my $instance (@instances) {
            my $physical = $domains ? "io__$instance" : $instance;
            like($top, qr/\(\?fsmc:\Q$physical\E \Q$child\E(?:\s|\))/, 'each instance uses the one correctly typed definition');
            push @links, ['packet', "$physical.packet"];
            push @links, ["$physical.isf_write_held_data", "$parent_instance.isf_write_${instance}_held_data"],
                ["$physical.isf_write_held_enable", "$parent_instance.isf_write_${instance}_held_enable"] if $writer;
            push @links, ["$parent_instance.${instance}_start", "$physical.start"],
                ["$physical.done", "$parent_instance.${instance}_done"],
                ["$physical.result", "$parent_instance.${instance}_result"];
        }
        push @links, ['unused', 'idle.unused'] if $domains;
        my ($top_root) = $top =~ /\A(\(\?top:.*?\n\))/s;
        my @actual_links = ($top_root // '') =~ /^    \(([^()\n]+ [^()\n]+)\)$/mg;
        same([sort @actual_links], [sort map {join ' ', @$_} @links], 'complete private and public wiring has exact endpoints');
        if ($domains) {
            same($report->{inferred_storage}, [], 'outer top has no domain-owned registers');
            my %owned = map {$_->{name} => $_} @{$report->{clock_domains}};
            same($owned{idle}{interface_ports}, [$ports[2]], 'unused declaration remains only in its real domain');
            same($owned{io}{interface_ports}, [@ports[0,1,3,4,5]], 'all live declarations remain only in their owning domain');
            same($owned{idle}{inferred_storage}, [], 'idle sibling has no inferred state');
            is($owned{idle}{reset}, undef, 'clock-only sibling has no reset');
            same($owned{io}{reset}, {name => 'rst_n', kind => 'async', polarity => 'active_low'}, 'exact authored owner reset');
            same([grep {($_->{role}//'') eq 'actor_storage'} @{$owned{io}{inferred_storage}}],
                [{name => 'held', kind => 'register', role => 'actor_storage', width => 10,
                    type => $base_type, type_kind => 'record'}], 'complete owned storage excludes public inputs');
        }
        mkdir "$work/$name" or die $!;
        for my $file (sort keys %{$product->{files}}) {
            my $path = "$work/$name/$file";
            write_file($path, $product->{files}{$file});
            my $checked = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
            is($checked->{exit_code}, 0, "$file actual strict public replay") or diag($checked->{stdout} . $checked->{stderr});
            is($checked->{stderr}, '', "$file clean machine-report stderr");
            ok($json->decode($checked->{stdout})->{success}, "$file complete success");
        }
        is(read_file($source), $text, 'original authored source stays byte exact');
    };
}

subtest 'maintained imported named-domain example retains its literal declarations' => sub {
    my $source = 'isf/record_input_children.isf';
    my $original = read_file($source);
    my $package_original = read_file('isf/record_input_types.fsm');
    my $actor = FSM::Adapter::ISF->new->parse_file($source);
    my $before = $json->encode($actor);
    my $record = {name => 'packet', direction => 'input', width => 6, type => 'frame',
        type_kind => 'record', domain => 'io', fields => [
            {path => 'flag', width => 1, lsb => 5, msb => 5, signed => 0},
            {path => 'data', width => 5, lsb => 0, msb => 4, signed => 1, state_model => 'four_state'}]};
    my @expected = (port('start', 'input', 1), $record,
        {%{dclone($record)}, name => 'unused', domain => 'idle'}, port('seen', 'output', 5),
        port('again', 'output', 5), port('done', 'output', 1));
    $_->{domain} //= 'io' for @expected;
    same($actor->{interface_port_metadata}, \@expected, 'all maintained pins, aliases, ranges and domains are literal');
    my $product = FSM::Scheduler::ISF->new->lower($actor);
    is($json->encode($actor), $before, 'maintained actor is unchanged');
    mkdir "$work/maintained" or die $!;
    for my $file (sort keys %{$product->{files}}) {
        my $path = "$work/maintained/$file";
        write_file($path, $product->{files}{$file});
        my $result = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
        is($result->{exit_code}, 0, "$file maintained actual strict replay") or diag($result->{stdout} . $result->{stderr});
        ok($json->decode($result->{stdout})->{success}, "$file maintained complete success");
    }
    is(read_file($source), $original, 'maintained source bytes stay exact');
    is(read_file('isf/record_input_types.fsm'), $package_original, 'shared package bytes stay exact');
};

done_testing;
sub port {return {name => $_[0], direction => $_[1], width => 0 + $_[2]}}
sub record_port {return {name => $_[0], direction => 'input', width => 10,
    type => $_[1], type_kind => 'record', fields => dclone($fields)}}
sub same {is($json->encode($_[0]), $json->encode($_[1]), $_[2])}
sub read_file {open my $file, '<:raw', $_[0] or die $!; local $/; return <$file>}
sub write_file {open my $file, '>:raw', $_[0] or die $!; print {$file} $_[1] or die $!; close $file or die $!}
