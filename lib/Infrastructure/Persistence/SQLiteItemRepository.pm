package Infrastructure::Persistence::SQLiteItemRepository;

use strict;
use warnings;
use Domain::Entities::Item;
use Domain::Repositories::ItemRepository;
use parent 'Domain::Repositories::ItemRepository';

sub new {
    my ($class, $dbh) = @_;
    my $self = { dbh => $dbh };
    bless $self, $class;
    return $self;
}

sub find_by_order_id {
    my ($self, $order_id) = @_;
    my $sth = $self->{dbh}->prepare("SELECT item_id, item_name, manufacturer, price, order_id FROM items WHERE order_id = ?");
    $sth->execute($order_id);
    my @items;
    while (my $row = $sth->fetchrow_hashref) {
        push @items, Domain::Entities::Item->new($row->{item_id}, $row->{item_name}, $row->{manufacturer}, $row->{price}, $row->{order_id});
    }
    return \@items;
}

sub insert {
    my ($self, $item) = @_;
    my $sth = $self->{dbh}->prepare("INSERT INTO items (item_name, manufacturer, price, order_id) VALUES (?, ?, ?, ?)");
    $sth->execute($item->item_name, $item->manufacturer, $item->price, $item->order_id);
}

1;
