use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use File::Temp qw(tempdir);
use JSON::PP;
use Storable qw(dclone);
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Support::ISFHDLProfile ();
use FSM::Support::ISFInterfacePortMetadata qw(capture_interface_port_metadata);

my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical;
my $definition = '(record (tag (bits 2)) (body (record (data (signed (four_state (bits 3)))) (flag bit))))';
write_file("$work/shared.fsm", '(?pkg:shared (+types (type frame '.$definition.')))');
my @cases = map { resolved_output_case($_) } qw(local imported alias mixed unused);

subtest 'output-only declared records receive exact unsupported target reasons' => sub {
    for my $case (grep {$_->{name} ne 'mixed'} @cases) {
        my $ports = $case->{actor}{interface_port_metadata};
        my $before = $json->encode($ports);
        for my $target (qw(verilog v vhdl)) {
            my $error = profile_error($case,$target);
            is($error,output_reason($case,$target),"$case->{name}/$target names exact actor, output, authored type and alternative");
        }
        is($json->encode($ports),$before,'complete first-touch metadata JSON remains unchanged');
    }
};

subtest 'mixed declarations preserve current input priority and input diagnostic bytes' => sub {
    my ($mixed) = grep {$_->{name} eq 'mixed'} @cases;
    for my $target (qw(verilog v)) {
        my $expected = "ISF actor 'profile_mixed' record input 'incoming' (type 'frame') cannot generate target 'verilog': packed record inputs require SystemVerilog; use --language systemverilog. Verilog-2005 record lowering is not implemented.\n";
        is(profile_error($mixed,$target),$expected,'mixed profile retains exact existing first record-input refusal');
        is(legacy_error($mixed,$target),$expected,'legacy input helper retains identical contract');
    }
    is(profile_error($mixed,'vhdl'),output_reason($mixed,'vhdl'),
        'prepared VHDL output boundary does not invent a blanket input refusal');
};

subtest 'supported and unknown profiles do not fabricate record evidence' => sub {
    for my $target (qw(systemverilog sv)) {
        for my $case (@cases) {
            is(profile_error($case,$target),'','SystemVerilog profile permits validated declarations for later source/writer qualification');
        }
    }
    for my $ports (undef,[],[{name=>'scalar',direction=>'output',width=>'6'}],
        [{name=>'typed_scalar',direction=>'output',width=>'3',type=>'bits_alias',type_kind=>'bits'}]) {
        for my $target (qw(verilog v vhdl)) {
            my $before=$json->encode($ports);
            my $error=invoke_error('profile_unknown',$ports,$target);
            is($error,'','absent/empty/scalar facts do not imply a record output');
            is($json->encode($ports),$before,'unknown and scalar facts stay byte-exact');
        }
    }
};

subtest 'legacy input helper keeps its input-only prepared output behavior' => sub {
    for my $case (grep {$_->{name} ne 'mixed'} @cases) {
        for my $target (qw(verilog v vhdl systemverilog)) {
            is(legacy_error($case,$target),'','compatibility helper remains input-only');
        }
    }
};

