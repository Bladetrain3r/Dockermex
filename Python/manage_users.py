# manage_users.py
"""
manage_users.py

This script provides a command-line interface (CLI) for managing users in the 
application. It includes commands for adding new users, listing all users, 
and updating user information.

Commands:
    add_user: Add a new user with a username, password, and role.
    list_users: List all users in the database.
    update_user: Update user information such as username, password, role, 
    and active status.

Dependencies:
    - click
    - ApiDatabase (DatabaseManager)
    - sys
"""

import click
from ApiDatabase import DatabaseManager
import sys

@click.group()
def cli():
    """WAD Manager User Administration Tool"""
    pass

@cli.command()
@click.option('--username', prompt=True)
@click.option('--password', prompt=True, hide_input=True, confirmation_prompt=True)
@click.option('--role', default='user', type=click.Choice(['user', 'admin']))
def add_user(username, password, role):
    """Add a new user"""
    db = DatabaseManager()
    if db.add_user(username, password, role):
        click.echo(f"User {username} added successfully")
    else:
        click.echo("Failed to add user", err=True)

@cli.command()
def list_users():
    """List all users"""
    db = DatabaseManager()
    users = db.list_users()
    if users:
        for user in users:
            click.echo(
                f"ID: {user['id']}, "
                f"Username: {user['username']}, "
                f"Role: {user['role']}, "
                f"Active: {user['active']}, "
                f"Last Login: {user['last_login']}"
            )
    else:
        click.echo("No users found")

@cli.command()
@click.argument('user_id', type=int)
@click.option('--username', '-u')
@click.option('--password', '-p', is_flag=True)
@click.option('--role', '-r', type=click.Choice(['user', 'admin']))
@click.option('--active/--inactive', default=None)
def modify_user(user_id, username, password, role, active):
    """Modify a user"""
    db = DatabaseManager()
    updates = {}
    
    if username:
        updates['username'] = username
    if password:
        new_password = click.prompt('New password', hide_input=True, confirmation_prompt=True)
        updates['password'] = new_password
    if role:
        updates['role'] = role
    if active is not None:
        updates['active'] = active
    
    if not updates:
        click.echo("No modifications specified")
        return
    
    if db.modify_user(user_id, **updates):
        click.echo(f"User {user_id} modified successfully")
    else:
        click.echo("Failed to modify user", err=True)

@cli.command()
@click.argument('user_id', type=int)
def delete_user(user_id):
    """Delete a user"""
    if click.confirm(f'Are you sure you want to delete user {user_id}?'):
        db = DatabaseManager()
        if db.delete_user(user_id):
            click.echo(f"User {user_id} deleted successfully")
        else:
            click.echo("Failed to delete user", err=True)

@cli.command()
def cleanup():
    """Clean up expired sessions"""
    db = DatabaseManager()
    count = db.cleanup_sessions()
    click.echo(f"Cleaned up {count} expired sessions")

if __name__ == '__main__':
    cli()