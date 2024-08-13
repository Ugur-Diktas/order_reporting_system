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

    # Path to the wkhtmltopdf executable
    my $wkhtmltopdf_path = 'bin/wkhtmltopdf/wkhtmltopdf.exe';

    # ========================================================
    # Start building the HTML content for the PDF
    # This section creates an HTML structure that will later 
    # be converted into a PDF. The HTML includes styling for 
    # the report's layout, customer, order, and item details.
    # ========================================================
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

    # ========================================================
    # Query database for order, customer, and item information
    # This section retrieves the relevant data from the database 
    # and groups it by customer, order, and item. The results 
    # are then iterated over to build the HTML content.
    # ========================================================
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

    # Loop through the database results and build the HTML
    while (my $row = $sth->fetchrow_hashref) {
        # Start a new customer section if the customer_id changes
        if (!defined $current_customer_id || $current_customer_id != $row->{customer_id}) {
            $current_customer_id = $row->{customer_id};
            $html .= "<div class='customer'><h2>$row->{first_name} $row->{last_name} (Customer ID: $row->{customer_id})</h2>";
        }

        # Add order and item details to the HTML
        $html .= "<div class='order'>";
        $html .= "<p><strong>Order $row->{order_number}</strong> - $row->{order_date}</p>";
        $html .= "<div class='item'><p><strong>$row->{item_name}</strong> ($row->{manufacturer}) - \$" . sprintf('%.2f', $row->{price}) . "</p></div>";
        $html .= "</div>"; # Close order div
    }

    $html .= "</div>"; # Close customer div
    $html .= "</body></html>"; # Close HTML content

    # ========================================================
    # Write the HTML content to a temporary file
    # The HTML content is written to a temporary file, which 
    # will be converted to PDF using wkhtmltopdf.
    # ========================================================
    my ($html_fh, $html_filename) = tempfile(SUFFIX => '.html');
    print $html_fh $html;
    close $html_fh;

    # Define the output PDF file
    my ($pdf_fh, $pdf_filename) = tempfile(SUFFIX => '.pdf');
    close $pdf_fh;

    # ========================================================
    # Convert HTML to PDF using wkhtmltopdf
    # The wkhtmltopdf tool is used to convert the HTML content 
    # into a PDF file. If the command fails, an error is raised.
    # ========================================================
    my $command = "\"$wkhtmltopdf_path\" $html_filename $pdf_filename";
    system($command) == 0 or die "Failed to execute wkhtmltopdf: $!";

    # Return the path to the generated PDF file
    return $pdf_filename;
}

1;
