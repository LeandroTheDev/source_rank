#include <sourcemod>
#include <scp>

public Plugin myinfo =
{
    name        = "Source Rank",
    author      = "LeandroTheDev",
    description = "Player rank system",
    version     = "2.0",
    url         = "https://github.com/LeandroTheDev/source_rank"
};

float  gv_PlayersScores[MAXPLAYERS];
int    gv_PlayerSpecialInfectedKilled[MAXPLAYERS];
char   gv_PlayerRankNameCache[MAXPLAYERS][128];

// Configurations
float  gv_PlayerMaxScore                           = 10.0;
float  gv_PlayerScoreLoseOnRoundLose               = 5.0;
float  gv_PlayerScoreEarnOnMarker                  = 2.0;
float  gv_PlayerScoreEarnOnRoundWin                = 2.0;
float  gv_PlayerScoreEarnPerSurvivorHurt           = 0.02;
float  gv_PlayerScoreEarnPerSpecialKill            = 0.2;
float  gv_PlayerScoreEarnPerRevive                 = 0.5;
float  gv_PlayerScoreLosePerIncapacitated          = 0.5;
float  gv_PlayerScoreEarnPerIncapacitated          = 0.5;
float  gv_PlayerScoreStartSurvival                 = -3.0;
float  gv_PlayerScoreEarnSurvivalPerSecond         = 0.01;
float  gv_PlayerScoreInfectedStartSurvival         = 6.0;
float  gv_PlayerScoreInfectedLoseSurvivalPerSecond = 0.01;
float  gv_PlayerScoreObjectiveComplete             = 1.0;
float  gv_PlayerScoreWaveSurvived                  = 1.0;
float  gv_PlayerScorePerScore                      = 0.1;

int    gv_RankCount                                = 7;
char   gv_RankNamesPath[PLATFORM_MAX_PATH]         = "addons/sourcemod/configs/source_rank.cfg";
int    gv_RankThresholds[99];
char   gv_RankNames[99][128];
char   gv_Gamemode[64];

int    gv_TimeStampSurvived;
Handle gv_TimeStampSurvivedTimer = INVALID_HANDLE;
int    gv_LastPlayerScore[MAXPLAYERS];
int    gv_IsDeadPlayer[MAXPLAYERS];
int    gv_ObjectivesCompleted = 0;
bool   gv_ObjectiveInCooldown = false;
float  gv_ObjectiveCooldown   = 5.0;
int    gv_ServerWave          = 0;

bool   gv_ShouldDebug         = false;
bool   gv_ShouldDisplayMenu   = true;
bool   gv_ShouldDisplayRank   = true;

char   gv_DatabaseConfig[128] = "sourcerank";

#define MVP_COUNT 3

ConVar gc_PlayerMaxScore;
ConVar gc_PlayerScoreLoseOnRoundLose;
ConVar gc_PlayerScoreEarnOnMarker;
ConVar gc_PlayerScoreEarnOnRoundWin;
ConVar gc_PlayerScoreEarnPerSurvivorHurt;
ConVar gc_PlayerScoreEarnPerSpecialKill;
ConVar gc_PlayerScoreEarnPerRevive;
ConVar gc_PlayerScoreLosePerIncapacitated;
ConVar gc_PlayerScoreEarnPerIncapacitated;
ConVar gc_PlayerScoreStartSurvival;
ConVar gc_PlayerScoreEarnSurvivalPerSecond;
ConVar gc_PlayerScoreInfectedStartSurvival;
ConVar gc_PlayerScoreInfectedLoseSurvivalPerSecond;
ConVar gc_PlayerScoreObjectiveComplete;
ConVar gc_PlayerScoreWaveSurvived;
ConVar gc_PlayerScorePerScore;
ConVar gc_RankCount;
ConVar gc_RankNamesPath;
ConVar gc_ShouldDebug;
ConVar gc_ShouldDisplayMenu;
ConVar gc_DatabaseConfig;
ConVar gc_ShouldDisplayRank;

void   ReadVariables()
{
    gv_PlayerMaxScore = gc_PlayerMaxScore.FloatValue;
    PrintToServer("[SourceRank] Player max score: %f", gv_PlayerMaxScore);

    gv_PlayerScoreLoseOnRoundLose = gc_PlayerScoreLoseOnRoundLose.FloatValue;
    PrintToServer("[SourceRank] Player score lose on round lose: %f", gv_PlayerScoreLoseOnRoundLose);

    gv_PlayerScoreEarnOnMarker = gc_PlayerScoreEarnOnMarker.FloatValue;
    PrintToServer("[SourceRank] Player score earn on marker: %f", gv_PlayerScoreEarnOnMarker);

    gv_PlayerScoreEarnOnRoundWin = gc_PlayerScoreEarnOnRoundWin.FloatValue;
    PrintToServer("[SourceRank] Player score earn on round win: %f", gv_PlayerScoreEarnOnRoundWin);

    gv_PlayerScoreEarnPerSurvivorHurt = gc_PlayerScoreEarnPerSurvivorHurt.FloatValue;
    PrintToServer("[SourceRank] Player score earn per survivor hurt: %f", gv_PlayerScoreEarnPerSurvivorHurt);

    gv_PlayerScoreEarnPerSpecialKill = gc_PlayerScoreEarnPerSpecialKill.FloatValue;
    PrintToServer("[SourceRank] Player score earn per special kill: %f", gv_PlayerScoreEarnPerSpecialKill);

    gv_PlayerScoreEarnPerRevive = gc_PlayerScoreEarnPerRevive.FloatValue;
    PrintToServer("[SourceRank] Player score earn per revive: %f", gv_PlayerScoreEarnPerRevive);

    gv_PlayerScoreLosePerIncapacitated = gc_PlayerScoreLosePerIncapacitated.FloatValue;
    PrintToServer("[SourceRank] Player score lose per incapacitated: %f", gv_PlayerScoreLosePerIncapacitated);

    gv_PlayerScoreEarnPerIncapacitated = gc_PlayerScoreEarnPerIncapacitated.FloatValue;
    PrintToServer("[SourceRank] Player score earn per incapacitated: %f", gv_PlayerScoreEarnPerIncapacitated);

    gv_PlayerScoreStartSurvival = gc_PlayerScoreStartSurvival.FloatValue;
    PrintToServer("[SourceRank] Player score start survival: %f", gv_PlayerScoreStartSurvival);

    gv_PlayerScoreEarnSurvivalPerSecond = gc_PlayerScoreEarnSurvivalPerSecond.FloatValue;
    PrintToServer("[SourceRank] Player score earn survival per second: %f", gv_PlayerScoreEarnSurvivalPerSecond);

    gv_PlayerScoreInfectedStartSurvival = gc_PlayerScoreInfectedStartSurvival.FloatValue;
    PrintToServer("[SourceRank] Player score infected start survival: %f", gv_PlayerScoreInfectedStartSurvival);

    gv_PlayerScoreInfectedLoseSurvivalPerSecond = gc_PlayerScoreInfectedLoseSurvivalPerSecond.FloatValue;
    PrintToServer("[SourceRank] Player score infected lose survival per second: %f", gv_PlayerScoreInfectedLoseSurvivalPerSecond);

    gv_PlayerScoreObjectiveComplete = gc_PlayerScoreObjectiveComplete.FloatValue;
    PrintToServer("[SourceRank] Player score objective complete: %f", gv_PlayerScoreObjectiveComplete);

    gv_PlayerScoreWaveSurvived = gc_PlayerScoreWaveSurvived.FloatValue;
    PrintToServer("[SourceRank] Player score wave survived: %f", gv_PlayerScoreWaveSurvived);

    gv_PlayerScorePerScore = gc_PlayerScorePerScore.FloatValue;
    PrintToServer("[SourceRank] Player score per score: %f", gv_PlayerScorePerScore);

    gv_RankCount = gc_RankCount.IntValue;
    PrintToServer("[SourceRank] Rank count: %d", gv_RankCount);

    gc_RankNamesPath.GetString(gv_RankNamesPath, sizeof(gv_RankNamesPath));
    PrintToServer("[SourceRank] Rank names path: %s", gv_RankNamesPath);

    gv_ShouldDebug = gc_ShouldDebug.BoolValue;
    PrintToServer("[SourceRank] Should debug: %b", gv_ShouldDebug);

    gv_ShouldDisplayMenu = gc_ShouldDisplayMenu.BoolValue;
    PrintToServer("[SourceRank] Should display menu: %b", gv_ShouldDisplayMenu);

    gc_DatabaseConfig.GetString(gv_DatabaseConfig, sizeof(gv_DatabaseConfig));
    PrintToServer("[SourceRank] Database Config: %s", gv_DatabaseConfig);

    gv_ShouldDisplayRank = gc_ShouldDisplayRank.BoolValue;
    PrintToServer("[SourceRank] Should display rank login and disconnections: %b", gv_ShouldDisplayRank);
}

