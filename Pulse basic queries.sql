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

-- Insert initial data
INSERT INTO Categories (name) VALUES 
('Data Analytics'),
('Software Systems');

INSERT INTO Subcategories (category_id, name, requires_text_input) VALUES 
(1, 'Power BI', 0),
(1, 'Excel', 0),
(1, 'Other', 1),
(2, 'System Issue', 0);


INSERT INTO SupportPersons (name, email, category_id) VALUES 
('Gayan', 'gayankar@masholdings.com', 1),
('Nadeesha', 'nadeeshasa@masholdings.com', 1),
('Ashen', 'ashenku@masholdings.com', 1),
('Gayan', 'gayankar@masholdings.com', 2),
('Supun', 'supunse@masholdings.com', 2),
('Nilaksha', 'NilakshaS@masholdings.com', 2);

-- Create indexes for better performance
CREATE INDEX IX_Tickets_CreatedBy ON Tickets(created_by);
CREATE INDEX IX_Tickets_AssignedTo ON Tickets(assigned_to);
CREATE INDEX IX_Tickets_Status ON Tickets(status);
CREATE INDEX IX_Tickets_Category ON Tickets(category_id);
CREATE INDEX IX_Tickets_CreatedAt ON Tickets(created_at);


-- Create trigger to update updated_at timestamp
CREATE TRIGGER TR_Tickets_UpdatedAt 
ON Tickets 
AFTER UPDATE 
AS 
BEGIN 
    UPDATE Tickets 
    SET updated_at = GETDATE() 
    WHERE id IN (SELECT id FROM inserted);
END;

CREATE TRIGGER TR_Users_UpdatedAt 
ON Users 
AFTER UPDATE 
AS 
BEGIN 
    UPDATE Users 
    SET updated_at = GETDATE() 
    WHERE id IN (SELECT id FROM inserted);
END;


Select*from TicketHistory

Select*from Tickets

select*from Users



ALTER TABLE Users 
ADD is_admin BIT DEFAULT 0,
    permissions NVARCHAR(500) DEFAULT NULL;
-- Ensure the target email exists in the Users table
-- If it does, update is_admin and permissions
-- If not, insert a new row

MERGE INTO Users AS target
USING (SELECT 'supunse@masholdings.com' AS email) AS source
ON target.email = source.email
WHEN MATCHED THEN
    UPDATE SET 
        target.is_admin = 1,
        target.permissions = 'delete_tickets,manage_support_persons,manage_managers,manage_categories,view_all_tickets,approve_tickets'
WHEN NOT MATCHED THEN
    INSERT (email, name, role, is_admin, permissions)
    VALUES (
        'supunse@masholdings.com',
        'Supun',
        'admin',
        1,
        'delete_tickets,manage_support_persons,manage_managers,manage_categories,view_all_tickets,approve_tickets'
    );


    UPDATE Users
SET role = 'admin'
WHERE email = 'supunse@masholdings.com';



CREATE TABLE AdminActions (
    id INT IDENTITY(1,1) PRIMARY KEY,
    admin_user_id INT NOT NULL,
    action_type NVARCHAR(100) NOT NULL, -- 'delete_ticket', 'add_support_person', 'add_manager', 'update_category', etc.
    target_type NVARCHAR(50) NOT NULL,  -- 'ticket', 'user', 'category', 'support_person'
    target_id INT NOT NULL,
    target_details NVARCHAR(MAX),
    action_description NVARCHAR(500),
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (admin_user_id) REFERENCES Users(id)
);