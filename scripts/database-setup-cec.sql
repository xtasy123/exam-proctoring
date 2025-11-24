-- IT Proctool Database Setup for cec_exam_system
-- Run this script in phpMyAdmin

USE cec_exam_system;

-- Drop existing tables if they exist
DROP TABLE IF EXISTS violations;
DROP TABLE IF EXISTS exam_sessions;
DROP TABLE IF EXISTS system_logs;
DROP TABLE IF EXISTS exams;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS teachers;
DROP TABLE IF EXISTS administrators;
DROP TABLE IF EXISTS proctoring_settings;

-- Create administrators table
CREATE TABLE administrators (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('super_admin', 'admin') DEFAULT 'admin',
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create teachers table
CREATE TABLE teachers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    department VARCHAR(255),
    employee_id VARCHAR(50) UNIQUE,
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create students table
CREATE TABLE students (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    student_id VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    department VARCHAR(255),
    year_level INT,
    status ENUM('active', 'inactive', 'graduated') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create exams table
CREATE TABLE exams (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    form_url TEXT NOT NULL,
    duration_minutes INT DEFAULT 60,
    start_time DATETIME,
    end_time DATETIME,
    teacher_id INT NOT NULL,
    unique_id VARCHAR(20) UNIQUE NOT NULL,
    status ENUM('draft', 'active', 'completed', 'cancelled') DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
);

-- Create exam_sessions table
CREATE TABLE exam_sessions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    exam_id INT NOT NULL,
    student_id INT NOT NULL,
    session_token VARCHAR(255) UNIQUE,
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP NULL,
    status ENUM('active', 'completed', 'terminated') DEFAULT 'active',
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

-- Create violations table
CREATE TABLE violations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    exam_session_id INT,
    student_name VARCHAR(255) NOT NULL,
    exam_title VARCHAR(255) NOT NULL,
    violation_type VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    severity ENUM('low', 'medium', 'high') DEFAULT 'medium',
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata JSON,
    FOREIGN KEY (exam_session_id) REFERENCES exam_sessions(id) ON DELETE SET NULL
);

-- Create system_logs table
CREATE TABLE system_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_type ENUM('admin', 'teacher', 'student') NOT NULL,
    user_id INT NOT NULL,
    action VARCHAR(255) NOT NULL,
    description TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create proctoring_settings table
CREATE TABLE proctoring_settings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    description TEXT,
    updated_by INT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insert sample administrators
INSERT INTO administrators (name, email, password_hash, role) VALUES
('System Administrator', 'admin@itproctool.edu', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'super_admin'),
('IT Admin', 'it.admin@itproctool.edu', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin');

-- Insert sample teachers
INSERT INTO teachers (name, email, password_hash, department, employee_id) VALUES
('Dr. John Smith', 'teacher@cec.edu', 'teacher123', 'Computer Science', 'EMP001'),
('Prof. Sarah Johnson', 'sarah.johnson@cec.edu', 'password123', 'Information Technology', 'EMP002'),
('Dr. Michael Brown', 'michael.brown@cec.edu', 'password123', 'Computer Engineering', 'EMP003'),
('Prof. Lisa Davis', 'lisa.davis@cec.edu', 'password123', 'Software Engineering', 'EMP004'),
('Dr. Robert Wilson', 'robert.wilson@cec.edu', 'password123', 'Computer Science', 'EMP005');

-- Insert sample students
INSERT INTO students (name, student_id, email, department, year_level) VALUES
('Alice Johnson', 'STU001', 'alice.johnson@student.cec.edu', 'Computer Science', 3),
('Bob Wilson', 'STU002', 'bob.wilson@student.cec.edu', 'Information Technology', 2),
('Carol Davis', 'STU003', 'carol.davis@student.cec.edu', 'Computer Science', 4),
('David Brown', 'STU004', 'david.brown@student.cec.edu', 'Information Technology', 1),
('Eva Martinez', 'STU005', 'eva.martinez@student.cec.edu', 'Computer Science', 3),
('Frank Taylor', 'STU006', 'frank.taylor@student.cec.edu', 'Computer Engineering', 2),
('Grace Lee', 'STU007', 'grace.lee@student.cec.edu', 'Software Engineering', 4),
('Henry Chen', 'STU008', 'henry.chen@student.cec.edu', 'Information Technology', 3),
('Ivy Rodriguez', 'STU009', 'ivy.rodriguez@student.cec.edu', 'Computer Science', 1),
('Jack Thompson', 'STU010', 'jack.thompson@student.cec.edu', 'Computer Engineering', 2);

-- Insert sample exams
INSERT INTO exams (title, description, form_url, duration_minutes, teacher_id, unique_id, status) VALUES
('Database Systems Midterm', 'Midterm examination covering database design and SQL', 'https://forms.google.com/sample1', 120, 1, 'EXAM001', 'active'),
('Programming Fundamentals Quiz', 'Weekly quiz on programming concepts', 'https://forms.google.com/sample2', 60, 2, 'EXAM002', 'draft'),
('Data Structures Final', 'Final examination on data structures and algorithms', 'https://forms.google.com/sample3', 180, 3, 'EXAM003', 'completed');

-- Insert sample proctoring settings
INSERT INTO proctoring_settings (setting_key, setting_value, description) VALUES
('violation_threshold', '3', 'Maximum violations before automatic termination'),
('tab_switch_enabled', 'true', 'Enable tab switching detection'),
('right_click_disabled', 'true', 'Disable right-click during exams'),
('copy_paste_disabled', 'true', 'Disable copy-paste during exams'),
('fullscreen_required', 'true', 'Require fullscreen mode during exams');

-- Create indexes for better performance
CREATE INDEX idx_teachers_email ON teachers(email);
CREATE INDEX idx_students_student_id ON students(student_id);
CREATE INDEX idx_exams_unique_id ON exams(unique_id);
CREATE INDEX idx_exams_teacher_id ON exams(teacher_id);
CREATE INDEX idx_exam_sessions_exam_id ON exam_sessions(exam_id);
CREATE INDEX idx_violations_exam_session_id ON violations(exam_session_id);
CREATE INDEX idx_system_logs_user_type_id ON system_logs(user_type, user_id);

SELECT 'Database setup completed successfully!' as message;
