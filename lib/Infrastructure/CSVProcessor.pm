package Infrastructure::CSVProcessor;

use strict;
use warnings;
use Text::CSV;
use Domain::Entities::Customer;
use Domain::Entities::Order;
use Domain::Entities::Item;
use Infrastructure::Persistence::SQLiteOrderRepository;
use Infrastructure::Persistence::SQLiteItemRepository;

# ========================================================
# Function: process_csv
# This function processes the CSV content provided, extracting and inserting
# customer, order, and item data into the appropriate database tables.
#
# Params:
#   - $csv_content_ref: A reference to the CSV content (scalar reference)
#   - $customer_repository: An instance of SQLiteCustomerRepository for handling customer-related database operations
#   - $dbh: The database handle for executing SQL queries
#
# Returns:
#   - A message string detailing the results of the CSV processing, including the number of duplicate customers skipped
#
# Die/Exception:
#   - Dies with an error message if the CSV content is invalid or if there is an issue opening the CSV file.
# ========================================================
sub process_csv {
    my ($csv_content_ref, $customer_repository, $dbh) = @_;

    # Validate that the CSV content is a valid scalar reference
    die "Invalid CSV content provided" unless $csv_content_ref && ref $csv_content_ref eq 'SCALAR';

    # Attempt to open the CSV content for reading
    open my $fh, '<', $csv_content_ref or die "Cannot open CSV content";

    # Create a new Text::CSV object for parsing the CSV content
    my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });

    # Skip the header row in the CSV file
    <$fh>;

    # Arrays to store details of duplicate and newly inserted customers
    my @duplicate_customers;
    my @inserted_customers;

    # Loop through each row in the CSV file
    while (my $row = $csv->getline($fh)) {
        # Extract fields from the current CSV row
        my ($order_date, $customer_id, $first_name, $last_name, $order_number, $item_name, $manufacturer, $price) = @$row;

        # Create a new Customer entity object
        my $customer = Domain::Entities::Customer->new($customer_id, $first_name, $last_name);

        # Attempt to insert the customer into the database
        my $result = $customer_repository->insert($customer);

        # Handle duplicate customer scenarios
        if ($result eq "duplicate") {
            push @duplicate_customers, { customer_id => $customer_id, first_name => $first_name, last_name => $last_name };
        } else {
            push @inserted_customers, { customer_id => $customer_id, first_name => $first_name, last_name => $last_name };

            # Insert the corresponding order and item into the database
            my $order_repository = Infrastructure::Persistence::SQLiteOrderRepository->new($dbh);
            my $order = Domain::Entities::Order->new(undef, $order_number, $order_date, $customer_id);
            my $order_id = $order_repository->insert($order);

            my $item_repository = Infrastructure::Persistence::SQLiteItemRepository->new($dbh);
            my $item = Domain::Entities::Item->new(undef, $item_name, $manufacturer, $price, $order_id);
            $item_repository->insert($item);
        }
    }

    # Close the file handle after processing
    close $fh;

    # Construct a result message detailing the processing outcome
    my $message = "CSV data has been successfully imported!\n";
    $message .= scalar(@duplicate_customers) . " duplicate customers were skipped:\n";
    foreach my $dup (@duplicate_customers) {
        $message .= "Customer ID: $dup->{customer_id}, Name: $dup->{first_name} $dup->{last_name}\n";
    }

    # Return the result message
    return $message;
}

1;
