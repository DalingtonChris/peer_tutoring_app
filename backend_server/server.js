const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const mysql = require('mysql2');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// ─── 1. Database Connection (Pool — never drops) ──────────────────────────────
const db = mysql.createPool({
    host: 'localhost',
    user: 'root',
    password: 'anye4cyber1!',
    database: 'peerconnect_db',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
});

// Create tutor_profiles table if it doesn't exist
db.query(`
    CREATE TABLE IF NOT EXISTS tutor_profiles (
        id          INT AUTO_INCREMENT PRIMARY KEY,
        tutor_id    INT NOT NULL UNIQUE,
        bio         TEXT,
        courses     TEXT,
        created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (tutor_id) REFERENCES users(id) ON DELETE CASCADE
    )
`, (err) => {
    if (err) console.error('❌ Could not create tutor_profiles table:', err.message);
    else console.log('✅ tutor_profiles table ready');
});

// Create messages table if it doesn't exist
db.query(`
    CREATE TABLE IF NOT EXISTS messages (
        id           INT AUTO_INCREMENT PRIMARY KEY,
        sender_id    INT NOT NULL,
        receiver_id  INT NOT NULL,
        message_text TEXT NOT NULL,
        created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (sender_id)   REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE
    )
`, (err) => {
    if (err) console.error('❌ Could not create messages table:', err.message);
    else console.log('✅ messages table ready');
});

console.log('✅ Connected to MySQL database successfully!');

const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*", methods: ["GET", "POST"] } });

// ─── 2. Authentication: REGISTER ─────────────────────────────────────────────
app.post('/api/register', (req, res) => {
    const { name, email, password, role, course } = req.body;
    const sql = "INSERT INTO users (name, email, password, role, course) VALUES (?, ?, ?, ?, ?)";
    db.query(sql, [name, email, password, role, course || 'General'], (err, result) => {
        if (err) return res.status(500).json({ success: false, message: "Registration failed" });
        res.status(201).json({ success: true, userId: result.insertId });
    });
});

// ─── 2.1 Authentication: LOGIN ────────────────────────────────────────────────
app.post('/api/login', (req, res) => {
    const { email, password } = req.body;
    db.query("SELECT * FROM users WHERE email = ? AND password = ?", [email, password], (err, results) => {
        if (err || results.length === 0)
            return res.status(401).json({ success: false, message: "Invalid credentials" });
        res.json({ success: true, user: results[0] });
    });
});

// ─── 3. TUTOR: Save / Update Profile (bio + courses) ─────────────────────────
app.post('/api/tutor/profile', (req, res) => {
    const { tutor_id, bio, courses } = req.body;
    if (!tutor_id) return res.status(400).json({ success: false, message: "Missing tutor_id" });

    const coursesStr = Array.isArray(courses) ? courses.join(',') : (courses || '');

    const sql = `
        INSERT INTO tutor_profiles (tutor_id, bio, courses)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE bio = VALUES(bio), courses = VALUES(courses)
    `;
    db.query(sql, [tutor_id, bio || '', coursesStr], (err) => {
        if (err) {
            console.error("SQL Error:", err);
            return res.status(500).json({ success: false, message: "Could not save profile" });
        }
        res.json({ success: true, message: "Profile saved successfully" });
    });
});

// ─── 3.1 TUTOR: Get their own profile ────────────────────────────────────────
app.get('/api/tutor/profile/:tutor_id', (req, res) => {
    const { tutor_id } = req.params;
    db.query("SELECT * FROM tutor_profiles WHERE tutor_id = ?", [tutor_id], (err, results) => {
        if (err) return res.status(500).json({ error: "Failed to fetch" });
        if (results.length === 0) return res.json({ exists: false });
        const profile = results[0];
        profile.courses = profile.courses ? profile.courses.split(',') : [];
        profile.exists = true;
        res.json(profile);
    });
});

