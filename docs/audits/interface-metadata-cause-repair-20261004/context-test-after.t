use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use FSM::Test::ProjectDataLocality;

my $json = JSON::PP->new->canonical;
my $work = tempdir(CLEANUP => 1);
my $echo = "$work/Invalid ISF interface port metadata:";
make_path("$echo/FSM/Support");
open my $module, '<:raw', 'perl/FSM/Support/ISFInterfacePortMetadata.pm' or die $!;
my $provider = do {local $/; <$module>}; close $module or die $!;
write_file("$echo/FSM/Support/ISFInterfacePortMetadata.pm", $provider);

# This child loads the complete real provider and exact prior/current helpers.
# Compile helpers before calling them so active eval source cannot echo a cause.
my $driver = "$work/context.pl";
write_file($driver, <<'PERL');
use strict;
use warnings;
use JSON::PP;
use Carp ();
use Scalar::Util qw(refaddr blessed);
use FSM::Support::ISFInterfacePortMetadata qw(capture_interface_port_metadata snapshot_interface_port_metadata);
use FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);
my $json = JSON::PP->new->canonical;
open my $prior_file, '<:raw', 'docs/audits/interface-metadata-copy-controls-20261004/binding.json' or die $!;
my $prior = $json->decode(do {local $/; <$prior_file>}); close $prior_file or die $!;
my $old = $prior->{sources}{'t/1983-isf-interface-port-metadata.t'}{body};
open my $current_file, '<:raw', 't/1983-isf-interface-port-metadata.t' or die $!;
my $current = do {local $/; <$current_file>}; close $current_file or die $!;
sub helper {
    my ($source) = @_;
    my $start = index($source, 'sub rejects {');
    my $end = index($source, 'sub write_file {', $start);
    die 'exact metadata helper missing' unless $start >= 0 && $end > $start;
    return substr($source, $start, $end - $start);
}
{
    package PriorMetadataContext;
    our ($json, @bits, @warnings);
    sub ok {push @bits, $_[0] ? 1 : 0}
    sub like {push @bits, $_[0] =~ $_[1] ? 1 : 0}
    sub is_deeply {push @bits, ref($_[0]) eq 'ARRAY' && !@{$_[0]} && !@{$_[1]} ? 1 : 0; @warnings = @{$_[0]}}
    sub diag {}
}
{
    package CurrentMetadataContext;
    our ($json, @bits, @warnings, @causes);
    sub ok {push @bits, $_[0] ? 1 : 0}
    sub is_deeply {push @bits, ref($_[0]) eq 'ARRAY' && !@{$_[0]} && !@{$_[1]} ? 1 : 0; @warnings = @{$_[0]}}
    sub diag {}
    sub diagnostic_cause_matches {
        push @causes, [@_];
        return FSM::Test::DiagnosticCause::diagnostic_cause_matches(@_);
    }
}
$PriorMetadataContext::json = $CurrentMetadataContext::json = $json;
my $old_helper = helper($old); my $current_helper = helper($current);
eval 'package PriorMetadataContext;' . $old_helper; die $@ if $@;
eval 'package CurrentMetadataContext;' . $current_helper; die $@ if $@;
# Only this exact inert unsupported CODE referent is included. It is never
# invoked and grants no native-class/copy/serialization capability.
sub graph {
    my ($value) = @_;
    return $value unless ref($value);
    die 'undeclared native referent' if blessed($value);
    return ['native CODE identity', refaddr($value)] if ref($value) eq 'CODE';
    return ['array', [map {graph($_)} @$value]] if ref($value) eq 'ARRAY';
    die 'undeclared native referent' unless ref($value) eq 'HASH';
    return ['hash', {map {$_ => graph($value->{$_})} sort keys %$value}];
}
my @rows;
for my $case (
    ['real_metadata', 'snapshot', 0, 'ordinary metadata'],
    ['earlier_storable', 'snapshot', 0, 'ordinary earlier refusal'],
    ['caller_label_echo', 'snapshot', 1, 'Invalid ISF interface port metadata: caller label only'],
    ['caller_argument_echo', 'capture', 1, 'ordinary earlier refusal'],
) {
    my ($id, $route, $verbose, $label) = @$case;
    my $input = $id eq 'real_metadata' ? [undef] : $route eq 'capture'
        ? {inputs => [], outputs => [], earlier_native => sub {1}}
        : [{earlier_native => sub {1}}];
    local $Carp::Verbose = $verbose;
    my $before = $json->encode(graph($input));
    my @subjects;
    for my $subject ('PriorMetadataContext', 'CurrentMetadataContext') {
        @PriorMetadataContext::bits = (); @PriorMetadataContext::warnings = ();
        @CurrentMetadataContext::bits = (); @CurrentMetadataContext::warnings = (); @CurrentMetadataContext::causes = ();
        my ($accepted, $error);
        my $operation = sub {
            $accepted = eval {
                $route eq 'capture' ? capture_interface_port_metadata($input, 'Invalid ISF interface port metadata: argument only')
                    : snapshot_interface_port_metadata($input);
                1;
            } ? 1 : 0;
            $error = $@;
            die $error unless $accepted;
        };
        if ($subject eq 'PriorMetadataContext') {
            PriorMetadataContext::rejects($operation, $label, undef, 'expected port metadata entry');
        } else {
            CurrentMetadataContext::rejects($operation, $label, undef, 'expected port metadata entry');
        }
        push @subjects, {subject => $subject, accepted => $accepted, error => $error,
            bits => [$subject eq 'PriorMetadataContext' ? @PriorMetadataContext::bits : @CurrentMetadataContext::bits],
            warnings => [$subject eq 'PriorMetadataContext' ? @PriorMetadataContext::warnings : @CurrentMetadataContext::warnings],
            causes => [@CurrentMetadataContext::causes], after => graph($input)};
    }
    push @rows, {id => $id, route => $route, verbose => $verbose, label => $label,
        before => $json->decode($before), subjects => \@subjects};
}
print $json->encode({loaded_module => $INC{'FSM/Support/ISFInterfacePortMetadata.pm'}, old_helper => $old_helper,
    current_helper => $current_helper, rows => \@rows}), "\n";
