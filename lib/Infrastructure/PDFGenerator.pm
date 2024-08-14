package Infrastructure::PDFGenerator;

use strict;
use warnings;
use File::Temp qw(tempfile);

# ========================================================
# Function: generate_pdf
# This function generates a PDF report from the order data
# provided. It converts the orders to an HTML format, and
# then uses the wkhtmltopdf tool to convert the HTML to a
# PDF file.
#
# Params:
#   - $dbh: The database handle used to execute SQL queries.
#   - $order_ids: An array reference containing the IDs of 
#                 the orders to include in the PDF report.
#
# Returns:
#   - The filename of the generated PDF report.
#
# Die/Exception:
#   - Dies with an error message if the wkhtmltopdf command 
#     fails to execute.
# ========================================================
sub generate_pdf {
    my ($dbh, $order_ids) = @_;

    my $wkhtmltopdf_path = 'bin/wkhtmltopdf/wkhtmltopdf.exe';

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
            $html .= "<div class='customer'><h2>$row->{first_name} $row->{last_name} (Customer ID: $row->{customer_id})</h2>";
        }

        $html .= "<div class='order'>";
        $html .= "<p><strong>Order $row->{order_number}</strong> - $row->{order_date}</p>";
        $html .= "<div class='item'><p><strong>$row->{item_name}</strong> ($row->{manufacturer}) - \$" . sprintf('%.2f', $row->{price}) . "</p></div>";
        $html .= "</div>"; 
    }

    $html .= "</div>";
    $html .= "</body></html>";

    my ($html_fh, $html_filename) = tempfile(SUFFIX => '.html');
    print $html_fh $html;
    close $html_fh;

    my ($pdf_fh, $pdf_filename) = tempfile(SUFFIX => '.pdf');
    close $pdf_fh;

    my $command = "\"$wkhtmltopdf_path\" $html_filename $pdf_filename";
    system($command) == 0 or die "Failed to execute wkhtmltopdf: $!";

    return $pdf_filename;
}

1;
