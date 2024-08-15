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

    my %processed_orders;

    while (my $row = $csv->getline($fh)) {
        # Skip processing if the row is empty
        next if !@$row || !defined $row->[0];

        my ($order_date, $customer_id, $first_name, $last_name, $order_number, $item_name, $manufacturer, $price) = @$row;

        # Skip processing if any required fields are missing
        unless ($first_name && $last_name && $customer_id && $order_number && $item_name) {
            warn "Skipping row due to missing required fields: " . join(",", @$row) . "\n";
            next;
        }

        # Insert customer if not already present
        my $result;
        if (!$customer_repository->find($customer_id)) {
            my $customer = Domain::Entities::Customer->new($customer_id, $first_name, $last_name);
            $result = $customer_repository->insert($customer);
            if ($result eq "inserted") {
                push @inserted_customers, { customer_id => $customer_id, first_name => $first_name, last_name => $last_name };
            }
        }

        # Insert item or find existing item ID
        my $item_repository = Infrastructure::Persistence::SQLiteItemRepository->new($dbh);
        my $item_id = $item_repository->find_or_insert($item_name, $manufacturer, $price);

        # Check if this order has already been processed
        my $order_key = $order_number . '_' . $customer_id . '_' . $item_id;
        unless (exists $processed_orders{$order_key}) {
            # Insert the order if it hasn't been processed yet
            my $order_repository = Infrastructure::Persistence::SQLiteOrderRepository->new($dbh);
            my $order_id = $order_repository->find_or_insert($order_number, $order_date, $customer_id, $item_id);

            if ($order_id) {
                $orders_added++;
                $processed_orders{$order_key} = $order_id;  # Store the order ID
            }
        }
    }

    close $fh;

    # Prepare a summary message of the results
    my $message = "CSV data has been successfully imported!\n";
    $message .= scalar(@inserted_customers) . " customers were added.\n";
    $message .= scalar(@duplicate_customers) . " duplicate customers were skipped.\n";
    $message .= "$orders_added orders were added.\n";
    $message .= "$items_added items were added.";  # This count may be removed or adjusted as needed

    return $message;
}

1;
