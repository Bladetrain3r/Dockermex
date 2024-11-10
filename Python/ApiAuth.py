import json
import hashlib
from ApiUtils import log_access
import logging
from flask import Flask, request, jsonify


app = Flask(__name__)

# Load users from a JSON file
def load_users():
    users_file = os.path.join(app.config['SERVICE_CONFIG_FOLDER'], 'users.json')
    app.logger.debug(f"Looking for users file at: {users_file}")
    
    if os.path.exists(users_file):
        app.logger.debug(f"Users file found")
        with open(users_file, 'r') as f:
            data = json.load(f)
            jsonusers = data.get('users', [])
            print(jsonusers)
            app.logger.debug(f"Loaded {len(users)} users: {users}")
            return jsonusers
    else:
        app.logger.debug(f"Users file not found!")
    return []

users = load_users()

@self.app.route('/auth/login', methods=['POST'])
@log_access(debug=True)
def login():
    print("Login attempt received")
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    
    print(f"Looking for user: {username}")
    print(f"Available users: {self.users}")  # Debug
    
    # Hash the provided password for comparison
    password_hash = hashlib.sha256(password.encode()).hexdigest()
    
    # Find matching user
    user = next(
        (user for user in self.users  # Note: self.users is the array
         if user.get('username') == username and 
         user.get('password_hash') == password_hash),
        None
    )
    
    if user:
        print("User found and authenticated")
        safe_user = {k:v for k,v in user.items() if k != 'password_hash'}
        return jsonify({
            "message": "Login successful",
            "user": safe_user
        }), 200
    
    print("Authentication failed")
    return jsonify({
        "message": "Invalid username or password"
    }), 401

@app.route('/user/<username>', methods=['GET'])
def get_user(username):
    user = next((user for user in users if user['username'] == username), None)
    if user:
        return jsonify(user), 200
    else:
        return jsonify({"message": "User not found"}), 404

if __name__ == '__main__':
    app.run(debug=True)