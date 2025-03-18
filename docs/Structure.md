# Dockermex: Application Structure

This document gives a broad overview of components and their functionality in the Dockermex stack.
This includes both the main Dockermex module and the submodules.

## Top Level Components

Broadly speaking, it can be broken into these major components:

- The API, written in Python, which serves as the core for server logic.
- The Database classes, also written in Python, intended to use Sqlite for access control and metadata.
- The Frontend, written primarily as static HTML which calls to the API. The API is a microservice, the frontend... is not.
    - The Frontend also contains web hosting configuration, SSL and passes requests to the less secured API.
- Orchestration and deployment of services is primarily handled by Docker, and relies on containers.
- The management component consisting of scripts to handle launch or termination of servers on the Docker's parent host.

## The API

### Broad Overview

A Python based Flask API which allows an authorised user to upload WADS, as well as set up configuration for servers.

### List of Routes

The API provides the following list of routes across it's classes:
