from flask import Flask, request, redirect, url_for, jsonify
from flask_cors import CORS
import json
import os
import hashlib
from ApiUtils import (
    rate_limit, 
    validate_file_type, 
    log_access,
    require_json
)

app = Flask(__name__)
CORS(app)
app.config['UPLOAD_FOLDER'] = '/pwads'
app.config['IWAD_FOLDER'] = '/iwads/freeware'
app.config['COMMERCIAL_IWAD_FOLDER'] = '/iwads/commercial'
app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024  # 100 MB
app.config['SERVICE_CONFIG_FOLDER'] = '/service-configs'
app.config['CONFIG_FOLDER'] = '/configs'

# Upload Ops

@app.route('/submit-wad', methods=['POST'])
@rate_limit(requests_per_window=10, window_seconds=60)
@validate_file_type('.wad')
@log_access()
def upload_file():
    """Upload a WAD file"""
    if 'file' not in request.files:
        return 'No file part', 400

    file = request.files['file']
    filename = file.filename.strip()  # Remove any whitespace
    folder = app.config['IWAD_FOLDER'] if 'iwad' in request.form and request.form['iwad'].lower() == 'true' else app.config['UPLOAD_FOLDER']

    # Calculate file hash once, as we might need it for comparison
    file_content = file.read()
    calculated_hash = hashlib.sha256(file_content).hexdigest().lower()
    file.seek(0)  # Reset file pointer after reading
    # Improved commercial IWAD checking
    if folder == app.config['UPLOAD_FOLDER']:
        # Get normalized list of commercial IWADs and their hashes
        commercial_iwads = {}
        for f in os.listdir(app.config['COMMERCIAL_IWAD_FOLDER']):
            if f.lower().endswith('.wad'):
                wad_path = os.path.join(app.config['COMMERCIAL_IWAD_FOLDER'], f)
                with open(wad_path, 'rb') as wad_file:
                    wad_hash = hashlib.sha256(wad_file.read()).hexdigest().lower()
                    commercial_iwads[os.path.splitext(f)[0].lower()] = {
                        'filename': f,
                        'hash': wad_hash
                    }

        # Check both full filename and name without extension
        upload_full = filename.lower()
        upload_name = os.path.splitext(filename)[0].lower()

        # Check if the file matches any commercial IWAD names
        matched_commercial = False
        if calculated_hash in [comm_data['hash'] for comm_data in commercial_iwads.values()]:
            matched_commercial = True
        for comm_name, comm_data in commercial_iwads.items():
            if upload_full == comm_data['filename'].lower() or upload_name == comm_name or matched_commercial is True:
                return f'File matches a commercial IWAD: {comm_name}', 400
    file.save(os.path.join(folder, filename))

    return jsonify({
        'message': 'File uploaded successfully',
        'filename': filename,
        'hash': calculated_hash
    }), 200

# List Ops

@app.route('/list-configs', methods=['GET'])
@rate_limit(requests_per_window=30, window_seconds=60)
@log_access()
def list_configs():
    configs = [f for f in os.listdir(app.config['CONFIG_FOLDER']) if f.lower().endswith('.cfg')]
    return jsonify(configs)

@app.route('/list-pwads', methods=['GET'])
@rate_limit(requests_per_window=30, window_seconds=60)
@log_access()
def list_pwads():
    wads = [f for f in os.listdir(app.config['UPLOAD_FOLDER']) if f.lower().endswith('.wad')]
    wads.insert(0, '')  # Add an empty field as the first choice
    return jsonify(wads)

@app.route('/list-iwads', methods=['GET'])
@rate_limit(requests_per_window=30, window_seconds=60)
@log_access()
def list_iwads():
    wads = [f for f in os.listdir(app.config['IWAD_FOLDER']) if f.lower().endswith('.wad')]
    commercial_wads = [f for f in os.listdir(app.config['COMMERCIAL_IWAD_FOLDER']) if f.lower().endswith('.wad')]
    wads.extend(commercial_wads)
    return jsonify(wads)

@app.route('/list-services', methods=['GET'])
@rate_limit(requests_per_window=30, window_seconds=60)
@log_access()
def list_services():
    services = [f for f in os.listdir(app.config['SERVICE_CONFIG_FOLDER']) if f.lower().endswith('.json')]
    return jsonify(services)

# Generate Ops

@app.route('/generate-config', methods=['POST'])
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
    config_path = os.path.join(app.config['SERVICE_CONFIG_FOLDER'], config_name)
    with open(config_path, 'w', encoding='utf-8') as f:
        json.dump(config_data, f, ensure_ascii=False, indent=4)

    configs = [f for f in os.listdir(app.config['CONFIG_FOLDER']) if f.lower().endswith('.cfg')]
    pwads = [f for f in os.listdir(app.config['UPLOAD_FOLDER']) if f.lower().endswith('.wad')]
    iwads = [f for f in os.listdir(app.config['IWAD_FOLDER']) if f.lower().endswith('.wad')]

    return jsonify({
        'message': 'Configuration saved',
        'configs': configs,
        'pwads': pwads,
        'iwads': iwads
    }), 200



if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
