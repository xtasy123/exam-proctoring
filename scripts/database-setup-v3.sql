-- Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS it_proctool_system;
USE it_proctool_system;

-- Drop existing tables to recreate with proper structure
DROP TABLE IF EXISTS exam_sessions;
DROP TABLE IF EXISTS violations;
DROP TABLE IF EXISTS exams;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS teachers;
DROP TABLE IF EXISTS administrators;
DROP TABLE IF EXISTS system_logs;
DROP TABLE IF EXISTS proctoring_settings;

-- Create administrators table
CREATE TABLE administrators (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('super_admin', 'admin') DEFAULT 'admin',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create teachers table
CREATE TABLE teachers (
    id INT AUTO_INCREMENT PRIMARY KEY,
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
    id INT AUTO_INCREMENT PRIMARY KEY,
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
    id INT AUTO_INCREMENT PRIMARY KEY,
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
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    INDEX idx_teacher_id (teacher_id),
    INDEX idx_unique_id (unique_id),
    INDEX idx_status (status)
);

-- Create exam_sessions table
CREATE TABLE exam_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    exam_id INT NOT NULL,
    student_id INT NOT NULL,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP NULL,
    status ENUM('active', 'completed', 'terminated') DEFAULT 'active',
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    INDEX idx_exam_id (exam_id),
    INDEX idx_student_id (student_id),
    INDEX idx_session_token (session_token)
);

-- Create violations table
CREATE TABLE violations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    exam_session_id INT NOT NULL,
    student_name VARCHAR(255) NOT NULL,
    exam_title VARCHAR(255) NOT NULL,
    violation_type VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    severity ENUM('low', 'medium', 'high') DEFAULT 'medium',
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata JSON,
    FOREIGN KEY (exam_session_id) REFERENCES exam_sessions(id) ON DELETE CASCADE,
    INDEX idx_exam_session_id (exam_session_id),
    INDEX idx_violation_type (violation_type),
    INDEX idx_severity (severity),
    INDEX idx_timestamp (timestamp)
);

-- Create system_logs table
CREATE TABLE system_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_type ENUM('admin', 'teacher', 'student') NOT NULL,
    user_id INT NOT NULL,
    action VARCHAR(255) NOT NULL,
    description TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_type_id (user_type, user_id),
    INDEX idx_action (action),
    INDEX idx_timestamp (timestamp)
);

-- Create proctoring_settings table
CREATE TABLE proctoring_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    description TEXT,
    updated_by INT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_setting_key (setting_key)
);

-- Insert default administrator
INSERT INTO administrators (name, email, password_hash, role) VALUES 
('System Administrator', 'admin@itproctool.edu', '$2b$10$rQZ8kHp0rJ0YxGxGxGxGxOeKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK', 'super_admin');

-- Insert default teacher (password: teacher123)
INSERT INTO teachers (name, email, password_hash, department, employee_id) VALUES 
('Dr. John Smith', 'teacher@cec.edu', '$2b$10$rQZ8kHp0rJ0YxGxGxGxGxOeKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK', 'Computer Science', 'EMP001');

-- Insert sample students
INSERT INTO students (name, student_id, email, department, year_level) VALUES 
('Alice Johnson', 'STU001', 'alice@student.edu', 'Computer Science', 3),
('Bob Wilson', 'STU002', 'bob@student.edu', 'Information Technology', 2),
('Carol Davis', 'STU003', 'carol@student.edu', 'Computer Science', 4),
('David Brown', 'STU004', 'david@student.edu', 'Information Technology', 1),
('Eva Martinez', 'STU005', 'eva@student.edu', 'Computer Science', 3);

-- Insert default proctoring settings
INSERT INTO proctoring_settings (setting_key, setting_value, description) VALUES 
('max_violations_before_termination', '5', 'Maximum number of violations before automatically terminating exam'),
('enable_camera_monitoring', 'true', 'Enable camera-based monitoring during exams'),
('enable_screen_recording', 'false', 'Enable screen recording during exams'),
('violation_cooldown_seconds', '30', 'Cooldown period between violation detections'),
('auto_submit_on_violation_limit', 'true', 'Automatically submit exam when violation limit is reached');

-- Create indexes for better performance
CREATE INDEX idx_exams_teacher_status ON exams(teacher_id, status);
CREATE INDEX idx_violations_timestamp ON violations(timestamp DESC);
CREATE INDEX idx_exam_sessions_status ON exam_sessions(status);
