#!/bin/bash

set -e

echo "Init Service..."

function init_service() {

    local LOCAL_ROOT=$1
    local LOCAL_ROOTFS=$2

if [ -f "${LOCAL_ROOTFS}"/etc/init.d/robotchain-host ];then
    cat <<-EOF > "${LOCAL_ROOTFS}"/etc/init.d/robotchain-host
#!/bin/bash

### BEGIN INIT INFO
# Provides:          your_service_name
# Required-Start:    $all
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start your_service_name at boot time
# Description:       Enable service provided by your_service_name
### END INIT INFO

echo "host" > /sys/devices/platform/soc/b2000000.usb/b2000000.dwc3/role

exit 0
EOF
fi

eval 'LC_ALL=C LANG=C chroot $ROOTFS_DIR /bin/bash -c "chmod +x /etc/init.d/robotchain-host"'
eval 'LC_ALL=C LANG=C chroot $ROOTFS_DIR /bin/bash -c "update-rc.d robotchain-host defaults"'
eval 'LC_ALL=C LANG=C chroot $ROOTFS_DIR /bin/bash -c "systemctl enable robotchain-host"'

echo "Init Service Done!"
}