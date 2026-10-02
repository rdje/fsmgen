from pathlib import Path
s=Path('t/2040-isf-first-when-activation-body.t').read_text()
s=s.replace('first-when-activation-body-20261002','conditional-macro-intent-20261002')
s=s.replace("my $cases = $json->decode(read_file(\"$base/cases.json\"));",'''my $cases = $json->decode(read_file("$base/cases.json"));
my %entry_refusal = map {$_ => 1} qw(first_select first_min first_max first_when_bit first_unless_bit first_when_field first_unless_field first_cond first_proc_select first_proc_when_bit first_select_zero domain_first_select first_generated_select);
my %proc_refusal = map {$_ => 1} qw(first_proc_cond later_proc_cond);
my %unsafe_entry = map {$_ => 1} qw(first_when_bit_sample first_unless_bit_sample first_when_field_sample first_unless_field_sample first_cond_sample first_bit_sample_zero domain_first_sample);
my @families = qw(select min max when_bit unless_bit when_field unless_field cond);
my @expected_names = (map {("first_$_", "later_$_")} @families,
    map {("first_${_}_sample", "later_${_}_sample")} qw(when_bit unless_bit when_field unless_field cond),
    map {("first_proc_$_", "later_proc_$_")} qw(select when_bit cond));
push @expected_names, qw(first_proc_when_sample first_when_sample first_select_zero first_bit_sample_zero initialized_select nested_select domain_first_select domain_later_select domain_first_sample first_generated_select later_generated_select);
is_deeply([sort map {$_->{name}} @$cases], [sort @expected_names], 'fixed complete actual source membership');
my %predicate = (
    when_bit => ['!=', ['&', 'datain', "3'd2"], "3'd0"],
    unless_bit => ['==', ['&', 'datain', "3'd2"], "3'd0"],
    when_field => ['==', ['&', 'datain', "3'd6"], "3'd2"],
    unless_field => ['!=', ['&', 'datain', "3'd6"], "3'd2"],
    select => 'allow', cond => 'allow', authored_when => 'allow',
    min => ['<=', 'datain', 'other'], max => ['>=', 'datain', 'other'],
);''')
s=s.replace('my $name = $case->{name};','''my $name = $case->{name};
    my $refuse = $entry_refusal{$name} || $proc_refusal{$name};
    my $expected_reason = $proc_refusal{$name}
        ? "unsupported '(cond ...)' clause in transaction body" : $reason;''')
s=s.replace('actual source $name','actual macro baseline $name')
s=s.replace('$case->{refuse}','$refuse')
s=s.replace('qr/\\Q$reason\\E/','qr/\\Q$expected_reason\\E/')
s=s.replace("'unsupported entry action cannot produce artifacts'","'owned source refusal cannot produce artifacts'")
a=s.index('                    my @assignments = ')
b=s.index('\n                }\n                for my $file ',a)
replacement='''                    my @assignments = map {@{$_->{assignments} || []}} @{$selected->{states}};
                    my @samples = $case->{body} eq 'sample'
                        ? ($case->{family} eq 'cond' ? qw(captured saved) : qw(captured)) : ();
                    my @writes;
                    if ($case->{body} eq 'set') {
                        @writes = ($case->{family} =~ /^(?:select|min|max|cond)$/) ? qw(seen seen) : qw(seen);
                        @writes = qw(result result) if ($case->{module} // '') eq 'worker';
                        unshift @writes, 'temp' if $name eq 'initialized_select';
                    }
                    is_deeply([sort map {$_->{lhs}} grep {($_->{source_kind} // '') eq 'sample_capture'} @assignments],
                        [sort @samples], 'literal complete baseline sample aliases survive');
                    is_deeply([map {$_->{lhs}} grep {($_->{source_kind} // '') eq 'set'} @assignments],
                        \\@writes, 'literal complete baseline source write order survives');
                    my $branches = $name eq 'nested_select' ? 3
                        : $unsafe_entry{$name} ? ($name eq 'first_cond_sample' ? 1 : 0)
                        : $case->{family} eq 'authored_when' ? 0
                        : $case->{family} =~ /^(?:select|min|max|cond)$/ ? 2 : 1;
                    is(scalar(grep {$_->{kind} eq 'branch'} @{$selected->{states}}), $branches,
                        $unsafe_entry{$name} ? 'actual missing macro branch intent is an owned defect, not delivery'
                            : 'literal complete admitted branch count');
                    if ($unsafe_entry{$name} || $case->{family} eq 'authored_when') {
                        is($selected->{states}[0]{kind}, 'entry', 'actual first form currently selects activation entry');
                        my $guard = $selected->{states}[0]{guard};
                        is_deeply($guard->{expr_ast} // $guard->{port}, $predicate{$case->{family}},
                            'literal actual entry predicate; macro placement remains owned');
                    } else {
                        my ($branch) = grep {$_->{kind} eq 'branch'} @{$selected->{states}};
                        is_deeply($branch->{condition}, $predicate{$case->{family}}, 'literal actual branch predicate');
                    }
                    for my $sample (grep {($_->{source_kind} // '') eq 'sample_capture'} @assignments) {
                        is($sample->{op}, '<=', 'actual sample retains register-input semantics');
                    }'''
s=s[:a]+replacement+s[b:]
s=s.replace('$ENV{FSMGEN_WHEN_CAPTURE}','$ENV{FSMGEN_MACRO_CAPTURE}')
s=s.replace('private_ir => $ir, private_error => $private_error,','private_ir => $ir, private_error => $private_error,\n                unsafe_macro_entry => !!$unsafe_entry{$name},')
Path('t/2041-isf-conditional-macro-intent-qualification.t').write_text(s)
