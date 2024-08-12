package Service::CSVProcessor;

use strict;
use warnings;
use Text::CSV;
use Model::Customers;
use Model::Orders;
use Model::Items;

# Process CSV and insert data into the database
sub process_csv {
    my ($csv_content_ref, $dbh) = @_;

    # Ensure the CSV content reference is valid
    die "Invalid CSV content provided" unless $csv_content_ref && ref $csv_content_ref eq 'SCALAR';

    # Create a filehandle from the scalar reference
    open my $fh, '<', $csv_content_ref or die "Cannot open CSV content";

    # Create a new CSV parser
    my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });

    # Skip the header row
    <$fh>;

    # Parse each row and insert data into the database
    while (my $row = $csv->getline($fh)) {
        my ($order_date, $customer_id, $first_name, $last_name, $order_number, $item_name, $manufacturer, $price) = @$row;
        
        # Insert customer data
        Model::Customers::insert($dbh, $customer_id, $first_name, $last_name);
        
        # Insert order data
        my $order_id = Model::Orders::insert($dbh, $order_number, $order_date, $customer_id);
        
        # Insert item data
        Model::Items::insert($dbh, $item_name, $manufacturer, $price, $order_id);
    }

    close $fh;

    return "CSV data has been successfully imported!";
}

1;
