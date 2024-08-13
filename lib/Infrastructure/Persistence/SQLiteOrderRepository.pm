package Infrastructure::Persistence::SQLiteOrderRepository;

use strict;
use warnings;
use Domain::Entities::Order;
use Domain::Repositories::OrderRepository;
use parent 'Domain::Repositories::OrderRepository';

sub new {
    my ($class, $dbh) = @_;
    my $self = { dbh => $dbh };
    bless $self, $class;
    return $self;
}

sub find_by_id {
    my ($self, $order_id) = @_;
    my $sth = $self->{dbh}->prepare("SELECT order_id, order_number, order_date, customer_id FROM orders WHERE order_id = ?");
    $sth->execute($order_id);
    my $row = $sth->fetchrow_hashref;
    return unless $row;
    return Domain::Entities::Order->new($row->{order_id}, $row->{order_number}, $row->{order_date}, $row->{customer_id});
}

sub insert {
    my ($self, $order) = @_;
    my $sth = $self->{dbh}->prepare("INSERT INTO orders (order_number, order_date, customer_id) VALUES (?, ?, ?)");
    $sth->execute($order->order_number, $order->order_date, $order->customer_id);
    return $self->{dbh}->last_insert_id(undef, undef, 'orders', undef);
}

sub find_all {
    my ($self) = @_;
    my $sth = $self->{dbh}->prepare("SELECT order_id, order_number, order_date FROM orders");
    $sth->execute();
    my @orders;
    while (my $row = $sth->fetchrow_hashref) {
        push @orders, {
            order_id => $row->{order_id},
            order_number => $row->{order_number},
            order_date => $row->{order_date},
        };
    }
    return \@orders;
}

1;
