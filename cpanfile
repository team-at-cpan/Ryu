requires 'parent', 0;
requires 'curry', 0;
requires 'Future', '>= 0.30';
requires 'Mixin::Event::Dispatch', '>= 2.000';
requires 'Log::Any', '>= 1.032';
requires 'Syntax::Keyword::Try', '>= 0.04';
requires 'namespace::clean', '>= 0.27';

recommends 'Check::UnitCheck', '>= 0.13';

requires 'Encode', '>= 1.98';
requires 'MIME::Base64', 0;
requires 'JSON::MaybeXS', 0;
requires 'JSON::SL', '>= 1.0.6';

on 'test' => sub {
	requires 'Test::More', '>= 0.98';
	requires 'Test::Deep', '>= 1.124';
	requires 'Test::Fatal', '>= 0.010';
	requires 'Test::Refcount', '>= 0.07';
	requires 'Test::Warnings', '>= 0.024';
	requires 'Test::Files', '>= 0.14';
	requires 'Log::Any::Adapter::TAP', '>= 0.003002';

	recommends 'Test::HexString', '>= 0.03';
};

