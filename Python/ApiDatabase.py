# ApiDatabase.py
import sqlite3
import hashlib
import secrets
from typing import Optional, List, Dict
import logging
from datetime import datetime

logger = logging.getLogger('api_database')

class DatabaseManager:
    def __init__(self, db_path: str = '/sqlite/users.db'):
        self.db_path = db_path
        self._init_db()
    
    def _init_db(self):
        """Initialize database and create tables if they don't exist"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                # Users table
                cursor.execute('''
                    CREATE TABLE IF NOT EXISTS users (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        username TEXT UNIQUE NOT NULL,
                        password_hash TEXT NOT NULL,
                        role TEXT NOT NULL DEFAULT 'user',
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        last_login TIMESTAMP,
                        active BOOLEAN DEFAULT 1
                    )
                ''')
                
                # Access tokens table for session management
                cursor.execute('''
                    CREATE TABLE IF NOT EXISTS access_tokens (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        user_id INTEGER,
                        token TEXT UNIQUE NOT NULL,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        expires_at TIMESTAMP NOT NULL,
                        FOREIGN KEY (user_id) REFERENCES users (id)
                    )
                ''')
                
                conn.commit()
                logger.info("Database initialized successfully")
        except Exception as e:
            logger.error(f"Database initialization error: {e}")
            raise

    def add_user(self, username: str, password: str, role: str = 'user') -> bool:
        """Add a new user to the database"""
        try:
            password_hash = hashlib.sha256(password.encode()).hexdigest()
            
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute(
                    'INSERT INTO users (username, password_hash, role) VALUES (?, ?, ?)',
                    (username, password_hash, role)
                )
                conn.commit()
                logger.info(f"User {username} added successfully")
                return True
        except sqlite3.IntegrityError:
            logger.warning(f"User {username} already exists")
            return False
        except Exception as e:
            logger.error(f"Error adding user: {e}")
            return False

    def verify_user(self, username: str, password: str) -> Optional[Dict]:
        """Verify user credentials and return user data if valid"""
        try:
            password_hash = hashlib.sha256(password.encode()).hexdigest()
            
            with sqlite3.connect(self.db_path) as conn:
                conn.row_factory = sqlite3.Row
                cursor = conn.cursor()
                
                cursor.execute('''
                    SELECT id, username, role, active
                    FROM users
                    WHERE username = ? AND password_hash = ? AND active = 1
                ''', (username, password_hash))
                
                user = cursor.fetchone()
                
                if user:
                    # Update last login time
                    cursor.execute(
                        'UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = ?',
                        (user['id'],)
                    )
                    conn.commit()
                    
                    return dict(user)
                return None
        except Exception as e:
            logger.error(f"Error verifying user: {e}")
            return None

    def create_session(self, user_id: int, expires_in: int = 3600) -> Optional[str]:
        """Create a new session token for user"""
        try:
            token = secrets.token_urlsafe(32)
            expires_at = datetime.now().timestamp() + expires_in
            
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute(
                    'INSERT INTO access_tokens (user_id, token, expires_at) VALUES (?, ?, ?)',
                    (user_id, token, expires_at)
                )
                conn.commit()
                return token
        except Exception as e:
            logger.error(f"Error creating session: {e}")
            return None

    def verify_session(self, token: str) -> Optional[Dict]:
        """Verify session token and return user data if valid"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                conn.row_factory = sqlite3.Row
                cursor = conn.cursor()
                
                cursor.execute('''
                    SELECT u.id, u.username, u.role
                    FROM users u
                    JOIN access_tokens t ON u.id = t.user_id
                    WHERE t.token = ? AND t.expires_at > ? AND u.active = 1
                ''', (token, datetime.now().timestamp()))
                
                user = cursor.fetchone()
                return dict(user) if user else None
        except Exception as e:
            logger.error(f"Error verifying session: {e}")
            return None

    def invalidate_session(self, token: str) -> bool:
        """Invalidate a session token"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute('DELETE FROM access_tokens WHERE token = ?', (token,))
                conn.commit()
                return True
        except Exception as e:
            logger.error(f"Error invalidating session: {e}")
            return False

    def list_users(self) -> List[Dict]:
        """List all users (excluding password hashes)"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                conn.row_factory = sqlite3.Row
                cursor = conn.cursor()
                cursor.execute('''
                    SELECT id, username, role, created_at, last_login, active
                    FROM users
                    ORDER BY username
                ''')
                return [dict(row) for row in cursor.fetchall()]
        except Exception as e:
            logger.error(f"Error listing users: {e}")
            return []

    def modify_user(self, user_id: int, **kwargs) -> bool:
        """Modify user attributes"""
        allowed_fields = {'username', 'password', 'role', 'active'}
        update_fields = {k: v for k, v in kwargs.items() if k in allowed_fields}
        
        if 'password' in update_fields:
            update_fields['password_hash'] = hashlib.sha256(
                update_fields.pop('password').encode()
            ).hexdigest()
        
        if not update_fields:
            return False
        
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                set_clause = ', '.join(f'{k} = ?' for k in update_fields)
                values = tuple(update_fields.values()) + (user_id,)
                
                cursor.execute(
                    f'UPDATE users SET {set_clause} WHERE id = ?',
                    values
                )
                conn.commit()
                return True
        except Exception as e:
            logger.error(f"Error modifying user: {e}")
            return False

    def delete_user(self, user_id: int) -> bool:
        """Delete a user (or set inactive)"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                # Soft delete - just set inactive
                cursor.execute(
                    'UPDATE users SET active = 0 WHERE id = ?',
                    (user_id,)
                )
                conn.commit()
                return True
        except Exception as e:
            logger.error(f"Error deleting user: {e}")
            return False

    def cleanup_sessions(self) -> int:
        """Clean up expired sessions"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute(
                    'DELETE FROM access_tokens WHERE expires_at < ?',
                    (datetime.now().timestamp(),)
                )
                conn.commit()
                return cursor.rowcount
        except Exception as e:
            logger.error(f"Error cleaning up sessions: {e}")
            return 0