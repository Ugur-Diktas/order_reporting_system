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
# Read SQL Migration Script
# ========================================================
my $sql_file = 'db/migrations/001_create_tables.sql';
my $sql = eval { read_file($sql_file) };
croak("Failed to read SQL file '$sql_file': $@") if $@;

# ========================================================
# Execute SQL Commands
# ========================================================
my @commands = split(/;/, $sql);

foreach my $command (@commands) {
    next unless $command =~ /\S/;  # Skip empty commands
    $command .= ';';  # Re-add the semicolon for execution
    eval {
        $dbh->do($command) or die "Failed to execute SQL command: $command\n";
    };
    croak("An error occurred during migration: $@") if $@;
}

print "Migration script executed successfully.\n";

# ========================================================
# Load Initial Data from CSV
# Loads initial data from 'orders.csv' into the database.
# ========================================================
my $csv_file = 'db/seeds/orders.csv';
open my $fh, "<:encoding(utf8)", $csv_file or croak("Failed to open CSV file: $csv_file");

my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });
<$fh>;  # Skip the header row

while (my $row = $csv->getline($fh)) {
    my ($order_date, $customer_id, $first_name, $last_name, $order_number, $item_name, $manufacturer, $price) = @$row;

    # Validate and insert customer data
    unless ($first_name && $last_name && $customer_id) {
        warn "Skipping row due to missing customer fields: " . join(",", @$row) . "\n";
        next;
    }

    my $sth = $dbh->prepare("SELECT customer_id FROM customers WHERE customer_id = ?");
    $sth->execute($customer_id);
    unless ($sth->fetchrow_array) {
        $sth = $dbh->prepare("INSERT INTO customers (customer_id, first_name, last_name) VALUES (?, ?, ?)");
        $sth->execute($customer_id, $first_name, $last_name);
    }

    # Validate and insert item data
    unless ($item_name && $manufacturer && defined $price) {
        warn "Skipping row due to missing item fields: " . join(",", @$row) . "\n";
        next;
    }

    $sth = $dbh->prepare("SELECT item_id FROM items WHERE item_name = ? AND manufacturer = ? AND price = ?");
    $sth->execute($item_name, $manufacturer, $price);
    my $item_id = $sth->fetchrow_array;

    unless ($item_id) {
        $sth = $dbh->prepare("INSERT INTO items (item_name, manufacturer, price) VALUES (?, ?, ?)");
        $sth->execute($item_name, $manufacturer, $price);
        $item_id = $dbh->last_insert_id(undef, undef, "items", "item_id");
    }

    # Validate and insert order data
    unless ($order_number && $order_date && $item_id && $customer_id) {
        warn "Skipping row due to missing order fields: " . join(",", @$row) . "\n";
        next;
    }

    $sth = $dbh->prepare("SELECT order_id FROM orders WHERE order_number = ? AND customer_id = ? AND item_id = ?");
    $sth->execute($order_number, $customer_id, $item_id);
    unless ($sth->fetchrow_array) {
        $sth = $dbh->prepare("INSERT INTO orders (order_number, order_date, customer_id, item_id) VALUES (?, ?, ?, ?)");
        $sth->execute($order_number, $order_date, $customer_id, $item_id);
    }
}

close $fh;
print "Initial data loaded successfully from $csv_file.\n";
