package Infrastructure::Persistence::SQLiteCustomerRepository;

use strict;
use warnings;
use Domain::Entities::Customer;
use Domain::Repositories::CustomerRepository;
use parent 'Domain::Repositories::CustomerRepository';

sub new {
    my ($class, $dbh) = @_;
    my $self = { dbh => $dbh };
    bless $self, $class;
    return $self;
}

sub find_by_id {
    my ($self, $customer_id) = @_;
    my $sth = $self->{dbh}->prepare("SELECT customer_id, first_name, last_name FROM customers WHERE customer_id = ?");
    $sth->execute($customer_id);
    my $row = $sth->fetchrow_hashref;
    return unless $row;
    return Domain::Entities::Customer->new($row->{customer_id}, $row->{first_name}, $row->{last_name});
}

sub insert {
    my ($self, $customer) = @_;

    eval {
        my $sth = $self->{dbh}->prepare("INSERT INTO customers (customer_id, first_name, last_name) VALUES (?, ?, ?)");
        $sth->execute($customer->customer_id, $customer->first_name, $customer->last_name);
    };

    if ($@) {
        if ($@ =~ /UNIQUE constraint failed/) {
            warn "Customer with ID " . $customer->customer_id . " already exists. Skipping insert.\n";
            return "duplicate";
        } else {
            die "Failed to insert customer: $@";
        }
    }

    return "inserted";
}

1;