bool gvf_Hooked_PlayerTeam                   = false;
bool gvf_Hooked_PlayerIncapacitated          = false;
bool gvf_Hooked_PlayerRevive                 = false;
bool gvf_Hooked_PlayerHurt                   = false;
bool gvf_Hooked_PlayerDeath                  = false;
bool gvf_Hooked_VersusRoundStart             = false;
bool gvf_Hooked_RoundEndVersus               = false;
bool gvf_Hooked_VersusMarkerReached          = false;
bool gvf_Hooked_SurvivalRoundStart           = false;
bool gvf_Hooked_RoundEndSurvival             = false;
bool gvf_Hooked_MapTransition                = false;
bool gvf_Hooked_MissionLost                  = false;
bool gvf_Hooked_Survival_NewWave             = false;
bool gvf_Hooked_Survival_RoundBegin          = false;
bool gvf_Hooked_Survival_ExtractionBegin     = false;
bool gvf_Hooked_Survival_PracticeEnding      = false;
bool gvf_Hooked_Objective_ObjectiveBegin     = false;
bool gvf_Hooked_Objective_ObjectiveComplete  = false;
bool gvf_Hooked_Objective_PracticeEnding     = false;
bool gvf_Hooked_Objective_RoundStart         = false;
bool gvf_Hooked_Objective_ExtractionComplete = false;
void ReadConfigs()
{
    //#region Rank names
    if (!FileExists(gv_RankNamesPath))
    {
        Handle file = OpenFile(gv_RankNamesPath, "w");
        if (file != null)
        {
            WriteFileLine(file, "\"SourceRank\"");
            WriteFileLine(file, "{");
            WriteFileLine(file, "    \"rankCount\"       \"7\"");
            WriteFileLine(file, "    \"rankThresholds\"");
            WriteFileLine(file, "    {");
            WriteFileLine(file, "        \"0\"  \"0\"");
            WriteFileLine(file, "        \"1\"  \"100\"");
            WriteFileLine(file, "        \"2\"  \"200\"");
            WriteFileLine(file, "        \"3\"  \"300\"");
            WriteFileLine(file, "        \"4\"  \"400\"");
            WriteFileLine(file, "        \"5\"  \"500\"");
            WriteFileLine(file, "        \"6\"  \"600\"");
            WriteFileLine(file, "    }");
            WriteFileLine(file, "");

            WriteFileLine(file, "    \"rankNames\"");
            WriteFileLine(file, "    {");
            WriteFileLine(file, "        \"0\"  \"Bronze\"");
            WriteFileLine(file, "        \"1\"  \"Silver\"");
            WriteFileLine(file, "        \"2\"  \"Gold\"");
            WriteFileLine(file, "        \"3\"  \"Platinum\"");
            WriteFileLine(file, "        \"4\"  \"Diamond\"");
            WriteFileLine(file, "        \"5\"  \"Grand Master\"");
            WriteFileLine(file, "        \"6\"  \"Challenger\"");
            WriteFileLine(file, "    }");
            WriteFileLine(file, "}");
            CloseHandle(file);

            PrintToServer("[SourceRank] Configuration file created: %s", gv_RankNamesPath);
        }
        else
        {
            PrintToServer("[SourceRank] Cannot create default file.");
            return;
        }
    }

    KeyValues kv = new KeyValues("SourceRank");
    if (!kv.ImportFromFile(gv_RankNamesPath))
    {
        delete kv;
        PrintToServer("[SourceRank] Cannot load configuration file: %s", gv_RankNamesPath);
    }
    // Loading from file
    else {
        gv_RankCount = kv.GetNum("rankCount", 7);
        if (kv.JumpToKey("rankThresholds"))
        {
            for (int i = 0; i < gv_RankCount; i++)
            {
                char key[8];
                Format(key, sizeof(key), "%d", i);
                gv_RankThresholds[i] = kv.GetNum(key, 0);
            }
            kv.GoBack();
            PrintToServer("[SourceRank] rankThresholds Loaded!");
        }
        if (kv.JumpToKey("rankNames"))
        {
            for (int i = 0; i < gv_RankCount; i++)
            {
                char key[8];
                Format(key, sizeof(key), "%d", i);
                kv.GetString(key, gv_RankNames[i], 128);
            }
            kv.GoBack();
            PrintToServer("[SourceRank] rankNames Loaded!");
        }
    }
    //#endregion Rank names

    //#region Events
    char game[64];
    GetGameFolderName(game, sizeof(game));

    if (StrEqual("left4dead2", game))
    {
        // Reset seguro
        SafeUnhook("player_team", OnPlayerChangeTeam, EventHookMode_Post, gvf_Hooked_PlayerTeam);
        SafeUnhook("player_incapacitated", OnPlayerIncapacitated, EventHookMode_Post, gvf_Hooked_PlayerIncapacitated);
        SafeUnhook("revive_success", OnPlayerRevive, EventHookMode_Post, gvf_Hooked_PlayerRevive);
        SafeUnhook("player_hurt", OnPlayerHurt, EventHookMode_Post, gvf_Hooked_PlayerHurt);
        SafeUnhook("player_death", OnSpecialKill, EventHookMode_Post, gvf_Hooked_PlayerDeath);
        SafeUnhook("versus_round_start", RoundStartVersus, EventHookMode_Post, gvf_Hooked_VersusRoundStart);
        SafeUnhook("round_end", RoundEndVersus, EventHookMode_Post, gvf_Hooked_RoundEndVersus);
        SafeUnhook("versus_marker_reached", MarkerReached, EventHookMode_Post, gvf_Hooked_VersusMarkerReached);
        SafeUnhook("survival_round_start", RoundStartSurvivalVersus, EventHookMode_Post, gvf_Hooked_SurvivalRoundStart);
        SafeUnhook("round_end", RoundEndSurvivalVersus, EventHookMode_Post, gvf_Hooked_RoundEndSurvival);
        SafeUnhook("map_transition", RoundEndCoop, EventHookMode_Post, gvf_Hooked_MapTransition);
        SafeUnhook("mission_lost", RoundEndLoseCoop, EventHookMode_Post, gvf_Hooked_MissionLost);

        // Base hooks
        SafeHook("player_team", OnPlayerChangeTeam, EventHookMode_Post, gvf_Hooked_PlayerTeam);
        SafeHook("player_incapacitated", OnPlayerIncapacitated, EventHookMode_Post, gvf_Hooked_PlayerIncapacitated);
        SafeHook("revive_success", OnPlayerRevive, EventHookMode_Post, gvf_Hooked_PlayerRevive);

        GetConVarString(FindConVar("mp_gamemode"), gv_Gamemode, sizeof(gv_Gamemode));
        PrintToServer("[SourceRank] Loaded gamemode: %s", gv_Gamemode);

        if (StrEqual(gv_Gamemode, "versus"))
        {
            SafeHook("player_hurt", OnPlayerHurt, EventHookMode_Post, gvf_Hooked_PlayerHurt);
            SafeHook("player_death", OnSpecialKill, EventHookMode_Post, gvf_Hooked_PlayerDeath);
            SafeHook("versus_round_start", RoundStartVersus, EventHookMode_Post, gvf_Hooked_VersusRoundStart);
            SafeHook("round_end", RoundEndVersus, EventHookMode_Post, gvf_Hooked_RoundEndVersus);
            SafeHook("versus_marker_reached", MarkerReached, EventHookMode_Post, gvf_Hooked_VersusMarkerReached);
        }
        else if (StrEqual(gv_Gamemode, "mutation15"))
        {
            SafeHook("player_hurt", OnPlayerHurt, EventHookMode_Post, gvf_Hooked_PlayerHurt);
            SafeHook("player_death", OnSpecialKill, EventHookMode_Post, gvf_Hooked_PlayerDeath);
            SafeHook("survival_round_start", RoundStartSurvivalVersus, EventHookMode_Post, gvf_Hooked_SurvivalRoundStart);
            SafeHook("round_end", RoundEndSurvivalVersus, EventHookMode_Post, gvf_Hooked_RoundEndSurvival);
        }
        else if (StrEqual(gv_Gamemode, "survival"))
        {
            SafeHook("player_death", OnSpecialKill, EventHookMode_Post, gvf_Hooked_PlayerDeath);
            SafeHook("survival_round_start", RoundStartSurvivalVersus, EventHookMode_Post, gvf_Hooked_SurvivalRoundStart);
            SafeHook("round_end", RoundEndSurvivalVersus, EventHookMode_Post, gvf_Hooked_RoundEndSurvival);
        }
        else if (StrEqual(gv_Gamemode, "coop"))
        {
            SafeHook("map_transition", RoundEndCoop, EventHookMode_Post, gvf_Hooked_MapTransition);
            SafeHook("mission_lost", RoundEndLoseCoop, EventHookMode_Post, gvf_Hooked_MissionLost);
        }
        else
        {
            PrintToServer("[SourceRank] Unsupported gamemode: %s", gv_Gamemode);
        }
    }
    else if (StrEqual("nmrih", game)) {
        char mapName[128];
        GetCurrentMap(mapName, sizeof(mapName));

        SafeUnhook("new_wave", OnSurvivalWaveStart, EventHookMode_Post, gvf_Hooked_Survival_NewWave);
        SafeUnhook("nmrih_round_begin", OnSurvivalStart, EventHookMode_Post, gvf_Hooked_Survival_RoundBegin);
        SafeUnhook("extraction_begin", OnSurvivalExtractionBegin, EventHookMode_Post, gvf_Hooked_Survival_ExtractionBegin);
        SafeUnhook("nmrih_practice_ending", OnSurvivalPracticeEnded, EventHookMode_Post, gvf_Hooked_Survival_PracticeEnding);
        SafeUnhook("objective_begin", OnObjectiveStart, EventHookMode_Post, gvf_Hooked_Objective_ObjectiveBegin);
        SafeUnhook("objective_complete", OnObjectiveComplete, EventHookMode_Post, gvf_Hooked_Objective_ObjectiveComplete);
        SafeUnhook("nmrih_practice_ending", OnObjectivePracticeEnded, EventHookMode_Post, gvf_Hooked_Objective_PracticeEnding);
        SafeUnhook("round_start", OnObjectiveRoundStart, EventHookMode_Post, gvf_Hooked_Objective_RoundStart);
        SafeUnhook("extraction_complete", OnObjectiveExtractionComplete, EventHookMode_Post, gvf_Hooked_Objective_ExtractionComplete);

        if (StrContains(mapName, "nms_") == 0)
        {
            SafeHook("new_wave", OnSurvivalWaveStart, EventHookMode_Post, gvf_Hooked_Survival_NewWave);
            SafeHook("nmrih_round_begin", OnSurvivalStart, EventHookMode_Post, gvf_Hooked_Survival_RoundBegin);
            SafeHook("extraction_begin", OnSurvivalExtractionBegin, EventHookMode_Post, gvf_Hooked_Survival_ExtractionBegin);
            SafeHook("nmrih_practice_ending", OnSurvivalPracticeEnded, EventHookMode_Post, gvf_Hooked_Survival_PracticeEnding);
        }
        else if (StrContains(mapName, "nmo_") == 0)
        {
            SafeHook("objective_begin", OnObjectiveStart, EventHookMode_Post, gvf_Hooked_Objective_ObjectiveBegin);
            SafeHook("objective_complete", OnObjectiveComplete, EventHookMode_Post, gvf_Hooked_Objective_ObjectiveComplete);
            SafeHook("nmrih_practice_ending", OnObjectivePracticeEnded, EventHookMode_Post, gvf_Hooked_Objective_PracticeEnding);
            SafeHook("round_start", OnObjectiveRoundStart, EventHookMode_Post, gvf_Hooked_Objective_RoundStart);
            SafeHook("extraction_complete", OnObjectiveExtractionComplete, EventHookMode_Post, gvf_Hooked_Objective_ExtractionComplete);
        }
        else {
            PrintToServer("Unsupported map prefix: %s", mapName)
        }
    }
    //#endregion Events
}

void SafeHook(const char[] event, EventHook callback, EventHookMode mode, bool& state)
{
    if (!state)
    {
        HookEventEx(event, callback, mode);
        state = true;
    }
}

void SafeUnhook(const char[] event, EventHook callback, EventHookMode mode, bool& state)
{
    if (state)
    {
        UnhookEvent(event, callback, mode);
        state = false;
    }
}

public void OnPluginStart()
{
    gc_ShouldDebug = CreateConVar(
        "rankShouldDebug",
        "0",
        "Enable debug logging",
        FCVAR_NONE,
        true,
        0.0,
        true,
        1.0);

    gc_ShouldDisplayMenu = CreateConVar(
        "rankDisableAutoMenu",
        "1",
        "If 0, disables the rank menu on player join",
        FCVAR_NONE,
        true,
        0.0,
        true,
        1.0);

    gc_PlayerMaxScore = CreateConVar(
        "rankPlayerMaxScore",
        "10.0",
        "Maximum score a player can earn per round",
        FCVAR_NONE,
        true,
        0.0,
        false,
        0.0);

    gc_PlayerScoreLoseOnRoundLose = CreateConVar(
        "rankPlayerScoreLoseOnRoundLose",
        "5.0",
        "Score lost on round lose",
        FCVAR_NONE,
        true,
        0.0,
        false,
        0.0);

    gc_PlayerScoreEarnOnMarker = CreateConVar(
        "rankPlayerScoreEarnOnMarker",
        "2.0",
        "Score earned on marker reached",
        FCVAR_NONE,
        true,
        0.0,
        false,
        0.0);

    gc_PlayerScoreEarnOnRoundWin = CreateConVar(
        "rankPlayerScoreEarnOnRoundWin",
        "2.0",
        "Score earned on round win",
        FCVAR_NONE,
        true,
        0.0,
        false,
        0.0);

    gc_PlayerScoreEarnPerSurvivorHurt = CreateConVar(
        "rankPlayerScoreEarnPerSurvivorHurt",
        "0.02",
        "Score earned per damage dealt to a survivor",
        FCVAR_NONE,
        true,
        0.0,
        false,
        0.0);

    gc_PlayerScoreEarnPerSpecialKill = CreateConVar(
        "rankPlayerScoreEarnPerSpecialKill",
        "0.2",
        "Score earned per special infected killed",
        FCVAR_NONE,
        true,
        0.0,
        false,
        0.0);

    gc_PlayerScoreEarnPerRevive = CreateConVar(
        "rankPlayerScoreEarnPerRevive",
        "0.5",
        "Score earned per revive",
        FCVAR_NONE,
        true,
        0.0,
        false,
        0.0);

    gc_PlayerScoreLosePerIncapacitated = CreateConVar(
        "rankPlayerScoreLosePerIncapacitated",
        "0.5",
        "Score lost when incapacitated",
        FCVAR_NONE,
        true,
        0.0,
        false,
        0.0);

    gc_PlayerScoreEarnPerIncapacitated = CreateConVar(
        "rankPlayerScoreEarnPerIncapacitated",
        "0.5",
        "Score earned for incapacitating a survivor",
        FCVAR_NONE,
        true,
        0.0,
        false,
        0.0);

    gc_PlayerScoreStartSurvival = CreateConVar(
        "rankPlayerScoreStartSurvival",
        "-3.0",
        "Base score for survivors at round end in survival",
        FCVAR_NONE,
        false,
        0.0,
        false,
        0.0);

    gc_PlayerScoreEarnSurvivalPerSecond = CreateConVar(
        "rankPlayerScoreEarnSurvivalPerSecond",
        "0.01",
        "Score earned per second survived",
        FCVAR_NONE,
        true,
        0.0,
        false,
        0.0);

    gc_PlayerScoreInfectedStartSurvival = CreateConVar(
        "rankPlayerScoreInfectedStartSurvival",
        "6.0",
        "Base score for infected at round end in survival",
        FCVAR_NONE,
        true,
        0.0,
        false,
        0.0);

    gc_PlayerScoreInfectedLoseSurvivalPerSecond = CreateConVar(
        "rankPlayerScoreInfectedLoseSurvivalPerSecond",
        "0.01",
        "Score lost per second for infected in survival",
        FCVAR_NONE,
        true,
        0.0,
        false,
        0.0);

    gc_PlayerScoreObjectiveComplete = CreateConVar(
        "rankPlayerScoreObjectiveComplete",
        "1",
        "Score earned per objective complete",
        FCVAR_NONE,
        true,
        0.0,
        false,
        0.0);

    gc_PlayerScoreWaveSurvived = CreateConVar(
        "rankPlayerScoreWaveSurvived",
        "1",
        "Score earned per wave survived",
        FCVAR_NONE,
        true,
        0.0,
        false,
        0.0);

    gc_PlayerScoreWaveSurvived = CreateConVar(
        "rankPlayerScorePerScore",
        "0.1",
        "Ingame score converted to mmr",
        FCVAR_NONE,
        true,
        0.0,
        false,
        0.0);

    gc_RankCount = CreateConVar(
        "rankCount",
        "7",
        "Number of ranks",
        FCVAR_NONE,
        true,
        1.0,
        true,
        99.0);

    gc_RankNamesPath = CreateConVar(
        "rankNamesPath",
        "addons/sourcemod/configs/source_rank.cfg",
        "Rank names file path",
        FCVAR_NONE,
        false,
        0.0,
        false,
        0.0);

    gc_DatabaseConfig = CreateConVar(
        "rankDatabaseConfig",
        "sourcerank",
        "Database config name",
        FCVAR_NONE,
        false,
        0.0,
        false,
        0.0);

    gc_ShouldDisplayRank = CreateConVar(
        "rankShouldDisplayRank",
        "1",
        "Should display the rank in login and chats",
        FCVAR_NONE,
        true,
        0.0,
        true,
        1.0);

    ReadVariables();
    ReadConfigs();

    RegConsoleCmd("rankreload", CommandReload, "Reload Rank");
    RegConsoleCmd("rank", CommandViewRank, "View your rank");

    PrintToServer("[SourceRank] Initialized");
}

