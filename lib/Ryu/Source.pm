package Ryu::Source;

use strict;
use warnings;

use parent qw(Ryu::Node);

=head1 NAME

Ryu::Source - base representation for a source of events

=head1 DESCRIPTION

This is probably the module you'd want to start with, if you were going to be
using any of this. There's a disclaimer in L<Ryu> that may be relevant at this
point.

=cut

use Future;
use Syntax::Keyword::Try;
use curry::weak;

use Log::Any qw($log);

=head1 GLOBALS

=head2 $FUTURE_FACTORY

This is a coderef which should return a new L<Future>-compatible instance.

Example overrides might include:

 $Ryu::Source::FUTURE_FACTORY = sub { Mojo::Future->new->set_label(shift) };

=cut

our $FUTURE_FACTORY = sub {
	Future->new->set_label($_[1])
};

# It'd be nice if L<Future> already provided a method for this, maybe I should suggest it
my $future_state = sub {
      $_[0]->is_done
    ? 'done'
    : $_[0]->is_failed
    ? 'failed'
    : $_[0]->is_cancelled
    ? 'cancelled'
    : 'pending'
};

=head1 METHODS

=head2 new

Takes named parameters.

=cut

sub new {
    my ($self, %args) = @_;
    $args{label} //= 'unknown';
    $self->SUPER::new(%args);
}

=head2 chained

Returns a new L<Ryu::Source> chained from this one.

=cut

sub chained {
	use Scalar::Util qw(weaken);
    use namespace::clean qw(weaken);

	my ($self) = shift;
	if(my $class = ref($self)) {
		my $src = $class->new(
			new_future => $self->{new_future},
			parent     => $self,
			@_
		);
        weaken($src->{parent});
        push @{$self->{children}}, $src;
        $log->tracef("Constructing chained source for %s from %s (%s)", $src->label, $self->label, $future_state->($self->completed));
        return $src;
	} else {
		my $src = $self->new(@_);
        $log->tracef("Constructing chained source for %s with no parent", $src->label, $self->label);
	}
}

=head2 describe

Returns a string describing this source and any parents - typically this will result in a chain
like C<< from->combine_latest->count >>.

=cut

sub describe {
    my ($self) = @_;
    ($self->parent ? $self->parent->describe . '=>' : '') . $self->label . '(' . $future_state->($self->completed) . ')';
}

=head2 from

Creates a new source from things.

The precise details of what this method supports may be somewhat ill-defined at this point in time.
It is expected that the interface and internals of this method will vary greatly in versions to come.

=cut

sub from {
	my $class = shift;
	my $src = (ref $class) ? $class : $class->new;
	if(my $ref = ref($_[0])) {
		if($ref eq 'GLOB') {
			if(my $fh = *{$_[0]}{IO}) {
				my $code = sub {
					while(read $fh, my $buf, 4096) {
						$src->emit($buf)
					}
					$src->finish
				};
				$src->{on_get} = $code;
				return $src;
			} else {
				die "whatever"
			}
		}
		die "unsupported ref type $ref";
	} else {
        die "unknown item in ->from";
    }
}

=head2 empty

Creates an empty source, which finishes immediately.

=cut

sub empty {
	my ($self, $code) = @_;

	my $src = $self->chained(label => (caller 0)[3]);
    $src->finish;
}

=head2 never

An empty source that never finishes.

=cut

sub never {
	my ($self, $code) = @_;

	my $src = $self->chained(label => (caller 0)[3]);
}

=head2 throw

Throws something. I don't know what, maybe a chair.

=cut

sub throw {
	my $src = shift->new(@_);
	$src->fail('...');
}

=head1 METHODS - Instance

=cut

=head2 new_future

Used internally to get a L<Future>.

=cut

sub new_future {
	my $self = shift;
	(
		$self->{new_future} //= $FUTURE_FACTORY
	)->($self, @_)
}

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

=head2 debounce

Not yet implemented.

=cut

sub debounce {
	my ($self, $interval) = @_;
	...
}

=head2 chomp

Chomps all items with the current delimiter.