// ─── 4. TUTOR: Add single course (legacy) ────────────────────────────────────
app.post('/api/tutor/add-course', (req, res) => {
    const { tutor_id, course_name } = req.body;
    db.query("INSERT INTO tutor_courses (tutor_id, course_name) VALUES (?, ?)", [tutor_id, course_name], (err) => {
        if (err) return res.status(500).json({ success: false });
        res.json({ success: true });
    });
});

// ─── 5. STUDENT: Create help request ─────────────────────────────────────────
app.post('/api/student/request', (req, res) => {
    console.log("Received Request:", req.body);
    const { student_id, course_name, issue_description } = req.body;
    if (!student_id)
        return res.status(400).json({ success: false, message: "Missing student_id" });

    const sql = "INSERT INTO requests (student_id, course_name, issue_description) VALUES (?, ?, ?)";
    db.query(sql, [student_id, course_name, issue_description], (err) => {
        if (err) {
            console.error("SQL Error:", err);
            return res.status(500).json({ success: false, message: "Server Database Error" });
        }
        res.json({ success: true });
    });
});

// ─── 6. TUTOR: View pending requests ─────────────────────────────────────────
app.get('/api/tutor/requests', (req, res) => {
    const sql = `
        SELECT r.*, u.name AS student_name
        FROM requests r
        JOIN users u ON r.student_id = u.id
        WHERE r.status = 'pending'
    `;
    db.query(sql, (err, results) => {
        if (err) return res.status(500).json({ error: "Failed to fetch" });
        res.json(results);
    });
});

// ─── 6.1 Get ALL requests ────────────────────────────────────────────────────
app.get('/api/requests', (req, res) => {
    const query = 'SELECT * FROM requests';
    db.query(query, (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results);
    });
});

// ─── 7. MARKETPLACE: Fetch All Tutors ────────────────────────────────────────
app.get('/api/tutors', (req, res) => {
    const { search, category } = req.query;

    let sql = `
        SELECT
            u.id        AS user_id,
            u.name,
            u.email,
            u.course    AS default_course,
            COALESCE(tp.bio, '')     AS bio,
            COALESCE(tp.courses, '') AS courses
        FROM users u
        LEFT JOIN tutor_profiles tp ON u.id = tp.tutor_id
        WHERE u.role = 'tutor'
    `;
    const params = [];

    if (search && search.trim() !== '') {
        sql += ' AND u.name LIKE ?';
        params.push(`%${search.trim()}%`);
    }

    if (category && category !== 'All') {
        sql += ' AND (tp.courses LIKE ? OR u.course LIKE ?)';
        params.push(`%${category}%`, `%${category}%`);
    }

    sql += ' ORDER BY u.name ASC';

    db.query(sql, params, (err, results) => {
        if (err) return res.status(500).json({ error: "Failed to fetch tutors" });
        const tutors = results.map(t => ({
            ...t,
            courses: t.courses ? t.courses.split(',').filter(Boolean) : []
        }));
        res.json(tutors);
    });
});

// ─── TUTOR: Add a subject with description ────────────────────────────────────
app.post('/api/tutor/subjects', (req, res) => {
    const { tutor_id, subject, description } = req.body;
    if (!tutor_id || !subject)
        return res.status(400).json({ success: false, message: "Missing tutor_id or subject" });

    const sql = "INSERT INTO tutor_subjects (tutor_id, subject, description) VALUES (?, ?, ?)";
    db.query(sql, [tutor_id, subject, description || ''], (err) => {
        if (err) {
            console.error("SQL Error:", err);
            return res.status(500).json({ success: false, message: err.message });
        }
        res.json({ success: true, message: "Subject saved successfully" });
    });
});

// ─── TUTOR: Get all subjects they teach ──────────────────────────────────────
app.get('/api/tutor/subjects/:tutor_id', (req, res) => {
    db.query(
        "SELECT * FROM tutor_subjects WHERE tutor_id = ? ORDER BY created_at DESC",
        [req.params.tutor_id],
        (err, results) => {
            if (err) return res.status(500).json({ error: "Failed to fetch subjects" });
            res.json(results);
        }
    );
});