//
// #region Events
//
public Action CP_OnChatMessage(int& author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool& processcolors, bool& removecolors)
{
    if (!IsClientInGame(author))
        return Plugin_Continue;
    if (!gv_ShouldDisplayRank)
        return Plugin_Continue;

    char colorPrefix[4];
    if (name[0] == '\x03' || name[0] == '\x01' || name[0] == '\x04')
    {
        colorPrefix[0] = name[0];
        colorPrefix[1] = '\0';
    }
    else
    {
        colorPrefix[0] = '\x03';
        colorPrefix[1] = '\0';
    }

    char teamTag[16];
    if (StrContains(flagstring, "Infected", false) != -1)
        strcopy(teamTag, sizeof(teamTag), "(Infected)");
    else if (StrContains(flagstring, "Survivor", false) != -1)
        strcopy(teamTag, sizeof(teamTag), "(Survivor)");
    else
        teamTag[0] = '\0';

    if (teamTag[0] != '\0')
        Format(name, MAXLENGTH_NAME, "[%s] %s%s \x01%s", gv_PlayerRankNameCache[author], colorPrefix, name, teamTag);
    else
        Format(name, MAXLENGTH_NAME, "[%s] %s%s", gv_PlayerRankNameCache[author], colorPrefix, name);

    return Plugin_Changed;
}

public void OnClientPutInServer(int client)
{
    if (!IsValidClient(client))
    {
        return;
    }

    int steamid = GetSteamAccountID(client);
    if (steamid == 0)
    {
        PrintToServer("[SourceRank] Invalid client when joining server");
        return;
    }

    Database database = CreateDatabaseConnection();
    if (database == null) return;

    char game[64];
    GetGameFolderName(game, sizeof(game));

    char query[256];
    Format(query, sizeof(query), "SELECT rank FROM `%s` WHERE uniqueid = %d", game, steamid);

    if (gv_ShouldDebug)
        PrintToServer("[SourceRank] Query: %s", query);

    SQL_TQuery(database, DisplayRankLogin_Callback, query, client, DBPrio_High);
}

void DisplayRankLogin_Callback(
    Database    db,
    DBResultSet results,
    const char[] error,
    any data)
{
    int client = data;

    if (error[0])
    {
        PrintToServer("[SourceRank] DisplayRankLogin_Callback SQL Error: %s", error);
        return;
    }

    if (!IsValidClient(client)) return;

    if (results != null && SQL_HasResultSet(results))
    {
        while (SQL_FetchRow(results))
        {
            char name[64];
            GetClientName(client, name, sizeof(name));

            char rank[128];
            SQL_FetchString(results, 0, rank, sizeof(rank));

            char rankName[128];
            GetRankNameFromRank(StringToInt(rank), rankName, sizeof(rankName));

            gv_PlayerRankNameCache[client] = rankName;
        }
    }
}

public void RoundStartVersus(Event event, const char[] name, bool dontBroadcast)
{
    PrintToServer("[SourceRank] Round start");

    int onlinePlayers[MAXPLAYERS];
    GetOnlinePlayers(onlinePlayers, sizeof(onlinePlayers));

    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;

        if (!IsValidClient(client)) continue;

        RegisterPlayer(client);
    }

    ClearPlayerScores();
}

public void RoundStartSurvivalVersus(Event event, const char[] name, bool dontBroadcast)
{
    PrintToServer("[SourceRank] Round start");

    int onlinePlayers[MAXPLAYERS];
    GetOnlinePlayers(onlinePlayers, sizeof(onlinePlayers));

    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;

        if (!IsValidClient(client)) continue;

        RegisterPlayer(client);
    }

    ClearPlayerScores();

    gv_TimeStampSurvived      = 0;
    gv_TimeStampSurvivedTimer = CreateTimer(1.0, OnTimestampPassed, 0, TIMER_REPEAT);
}

public Action OnTimestampPassed(Handle timer, any data)
{
    gv_TimeStampSurvived++;
    return Plugin_Handled;
}

public void MarkerReached(Event event, const char[] name, bool dontBroadcast)
{
    PrintToServer("[SourceRank] Marker Reached");

    int onlinePlayers[MAXPLAYERS];
    GetOnlinePlayers(onlinePlayers, sizeof(onlinePlayers));

    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;

        if (!IsValidClient(client)) continue;
        if (GetClientTeam(client) != 2 || !IsPlayerAlive(client)) continue;

        gv_PlayersScores[client] += gv_PlayerScoreEarnOnMarker;

        if (gv_ShouldDebug)
            PrintToServer("[SourceRank] [MarkerReached] %d Earned: %f for marker reach", client, gv_PlayerScoreEarnOnMarker);
    }
}

