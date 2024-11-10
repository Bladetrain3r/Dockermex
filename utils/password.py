#!/usr/bin/env python3
# hash_password.py
import hashlib
import argparse
import getpass

def hash_password(password=None, show_password=False):
    """Generate SHA256 hash for password"""
    if password is None:
        password = getpass.getpass('Enter password: ')
    
    password_hash = hashlib.sha256(password.encode()).hexdigest()

    if show_password:
        print(f'Password: {password}')
    print(f'Hash: {password_hash}')
    return password_hash

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate SHA256 hash for password')
    parser.add_argument('-p', '--password', help='Password to hash \
                        (if not provided, will prompt securely)')
    parser.add_argument('-s', '--show', action='store_true', help='Show password in output')

    args = parser.parse_args()
    hash_password(args.password, args.show)
