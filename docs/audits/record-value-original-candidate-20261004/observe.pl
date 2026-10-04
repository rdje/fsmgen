use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable ();
use Scalar::Util qw(refaddr blessed);
use FSM::Support::ISFInterfacePortMetadata ();

my $base = 'docs/audits/record-value-original-candidate-20261004';
my ($mode, $output) = @ARGV;
die 'candidate mode and relative output required' unless defined $mode
    && $mode =~ /\A(?:ordinary|storable|alias|controls)\z/ && defined $output
    && $output =~ m{\Adocs/audits/record-value-original-candidate-20261004/};
require './docs/audits/record-value-original-candidate-20261004/candidate.pl';
my $json = JSON::PP->new->canonical;
my (@api, @copies, @consumers, @helpers, @parses, @warnings, @copy_assertions);
my ($test_loaded, $test_error, $test_errno);
my @trials;
our $trial_provider;
our ($active_test_copy, $candidate_calls);
my $pure_copy = \&source_value_copy;
our ($active_helper, $active_api, $active_parse);
my $clone = Storable->can('dclone');
my $capture = FSM::Support::ISFInterfacePortMetadata->can('capture_interface_port_metadata');
my $snapshot = FSM::Support::ISFInterfacePortMetadata->can('snapshot_interface_port_metadata');
my $subtest = Test::More->can('subtest');
my %assertion = map {$_ => Test::More->can($_)} qw(ok like unlike is is_deeply);

# Scalar copies precede any numeric/string interpretation. Referential paths
# retain DAG/cycle topology; native objects are outside this plain fact graph.
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
    local $active_api = scalar @api;
    push @api, {kind => $kind, caller => $caller, helper => $active_helper,
        parse => $active_parse, before => $json->decode($before)};
    my ($result, $error, @local_warnings);
    my $old_warning = $SIG{__WARN__};
    my $ok;
    {
        local $SIG{__WARN__} = sub {
            push @local_warnings, @_;
            if (ref($old_warning) eq 'CODE') {$old_warning->(@_)}
            elsif (!defined($old_warning) || $old_warning ne 'IGNORE') {CORE::warn(@_)}
        };
        $ok = eval {$result = $operation->(@args); 1}; $error = $@;
    }
    my $primary = (split /\n/, $error // '')[0] // '';
    @{$api[$active_api]}{qw(after accepted error primary warnings result)} =
        (graph(\@args), $ok ? 1 : 0, $error, $primary, \@local_warnings,
            $ok ? graph($result) : undef);
    die $error unless $ok;
    return $result;
}

sub copy_value {
    my ($kind, $caller, @args) = @_;
    my $before = $json->encode(graph($args[0]));
    my $original_refs = refs($args[0]);
    my ($copy, $error);
    my $assertion_start = scalar @copy_assertions;
    my $calls = 0;
    my $ok = eval {
        if ($kind eq 'test') {
            local $active_test_copy = scalar @copies;
            local $candidate_calls = 0;
            if ($mode eq 'controls') {
                for my $provider (qw(storable alias)) {
                    local $trial_provider = $provider;
                    $candidate_calls = 0;
                    my $start = scalar @copy_assertions;
                    my $before_trial = $json->encode(graph($args[0]));
                    my $result = source_copy($args[0], "original copy $active_test_copy $provider control");
                    push @trials, {copy => $active_test_copy, provider => $provider, caller => $caller,
                        before => $json->decode($before_trial), after => graph($args[0]),
                        result => graph($result), joint => graph({input => $args[0], result => $result}),
                        assertion_start => $start, assertion_end => scalar @copy_assertions,
                        candidate_calls => $candidate_calls};
                }
                $candidate_calls = 0;
            }
            $copy = source_copy($args[0], "original copy $active_test_copy");
            $calls = $candidate_calls;
        } else {
            $copy = $clone->(@args);
        }
        1;
    }; $error = $@;
    my $copy_refs = $ok ? refs($copy) : {};
    push @copies, {kind => $kind, caller => $caller, api => $active_api,
        helper => $active_helper, parse => $active_parse,
        before => $json->decode($before), after => graph($args[0]),
        accepted => $ok ? 1 : 0, error => $error, copy => $ok ? graph($copy) : undef,
        original_reference_count => scalar(keys %$original_refs),
        copy_reference_count => scalar(keys %$copy_refs),
        shared_with_original => scalar(grep {exists $original_refs->{$_}} keys %$copy_refs),
        joint_input_result => $ok ? graph({input => $args[0], result => $copy}) : undef,
        assertion_start => $assertion_start, assertion_end => scalar @copy_assertions,
        candidate_calls => $calls};
    die $error unless $ok;
    return $copy;
}

