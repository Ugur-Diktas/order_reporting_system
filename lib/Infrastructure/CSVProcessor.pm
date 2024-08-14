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
# Description:
#   This function processes the content of a CSV file that contains data
#   related to customers, orders, and items. It reads each row from the CSV,
#   validates the data, and then inserts it into the appropriate tables in
#   the SQLite database. The function ensures that duplicate customers are 
#   skipped and that no invalid data is inserted into the database.
#
# Parameters:
#   - $csv_content_ref: A reference to the CSV content. This is expected to 
#                       be a scalar reference containing the entire CSV file.
#   - $customer_repository: An instance of SQLiteCustomerRepository that handles
#                           database operations related to customers.
#   - $dbh: A database handle for executing SQL queries.
#
# Returns:
#   - A string message detailing the result of the CSV processing. This includes
#     a summary of the number of customers inserted and the number of duplicates 
#     that were skipped.
#
# Exceptions:
#   - Dies with an error message if the CSV content is invalid or if there is
#     an issue opening or processing the CSV file.
#
# Example Usage:
#   my $csv_content = 'order_date,customer_id,first_name,last_name,order_number,item_name,manufacturer,price\n...';
#   my $message = process_csv(\$csv_content, $customer_repository, $dbh);
#   print $message;
# ========================================================
sub process_csv {
    my ($csv_content_ref, $customer_repository, $dbh) = @_;

    die "Invalid CSV content provided" unless $csv_content_ref && ref $csv_content_ref eq 'SCALAR';

    open my $fh, '<', $csv_content_ref or die "Cannot open CSV content";

    my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });

    <$fh>; # Skip the header row

    my @duplicate_customers;
    my @inserted_customers;
    my $orders_added = 0;
    my $items_added = 0;

    while (my $row = $csv->getline($fh)) {
        my ($order_date, $customer_id, $first_name, $last_name, $order_number, $item_name, $manufacturer, $price) = @$row;

        # Skip processing if any required fields are missing
        unless ($first_name && $last_name && $customer_id) {
            warn "Skipping row due to missing required fields: " . join(",", @$row) . "\n";
            next;
        }

        my $result;
        if ($customer_repository->find($customer_id)) {
            push @duplicate_customers, { customer_id => $customer_id, first_name => $first_name, last_name => $last_name };
            $result = "duplicate";
        } else {
            my $customer = Domain::Entities::Customer->new($customer_id, $first_name, $last_name);
            $result = $customer_repository->insert($customer);
            if ($result eq "inserted") {
                push @inserted_customers, { customer_id => $customer_id, first_name => $first_name, last_name => $last_name };
            }
        }

        # Insert order and item records regardless of customer status
        my $order_repository = Infrastructure::Persistence::SQLiteOrderRepository->new($dbh);
        my $order_id = $order_repository->find_or_insert($order_number, $order_date, $customer_id);

        if ($order_id) {
            $orders_added++;
        }

        my $item_repository = Infrastructure::Persistence::SQLiteItemRepository->new($dbh);
        my $item_id = $item_repository->find_or_insert($item_name, $manufacturer, $price, $order_id);

        if ($item_id) {
            $items_added++;
        }
    }

    close $fh;

    # Prepare a summary message of the results
    my $message = "CSV data has been successfully imported!\n";
    $message .= scalar(@inserted_customers) . " customers were added.\n";
    $message .= scalar(@duplicate_customers) . " duplicate customers were skipped.\n";
    $message .= "$orders_added orders were added.\n";
    $message .= "$items_added items were added.";

    return $message;
}

1;
