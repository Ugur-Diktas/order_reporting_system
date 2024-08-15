#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use File::Slurp;
use Carp;
use Text::CSV;

# ========================================================
# Database Connection
# ========================================================
my $db_path = "db/orders.db";
my $dbh = DBI->connect("dbi:SQLite:dbname=$db_path", "", "", {
    RaiseError => 1,
    AutoCommit => 1,
}) or croak("Failed to connect to the database: $DBI::errstr");

# ========================================================
# Read SQL Script
# ========================================================
my $sql_file = 'db/migrations/001_create_tables.sql';
my $sql = eval { read_file($sql_file) };
croak("Failed to read SQL file '$sql_file': $@") if $@;

# ========================================================
# SQL Command Execution
# ========================================================
my @commands = split(/;/, $sql);

foreach my $command (@commands) {
    next unless $command =~ /\S/;  # Skip empty commands
    $command .= ';';  # Re-add the semicolon for execution
    eval {
        my $result = $dbh->do($command);
        die "Failed to execute SQL command: $command\n" unless $result;
    };
    if ($@) {
        croak("An error occurred during migration: $@");
    }
}

print "Migration script executed successfully.\n";

# ========================================================
# Process Initial Data (CSV)
# ========================================================
my $csv_file = 'db/seeds/orders.csv';
open my $fh, "<:encoding(utf8)", $csv_file or croak("Failed to open CSV file: $!");

my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });  # Create a new Text::CSV object
<$fh>;  # Skip the header row

while (my $row = $csv->getline($fh)) {
    my ($order_date, $customer_id, $first_name, $last_name, $order_number, $item_name, $manufacturer, $price) = @$row;

    # Validate required fields for customers
    unless ($first_name && $last_name && $customer_id) {
        warn "Skipping row due to missing required customer fields: " . join(",", @$row) . "\n";
        next;
    }

    # Check if customer already exists
    my $sth = $dbh->prepare("SELECT COUNT(*) FROM customers WHERE customer_id = ?");
    $sth->execute($customer_id);
    my ($customer_exists) = $sth->fetchrow_array();

    # Insert customer if it doesn't exist
    if (!$customer_exists) {
        $sth = $dbh->prepare("INSERT INTO customers (customer_id, first_name, last_name) VALUES (?, ?, ?)");
        $sth->execute($customer_id, $first_name, $last_name);
    }

    # Validate required fields for items
    unless ($item_name && $manufacturer && defined $price) {
        warn "Skipping row due to missing required item fields: " . join(",", @$row) . "\n";
        next;
    }

    # Check if item already exists
    $sth = $dbh->prepare("SELECT item_id FROM items WHERE item_name = ? AND manufacturer = ? AND price = ?");
    $sth->execute($item_name, $manufacturer, $price);
    my ($item_id) = $sth->fetchrow_array();

    # Insert item if it doesn't exist
    if (!$item_id) {
        $sth = $dbh->prepare("INSERT INTO items (item_name, manufacturer, price) VALUES (?, ?, ?)");
        $sth->execute($item_name, $manufacturer, $price);
        $item_id = $dbh->last_insert_id(undef, undef, "items", "item_id");
    }

    # Validate required fields for orders
    unless ($order_number && $order_date && $item_id && $customer_id) {
        warn "Skipping row due to missing required order fields: " . join(",", @$row) . "\n";
        next;
    }

    # Check if order already exists
    $sth = $dbh->prepare("SELECT order_id FROM orders WHERE order_number = ? AND customer_id = ? AND item_id = ?");
    $sth->execute($order_number, $customer_id, $item_id);
    my ($order_id) = $sth->fetchrow_array();

    # Insert order if it doesn't exist
    if (!$order_id) {
        $sth = $dbh->prepare("INSERT INTO orders (order_number, order_date, customer_id, item_id) VALUES (?, ?, ?, ?)");
        $sth->execute($order_number, $order_date, $customer_id, $item_id);
    }
}

close $fh;
print "Initial data loaded successfully from $csv_file.\n";
