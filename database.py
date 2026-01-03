"""
Database module for ClairText
Handles connections and operations for mastered and saved words
"""

import psycopg2
from psycopg2.extras import RealDictCursor
from contextlib import contextmanager

# Database connection parameters
DB_CONFIG = {
    'dbname': 'clairtext',
    'user': 'r3alistic',  # Default macOS user
    'host': 'localhost',
    'port': 5432
}

@contextmanager
def get_db_connection():
    """Context manager for database connections"""
    conn = psycopg2.connect(**DB_CONFIG)
    try:
        yield conn
        conn.commit()
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()

def get_excluded_words(user_id=1):
    """
    Get all words that should be excluded (mastered + saved)

    Args:
        user_id: User ID (default 1 for MVP)

    Returns:
        set: Set of words to exclude from analysis
    """
    excluded = set()

    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                # Get mastered words
                cur.execute("""
                    SELECT word FROM mastered_words WHERE user_id = %s
                """, (user_id,))
                excluded.update(row[0] for row in cur.fetchall())

                # Get saved words
                cur.execute("""
                    SELECT word FROM saved_words WHERE user_id = %s
                """, (user_id,))
                excluded.update(row[0] for row in cur.fetchall())

    except Exception as e:
        print(f"Error loading excluded words: {e}")

    return excluded

def master_word(word, difficulty, user_id=1):
    """
    Add a word to the mastered words (Cookie Jar)

    Args:
        word: The word to master
        difficulty: Difficulty score of the word
        user_id: User ID (default 1 for MVP)

    Returns:
        bool: True if successful
    """
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO mastered_words (word, difficulty, user_id)
                    VALUES (%s, %s, %s)
                    ON CONFLICT (word) DO NOTHING
                """, (word, difficulty, user_id))

                # Remove from saved if it was there
                cur.execute("""
                    DELETE FROM saved_words WHERE word = %s AND user_id = %s
                """, (word, user_id))

        print(f"Mastered word: {word}")
        return True

    except Exception as e:
        print(f"Error mastering word '{word}': {e}")
        return False

def save_word(word, difficulty, user_id=1):
    """
    Add a word to saved words (Save for Later)

    Args:
        word: The word to save
        difficulty: Difficulty score of the word
        user_id: User ID (default 1 for MVP)

    Returns:
        bool: True if successful
    """
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO saved_words (word, difficulty, user_id)
                    VALUES (%s, %s, %s)
                    ON CONFLICT (word) DO NOTHING
                """, (word, difficulty, user_id))

        print(f"Saved word for later: {word}")
        return True

    except Exception as e:
        print(f"Error saving word '{word}': {e}")
        return False

def get_mastered_words(user_id=1):
    """Get all mastered words for a user"""
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("""
                    SELECT word, difficulty, mastered_at
                    FROM mastered_words
                    WHERE user_id = %s
                    ORDER BY mastered_at DESC
                """, (user_id,))
                return cur.fetchall()
    except Exception as e:
        print(f"Error getting mastered words: {e}")
        return []

def get_saved_words(user_id=1):
    """Get all saved words for a user"""
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("""
                    SELECT word, difficulty, saved_at
                    FROM saved_words
                    WHERE user_id = %s
                    ORDER BY saved_at DESC
                """, (user_id,))
                return cur.fetchall()
    except Exception as e:
        print(f"Error getting saved words: {e}")
        return []
