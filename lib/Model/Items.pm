package Model::Items;

use strict;
use warnings;

sub insert {
    my ($dbh, $item_name, $manufacturer, $price, $order_id) = @_;
    
    # Insert item
    my $sth = $dbh->prepare("INSERT INTO items (item_name, manufacturer, price, order_id) VALUES (?, ?, ?, ?)");
    $sth->execute($item_name, $manufacturer, $price, $order_id);
}

1;
