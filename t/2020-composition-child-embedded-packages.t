use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Composition::GeneratedChildRealizer;
use FSM::Pipeline::HDLGenerator;
use FSM::Pipeline::SourceFrontend;

my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical;
my $package = '(?pkg:shared (+types (type frame (record (flag bit) (data (bits 5)))))'
    . ' (+constants (ENABLED 1)) (+enums (mode (OFF 0) (ON 1))))';
my $type = {kind => 'record', width => 6, signed => 0, member_order => [qw(flag data)],
    members => {flag => {kind => 'bit', width => 1, signed => 0},
        data => {kind => 'bits', width => 5, signed => 0}}};

for my $kind (qw(fsmc dtc)) {
    subtest "embedded $kind retains the sibling package context" => sub {
        my $path = "$work/$kind.fsm";
        my $root = $kind eq 'fsmc' ? 'fsm' : 'dt';
        my $child = '(?' . $root . ':reader (+import shared) (+types (type alias shared.frame))'
            . ' (+system (clock clk)) (+interface (input packet) (output seen))'
            . ' (+size (packet alias) (seen 5))'
            . ' (-read (= (seen> packet.data) <shared.mode.ON)))';
        my $text = '(?top:package_children (?ports:public_io clk packet<6 seen>5 seen2>5)'
            . ' (?' . $kind . ':child reader) (?' . $kind . ':peer reader)'
            . ' (?wiring:wires (packet child.packet) (child.seen seen) (packet peer.packet) (peer.seen seen2)))'
            . $child . $package;
        write_file($path, $text);
        my ($pipeline, $spec, $header) = prepare($path);
        my $before = $json->encode($spec->raw_ast);
        my $result;
        my $ok = eval {$result = realize($kind, $pipeline, $spec, $path, $header); 1};
        my $error = first_cause($@);
        ok($ok, 'actual generated child resolves its explicit imported package') or diag($error // '');
        is($json->encode($spec->raw_ast), $before, 'complete composition source facts remain unchanged');
        if ($ok) {
            my %ports = map {$_->name => $_} @{$result->interface_ports};
            is($ports{packet}->width, 6, 'packed width is independently expected');
            is($ports{packet}->declared_type_name, 'alias', 'authored alias spelling remains');
            is($json->encode($ports{packet}->declared_type_spec), $json->encode($type),
                'complete recursive imported record identity remains');
            is($ports{packet}->direction, 'input', 'record role remains input');
            is($ports{seen}->width, 5, 'scalar output width remains exact');
            like($result->hdl_code, qr/seen = packet\.data;/, 'HDL retains the selected member read');
            like($result->hdl_code, qr/logic\s+\[4:0\]\s+data;/, 'packed struct member width is independently expected');
        }
        my $planned;
        $ok = eval {$planned = $pipeline->generate_hdl_from_file($path); 1};
        $error = first_cause($@);
        ok($ok, 'actual full composition pipeline resolves the same sibling packages') or diag($error // '');
        is(read_file($path), $text, 'source bytes remain unchanged');

        (my $missing = $text) =~ s/\Q$package\E\z//;
        my $negative = "$work/$kind-missing.fsm";
        write_file($negative, $missing);
        my ($bad_pipeline, $bad_spec, $bad_header) = prepare($negative);
        $ok = eval {realize($kind, $bad_pipeline, $bad_spec, $negative, $bad_header); 1};
        $error = first_cause($@);
        ok(!$ok, 'absent package source remains an explicit refusal');
        like($error // '', qr/package-source resolution is blocked.*no active '\?pkg:shared'/,
            'first diagnostic names the missing package, independent of stack text');

        (my $unimported = $text) =~ s/\(\+import shared\)//;
        my $unimported_path = "$work/$kind-unimported.fsm";
        write_file($unimported_path, $unimported);
        my ($unimported_pipeline, $unimported_spec, $unimported_header) = prepare($unimported_path);
        $ok = eval {realize($kind, $unimported_pipeline, $unimported_spec, $unimported_path, $unimported_header); 1};
        $error = first_cause($@);
        ok(!$ok, 'sibling package cannot silently invent a child import');
        like($error, qr/Malformed '\+types' entry for type 'alias'/,
            'undeclared dependency refuses at the normal type resolver');
    };
}

subtest 'external child packages stay local to their source file' => sub {
    mkdir "$work/external" or die $!;
    my $top = "$work/external-top.fsm";
    write_file($top, '(?top:external_top (?ports:public_io clk packet<9 seen>8)'
        . ' (?fsmc:child external_reader) (?wiring:wires (packet child.packet) (child.seen seen)))' . $package);
    write_file("$work/external/external_reader.fsm", '(?fsm:external_reader (+import shared)'
        . ' (+system (clock clk)) (+interface (input packet) (output seen))'
        . ' (+size (packet shared.frame) (seen 8)) (-read (= (seen> packet.data))))');
    write_file("$work/external/shared.fsm", '(?pkg:shared (+types (type frame (record (flag bit) (data (bits 8))))))');
    my ($pipeline, $spec, $header) = prepare($top, ["$work/external"]);
    my $result = realize('fsmc', $pipeline, $spec, $top, $header);
    my ($packet) = grep {$_->name eq 'packet'} @{$result->interface_ports};
    is($packet->width, 9, 'external source uses its own package instead of the same-name top package');
    is($packet->declared_type_spec->{members}{data}{width}, 8, 'external member type is independently expected');
    unlink "$work/external/shared.fsm" or die $!;
    my ($fresh_pipeline, $fresh_spec, $fresh_header) = prepare($top, ["$work/external"]);
    my $ok = eval {realize('fsmc', $fresh_pipeline, $fresh_spec, $top, $fresh_header); 1};
    my $error = first_cause($@);
    ok(!$ok, 'composition package cannot silently fill an external source dependency');
    like($error // '', qr/package-source resolution is blocked.*no active '\?pkg:shared'/,
        'external missing dependency retains its original first cause');
};

done_testing;
sub prepare {
    my ($path, $search) = @_;
    my $pipeline = FSM::Pipeline::HDLGenerator->new(target_language => 'systemverilog', quiet => 1,
        strict_mode => 1, source_search_paths => $search // []);
    my $ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(fsm_file => $path);
    my $info = FSM::Pipeline::SourceFrontend->classify_source_ast($ast);
    my $spec = FSM::Pipeline::SourceFrontend->parse_composition_source(raw_ast => $ast);
    return ($pipeline, $spec, $info->{header});
}
sub realize {
    my ($kind, $pipeline, $spec, $path, $header) = @_;
    my $method = "realize_${kind}_child_instance";
    return FSM::Composition::GeneratedChildRealizer->$method(pipeline => $pipeline,
        instance => $spec->top->instances->[0], composition_spec => $spec, fsm_file => $path, header => $header);
}
sub read_file {open my $file, '<:raw', $_[0] or die $!; local $/; return <$file>}
sub write_file {open my $file, '>:raw', $_[0] or die $!; print {$file} $_[1] or die $!; close $file or die $!}

sub first_cause {
    my @lines = split /\n/, $_[0];
    shift @lines while @lines && $lines[0] =~ /\A(?:Source file|Parent composition source|Expected child source file|Search roots|Searched locations|Generated child source):/;
    return $lines[0] // '';
}
