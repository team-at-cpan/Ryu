package Ryu::Node;

use strict;
use warnings;

=head1 NAME

Ryu::Node - generic node

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=head1 METHODS

=cut

sub new { bless { @_[1..$#_] }, $_[0] }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2015. Licensed under the same terms as Perl itself.

