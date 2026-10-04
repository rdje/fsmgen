use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable ();
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use Scalar::Util qw(refaddr blessed);
use FSM::Support::ISFInterfacePortMetadata ();

my $base = 'docs/audits/interface-metadata-writer-cause-repair-20261004';
my $json = JSON::PP->new->canonical;
sub source_bodies {
    open my $binding, '<:raw', "$base/binding-before.json" or die $!;
    my $selected = $json->decode(do {local $/; <$binding>}); close $binding or die $!;
    my %bodies;
    for my $path (sort keys %{$selected->{sources}}) {
        open my $file, '<:raw', $path or die $!;
        $bodies{$path} = do {local $/; <$file>}; close $file or die $!;
    }
    return \%bodies;
}
my $source_before = source_bodies();
my $mode = shift @ARGV // 'ordinary';
die 'undeclared finite control mode' unless $mode =~ /\A(?:ordinary|bypass)\z/;
my $changed = 0;
my @cycles;


my (@api, @copies, @consumers, @helpers, @parses, @cause_consumers);
my $match_cause;
our ($active_helper, $active_api, $active_cycle, $active_parse);
my $test_copy;
my $clone = Storable->can('dclone');
my $capture = FSM::Support::ISFInterfacePortMetadata->can('capture_interface_port_metadata');
my $snapshot = FSM::Support::ISFInterfacePortMetadata->can('snapshot_interface_port_metadata');
my ($parse_source, $parse_file);
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

sub pure_copy {
    my ($value, $copies) = @_;
    return $value unless ref($value);
    die 'unexpected source reference' if blessed($value)
        || (ref($value) ne 'HASH' && ref($value) ne 'ARRAY');
    $copies ||= {};
    my $address = refaddr($value);
    return $copies->{$address} if exists $copies->{$address};
    my $copy = ref($value) eq 'HASH' ? {} : [];
    $copies->{$address} = $copy;
    if (ref($value) eq 'HASH') {
        $copy->{$_} = pure_copy($value->{$_}, $copies) for keys %$value;
    } else {
        push @$copy, pure_copy($_, $copies) for @$value;
    }
    return $copy;
}

sub call_api {
    my ($kind, $operation, $caller, @args) = @_;
    my $before = $json->encode(graph(\@args));
    local $active_api = scalar @api;
    push @api, {kind => $kind, caller => $caller, helper => $active_helper, parse => $active_parse,
        before => $json->decode($before)};
    if ($kind eq 'capture' && defined($active_helper) && $active_helper == 43) {
        my $before_cycle = $json->encode(graph($args[0]));
        my $original_refs = refs($args[0]);
        my $copy_cycle;
        {local $active_cycle = 1; $copy_cycle = main::source_copy($args[0], 'actual cyclic input')}

        my $copied_refs = refs($copy_cycle);
        die 'native cycle fixture locator changed' unless refaddr($args[0]{inputs}[0]{type_spec})
            == refaddr($args[0]{inputs}[0]{type_spec}{members}{loop});
        push @cycles, {before => $json->decode($before_cycle), after => graph($args[0]), copy => graph($copy_cycle),
            original_reference_count => scalar(keys %$original_refs), copy_reference_count => scalar(keys %$copied_refs),
            shared_with_original => scalar(grep {exists $original_refs->{$_}} keys %$copied_refs)};
        die 'cyclic candidate overlaps original' if $cycles[-1]{shared_with_original};
        delete $copy_cycle->{inputs}[0]{type_spec}{members}{loop};
    }
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
    $api[$active_api]{mutation} = undef;
    @{$api[$active_api]}{qw(after accepted error warnings result)} =
        (graph(\@args), $ok ? 1 : 0, $error, \@warnings, $ok ? graph($result) : undef);
    die $error unless $ok;
    return $result;
}

sub copy_value {
    my ($kind, $caller, @args) = @_;
    my $before = $json->encode(graph($args[0]));
    my $original_refs = refs($args[0]);
    my $copy;
    $copy = $kind eq 'provider' ? $clone->(@args) : $test_copy->(@args);
    my $copy_refs = refs($copy);
    push @copies, {kind => $kind, caller => $caller, api => $active_api, parse => $active_parse,
        before => $json->decode($before), after => graph($args[0]), copy => graph($copy),
        original_reference_count => scalar(keys %$original_refs),
        copy_reference_count => scalar(keys %$copy_refs),
        shared_with_original => scalar(grep {exists $original_refs->{$_}} keys %$copy_refs)};
    return $copy;
}

