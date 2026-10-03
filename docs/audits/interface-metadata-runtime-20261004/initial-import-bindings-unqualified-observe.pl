use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable ();
use Scalar::Util qw(refaddr blessed);
use FSM::Support::ISFInterfacePortMetadata ();
use FSM::Adapter::ISF;

my $base = 'docs/audits/interface-metadata-runtime-20261004';
my $json = JSON::PP->new->canonical;
my (@api, @copies, @consumers, @helpers, @parses);
our $active_helper;
my $clone = Storable->can('dclone');
my $capture = FSM::Support::ISFInterfacePortMetadata->can('capture_interface_port_metadata');
my $snapshot = FSM::Support::ISFInterfacePortMetadata->can('snapshot_interface_port_metadata');
my $parse_source = FSM::Adapter::ISF->can('parse_source');
my $parse_file = FSM::Adapter::ISF->can('parse_file');
my $subtest = Test::More->can('subtest');
my %assertion = map {$_ => Test::More->can($_)} qw(ok like is is_deeply);

# Fresh scalar assignments preserve JSON primitive kinds. Reference paths record
# sharing/cycles without traversing a referent twice; no native object is assumed.
sub graph {
    my ($value, $seen, $path) = @_;
    return $value unless ref($value);
    die 'unqualified native graph reference' if blessed($value);
    $seen ||= {}; $path //= '';
    my $address = refaddr($value);
    return ['reference', $seen->{$address}] if exists $seen->{$address};
    $seen->{$address} = $path;
    if (ref($value) eq 'HASH') {
        my %out;
        for my $key (sort keys %$value) {
            my $escaped = $key; $escaped =~ s/~/~0/g; $escaped =~ s{/}{~1}g;
            $out{$key} = graph($value->{$key}, $seen, "$path/$escaped");
        }
        return ['hash', \%out];
    }
    return ['array', [map {graph($value->[$_], $seen, "$path/$_")} 0..$#$value]]
        if ref($value) eq 'ARRAY';
    die 'unqualified native graph reference';
}

sub refs {
    my ($value, $seen) = @_;
    $seen ||= {};
    return $seen unless ref($value);
    die 'unqualified native isolation reference' if blessed($value)
        || (ref($value) ne 'HASH' && ref($value) ne 'ARRAY');
    return $seen if $seen->{refaddr($value)}++;
    refs($_, $seen) for ref($value) eq 'HASH' ? values(%$value) : @$value;
    return $seen;
}

sub call_api {
    my ($kind, $operation, $caller, @args) = @_;
    my $before = $json->encode(graph(\@args));
    my ($result, $error, @warnings);
    my $old_warning = $SIG{__WARN__};
    my $ok;
    {
        local $SIG{__WARN__} = sub {
            push @warnings, @_;
            if (ref($old_warning) eq 'CODE') {$old_warning->(@_)}
            elsif (!defined($old_warning) || $old_warning ne 'IGNORE') {CORE::warn(@_)}
        };
        $ok = eval {$result = $operation->(@args); 1}; $error = $@;
    }
    push @api, {kind => $kind, caller => $caller, helper => $active_helper,
        before => $json->decode($before), after => graph(\@args),
        accepted => $ok ? 1 : 0, error => $error, warnings => \@warnings,
        result => $ok ? graph($result) : undef};
    die $error unless $ok;
    return $result;
}

sub copy_value {
    my ($kind, $caller, @args) = @_;
    my $before = $json->encode(graph($args[0]));
    my $original_refs = refs($args[0]);
    my $copy = $clone->(@args);
    my $copy_refs = refs($copy);
    push @copies, {kind => $kind, caller => $caller,
        before => $json->decode($before), after => graph($args[0]), copy => graph($copy),
        original_reference_count => scalar(keys %$original_refs),
        copy_reference_count => scalar(keys %$copy_refs),
        shared_with_original => scalar(grep {exists $original_refs->{$_}} keys %$copy_refs)};
    return $copy;
}

sub parse {
    my ($kind, $operation, $caller, @args) = @_;
    my @inputs = @args[1..$#args];
    my $before = $json->encode(graph(\@inputs));
    my ($result, $error);
    my $ok = eval {$result = $operation->(@args); 1}; $error = $@;
    push @parses, {kind => $kind, caller => $caller, before => $json->decode($before),
        after => graph(\@inputs), accepted => $ok ? 1 : 0, error => $error,
        result => $ok ? graph($result) : undef};
    die $error unless $ok;
    return $result;
}

{
    no warnings 'redefine';
    local *Storable::dclone = sub ($) {
        my @caller = caller;
        return $clone->(@_) unless $caller[0] eq 'main'
            && $caller[1] eq './t/1983-isf-interface-port-metadata.t';
        return copy_value('test', \@caller, @_);
    };
    local *FSM::Support::ISFInterfacePortMetadata::dclone = sub ($) {
        return copy_value('provider', [caller], @_);
    };
    local *FSM::Support::ISFInterfacePortMetadata::capture_interface_port_metadata = sub {
        return call_api('capture', $capture, [caller], @_);
    };
    local *FSM::Support::ISFInterfacePortMetadata::snapshot_interface_port_metadata = sub {
        return call_api('snapshot', $snapshot, [caller], @_);
    };
    local *FSM::Adapter::ISF::parse_source = sub {
        return parse('source', $parse_source, [caller], @_);
    };
    local *FSM::Adapter::ISF::parse_file = sub {
        return parse('file', $parse_file, [caller], @_);
    };
    local *Test::More::subtest = sub {
        my ($name, $body, @args) = @_;
        my $helper = main->can('rejects');
        die 'whole compiled helper missing' unless $helper;
        return $subtest->($name, sub {
            local *main::rejects = sub {
                my ($operation, $label, $value) = @_;
                local $active_helper = scalar @helpers;
                push @helpers, {label => $label, caller => [caller],
                    supplied_value => graph($value), api_start => scalar @api,
                    consumer_start => scalar @consumers};
                my $returned = $helper->(@_);
                $helpers[$active_helper]{api_end} = scalar @api;
                $helpers[$active_helper]{consumer_end} = scalar @consumers;
                return $returned;
            };
            return $body->(@_);
        }, @args);
    };
    local *Test::More::ok = sub ($;$) {
        my ($actual, $label) = @_;
        my $caller = [caller];
        my $passed = $assertion{ok}->(@_);
        push @consumers, {kind => 'ok', caller => $caller, helper => $active_helper,
            label => $label, actual => $actual ? 1 : 0, passed => $passed ? 1 : 0}
            if $caller->[0] eq 'main';
        return $passed;
    };
    local *Test::More::like = sub ($$;$) {
        my ($actual, $expected, $label) = @_;
        my $caller = [caller];
        my $passed = $assertion{like}->(@_);
        push @consumers, {kind => 'like', caller => $caller, helper => $active_helper,
            label => $label, actual => $actual, expected => "$expected", passed => $passed ? 1 : 0}
            if $caller->[0] eq 'main';
        return $passed;
    };
    local *Test::More::is = sub ($$;$) {
        my ($actual, $expected, $label) = @_;
        my $caller = [caller];
        my $before = [graph($actual), graph($expected)];
        my $passed = $assertion{is}->(@_);
        push @consumers, {kind => 'is', caller => $caller, helper => $active_helper,
            label => $label, actual => $before->[0], expected => $before->[1], passed => $passed ? 1 : 0}
            if $caller->[0] eq 'main';
        return $passed;
    };
    local *Test::More::is_deeply = sub ($$;$) {
        my ($actual, $expected, $label) = @_;
        my $caller = [caller];
        my $before = [graph($actual), graph($expected)];
        my $passed = $assertion{is_deeply}->(@_);
        push @consumers, {kind => 'is_deeply', caller => $caller, helper => $active_helper,
            label => $label, actual => $before->[0], expected => $before->[1], passed => $passed ? 1 : 0}
            if $caller->[0] eq 'main';
        return $passed;
    };
    my $ok = do './t/1983-isf-interface-port-metadata.t';
    die $@ if $@; die $! unless defined $ok;
}
open my $out, '>:raw', "$base/ordinary.json" or die $!;
print {$out} $json->encode({api => \@api, copies => \@copies, helpers => \@helpers,
    consumers => \@consumers, parses => \@parses,
    host => {perl => "$^V", storable => $Storable::VERSION, json_pp => $JSON::PP::VERSION}}), "\n" or die $!;
close $out or die $!;
