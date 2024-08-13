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

    my @duplicate_customers;
    my @inserted_customers;

    while (my $row = $csv->getline($fh)) {
        my ($order_date, $customer_id, $first_name, $last_name, $order_number, $item_name, $manufacturer, $price) = @$row;

        my $customer = Domain::Entities::Customer->new($customer_id, $first_name, $last_name);
        my $result = $customer_repository->insert($customer);

        if ($result eq "duplicate") {
            push @duplicate_customers, { customer_id => $customer_id, first_name => $first_name, last_name => $last_name };
        } else {
            push @inserted_customers, { customer_id => $customer_id, first_name => $first_name, last_name => $last_name };

            my $order_repository = Infrastructure::Persistence::SQLiteOrderRepository->new($dbh);
            my $order = Domain::Entities::Order->new(undef, $order_number, $order_date, $customer_id);
            my $order_id = $order_repository->insert($order);

            my $item_repository = Infrastructure::Persistence::SQLiteItemRepository->new($dbh);
            my $item = Domain::Entities::Item->new(undef, $item_name, $manufacturer, $price, $order_id);
            $item_repository->insert($item);
        }
    }

    close $fh;

    my $message = "CSV data has been successfully imported!\n";
    $message .= scalar(@duplicate_customers) . " duplicate customers were skipped:\n";
    foreach my $dup (@duplicate_customers) {
        $message .= "Customer ID: $dup->{customer_id}, Name: $dup->{first_name} $dup->{last_name}\n";
    }

    return $message;
}

1;
