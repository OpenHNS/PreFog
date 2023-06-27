# PreFog

Prestrafe and FOG for Counter-Strike 1.6

## Requirements

- [ReHLDS](https://dev-cs.ru/resources/64/)
- [Amxmodx 1.9.0](https://www.amxmodx.org/downloads-new.php)
- [Reapi (last)](https://dev-cs.ru/resources/73/updates)
- [ReGameDLL (last)](https://dev-cs.ru/resources/67/updates)

## Description

The plugin shows: the type of pre-strike, the amount of FOG (frames on the ground), speed before bhop/gstrafe (before hitting the ground) and speed after. Intended for Hide'n'Seek, Kreedz.

![prefog2](https://github.com/OpenHNS/PreFog/assets/63194135/5d337dec-e910-4df9-840a-6616323f5af4) ![prefog1](https://github.com/OpenHNS/PreFog/assets/63194135/7bc4c812-75fc-49e8-addf-4ab8add93618)

The plugin also indicates the effectiveness of your bhop/gstrafe:

[P] - perfect

[G] - good

[B] - bad

[VB] - very bad

The plugin idea was taken from [KZ-Stats] (https://github.com/ddenzer/KZ-Stats)

Algorithm was borrowed from [Theggv](https://github.com/Theggv/Kreedz/blob/master/src/scripts/utility/kz_fog.sma)

Inspired by Kpoluk's jumpstats

## Chat commands

/showpre - on/off pre
/pre - on/off pre

## Setup
 
1. Compile the plugin.

2. Copy compiled file `.amxx` to directory: `amxmodx/plugins/`.

3. Write `.amxx` in file `amxmodx/configs/plugins.ini`.

4. Restart the server or change the map.