public void RoundEndVersus(Event event, const char[] name, bool dontBroadcast)
{
    int winner = event.GetInt("winner");
    int reason = event.GetInt("reason");

    // Restart from hibernation
    if (reason == 8) return;

    // Scenario Restart
    if (reason == 0) return;

    // Chapter ended
    if (reason == 6) return;

    int onlinePlayers[MAXPLAYERS];
    GetOnlinePlayers(onlinePlayers, sizeof(onlinePlayers));

    winner = 3;
    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;

        // 2 Survival - 3 Zombie
        int team = GetClientTeam(client);

        if (team == 2)
        {
            // Check if a player survivor is alive
            if (!(GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0) && IsPlayerAlive(client))
            {
                // Yes it is, so we can say that the winner team is survivor
                winner = 2;
                break;
            }
        }
    }

    int survivorsMVP[MVP_COUNT];
    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;

        if (!IsValidClient(client)) continue;

        int team = GetClientTeam(client);

        if (team == 2)
        {
            int kills = gv_PlayerSpecialInfectedKilled[client];
            if (kills > gv_PlayerSpecialInfectedKilled[survivorsMVP[0]])
            {
                survivorsMVP[2] = survivorsMVP[1];
                survivorsMVP[1] = survivorsMVP[0];
                survivorsMVP[0] = client;
            }
            else if (kills > gv_PlayerSpecialInfectedKilled[survivorsMVP[1]]) {
                survivorsMVP[2] = survivorsMVP[1];
                survivorsMVP[1] = client;
            }
            else if (kills > gv_PlayerSpecialInfectedKilled[survivorsMVP[2]]) {
                survivorsMVP[2] = client;
            }
        }

        if (team == winner)
        {
            gv_PlayersScores[client] += gv_PlayerScoreEarnOnRoundWin;

            if (gv_ShouldDebug)
                PrintToServer("[SourceRank] [RoundEndVersus] %d Earned: %f for winning", client, gv_PlayerScoreEarnOnRoundWin);
        }
        else {
            gv_PlayersScores[client] -= gv_PlayerScoreLoseOnRoundLose;
            if (gv_ShouldDebug)
                PrintToServer("[SourceRank] [RoundEndVersus] %d Losed: %f for losing", client, gv_PlayerScoreLoseOnRoundLose);
        }
        PrintToServer("[SourceRank] Player: %d, team: %d, score: %f", client, team, gv_PlayersScores[client]);

        CheckMaxScore(client);

        UploadMMR(client, gv_PlayersScores[client]);
    }

    PrintToChatAll("[SourceRank] Survivors Special Infected MVP:");
    for (int i = 0; i < MVP_COUNT; i++)
    {
        int client = survivorsMVP[i];
        if (IsValidClient(client))
        {
            char clientUsername[128];
            GetClientName(client, clientUsername, sizeof(clientUsername));

            PrintToChatAll("[%d] %s: %d", i + 1, clientUsername, gv_PlayerSpecialInfectedKilled[client]);
        }
    }

    ClearPlayerScores();
}

public void RoundEndSurvivalVersus(Event event, const char[] name, bool dontBroadcast)
{
    if (gv_TimeStampSurvivedTimer != INVALID_HANDLE)
        CloseHandle(gv_TimeStampSurvivedTimer);
    gv_TimeStampSurvivedTimer = INVALID_HANDLE;

    int reason                = event.GetInt("reason");

    // Restart from hibernation
    if (reason == 8) return;

    // Scenario Restart
    if (reason == 0) return;

    // Chapter ended
    if (reason == 6) return;

    if (gv_ShouldDebug)
        PrintToServer("[SourceRank] Round ended reason: %d", reason);

    int onlinePlayers[MAXPLAYERS];
    GetOnlinePlayers(onlinePlayers, sizeof(onlinePlayers));

    int survivorsMVP[3];
    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;

        if (!IsValidClient(client)) continue;

        int team = GetClientTeam(client);

        if (team == 2)
        {
            gv_PlayersScores[client] += GetRankEarnByTimeStampSurvival();

            int kills = gv_PlayerSpecialInfectedKilled[client];
            if (kills > gv_PlayerSpecialInfectedKilled[survivorsMVP[0]])
            {
                survivorsMVP[2] = survivorsMVP[1];
                survivorsMVP[1] = survivorsMVP[0];
                survivorsMVP[0] = client;
            }
            else if (kills > gv_PlayerSpecialInfectedKilled[survivorsMVP[1]]) {
                survivorsMVP[2] = survivorsMVP[1];
                survivorsMVP[1] = client;
            }
            else if (kills > gv_PlayerSpecialInfectedKilled[survivorsMVP[2]]) {
                survivorsMVP[2] = client;
            }

            if (gv_ShouldDebug)
                PrintToServer("[SourceRank] [RoundEndSurvivalVersus] %d SUpdated rank: %f", client, GetRankEarnByTimeStampSurvival());
        }
        else if (team == 3) {
            gv_PlayersScores[client] += GetRankEarnByTimeStampInfected();

            if (gv_ShouldDebug)
                PrintToServer("[SourceRank] [RoundEndSurvivalVersus] %d IUpdated rank: %f", client, GetRankEarnByTimeStampInfected());
        }
        PrintToServer("[SourceRank] Player: %d, team: %d, score: %d", client, team, gv_PlayersScores[client]);

        CheckMaxScore(client);

        UploadMMR(client, gv_PlayersScores[client]);
    }

    PrintToChatAll("[SourceRank] Survivors Special Infected MVP:");
    for (int i = 0; i < MVP_COUNT; i++)
    {
        int client = survivorsMVP[i];
        if (IsValidClient(client))
        {
            char clientUsername[128];
            GetClientName(client, clientUsername, sizeof(clientUsername));

            PrintToChatAll("[%d] %s: %d", i + 1, clientUsername, gv_PlayerSpecialInfectedKilled[client]);
        }
    }

    ClearPlayerScores();
}

public void RoundEndCoop(Event event, const char[] name, bool dontBroadcast)
{
    int reason = event.GetInt("reason");

    // Restart from hibernation
    if (reason == 8) return;

    // Chapter ended
    if (reason == 6) return;

    int onlinePlayers[MAXPLAYERS];
    GetOnlinePlayers(onlinePlayers, sizeof(onlinePlayers));

    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;

        if (!IsValidClient(client)) continue;

        gv_PlayersScores[client] += gv_PlayerScoreEarnOnRoundWin;

        if (gv_ShouldDebug)
            PrintToServer("[SourceRank] [RoundEndCoop] %d Earned: %f for winning", client, gv_PlayerScoreEarnOnRoundWin);
        PrintToServer("[SourceRank] Player: %d, score: %f", client, gv_PlayersScores[client]);

        CheckMaxScore(client);

        UploadMMR(client, gv_PlayersScores[client]);
    }

    ClearPlayerScores();
}

public void RoundEndLoseCoop(Event event, const char[] name, bool dontBroadcast)
{
    int reason = event.GetInt("reason");

    // Restart from hibernation
    if (reason == 8) return;

    // Chapter ended
    if (reason == 6) return;

    int onlinePlayers[MAXPLAYERS];
    GetOnlinePlayers(onlinePlayers, sizeof(onlinePlayers));

    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;

        if (!IsValidClient(client)) continue;

        gv_PlayersScores[client] -= gv_PlayerScoreLoseOnRoundLose;
        if (gv_ShouldDebug)
            PrintToServer("[SourceRank] [RoundEndCoop] %d Losed: %f for losing", client, gv_PlayerScoreLoseOnRoundLose);
        PrintToServer("[SourceRank] Player: %d, score: %f", client, gv_PlayersScores[client]);

        CheckMaxScore(client);

        UploadMMR(client, gv_PlayersScores[client]);
    }

    ClearPlayerScores();
}

