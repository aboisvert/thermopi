#!/usr/bin/env fish

if test -n "$USB"
  set USB_DEVICE "--device=/dev/ttyUSB0"
end

set GID (id -g $USER)
set UID (id -u $USER)

set RUN_SCRIPT (mktemp -p $PWD)

# Run container as current $USER to avoid messing up permissions 
# when mounting $PWD to /project within the container

echo "
addgroup --gid $GID $USER
mkdir -p /home/$USER
useradd --home /home/$USER --gid $GID --uid $UID  $USER
mkdir -p /home/$USER
chown $USER:$GID /home/$USER
chsh -s /usr/bin/fish $USER 
runuser $USER
" > $RUN_SCRIPT

function on_exit --on-event fish_exit
  #echo Deleting $RUN_SCRIPT
  rm -rf $RUN_SCRIPT
end

set CONTAINER_SCRIPT /project/(basename $RUN_SCRIPT)
docker run --rm -v $PWD:/project $USB_DEVICE -w /project -it hvac_controller /usr/bin/fish $CONTAINER_SCRIPT