PERL
my @captures;
for my $mode ('ordinary', 'location_echo') {
    my @include = $mode eq 'location_echo' ? ("-I$echo", '-Iperl', '-It/lib') : ('-Iperl', '-It/lib');
    open my $pipe, '-|', $^X, @include, $driver or die $!;
    my $body = do {local $/; <$pipe>};
    close $pipe; my $status = $?;
    is($status, 0, "$mode complete native probe exits successfully");
    die 'native context child failed' if $status;
    my $capture = $json->decode($body);
    like($capture->{loaded_module}, qr/\Q$echo\E/, 'actual wanted-prefix module location loaded') if $mode eq 'location_echo';
    for my $row (@{$capture->{rows}}) {
        my ($old, $current) = @{$row->{subjects}};
        my $real = $row->{id} eq 'real_metadata';
        is_deeply($current->{bits}, [1, $real ? 1 : 0, 1], "$mode/$row->{id}: current helper accepts only intended primary");
        is_deeply($old->{bits}, [1, $real || $mode eq 'location_echo' ? 1 : 0, 1], "$mode/$row->{id}: exact prior predicate reproduces native outcome");
        is((split /\n/, $old->{error})[0], (split /\n/, $current->{error})[0], "$mode/$row->{id}: complete native primary conserved");
        is_deeply($current->{warnings}, [], "$mode/$row->{id}: no incidental warnings");
        is($current->{causes}[0][0], $current->{error}, "$mode/$row->{id}: native error passed unchanged to predicate");
        is($current->{causes}[0][1], 'Invalid ISF interface port metadata: expected port metadata entry', "$mode/$row->{id}: complete expectation retained");
        for my $subject ($old, $current) {
            is($json->encode($subject->{after}), $json->encode($row->{before}), "$mode/$row->{id}/$subject->{subject}: actual source/native identity unchanged");
        }
        like($current->{error}, qr/\ACan't store CODE items at /, "$mode/$row->{id}: actual earlier Storable refusal") unless $real;
    }
    push @captures, {mode => $mode, capture => $capture};
}
if (defined $ENV{FSMGEN_METADATA_CONTEXT_CAPTURE}) {
    write_file($ENV{FSMGEN_METADATA_CONTEXT_CAPTURE}, $json->encode({provider => $provider, driver => do {
        open my $source, '<:raw', $driver or die $!; my $body = do {local $/; <$source>}; close $source or die $!; $body
    }, runs => \@captures}) . "\n");
}
done_testing;
sub write_file {
    my ($path, $body) = @_;
    open my $out, '>:raw', $path or die $!;
    print {$out} $body or die $!; close $out or die $!;
}
