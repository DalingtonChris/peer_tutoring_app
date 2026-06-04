require('dotenv').config();
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
    host:     process.env.DB_HOST     || 'localhost',
    user:     process.env.DB_USER     || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME     || 'peerconnect_db',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
});

// Create tutor_profiles table
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

// Create messages table
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

// ─── tutor_credits table ──────────────────────────────────────────────────────
db.query(`
    CREATE TABLE IF NOT EXISTS tutor_credits (
        id           INT AUTO_INCREMENT PRIMARY KEY,
        tutor_id     INT NOT NULL,
        student_id   INT NOT NULL,
        credits      INT NOT NULL DEFAULT 5,
        reason       VARCHAR(255) DEFAULT 'new_conversation',
        created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (tutor_id)   REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE
    )
`, (err) => {
    if (err) console.error('❌ Could not create tutor_credits table:', err.message);
    else console.log('✅ tutor_credits table ready');
});

// ─── request_replies table ────────────────────────────────────────────────────
db.query(`
    CREATE TABLE IF NOT EXISTS request_replies (
        id          INT AUTO_INCREMENT PRIMARY KEY,
        request_id  INT NOT NULL,
        tutor_id    INT NOT NULL,
        reply_text  TEXT NOT NULL,
        created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (request_id) REFERENCES requests(id) ON DELETE CASCADE,
        FOREIGN KEY (tutor_id)   REFERENCES users(id)    ON DELETE CASCADE
    )
`, (err) => {
    if (err) console.error('❌ Could not create request_replies table:', err.message);
    else console.log('✅ request_replies table ready');
});

console.log('✅ Connected to MySQL database successfully!');

const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*", methods: ["GET", "POST"] } });

