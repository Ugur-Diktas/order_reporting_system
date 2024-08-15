package Application::Validation;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(validate_csv_file validate_order_ids);

# ========================================================
# Function: validate_csv_file
# Validates that the uploaded file is a valid CSV file.
# Returns (1, "Valid CSV file") if valid, otherwise (0, error message).
# ========================================================
sub validate_csv_file {
    my ($upload) = @_;

    unless ($upload) {
        return (0, "No file uploaded");
    }

    unless ($upload->filename =~ /\.csv$/i) {
        return (0, "Invalid file type. Please upload a CSV file.");
    }

    return (1, "Valid CSV file");
}

# ========================================================
# Function: validate_order_ids
# Validates that the provided order IDs are an array of valid integers.
# Returns (1, "Valid order IDs") if valid, otherwise (0, error message).
# ========================================================
sub validate_order_ids {
    my ($order_ids) = @_;

    unless ($order_ids && ref($order_ids) eq 'ARRAY' && @$order_ids) {
        return (0, "No orders selected or invalid input format");
    }

    foreach my $id (@$order_ids) {
        unless ($id =~ /^\d+$/) {
            return (0, "Invalid order ID: $id");
        }
    }

    return (1, "Valid order IDs");
}

1;
