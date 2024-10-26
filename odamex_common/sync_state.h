// New header: state_sync.h
#pragma once
#include "d_player.h"
#include "jsoncpp/json.h" // Already part of Odamex

// Success/failure return type
struct StateResult {
    bool success;
    std::string error;
};

// Main interface
StateResult SavePlayerState(const player_t& player, const char* endpoint);
StateResult LoadPlayerState(player_t& player, const char* endpoint, const char* playerid);