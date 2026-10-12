IF DB_ID('SchoolDB') IS NOT NULL
BEGIN
    ALTER DATABASE SchoolDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SchoolDB;
END
GO
CREATE DATABASE SchoolDB;
GO
USE SchoolDB;
GO

/* ---------- TABLES ---------- */
CREATE TABLE Departments (
    DepartmentID   INT PRIMARY KEY,
    DepartmentName NVARCHAR(60) NOT NULL
);

CREATE TABLE Students (
    StudentID   INT PRIMARY KEY,
    FirstName   NVARCHAR(50) NOT NULL,
    LastName    NVARCHAR(50) NOT NULL,
    Faculty     NVARCHAR(50) NOT NULL,   -- Science, Engineering, ...
    Programme   NVARCHAR(80) NOT NULL,
    YearOfStudy INT NOT NULL CHECK (YearOfStudy BETWEEN 1 AND 6)
);

CREATE TABLE Employees (
    EmployeeID   INT PRIMARY KEY,
    FirstName    NVARCHAR(50) NOT NULL,
    LastName     NVARCHAR(50) NOT NULL,
    JobTitle     NVARCHAR(60) NOT NULL,  -- Accountant, Lecturer, ...
    DepartmentID INT NOT NULL REFERENCES Departments(DepartmentID),
    Salary       DECIMAL(10,2)
);

CREATE TABLE Marks (
    MarkID       INT IDENTITY(1,1) PRIMARY KEY,
    StudentID    INT NOT NULL REFERENCES Students(StudentID),
    CourseCode   NVARCHAR(10) NOT NULL,
    Mark         DECIMAL(5,2) NOT NULL CHECK (Mark BETWEEN 0 AND 100),
    Semester     INT NOT NULL CHECK (Semester IN (1,2)),
    AcademicYear INT NOT NULL
);
GO

/* ---------- SAMPLE DATA ---------- */
INSERT INTO Departments VALUES
 (1,'Finance'),(2,'Computer Science'),(3,'Civil Engineering'),(4,'Biology'),(5,'Administration');

INSERT INTO Students VALUES
 (1001,'Thato','Moeng','Science','BSc Computer Science',2),
 (1002,'Neo','Kgosi','Science','BSc Biology',1),
 (1003,'Kabelo','Sebina','Engineering','BEng Civil Engineering',2),
 (1004,'Lerato','Dube','Engineering','BEng Electrical Engineering',2),
 (1005,'Mpho','Tau','Engineering','BEng Mechanical Engineering',3),
 (1006,'Boitumelo','Ndlovu','Science','BSc Chemistry',2),
 (1007,'Tebogo','Phiri','Engineering','BEng Civil Engineering',1);

INSERT INTO Employees VALUES
 (1,'Gaone','Mothibi','Accountant',1,18000),
 (2,'Onalenna','Sithole','Accountant',1,17500),
 (3,'Kefilwe','Rantao','Lecturer',2,25000),
 (4,'Tumelo','Bogatsu','Lecturer',3,26000),
 (5,'Masego','Kelesitse','Lab Technician',4,12000),
 (6,'Lesedi','Mosimane','Administrator',5,14000);

INSERT INTO Marks (StudentID,CourseCode,Mark,Semester,AcademicYear) VALUES
 (1001,'COMP311',72,2,2024),(1001,'COMP332',65,2,2024),
 (1002,'BIO101',48,2,2024),(1002,'CHEM101',60,2,2024),
 (1003,'ENG201',55,2,2024),(1003,'ENG202',80,2,2024),
 (1004,'ENG203',90,2,2024),(1005,'ENG301',58,1,2024),
 (1006,'CHEM201',67,2,2024),(1007,'ENG101',45,2,2023);
GO

/* ---------- QUERIES ---------- */

-- a) all students from Science faculty
SELECT * FROM Students WHERE Faculty = 'Science';

-- b) accountants in the organisation
SELECT * FROM Employees WHERE JobTitle = 'Accountant';

-- c) all employees
SELECT * FROM Employees;

-- d) all departments
SELECT * FROM Departments;

-- e) all students
SELECT * FROM Students;

-- f) year 2 Engineering students
SELECT * FROM Students WHERE Faculty = 'Engineering' AND YearOfStudy = 2;
GO

/* g) pass/fail check (pass mark = 60 or above) */
CREATE PROCEDURE CheckStudentResult @StudentID INT
AS
BEGIN
    SELECT s.StudentID, s.FirstName, s.LastName, m.CourseCode, m.Mark,
           CASE WHEN m.Mark >= 60 THEN 'PASSED' ELSE 'FAILED' END AS Result
    FROM Students s
    JOIN Marks m ON m.StudentID = s.StudentID
    WHERE s.StudentID = @StudentID;
END
GO
EXEC CheckStudentResult @StudentID = 1003;
GO

-- h) average mark of students in semester 2, year 2024
SELECT AVG(Mark) AS AvgMark_Sem2_2024
FROM Marks
WHERE Semester = 2 AND AcademicYear = 2024;

-- (optional) average per student
SELECT StudentID, AVG(Mark) AS AvgMark
FROM Marks
WHERE Semester = 2 AND AcademicYear = 2024
GROUP BY StudentID;
GO

/* i) modify (g): handle student ID that does not exist */
ALTER PROCEDURE CheckStudentResult @StudentID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Students WHERE StudentID = @StudentID)
        BEGIN
            PRINT 'Error: student ID ' + CAST(@StudentID AS VARCHAR(20)) + ' does not exist.';
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM Marks WHERE StudentID = @StudentID)
        BEGIN
            PRINT 'Student exists but has no marks recorded.';
            RETURN;
        END

        SELECT s.StudentID, s.FirstName, s.LastName, m.CourseCode, m.Mark,
               CASE WHEN m.Mark >= 60 THEN 'PASSED' ELSE 'FAILED' END AS Result
        FROM Students s
        JOIN Marks m ON m.StudentID = s.StudentID
        WHERE s.StudentID = @StudentID;
    END TRY
    BEGIN CATCH
        PRINT 'Unexpected error: ' + ERROR_MESSAGE();
    END CATCH
END
GO
EXEC CheckStudentResult @StudentID = 1003;   -- exists
EXEC CheckStudentResult @StudentID = 9999;   -- does not exist
GO