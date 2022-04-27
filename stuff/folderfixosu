#!/bin/bash

# This will remove a single quote (') that comes with the argument for some reason
truepath=${2::-1}

# This will execute the first argument with the unix path provided by the second argument
echo "$truepath" | sed -e 's/\\/\//g' -e 's/://' | sed -r 's/^.{1}//' | xargs -d \\n $1
