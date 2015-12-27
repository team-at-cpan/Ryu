package Ryu::Exception;

use strict;
use warnings;

=head1 NAME

Ryu::Exception

=head1 SYNOPSIS

 use Ryu::Exception;
 my $exception = Ryu::Exception->new(
  type => 'http',
  message => '404 response'
  details => [ $response, $request ]
 );
 Future->fail($exception->failure);

=cut

use Future;

sub new { bless { @_[1..$#_] }, $_[0] }

sub throw { die shift }

sub type { shift->{type} }

sub message { shift->{message} }

sub details { @{ shift->{details} || [] } }

sub fail {
	use Scalar::Util qw(blessed);
	use namespace::clean qw(blessed);
	my ($self, $f) = @_;
	die "expects a Future" unless blessed($f) && $f->isa('Future');
	return $self->future->on_ready($f);
}

sub future {
	my ($self) = @_;
	return Future->fail($self->message, $self->type, $self->details);
}

sub from_future {
	use Scalar::Util qw(blessed);
	use namespace::clean qw(blessed);
	my ($class, $f) = @_;
	die "expects a Future" unless blessed($f) && $f->isa('Future');
	die "Future is not ready" unless $f->is_ready;
	my ($msg, $type, @details) = $f->failure or die "Future is not failed?";
	$class->new(
		message => $msg,
		type => $type,
		details => \@details
	)
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2015. Licensed under the same terms as Perl itself.