sub parse {
    my ($kind, $operation, $caller, @args) = @_;
    # The parser object is deliberately excluded; source/path args and the whole
    # returned actor are observed through the published parser interface.
    my @inputs = @args[1..$#args];
    my $before = $json->encode(graph(\@inputs));
    local $active_parse = scalar @parses;
    push @parses, {kind => $kind, caller => $caller, helper => $active_helper,
        before => $json->decode($before), api_start => scalar @api};
    my ($result, $error);
    my $ok = eval {$result = $operation->(@args); 1}; $error = $@;
    @{$parses[$active_parse]}{qw(after accepted error primary result api_end)} =
        (graph(\@inputs), $ok ? 1 : 0, $error, (split(/\n/, $error // ''))[0] // '',
            $ok ? graph($result) : undef, scalar @api);
    die $error unless $ok;
    return $result;
}

{
    no warnings 'redefine';
    local *main::source_value_copy = sub {
        my ($value, $memo) = @_;
        $candidate_calls++;
        return $pure_copy->(@_) if defined $memo;
        my $complete = $pure_copy->(@_);
        my $provider = $trial_provider // $mode;
        return $clone->($value) if $provider eq 'storable';
        return $value if $provider eq 'alias';
        return $complete;
    };
    # Install declaration wrappers before consumers import those functions.
    local *FSM::Support::ISFInterfacePortMetadata::dclone = sub ($) {
        return copy_value('metadata-private', [caller], @_);
    };
    local *FSM::Support::ISFInterfacePortMetadata::capture_interface_port_metadata = sub {
        return call_api('capture', $capture, [caller], @_);
    };
    local *FSM::Support::ISFInterfacePortMetadata::snapshot_interface_port_metadata = sub {
        return call_api('snapshot', $snapshot, [caller], @_);
    };
    require FSM::Support::ISFRecordPortValues;
    my %value = map {$_ => FSM::Support::ISFRecordPortValues->can($_)}
        qw(record_value_scope record_value_reference validate_record_port_copy);
    local *FSM::Support::ISFRecordPortValues::dclone = sub ($) {
        return copy_value('value-private', [caller], @_);
    };
    local *FSM::Support::ISFRecordPortValues::record_value_scope = sub {
        return call_api('scope', $value{record_value_scope}, [caller], @_);
    };
    local *FSM::Support::ISFRecordPortValues::record_value_reference = sub {
        return call_api('reference', $value{record_value_reference}, [caller], @_);
    };
    local *FSM::Support::ISFRecordPortValues::validate_record_port_copy = sub {
        return call_api('copy', $value{validate_record_port_copy}, [caller], @_);
    };
    my $range = FSM::Package::AggregatePathSupport->can('resolve_packed_range');
    my $structured = FSM::Package::AggregatePathSupport->can('clone_structured_value');
    my $conflicts = FSM::Composition::InterfacePortBuilder->can('declared_type_conflicts');
    local *FSM::Package::AggregatePathSupport::resolve_packed_range = sub {
        return call_api('range', $range, [caller], @_);
    };
    local *FSM::Package::AggregatePathSupport::clone_structured_value = sub {
        return call_api('structured-clone', $structured, [caller], @_);
    };
    local *FSM::Composition::InterfacePortBuilder::declared_type_conflicts = sub {
        return call_api('identity', $conflicts, [caller], @_);
    };
    require FSM::Package::PayloadTypeSupport;
    my $payload = FSM::Package::PayloadTypeSupport->can('payload_compatible_with_type_spec');
    local *FSM::Package::PayloadTypeSupport::payload_compatible_with_type_spec = sub {
        return call_api('payload', $payload, [caller], @_);
    };
    require FSM::Adapter::ISF;
    my $parse_source = FSM::Adapter::ISF->can('parse_source');
    my $parse_file = FSM::Adapter::ISF->can('parse_file');
    local *FSM::Adapter::ISF::parse_source = sub {
        return parse('source', $parse_source, [caller], @_);
    };
    local *FSM::Adapter::ISF::parse_file = sub {
        return parse('file', $parse_file, [caller], @_);
    };
    local *Storable::dclone = sub ($) {
        my @caller = caller;
        return $clone->(@_) unless $caller[0] eq 'main'
            && $caller[1] eq './t/1986-isf-record-port-value-gates.t';
        return copy_value('test', \@caller, @_);
    };
    local *Test::More::subtest = sub {
        my ($name, $body, @args) = @_;
        my $helper = main->can('refuses');
        die 'whole compiled helper missing' unless $helper;
        return $subtest->($name, sub {
            local *main::refuses = sub {
                my ($operation, $pattern, $label) = @_;
                local $active_helper = scalar @helpers;
                push @helpers, {label => $label, pattern => "$pattern", caller => [caller],
                    api_start => scalar @api, parse_start => scalar @parses,
                    consumer_start => scalar @consumers};
                my $returned = $helper->(@_);
                @{$helpers[$active_helper]}{qw(api_end parse_end consumer_end)} =
                    (scalar @api, scalar @parses, scalar @consumers);
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
    local *Test::More::unlike = sub ($$;$) {
        my ($actual, $expected, $label) = @_;
        my $caller = [caller];
        my $passed = $assertion{unlike}->(@_);
        push @consumers, {kind => 'unlike', caller => $caller, helper => $active_helper,
            label => $label, actual => $actual, expected => "$expected", passed => $passed ? 1 : 0}
            if $caller->[0] eq 'main';
        return $passed;
    };
    local *Test::More::is = sub ($$;$) {
        my ($actual, $expected, $label) = @_;
        my $caller = [caller];
        my $before = [graph($actual), graph($expected)];
        my $passed = $assertion{is}->(@_);
        if (defined $active_test_copy) {
            push @copy_assertions, {copy => $active_test_copy, label => $label,
                actual => $before->[0], expected => $before->[1], passed => $passed ? 1 : 0};
            return $passed;
        }
        push @consumers, {kind => 'is', caller => $caller, helper => $active_helper,
            label => $label, actual => $before->[0], expected => $before->[1], passed => $passed ? 1 : 0}
            if $caller->[0] eq 'main';
        return $passed;
    };
    local *Test::More::is_deeply = sub {
        my ($actual, $expected, $label) = @_;
        my $caller = [caller];
        my $before = [graph($actual), graph($expected)];
        my $passed = $assertion{is_deeply}->(@_);
        push @consumers, {kind => 'is_deeply', caller => $caller, helper => $active_helper,
            label => $label, actual => $before->[0], expected => $before->[1], passed => $passed ? 1 : 0}
            if $caller->[0] eq 'main';
        return $passed;
    };
    local $SIG{__WARN__} = sub {push @warnings, @_; CORE::warn(@_)};
    my $ok = do './t/1986-isf-record-port-value-gates.t';
    $test_error = $@; $test_errno = "$!";
    $test_loaded = defined($ok) ? 1 : 0;
}
my $encoded = $json->encode({mode => $mode, trials => \@trials, copy_assertions => \@copy_assertions,
    test_run => {completed => $test_loaded, error => $test_error, errno => $test_errno},
    api => \@api, copies => \@copies, helpers => \@helpers,
    consumers => \@consumers, parses => \@parses, warnings => \@warnings,
    host => {perl => "$^V", storable => $Storable::VERSION, json_pp => $JSON::PP::VERSION}});
open my $out, '>:raw', $output or die $!;
print {$out} $encoded, "\n" or die $!;
close $out or die $!;
die $test_error if length $test_error;
die $test_errno unless $test_loaded;
