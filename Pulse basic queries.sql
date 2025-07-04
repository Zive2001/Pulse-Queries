select * from Users

-- Create Categories table
CREATE TABLE Categories (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE()
);

-- Create Subcategories table
CREATE TABLE Subcategories (
    id INT IDENTITY(1,1) PRIMARY KEY,
    category_id INT NOT NULL,
    name NVARCHAR(100) NOT NULL,
    requires_text_input BIT DEFAULT 0,
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (category_id) REFERENCES Categories(id)
);

select * from Subcategories


-- Create Support Persons table
CREATE TABLE SupportPersons (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    email NVARCHAR(255) NOT NULL,
    category_id INT NOT NULL,
    is_active BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (category_id) REFERENCES Categories(id)
);

-- Create main Tickets table
CREATE TABLE Tickets (
    id INT IDENTITY(1,1) PRIMARY KEY,
    ticket_number NVARCHAR(20) UNIQUE NOT NULL,
    title NVARCHAR(255) NOT NULL,
    description NTEXT NOT NULL,
    category_id INT NOT NULL,
    subcategory_id INT,
    subcategory_text NVARCHAR(255),
    software_name NVARCHAR(255),
    system_url NVARCHAR(500),
    type NVARCHAR(50) NOT NULL CHECK (type IN ('BreakFix', 'Application Error', 'Change Request')),
    urgency NVARCHAR(20) NOT NULL CHECK (urgency IN ('High', 'Medium', 'Low')),
    status NVARCHAR(50) DEFAULT 'Open' CHECK (status IN ('Open', 'In Progress', 'Pending Approval', 'Resolved', 'Closed')),
    created_by INT NOT NULL,
    assigned_to INT,
    mentioned_support_person INT,
    requires_manager_approval BIT DEFAULT 0,
    approved_by INT,
    approved_at DATETIME2,
    resolved_at DATETIME2,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (category_id) REFERENCES Categories(id),
    FOREIGN KEY (subcategory_id) REFERENCES Subcategories(id),
    FOREIGN KEY (created_by) REFERENCES Users(id),
    FOREIGN KEY (assigned_to) REFERENCES Users(id),
    FOREIGN KEY (mentioned_support_person) REFERENCES SupportPersons(id),
    FOREIGN KEY (approved_by) REFERENCES Users(id)
);


-- Create Ticket History table for tracking changes
CREATE TABLE TicketHistory (
    id INT IDENTITY(1,1) PRIMARY KEY,
    ticket_id INT NOT NULL,
    changed_by INT NOT NULL,
    field_name NVARCHAR(100) NOT NULL,
    old_value NVARCHAR(MAX),
    new_value NVARCHAR(MAX),
    change_reason NVARCHAR(255),
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (ticket_id) REFERENCES Tickets(id),
    FOREIGN KEY (changed_by) REFERENCES Users(id)
);