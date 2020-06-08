use strict;
use warnings;

use Test::More;

use Ryu::Buffer;

my $buffer = new_ok('Ryu::Buffer');
is($buffer->size, 0, 'starts with nothing it in');
ok($buffer->is_empty, 'which means it is empty');
ok($buffer->write('test'), 'can write some data');
ok(!$buffer->is_empty, 'which means it is no longer empty');
{
    isa_ok(my $f = $buffer->read_exactly(2), 'Future');
    ok($f->is_ready, 'read when data already exists');
    is($f->get, 'te', 'data is correct');
}
{
    isa_ok(my $f = $buffer->read_exactly(2), 'Future');
    ok($f->is_ready, 'read when data already exists');
    is($f->get, 'st', 'data is correct');
}
{
    isa_ok(my $f = $buffer->read_exactly(2), 'Future');
    ok(!$f->is_ready, 'not ready yet');
    $buffer->write('!');
    ok(!$f->is_ready, 'not ready yet');
    $buffer->write('!');
    ok($f->is_ready, 'read when data already exists');
    is($f->get, '!!', 'data is correct');
}
{
    isa_ok(my $f = $buffer->read_until("\x0D\x0A"), 'Future');
    ok(!$f->is_ready, 'not ready yet');
    $buffer->write('example');
    ok(!$f->is_ready, 'not ready yet');
    $buffer->write(' text');
    ok(!$f->is_ready, 'not ready yet');
    $buffer->write(" here\x0D");
    ok(!$f->is_ready, 'not ready yet');
    $buffer->write("\x0A...");
    ok($f->is_ready, 'read when data already exists');
    is($f->get, "example text here\x0D\x0A", 'data is correct');
    ok(!$buffer->is_empty, 'still not empty');
}

done_testing;

