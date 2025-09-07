CREATE DATABASE schedu;
USE schedu;
-- Set default engine/charset
SET NAMES utf8mb4;

-- 1. Users & Roles (for authorized personnel)
CREATE TABLE roles (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  role_id INT NOT NULL,
  username VARCHAR(100) NOT NULL UNIQUE,
  full_name VARCHAR(200) NOT NULL,
  email VARCHAR(200) UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  is_active TINYINT(1) DEFAULT 1,
  last_login TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (role_id) REFERENCES roles(id)
) ENGINE=InnoDB;

-- 2. Departments & Shifts
CREATE TABLE departments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(20) NOT NULL UNIQUE,
  name VARCHAR(200) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE shifts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL, -- e.g., Morning, Evening
  start_time TIME,
  end_time TIME,
  description VARCHAR(255)
) ENGINE=InnoDB;

-- 3. Rooms and Room Types
CREATE TABLE room_types (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE, -- Lecture, Lab, Tutorial
  description VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE rooms (
  id INT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE, -- e.g., L-101, LAB-A
  name VARCHAR(200),
  room_type_id INT NOT NULL,
  capacity INT NOT NULL,
  location VARCHAR(255),
  is_active TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (room_type_id) REFERENCES room_types(id)
) ENGINE=InnoDB;

-- 4. Batches (groups of students) and Programs
CREATE TABLE programs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE, -- BTECH, MTECH, BCA
  name VARCHAR(200) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE batches (
  id INT AUTO_INCREMENT PRIMARY KEY,
  program_id INT NOT NULL,
  department_id INT NOT NULL,
  intake_year YEAR NOT NULL,
  batch_code VARCHAR(50), -- e.g., CSE-2023-A
  shift_id INT,
  strength INT DEFAULT 0,
  active TINYINT(1) DEFAULT 1,
  FOREIGN KEY (program_id) REFERENCES programs(id),
  FOREIGN KEY (department_id) REFERENCES departments(id),
  FOREIGN KEY (shift_id) REFERENCES shifts(id)
) ENGINE=InnoDB;

-- 5. Subjects & Subject Offerings (per batch/semester)
CREATE TABLE subjects (
  id INT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  credit_hours DECIMAL(4,2) DEFAULT 0,
  is_lab TINYINT(1) DEFAULT 0,
  department_id INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (department_id) REFERENCES departments(id)
) ENGINE=InnoDB;

CREATE TABLE subject_offerings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  subject_id INT NOT NULL,
  batch_id INT NOT NULL,
  semester INT NOT NULL,
  teaching_type ENUM('theory','lab','tutorial') DEFAULT 'theory',
  preferred_room_type_id INT,
  notes TEXT,
  active TINYINT(1) DEFAULT 1,
  FOREIGN KEY (subject_id) REFERENCES subjects(id),
  FOREIGN KEY (batch_id) REFERENCES batches(id),
  FOREIGN KEY (preferred_room_type_id) REFERENCES room_types(id)
) ENGINE=InnoDB;

-- 6. Class requirements: how many sessions needed
CREATE TABLE class_requirements (
  id INT AUTO_INCREMENT PRIMARY KEY,
  offering_id INT NOT NULL,
  sessions_per_week INT NOT NULL DEFAULT 0,
  max_sessions_per_day INT DEFAULT 1,
  session_duration_minutes INT DEFAULT 50,
  allow_consecutive_sessions TINYINT(1) DEFAULT 0,
  FOREIGN KEY (offering_id) REFERENCES subject_offerings(id)
) ENGINE=InnoDB;

-- 7. Faculties and mapping to subjects
CREATE TABLE faculties (
  id INT AUTO_INCREMENT PRIMARY KEY,
  employee_code VARCHAR(50) NOT NULL UNIQUE,
  full_name VARCHAR(200) NOT NULL,
  email VARCHAR(200) UNIQUE,
  phone VARCHAR(50),
  department_id INT,
  is_active TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (department_id) REFERENCES departments(id)
) ENGINE=InnoDB;

CREATE TABLE faculty_subjects (
  faculty_id INT NOT NULL,
  subject_id INT NOT NULL,
  PRIMARY KEY (faculty_id, subject_id),
  FOREIGN KEY (faculty_id) REFERENCES faculties(id),
  FOREIGN KEY (subject_id) REFERENCES subjects(id)
) ENGINE=InnoDB;

-- 8. Faculty availability and average leaves (leaves table)
CREATE TABLE slot_templates (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL, -- Slot 1, Slot 2
  day_of_week ENUM('Mon','Tue','Wed','Thu','Fri','Sat','Sun') DEFAULT 'Mon',
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  slot_index INT NOT NULL, -- e.g., 1..8
  shift_id INT,
  UNIQUE KEY (day_of_week, slot_index, shift_id),
  FOREIGN KEY (shift_id) REFERENCES shifts(id)
) ENGINE=InnoDB;

