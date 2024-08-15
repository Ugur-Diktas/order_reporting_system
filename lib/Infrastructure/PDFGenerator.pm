package Infrastructure::PDFGenerator;

use strict;
use warnings;
use PDF::API2;
use File::Path qw(make_path);
use File::Spec;

# ========================================================
# Function: generate_pdf
# Generates a PDF report based on the given order IDs. The PDF 
# includes customer details, order information, and item details.
# The generated PDF is saved in the `generated_pdfs` directory 
# with a unique filename.
# ========================================================
sub generate_pdf {
    my ($dbh, $order_ids) = @_;

    # Create a new PDF document
    my $pdf = PDF::API2->new();
    my $page = $pdf->page();
    $page->mediabox('Letter');

    # Fonts and styles
    my $font_title = $pdf->corefont('Helvetica-Bold');
    my $font_bold = $pdf->corefont('Helvetica-Bold');
    my $font_regular = $pdf->corefont('Helvetica');
    my $font_italic = $pdf->corefont('Helvetica-Oblique');

    # Header
    my $text = $page->text();
    $text->font($font_title, 24);
    $text->translate(200, 750);
    $text->text('Orders Report');

    # Footer
    my $footer = $page->text();
    $footer->font($font_regular, 10);
    $footer->translate(300, 20);
    $footer->text('Page 1');

    # Start position for order details
    my $y_position = 720;

    # Fetch order details from the database
    my $sth = $dbh->prepare("
        SELECT c.customer_id, c.first_name, c.last_name, 
               i.item_name, i.manufacturer, i.price, 
               o.order_number, o.order_date
        FROM orders o
        JOIN customers c ON o.customer_id = c.customer_id
        JOIN items i ON o.item_id = i.item_id
        WHERE o.order_id IN (" . join(",", ("?") x @$order_ids) . ")
        ORDER BY c.customer_id, o.order_date
    ");
    $sth->execute(@$order_ids);

    my $current_customer_id;

    # Process each order and add to the PDF
    while (my $row = $sth->fetchrow_hashref) {
        # Add a new page if content overflows
        if ($y_position < 100) {
            $page = $pdf->page();
            $text = $page->text();
            $text->font($font_regular, 12);
            $y_position = 750;

            # Add footer to each page
            $footer = $page->text();
            $footer->font($font_regular, 10);
            $footer->translate(300, 20);
            $footer->text('Page ' . $pdf->pages);
        }

        # Print customer details if changed
        if (!defined $current_customer_id || $current_customer_id != $row->{customer_id}) {
            $current_customer_id = $row->{customer_id};
            $text->font($font_bold, 16);
            $text->translate(50, $y_position);
            $text->text("$row->{first_name} $row->{last_name} (Customer ID: $row->{customer_id})");
            $y_position -= 30;
        }

        # Print order number
        $text->font($font_regular, 12);
        $text->translate(70, $y_position);
        $text->text("Order #$row->{order_number}");
        $y_position -= 25;

        # Print order date
        $text->translate(90, $y_position);
        $text->text("$row->{order_date}");
        $y_position -= 15;

        # Print item details
        $text->font($font_italic, 12);
        $text->translate(90, $y_position);
        my $price = $row->{price};
        $text->text("$row->{item_name} ($row->{manufacturer}) - $price");
        $y_position -= 30;
    }

    # Ensure the directory for PDFs exists
    my $directory = 'generated_pdfs';
    unless (-d $directory) {
        make_path($directory) or die "Failed to create directory: $directory";
    }

    # Generate a unique filename for the PDF
    my $base_filename = 'orders_report';
    my $ext = '.pdf';
    my $pdf_filename = File::Spec->catfile($directory, $base_filename . $ext);
    my $counter = 1;

    while (-e $pdf_filename) {
        $pdf_filename = File::Spec->catfile($directory, $base_filename . "_" . $counter++ . $ext);
    }

    # Save the PDF with a unique filename
    $pdf->saveas($pdf_filename);

    return $pdf_filename;
}

1;
