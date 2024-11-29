# api_utils.py
from functools import wraps
import time
from threading import Lock
import hashlib
from typing import Dict, List, Optional, Callable
import logging
from flask import request, jsonify

class RateLimiter:
    """Simple rate limiter class"""
    def __init__(self, requests: int, window: int):
        """
        Initialize rate limiter

        Args:
            requests (int): Number of requests allowed
            window (int): Time window in seconds
        """
        self.requests = requests
        self.window = window
        self.clients: Dict[str, List[float]] = {}
        self.lock = Lock()

    def _cleanup_old_requests(self, client: str) -> None:
        """Remove requests outside the current time window"""
        current = time.time()
        self.clients[client] = [
            req_time for req_time in self.clients[client]
            if current - req_time <= self.window
        ]

    def is_allowed(self, client: str) -> bool:
        """Check if request is allowed for client"""
        with self.lock:
            if client not in self.clients:
                self.clients[client] = []

            self._cleanup_old_requests(client)

            if len(self.clients[client]) >= self.requests:
                return False

            self.clients[client].append(time.time())
            return True

def rate_limit(requests_per_window: int, window_seconds: int = 60):
    """
    Rate limiting decorator

    Args:
        requests_per_window (int): Number of requests allowed in window
        window_seconds (int): Window size in seconds
    """
    limiter = RateLimiter(requests_per_window, window_seconds)

    def decorator(f: Callable):
        @wraps(f)
        def wrapped(*args, **kwargs):
            # Get client identifier (IP address or API key)
            client = request.headers.get('X-API-Key', request.remote_addr)

            if not limiter.is_allowed(client):
                return jsonify({
                    'error': 'Rate limit exceeded',
                    'retry_after': window_seconds
                }), 429

            return f(*args, **kwargs)
        return wrapped
    return decorator

def validate_file_type(*allowed_extensions: str):
    """
    Validate file type decorator

    Args:
        allowed_extensions: Tuple of allowed file extensions
    """
    def decorator(f: Callable):
        @wraps(f)
        def wrapped(*args, **kwargs):
            if 'file' not in request.files:
                return jsonify({'error': 'No file provided'}), 400

            file = request.files['file']
            if not file.filename:
                return jsonify({'error': 'No filename provided'}), 400

            if not any(file.filename.lower().endswith(ext.lower())
                      for ext in allowed_extensions):
                return jsonify({
                    'error': (
                        'File type not allowed. Allowed types: '
                        f'{", ".join(allowed_extensions)}'
                    )
                }), 400

            return f(*args, **kwargs)
        return wrapped
    return decorator

def log_access(logger: Optional[logging.Logger] = None, debug: bool = False):
    """
    Access logging decorator with optional debug mode

    Args:
        logger: Optional logger instance, creates new one if not provided
        debug: Enable debug logging for this endpoint
    """
    if logger is None:
        logger = logging.getLogger('api_access')
        logger.setLevel(logging.DEBUG if debug else logging.INFO)
        handler = logging.StreamHandler()
        handler.setFormatter(logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        ))
        if not logger.handlers:
            logger.addHandler(handler)

    def decorator(f: Callable):
        @wraps(f)
        def wrapped(*args, **kwargs):
            start_time = time.time()
            
            # Debug logging for auth endpoints
            if debug and 'auth' in request.path:
                logger.debug("Request data: %s", request.get_json())
                if hasattr(request, 'users'):
                    logger.debug("Available users: %s", request.users)
            
            result = f(*args, **kwargs)
            duration = time.time() - start_time

            # Standard access logging
            logger.info(
                'Access: %s %s - Client: %s - Duration: %.2fs - Status: %s',
                request.method, request.path, request.remote_addr, duration,
                result[1] if isinstance(result, tuple) else 200
            )
            
            # Debug logging for response
            if debug:
                logger.debug("Response: %s", result)

            return result
        return wrapped
    return decorator

def require_json():
    """Require JSON content type decorator"""
    def decorator(f: Callable):
        @wraps(f)
        def wrapped(*args, **kwargs):
            if not request.is_json:
                return jsonify({'error': 'Content-Type must be application/json'}), 400
            return f(*args, **kwargs)
        return wrapped
    return decorator