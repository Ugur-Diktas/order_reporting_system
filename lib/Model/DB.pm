package Model::DB;

use strict;
use warnings;
use DBI;

sub connect {
    my $dsn = "dbi:SQLite:dbname=db/orders.db";
    my $dbh = DBI->connect($dsn, "", "", {
        RaiseError => 1,
        AutoCommit => 1,
    }) or die $DBI::errstr;

    return $dbh;
}

1;
