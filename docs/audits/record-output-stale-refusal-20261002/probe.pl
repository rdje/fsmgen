use strict;
use warnings;
use lib 'perl', 't/lib';
use JSON::PP;
use FSM::Adapter::ISF;

my $parser = FSM::Adapter::ISF->new;
my @products;
for my $case (
    ['whole-output', 'output', 'frame', '(complete done)'],
    ['output-field', 'output', 'frame', '(set value.flag 1)'],
    ['input-list', 'input', 'lanes', '(complete done)'],
) {
    my ($name, $direction, $type, $clause) = @$case;
    my $source = '(actor refused (types (type frame (record (flag bit))) (type lanes (list bit bit)))'
        . " (interface ($direction value (type $type)) (output done))"
        . " (transaction main $clause))";
    my $actor;
    my $accepted = eval {$actor = $parser->parse_source($source, 'still-refused.isf'); 1};
    my $error = $@;
    push @products, {name => $name, source => $source, actor => $actor,
        accepted => $accepted ? 1 : 0, error => $error};
}
print JSON::PP->new->canonical->encode(\@products) . "\n";
