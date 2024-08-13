package Domain::Entities::Customer;

use strict;
use warnings;

sub new {
    my ($class, $customer_id, $first_name, $last_name) = @_;
    my $self = {
        customer_id => $customer_id,
        first_name  => $first_name,
        last_name   => $last_name,
    };
    bless $self, $class;
    return $self;
}

sub customer_id { $_[0]->{customer_id} }
sub first_name  { $_[0]->{first_name} }
sub last_name   { $_[0]->{last_name} }

1;
