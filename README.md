# Source Rank
Creates a ranking system that works across multiple servers.

!rank, to view your rank

## Features
- On round end receive MMR or lose based on your gameplay
- [Left 4 Dead 2] On survival and versus show the survivor MVP (Most killed special infected)
- [No More Room in Hell] End of objective or round show the survivor MVP (Most scores) (TO DO)

## Requirements
- If ``rankDisplayRank`` is enabled [chat-processor](https://github.com/KeithGDR/chat-processor) is required
- [Any Sourcemod compatible Database](https://www.mysql.com/)
- Sourcemod and metamod

## CVARS
- rankShouldDebug
- > Enable debug logging
- rankDisableAutoMenu
- > If 0, disables the rank menu on player join
- rankPlayerMaxScore
- > Maximum score a player can earn per round
- rankPlayerScoreLoseOnRoundLose
- > Score lost on round lose
- rankPlayerScoreEarnOnMarker
- > Score earned on marker reached [Left 4 Dead 2 Only]
- rankPlayerScoreEarnOnRoundWin
- > Score earned on round win
- rankPlayerScoreEarnPerSurvivorHurt
- > Score earned per damage dealt to a survivor [Left 4 Dead 2 Only]
- rankPlayerScoreEarnPerSpecialKill
- > Score earned per special infected killed [Left 4 Dead 2 Only]
- rankPlayerScoreEarnPerRevive
- > Score earned per revive [Left 4 Dead 2 Only]
- rankPlayerScoreLosePerIncapacitated
- > Score lost when incapacitated
- rankPlayerScoreEarnPerIncapacitated
- > Score earned for incapacitating a survivor [Left 4 Dead 2 Only]
- rankPlayerScoreStartSurvival
- > Base score for survivors at round end in survival [Left 4 Dead 2 Only]
- rankPlayerScoreEarnSurvivalPerSecond
- > Score earned per second survived [Left 4 Dead 2 Only]
- rankPlayerScoreInfectedStartSurvival
- > Base score for infected at round end in survival [Left 4 Dead 2 Only]
- rankPlayerScoreInfectedLoseSurvivalPerSecond
- > Score lost per second for infected in survival [Left 4 Dead 2 Only]
- rankCount
- > Number of ranks
- rankDatabaseConfig
- > Database config name
- rankNamesPath
- > Rank names file path

## Usage
1. Download the plugin from the latest release:
[Releases Section](https://github.com/LeandroTheDev/left_4_rank/releases)

2. Place the compiled .smx file into the following folder on your server: addons/sourcemod/plugins/

3. Configure database in addons/sourcemod/configs/database.cfg
```
"sourcerank"
{
    "driver"    "default"
    "host"      "127.0.0.1"
    "database"  "mydatabase"
    "pass"      "ultrasecret"
}
```

4. Create the database and table, table must be ``left4dead2`` because the plugin use the game name as table
```sql
CREATE mydatabase
USE mydatabase
CREATE TABLE left4dead2 (
    uniqueid VARCHAR(255) NOT NULL PRIMARY KEY,
    rank DECIMAL(50, 0) NOT NULL DEFAULT 0
);
```

5. Run the server

## Compiling

- Use the compiler from sourcemod to compile the source_rank.sp

