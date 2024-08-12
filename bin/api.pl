#!/usr/bin/perl

use strict;
use warnings;
use JSON;
use CGI;
use lib 'lib';
use Model::DB;

# Set up the CGI object
my $cgi = CGI->new;

# Connect to the database
my $dbh = Model::DB::connect();

# Determine which API endpoint to call based on the 'action' parameter
my $action = $cgi->param('action') || '';

if ($action eq 'index.html') {
    list_orders($dbh);
} elsif ($action eq 'list_orders') {
    list_orders($dbh);
} elsif ($action eq 'order_details') {
    my $order_id = $cgi->param('order_id');
    order_details($dbh, $order_id);
} else {
    print $cgi->header('application/json', '400 Bad Request');
    print encode_json({ error => "Invalid action" });
}

# List all orders
sub list_orders {
    my ($dbh) = @_;
    
    my $sth = $dbh->prepare("SELECT order_id, order_number, order_date FROM orders");
    $sth->execute();
    
    my @orders;
    while (my $row = $sth->fetchrow_hashref) {
        push @orders, $row;
    }
    
    print $cgi->header('application/json');
    print encode_json(\@orders);
}

# Get details for a specific order
sub order_details {
    my ($dbh, $order_id) = @_;
    
    my $sth = $dbh->prepare("
        SELECT o.order_id, o.order_number, o.order_date, c.first_name, c.last_name, i.item_name, i.manufacturer, i.price
        FROM orders o
        JOIN customers c ON o.customer_id = c.customer_id
        JOIN items i ON o.order_id = i.order_id
        WHERE o.order_id = ?
    ");
    $sth->execute($order_id);
    
    my @details;
    while (my $row = $sth->fetchrow_hashref) {
        push @details, $row;
    }
    
    print $cgi->header('application/json');
    print encode_json(\@details);
}
