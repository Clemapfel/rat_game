if [ "$(basename "$(pwd)")" != "rat_game" ]; then
    echo "Executable invoked from the wrong directory, make sure it is called from `/rat_game` using the command `./run_linux.sh`"
fi

./love/linux/bin/love main.lua