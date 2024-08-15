# Notes on the Order Reporting System

## Overview

This document outlines the key decisions I made during the development of the Order Reporting System, focusing on the architecture, design patterns, and overall approach taken to solve the problem.

## Key Decisions

### 1. Domain-Driven Design (DDD)

**Decision**: The system was implemented using Domain-Driven Design (DDD) principles.

**Reasoning**: DDD is particularly well-suited for this project, which involves complex interactions between entities like customers, orders, and items. By structuring the system around the business domain, DDD ensures that the code remains closely aligned with business needs, scalable, and maintainable. This approach enables a clear separation of concerns, encapsulates business logic within the domain layer, and allows the system to evolve alongside business requirements.

**Implementation**:
- **Entities**: Core domain entities include `Customer`, `Item`, and `Order`, each encapsulating relevant attributes and behaviors.
- **Repositories**: Repositories such as `SQLiteCustomerRepository`, `SQLiteItemRepository`, and `SQLiteOrderRepository` abstract database operations, enabling the domain logic to interact with the database independently of its implementation.
- **Use Cases**: The use cases, `UploadCSVUseCase` and `GeneratePDFUseCase`, represent the system's business processes, orchestrating data flow between entities and repositories.

### 2. Database Structure

**Decision**: The database was structured into three main tables: `customers`, `items`, and `orders`.

**Reasoning**: This structure reflects the real-world relationships between customers, items, and orders, ensuring that the database is normalized, efficient, and easy to maintain. The separation into distinct tables avoids redundancy and aligns with best practices for relational database design.

**Implementation**:
- **Customers Table**: Stores customer details, with a primary key `customer_id`.
- **Items Table**: Stores item details, with a primary key `item_id`.
- **Orders Table**: Links customers to items, with foreign keys referencing `customer_id` and `item_id`.

### 3. CSV Processing

**Decision**: A dedicated CSV processor was implemented to handle data ingestion.

**Reasoning**: Since the system is expected to process CSV files frequently, a robust CSV processor ensures data integrity and automates the insertion process into the database, reducing manual intervention and potential errors.

**Implementation**:
- **Validation**: Each CSV row is validated to ensure completeness before insertion.
- **Duplicate Handling**: The system checks for duplicates in customers and orders, skipping redundant entries and logging them for reference.

### 4. PDF Generation

**Decision**: The system uses a Perl module (`PDF::API2`) to generate reports in PDF format.

**Reasoning**: While considering options like `wkhtmltopdf`, using a Perl module was preferred to minimize external dependencies, making the code easier to set up and use. PDF was chosen for its portability and ease of sharing, ensuring that reports are accessible and presentable.

**Implementation**:
- **Report Structure**: Reports are organized by customers, with clear grouping of orders and items. Headers, footers, and sectioning improve readability.

### 5. Modularization and Separation of Concerns

**Decision**: The project was designed with a modular architecture, ensuring a clear separation of concerns.

**Reasoning**: Modularization improves maintainability and extensibility by isolating different responsibilities within the codebase. This approach aligns with DDD principles, allowing each part of the system to be developed and tested independently.

**Implementation**:
- **Mojolicious for Web Interface**: Handles HTTP requests and serves the user interface, with routes defined in `app.pl`.
- **Repositories for Data Access**: Abstract database operations, separating data access from domain logic.
- **Use Cases for Business Logic**: Orchestrate business processes, ensuring a clean interaction between the domain layer and the infrastructure.

### 6. Testing Strategy

**Decision**: A comprehensive test suite was developed to cover key functionalities.

**Reasoning**: Testing is critical for ensuring the system's reliability and correctness. The tests were designed to cover the core entities, repository operations, and use cases, providing confidence in the system's behavior and robustness.

**Implementation**:
- **Entity Tests**: Verify correct instantiation and attribute behavior for domain entities.
- **Repository Tests**: Ensure correct CRUD operations, including handling of duplicates.
- **Use Case Tests**: Validate the correct operation of the CSV upload and PDF generation processes.

### 7. Compact and Readable Codebase

**Decision**: The project was kept compact by using only Perl, SQLite, and a single `index.html` file with embedded CSS and JavaScript.

**Reasoning**: By limiting the number of external dependencies and files, the project remains easy to understand, maintain, and deploy. Documentation is provided throughout the code to enhance readability and assist future developers in understanding the system's functionality.

**Implementation**:
- **Single HTML File**: All front-end code is contained in one file, simplifying the structure.
- **Perl and SQLite**: Core functionalities are implemented using Perl and SQLite.
- **Comprehensive Documentation**: The code is thoroughly documented to guide developers through the system's architecture and logic.
