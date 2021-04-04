#!/bin/bash -x

# Get access token, generate one if need too
# https://www.dropbox.com/developers/apps/info/u908atkj2n0n8g7#settings

# export these in .machine_config
# export ACCESS_TOKEN=""
source ~/.machine_config > /dev/null 2>&1

cd ~/plex
7z a thaNAS_config ~/plex/config

curl -X POST https://content.dropboxapi.com/2/files/upload \
     --header "Authorization: Bearer $ACCESS_TOKEN" \
    --header "Dropbox-API-Arg: {\"path\": \"/Backup/thaNAS_config.7z\"}" \
    --header "Content-Type: application/octet-stream" \
    --data-binary @thaNAS_config.7z
