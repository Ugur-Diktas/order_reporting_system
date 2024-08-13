package Domain::Entities::Item;

use strict;
use warnings;

sub new {
    my ($class, $item_id, $item_name, $manufacturer, $price, $order_id) = @_;
    my $self = {
        item_id      => $item_id,
        item_name    => $item_name,
        manufacturer => $manufacturer,
        price        => $price,
        order_id     => $order_id,
    };
    bless $self, $class;
    return $self;
}

sub item_id      { $_[0]->{item_id} }
sub item_name    { $_[0]->{item_name} }
sub manufacturer { $_[0]->{manufacturer} }
sub price        { $_[0]->{price} }
sub order_id     { $_[0]->{order_id} }

1;