Once you've instantiated this, it will stick with the delimiter which was in force at the time of instantiation.
Said delimiter follows the usual rules of C<< $/ >>, whatever they happen to be.

=cut

sub chomp {
	my ($self, $delim) = @_;
	$delim //= $/;
	$self->map(sub {
        local $/ = $delim;
		chomp(my $line = $_);
		$line
	})
}

=head2 map

A bit like L<perlfunc/map>.

=cut

sub map : method {
	my ($self, $code) = @_;

	my $src = $self->chained(label => (caller 0)[3]);
	$self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
	$self->each_while_source(sub { $src->emit($code->($_)) }, $src);
}

sub split : method {
	my ($self, $delim) = @_;
	$delim //= qr//;

	my $src = $self->chained(label => (caller 0)[3]);
	$self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
	$self->each_while_source(sub { $src->emit($_) for split $delim, $_ }, $src);
}

sub chunksize : method {
	my ($self, $size) = @_;
    die 'need positive chunk size parameter' unless $size && $size > 0;

	my $buffer = '';
	my $src = $self->chained(label => (caller 0)[3]);
	$self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
	$self->each_while_source(sub {
        $buffer .= $_;
        $src->emit(substr $buffer, 0, $size, '') while length($buffer) >= $size;
    }, $src);
}

sub by_line : method {
	my ($self, $delim) = @_;
	$delim //= $/;

	my $src = $self->chained(label => (caller 0)[3]);
	my $buffer = '';
	$self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
	$self->each_while_source(sub {
		$buffer .= $_;
		while($buffer =~ s/^(.*)\Q$delim//) {
			$src->emit($1)
		}
	}, $src);
}

=head2 combine_latest

=cut

sub combine_latest : method {
	use Scalar::Util qw(blessed);
	use namespace::clean qw(blessed);
	my ($self, @sources) = @_;
	push @sources, sub { @_ } if blessed $sources[-1];
	my $code = pop @sources;

	my $combined = $self->chained(label => (caller 0)[3]);
	unshift @sources, $self if ref $self;
	my @value;
	my %seen;
	for my $idx (0..$#sources) {
		my $src = $sources[$idx];
		$src->each(sub {
			return if $combined->completed->is_ready;
			$value[$idx] = $_;
			$seen{$idx} ||= 1;
			$combined->emit([ $code->(@value) ]) if @sources == keys %seen;
		});
	}
	Future->needs_any(
		map $_->completed, @sources
	)->on_ready($combined->completed);
	$combined
}

sub with_latest_from : method {
	use Scalar::Util qw(blessed);
	use namespace::clean qw(blessed);
	my ($self, @sources) = @_;
	push @sources, sub { @_ } if blessed $sources[-1];
	my $code = pop @sources;

	my $combined = $self->chained(label => (caller 0)[3]);
	my @value;
	my %seen;
	for my $idx (0..$#sources) {
		my $src = $sources[$idx];
		$src->each(sub {
			return if $combined->completed->is_ready;
			$value[$idx] = $_;
			$seen{$idx} ||= 1;
		});
	}
	$self->each(sub {
		$combined->emit([ $code->(@value) ]) if keys %seen;
	});
	$self->completed->on_ready($combined->completed);
	$self->completed->on_ready(sub {
        return if $combined->is_ready;
        shift->on_ready($combined->completed);
    });
	$combined
}

=head2 merge

=cut

sub merge : method {
	my ($self, @sources) = @_;

	my $combined = $self->chained(label => (caller 0)[3]);
	unshift @sources, $self if ref $self;
	for my $src (@sources) {
		$src->each(sub {
			return if $combined->completed->is_ready;
			$combined->emit($_)
		});
	}
	Future->needs_all(
		map $_->completed, @sources
	)->on_ready($combined->completed);
	$combined
}

=head2 distinct

=cut

sub distinct {
	my $self = shift;

	my $src = $self->chained(label => (caller 0)[3]);
	$self->completed->on_ready($src->completed);
	$self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
	my $active;
	my $prev;
	$self->each(sub {
		if($active) {
			if(defined($prev) ^ defined($_)) {
				$src->emit($_) 
			} elsif(defined($_)) {
				$src->emit($_) if $prev ne $_;
			}
		} else {
			$active = 1;
			$src->emit($_);
		}
		$prev = $_;
	});
	$src
}

