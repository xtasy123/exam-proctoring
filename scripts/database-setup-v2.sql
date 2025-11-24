-- IT Proctool Database Setup
-- Updated version with proper field types and constraints

CREATE DATABASE IF NOT EXISTS it_proctool_system;
USE it_proctool_system;

-- Drop existing tables if they exist (for clean setup)
DROP TABLE IF EXISTS exam_sessions;
DROP TABLE IF EXISTS violations;
DROP TABLE IF EXISTS exams;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS teachers;
DROP TABLE IF EXISTS administrators;
DROP TABLE IF EXISTS system_logs;
DROP TABLE IF EXISTS proctoring_settings;

-- Administrators table
CREATE TABLE administrators (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('super_admin', 'admin') DEFAULT 'admin',
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
    phone VARCHAR(20),
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Students table
CREATE TABLE students (
    id INT PRIMARY KEY AUTO_INCREMENT,
    student_id VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    department VARCHAR(100),
    year_level INT,
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Exams table
CREATE TABLE exams (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    form_url TEXT NOT NULL,
    duration_minutes INT NOT NULL DEFAULT 60,
    start_time DATETIME,
    end_time DATETIME,
    teacher_id INT NOT NULL,
    unique_id VARCHAR(20) UNIQUE NOT NULL,
    status ENUM('draft', 'active', 'completed', 'cancelled') DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    INDEX idx_unique_id (unique_id),
    INDEX idx_teacher_id (teacher_id),
    INDEX idx_status (status)
);

-- Exam sessions table
CREATE TABLE exam_sessions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    exam_id INT NOT NULL,
    student_id INT NOT NULL,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP NULL,
    status ENUM('active', 'completed', 'terminated', 'flagged') DEFAULT 'active',
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    INDEX idx_exam_student (exam_id, student_id),
    INDEX idx_session_token (session_token),
    INDEX idx_status (status)
);

-- Violations table
CREATE TABLE violations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    session_id INT NOT NULL,
    exam_id INT NOT NULL,
    student_id INT NOT NULL,
    violation_type VARCHAR(50) NOT NULL,
    description TEXT,
    severity ENUM('low', 'medium', 'high') DEFAULT 'medium',
    metadata JSON,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES exam_sessions(id) ON DELETE CASCADE,
    FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    INDEX idx_session_id (session_id),
    INDEX idx_exam_id (exam_id),
    INDEX idx_student_id (student_id),
    INDEX idx_violation_type (violation_type),
    INDEX idx_severity (severity),
    INDEX idx_timestamp (timestamp)
);

-- System logs table
CREATE TABLE system_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_type ENUM('admin', 'teacher', 'student') NOT NULL,
    user_id INT NOT NULL,
    action VARCHAR(100) NOT NULL,
    description TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    metadata JSON,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_type_id (user_type, user_id),
    INDEX idx_action (action),
    INDEX idx_timestamp (timestamp)
);

-- Proctoring settings table
CREATE TABLE proctoring_settings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    description TEXT,
    updated_by INT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_setting_key (setting_key)
);

-- Insert default administrator
INSERT INTO administrators (name, email, password_hash, role) VALUES 
('System Administrator', 'admin@itproctool.edu', '$2b$10$rQZ9QmZJZGZJZGZJZGZJZO8K8K8K8K8K8K8K8K8K8K8K8K8K8K8K8K', 'super_admin');

-- Insert default teacher
INSERT INTO teachers (name, email, password_hash, department) VALUES 
('Demo Teacher', 'teacher@cec.edu', '$2b$10$teacher123hashedpassword', 'Computer Science');

-- Insert sample students
INSERT INTO students (student_id, name, email, department, year_level) VALUES 
('STU001', 'John Doe', 'john.doe@student.edu', 'Computer Science', 3),
('STU002', 'Jane Smith', 'jane.smith@student.edu', 'Information Technology', 2),
('STU003', 'Mike Johnson', 'mike.johnson@student.edu', 'Computer Engineering', 4),
('STU004', 'Sarah Wilson', 'sarah.wilson@student.edu', 'Computer Science', 1),
('STU005', 'David Brown', 'david.brown@student.edu', 'Information Technology', 3);

-- Insert default proctoring settings
INSERT INTO proctoring_settings (setting_key, setting_value, description) VALUES 
('max_violations_before_termination', '5', 'Maximum number of violations before automatically terminating exam'),
('enable_camera_monitoring', 'true', 'Enable camera-based monitoring during exams'),
('enable_screen_recording', 'false', 'Enable screen recording during exams'),
('violation_cooldown_seconds', '30', 'Cooldown period between similar violations'),
('auto_submit_on_violation_limit', 'true', 'Automatically submit exam when violation limit is reached');

-- Create views for easier data access
CREATE VIEW exam_summary AS
SELECT 
    e.id,
    e.title,
    e.unique_id,
    e.status,
    e.start_time,
    e.end_time,
    e.duration_minutes,
    t.name as teacher_name,
    t.department as teacher_department,
    COUNT(DISTINCT es.id) as total_sessions,
    COUNT(DISTINCT CASE WHEN es.status = 'active' THEN es.id END) as active_sessions,
    COUNT(DISTINCT v.id) as total_violations
FROM exams e
LEFT JOIN teachers t ON e.teacher_id = t.id
LEFT JOIN exam_sessions es ON e.id = es.exam_id
LEFT JOIN violations v ON e.id = v.exam_id
GROUP BY e.id, e.title, e.unique_id, e.status, e.start_time, e.end_time, e.duration_minutes, t.name, t.department;

-- Create view for violation summary
CREATE VIEW violation_summary AS
SELECT 
    v.id,
    v.violation_type,
    v.severity,
    v.timestamp,
    s.name as student_name,
    s.student_id,
    e.title as exam_title,
    e.unique_id as exam_unique_id,
    t.name as teacher_name
FROM violations v
JOIN students s ON v.student_id = s.id
JOIN exams e ON v.exam_id = e.id
JOIN teachers t ON e.teacher_id = t.id
ORDER BY v.timestamp DESC;

COMMIT;
