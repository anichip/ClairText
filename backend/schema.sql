-- ClairText Database Schema

-- Table for mastered words (Cookie Jar)
CREATE TABLE IF NOT EXISTS mastered_words (
    id SERIAL PRIMARY KEY,
    word TEXT NOT NULL UNIQUE,
    difficulty REAL,
    mastered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_id INTEGER DEFAULT 1  -- For future multi-user support
);

-- Table for saved words (Save for Later)
CREATE TABLE IF NOT EXISTS saved_words (
    id SERIAL PRIMARY KEY,
    word TEXT NOT NULL UNIQUE,
    difficulty REAL,
    saved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_id INTEGER DEFAULT 1  -- For future multi-user support
);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_mastered_words_word ON mastered_words(word);
CREATE INDEX IF NOT EXISTS idx_saved_words_word ON saved_words(word);
CREATE INDEX IF NOT EXISTS idx_mastered_words_user ON mastered_words(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_words_user ON saved_words(user_id);
