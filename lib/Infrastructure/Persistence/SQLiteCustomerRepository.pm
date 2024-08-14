package Infrastructure::Persistence::SQLiteCustomerRepository;

use strict;
use warnings;
use Domain::Entities::Customer;

sub new {
    my ($class, $dbh) = @_;
    my $self = { dbh => $dbh };
    bless $self, $class;
    return $self;
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

sub find {
    my ($self, $customer_id) = @_;

    my $sth = $self->{dbh}->prepare("SELECT customer_id FROM customers WHERE customer_id = ?");
    $sth->execute($customer_id);

    my ($found_customer_id) = $sth->fetchrow_array();

    return defined $found_customer_id ? 1 : 0;
}

1;