// ─── TUTOR: Update a subject ──────────────────────────────────────────────────
app.put('/api/tutor/subjects/:id', (req, res) => {
    const { subject, description } = req.body;
    db.query(
        "UPDATE tutor_subjects SET subject = ?, description = ? WHERE id = ?",
        [subject, description || '', req.params.id],
        (err) => {
            if (err) return res.status(500).json({ success: false, message: err.message });
            res.json({ success: true, message: "Subject updated" });
        }
    );
});

// ─── TUTOR: Delete a subject ──────────────────────────────────────────────────
app.delete('/api/tutor/subjects/:id', (req, res) => {
    db.query("DELETE FROM tutor_subjects WHERE id = ?", [req.params.id], (err) => {
        if (err) return res.status(500).json({ success: false, message: err.message });
        res.json({ success: true, message: "Subject deleted" });
    });
});

// ─── MARKETPLACE: Get one tutor's full profile + subjects ─────────────────────
app.get('/api/tutors/:tutor_id/full', (req, res) => {
    const sql = `
        SELECT
            u.id, u.name, u.email,
            COALESCE(tp.bio, '') AS bio,
            ts.id AS subject_id,
            ts.subject,
            ts.description
        FROM users u
        LEFT JOIN tutor_profiles tp ON u.id = tp.tutor_id
        LEFT JOIN tutor_subjects ts  ON u.id = ts.tutor_id
        WHERE u.id = ?
        ORDER BY ts.created_at DESC
    `;
    db.query(sql, [req.params.tutor_id], (err, rows) => {
        if (err) return res.status(500).json({ error: "Failed to fetch tutor profile" });
        if (!rows.length) return res.status(404).json({ error: "Tutor not found" });

        res.json({
            id: rows[0].id,
            name: rows[0].name,
            email: rows[0].email,
            bio: rows[0].bio,
            subjects: rows
                .filter(r => r.subject_id !== null)
                .map(r => ({
                    id: r.subject_id,
                    subject: r.subject,
                    description: r.description
                }))
        });
    });
});

// ─── 8. Messaging & Sockets ───────────────────────────────────────────────────
io.on('connection', (socket) => {
    console.log('🔌 User connected:', socket.id);

    socket.on('join_room', (data) => {
        const roomName = `room_${Math.min(data.senderId, data.receiverId)}_${Math.max(data.senderId, data.receiverId)}`;
        socket.join(roomName);
        console.log(`👥 Joined room: ${roomName}`);
    });

    socket.on('send_message', (data) => {
        db.query(
            "INSERT INTO messages (sender_id, receiver_id, message_text) VALUES (?, ?, ?)",
            [data.sender_id, data.receiver_id, data.message_text],
            (err) => {
                if (err) {
                    console.error('❌ Error saving message:', err);
                    return;
                }
                const roomName = `room_${Math.min(data.sender_id, data.receiver_id)}_${Math.max(data.sender_id, data.receiver_id)}`;
                io.to(roomName).emit('receive_message', { ...data, timestamp: new Date().toISOString() });
            }
        );
    });

    socket.on('disconnect', () => {
        console.log('🔌 User disconnected:', socket.id);
    });
});

// ─── Get message history between two users ────────────────────────────────────
app.get('/api/messages/:user1/:user2', (req, res) => {
    const { user1, user2 } = req.params;
    const sql = `
        SELECT * FROM messages
        WHERE (sender_id = ? AND receiver_id = ?)
           OR (sender_id = ? AND receiver_id = ?)
        ORDER BY created_at ASC
    `;
    db.query(sql, [user1, user2, user2, user1], (err, results) => {
        if (err) {
            console.error('❌ Messages fetch error:', err);
            return res.status(500).json({ error: "Failed to fetch messages" });
        }
        res.json(results);
    });
});

const PORT = 3000;
server.listen(PORT, '0.0.0.0', () =>
    console.log(`🚀 Server running on http://192.168.1.145:${PORT}`)
);