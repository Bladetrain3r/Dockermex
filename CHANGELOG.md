# Changelog

All notable changes to Dockermex will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [V2-Alpha 0.1] (PENDING)

## Why V2?
V1 was a learning project that grew into a full web stack - authentication, sessions, database, the works. Great for learning, massive overkill for "hey let's spin up a DOOM server for tonight."

After building Magic Launcher and seeing its clean, direct approach work so well, it became clear that Dockermex's web layer was overengineered for the actual use case. V2 strips away complexity in favor of direct control.
### Key realizations:

**Why maintain a web app when all you need is to launch Docker containers?**

- Users don't need a web UI to launch game servers
- WAD filename nightmares solved by simple sanitization
- Docker orchestration is simpler without web abstraction
- Magic Launcher already provides the UI paradigm needed

### V2 philosophy:

Learning project → Practical tool
Web complexity → Direct control
Database configs → JSON files
Session management → Just launch the damn server

### The Magic Launcher Paradigm
The Magic Launcher paradigm is one which emphasises stripping a project down to the core problem it solves.
First solve that, then consider the impact on it's ability to solve that when making changes.
This sounds obvious but anyone who has worked on enterprise scale software stacks understands that, when filtered through multiple teams and motivations, the core problem becomes murky.
Dockermex has no such crises of identity to concern itself with, it is explicitly meant to solve one problem: Managing DOOM servers for a night of play.
Removing all the bloat, ironically, will open up many avenues when it comes to configuration files, source ports, and remote administration.

The project will continue under one core philosophy:
Speed is life, bloat is death. It must let you manage servers fast, and with minimum friction. That is it.

## V2 Roadmap (Rough)

### Phase 1: Demolition

Remove web application layer. No Nginx, no Flask, no HTML
Strip out authentication, sessions, database
Archive V1 for posterity

### Phase 2: Foundation

Refactor Odamex container services for script-based orchestration
Implement WAD sanitization on import (spaces→underscores, strip specials)
Create JSON-based server config templates

### Phase 3: Integration

Set up Magic Launcher container with basic SSH access to Odamex containers (aka the sidecar)
Implement script to create new and destroy Odamex service containers with compose
Add default configuration for local Magic Launcher (docker/docker compose presets and skeleton scripts)
Add default configuration for Sidecar Magic Launcher (SSH, system stats, logs)

### Phase 4: Testing and Polish
Create client container templates with X forwarding enabled for rapid testing on different sourceports/versions.
Switch to polish and crud removal, make it something you can SSH -XC into an EC2 instance and get going in maybe... 10 minutes, without compiles and assuming a few pwads need to be manually moved.

### Phase 5: V2.0 and Beyond
No specific expansion are planned beyond this point, bugfixing and keeping up to date with new third party releases are about the most of it.
Hold that thought: Expand to other id games that have a Linux source port that can do hosting. Quake, at least. 
Hexen/Heretic/Strife shouldn't even need to be explicitly accounted for they're just iwads you need the right source port to run.

### Phase 6: V2.0 and Beyond
No specific expansions are... wait. Okay, but seriously this time - past this point is maintenance only.

### These probably won't happen but I like the ideas
DOS servers with DOSBox... thank god they're TCP/IP but still. Dosbox itself no problem, the confs not really a problem, DOSBox networking layering with Docker? Probably a nightmare.

## Notes

This is a complete rewrite, not an upgrade.
V1 was fun to build but painful to maintain.
If you need high maintenance, full-stack session based web-based DOOM server management, V1 will be on the "legacy" branch.