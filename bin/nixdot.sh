#!/usr/bin/env bash

set -euo pipefail

CONFIG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)
      CONFIG="$2"
      shift 2
      ;;
    *)
      echo "Argument inconnu : $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$CONFIG" ]]; then
  echo "Usage: nixdot --config <fichier>" >&2
  exit 1
fi

if [[ ! -f "$CONFIG" ]]; then
  echo "Fichier introuvable : $CONFIG" >&2
  exit 1
fi

echo "Fichier reçu : $CONFIG"
echo "Contenu du fichier :"
cat "$CONFIG"

USERNAME=$(nix eval --raw --file "$CONFIG" --apply 'config: config.username')
HOME_DIRECTORY=$(nix eval --raw --file "$CONFIG" --apply 'config: config.homeDirectory')

echo "Username : $USERNAME"
echo "Home directory : $HOME_DIRECTORY"