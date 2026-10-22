use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::SemanticIntrospectionMCPAdapter;

# ISF-REDUCTION-DELIVERY.1.2.3.2.2. This binds independently selected
# operators/operands and widths to actual report, helper, mux and enable
# products. It does not execute HDL or certify hardware truth tables.
my $json = JSON::PP->new->canonical;
my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
sub capture { FSM::Test::SourceQueryRunner::_capture($_[0], $_[1] // '') }
sub same { is($json->encode($_[0]), $json->encode($_[1]), $_[2]) }
sub read_file {
    open my $fh, '<', $_[0] or die $!;
    my $text = do {local $/; <$fh>};
    close $fh or die $!;
    return $text;
}
sub write_file {
    my ($name, $text) = @_;
    my $path = "$work/$name";
    open my $fh, '>', $path or die $!;
    print {$fh} $text;
    close $fh or die $!;
    $path =~ s/\A\Q$root\E\///;
    return $path;
}
sub compact { my $s = $_[0]; $s =~ s/\s+//g; return $s }
my @authored = qw(reduce_xor_data expr_reduce_xor_data and_data or_data
    out_repeat_and_data_en intermediate_xor_data_other_1 intermediate_complex_expr_2);
my @external = qw(external_bit_a external_bit_b external_and external_or
    external_bit_d external_vector external_bit_c);
my $source = read_file('t/data/reduction_capture_identity.isf');
my $renamed = $source;
my %renames; @renames{@authored} = @external;
$renamed =~ s/\b(\w+)\b/exists($renames{$1}) ? $renames{$1} : $1/ge;
my $wrong = $source;
$wrong =~ s/\(set out_repeat \(\^ data\)\)/(set out_repeat (\& data))/ or die 'missing wrong-value control';
my @cases = (
    {name => 'named', source => $source, pins => \@authored},
    {name => 'renamed', source => $renamed, pins => \@external},
    {name => 'wrong', source => $wrong, pins => \@authored},
);

sub capture_errors {
    my ($report, $sv, $pins) = @_;
    my @errors;
    my ($xor_name, $expr_name, $and_name, $or_name, $enable_name, $vector_name, $bit_name) = @$pins;
    my %inputs = map {$_ => 1} ('start', 'data', 'other', @$pins);
    my (%assign, %width, %state, %mux);
    while ($sv =~ /^\s*assign\s+(\w+)\s*=\s*([^;]+);/mg) {
        push @errors, "duplicate continuous driver $1" if exists $assign{$1};
        $assign{$1} = compact($2);
    }
    while ($sv =~ /^\s*(?:input\s+wire|output\s+reg|wire|reg)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*[,;)]/mg) {
        $width{$3} = defined($1) ? abs($1-$2)+1 : 1;
    }
    while ($sv =~ /localparam\s+(\w+)\s*=\s*\d+'d(\d+)\s*;/g) { $state{$1} = 0+$2 }
    while ($sv =~ /if \((\w+)\) begin\s+(\w+)_next\s*=\s*([^;]+);/g) {
        push @errors, "duplicate mux enable $2/$1" if exists $mux{$2}{$1};
        $mux{$2}{$1} = compact($3);
    }
    for my $input (keys %inputs) {
        push @errors, "internally driven input $input" if exists $assign{$input};
    }
    # Expectations are authored independently of expression/helper names.
    my %expected = (
        out_repeat => [1, {
            main_set_1 => '(^(data))', main_set_2 => '(&(data))',
            main_set_3 => '(|(data))', main_set_4 => $and_name, main_set_5 => $or_name}],
        out_reduce => [3, {'-reduce_rule' => '{(^(data)),(&(data)),(|(data))}'}],
        out_nested => [4, {'-nested_rule' => '{!((^(data))),{(^(data[3:0])),(&(data[0]))},'.$xor_name.'}'}],
        out_user => [5, {'-user_rule' => '{'.join(',', $xor_name,$expr_name,$and_name,$or_name,$enable_name).'}'}],
        out_label => [8, {'-label_rule' => $vector_name}],
        out_label_bit => [1, {'-label_bit_rule' => $bit_name}],
        out_binary => [8, {'-binary_rule' => 'data^other'}],
        out_unrolled => [1, {'-unrolled_rule' => join('^', map {"data[$_]"} 0..7)}],
    );
    my @input_records = map {+{name => $_->[0], width => $_->[1], signed => 0, direction => 'input'}}
        (['start',1], ['data',8], ['other',8], map {[$_, $_ eq $vector_name ? 8 : 1]} @$pins);
    my @output_records = map {+{name => $_, width => $expected{$_}[0], signed => 0, direction => 'output'}} keys %expected;
    push @output_records, {name => 'done', width => 1, signed => 0, direction => 'output'};
    for my $port_set ([inputs => \@input_records], [outputs => \@output_records]) {
        my ($kind, $wanted) = @$port_set;
        my $actual = $report->{semantic}{signal_analysis}{$kind};
        push @errors, "complete declared $kind roles/types/widths"
            unless $json->encode([sort {$a->{name} cmp $b->{name}} @$actual])
                eq $json->encode([sort {$a->{name} cmp $b->{name}} @$wanted]);
    }
    my $families = $report->{semantic}{forward_ir}{lowered_rtl_ir}{output_drive_families};
    my %families = map {$_->{signal_name} => $_} @$families;
    for my $target (sort keys %expected) {
        my ($wanted_width, $drivers) = @{$expected{$target}};
        my $family = $families{$target};
        if (!$family) {push @errors, "missing output family $target"; next}
        push @errors, "semantic width $target" unless $family->{width} == $wanted_width;
        push @errors, "SV width $target" unless ($width{$target} // 0) == $wanted_width;
        my %actual;
        for my $rhs (@{$family->{rhs_enable_families}}) {
            my $value = compact($rhs->{rhs_value});
            my $resolved = $value;
            if ($value =~ /^\w+$/ && !$inputs{$value} && exists $assign{$value}) {
                $resolved = $assign{$value};
                push @errors, "helper width $target" unless ($width{$value} // 0) == $wanted_width;
            }
            for my $block (@{$rhs->{driver_blocks}}) {
                push @errors, "duplicate driver block $target/$block" if exists $actual{$block};
                $actual{$block} = $resolved;
            }
            my $enable = $rhs->{family_enable_signal};
            push @errors, "actual mux RHS $target/$enable" unless ($mux{$target}{$enable} // '') eq $value;
            my @aliases = sort split /\|/, ($assign{$enable} // '');
            push @errors, "actual family enable fan-in $target/$enable"
                unless $json->encode(\@aliases) eq $json->encode([sort @{$rhs->{driver_enable_signals}}]);
            my @actual_conditions;
            for my $driver_enable (@{$rhs->{driver_enable_signals}}) {
                my $condition = $driver_enable;
                my %seen;
                while ($condition =~ /^\w+$/ && exists $assign{$condition}) {
                    if ($seen{$condition}++) {push @errors, "enable cycle $driver_enable"; last}
                    $condition = $assign{$condition};
                }
                if ($condition =~ /^current_state==(\w+)$/ && exists $state{$1}) {
                    $condition = 'state:'.$state{$1};
                }
                push @actual_conditions, $condition;
            }
            my @wanted_conditions = map {/^main_set_([1-5])$/ ? 'state:'.$1 : 'start'} @{$rhs->{driver_blocks}};
            push @errors, "actual driver condition $target/$enable"
                unless $json->encode([sort @actual_conditions]) eq $json->encode([sort @wanted_conditions]);
        }
        for my $block (sort keys %$drivers) {
            push @errors, "wrong value $target/$block: ".($actual{$block} // '<missing>')
                unless ($actual{$block} // '') eq $drivers->{$block};
        }
        push @errors, "complete driver membership $target"
            unless $json->encode([sort keys %actual]) eq $json->encode([sort keys %$drivers]);
    }
    return \@errors;
}

my %products;
subtest 'actual source and carriers bind operators, widths, helper values and write enables' => sub {
    for my $case (@cases) {
        $case->{path} = write_file("$case->{name}.isf", $case->{source});
        my $actor = FSM::Adapter::ISF->new->parse_file($case->{path});
        my $before = $json->encode($actor);
        my $lowered = FSM::Scheduler::ISF->new->lower($actor);
        is($json->encode($actor), $before, "$case->{name} caller data and primitive kinds preserved");
        my ($carrier) = values %{$lowered->{files}};
        my $carrier_path = write_file("$case->{name}.fsm", $carrier);
        for my $path ($case->{path}, $carrier_path) {
            my $native = capture([$^X, 'bin/fsmgen', qw(--strict --emit-semantic-json), $path]);
            is($native->{exit_code}, 0, "$path strict native semantic succeeds") or diag($native->{stdout},$native->{stderr});
            my $report = $json->decode($native->{stdout});
            $products{$case->{name}} = $native if $path eq $case->{path};
            my $sv_path = "$work/$case->{name}-".($path eq $case->{path} ? 'source' : 'carrier').'.sv';
            my $generated = capture([$^X, 'bin/fsmgen', '--strict', '--output', $sv_path, $path]);
            is($generated->{exit_code}, 0, "$path strict SV generation succeeds") or diag($generated->{stderr});
            my $errors = capture_errors($report, read_file($sv_path), $case->{pins});
            if ($case->{name} eq 'wrong') {
                same($errors, ['wrong value out_repeat/main_set_1: (&(data))'],
                    'actual wrong AND source has exactly the independent first-XOR value failure');
            } else {
                same($errors, [], "$path complete actual value/width/enable associations");
            }
        }
    }
    # This concrete operand distinguishes the source control semantically:
    # parity(00000001)=1, whereas all-set(00000001)=0. Hardware execution is later.
    my @bits = (1, 0, 0, 0, 0, 0, 0, 0);
    my ($parity, $all) = (0, 1);
    for (@bits) { $parity ^= $_; $all &&= $_ }
    isnt($parity, $all, 'wrong control changes a value, not only a label or rendering');
};

subtest 'complete native API and actual newline products retain capture and nested-width reports' => sub {
    my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
    for my $case (@cases[0,1]) {
        for my $mode (
            [[qw(--strict --check --json)], 'fsmgen_check'],
            [[qw(--strict --emit-semantic-json)], 'fsmgen_semantic_introspect'],
            [['--emit-schedule-json'], 'fsmgen_schedule_preview'],
        ) {
            my ($flags, $tool) = @$mode;
            my $native = $tool eq 'fsmgen_semantic_introspect' ? $products{$case->{name}}
                : capture([$^X, 'bin/fsmgen', @$flags, $case->{path}]);
            is($native->{exit_code}, 0, "$case->{name} $tool native succeeds");
            my $report = normalize_repository_paths($json->decode($native->{stdout}), $root);
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $tool, arguments => {source_id => $case->{path}}}};
            my $response = $api->handle_jsonrpc_request($request);
            my $result = $response->{result};
            ok(ref($result) eq 'HASH' && !$result->{isError}, 'API success');
            same($result->{structuredContent}{report}, $report, 'complete native/API report equality');
            same($json->decode($result->{content}[0]{text}), $result->{structuredContent}, 'complete text/structured equality');
            my $wire = capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
            is($wire->{exit_code}, 0, 'newline process settles');
            is($wire->{stderr}, '', 'clean newline stderr');
            like($wire->{stdout}, qr/\A[^\n]+\n\z/, 'one compact newline response');
            same($json->decode($wire->{stdout}), $response, 'complete API/newline response equality');
        }
    }
};

done_testing();