=head2 skip

=cut

sub skip {
	my ($self, $count) = @_;
	$count //= 0;

	my $src = $self->chained(label => (caller 0)[3]);
	$self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
	$self->each(sub {
		$src->emit($_) unless $count-- > 0;
	});
	$src
}

=head2 skip_last

=cut

sub skip_last {
	my ($self, $count) = @_;
	$count //= 0;

	my $src = $self->chained(label => (caller 0)[3]);
	$self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
	my @pending;
	$self->each(sub {
		push @pending, $_;
		$src->emit(shift @pending) if @pending > $count;
	});
	$src
}

=head2 take

=cut

sub take {
	my ($self, $count) = @_;
    $count //= 0;
    return $self->empty unless $count > 0;

	my $src = $self->chained(label => (caller 0)[3]);
	$self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
    # $self->completed->on_ready($src->completed);
	$self->each_while_source(sub {
        $log->tracef("Still alive with %d remaining", $count);
        $src->emit($_);
        return if --$count;
        $log->tracef("Count is zero, finishing");
        $src->finish
	}, $src);
}

sub each_while_source {
	use Scalar::Util qw(refaddr);
	use List::UtilsBy qw(extract_by);
	use namespace::clean qw(refaddr extract_by);
    my ($self, $code, $src) = @_;
	$self->each($code);
	$src->completed->on_ready(sub {
        my $count = extract_by { refaddr($_) == refaddr($code) } @{$self->{on_item}};
        $log->tracef("->e_w_s completed on %s for refaddr 0x%x", $self->describe, refaddr($self));
    });
	$src
}

=head2 some

=cut

sub some {
	my ($self, $code) = @_;

	my $src = $self->chained(label => (caller 0)[3]);
	$self->completed->on_ready(sub {
		my $sf = $src->completed;
		return if $sf->is_ready;
		my $f = shift;
		return $f->on_ready($sf) unless $f->is_done;
		$src->emit(0);
		$sf->done;
	});
	$self->each(sub {
		return if $src->completed->is_ready;
		return unless $code->($_);
		$src->emit(1);
		$src->completed->done 
	});
	$src
}

=head2 every

=cut

sub every {
	my ($self, $code) = @_;

	my $src = $self->chained(label => (caller 0)[3]);
	$self->completed->on_done(sub {
		return if $src->completed->is_ready;
		$src->emit(1);
		$src->completed->done 
	});
	$self->each(sub {
		return if $src->completed->is_ready;
		return if $code->($_);
		$src->emit(0);
		$src->completed->done 
	});
	$src
}

=head2 count

=cut

sub count {
	my ($self) = @_;

	my $count = 0;

	my $src = $self->chained(label => (caller 0)[3]);
	$self->each(sub { ++$count });
	$self->completed->on_done(sub { $src->emit($count) })
		->on_ready($src->completed);
	$src
}

=head2 sum

=cut

sub sum {
	my ($self) = @_;

	my $sum = 0;

	my $src = $self->chained(label => (caller 0)[3]);
	$self->each(sub { $sum += $_ });
	$self->completed->on_done(sub { $src->emit($sum) })
		->on_ready($src->completed);
	$src
}

=head2 mean

=cut

sub mean {
	my ($self) = @_;

	my $sum = 0;
	my $count = 0;

	my $src = $self->chained(label => (caller 0)[3]);
	$self->each(sub { ++$count; $sum += $_ });
	$self->completed->on_done(sub { $src->emit($sum / ($count || 1)) })
		->on_ready($src->completed);
	$src
}

=head2 max

=cut

sub max {
	my ($self) = @_;

	my $src = $self->chained(label => (caller 0)[3]);
	my $max;
	$self->each(sub {
		return if defined $max and $max > $_;
		$max = $_;
	});
	$self->completed->on_done(sub { $src->emit($max) })
		->on_ready($src->completed);
	$src
}

=head2 min

=cut

