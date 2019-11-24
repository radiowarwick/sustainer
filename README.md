# Sustainer 2.0

This is a new version of the sustainer system which uses `liquidsoap`. This uses the API interface from [Digiplay Laravel](https://github.com/radiowarwick/digiplay-laravel/) so that we never directly talk to the database.

## Installation (developer environment) instructions

1. Make sure you have `liquidsoap` installed
2. `git clone https://github.com/radiowarwick/sustainer.git`
3. `cd sustainer`
4. `cp config.liq.example config.liq`
5. Fill `config.liq` with configuration values
6. Run using `liquidsoap script/sustainer.liq`

## Installing in production

The Sustainer is run through a docker container, and allows you to have phyiscal output via ALSA, as well as sending the audio to an icecast server.

First make a copy of `config.liq.example` and fill it in with your config information. (API key, Icecast information, weightings, etc.)

The most basic execution of the container is as follows:
`docker run --device /dev/snd --group-add audio -v /mnt/dps0-0:/mnt/dps0-0:ro -v /path/to/my/config.liq:/sustainer/config.liq -v /var/sustainer.log:/var/log/liquidsoap/sustainer.log raw1251am/sustainer`

`--device /dev/snd --group-add audio` This gives the container access to the host's sound device and gives the container audio group permissions.

`-v /mnt/dps0-0:/mnt/dps0-0` Mounts the audio file system, change left hand side if your audio is mounted in a different location.

`-v /path/to/my/config.liq:/sustainer/config.liq` This maps your config file for the sustainer to use. Change left hand path to map to your config file

`-v /var/sustainer.log:/var/log/liquidsoap/sustainer.log` maps the log file out of the container, change left hand side to your log location