subtest 'canonical metadata validation precedes unsupported profile interpretation' => sub {
    my $case = $cases[0];
    for my $change (
        sub {delete $_[0][-1]{type_kind}},
        sub {$_[0][-1]{fields}[0]{lsb}=0},
        sub {push @{$_[0]}, {name=>'late_input',direction=>'input',width=>1}},
        sub {push @{$_[0]}, []},
    ) {
        my $ports=dclone($case->{actor}{interface_port_metadata});
        $change->($ports);
        my $before=$json->encode($ports);
        my $error=invoke_error($case->{actor}{actor_name},$ports,'verilog');
        like((split /\n/,$error)[0] // '',qr/^Invalid ISF interface port metadata: /,
            'malformed layout/order/entry receives canonical primary diagnostic');
        unlike((split /\n/,$error)[0] // '',qr/cannot generate target/,'bad metadata cannot be accepted as a valid record declaration');
        is($json->encode($ports),$before,'malformed first-touch caller facts remain unchanged');
    }
};

subtest 'resolved prototypes preserve independently literal layout and authoring boundary' => sub {
    for my $case (@cases) {
        my ($record)=grep {$_->{name} eq 'packet'} @{$case->{actor}{interface_port_metadata}};
        is($record->{direction},'output','resolved donor is explicitly projected into output role');
        is($record->{width},6,'literal nested packed width');
        is_deeply($record->{fields},[
            {path=>'tag',width=>2,msb=>5,lsb=>4,signed=>0},
            {path=>'body.data',width=>3,msb=>3,lsb=>1,signed=>1,state_model=>'four_state'},
            {path=>'body.flag',width=>1,msb=>0,lsb=>0,signed=>0},
        ],'authored traversal, exact signed/state layout and ranges are independently expected');
    }
    eval {FSM::Adapter::ISF->new->parse_source('(actor still_closed (types (type frame '.$definition.')) (interface (output packet (type frame))))','still_closed.isf')};
    like((split /\n/,$@)[0] // '',qr/interface port 'packet' references aggregate type 'frame'/,
        'target-profile preparation does not widen authored output grammar');
};

done_testing;

sub resolved_output_case {
    my ($name)=@_;
    my $imported=$name eq 'imported' || $name eq 'alias';
    my $type=$name eq 'imported' ? 'shared.frame' : 'frame';
    my $types=$imported ? '(imports (package shared))'.($name eq 'alias' ? '(types (type frame shared.frame))' : '')
        : '(types (type frame '.$definition.'))';
    my $incoming=$name eq 'mixed' ? '(input incoming (type frame))' : '';
    my $body=$name eq 'unused' ? '' : '(transaction main (on start) (set held.tag 1) (complete done))';
    my $source='(actor profile_'.$name.' (clock clk) '.$types.' (interface (input start) '.$incoming
        .' (output done) (output placeholder (width 6))) (storage (var packet (type '.$type.')) (var held (type '.$type.'))) '.$body.')';
    my $path="$work/$name.isf";
    write_file($path,$source);
    my $actor=FSM::Adapter::ISF->new->parse_file($path);
    my $donor=shift @{$actor->{storage}};
    my ($output)=grep {$_->{name} eq 'placeholder'} @{$actor->{interface}{outputs}};
    %$output=map {$_=>ref($donor->{$_}) ? dclone($donor->{$_}) : $donor->{$_}}
        grep {exists $donor->{$_}} qw(name width type type_spec domain);
    $actor->{interface_port_metadata}=capture_interface_port_metadata($actor->{interface},undef);
    # Stringify numeric facts before first use to detect in-place numeric coercion.
    for my $port (@{$actor->{interface_port_metadata}}) {
        $port->{width}=''.$port->{width};
        for my $field (@{$port->{fields} // []}) {$field->{$_}=''.$field->{$_} for qw(width lsb msb signed)}
    }
    return {name=>$name,type=>$type,actor=>$actor,source=>$source};
}
sub output_reason {
    my ($case,$target)=@_;
    $target='verilog' if $target eq 'v';
    my $detail=$target eq 'verilog' ? 'Verilog-2005 record lowering is not implemented.' : 'VHDL record-output lowering is not implemented.';
    return "ISF actor '$case->{actor}{actor_name}' record output 'packet' (type '$case->{type}') cannot generate target '$target': packed record outputs require SystemVerilog; use --language systemverilog. $detail\n";
}
sub profile_error {my ($case,$target)=@_;return invoke_error($case->{actor}{actor_name},$case->{actor}{interface_port_metadata},$target)}
sub invoke_error {
    my ($actor,$ports,$target)=@_;
    my $ok=eval {FSM::Support::ISFHDLProfile::assert_record_port_hdl_profile(actor_name=>$actor,interface_ports=>$ports,target_language=>$target);1};
    return $ok ? '' : $@;
}
sub legacy_error {
    my ($case,$target)=@_;
    my $ok=eval {FSM::Support::ISFHDLProfile::assert_record_input_hdl_profile(actor_name=>$case->{actor}{actor_name},interface_ports=>$case->{actor}{interface_port_metadata},target_language=>$target);1};
    return $ok ? '' : $@;
}
sub write_file {open my $fh,'>:raw',$_[0] or die $!;print {$fh} $_[1] or die $!;close $fh or die $!}