CREATE TABLE faculty_availability (
  id INT AUTO_INCREMENT PRIMARY KEY,
  faculty_id INT NOT NULL,
  day_of_week ENUM('Mon','Tue','Wed','Thu','Fri','Sat','Sun') NOT NULL,
  slot_index INT NOT NULL,
  available TINYINT(1) DEFAULT 1,
  note VARCHAR(255),
  FOREIGN KEY (faculty_id) REFERENCES faculties(id)
) ENGINE=InnoDB;

CREATE TABLE faculty_leaves (
  id INT AUTO_INCREMENT PRIMARY KEY,
  faculty_id INT NOT NULL,
  leave_date DATE NOT NULL,
  leave_type VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (faculty_id) REFERENCES faculties(id)
) ENGINE=InnoDB;

-- 9. Fixed (special) classes with locked slots
CREATE TABLE fixed_classes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  offering_id INT NOT NULL,
  day_of_week ENUM('Mon','Tue','Wed','Thu','Fri','Sat','Sun') NOT NULL,
  slot_index INT NOT NULL,
  room_id INT,
  faculty_id INT,
  note VARCHAR(255),
  FOREIGN KEY (offering_id) REFERENCES subject_offerings(id),
  FOREIGN KEY (room_id) REFERENCES rooms(id),
  FOREIGN KEY (faculty_id) REFERENCES faculties(id)
) ENGINE=InnoDB;

-- 10. Generated timetables and entries
CREATE TABLE generated_timetables (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  generated_by INT, -- user id
  generation_params JSON, -- input parameters used for generation
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status ENUM('draft','submitted','approved','rejected') DEFAULT 'draft',
  notes TEXT,
  FOREIGN KEY (generated_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE timetable_entries (
  id INT AUTO_INCREMENT PRIMARY KEY,
  timetable_id INT NOT NULL,
  offering_id INT NOT NULL,
  day_of_week ENUM('Mon','Tue','Wed','Thu','Fri','Sat','Sun') NOT NULL,
  slot_index INT NOT NULL,
  room_id INT NOT NULL,
  faculty_id INT NOT NULL,
  is_cover TINYINT(1) DEFAULT 0, -- if it's a cover class (replacement)
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (timetable_id) REFERENCES generated_timetables(id) ON DELETE CASCADE,
  FOREIGN KEY (offering_id) REFERENCES subject_offerings(id),
  FOREIGN KEY (room_id) REFERENCES rooms(id),
  FOREIGN KEY (faculty_id) REFERENCES faculties(id),
  UNIQUE KEY uq_timetable_slot (timetable_id, day_of_week, slot_index, room_id),
  UNIQUE KEY uq_timetable_faculty (timetable_id, day_of_week, slot_index, faculty_id)
) ENGINE=InnoDB;

-- 11. Approval workflow and suggestions
CREATE TABLE approvals (
  id INT AUTO_INCREMENT PRIMARY KEY,
  timetable_id INT NOT NULL,
  approved_by INT NOT NULL,
  role_snapshot VARCHAR(100),
  comment TEXT,
  action ENUM('approved','rejected','needs_changes') NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (timetable_id) REFERENCES generated_timetables(id) ON DELETE CASCADE,
  FOREIGN KEY (approved_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE suggestions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  timetable_id INT NOT NULL,
  entry_id INT NULL,
  suggestion_text TEXT NOT NULL,
  suggested_by INT,
  priority INT DEFAULT 5,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (timetable_id) REFERENCES generated_timetables(id) ON DELETE CASCADE,
  FOREIGN KEY (entry_id) REFERENCES timetable_entries(id),
  FOREIGN KEY (suggested_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- 12. Audit / logs
CREATE TABLE audit_logs (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  action VARCHAR(200),
  entity VARCHAR(100),
  entity_id VARCHAR(100),
  details JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

-- 13. Useful views (example) - show room occupancy per slot (read-only view)
-- (Note: MySQL views can't reference non-deterministic functions; keep simple)

-- 14. Index recommendations (already have many keys; add as needed)
CREATE INDEX idx_rooms_type_capacity ON rooms(room_type_id, capacity);
CREATE INDEX idx_faculty_dept ON faculties(department_id);
CREATE INDEX idx_offering_batch ON subject_offerings(batch_id, subject_id);
CREATE INDEX idx_timetable_entries_faculty_slot ON timetable_entries(faculty_id, day_of_week, slot_index);

/* ==========================
   Sample seed data (short)
   ==========================
*/
-- Roles
INSERT IGNORE INTO roles (name, description) VALUES ('admin','Full admin'),('scheduler','Scheduler user'),('hod','Head of Department');

-- Room types
INSERT IGNORE INTO room_types (name, description) VALUES ('Lecture','Regular lecture room'),('Lab','Computer lab / specialized lab');

-- Shifts sample
INSERT IGNORE INTO shifts (name, start_time, end_time) VALUES ('Morning','08:30:00','13:00:00'),('Afternoon','13:30:00','18:00:00');
 
 -- End of schema
SELECT * FROM departments;
SELECT * FROM faculties;
SELECT * FROM batches;
SELECT * FROM subjects;
SELECT * FROM rooms;