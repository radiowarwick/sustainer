# Sustainer 2.0

This is a new version of the sustainer system which uses `liquidsoap`. This uses the API interface from [Digiplay Laravel](https://github.com/radiowarwick/digiplay-laravel/) so that we never directly talk to the database.

## Installing instructions

1. Make sure you have `liquidsoap` installed
2. `git clone https://github.com/radiowarwick/sustainer.git`
3. `cd sustainer`
4. `cp config.liq.example config.liq`
5. Fill `config.liq` with configuration values
6. Run using `./sustainer.liq`