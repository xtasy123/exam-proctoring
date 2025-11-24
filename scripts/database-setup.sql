-- IT Proctool System Database Schema
-- This script creates the necessary tables for the exam proctoring system

-- Create database
CREATE DATABASE IF NOT EXISTS cec_exam_system;
USE cec_exam_system;

-- Students table
CREATE TABLE students (
    id INT PRIMARY KEY AUTO_INCREMENT,
    student_id VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    status ENUM('active', 'suspended', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Teachers table
CREATE TABLE teachers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    department VARCHAR(100),
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Administrators table
CREATE TABLE administrators (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('super_admin', 'admin') DEFAULT 'admin',
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Exams table
CREATE TABLE exams (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    teacher_id INT NOT NULL,
    form_url VARCHAR(500) NOT NULL,
    duration_minutes INT NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    proctored BOOLEAN DEFAULT TRUE,
    status ENUM('draft', 'active', 'completed', 'cancelled') DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
);

-- Exam sessions table
CREATE TABLE exam_sessions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    exam_id INT NOT NULL,
    student_id INT NOT NULL,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    start_time TIMESTAMP NULL,
    end_time TIMESTAMP NULL,
    status ENUM('not_started', 'in_progress', 'completed', 'terminated') DEFAULT 'not_started',
    violations_count INT DEFAULT 0,
    final_score DECIMAL(5,2) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    UNIQUE KEY unique_student_exam (exam_id, student_id)
);

-- Violations table
CREATE TABLE violations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    session_id INT NOT NULL,
    violation_type ENUM('TAB_SWITCH', 'FULLSCREEN_EXIT', 'INACTIVITY', 'ALT_TAB', 'KEYBOARD_SHORTCUT', 'DEV_TOOLS', 'RIGHT_CLICK', 'MULTIPLE_SCREENS') NOT NULL,
    description TEXT NOT NULL,
    severity ENUM('low', 'medium', 'high') DEFAULT 'medium',
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved BOOLEAN DEFAULT FALSE,
    notes TEXT NULL,
    FOREIGN KEY (session_id) REFERENCES exam_sessions(id) ON DELETE CASCADE,
    INDEX idx_session_timestamp (session_id, timestamp),
    INDEX idx_violation_type (violation_type),
    INDEX idx_severity (severity)
);

-- System logs table
CREATE TABLE system_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    log_type ENUM('login', 'logout', 'violation', 'system', 'error', 'security') NOT NULL,
    user_type ENUM('student', 'teacher', 'admin', 'system') NOT NULL,
    user_id INT NULL,
    message TEXT NOT NULL,
    severity ENUM('low', 'medium', 'high', 'critical') DEFAULT 'low',
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_log_type (log_type),
    INDEX idx_user_type (user_type),
    INDEX idx_timestamp (timestamp),
    INDEX idx_severity (severity)
);

-- Proctoring settings table
CREATE TABLE proctoring_settings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    setting_name VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT NOT NULL,
    description TEXT NULL,
    updated_by INT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (updated_by) REFERENCES administrators(id) ON DELETE SET NULL
);

-- Insert default proctoring settings
INSERT INTO proctoring_settings (setting_name, setting_value, description) VALUES
('fullscreen_required', 'true', 'Require fullscreen mode during exams'),
('tab_switching_detection', 'true', 'Detect and flag tab switching'),
('inactivity_timeout', '300', 'Inactivity timeout in seconds (5 minutes)'),
('violation_threshold', '3', 'Number of violations before auto-flagging'),
('keyboard_shortcuts_blocked', 'true', 'Block common keyboard shortcuts'),
('right_click_disabled', 'true', 'Disable right-click context menu'),
('dev_tools_detection', 'true', 'Detect attempts to open developer tools'),
('session_timeout', '7200', 'Maximum exam session duration in seconds (2 hours)');

-- Insert default administrator account
INSERT INTO administrators (name, email, password_hash, role) VALUES
('System Administrator', 'admin@itproctool.edu', '$2y$10$example_hash_here', 'super_admin');

-- Insert sample teacher
INSERT INTO teachers (name, email, password_hash, department) VALUES
('Dr. Emily Wilson', 'teacher@cec.edu', '$2y$10$example_hash_here', 'Mathematics');

-- Insert sample students
INSERT INTO students (student_id, name, email, password_hash) VALUES
('STU001', 'John Smith', 'john.smith@student.cec.edu', '$2y$10$example_hash_here'),
('STU002', 'Sarah Johnson', 'sarah.johnson@student.cec.edu', '$2y$10$example_hash_here'),
('STU003', 'Mike Davis', 'mike.davis@student.cec.edu', '$2y$10$example_hash_here');

-- Create indexes for better performance
CREATE INDEX idx_students_student_id ON students(student_id);
CREATE INDEX idx_students_email ON students(email);
CREATE INDEX idx_teachers_email ON teachers(email);
CREATE INDEX idx_exams_teacher_id ON exams(teacher_id);
CREATE INDEX idx_exams_status ON exams(status);
CREATE INDEX idx_exam_sessions_exam_id ON exam_sessions(exam_id);
CREATE INDEX idx_exam_sessions_student_id ON exam_sessions(student_id);
CREATE INDEX idx_exam_sessions_status ON exam_sessions(status);
