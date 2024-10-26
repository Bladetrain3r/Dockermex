#include "state_sync.h"
#include "curl/curl.h"

// Callback for CURL to write response data
static size_t WriteCallback(void* contents, size_t size, size_t nmemb, std::string* userp) {
    userp->append((char*)contents, size * nmemb);
    return size * nmemb;
}

// Serialize player state to JSON
static Json::Value SerializePlayerState(const player_t& player) {
    Json::Value root;
    
    // Basic stats
    root["health"] = player.health;
    root["armorpoints"] = player.armorpoints;
    root["armortype"] = player.armortype;
    
    // Weapons
    Json::Value weapons(Json::arrayValue);
    for (int i = 0; i < NUMWEAPONS; i++) {
        if (player.weaponowned[i])
            weapons.append(i);
    }
    root["weapons"] = weapons;
    root["readyweapon"] = player.readyweapon;
    
    // Ammo
    Json::Value ammo(Json::objectValue);
    for (int i = 0; i < NUMAMMO; i++) {
        ammo[std::to_string(i)] = player.ammo[i];
    }
    root["ammo"] = ammo;
    
    // Powers
    root["berserk"] = player.powers[pw_strength] > 0;
    root["invul"] = player.powers[pw_invulnerability] / TICRATE;
    root["backpack"] = player.backpack;
    
    return root;
}

// Deserialize JSON to player state
static void DeserializePlayerState(player_t& player, const Json::Value& root) {
    // Basic stats
    player.health = root["health"].asInt();
    player.armorpoints = root["armorpoints"].asInt();
    player.armortype = root["armortype"].asInt();
    
    // Weapons
    memset(player.weaponowned, 0, sizeof(player.weaponowned));
    const Json::Value& weapons = root["weapons"];
    for (const Json::Value& weapon : weapons) {
        player.weaponowned[weapon.asInt()] = true;
    }
    player.readyweapon = player.pendingweapon = 
        (weapontype_t)root["readyweapon"].asInt();
    
    // Ammo
    const Json::Value& ammo = root["ammo"];
    for (int i = 0; i < NUMAMMO; i++) {
        player.ammo[i] = ammo[std::to_string(i)].asInt();
    }
    
    // Powers
    if (root["berserk"].asBool())
        player.powers[pw_strength] = INV_BERSERK_TIME;
    if (root["invul"].asInt() > 0)
        player.powers[pw_invulnerability] = root["invul"].asInt() * TICRATE;
    player.backpack = root["backpack"].asBool();
    
    // Handle backpack ammo doubling
    if (player.backpack) {
        for (int i = 0; i < NUMAMMO; i++) {
            player.maxammo[i] *= 2;
        }
    }
}

StateResult SavePlayerState(const player_t& player, const char* endpoint) {
    CURL* curl = curl_easy_init();
    StateResult result = {false, ""};
    
    if (!curl) {
        result.error = "Failed to initialize CURL";
        return result;
    }
    
    // Serialize state
    Json::Value root = SerializePlayerState(player);
    Json::FastWriter writer;
    std::string json_str = writer.write(root);
    
    // Set up POST request
    struct curl_slist* headers = NULL;
    headers = curl_slist_append(headers, "Content-Type: application/json");
    
    curl_easy_setopt(curl, CURLOPT_URL, endpoint);
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, json_str.c_str());
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    
    // Perform request
    CURLcode res = curl_easy_perform(curl);
    
    if (res != CURLE_OK) {
        result.error = curl_easy_strerror(res);
    } else {
        result.success = true;
    }
    
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);
    return result;
}

StateResult LoadPlayerState(player_t& player, const char* endpoint, const char* playerid) {
    CURL* curl = curl_easy_init();
    StateResult result = {false, ""};
    
    if (!curl) {
        result.error = "Failed to initialize CURL";
        return result;
    }
    
    // Build URL with player ID
    std::string url = std::string(endpoint) + "/" + playerid;
    std::string response_data;
    
    // Set up GET request
    curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response_data);
    
    // Perform request
    CURLcode res = curl_easy_perform(curl);
    
    if (res != CURLE_OK) {
        result.error = curl_easy_strerror(res);
    } else {
        // Parse response
        Json::Value root;
        Json::Reader reader;
        
        if (reader.parse(response_data, root)) {
            DeserializePlayerState(player, root);
            result.success = true;
        } else {
            result.error = "Failed to parse JSON response";
        }
    }
    
    curl_easy_cleanup(curl);
    return result;
}