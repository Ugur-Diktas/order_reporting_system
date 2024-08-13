#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use File::Slurp;
use Carp;
use Text::CSV;

# ========================================================
# Database Connection
# This section establishes a connection to the SQLite database.
# The connection is configured to raise errors automatically 
# if something goes wrong (RaiseError) and to commit each statement
# as soon as it is executed (AutoCommit).
#
# The database connection handle ($dbh) is used to execute SQL
# commands later in the script.
# ========================================================
my $db_path = "db/orders.db";  # Path to the SQLite database
my $dbh = DBI->connect("dbi:SQLite:dbname=$db_path", "", "", {
    RaiseError => 1,
    AutoCommit => 1,
}) or croak("Failed to connect to the database: $DBI::errstr");

# ========================================================
# Read SQL Script
# This section reads the SQL migration script from the file
# 'db/migrations/001_create_tables.sql'. The script contains 
# SQL commands to create necessary tables and set up the 
# database schema.
# ========================================================
my $sql_file = 'db/migrations/001_create_tables.sql';
my $sql = eval { read_file($sql_file) };
croak("Failed to read SQL file '$sql_file': $@") if $@;

# ========================================================
# SQL Command Execution
# The SQL script is split into individual commands based on
# the semicolon (;) delimiter. Each command is executed 
# separately to ensure that multi-line SQL statements are 
# processed correctly.
#
# The script loops through each command, re-adding the 
# semicolon for execution, and executing it using the 
# database connection handle ($dbh). If any command fails,
# the script dies with an error message.
# ========================================================

# Split the script into individual commands
my @commands = split(/;/, $sql);

# Execute each command separately
foreach my $command (@commands) {
    next unless $command =~ /\S/; # Skip empty commands
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
# After the database schema has been set up, we load the
# initial data from the CSV file and populate the tables.
# ========================================================
my $csv_file = 'db/seeds/orders.csv';  # Path to the CSV file
open my $fh, "<:encoding(utf8)", $csv_file or croak("Failed to open CSV file: $!");

my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });  # Create a new Text::CSV object
<$fh>;  # Skip the header row

while (my $row = $csv->getline($fh)) {
    # Parse the row and insert the data into the appropriate tables
    my ($order_date, $customer_id, $first_name, $last_name, $order_number, $item_name, $manufacturer, $price) = @$row;

    # Check if customer already exists
    my $sth = $dbh->prepare("SELECT COUNT(*) FROM customers WHERE customer_id = ?");
    $sth->execute($customer_id);
    my ($customer_exists) = $sth->fetchrow_array();

    # Insert customer if it doesn't exist
    if (!$customer_exists) {
        $sth = $dbh->prepare("INSERT INTO customers (customer_id, first_name, last_name) VALUES (?, ?, ?)");
        $sth->execute($customer_id, $first_name, $last_name);
    }

    # Check if order already exists
    $sth = $dbh->prepare("SELECT order_id FROM orders WHERE order_number = ? AND customer_id = ?");
    $sth->execute($order_number, $customer_id);
    my ($order_id) = $sth->fetchrow_array();

    # Insert order if it doesn't exist
    if (!$order_id) {
        $sth = $dbh->prepare("INSERT INTO orders (order_number, order_date, customer_id) VALUES (?, ?, ?)");
        $sth->execute($order_number, $order_date, $customer_id);
        $order_id = $dbh->last_insert_id(undef, undef, "orders", "order_id");
    }

    # Check if item already exists
    $sth = $dbh->prepare("SELECT COUNT(*) FROM items WHERE item_name = ? AND order_id = ?");
    $sth->execute($item_name, $order_id);
    my ($item_exists) = $sth->fetchrow_array();

    # Insert item if it doesn't exist
    if (!$item_exists) {
        $sth = $dbh->prepare("INSERT INTO items (item_name, manufacturer, price, order_id) VALUES (?, ?, ?, ?)");
        $sth->execute($item_name, $manufacturer, $price, $order_id);
    }
}

close $fh;
print "Initial data loaded successfully from $csv_file.\n";
