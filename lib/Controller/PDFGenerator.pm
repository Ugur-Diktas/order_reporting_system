package Controller::PDFGenerator;

use strict;
use warnings;
use File::Temp qw(tempfile);

sub generate_pdf {
    my ($dbh, $order_id) = @_;

    # Path to wkhtmltopdf within the project
    my $wkhtmltopdf_path = 'bin/wkhtmltopdf/wkhtmltopdf.exe';  # Adjust if necessary
    
    # Generate HTML content for the PDF
    my $html = "<html><head><style>
                    body { font-family: Arial, sans-serif; margin: 20px; }
                    h1 { text-align: center; }
                    p { margin: 10px 0; }
                </style><title>Orders Report</title></head><body>";
    $html .= "<h1>Orders Report</h1>";

    if ($order_id) {
        # Fetch details for a specific order
        my $sth = $dbh->prepare("
            SELECT o.order_id, o.order_number, o.order_date, 
                   c.first_name, c.last_name, 
                   i.item_name, i.manufacturer, i.price
            FROM orders o
            JOIN customers c ON o.customer_id = c.customer_id
            JOIN items i ON o.order_id = i.order_id
            WHERE o.order_id = ?
        ");
        $sth->execute($order_id);

        my $row = $sth->fetchrow_hashref;
        $html .= "<p><strong>Order ID:</strong> $row->{order_id}</p>";
        $html .= "<p><strong>Order Number:</strong> $row->{order_number}</p>";
        $html .= "<p><strong>Order Date:</strong> $row->{order_date}</p>";
        $html .= "<p><strong>Customer:</strong> $row->{first_name} $row->{last_name}</p>";
        $html .= "<p><strong>Item:</strong> $row->{item_name}</p>";
        $html .= "<p><strong>Manufacturer:</strong> $row->{manufacturer}</p>";
        $html .= "<p><strong>Price:</strong> $row->{price}</p>";
    } else {
        # Fetch and list all orders
        my $sth = $dbh->prepare("SELECT order_id, order_number, order_date FROM orders");
        $sth->execute();

        while (my $row = $sth->fetchrow_hashref) {
            $html .= "<p><strong>Order ID:</strong> $row->{order_id} - ";
            $html .= "<strong>Order Number:</strong> $row->{order_number} - ";
            $html .= "<strong>Date:</strong> $row->{order_date}</p>";
        }
    }

    $html .= "</body></html>";

    # Write HTML content to a temporary file
    my ($html_fh, $html_filename) = tempfile(SUFFIX => '.html');
    print $html_fh $html;
    close $html_fh;

    # Define the output PDF file
    my ($pdf_fh, $pdf_filename) = tempfile(SUFFIX => '.pdf');
    close $pdf_fh;

    # Convert HTML to PDF using wkhtmltopdf
    my $command = "\"$wkhtmltopdf_path\" $html_filename $pdf_filename";
    system($command) == 0 or die "Failed to execute wkhtmltopdf: $!";

    return $pdf_filename;
}

1;
