package Infrastructure::Persistence::SQLiteItemRepository;

use strict;
use warnings;
use Domain::Entities::Item;

sub new {
    my ($class, $dbh) = @_;
    my $self = { dbh => $dbh };
    bless $self, $class;
    return $self;
}

sub insert {
    my ($self, $item) = @_;
    my $sth = $self->{dbh}->prepare("INSERT INTO items (item_name, manufacturer, price) VALUES (?, ?, ?)");
    $sth->execute($item->item_name, $item->manufacturer, $item->price);
}

sub find_or_insert {
    my ($self, $item_name, $manufacturer, $price) = @_;

    my $sth = $self->{dbh}->prepare("SELECT item_id FROM items WHERE item_name = ? AND manufacturer = ? AND price = ?");
    $sth->execute($item_name, $manufacturer, $price);
    my ($item_id) = $sth->fetchrow_array();

    unless ($item_id) {
        $sth = $self->{dbh}->prepare("INSERT INTO items (item_name, manufacturer, price) VALUES (?, ?, ?)");
        $sth->execute($item_name, $manufacturer, $price);
        $item_id = $self->{dbh}->last_insert_id(undef, undef, "items", "item_id");
    }

    return $item_id;
}

1;
