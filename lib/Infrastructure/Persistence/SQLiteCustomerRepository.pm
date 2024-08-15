package Infrastructure::Persistence::SQLiteCustomerRepository;

use strict;
use warnings;
use Domain::Entities::Customer;

# ========================================================
# Constructor: new
# Initializes the SQLiteCustomerRepository with a database handle.
# ========================================================
sub new {
    my ($class, $dbh) = @_;
    my $self = { dbh => $dbh };
    bless $self, $class;
    return $self;
}

# ========================================================
# Method: insert
# Inserts a new customer into the database.
# Returns "inserted" on success, "duplicate" if the customer 
# already exists, and dies with an error message if insertion fails.
# ========================================================
sub insert {
    my ($self, $customer) = @_;

    eval {
        my $sth = $self->{dbh}->prepare(
            "INSERT INTO customers (customer_id, first_name, last_name) VALUES (?, ?, ?)"
        );
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

# ========================================================
# Method: find
# Finds a customer by ID in the database.
# Returns 1 if the customer exists, 0 otherwise.
# ========================================================
sub find {
    my ($self, $customer_id) = @_;

    my $sth = $self->{dbh}->prepare("SELECT customer_id FROM customers WHERE customer_id = ?");
    $sth->execute($customer_id);

    my ($found_customer_id) = $sth->fetchrow_array();

    return defined $found_customer_id ? 1 : 0;
}

1;