public void OnPlayerChangeTeam(Event event, const char[] name, bool dontBroadcast)
{
    bool disconnected = event.GetBool("disconnect");
    if (disconnected) return;

    int userid  = event.GetInt("userid");
    int team    = event.GetInt("team");
    int oldTeam = event.GetInt("oldteam");

    int client  = GetClientOfUserId(userid);
    if (!IsValidClient(client))
    {
        if (gv_ShouldDebug)
            PrintToServer("[SourceRank] Fake client %d, ignoring team change, %d", userid, gv_ShouldDebug);
        return;
    }

    if (gv_ShouldDebug)
        PrintToServer("[SourceRank] %d changed their team: %d, previously: %d", client, team, oldTeam);

    if (oldTeam == 0)
    {
        ClearSinglePlayerScore(client);

        PrintToServer("[SourceRank] Player started playing %d", client);

        RegisterPlayer(client);

        if (gv_ShouldDisplayMenu)
            ShowRankMenu(client);
    }
}

public void OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    // Infected to Survivor
    {
        int survivorClient = GetClientOfUserId(event.GetInt("userid"));
        int infectedClient = GetClientOfUserId(event.GetInt("attacker"));

        // Valid client detection
        if (!IsValidClient(infectedClient))
        {
            if (gv_ShouldDebug)
                PrintToServer("[SourceRank] [OnPlayerHurt] Ignored: Attacker client not valid");
            return;
        }

        // Check if attacker is from infected team
        if (GetClientTeam(infectedClient) != 3)
        {
            if (gv_ShouldDebug)
                PrintToServer("[SourceRank] [OnPlayerHurt] Ignored: Attacker client is not on infected team");
            return;
        }

        // Check if client beenn attacked is a survivor
        if (GetClientTeam(survivorClient) != 2)
        {
            if (gv_ShouldDebug)
                PrintToServer("[SourceRank] [OnPlayerHurt] Ignored: Infected client is attacking a non survivor");
            return;
        }

        int   totalDamage = event.GetInt("dmgc_health");
        float earnedMMR   = gv_PlayerScoreEarnPerSurvivorHurt * totalDamage;

        gv_PlayersScores[infectedClient] += earnedMMR;

        if (gv_ShouldDebug)
            PrintToServer("[SourceRank] [OnPlayerHurt] %d infected deal: %d damage to %d survivor, earned mmr: %f, total mmr: %f", infectedClient, totalDamage, survivorClient, earnedMMR, gv_PlayersScores[infectedClient]);
    }
}

public void OnPlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
    int survivorIncapacitated = GetClientOfUserId(event.GetInt("userid"));
    int infectedClient        = GetClientOfUserId(event.GetInt("attacker"));

    // Player reducer MMR
    if (IsValidClient(survivorIncapacitated) && GetClientTeam(survivorIncapacitated) == 2)
    {
        // Check if is valid client and the attacker is not a friendly fire
        if (!IsValidClient(infectedClient) || GetClientTeam(infectedClient) != 2)
        {
            gv_PlayersScores[survivorIncapacitated] -= gv_PlayerScoreLosePerIncapacitated;
            if (gv_ShouldDebug)
                PrintToServer("[SourceRank] [OnPlayerIncapacitated] %d was incapacitated and lose: %f MMR, total: %f", survivorIncapacitated, gv_PlayerScoreLosePerIncapacitated, gv_PlayersScores[survivorIncapacitated]);
        }
        else {
            if (gv_ShouldDebug)
                PrintToServer("[SourceRank] [OnPlayerIncapacitated] Ignored mmr change: Invalid client or friendly fire");
        }
    }
    else {
        if (gv_ShouldDebug)
            PrintToServer("[SourceRank] [OnPlayerIncapacitated] Ignored mmr change: Not a survivor");
        return;
    }

    if (!IsValidClient(infectedClient))
    {
        if (gv_ShouldDebug)
            PrintToServer("[SourceRank] [OnPlayerIncapacitated] Ignored mmr change: Invalid client zombie");
        return;
    }

    if (GetClientTeam(infectedClient) == 2)
    {
        gv_PlayersScores[infectedClient] += gv_PlayerScoreEarnPerIncapacitated;
        PrintToServer("[SourceRank] [OnPlayerIncapacitated] %d incapacitated someone and earn: %f MMR, total: %f", infectedClient, gv_PlayerScoreEarnPerIncapacitated, gv_PlayersScores[infectedClient]);
    }
    else {
        if (gv_ShouldDebug)
            PrintToServer("[SourceRank] [OnPlayerIncapacitated] Ignored mmr change: Not a zombie");
    }
}

public void OnPlayerRevive(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidClient(client))
    {
        if (gv_ShouldDebug)
            PrintToServer("[SourceRank] [OnPlayerRevive] Ignored: invalid client");
        return;
    }

    if (GetClientTeam(client) == 2)
    {
        gv_PlayersScores[client] += gv_PlayerScoreEarnPerRevive;
        if (gv_ShouldDebug)
            PrintToServer("[SourceRank] [OnPlayerRevive] %d revived and earned: %f MMR, total: %f", client, gv_PlayerScoreEarnPerRevive, gv_PlayersScores[client]);
    }
    else {
        if (gv_ShouldDebug)
            PrintToServer("[SourceRank] [OnPlayerRevive] Ignored: invalid team");
    }
}

public void OnSpecialKill(Event event, const char[] name, bool dontBroadcast)
{
    char victimname[32];
    event.GetString("victimname", victimname, sizeof(victimname));
    if (StrEqual(victimname, "Infected"))
    {
        if (gv_ShouldDebug)
            PrintToServer("[SourceRank] Special kill ignored normal infected");
        return;
    }

    int clientDied     = GetClientOfUserId(event.GetInt("userid"));
    int clientAttacker = GetClientOfUserId(event.GetInt("attacker"));

    if (!IsValidClient(clientAttacker))
    {
        if (gv_ShouldDebug)
            PrintToServer("[SourceRank] Special kill ignored: invalid client %d", clientAttacker);
        return;
    }
    if (GetClientTeam(clientAttacker) != 2)
    {
        if (gv_ShouldDebug)
            PrintToServer("[SourceRank] Special kill ignored: invalid team %d", clientAttacker);
        return;
    }
    if (GetClientTeam(clientDied) != 3)
    {
        if (gv_ShouldDebug)
            PrintToServer("[SourceRank] Special kill ignored: invalid enemy team %d", clientAttacker);
        return;
    }

    if (
        StrEqual(victimname, "Hunter") || StrEqual(victimname, "Boomer") || StrEqual(victimname, "Charger") || StrEqual(victimname, "Jockey") || StrEqual(victimname, "Smoker") || StrEqual(victimname, "Tank") || StrEqual(victimname, "Spitter"))
    {
        if (gv_ShouldDebug)
            PrintToServer("[SourceRank] [OnSpecialKill] %d received %f for killing: %s", clientAttacker, gv_PlayerScoreEarnPerSpecialKill, victimname);
        gv_PlayersScores[clientAttacker] += gv_PlayerScoreEarnPerSpecialKill;
        gv_PlayerSpecialInfectedKilled[clientAttacker] += 1
    }
    else
    {
        if (gv_ShouldDebug)
            PrintToServer("[SourceRank] %d wrong victim name: %s", clientAttacker, victimname);
    }
}

public OnServerExitHibernation()
{
    for (int i = 0; i < MAXPLAYERS; i++)
    {
        gv_LastPlayerScore[i] = 0;
        gv_IsDeadPlayer[i]    = false;
    }
    gv_ObjectivesCompleted = 0;
}

