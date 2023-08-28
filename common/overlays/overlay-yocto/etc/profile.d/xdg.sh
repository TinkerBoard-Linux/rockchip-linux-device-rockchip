#!/bin/sh
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/`id -u weston`}
chown weston:weston -R /run/user/1000
