#!/usr/bin/perl

use strict;
use warnings;
use Text::CSV;
use lib 'lib';  # Ensure the 'lib' directory is included
use Model::DB;
use Model::Customers;
use Model::Orders;
use Model::Items;

# Path to the CSV file (adjust this path as needed)
my $csv_file = "../orders (1).csv";

# Connect to the database
my $dbh = Model::DB::connect();

# Parse the CSV file
my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });
open my $fh, "<", $csv_file or die "Cannot open CSV file: $!";
<$fh>; # skip the header

while (my $row = $csv->getline($fh)) {
    my ($order_date, $customer_id, $first_name, $last_name, $order_number, $item_name, $manufacturer, $price) = @$row;
    
    # Insert customer data
    Model::Customers::insert($dbh, $customer_id, $first_name, $last_name);
    
    # Insert order data
    my $order_id = Model::Orders::insert($dbh, $order_number, $order_date, $customer_id);
    
    # Insert item data
    Model::Items::insert($dbh, $item_name, $manufacturer, $price, $order_id);
}

close $fh;
print "CSV data has been successfully imported!\n";
