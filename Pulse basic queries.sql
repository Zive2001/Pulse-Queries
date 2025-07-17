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




-- 4. Create index for performance on admin actions
CREATE INDEX IX_AdminActions_AdminUser ON AdminActions(admin_user_id);
CREATE INDEX IX_AdminActions_ActionType ON AdminActions(action_type);
CREATE INDEX IX_AdminActions_CreatedAt ON AdminActions(created_at);


ALTER TABLE Tickets 
ADD is_deleted BIT DEFAULT 0,
    deleted_by INT NULL,
    deleted_at DATETIME2 NULL,
    FOREIGN KEY (deleted_by) REFERENCES Users(id);





 CREATE VIEW vw_ActiveTickets AS
SELECT 
    t.id, t.ticket_number, t.title, t.description, t.type, t.urgency, 
    t.status, t.created_at, t.updated_at, t.resolved_at,
    t.requires_manager_approval, t.approved_at,
    c.name as category_name,
    sc.name as subcategory_name,
    t.subcategory_text, t.software_name, t.system_url,
    u.name as created_by_name, u.email as created_by_email,
    a.name as assigned_to_name,
    sp.name as mentioned_support_person_name,
    ap.name as approved_by_name
FROM Tickets t
LEFT JOIN Categories c ON t.category_id = c.id
LEFT JOIN Subcategories sc ON t.subcategory_id = sc.id
LEFT JOIN Users u ON t.created_by = u.id
LEFT JOIN Users a ON t.assigned_to = a.id
LEFT JOIN SupportPersons sp ON t.mentioned_support_person = sp.id
LEFT JOIN Users ap ON t.approved_by = ap.id
WHERE t.is_deleted = 0;



select*from Users



-- Add remark column to Tickets table
ALTER TABLE Tickets 
ADD remark NTEXT NULL;

-- Add index for better performance (optional)
CREATE INDEX IX_Tickets_Remark ON Tickets(id) WHERE remark IS NOT NULL;



--from here onward a rechecking implemented 


















-- Database Schema Fix Script
-- Run this script to ensure all required columns and indexes exist

-- Add missing columns to Tickets table if they don't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Tickets') AND name = 'is_deleted')
BEGIN
    ALTER TABLE Tickets ADD is_deleted BIT DEFAULT 0;
END

-- Ensure Users table has all required columns
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'is_admin')
BEGIN
    ALTER TABLE Users ADD is_admin BIT DEFAULT 0;
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'permissions')
BEGIN
    ALTER TABLE Users ADD permissions NVARCHAR(500) DEFAULT NULL;
END

-- Create AdminActions table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AdminActions')
BEGIN
    CREATE TABLE AdminActions (
        id INT IDENTITY(1,1) PRIMARY KEY,
        admin_user_id INT NOT NULL,
        action_type NVARCHAR(100) NOT NULL,
        target_type NVARCHAR(50) NOT NULL,
        target_id INT NOT NULL,
        target_details NVARCHAR(MAX),
        action_description NVARCHAR(500),
        created_at DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (admin_user_id) REFERENCES Users(id)
    );
    
    -- Create indexes for performance
    CREATE INDEX IX_AdminActions_AdminUser ON AdminActions(admin_user_id);
    CREATE INDEX IX_AdminActions_ActionType ON AdminActions(action_type);
    CREATE INDEX IX_AdminActions_CreatedAt ON AdminActions(created_at);
END

-- Ensure Categories table exists
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Categories')
BEGIN
    CREATE TABLE Categories (
        id INT IDENTITY(1,1) PRIMARY KEY,
        name NVARCHAR(100) NOT NULL,
        created_at DATETIME2 DEFAULT GETDATE()
    );
END

-- Ensure Subcategories table exists
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Subcategories')
BEGIN
    CREATE TABLE Subcategories (
        id INT IDENTITY(1,1) PRIMARY KEY,
        category_id INT NOT NULL,
        name NVARCHAR(100) NOT NULL,
        requires_text_input BIT DEFAULT 0,
        created_at DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (category_id) REFERENCES Categories(id)
    );
END

-- Ensure SupportPersons table exists
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SupportPersons')
BEGIN
    CREATE TABLE SupportPersons (
        id INT IDENTITY(1,1) PRIMARY KEY,
        name NVARCHAR(100) NOT NULL,
        email NVARCHAR(255) NOT NULL,
        category_id INT NOT NULL,
        is_active BIT DEFAULT 1,
        created_at DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (category_id) REFERENCES Categories(id)
    );
END

-- Add unique constraint on email for SupportPersons if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('SupportPersons') AND name = 'UQ_SupportPersons_Email')
BEGIN
    ALTER TABLE SupportPersons ADD CONSTRAINT UQ_SupportPersons_Email UNIQUE (email);
END

-- Add unique constraint on email for Users if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Users') AND name = 'UQ_Users_Email')
BEGIN
    ALTER TABLE Users ADD CONSTRAINT UQ_Users_Email UNIQUE (email);
END

-- Insert default categories if they don't exist
IF NOT EXISTS (SELECT * FROM Categories WHERE name = 'Data Analytics')
BEGIN
    INSERT INTO Categories (name) VALUES ('Data Analytics');
END

IF NOT EXISTS (SELECT * FROM Categories WHERE name = 'Software Systems')
BEGIN
    INSERT INTO Categories (name) VALUES ('Software Systems');
END