public void OnPlayerDie(Event event, const char[] name, bool dontBroadcast)
{
    int userid                 = event.GetInt("userid");
    int client                 = GetClientOfUserId(userid);

    gv_LastPlayerScore[client] = GetClientFrags(client);
    gv_IsDeadPlayer[client]    = true;

    PrintToServer("[SourceRank-OnPlayerDie] Player died %d", userid);
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int userid              = event.GetInt("userid");
    int client              = GetClientOfUserId(userid);

    gv_IsDeadPlayer[client] = false;
    PrintToServer("[SourceRank-OnPlayerSpawn] Player spawned %d", userid);
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
    gv_IsDeadPlayer[client] = true;

    return true;
}

public void OnClientDisconnect(int client)
{
    gv_IsDeadPlayer[client] = false;
}

public void OnObjectiveStart(Event event, const char[] name, bool dontBroadcast)
{
    int  objectiveId = event.GetInt("id");
    char objectiveName[32];
    event.GetString("name", objectiveName, sizeof(objectiveName));
    PrintToServer("[SourceRank-OnObjectiveStart] Objective started: %s : %d", objectiveName, objectiveId);

    int onlinePlayers[MAXPLAYERS];
    GetOnlinePlayers(onlinePlayers, sizeof(onlinePlayers));
    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;
        gv_LastPlayerScore[onlinePlayers[i]] = 0;
    }
}

public void OnObjectiveComplete(Event event, const char[] name, bool dontBroadcast)
{
    int objectiveId = event.GetInt("id");

    if (objectiveId == -1)
    {
        PrintToServer("[SourceRank-OnObjectiveComplete] Invalid objective id, ignoring...");
        return;
    }

    if (gv_ObjectiveInCooldown)
    {
        PrintToServer("[SourceRank-OnObjectiveComplete] WARNING: Objective complete event called, but the 'objectiveInCooldown' is still true..., map did not set correctly the objectives");
        return;
    }
    gv_ObjectiveInCooldown = true;
    CreateTimer(gv_ObjectiveCooldown, Timer_ObjectiveStart);

    char objectiveName[32];
    event.GetString("name", objectiveName, sizeof(objectiveName));
    PrintToServer("[SourceRank-OnObjectiveComplete] Objective completed: %s : %d", objectiveName, objectiveId);

    int onlinePlayers[MAXPLAYERS];
    GetOnlinePlayers(onlinePlayers, sizeof(onlinePlayers));
    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;    // End of the list

        if (gv_IsDeadPlayer[client])
        {
            char playerName[32];
            GetClientName(client, playerName, sizeof(playerName));
            PrintToServer("[PTEC-OnObjectiveComplete] Ignoring %s because he is dead", playerName);
            continue;
        }

        // Objective reward
        {
            // Added score
        }

        // Score reward
        {
            int scoreDifference        = GetClientFrags(client) - gv_LastPlayerScore[client];
            gv_LastPlayerScore[client] = GetClientFrags(client);
            PrintToServer("[SourceRank-OnObjectiveComplete] %d scored: %d, in this round, total: %d", client, scoreDifference, GetClientFrags(client));
            if (scoreDifference > 0)
            {
                // Check the best player
            }
        }
    }

    gv_ObjectivesCompleted++;
}

public Action Timer_ObjectiveStart(Handle timer, any data)
{
    PrintToServer("[SourceRank-Timer_ObjectiveStart] Objective cooldown reseted...");
    gv_ObjectiveInCooldown = false;
    return Plugin_Stop;
}

public void OnObjectivePracticeEnded(Event event, const char[] name, bool dontBroadcast)
{
    PrintToServer("[SourceRank-OnObjectivePracticeEnded] Practice ended");

    gv_ObjectivesCompleted = 0;

    int onlinePlayers[MAXPLAYERS];
    GetOnlinePlayers(onlinePlayers, sizeof(onlinePlayers));
    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;

        gv_LastPlayerScore[client] = 0;

        // Show Rank??
    }
}

public void OnObjectiveRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    PrintToServer("[SourceRank-OnObjectiveRoundStart] Round start");
    gv_ObjectivesCompleted = 0;
}

public void OnObjectiveExtractionComplete(Event event, const char[] name, bool dontBroadcast)
{
    int onlinePlayers[MAXPLAYERS];
    GetOnlinePlayers(onlinePlayers, sizeof(onlinePlayers));
    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;

        if (IsPlayerAlive(client))
        {
            char playerName[32];
            GetClientName(client, playerName, sizeof(playerName));
            PrintToServer("[SourceRank-OnObjectiveExtractionComplete] Ignoring %s because he is dead", playerName);
            continue;
        }

        // Objective reward
        {
            // Added score
        }

        // Score reward
        {
            int scoreDifference        = GetClientFrags(client) - gv_LastPlayerScore[client];
            gv_LastPlayerScore[client] = GetClientFrags(client);
            PrintToServer("[PTEC-OnExtractionComplete] %d scored: %d, in this round, total: %d", client, scoreDifference, GetClientFrags(client));
            if (scoreDifference > 0)
            {
                // Check the best player
            }
        }
    }
}
//#endregion Objective

//#region Survival
public void OnSurvivalWaveStart(Event event, const char[] name, bool dontBroadcast)
{
    if (gv_ServerWave > 0)
    {
        OnSurvivalWaveFinish();
    }

    bool isSupply = event.GetBool("resupply");
    if (!isSupply)
    {
        gv_ServerWave++;
    }

    int onlinePlayers[MAXPLAYERS];
    GetOnlinePlayers(onlinePlayers, sizeof(onlinePlayers));
    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;
        gv_LastPlayerScore[onlinePlayers[i]] = 0;
    }

    PrintToServer("[SourceRank-OnSurvivalWaveStart] Wave %d Started, supply: %b", gv_ServerWave, isSupply);
}

public void OnSurvivalStart(Event event, const char[] name, bool dontBroadcast)
{
    gv_ServerWave = 0;

    PrintToServer("[SourceRank-OnSurvivalStart] Survival Started");
}

public void OnSurvivalPracticeEnded(Event event, const char[] name, bool dontBroadcast)
{
    PrintToServer("[SourceRank-OnSurvivalPracticeEnded] Practice ended");

    int onlinePlayers[MAXPLAYERS];
    GetOnlinePlayers(onlinePlayers, sizeof(onlinePlayers));
    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;

        gv_LastPlayerScore[client] = 0;

        // Added score
    }
}

public void OnSurvivalWaveFinish()
{
    int onlinePlayers[MAXPLAYERS];
    GetOnlinePlayers(onlinePlayers, sizeof(onlinePlayers));
    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;    // End of the list

        if (gv_IsDeadPlayer[client])
        {
            char playerName[32];
            GetClientName(client, playerName, sizeof(playerName));
            PrintToServer("[SourceRank-OnSurvivalWaveFinish] Ignoring %s because he is dead", playerName);
            continue;
        }

        // Wave survival reward
        {
            // Added score
        }

        // Score reward
        {
            int scoreDifference        = GetClientFrags(client) - gv_LastPlayerScore[client];
            gv_LastPlayerScore[client] = GetClientFrags(client);
            PrintToServer("[PTEC-OnSurvivalWaveFinish] %d scored: %d, in this round, total: %d", client, scoreDifference, GetClientFrags(client));
            if (scoreDifference > 0)
            {
                // Check best player
            }
        }
    }

    PrintToServer("[SourceRank-OnSurvivalWaveFinish] Wave %d Finished", gv_ServerWave);
}

public void OnSurvivalExtractionBegin(Event event, const char[] name, bool dontBroadcast)
{
    OnSurvivalWaveFinish();
}
//#endregion Survival

//
// #endregion Events
//

//
// #region Commands
//
public Action CommandReload(int client, int args)
{
    if (client != 0 && !IsValidClient(client))
        return Plugin_Stop;
    if (client != 0 && !CheckCommandAccess(client, "sm_rankreload", ADMFLAG_CONFIG))
    {
        PrintToChat(client, "[ERROR] Only admins can use this command.");
        return Plugin_Stop;
    }

    ReadVariables();
    ReadConfigs();

    if (client == 0)
        PrintToServer("[SourceRank] Variables reloaded.");
    else
        PrintToChat(client, "[SourceRank] Variables reloaded.");

    return Plugin_Handled;
}

