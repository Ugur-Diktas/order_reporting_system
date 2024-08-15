package Infrastructure::Persistence::SQLiteOrderRepository;

use strict;
use warnings;
use Domain::Entities::Order;

sub new {
    my ($class, $dbh) = @_;
    my $self = { dbh => $dbh };
    bless $self, $class;
    return $self;
}

sub find_all {
    my ($self) = @_;
    my $sth = $self->{dbh}->prepare("
        SELECT 
            o.order_id, 
            o.order_number, 
            o.order_date, 
            c.first_name || ' ' || c.last_name AS customer_name, 
            i.item_name, 
            i.manufacturer, 
            i.price
        FROM orders o
        JOIN customers c ON o.customer_id = c.customer_id
        JOIN items i ON o.item_id = i.item_id
    ");
    $sth->execute();
    
    my @orders;
    while (my $row = $sth->fetchrow_hashref) {
        push @orders, {
            order_id => $row->{order_id},
            order_number => $row->{order_number},
            order_date => $row->{order_date},
            customer_name => $row->{customer_name},
            item_name => $row->{item_name},
            manufacturer => $row->{manufacturer},
            price => $row->{price},
        };
    }
    return \@orders;
}

sub insert {
    my ($self, $order) = @_;
    
    my $sth = $self->{dbh}->prepare("INSERT INTO orders (order_number, order_date, customer_id, item_id) VALUES (?, ?, ?, ?)");
    $sth->execute($order->order_number, $order->order_date, $order->customer_id, $order->item_id);
    
    return $self->{dbh}->last_insert_id(undef, undef, "orders", "order_id");
}

sub find_or_insert {
    my ($self, $order_number, $order_date, $customer_id, $item_id) = @_;

    my $sth = $self->{dbh}->prepare("SELECT order_id FROM orders WHERE order_number = ? AND customer_id = ? AND item_id = ?");
    $sth->execute($order_number, $customer_id, $item_id);
    my ($order_id) = $sth->fetchrow_array();

    unless ($order_id) {
        $sth = $self->{dbh}->prepare("INSERT INTO orders (order_number, order_date, customer_id, item_id) VALUES (?, ?, ?, ?)");
        $sth->execute($order_number, $order_date, $customer_id, $item_id);
        $order_id = $self->{dbh}->last_insert_id(undef, undef, "orders", "order_id");
    }

    return $order_id;
}

sub delete_orders {
    my ($self, $order_ids) = @_;

    my $placeholders = join(',', ('?') x @$order_ids);
    my $sth = $self->{dbh}->prepare("DELETE FROM orders WHERE order_id IN ($placeholders)");

    $sth->execute(@$order_ids);

    return $sth->rows;
}

1;
