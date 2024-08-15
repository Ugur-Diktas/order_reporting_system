package Domain::Entities::Order;

use strict;
use warnings;

sub new {
    my ($class, $order_id, $order_number, $order_date, $customer_id, $item_id) = @_;
    my $self = {
        order_id     => $order_id,
        order_number => $order_number,
        order_date   => $order_date,
        customer_id  => $customer_id,
        item_id      => $item_id,
    };
    bless $self, $class;
    return $self;
}

sub order_id     { $_[0]->{order_id} }
sub order_number { $_[0]->{order_number} }
sub order_date   { $_[0]->{order_date} }
sub customer_id  { $_[0]->{customer_id} }
sub item_id      { $_[0]->{item_id} }

1;