public Action CommandViewRank(int client, int args)
{
    if (gv_ShouldDebug)
        PrintToServer("[SourceRank] %d requested rank menu", client);

    ShowRankMenu(client);

    return Plugin_Handled;
}
//
// #endregion Events
//

//
// #region Utils
//
stock float GetRankEarnByTimeStampSurvival()
{
    float result    = gv_PlayerScoreStartSurvival;
    float increment = gv_TimeStampSurvived * gv_PlayerScoreEarnSurvivalPerSecond;

    return result + increment;
}

stock float GetRankEarnByTimeStampInfected()
{
    float result    = gv_PlayerScoreInfectedStartSurvival;
    float decrement = gv_TimeStampSurvived * gv_PlayerScoreInfectedLoseSurvivalPerSecond;

    return result - decrement;
}

stock void GetOnlinePlayers(int[] onlinePlayers, int playerSize)
{
    int arrayIndex = 0;
    for (int i = 1; i < MaxClients; i += 1)
    {
        if (arrayIndex >= playerSize)
        {
            break;
        }

        int client = i;

        if (!IsValidClient(client))
        {
            continue;
        }

        onlinePlayers[arrayIndex] = client;
        arrayIndex++;
    }
}

stock bool IsValidClient(client)
{
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || IsFakeClient(client))
    {
        return false;
    }
    return IsClientInGame(client);
}

stock void ClearPlayerScores()
{
    // Cleanup player scores
    for (int i = 0; i < MAXPLAYERS; i++)
    {
        gv_PlayersScores[i] = 0.0;
    }

    // Cleanup special infected killed
    for (int i = 0; i < MAXPLAYERS; i++)
    {
        gv_PlayerSpecialInfectedKilled[i] = 0;
    }

    PrintToServer("[SourceRank] Scores cleared");
}

stock void ClearSinglePlayerScore(int client)
{
    gv_PlayersScores[client]               = 0.0;
    gv_PlayerSpecialInfectedKilled[client] = 0;

    PrintToServer("[SourceRank] client %d Scores cleared", client);
}

void GetRankNameFromRank(int rank, char[] output, int maxlen)
{
    for (int i = gv_RankCount - 1; i >= 0; i--)
    {
        if (rank >= gv_RankThresholds[i])
        {
            strcopy(output, maxlen, gv_RankNames[i]);
            return;
        }
    }

    strcopy(output, maxlen, "Unranked");
}

stock void UploadMMR(int client, float mmrfloat)
{
    int mmr = RoundToNearest(mmrfloat);

    if (mmr > 100)
    {
        PrintToServer("[SourceRank] INVALID MMR TOO HIGH: %d, MMR: %d", client, mmr);
        return;
    }

    if (!IsValidClient(client)) return;

    int steamid = GetSteamAccountID(client);

    if (steamid == 0)
    {
        PrintToServer("[SourceRank] Invalid steamid when uploading MMR %d", client);
        return;
    }

    Database database = CreateDatabaseConnection();
    if (database == null) return;

    char game[64];
    GetGameFolderName(game, sizeof(game));

    char query[256];
    Format(query, sizeof(query), "UPDATE `%s` SET rank = GREATEST(rank + %d, 0) WHERE uniqueid = %d", game, mmr, steamid);

    if (gv_ShouldDebug)
        PrintToServer("[SourceRank] Query: %s", query);

    DataPack pack = new DataPack();
    pack.WriteCell(client);
    pack.WriteCell(mmr);

    SQL_TQuery(database, UploadMMR_Callback, query, pack, DBPrio_Low);
}

stock void UploadMMR_Callback(
    Database    db,
    DBResultSet results,
    const char[] error,
    any data)
{
    DataPack pack = view_as<DataPack>(data);
    pack.Reset();

    int client = pack.ReadCell();
    int mmr    = pack.ReadCell();

    delete pack;

    if (error[0])
    {
        PrintToServer("[SourceRank] UploadMMR_Callback SQL Error: %s", error);
        return;
    }

    PrintToServer("[SourceRank] Updated %d mmr to: %d", client, mmr);
    PrintToChat(client, "[SourceRank] %d MMR", mmr);
}

stock void RegisterPlayer(const int client)
{
    if (!IsValidClient(client))
    {
        return;
    }

    int steamid = GetSteamAccountID(client);

    if (steamid == 0)
    {
        PrintToServer("[SourceRank] Invalid client when registering player");
        return;
    }

    Database database = CreateDatabaseConnection();
    if (database == null) return;

    char game[64];
    GetGameFolderName(game, sizeof(game));

    char query[256];
    Format(query, sizeof(query), "INSERT INTO `%s` (uniqueid) VALUES (%d)", game, steamid);

    if (gv_ShouldDebug)
        PrintToServer("[SourceRank] Query: %s", query);

    SQL_TQuery(database, RegisterPlayer_Callback, query, _, DBPrio_Low);
}

stock void RegisterPlayer_Callback(
    Database    db,
    DBResultSet results,
    const char[] error,
    any data)
{
    if (error[0])
    {
        // Ignore prints if the error is from duplicate entry
        if (StrContains(error, "Duplicate entry", false) == -1)
        {
            PrintToServer("[SourceRank] RegisterPlayer_Callback SQL Error: %s", error);
        }
    }
}

public void ShowRankMenu(const int client)
{
    if (!IsValidClient(client))
    {
        return;
    }

    int steamid = GetSteamAccountID(client);

    if (steamid == 0)
    {
        PrintToServer("[SourceRank] Invalid client when show rank menu");
        return;
    }

    Database database = CreateDatabaseConnection();
    if (database == null) return;

    char game[64];
    GetGameFolderName(game, sizeof(game));

    char query[256];
    Format(query, sizeof(query), "SELECT rank FROM `%s` WHERE uniqueid = %d", game, steamid);

    if (gv_ShouldDebug)
        PrintToServer("[SourceRank] Query: %s", query);

    SQL_TQuery(database, ShowRankMenu_Callback, query, client, DBPrio_High);
}

stock void ShowRankMenu_Callback(
    Database    db,
    DBResultSet results,
    const char[] error,
    any data)
{
    int client = data;

    if (error[0])
    {
        PrintToServer("[SourceRank] ShowRankMenu_Callback SQL Error: %s", error);
        return;
    }

    if (!IsValidClient(client)) return;

    if (results != null && SQL_HasResultSet(results))
    {
        while (SQL_FetchRow(results))
        {
            char rank[128];
            SQL_FetchString(results, 0, rank, sizeof(rank));

            Menu menu = new Menu(MenuHandler);
            char rankName[128];
            GetRankNameFromRank(StringToInt(rank), rankName, sizeof(rankName));

            menu.SetTitle("Your Current Rank: %s, Total MMR: %s", rankName, rank);
            menu.AddItem("0", "OK");
            menu.Display(client, 4);
        }
    }
}

stock int MenuHandler(Menu menu, MenuAction action, int client, int param)
{
    return 0;
}

Database       gv_Database = null;
stock Database CreateDatabaseConnection()
{
    if (gv_Database != null && gv_Database != INVALID_HANDLE)
    {
        return gv_Database;
    }

    char error[256];
    gv_Database = SQL_Connect(gv_DatabaseConfig, true, error, sizeof(error));

    if (gv_Database == null)
    {
        PrintToServer(
            "[CreateDatabaseConnection] ERROR: Cannot connect to database '%s': %s",
            gv_DatabaseConfig,
            error);
        return null;
    }

    return gv_Database;
}

// Reset score to max score if needed
stock CheckMaxScore(int client)
{
    if (gv_PlayersScores[client] > gv_PlayerMaxScore)
    {
        if (gv_ShouldDebug)
            PrintToServer("[SourceRank] %d is on max score");

        gv_PlayersScores[client] = gv_PlayerMaxScore;
    }
}
//
// #endregion Utils
//