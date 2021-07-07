#!/bin/bash

# initialize our error check and alert function
failfunction()
{
    if [ "$1" != 0 ]
    then echo "One of the commands has failed!!"
         #echo "One of the docker backup tasks failed." | s-nail -v -s "Task failed." -S smtp=smtp://outbound.x86txt.lan -S from="alert@x86txt.com" matt@x86txt.com
         exit
    fi
}

#initialize dates and variables
current_time=$(date "+%Y.%m.%d-%H.%M.%S")
names_file="/tmp/docker_names"

# get docker names into array
/usr/bin/docker ps --format {{.Names}} > $names_file

# let's create our folder structure and then use autocompose to dump each container to a docker_compose.yml
lines=`cat $names_file`
echo "Starting backup of Docker environment ..."
echo -e "  \e[90m[\e[32m*\e[90m] \e[39mCreating folder structure and generating docker_compose.yml files ..."
for line in $lines; do
        mkdir -p /mnt/us-east-1/docker_compose/$line
            failfunction "$?"
        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock red5d/docker-autocompose:latest -v 1 $line > /mnt/us-east-1/docker_compose/$line/docker_compose.yml.$current_time
            failfunction "$?"
done

# let's backup our bind mount folders also
echo -e "  \e[90m[\e[32m*\e[90m] \e[39mBacking up bind mount directories ..."
export XZ_OPT="-9e --threads=4"
/usr/bin/tar --exclude="/mnt/docker/nginx_media" -cJf /mnt/us-east-1/docker/backup.$current_time.tar.xz /mnt/docker/ 2>/dev/null
    failfunction "$?"

# remove docker names file
echo -e "  \e[90m[\e[32m*\e[90m] \e[39mCleaning up ..."
/usr/bin/rm /tmp/docker_names

echo -e "Done!"

exit 0
