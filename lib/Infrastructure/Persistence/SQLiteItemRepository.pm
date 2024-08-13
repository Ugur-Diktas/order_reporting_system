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

1;
