package Infrastructure::Persistence::SQLiteItemRepository;

use strict;
use warnings;
use Domain::Entities::Item;

# ========================================================
# Constructor: new
# Initializes the SQLiteItemRepository with a database handle.
# ========================================================
sub new {
    my ($class, $dbh) = @_;
    my $self = { dbh => $dbh };
    bless $self, $class;
    return $self;
}

# ========================================================
# Method: insert
# Inserts a new item into the database.
# ========================================================
sub insert {
    my ($self, $item) = @_;
    my $sth = $self->{dbh}->prepare(
        "INSERT INTO items (item_name, manufacturer, price) VALUES (?, ?, ?)"
    );
    $sth->execute($item->item_name, $item->manufacturer, $item->price);
}

# ========================================================
# Method: find_or_insert
# Attempts to find an existing item in the database. If the item 
# does not exist, it inserts the item and returns the new item ID.
# Returns the item ID of the found or newly inserted item.
# ========================================================
sub find_or_insert {
    my ($self, $item_name, $manufacturer, $price) = @_;

    my $sth = $self->{dbh}->prepare(
        "SELECT item_id FROM items WHERE item_name = ? AND manufacturer = ? AND price = ?"
    );
    $sth->execute($item_name, $manufacturer, $price);
    my ($item_id) = $sth->fetchrow_array();

    unless ($item_id) {
        $sth = $self->{dbh}->prepare(
            "INSERT INTO items (item_name, manufacturer, price) VALUES (?, ?, ?)"
        );
        $sth->execute($item_name, $manufacturer, $price);
        $item_id = $self->{dbh}->last_insert_id(undef, undef, "items", "item_id");
    }

    return $item_id;
}

1;
