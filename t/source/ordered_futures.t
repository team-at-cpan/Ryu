
use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;
use Future;

my $src = Ryu::Source->new;
my @actual;
my $ordered = $src->ordered_futures->each(sub {
    push @actual, $_;
});
my @f = map Future->new, 0..2;
$src->emit(@f);
ok(!$ordered->completed->is_ready, 'ordered futures not yet complete');
$f[$_]->done($_) for 1, 2;
ok(!$ordered->completed->is_ready, 'ordered futures still not complete');
$src->finish;
ok(!$ordered->completed->is_ready, 'ordered futures still not complete');
$f[0]->done(0);
ok($ordered->completed->is_done, 'ordered futures complete after all Futures resolved');
cmp_deeply(\@actual, [ 1,2,0 ], 'ordered_futures operation was performed');


subtest 'One of the emited itemes has faild' => sub {
    my $src = Ryu::Source->new;
    my $ordered = $src->ordered_futures;
    my @f = map Future->new, 0..2;
    $src->emit(@f);
    ok(!$ordered->completed->is_ready, 'ordered futures not yet complete');
    $f[0]->fail("Item has faild");
    ok($ordered->completed->is_failed, 'ordered futures has faild');
    ok($src->completed->is_cancelled, 'source has canceled');
    ok $_->is_cancelled, "The pending item has canceled" for map {$f[$_]} (1,2);
    
};

done_testing;
