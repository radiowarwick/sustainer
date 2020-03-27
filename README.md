# Sustainer 2.0

This is a new version of the sustainer system which uses `liquidsoap`. This uses the API interface from [Digiplay Laravel](https://github.com/radiowarwick/digiplay-laravel/) so that we never directly talk to the database.

## Installation (developer environment) instructions

1. Make sure you have `liquidsoap` installed
2. `git clone https://github.com/radiowarwick/sustainer.git`
3. `cd sustainer`
4. `cp sutainer.config.example sustainer.config`
5. Fill `sustainer.config` with configuration values
6. Run using `liquidsoap sustainer.liq`

## Installing in production (liqudsoap dameon)

If you would like to install the sustainer to be run using liquidsoap's built in daemon then you'll need to do the following.

```bash
ln -s $(pwd)/sustainer.liq /etc/liquidsoap/sustainer.liq
ln -s $(pwd)/sustainer.config /etc/liquidsoap/sustainer.config
systemctl restart liquidsoap
```

## Installing in production (docker)

The Sustainer is run through a docker container, and allows you to have phyiscal output via ALSA, as well as sending the audio to an icecast server.

First make a copy of `config.liq.example` and fill it in with your config information. (API key, Icecast information, weightings, etc.)

The most basic execution of the container is as follows:
`docker run --device /dev/snd -v /mnt/dps0-0:/mnt/dps0-0:ro -v /path/to/my/config.liq:/sustainer/config.liq -v /var/sustainer.log:/var/log/liquidsoap/sustainer.log raw1251am/sustainer`

`--device /dev/snd` This gives the container access to the host's sound device.

`-v /mnt/dps0-0:/mnt/dps0-0` Mounts the audio file system, change left hand side if your audio is mounted in a different location.

`-v /path/to/my/config.liq:/sustainer/config.liq` This maps your config file for the sustainer to use. Change left hand path to map to your config file

`-v /var/sustainer.log:/var/log/liquidsoap/sustainer.log` maps the log file out of the container, change left hand side to your log location