sub min {
	my ($self) = @_;

	my $src = $self->chained(label => (caller 0)[3]);
	my $min;
	$self->each(sub {
		return if defined $min and $min < $_;
		$min = $_;
	});
	$self->completed->on_done(sub { $src->emit($min) })
		->on_ready($src->completed);
	$src
}

=head2 statistics

Emits a single hashref of statistics once the source completes.

=cut

sub statistics {
	my ($self) = @_;

	my $sum = 0;
	my $count = 0;
	my $min;
	my $max;

	my $src = $self->chained(label => (caller 0)[3]);
	$self->each(sub {
        $min //= $_;
        $max //= $_;
        $min = $_ if $_ < $min;
        $max = $_ if $_ > $max;
		++$count;
		$sum += $_
	});
	$self->completed->on_done(sub {
		$src->emit({
			count => $count,
			sum   => $sum,
			min   => $min,
			max   => $max,
			mean  => ($sum / ($count || 1))
		})
	})
		->on_ready($src->completed);
	$src
}

=head2 filter

=cut

sub filter {
	use Scalar::Util qw(blessed);
	use namespace::clean qw(blessed);
	my $self = shift;

	my $src = $self->chained(label => (caller 0)[3]);
	$self->completed->on_ready(sub {
        return if $src->is_ready;
        shift->on_ready($src->completed);
    });
    $self->each_while_source((@_ > 1) ? do {
		my %args = @_;
		my $check = sub {
			my ($k, $v) = @_;
			if(my $ref = ref $args{$k}) {
				if($ref eq 'Regexp') {
					return 0 unless $v =~ $args{$k};
				} elsif($ref eq 'CODE') {
					return 0 for grep !$args{$k}->($_), $v;
				} else {
					die "Unsure what to do with $args{$k} which seems to be a $ref";
				}
			} else {
				return 0 unless $v eq $args{$k};
			}
			return 1;
		};
		sub {
			my $item = shift;
			if(blessed $item) {
				for my $k (keys %args) {
					my $v = $item->$k;
					return unless $check->($k, $v);
				}
			} elsif(my $ref = ref $item) {
				if($ref eq 'HASH') {
					for my $k (keys %args) {
						my $v = $item->{$k};
						return unless $check->($k, $v);
					}
				} else {
					die 'not a ref we know how to handle: ' . $ref;
				}
			} else {
				die 'not a ref, not sure what to do now';
			}
			$src->emit($item);
		}
	} : do {
		my $code = shift;
        if(my $ref = ref($code)) {
            if($ref eq 'Regexp') {
                my $re = $code;
                $code = sub { /$re/ };
            } elsif($ref eq 'CODE') {
                # use as-is
            } else {
                die "not sure how to handle $ref";
            }
        }
		sub {
			my $item = shift;
			$src->emit($item) if $code->($item);
		}
    }, $src);
}

=head2 emit

=cut

