#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use File::Slurp;

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
my $dbh = DBI->connect("dbi:SQLite:dbname=db/orders.db", "", "", {
    RaiseError => 1,
    AutoCommit => 1,
});

# ========================================================
# Read SQL Script
# This section reads the SQL migration script from the file
# 'db/migrations/001_create_tables.sql'. The script contains 
# SQL commands to create necessary tables and set up the 
# database schema.
# ========================================================
my $sql = read_file('db/migrations/001_create_tables.sql');

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
    my $result = $dbh->do($command);
    
    # Die with an error message if the command fails
    die "Failed to execute SQL command: $command\nCheck the syntax or database constraints." unless $result;
}

# ========================================================
# Success Message
# If all commands are executed successfully, a success 
# message is printed to indicate that the migration script
# has been applied to the database without errors.
# ========================================================
print "Migration script executed successfully.\n";
