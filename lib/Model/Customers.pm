package Model::Customers;

use strict;
use warnings;

sub insert {
    my ($dbh, $customer_id, $first_name, $last_name) = @_;
    
    # Check if customer already exists
    my $sth = $dbh->prepare("SELECT customer_id FROM customers WHERE customer_id = ?");
    $sth->execute($customer_id);
    return if $sth->fetchrow_array();
    
    # Insert customer
    $sth = $dbh->prepare("INSERT INTO customers (customer_id, first_name, last_name) VALUES (?, ?, ?)");
    $sth->execute($customer_id, $first_name, $last_name);
}

1;
