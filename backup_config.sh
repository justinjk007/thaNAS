#!/bin/bash -x

# Configure
# https://github.com/andreafabrizi/Dropbox-Uploader

cd ~/plex
rm -rf thaNAS_config.7z
7z a thaNAS_config ~/plex/config

~/plex/dropbox_uploader.sh upload thaNAS_config.7z Backup/thaNAS_config.7z
