package Infrastructure::PDFGenerator;

use strict;
use warnings;
use PDF::API2;
use File::Path qw(make_path);
use File::Spec;
use File::Basename;

# ========================================================
# Function: generate_pdf
# ========================================================
sub generate_pdf {
    my ($dbh, $order_ids) = @_;

    my $pdf = PDF::API2->new();
    my $page = $pdf->page();
    my $font = $pdf->corefont('Helvetica-Bold');
    my $text = $page->text();
    $text->font($font, 20);
    $text->translate(200, 750);
    $text->text('Orders Report');

    $page->mediabox('Letter');
    my $y_position = 720;

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

    my $current_customer_id = undef;
    my $font_regular = $pdf->corefont('Helvetica');
    my $font_bold = $pdf->corefont('Helvetica-Bold');

    while (my $row = $sth->fetchrow_hashref) {
        if ($y_position < 100) {
            $page = $pdf->page();
            $text = $page->text();
            $text->font($font, 12);
            $y_position = 750;
        }

        if (!defined $current_customer_id || $current_customer_id != $row->{customer_id}) {
            $current_customer_id = $row->{customer_id};
            $text->font($font_bold, 14);
            $text->translate(50, $y_position);
            $text->text("$row->{first_name} $row->{last_name} (Customer ID: $row->{customer_id})");
            $y_position -= 20;
        }

        $text->font($font_regular, 12);
        $text->translate(70, $y_position);
        $text->text("Order $row->{order_number} - $row->{order_date}");
        $y_position -= 20;

        $text->translate(90, $y_position);
        $text->text("$row->{item_name} ($row->{manufacturer}) - \$" . sprintf('%.2f', $row->{price}));
        $y_position -= 20;
    }

    # Define the directory and ensure it exists
    my $directory = 'generated_pdfs';
    unless (-d $directory) {
        make_path($directory) or die "Failed to create directory: $directory";
    }

    # Generate a unique filename
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
