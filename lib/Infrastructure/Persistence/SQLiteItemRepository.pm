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
    my $sth = $self->{dbh}->prepare("INSERT INTO items (item_name, manufacturer, price, order_id) VALUES (?, ?, ?, ?)");
    $sth->execute($item->item_name, $item->manufacturer, $item->price, $item->order_id);
}

sub find_or_insert {
    my ($self, $item_name, $manufacturer, $price, $order_id) = @_;

    my $sth = $self->{dbh}->prepare("SELECT item_id FROM items WHERE item_name = ? AND order_id = ?");
    $sth->execute($item_name, $order_id);
    my ($item_id) = $sth->fetchrow_array();

    unless ($item_id) {
        $sth = $self->{dbh}->prepare("INSERT INTO items (item_name, manufacturer, price, order_id) VALUES (?, ?, ?, ?)");
        $sth->execute($item_name, $manufacturer, $price, $order_id);
        $item_id = $self->{dbh}->last_insert_id(undef, undef, "items", "item_id");
        return $item_id;
    }

    return undef;  # Item already exists, return undef
}

1;
