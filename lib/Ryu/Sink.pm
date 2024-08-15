package Ryu::Sink;

use strict;
use warnings;

use parent qw(Ryu::Node);

# VERSION
# AUTHORITY

=head1 NAME

Ryu::Sink - base representation for a thing that receives events

=head1 DESCRIPTION

This is currently of limited utility.

 my $src = Ryu::Source->new;
 my $sink = Ryu::Sink->new;
 $sink->from($src);
 $sink->source->say;

=cut

use Future;
use Log::Any qw($log);

=head1 METHODS

=cut

sub new {
    my $class = shift;
    $class->SUPER::new(
        sources => [],
        @_
    )
}

=head2 from

Given a source, will attach it as the input for this sink.

The key difference between L</from> and L</drain_from> is that this method will mark the sink as completed
when the source is finished. L</drain_from> allows sequencing of multiple sources, keeping the sink active
as each of those completes.

=cut

sub from {
    my ($self, $src, %args) = @_;

    die 'expected a subclass of Ryu::Source, received ' . $src . ' instead' unless $src->isa('Ryu::Source');

    $self = $self->new unless ref $self;
    $self->drain_from($src);
    $src->completed->on_ready(sub {
        my $f = $self->source->completed;
        shift->on_ready($f) unless $f->is_ready;
    });
    return $self
}

sub drain_from {
    my ($self, $src) = @_;
    die 'expected a subclass of Ryu::Source, received ' . $src . ' instead' unless $src->isa('Ryu::Source');

    push $self->{sources}->@*, $src;
    $self->start_drain;
    $self->source->emit($data);
    $self
}

sub start_drain {
    my ($self) = @_;
    return $self if $self->is_draining;

    my $src = shift $self->{sources}->@*
        or return $self;

    $self->{active_source} = $src;
    $src->each_while_source(sub {
        $self->emit($_)
    }, $self->source);
    $src->completed->on_ready(sub {
        my $f = $self->source->completed;
        shift->on_ready($f) unless $f->is_ready;
        undef $self->{active_source};
        $self->start_drain;
    });
}

sub is_draining { !!shift->{active_source} }

sub emit {
    my ($self, $data) = @_;
    $self->source->emit($data);
    $self
}

sub source {
    my ($self) = @_;
    $self->{source} //= do {
        my $src = ($self->{new_source} //= sub { Ryu::Source->new })->();
        Scalar::Util::weaken($src->{parent} = $self);
        $src;
    };
}

sub _completed { shift->source->_completed }

sub notify_child_completion { }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2024. Licensed under the same terms as Perl itself.

