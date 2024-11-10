# CoreApi.py
from flask import Flask, request, jsonify, session
from flask_cors import CORS
import json
import os
import hashlib
from functools import wraps
from ApiUtils import rate_limit, validate_file_type, log_access, require_json
from typing import Callable
import secrets

class CoreApi:
    def __init__(self):
        self.app = Flask(__name__)
        CORS(self.app, 
             supports_credentials=True,  # Important for cookies
             resources={
                 r"/*": {
                     "origins": ["http://odamex.zerofuchs.co.za:443", "https://odamex.zerofuchs.co.za:443"],  # Add your domains
                     "methods": ["GET", "POST", "OPTIONS"],
                     "allow_headers": ["Content-Type", "Authorization"],
                     "expose_headers": ["Content-Range", "X-Content-Range"],
                     "supports_credentials": True
                 }
             })
        
        # Basic configuration
        self.app.config['UPLOAD_FOLDER'] = '/pwads'
        self.app.config['IWAD_FOLDER'] = '/iwads/freeware'
        self.app.config['COMMERCIAL_IWAD_FOLDER'] = '/iwads/commercial'
        self.app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024
        self.app.config['SERVICE_CONFIG_FOLDER'] = '/service-configs'
        self.app.config['CONFIG_FOLDER'] = '/configs'
        
        # Session configuration
        self.app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', secrets.token_hex(32))
        self.app.config['SESSION_COOKIE_SECURE'] = True
        self.app.config['SESSION_COOKIE_HTTPONLY'] = True
        self.app.config['SESSION_COOKIE_SAMESITE'] = 'Strict'
        self.app.config['PERMANENT_SESSION_LIFETIME'] = 3600  # 1 hour

        # Load users on startup
        self.reload_users()
        
        # Register routes
        self._register_routes()

    def reload_users(self):
        """Load users from JSON file"""
        users_file = os.path.join(self.app.config['SERVICE_CONFIG_FOLDER'], "users.json")
        print(f"Attempting to load users from: {users_file}")
        
        if os.path.exists(users_file):
            try:
                with open(users_file, 'r') as f:
                    data = json.load(f)
                    print(f"Loaded data: {data}")  # Debug
                    if isinstance(data, dict) and 'users' in data:
                        self.users = data['users']  # Get the users array
                    else:
                        print("Invalid users file format")
                        self.users = []
            except Exception as e:
                print(f"Error loading users: {e}")
                self.users = []
        else:
            print(f"Users file not found at {users_file}")
            self.users = []

    def require_auth(self, f: Callable):
        """Authentication requirement decorator"""
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if not session.get('user_id'):
                return jsonify({'error': 'Authentication required'}), 401
            return f(*args, **kwargs)
        return decorated_function

    def _register_routes(self):
        """Register all API routes"""
        
        # Auth routes
        @self.app.route('/auth/login', methods=['POST'])
        @rate_limit(requests_per_window=5, window_seconds=60)
        @require_json()
        @log_access()
        def login():
            data = request.get_json()
            username = data.get('username')
            password = data.get('password')
            
            # Hash password for comparison
            password_hash = hashlib.sha256(password.encode()).hexdigest()
            
            user = next(
                (user for user in self.users 
                 if user['username'] == username and 
                 user['password_hash'] == password_hash),
                None
            )
            
            if user:
                session.permanent = True
                session['user_id'] = user['id']
                session['username'] = user['username']
                session['role'] = user['role']
                
                return jsonify({
                    "message": "Login successful",
                    "user": {
                        "username": user['username'],
                        "role": user['role']
                    }
                }), 200
            return jsonify({"error": "Invalid credentials"}), 401

        @self.app.route('/auth/logout', methods=['POST'])
        def logout():
            session.clear()
            return jsonify({"message": "Logout successful"}), 200

        @self.app.route('/auth/session', methods=['GET'])
        def check_session():
            if session.get('user_id'):
                return jsonify({
                    "authenticated": True,
                    "user": {
                        "username": session.get('username'),
                        "role": session.get('role')
                    }
                }), 200
            return jsonify({"authenticated": False}), 401

        # WAD management routes
        @self.app.route('/submit-wad', methods=['POST'])
        @self.require_auth
        @rate_limit(requests_per_window=10, window_seconds=60)
        @validate_file_type('.wad')
        @log_access()
        def upload_file():
            if 'file' not in request.files:
                return jsonify({'error': 'No file provided'}), 400

            file = request.files['file']
            filename = file.filename.strip()
            folder = (self.app.config['IWAD_FOLDER'] 
                     if 'iwad' in request.form and request.form['iwad'].lower() == 'true' 
                     else self.app.config['UPLOAD_FOLDER'])

            # File hash calculation and commercial IWAD checking
            file_content = file.read()
            calculated_hash = hashlib.sha256(file_content).hexdigest().lower()
            file.seek(0)

            if folder == self.app.config['UPLOAD_FOLDER']:
                commercial_check = self._check_commercial_wad(filename, calculated_hash)
                if commercial_check:
                    return commercial_check

            file.save(os.path.join(folder, filename))
            return jsonify({
                'message': 'File uploaded successfully',
                'filename': filename,
                'hash': calculated_hash
            }), 200

        # List routes
        @self.app.route('/list-configs', methods=['GET'])
        @self.require_auth
        @rate_limit(requests_per_window=30, window_seconds=60)
        @log_access()
        def list_configs():
            configs = [f for f in os.listdir(self.app.config['CONFIG_FOLDER']) 
                      if f.lower().endswith('.cfg')]
            return jsonify(configs)

        @self.app.route('/list-pwads', methods=['GET'])
        @self.require_auth
        @rate_limit(requests_per_window=30, window_seconds=60)
        @log_access()
        def list_pwads():
            wads = [f for f in os.listdir(self.app.config['UPLOAD_FOLDER']) 
                   if f.lower().endswith('.wad')]
            wads.insert(0, '')
            return jsonify(wads)

        @self.app.route('/list-iwads', methods=['GET'])
        @self.require_auth
        @rate_limit(requests_per_window=30, window_seconds=60)
        @log_access()
        def list_iwads():
            wads = [
                f for f in os.listdir(self.app.config['IWAD_FOLDER'])
                if f.lower().endswith('.wad') and not f.lower().startswith('odamex')
            ]
            commercial_wads = [
                f for f in os.listdir(self.app.config['COMMERCIAL_IWAD_FOLDER'])
                if f.lower().endswith('.wad') and not f.lower().startswith('odamex')
            ]
            return jsonify(wads + commercial_wads)
        
        @self.app.route('/generate-config', methods=['POST'])
        @self.require_auth
        @rate_limit(requests_per_window=20, window_seconds=60)
        @require_json()
        @log_access()
        def submit_config():
            config_data = request.json
            config_name = (
                f"{config_data.get('configFile').split('.')[0]}_"
                f"{config_data.get('iwadFile').split('.')[0]}_"
                f"{config_data.get('pwadFile').split('.')[0]}.json"
            )
            config_path = os.path.join(self.app.config['SERVICE_CONFIG_FOLDER'], config_name)
            with open(config_path, 'w', encoding='utf-8') as f:
                json.dump(config_data, f, ensure_ascii=False, indent=4)
        
            configs = [f for f in os.listdir(self.app.config['CONFIG_FOLDER']) if f.lower().endswith('.cfg')]
            pwads = [f for f in os.listdir(self.app.config['UPLOAD_FOLDER']) if f.lower().endswith('.wad')]
            iwads = [f for f in os.listdir(self.app.config['IWAD_FOLDER']) if f.lower().endswith('.wad')]
        
            return jsonify({
                'message': 'Configuration saved',
                'configs': configs,
                'pwads': pwads,
                'iwads': iwads
            }), 200

    def _check_commercial_wad(self, filename: str, file_hash: str):
        """Check if a WAD file matches any known commercial WADs"""
        commercial_iwads = {}
        for f in os.listdir(self.app.config['COMMERCIAL_IWAD_FOLDER']):
            if f.lower().endswith('.wad'):
                wad_path = os.path.join(self.app.config['COMMERCIAL_IWAD_FOLDER'], f)
                with open(wad_path, 'rb') as wad_file:
                    wad_hash = hashlib.sha256(wad_file.read()).hexdigest().lower()
                    commercial_iwads[os.path.splitext(f)[0].lower()] = {
                        'filename': f,
                        'hash': wad_hash
                    }

        upload_full = filename.lower()
        upload_name = os.path.splitext(filename)[0].lower()

        if file_hash in [comm_data['hash'] for comm_data in commercial_iwads.values()]:
            return jsonify({'error': 'File matches a commercial IWAD'}), 400

        for comm_name, comm_data in commercial_iwads.items():
            if upload_full == comm_data['filename'].lower() or upload_name == comm_name:
                return jsonify({'error': f'File matches commercial IWAD: {comm_name}'}), 400

        return None

    def run(self, host='0.0.0.0', port=5000, **kwargs):
        """Run the API server"""
        self.app.run(host=host, port=port, **kwargs)

if __name__ == '__main__':
    api = CoreApi()
    api.run(debug=True)