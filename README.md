# PreFog
Prestrafe и FOG для Counter-Strike 1.6
## Требования / Requirements
- [ReHLDS](https://dev-cs.ru/resources/64/)
- [Amxmodx 1.9.0](https://www.amxmodx.org/downloads-new.php)
- [Reapi (last)](https://dev-cs.ru/resources/73/updates)
- [ReGameDLL (last)](https://dev-cs.ru/resources/67/updates)

## Описание

Плагин показывает: Тип престрейфа, кол-во FOG (frames on the ground), скорость до bhop/gstrafe (перед попаданием на землю) и скорость после. Предназначено для Hide'n'Seek, Kreedz.

![prefog2](https://github.com/OpenHNS/PreFog/assets/63194135/5d337dec-e910-4df9-840a-6616323f5af4)![prefog1](https://github.com/OpenHNS/PreFog/assets/63194135/7bc4c812-75fc-49e8-addf-4ab8add93618)

Также плагин указывает эффективность вашего bhop/gstrafe:

[P] - perfect

[G] - good

[B] - bad

[VB] - very bad

Идея плагина была взята с [KZ-Stats](https://github.com/ddenzer/KZ-Stats)

Алгоритм фогов позаимствовал у [Theggv](https://github.com/Theggv/Kreedz/blob/master/src/scripts/utility/kz_fog.sma)

Вдохновлялся jumpstats от Kpoluk

## Команды чата / Chat commands

/showpre - on/off pre
/pre - on/off pre

## Установка
 
1. Скомпилируйте плагин.

2. Скопируйте скомпилированный файл `.amxx` в директорию: `amxmodx/plugins/`

3. Пропишите `.amxx` в файле `amxmodx/configs/plugins.ini`

4. Перезапустите сервер или поменяйте карту.
