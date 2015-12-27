package Ryu::Observable;

use strict;
use warnings;

=head1 NAME

Ryu::Observable

=head1 SYNOPSIS

=head1 DESCRIPTION

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

sub notify_all { my $self = shift; $_->($self->{value}) for @{$self->{subscriptions}}; $self }

=head2 set

=cut

sub set { my ($self, $v) = @_; $self->{value} = $v; $self->notify_all }

1;

