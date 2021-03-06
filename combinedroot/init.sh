#!/sbin/busybox sh
set +x
_PATH="$PATH"
export PATH=/sbin

busybox cd /
busybox date >>boot.txt
exec >>boot.txt 2>&1
busybox rm /init

# include device specific vars
source /sbin/bootrec-device

# create directories
busybox mkdir -m 755 -p /cache
busybox mkdir -m 755 -p /dev/block
busybox mkdir -m 755 -p /dev/input
busybox mkdir -m 555 -p /proc
busybox mkdir -m 755 -p /sys

# create device nodes
busybox mknod -m 600 /dev/block/mmcblk0 b 179 0
busybox mknod -m 600 ${BOOTREC_CACHE_NODE}
busybox mknod -m 600 ${BOOTREC_EVENT_NODE}
busybox mknod -m 666 /dev/null c 1 3

# mount filesystems
busybox mount -t proc proc /proc
busybox mount -t sysfs sysfs /sys
busybox mount -t yaffs2 ${BOOTREC_CACHE} /cache

# leds & backlight configuration
busybox echo ${BOOTREC_LED_RED_CURRENT} > ${BOOTREC_LED_RED}/max_current
busybox echo ${BOOTREC_LED_GREEN_CURRENT} > ${BOOTREC_LED_GREEN}/max_current
busybox echo ${BOOTREC_LED_BLUE_CURRENT} > ${BOOTREC_LED_BLUE}/max_current
busybox echo ${BOOTREC_LED_BUTTONS_CURRENT} > ${BOOTREC_LED_BUTTONS}/max_current
busybox echo ${BOOTREC_LED_BUTTONS2_CURRENT} > ${BOOTREC_LED_BUTTONS2}/max_current
busybox echo ${BOOTREC_LED_LCD_CURRENT} > ${BOOTREC_LED_LCD}/max_current
busybox echo ${BOOTREC_LED_LCD_MODE} > ${BOOTREC_LED_LCD}/mode

# trigger lime green LED & button-backlight
busybox echo 25 > ${BOOTREC_LED_RED}/brightness
busybox echo 255 > ${BOOTREC_LED_GREEN}/brightness
busybox echo 0 > ${BOOTREC_LED_BLUE}/brightness
busybox echo 255 > ${BOOTREC_LED_BUTTONS}/brightness
busybox echo 255 > ${BOOTREC_LED_BUTTONS2}/brightness
busybox echo 50 > /sys/class/timed_output/vibrator/enable
busybox sleep 1

# trigger pink LED
busybox echo 100 > ${BOOTREC_LED_RED}/brightness
busybox echo 35 > ${BOOTREC_LED_GREEN}/brightness
busybox echo 50 > ${BOOTREC_LED_BLUE}/brightness
busybox echo 50 > /sys/class/timed_output/vibrator/enable
busybox sleep 1

# trigger aqua blue LED
busybox echo 0 > ${BOOTREC_LED_RED}/brightness
busybox echo 100 > ${BOOTREC_LED_GREEN}/brightness
busybox echo 255 > ${BOOTREC_LED_BLUE}/brightness
busybox echo 200 > /sys/class/timed_output/vibrator/enable

#trigger vibrator
#echo 100 > /sys/class/timed_output/vibrator/enable

# keycheck
busybox cat ${BOOTREC_EVENT} > /dev/keycheck&
busybox sleep 3

# android ramdisk
load_image=/sbin/ramdisk.cpio

# boot decision
if [ -s /dev/keycheck -o -e /cache/recovery/boot ]
then
	busybox echo 'RECOVERY BOOT' >>boot.txt
	busybox rm -fr /cache/recovery/boot
	# trigger blue led
	busybox echo 0 > ${BOOTREC_LED_RED}/brightness
	busybox echo 0 > ${BOOTREC_LED_GREEN}/brightness
	busybox echo 255 > ${BOOTREC_LED_BLUE}/brightness
	busybox echo 0 > ${BOOTREC_LED_BUTTONS}/brightness
	busybox echo 0 > ${BOOTREC_LED_BUTTONS2}/brightness
	# framebuffer fix
	busybox echo 0 > /sys/module/msm_fb/parameters/align_buffer
	# recovery ramdisk
	load_image=/sbin/ramdisk-recovery.cpio
else
	busybox echo 'ANDROID BOOT' >>boot.txt
	# poweroff LED & button-backlight
	busybox echo 0 > ${BOOTREC_LED_RED}/brightness
	busybox echo 0 > ${BOOTREC_LED_GREEN}/brightness
	busybox echo 0 > ${BOOTREC_LED_BLUE}/brightness
	busybox echo 0 > ${BOOTREC_LED_BUTTONS}/brightness
	busybox echo 0 > ${BOOTREC_LED_BUTTONS2}/brightness
	# framebuffer fix
	busybox echo 1 > /sys/module/msm_fb/parameters/align_buffer
fi

# kill the keycheck process
busybox pkill -f "busybox cat ${BOOTREC_EVENT}"

# unpack the ramdisk image
busybox cpio -i < ${load_image}

busybox umount /cache
busybox umount /proc
busybox umount /sys

busybox rm -fr /dev/*
busybox date >>boot.txt
export PATH="${_PATH}"
exec /init