sub parse {
    my ($kind, $operation, $caller, @args) = @_;
    my %documents;
    if ($kind eq 'file') {
        my $root = abs_path('.');
        for my $path ($args[1], dirname($args[1]) . '/shared.fsm') {
            die 'unowned fixture file' unless abs_path($path) =~ /\A\Q$root\E\//
                && !-l $path && (stat($path))[0] == (stat('.'))[0];
            open my $fixture, '<:raw', $path or die $!;
            $documents{$path} = do {local $/; <$fixture>}; close $fixture or die $!;
        }
    }
    my @inputs = @args[1..$#args];
    my $before = $json->encode(graph(\@inputs));
    my ($result, $error);
    local $active_parse = scalar @parses;
    my $ok = eval {$result = $operation->(@args); 1}; $error = $@;
    my %documents_after;
    for my $path (keys %documents) {
        open my $fixture, '<:raw', $path or die $!;
        $documents_after{$path} = do {local $/; <$fixture>}; close $fixture or die $!;
    }
    push @parses, {kind => $kind, caller => $caller, before => $json->decode($before),
        documents_before => \%documents, documents_after => \%documents_after,
        after => graph(\@inputs), accepted => $ok ? 1 : 0, error => $error,
        result => $ok ? graph($result) : undef};
    die $error unless $ok;
    return $result;
}

{
    no warnings 'redefine';
    local *FSM::Support::ISFInterfacePortMetadata::dclone = sub ($) {
        return copy_value('provider', [caller], @_);
    };
    local *FSM::Support::ISFInterfacePortMetadata::capture_interface_port_metadata = sub {
        return call_api('capture', $capture, [caller], @_);
    };
    local *FSM::Support::ISFInterfacePortMetadata::snapshot_interface_port_metadata = sub {
        return call_api('snapshot', $snapshot, [caller], @_);
    };
    require FSM::Support::ISFRecordPortContexts;
if ($mode eq 'bypass') {
    my $require = FSM::Support::ISFRecordPortContexts->can('_require');
    no warnings 'redefine';
    *FSM::Support::ISFRecordPortContexts::_require = sub {
        if (!$_[0] && $_[1] eq "transaction 'main' set target record output field writes are not yet admitted; target 'packet.flag' requires output-field writer qualification") {$changed++; return}
        return $require->(@_);
    };
}
    require FSM::Adapter::ISF;
    $parse_source = FSM::Adapter::ISF->can('parse_source');
    $parse_file = FSM::Adapter::ISF->can('parse_file');
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
        $test_copy = main->can('source_value_copy');
        die 'complete actual test source copier missing' unless $test_copy;
        $match_cause = main->can('diagnostic_cause_matches');
        die 'complete current cause predicate missing' unless $match_cause;
        return $subtest->($name, sub {
            local *main::diagnostic_cause_matches = sub {
                my ($error, $expected) = @_;
                my $passed = $match_cause->(@_);
                push @cause_consumers, {caller => [caller], helper => $active_helper,
                    error => $error, expected => $expected, matched => $passed ? 1 : 0};
                return $passed;
            };
            local *main::source_value_copy = sub {
                return $test_copy->(@_) if @_ != 1;
                return copy_value($active_cycle ? 'cycle' : 'test', [caller(1)], @_);
            };
            local *main::rejects = sub {
                my ($operation, $label, $value, $reason) = @_;
                local $active_helper = scalar @helpers;
                push @helpers, {label => $label, reason => $reason, caller => [caller],
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
open my $out, '>:raw', "$base/$mode.json" or die $!;
die 'exact guard bypass count changed' unless $changed == ($mode eq 'bypass' ? 1 : 0);
print {$out} $json->encode({mode => $mode, changed => $changed, sources_before => $source_before, sources_after => source_bodies(), cycles => \@cycles, api => \@api, copies => \@copies, helpers => \@helpers,
    consumers => \@consumers, cause_consumers => \@cause_consumers, parses => \@parses,
    host => {perl => "$^V", storable => $Storable::VERSION, json_pp => $JSON::PP::VERSION}}), "\n" or die $!;
close $out or die $!;
