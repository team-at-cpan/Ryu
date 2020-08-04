# NAME

Ryu - asynchronous stream building blocks

# SYNOPSIS

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use Ryu qw($ryu);
    my ($lines) =
           $ryu->from(\*STDIN)
                   ->by_line
                   ->filter(qr/\h/)
                   ->count
                   ->get;
    print "Had $lines line(s) containing whitespace\n";

# DESCRIPTION

Provides data flow processing for asynchronous coding purposes. It's a bit like [ReactiveX](https://reactivex.io) in
concept. Where possible, it tries to provide a similar API. It is not a directly-compatible implementation, however.

For more information, start with [Ryu::Source](https://metacpan.org/pod/Ryu%3A%3ASource). That's where most of the
useful parts are.

## Why would I be using this?

Eventually some documentation pages might appear, but at the moment they're unlikely to exist.

- Network protocol implementations - if you're bored of stringing together `substr`, `pack`, `unpack`
and `vec`, try [Ryu::Manual::Protocol](https://metacpan.org/pod/Ryu%3A%3AManual%3A%3AProtocol) or [Ryu::Buffer](https://metacpan.org/pod/Ryu%3A%3ABuffer).
- Extract, Transform, Load workflows (ETL) - need to pull data from somewhere, mangle it into shape, push it to
a database? that'd be [Ryu::Manual::ETL](https://metacpan.org/pod/Ryu%3A%3AManual%3A%3AETL)
- Reactive event handling - [Ryu::Manual::Reactive](https://metacpan.org/pod/Ryu%3A%3AManual%3A%3AReactive)

As an expert software developer with a keen eye for useful code, you may already be bored of this documentation
and on the verge of reaching for alternatives. The ["SEE ALSO"](#see-also) section may speed you on your way.

## Compatibility

Since [Mojo::Rx](https://metacpan.org/pod/Mojo%3A%3ARx) follows the ReactiveX conventions quite closely, we'd expect to have
the ability to connect [Mojo::Rx](https://metacpan.org/pod/Mojo%3A%3ARx) observable to a [Ryu::Source](https://metacpan.org/pod/Ryu%3A%3ASource), and provide an
adapter from a [Ryu::Source](https://metacpan.org/pod/Ryu%3A%3ASource) to act as a [Mojo::Rx](https://metacpan.org/pod/Mojo%3A%3ARx)-style observable. This is not yet
implemented, but planned for a future version.

Most of the other modules in ["SEE ALSO"](#see-also) are either not used widely enough or not a good
semantic fit for a compatibility layer - but if you're interested in this, [please ask](https://github.com/team-at-cpan/Ryu/issues).

## Components

### Sources

A source emits items. See [Ryu::Source](https://metacpan.org/pod/Ryu%3A%3ASource). If in doubt, this is likely to be the class
that you wanted.

Items can be any scalar value - some examples:

- a single byte
- a character
- a byte string
- a character string
- an object instance
- an arrayref or hashref

### Sinks

A sink receives items. It's the counterpart to a source. See [Ryu::Sink](https://metacpan.org/pod/Ryu%3A%3ASink).

### Streams

A stream is a thing with a source. See [Ryu::Stream](https://metacpan.org/pod/Ryu%3A%3AStream), which is likely to be something that does not yet
have much documentation - in practice, the [Ryu::Source](https://metacpan.org/pod/Ryu%3A%3ASource) implementation covers most use-cases.

## So what does this module do?

Nothing. It's just a top-level loader for pulling in all the other components.
You wanted [Ryu::Source](https://metacpan.org/pod/Ryu%3A%3ASource) instead, or possibly [Ryu::Buffer](https://metacpan.org/pod/Ryu%3A%3ABuffer).

## Some notes that might not relate to anything

With a single parameter, ["from"](#from) and ["to"](#to) will use the given
instance as a [Ryu::Source](https://metacpan.org/pod/Ryu%3A%3ASource) or [Ryu::Sink](https://metacpan.org/pod/Ryu%3A%3ASink) respectively.

Multiple parameters are a shortcut for instantiating the given source
or sink:

    my $stream = Ryu::Stream->from(
     file => 'somefile.bin'
    );

is equivalent to

    my $stream = Ryu::Stream->from(
     Ryu::Source->new(
      file => 'somefile.bin'
     )
    );

# Why the name?

- ` $ryu ` lines up with typical 4-character indentation settings.
- there's Rx for other languages, and this is based on the same ideas
- 流 was too hard for me to type

# METHODS

Note that you're more likely to find useful methods in the following classes:

- [Ryu::Source](https://metacpan.org/pod/Ryu%3A%3ASource)
- [Ryu::Sink](https://metacpan.org/pod/Ryu%3A%3ASink)
- [Ryu::Observable](https://metacpan.org/pod/Ryu%3A%3AObservable)

## new

Instantiates a [Ryu](https://metacpan.org/pod/Ryu) object, allowing ["from"](#from), ["just"](#just) and other methods.

## from

Helper method which returns a [Ryu::Source](https://metacpan.org/pod/Ryu%3A%3ASource) from a list of items.

## just

Helper method which returns a single-item [Ryu::Source](https://metacpan.org/pod/Ryu%3A%3ASource).

# SEE ALSO

## Other modules

Some perl modules of relevance:

- [Future](https://metacpan.org/pod/Future) - fundamental building block for one-shot tasks
- [Future::Queue](https://metacpan.org/pod/Future%3A%3AQueue) - a FIFO queue for [Future](https://metacpan.org/pod/Future) tasks
- [Future::Buffer](https://metacpan.org/pod/Future%3A%3ABuffer) - provides equivalent functionality to [Ryu::Buffer](https://metacpan.org/pod/Ryu%3A%3ABuffer)
- [POE::Filter](https://metacpan.org/pod/POE%3A%3AFilter) - venerable and battle-tested, but slightly short on features due to the focus on protocols
- [Data::Transform](https://metacpan.org/pod/Data%3A%3ATransform) - standalone version of [POE::Filter](https://metacpan.org/pod/POE%3A%3AFilter)
- [List::Gen](https://metacpan.org/pod/List%3A%3AGen) - list mangling features
- [HOP::Stream](https://metacpan.org/pod/HOP%3A%3AStream) - based on the Higher Order Perl book
- [Flow](https://metacpan.org/pod/Flow) - quite similar in concept to this module, maybe a bit short on documentation, doesn't provide integration with other sources such as files or [IO::Async::Stream](https://metacpan.org/pod/IO%3A%3AAsync%3A%3AStream)
- [Flux](https://metacpan.org/pod/Flux) - more like the java8 streams API, sync-based
- [Message::Passing](https://metacpan.org/pod/Message%3A%3APassing) - on initial glance seemed more of a commandline tool, sadly based on [AnyEvent](https://metacpan.org/pod/AnyEvent)
- [Rx.pl](https://github.com/eilara/Rx.pl) - a Perl version of the [http://reactivex.io](http://reactivex.io) Reactive API
- [Perlude](https://metacpan.org/pod/Perlude) - combines features of the shell / UNIX streams and Haskell, pipeline
syntax is "backwards" (same as grep/map chains in Perl)
- [IO::Pipeline](https://metacpan.org/pod/IO%3A%3APipeline)
- [DS](https://metacpan.org/pod/DS)
- [Evo](https://metacpan.org/pod/Evo)
- [Async::Stream](https://metacpan.org/pod/Async%3A%3AStream) - early release, but seems to be very similar in concept to [Ryu::Source](https://metacpan.org/pod/Ryu%3A%3ASource)
- [Data::Monad](https://metacpan.org/pod/Data%3A%3AMonad)
- [Mojo::Rx](https://metacpan.org/pod/Mojo%3A%3ARx) - Mojolicious-specific support for ReactiveX, follows the rxjs API quite closely
- [RxPerl](https://metacpan.org/pod/RxPerl) - same author as [Mojo::Rx](https://metacpan.org/pod/Mojo%3A%3ARx), this (will eventually!) provide a ReactiveX API without being tied to Mojolicious

## Other references

There are various documents, specifications and discussions relating to the concepts we use. Here's a few:

- [http://www.reactivemanifesto.org/](http://www.reactivemanifesto.org/)
- Java 8 [streams API](https://docs.oracle.com/javase/8/docs/api/java/util/stream/package-summary.html)
- C++ [range-v3](https://github.com/ericniebler/range-v3)

# AUTHOR

Tom Molesworth `<TEAM@cpan.org>` with contributions from Mohammad S Anwar,
Michael Mueller, Zak Elep, Mohanad Zarzour and Nael Alolwani.

# LICENSE

Copyright Tom Molesworth 2011-2020. Licensed under the same terms as Perl itself.