-- Insert default subcategories if they don't exist
DECLARE @DataAnalyticsId INT = (SELECT id FROM Categories WHERE name = 'Data Analytics');
DECLARE @SoftwareSystemsId INT = (SELECT id FROM Categories WHERE name = 'Software Systems');

IF @DataAnalyticsId IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT * FROM Subcategories WHERE name = 'Power BI' AND category_id = @DataAnalyticsId)
    BEGIN
        INSERT INTO Subcategories (category_id, name, requires_text_input) VALUES (@DataAnalyticsId, 'Power BI', 0);
    END
    
    IF NOT EXISTS (SELECT * FROM Subcategories WHERE name = 'Excel' AND category_id = @DataAnalyticsId)
    BEGIN
        INSERT INTO Subcategories (category_id, name, requires_text_input) VALUES (@DataAnalyticsId, 'Excel', 0);
    END
    
    IF NOT EXISTS (SELECT * FROM Subcategories WHERE name = 'Other' AND category_id = @DataAnalyticsId)
    BEGIN
        INSERT INTO Subcategories (category_id, name, requires_text_input) VALUES (@DataAnalyticsId, 'Other', 1);
    END
END

IF @SoftwareSystemsId IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT * FROM Subcategories WHERE name = 'System Issue' AND category_id = @SoftwareSystemsId)
    BEGIN
        INSERT INTO Subcategories (category_id, name, requires_text_input) VALUES (@SoftwareSystemsId, 'System Issue', 0);
    END
END

-- Insert default support persons if they don't exist
IF @DataAnalyticsId IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT * FROM SupportPersons WHERE email = 'gayankar@masholdings.com' AND category_id = @DataAnalyticsId)
    BEGIN
        INSERT INTO SupportPersons (name, email, category_id) VALUES ('Gayan', 'gayankar@masholdings.com', @DataAnalyticsId);
    END
    
    IF NOT EXISTS (SELECT * FROM SupportPersons WHERE email = 'nadeeshasa@masholdings.com' AND category_id = @DataAnalyticsId)
    BEGIN
        INSERT INTO SupportPersons (name, email, category_id) VALUES ('Nadeesha', 'nadeeshasa@masholdings.com', @DataAnalyticsId);
    END
    
    IF NOT EXISTS (SELECT * FROM SupportPersons WHERE email = 'ashenku@masholdings.com' AND category_id = @DataAnalyticsId)
    BEGIN
        INSERT INTO SupportPersons (name, email, category_id) VALUES ('Ashen', 'ashenku@masholdings.com', @DataAnalyticsId);
    END
END

IF @SoftwareSystemsId IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT * FROM SupportPersons WHERE email = 'gayankar@masholdings.com' AND category_id = @SoftwareSystemsId)
    BEGIN
        INSERT INTO SupportPersons (name, email, category_id) VALUES ('Gayan', 'gayankar@masholdings.com', @SoftwareSystemsId);
    END
    
    IF NOT EXISTS (SELECT * FROM SupportPersons WHERE email = 'supunse@masholdings.com' AND category_id = @SoftwareSystemsId)
    BEGIN
        INSERT INTO SupportPersons (name, email, category_id) VALUES ('Supun', 'supunse@masholdings.com', @SoftwareSystemsId);
    END
    
    IF NOT EXISTS (SELECT * FROM SupportPersons WHERE email = 'NilakshaS@masholdings.com' AND category_id = @SoftwareSystemsId)
    BEGIN
        INSERT INTO SupportPersons (name, email, category_id) VALUES ('Nilaksha', 'NilakshaS@masholdings.com', @SoftwareSystemsId);
    END
END

-- Ensure admin user exists with proper permissions
IF NOT EXISTS (SELECT * FROM Users WHERE email = 'supunse@masholdings.com')
BEGIN
    INSERT INTO Users (email, name, role, is_admin, permissions)
    VALUES (
        'supunse@masholdings.com',
        'Supun',
        'admin',
        1,
        'delete_tickets,manage_support_persons,manage_managers,manage_categories,view_all_tickets,approve_tickets'
    );
END
ELSE
BEGIN
    UPDATE Users
    SET is_admin = 1,
        role = 'admin',
        permissions = 'delete_tickets,manage_support_persons,manage_managers,manage_categories,view_all_tickets,approve_tickets'
    WHERE email = 'supunse@masholdings.com';
END

-- Create necessary indexes for better performance if they don't exist
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Tickets') AND name = 'IX_Tickets_CreatedBy')
BEGIN
    CREATE INDEX IX_Tickets_CreatedBy ON Tickets(created_by);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Tickets') AND name = 'IX_Tickets_AssignedTo')
BEGIN
    CREATE INDEX IX_Tickets_AssignedTo ON Tickets(assigned_to);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Tickets') AND name = 'IX_Tickets_Status')
BEGIN
    CREATE INDEX IX_Tickets_Status ON Tickets(status);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Tickets') AND name = 'IX_Tickets_Category')
BEGIN
    CREATE INDEX IX_Tickets_Category ON Tickets(category_id);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Tickets') AND name = 'IX_Tickets_CreatedAt')
BEGIN
    CREATE INDEX IX_Tickets_CreatedAt ON Tickets(created_at);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Tickets') AND name = 'IX_Tickets_IsDeleted')
BEGIN
    CREATE INDEX IX_Tickets_IsDeleted ON Tickets(is_deleted);
END

PRINT 'Database schema update completed successfully!';