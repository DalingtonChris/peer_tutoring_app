-- PeerConnect Database Schema
-- Run this ONCE on the VPS before starting the server:
--   mysql -u root -p < peerconnect_db.sql

CREATE DATABASE IF NOT EXISTS peerconnect_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE peerconnect_db;

-- ─── users ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(100)  NOT NULL,
    email      VARCHAR(150)  NOT NULL UNIQUE,
    password   VARCHAR(255)  NOT NULL,
    role       ENUM('tutor', 'learner') NOT NULL DEFAULT 'learner',
    course     VARCHAR(100)  DEFAULT 'General',
    created_at TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
);

-- ─── tutor_profiles ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tutor_profiles (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    tutor_id   INT  NOT NULL UNIQUE,
    bio        TEXT,
    courses    TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tutor_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ─── tutor_subjects ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tutor_subjects (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    tutor_id    INT          NOT NULL,
    subject     VARCHAR(150) NOT NULL,
    description TEXT,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tutor_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ─── tutor_courses (legacy) ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tutor_courses (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    tutor_id    INT          NOT NULL,
    course_name VARCHAR(150) NOT NULL,
    FOREIGN KEY (tutor_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ─── requests ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS requests (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    student_id        INT          NOT NULL,
    course_name       VARCHAR(150) DEFAULT 'General',
    issue_description TEXT,
    status            ENUM('pending', 'answered') DEFAULT 'pending',
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ─── request_replies ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS request_replies (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    request_id  INT  NOT NULL,
    tutor_id    INT  NOT NULL,
    reply_text  TEXT NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (request_id) REFERENCES requests(id) ON DELETE CASCADE,
    FOREIGN KEY (tutor_id)   REFERENCES users(id)    ON DELETE CASCADE
);

-- ─── messages ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS messages (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    sender_id    INT  NOT NULL,
    receiver_id  INT  NOT NULL,
    message_text TEXT NOT NULL,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id)   REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ─── tutor_credits ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tutor_credits (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    tutor_id   INT NOT NULL,
    student_id INT NOT NULL,
    credits    INT NOT NULL DEFAULT 5,
    reason     VARCHAR(255) DEFAULT 'new_conversation',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tutor_id)   REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE
);