// ─── 2. Authentication: REGISTER ─────────────────────────────────────────────
app.post('/api/register', (req, res) => {
    const { name, email, password, role, course } = req.body;
    const sql = "INSERT INTO users (name, email, password, role, course) VALUES (?, ?, ?, ?, ?)";
    db.query(sql, [name, email, password, role, course || 'General'], (err, result) => {
        if (err) {
            console.error('❌ Register SQL error:', err.message);
            return res.status(500).json({ success: false, message: err.message });
        }
        db.query("SELECT * FROM users WHERE id = ?", [result.insertId], (err2, rows) => {
            if (err2 || rows.length === 0) {
                return res.status(201).json({ success: true, userId: result.insertId });
            }
            res.status(201).json({ success: true, user: rows[0] });
        });
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

// ─── 3. TUTOR: Save / Update Profile ─────────────────────────────────────────
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

// ─── TUTOR: Get dashboard stats ───────────────────────────────────────────────
app.get('/api/tutor/stats/:tutor_id', (req, res) => {
    const { tutor_id } = req.params;

    const sql = `
        SELECT
            COALESCE(SUM(credits), 0)   AS rating_score,
            COUNT(DISTINCT student_id)  AS active_students
        FROM tutor_credits
        WHERE tutor_id = ?
    `;

    db.query(sql, [tutor_id], (err, results) => {
        if (err) {
            console.error("Stats SQL Error:", err);
            return res.status(500).json({ error: "Failed to fetch stats" });
        }
        res.json({
            rating_score:    results[0].rating_score    || 0,
            active_students: results[0].active_students || 0,
        });
    });
});

// ─── TUTOR: Get active students list ─────────────────────────────────────────
app.get('/api/tutor/active-students/:tutor_id', (req, res) => {
    const { tutor_id } = req.params;
    const sql = `
        SELECT
            u.id           AS student_id,
            u.name         AS student_name,
            u.course       AS course,
            SUM(tc.credits) AS credits_given,
            MAX(tc.created_at) AS last_interaction
        FROM tutor_credits tc
        JOIN users u ON u.id = tc.student_id
        WHERE tc.tutor_id = ?
        GROUP BY u.id, u.name, u.course
        ORDER BY last_interaction DESC
    `;
    db.query(sql, [tutor_id], (err, results) => {
        if (err) {
            console.error('❌ active-students error:', err.message);
            return res.status(500).json({ error: err.message });
        }
        res.json(results);
    });
});

// ─── Award +5 credits when a student first messages a tutor ──────────────────
app.post('/api/tutor/award-credits', (req, res) => {
    const { tutor_id, student_id } = req.body;
    if (!tutor_id || !student_id)
        return res.status(400).json({ success: false, message: "Missing tutor_id or student_id" });

    const checkSql = `
        SELECT id FROM tutor_credits
        WHERE tutor_id = ? AND student_id = ? AND reason = 'new_conversation'
        LIMIT 1
    `;
    db.query(checkSql, [tutor_id, student_id], (err, rows) => {
        if (err) return res.status(500).json({ success: false, message: err.message });

        if (rows.length > 0) {
            return res.json({ success: true, credited: false, message: "Already credited" });
        }

        const insertSql = `
            INSERT INTO tutor_credits (tutor_id, student_id, credits, reason)
            VALUES (?, ?, 5, 'new_conversation')
        `;
        db.query(insertSql, [tutor_id, student_id], (insertErr) => {
            if (insertErr) return res.status(500).json({ success: false, message: insertErr.message });
            console.log(`✅ +5 credits awarded to tutor ${tutor_id} for new student ${student_id}`);
            res.json({ success: true, credited: true, message: "+5 credits awarded" });
        });
    });
});

// ─── TUTOR: Reply to a help request ──────────────────────────────────────────
app.post('/api/tutor/reply/:request_id', (req, res) => {
    const { request_id } = req.params;
    const { tutor_id, reply_text } = req.body;

    if (!tutor_id || !reply_text || !reply_text.trim()) {
        return res.status(400).json({ success: false, message: "Missing tutor_id or reply_text" });
    }

    // Check if this tutor already has a reply for this request (edit vs first reply)
    db.query(
        'SELECT id FROM request_replies WHERE request_id = ? AND tutor_id = ? LIMIT 1',
        [request_id, tutor_id],
        (checkErr, existing) => {
            if (checkErr) {
                console.error("Reply check error:", checkErr);
                return res.status(500).json({ success: false, message: "Could not save reply" });
            }

            const isEdit = existing.length > 0;

            const sql    = isEdit
                ? 'UPDATE request_replies SET reply_text = ? WHERE id = ?'
                : 'INSERT INTO request_replies (request_id, tutor_id, reply_text) VALUES (?, ?, ?)';
            const params = isEdit
                ? [reply_text.trim(), existing[0].id]
                : [request_id, tutor_id, reply_text.trim()];

            db.query(sql, params, (err) => {
                if (err) {
                    console.error("Reply SQL Error:", err);
                    return res.status(500).json({ success: false, message: "Could not save reply" });
                }

                db.query(
                    "UPDATE requests SET status = 'answered' WHERE id = ?",
                    [request_id],
                    (updateErr) => {
                        if (updateErr) console.error("Status update error:", updateErr.message);
                    }
                );

                // ── Award +2 credits only on first reply, not on edits ────────
                if (!isEdit) {
                    db.query(
                        'SELECT student_id FROM requests WHERE id = ? LIMIT 1',
                        [request_id],
                        (selErr, rows) => {
                            if (selErr || !rows.length) return;
                            db.query(
                                `INSERT INTO tutor_credits (tutor_id, student_id, credits, reason)
                                 VALUES (?, ?, 2, 'answered_request')`,
                                [tutor_id, rows[0].student_id],
                                (insertErr) => {
                                    if (insertErr) console.error('❌ +2 credits error:', insertErr.message);
                                    else console.log(`✅ +2 credits awarded to tutor ${tutor_id} for request ${request_id}`);
                                }
                            );
                        }
                    );
                } else {
                    console.log(`📝 Tutor ${tutor_id} edited reply for request ${request_id} — no credits`);
                }

                res.json({ success: true, message: isEdit ? "Reply updated" : "Reply sent successfully" });
            });
        }
    );
});

// ─── STUDENT: Get their own requests + latest reply ──────────────────────────
app.get('/api/student/requests/:student_id', (req, res) => {
    const { student_id } = req.params;

    const sql = `
        SELECT r.*, u.name AS tutor_name, rr.reply_text, rr.created_at AS replied_at
        FROM requests r
        LEFT JOIN request_replies rr ON rr.request_id = r.id
            AND rr.id = (SELECT MAX(id) FROM request_replies WHERE request_id = r.id)
        LEFT JOIN users u ON u.id = rr.tutor_id
        WHERE r.student_id = ?
        ORDER BY r.id DESC
    `;

    db.query(sql, [student_id], (err, results) => {
        if (err) {
            console.error('❌ student requests error:', err.message);
            return res.status(500).json({ error: err.message });
        }
        res.json(results);
    });
});

// ─── STUDENT: Get tutors they have messaged ───────────────────────────────────
app.get('/api/student/conversations/:student_id', (req, res) => {
    const { student_id } = req.params;

    const sql = `
        SELECT
            u.id          AS tutor_id,
            u.name        AS tutor_name,
            m.message_text AS last_message,
            m.created_at  AS last_time
        FROM messages m
        JOIN users u ON u.id = m.receiver_id
        WHERE m.sender_id = ?
          AND m.created_at = (
              SELECT MAX(m2.created_at)
              FROM messages m2
              WHERE m2.sender_id = ? AND m2.receiver_id = m.receiver_id
          )
        ORDER BY m.created_at DESC
    `;

    db.query(sql, [student_id, student_id], (err, results) => {
        if (err) {
            console.error('❌ student conversations error:', err.message);
            return res.status(500).json({ error: err.message });
        }
        res.json(results);
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

// ─── 6. TUTOR: View pending requests (legacy route kept) ─────────────────────
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

// ─── 6.1 Get ALL requests (with student name + most recent reply) ─────────────
// ─── 6.1 Get ALL requests (simple + bulletproof) ─────────────────────────────
// Step 1: fetch all requests + student name
// Step 2: for each request, attach the latest reply (if any)
// Kept as two simple queries to avoid any JOIN/subquery MySQL version issues.
app.get('/api/requests', (req, res) => {
    const requestsQuery = `
        SELECT r.*, u.name AS student_name
        FROM requests r
        LEFT JOIN users u ON u.id = r.student_id
        ORDER BY r.id DESC
    `;

    db.query(requestsQuery, (err, requests) => {
        if (err) {
            console.error('❌ /api/requests — requests query failed:', err.message);
            return res.status(500).json({ error: err.message });
        }

        console.log(`✅ /api/requests — fetched ${requests.length} request(s)`);

        if (requests.length === 0) {
            return res.json([]);
        }

        // Fetch latest reply for every request in one query
        const repliesQuery = `
            SELECT rr.request_id, rr.reply_text, rr.created_at
            FROM request_replies rr
            WHERE rr.id IN (
                SELECT MAX(id) FROM request_replies GROUP BY request_id
            )
        `;

        db.query(repliesQuery, (repliesErr, replies) => {
            if (repliesErr) {
                // Replies failed — still return requests without reply_text
                console.error('❌ /api/requests — replies query failed:', repliesErr.message);
                return res.json(requests.map(r => ({ ...r, reply_text: null, replied_at: null })));
            }

            // Build a lookup map: request_id -> reply
            const replyMap = {};
            replies.forEach(r => { replyMap[r.request_id] = r; });

            // Merge replies into requests
            const merged = requests.map(r => ({
                ...r,
                reply_text: replyMap[r.id]?.reply_text ?? null,
                replied_at: replyMap[r.id]?.created_at ?? null,
            }));

            console.log(`✅ /api/requests — returning ${merged.length} merged row(s)`);
            res.json(merged);
        });
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

                // ── Award +5 to the TUTOR when a student messages them for the first time ──
                db.query(
                    'SELECT id, role FROM users WHERE id IN (?, ?)',
                    [data.sender_id, data.receiver_id],
                    (roleErr, users) => {
                        if (roleErr || users.length < 2) return;

                        const sender   = users.find(u => u.id === data.sender_id);
                        const receiver = users.find(u => u.id === data.receiver_id);
                        if (!sender || !receiver) return;

                        // Only proceed when a learner messages a tutor
                        if (sender.role !== 'learner' || receiver.role !== 'tutor') return;

                        const tutor_id   = receiver.id; // points go TO the tutor
                        const student_id = sender.id;   // student triggered the event

                        db.query(
                            `SELECT id FROM tutor_credits
                             WHERE tutor_id = ? AND student_id = ? AND reason = 'new_conversation'
                             LIMIT 1`,
                            [tutor_id, student_id],
                            (checkErr, existing) => {
                                if (checkErr || existing.length > 0) return; // already awarded
                                db.query(
                                    `INSERT INTO tutor_credits (tutor_id, student_id, credits, reason)
                                     VALUES (?, ?, 5, 'new_conversation')`,
                                    [tutor_id, student_id],
                                    (insertErr) => {
                                        if (insertErr) console.error('❌ +5 credits error:', insertErr.message);
                                        else console.log(`✅ +5 pts awarded to TUTOR ${tutor_id} — new student ${student_id}`);
                                    }
                                );
                            }
                        );
                    }
                );
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

// ─── GET conversations for a tutor ───────────────────────────────────────────
app.get('/api/conversations/:tutorId', (req, res) => {
    const { tutorId } = req.params;
    const sql = `
        SELECT
            u.id           AS student_id,
            u.name         AS student_name,
            m.message_text AS last_message,
            m.created_at   AS last_time
        FROM messages m
        JOIN users u ON u.id = m.sender_id
        WHERE m.receiver_id = ?
          AND m.created_at = (
            SELECT MAX(m2.created_at)
            FROM messages m2
            WHERE m2.sender_id = m.sender_id
              AND m2.receiver_id = ?
          )
        ORDER BY m.created_at DESC
    `;
    db.query(sql, [tutorId, tutorId], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
    });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () =>
    console.log(`🚀 Server running on http://0.0.0.0:${PORT}`)
);