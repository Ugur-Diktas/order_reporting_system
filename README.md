# Order Reporting System

## Overview

This project is an Order Reporting System that processes CSV files containing order data, stores them in an SQLite database, and generates reports in PDF format. The system is designed to handle multiple CSV uploads and accumulates data without overwriting existing records.

## Prerequisites

- Perl (5.10 or later)
- SQLite
- cpanm (for installing Perl dependencies)

If you don't have `cpanm` installed, you can install it using the following command:

curl -L https://cpanmin.us | perl - App::cpanminus

## Installation

1. **cd into the project directory**:
cd order-reporting-system

2. **Install Perl dependencies**:
Run the following command to install the required Perl modules:
cpanm --installdeps .

## Usage

1. **Start the server**:
Run the following command to start the Mojolicious server:
perl ./bin/app.pl daemon

2. **Access the application**:
Open your web browser and navigate to `http://localhost:3000` to access the Order Reporting System.

3. **Upload a CSV file**:
Use the "Upload CSV" section to upload a CSV file. The system will process the file and store the data in the SQLite database.

4. **Generate PDF report**:
In the "Orders" section, select the orders you want to include in the report, then click "Generate PDF". The system will generate a PDF report and download it.

5. **Delete Orders**:
Select orders in the list and click "Delete Orders" to remove them from the database.

## Testing

To run the test suite, use the following command:
prove -l

This will run all tests in the `t/` directory and provide a summary of the results.

The test suite covers the following aspects of the system:
- Entity creation (Customers, Items, Orders)
- Repository operations (insert, find, delete)
- CSV processing
- PDF generation

## Directory Structure

- `bin/`: Contains executable scripts.
- `db/`: Contains database migrations and seed data.
- `lib/`: Contains the Perl modules for the application.
- `public/`: Contains static files (index.html).
- `t/`: Contains the test files.