requires 'parent', 0;
requires 'curry', 0;
requires 'Future', '>= 0.30';
requires 'Mixin::Event::Dispatch', '>= 2.000';

on 'test' => sub {
	requires 'Test::More', '>= 0.98';
	requires 'Test::Fatal', '>= 0.010';
	requires 'Test::Refcount', '>= 0.07';
};

