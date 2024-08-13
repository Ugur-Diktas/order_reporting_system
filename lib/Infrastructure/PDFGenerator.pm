package Infrastructure::PDFGenerator;

use strict;
use warnings;
use File::Temp qw(tempfile);

sub generate_pdf {
    my ($dbh, $order_ids) = @_;

    my $wkhtmltopdf_path = 'bin/wkhtmltopdf/wkhtmltopdf.exe';  # Adjust path as necessary

    # Start the HTML content
    my $html = "<html><head><style>
                    body { font-family: Arial, sans-serif; margin: 20px; line-height: 1.6; }
                    h1 { text-align: center; color: #333; }
                    h2 { margin: 15px 0; color: #444; }
                    .customer { margin-bottom: 25px; }
                    .order { background-color: #f9f9f9; padding: 10px; border-radius: 5px; margin-bottom: 10px; }
                    .order p { margin: 5px 0; }
                    .item { margin-left: 20px; }
                    .item strong { color: #007BFF; }
                </style><title>Orders Report</title></head><body>";
    $html .= "<h1>Orders Report</h1>";

    # Query to get all relevant information grouped by customer, order, and item
    my $sth = $dbh->prepare("
        SELECT c.customer_id, c.first_name, c.last_name, 
               i.item_name, i.manufacturer, i.price, 
               o.order_number, o.order_date
        FROM orders o
        JOIN customers c ON o.customer_id = c.customer_id
        JOIN items i ON o.order_id = i.order_id
        WHERE o.order_id IN (" . join(",", ("?") x @$order_ids) . ")
        ORDER BY c.customer_id, o.order_date
    ");
    $sth->execute(@$order_ids);

    my $current_customer_id = undef;
    while (my $row = $sth->fetchrow_hashref) {
        if (!defined $current_customer_id || $current_customer_id != $row->{customer_id}) {
            $current_customer_id = $row->{customer_id};
            # Print customer information
            $html .= "<div class='customer'><h2>$row->{first_name} $row->{last_name} (Customer ID: $row->{customer_id})</h2>";
        }

        # Print item information and corresponding order
        $html .= "<div class='order'>";
        $html .= "<p><strong>Order $row->{order_number}</strong> - $row->{order_date}</p>";
        $html .= "<div class='item'><p><strong>$row->{item_name}</strong> ($row->{manufacturer}) - \$" . sprintf('%.2f', $row->{price}) . "</p></div>";
        $html .= "</div>"; # Close order div
    }

    $html .= "</div>"; # Close customer div
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
