#!/usr/bin/env bash
# Mise a jour de la base (Linux). Usage : ./update.sh [check|force]
exec bash "$(cd "$(dirname "$0")" && pwd)/resources/[standalone]/updater/tools/update.sh" "$@"
