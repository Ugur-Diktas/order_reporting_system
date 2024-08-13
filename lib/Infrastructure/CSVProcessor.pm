package Infrastructure::CSVProcessor;

use strict;
use warnings;
use Text::CSV;
use Domain::Entities::Customer;
use Domain::Entities::Order;
use Domain::Entities::Item;

sub process_csv {
    my ($csv_content_ref, $customer_repository, $dbh) = @_;

    die "Invalid CSV content provided" unless $csv_content_ref && ref $csv_content_ref eq 'SCALAR';

    open my $fh, '<', $csv_content_ref or die "Cannot open CSV content";

    my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });

    <$fh>; # Skip the header row

    while (my $row = $csv->getline($fh)) {
        my ($order_date, $customer_id, $first_name, $last_name, $order_number, $item_name, $manufacturer, $price) = @$row;

        my $customer = Domain::Entities::Customer->new($customer_id, $first_name, $last_name);
        $customer_repository->insert($customer);

        my $order_repository = Infrastructure::Persistence::SQLiteOrderRepository->new($dbh);
        my $order = Domain::Entities::Order->new(undef, $order_number, $order_date, $customer_id);
        my $order_id = $order_repository->insert($order);

        my $item_repository = Infrastructure::Persistence::SQLiteItemRepository->new($dbh);
        my $item = Domain::Entities::Item->new(undef, $item_name, $manufacturer, $price, $order_id);
        $item_repository->insert($item);
    }

    close $fh;

    return "CSV data has been successfully imported!";
}

1;
