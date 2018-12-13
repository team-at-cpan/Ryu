package Ryu::Node;

use strict;
use warnings;

# VERSION

=head1 NAME

Ryu::Node - generic node

=head1 DESCRIPTION

This is a common base class for all sources, sinks and other related things.
It does very little.

=cut

=head1 METHODS

Not really. There's a constructor, but that's not particularly exciting.

=cut

sub new { bless { @_[1..$#_] }, $_[0] }

=head2 pause

Does nothing useful.

=cut

sub pause {
    my $self = shift;
    $self->{is_paused} = 1;
    $self
}

=head2 resume

Is about as much use as L</pause>.

=cut

sub resume {
    my $self = shift;
    $self->{is_paused} = 0;
    $self
}

=head2 is_paused

Might return 1 or 0, but is generally meaningless.

=cut

sub is_paused { $_[0]->{is_paused} }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2018. Licensed under the same terms as Perl itself.

