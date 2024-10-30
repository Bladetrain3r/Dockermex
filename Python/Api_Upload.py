from flask import Flask, request, redirect, url_for
import os

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = '/pwads'
app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024  # 100 MB

@app.route('/submit-wad', methods=['POST'])
def upload_file():
    if 'wadfile' not in request.files:
        return 'No file part', 400
    file = request.files['wadfile']
    if file.filename == '':
        return 'No selected file', 400
    if not file.filename.lower().endswith('.wad'):
        return 'Only .wad files are allowed', 400
    filename = file.filename
    file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
    return 'File uploaded successfully', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
