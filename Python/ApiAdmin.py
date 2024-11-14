# ApiAdmin.py
from flask import Blueprint, request, jsonify, session
from ApiDatabase import DatabaseManager
from ApiUtils import rate_limit, log_access, require_json
from functools import wraps

admin_bp = Blueprint('admin', __name__, url_prefix='/admin')
db = DatabaseManager()

def require_admin(f):
    """Decorator to check for admin privileges"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not session.get('user_id'):
            return jsonify({'error': 'Authentication required'}), 401
        
        if session.get('role') != 'admin':
            return jsonify({'error': 'Admin privileges required'}), 403
            
        return f(*args, **kwargs)
    return decorated_function

@admin_bp.route('/users', methods=['GET'])
@require_admin
@rate_limit(requests_per_window=30, window_seconds=60)
@log_access()
def list_users():
    """List all users"""
    users = db.list_users()
    return jsonify({'users': users})

@admin_bp.route('/users', methods=['POST'])
@require_admin
@require_json()
@rate_limit(requests_per_window=10, window_seconds=60)
@log_access()
def create_user():
    """Create a new user"""
    data = request.get_json()
    required_fields = {'username', 'password', 'role'}
    
    if not all(field in data for field in required_fields):
        return jsonify({'error': 'Missing required fields'}), 400
        
    if data['role'] not in ['admin', 'user']:
        return jsonify({'error': 'Invalid role'}), 400
    
    if db.add_user(data['username'], data['password'], data['role']):
        return jsonify({'message': 'User created successfully'}), 201
    else:
        return jsonify({'error': 'Failed to create user'}), 400

@admin_bp.route('/users/<int:user_id>', methods=['PUT'])
@require_admin
@require_json()
@rate_limit(requests_per_window=10, window_seconds=60)
@log_access()
def update_user(user_id):
    """Update user details"""
    data = request.get_json()
    
    # Don't allow modifying own account through this endpoint
    if user_id == session.get('user_id'):
        return jsonify({'error': 'Cannot modify own account through this endpoint'}), 403
    
    if db.modify_user(user_id, **data):
        return jsonify({'message': 'User updated successfully'}), 200
    else:
        return jsonify({'error': 'Failed to update user'}), 400

@admin_bp.route('/users/<int:user_id>', methods=['DELETE'])
@require_admin
@rate_limit(requests_per_window=5, window_seconds=60)
@log_access()
def delete_user(user_id):
    """Delete a user"""
    # Prevent self-deletion
    if user_id == session.get('user_id'):
        return jsonify({'error': 'Cannot delete own account'}), 403
        
    if db.delete_user(user_id):
        return jsonify({'message': 'User deleted successfully'}), 200
    else:
        return jsonify({'error': 'Failed to delete user'}), 400

@admin_bp.route('/sessions/cleanup', methods=['POST'])
@require_admin
@rate_limit(requests_per_window=5, window_seconds=60)
@log_access()
def cleanup_sessions():
    """Clean up expired sessions"""
    count = db.cleanup_sessions()
    return jsonify({
        'message': 'Sessions cleaned up',
        'count': count
    }), 200