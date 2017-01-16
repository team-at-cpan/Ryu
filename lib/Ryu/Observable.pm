package Ryu::Observable;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Ryu::Observable - plus ça change

=head1 DESCRIPTION

This module is still of no great use to you in its current state.

=cut

use overload
	'""'   => sub { shift->as_string },
	'0+'   => sub { shift->as_number },
	'++'   => sub { my $v = ++$_[0]->{value}; $_[0]->notify_all; $v },
	'--'   => sub { my $v = --$_[0]->{value}; $_[0]->notify_all; $v },
	'bool' => sub { shift->as_number },
	fallback => 1;

=head2 as_string
	
=cut

sub as_string { '' . shift->{value} }

=head2 as_number

=cut

sub as_number { 0 + shift->{value} }

=head2 new

=cut

sub new { bless { value => $_[1] }, $_[0] }

=head2 subscribe

=cut

sub subscribe { my $self = shift; push @{$self->{subscriptions}}, @_; $self }

=head2 notify_all

=cut

sub notify_all {
	my $self = shift;
	for my $sub (@{$self->{subscriptions}}) {
		$sub->($_) for $self->{value}
	}
	$self
}

=head2 set

=cut

sub set { my ($self, $v) = @_; $self->{value} = $v; $self->notify_all }

=head2 set_numeric

Applies a new numeric value, and notifies subscribers if the value is numerically
different to the previous one (or if we had no previous value).

Returns C<$self>.

=cut

sub set_numeric {
	my ($self, $v) = @_;
	my $prev = $self->{value};
	return $self if defined($prev) && $prev == $v;
	$self->{value} = $v;
	$self->notify_all
}

=head2 set_string

Applies a new string value, and notifies subscribers if the value stringifies to a
different value than the previous one (or if we had no previous value).

Returns C<$self>.

=cut

sub set_string {
	my ($self, $v) = @_;
	my $prev = $self->{value};
	return $self if defined($prev) && $prev eq $v;
	$self->{value} = $v;
	$self->notify_all
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2016. Licensed under the same terms as Perl itself.