sub emit {
	my $self = shift;
	my $completion = $self->completed;
	for (@_) {
		for my $code (@{$self->{on_item}}) {
			die 'already completed' if $completion->is_ready;
			try {
				$code->($_);
			} catch {
                my $ex = $@;
                $log->warnf("Exception raised in %s - %s", (eval { $self->describe } // "<failed>"), "$ex");
				$completion->fail($ex, source => 'exception in on_item callback');
				die $ex;
			}
		}
	}
	$self
}

=head2 flat_map

Similar to L</map>, but will flatten out some items:

=over 4

=item * an arrayref will be expanded out to emit the individual elements

=item * for a L<Ryu::Source>, passes on any emitted elements

=back

This also means you can "merge" items from a series of sources.

Note that this is not recursive - an arrayref of arrayrefs will be expanded out
into the child arrayrefs, but no further.

=cut

sub flat_map {
	use Scalar::Util qw(blessed weaken);
    use Ref::Util qw(is_plain_arrayref is_plain_coderef);
    use namespace::clean qw(blessed is_plain_arrayref is_plain_coderef weaken);

	my ($self, $code) = splice @_, 0, 2;

    # Upgrade ->flat_map(method => args...) to a coderef
    if(!is_plain_coderef($code)) {
        my $method = $code;
        my @args = @_;
        $code = sub { $_->$method(@args) }
    }

	my $src = $self->chained(label => (caller 0)[3]);

    weaken(my $weak_sauce = $src);
    my $add = sub  {
        my $v = shift;
        my $src = $weak_sauce or return;

        my $k = "$v";
        $log->tracef("Adding %s which will bring our count to %d", $k, 0 + keys %{$src->{waiting}});
        $src->{waiting}{$k} = $v->on_ready(sub {
            return unless my $src = $weak_sauce;
            delete $src->{waiting}{$k};
            $src->finish unless %{$src->{waiting}};
        })
    };

    $add->($self->completed);
	$self->each_while_source(sub {
        my $src = $weak_sauce or return;
        for ($code->($_)) {
            my $item = $_;
            if(is_plain_arrayref($item)) {
                $log->tracef("Have an arrayref of %d items", 0 + @$item);
                for(@$item) {
                    last if $src->is_ready;
                    $src->emit($_);
                }
            } elsif(blessed($item) && $item->isa(__PACKAGE__)) {
                $log->tracef("This item is a source");
                $add->($item->completed);
                $src->on_ready(sub {
                    return if $item->is_ready;
                    $log->tracef("Marking %s as ready because %s was", $item->describe, $src->describe);
                    shift->on_ready($item->completed);
                });
                $item->each_while_source(sub {
                    my $src = $weak_sauce or return;
                    $src->emit($_)
                }, $src)->on_ready(sub {
                    undef $item;
                });
            }
        }
	}, $src);
	$src
}

=head2 each

=cut

sub each {
	my ($self, $code, %args) = @_;
	push @{$self->{on_item}}, $code;
	$self;
}

=head2 completed

=cut

sub completed {
	my ($self) = @_;
	$self->{completed} //= $self->new_future(
        'completion'
    )->on_ready(
        $self->curry::weak::cleanup
    )
}

sub cleanup {
    my ($self) = @_;
    $log->tracef("Cleanup for %s (f = %s)", $self->describe, 0 + $self->completed);
    $self->parent->notify_child_completion($self) if $self->parent;
    delete @{$self}{qw(on_item parent children)};
    $log->tracef("Finished cleanup for %s", $self->describe);
}

sub notify_child_completion {
	use List::UtilsBy qw(extract_by);
    use namespace::clean qw(extract_by);

    my ($self, $child) = @_;
    if(extract_by { $child == $_ } @{$self->{children}}) {
        $log->tracef(
            "Removed completed child %s, have %d left",
            $child->describe,
            0 + @{$self->{children}}
        );
        unless(@{$self->{children}}) {
            $log->tracef(
                "This was the last child, cancelling %s",
                $self->describe
            );
            $self->cancel unless $self->is_ready;
        }
    } else {
        $log->warnf("Child %s not found in list for %s", $child->describe, $self->describe);
    }
    $self
}

sub label { shift->{label} }

sub parent { shift->{parent} }

=head1 METHODS - Proxied

The following methods are proxied to our completion L<Future>:

=over 4

=item * then

=item * is_ready

=item * is_done

=item * failure

=item * is_cancelled

=item * else

=back

=cut

sub get {
	my ($self) = @_;
    my $f = $self->completed;
	my @rslt;
	$self->each(sub { push @rslt, $_ }) if defined wantarray;
	if(my $parent = $self->parent) {
        $parent->await
	}
	(delete $self->{on_get})->() if $self->{on_get};
	$f->transform(done => sub {
        @rslt
    })->get
}

for my $k (qw(then cancel fail on_ready transform is_ready is_done failure is_cancelled else await)) {
	do { no strict 'refs'; *$k = $_ } for sub { shift->completed->$k(@_) }
}

sub finish { shift->completed->done }

sub refresh { }

sub DESTROY {
    my ($self) = @_;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    $log->tracef("Destruction for %s", $self->describe);
    # warn "destroy for " . $self->label;
    $self->completed->cancel unless $self->completed->is_ready;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2016. Licensed under the same terms as Perl itself.

