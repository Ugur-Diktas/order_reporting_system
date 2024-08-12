package Model::Orders;

use strict;
use warnings;

sub insert {
    my ($dbh, $order_number, $order_date, $customer_id) = @_;
    
    # Insert order
    my $sth = $dbh->prepare("INSERT INTO orders (order_number, order_date, customer_id) VALUES (?, ?, ?)");
    $sth->execute($order_number, $order_date, $customer_id);
    
    return $dbh->last_insert_id(undef, undef, 'orders', undef);
}

1;
