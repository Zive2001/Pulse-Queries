select * from Users

-- Create Categories table
CREATE TABLE Categories (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE()
);