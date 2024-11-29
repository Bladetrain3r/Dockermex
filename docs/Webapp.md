# WAD Manager Web Application

## Overview

The WAD Manager is a web application designed to manage WAD files for the Odamex game server. It allows users to upload WAD files, manage configurations, and set up game servers easily through a web interface.

## Features

- **User Authentication**: Secure login system with session management.
- **WAD File Upload**: Upload and manage `.wad` files directly through the web interface.
- **Configuration Management**: Create and manage server configurations for Odamex.
- **Admin Panel**: Administrative functionalities for managing users and sessions.
- **Security Measures**: Rate limiting, input validation, and secure cookie handling.

## Technologies Used

- **Frontend**: HTML, CSS, JavaScript
- **Backend**: Python (Flask)
- **Web Server**: Nginx
- **Database**: SQLite
- **Authentication**: Session-based authentication with hashed passwords
- **Rate Limiting**: Custom rate limiter implemented in 

ApiUtils.py



## Installation

### Prerequisites

- **Python 3.6+**
- **pipenv**: For managing Python dependencies
- **Nginx**: As the web server and reverse proxy
- **SQLite**: For the database

### Steps

1. **Clone the Repository**

   ```bash
   git clone https://github.com/yourusername/wad-manager.git
   cd wad-manager
   ```

2. **Set Up Python Environment**

   ```bash
   pipenv install
   pipenv shell
   ```

3. **Configure Environment Variables**

   Create a `.env` file in the root directory and set the following variables:

   ```bash
   SECRET_KEY=your_secret_key
   ```

4. **Initialize the Database**

   ```bash
   python manage_users.py add-user --username admin --password adminpassword --role admin
   ```

5. **Set Up Nginx**

   Replace the default Nginx configuration with the provided 

nginx.conf

 or add the server blocks to your existing configuration.

   ```bash
   sudo cp nginx.conf /etc/nginx/nginx.conf
   sudo nginx -t
   sudo systemctl restart nginx
   ```

6. **Set Up SSL Certificates**

   Place your SSL certificates in the specified directories in the Nginx configuration.

7. **Run the Application**

   ```bash
   python CoreApi.py
   ```

## Usage

### Accessing the Application

- Navigate to `https://yourdomain.com` to access the login page.
- Log in with your credentials to access the main dashboard.

### Uploading WAD Files

- Use the upload form on the main page to upload `.wad` files.
- Only files with the `.wad` extension are allowed.

### Managing Configurations

- Select existing configuration files or create new ones.
- Associate IWAD and PWAD files to set up game servers.

### Admin Panel

- Accessible only to users with admin privileges.
- Manage users and clean up expired sessions.

## Project Structure

- 

login.html

: Login page for user authentication.
- 

main.html

: Main dashboard after login.
- 

styles.css

: Styling for the web pages.
- 

nginx.conf

: Nginx configuration file.
- 

manage_users.py

: Command-line tool for user management.
- 

ApiDatabase.py

: Handles database interactions.
- 

ApiUtils.py

: Contains utility functions like rate limiting and decorators.
- 

CoreApi.py

: Core API endpoints and application setup.
- 

ApiAdmin.py

: Admin-specific API endpoints.

## Security Considerations

- **Input Validation**: All inputs are validated to prevent injection attacks.
- **Rate Limiting**: Implemented to prevent abuse of the API.
- **Session Management**: Secure cookies with HTTPOnly and Secure flags.
- **Password Hashing**: Passwords are stored as hashed values using SHA256.
- **HTTPS Enforcement**: Nginx is configured to redirect all traffic to HTTPS.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements.

## License

This project is licensed under the MIT License.