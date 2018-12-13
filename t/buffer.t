use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $src = new_ok('Ryu::Source');
my $buffered = $src->buffer(3);
my $target = $buffered->count;
my @received;
$target->each(sub { push @received, $_ });
cmp_deeply(\@received, [], 'start with no items');
$src->emit('x');
cmp_deeply(\@received, ['x'], 'have one item');
$target->pause;
$src->emit('y');
cmp_deeply(\@received, ['x'], 'still that one item');
$target->resume;
cmp_deeply(\@received, ['x', 'y'], 'now have the next item');
$src->finish;
$target->

is(exception {
    my $chained = Ryu::Source->chained;
    isa_ok($chained, 'Ryu::Source');
    is($chained->label, 'unknown', 'starts off with "unknown" label');
    is($chained->parent, undef, 'has no parent');
}, undef, 'can create ->chained source without issues');

done_testing;


