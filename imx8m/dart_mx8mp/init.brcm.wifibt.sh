#!/vendor/bin/sh

#################################
# /etc/wifi/variscite-wifi.conf #
#################################

#BT_EN_GPIO=68
BT_EN_RFKILL=0

WIFI_PWR_GPIO=40
WIFI_PWR_GPIO_SOM=51

WIFI_EN_GPIO=39
WIFI_EN_GPIO_SOM=40

BT_BUF_GPIO=41
BT_BUF_GPIO_SOM=4

WIFI_MMC_HOST=30b40000.mmc
WIFI_SDIO_ID_FILE=/sys/bus/mmc/devices/mmc0:0001/mmc0:0001:1/device
WIFI_5G_SDIO_ID=0x4339

# Return true if board is VAR-SOM-MX8M-PLUS
board_is_var_som_mx8m_plus()
{
	grep -q VAR-SOM-MX8M-PLUS /sys/devices/soc0/machine
}

# Configure VAR-SOM-MX8M-PLUS WIFI/BT pins
config_pins()
{
	if board_is_var_som_mx8m_plus; then
		WIFI_PWR_GPIO=${WIFI_PWR_GPIO_SOM}
		WIFI_EN_GPIO=${WIFI_EN_GPIO_SOM}
		BT_BUF_GPIO=${BT_BUF_GPIO_SOM}
		BT_EN_GPIO=${BT_EN_GPIO_SOM}
	fi
}

######################################
# /etc/wifi/variscite-wifi-common.sh #
######################################

# Setup WIFI control GPIOs
wifi_pre_up()
{
	# Configure WIFI/BT pins
	config_pins
	if [ ! -d /sys/class/gpio/gpio${WIFI_PWR_GPIO} ]; then
		echo ${WIFI_PWR_GPIO} > /sys/class/gpio/export
		echo out > /sys/class/gpio/gpio${WIFI_PWR_GPIO}/direction
	fi

	if [ ! -d /sys/class/gpio/gpio${WIFI_EN_GPIO} ]; then
		echo ${WIFI_EN_GPIO} > /sys/class/gpio/export
		echo out > /sys/class/gpio/gpio${WIFI_EN_GPIO}/direction
	fi

	if [ ! -d /sys/class/gpio/gpio${BT_BUF_GPIO} ]; then
		echo ${BT_BUF_GPIO} > /sys/class/gpio/export
		echo out > /sys/class/gpio/gpio${BT_BUF_GPIO}/direction
	fi

	#if [ ! -d /sys/class/gpio/gpio${BT_EN_GPIO} ]; then
	#	echo ${BT_EN_GPIO} > /sys/class/gpio/export
	#	echo out > /sys/class/gpio/gpio${BT_EN_GPIO}/direction
	#fi
}

# Power up WIFI chip
wifi_up()
{
	# Configure WIFI/BT pins
	config_pins
	# Unbind WIFI device from MMC controller
	if [ -e /sys/bus/platform/drivers/sdhci-esdhc-imx/${WIFI_MMC_HOST} ]; then
		echo ${WIFI_MMC_HOST} > /sys/bus/platform/drivers/sdhci-esdhc-imx/unbind
	fi

	# WIFI_PWR up
	echo 1 > /sys/class/gpio/gpio${WIFI_PWR_GPIO}/value
	usleep 10000

	# WLAN_EN up
	echo 1 > /sys/class/gpio/gpio${WIFI_EN_GPIO}/value

	# BT_EN up via rfkill
	#echo 1 > /sys/class/gpio/gpio${BT_EN_GPIO}/value
	echo 1 > /sys/class/rfkill/rfkill${BT_EN_RFKILL}/state

	# BT_BUF up
	echo 0 > /sys/class/gpio/gpio${BT_BUF_GPIO}/value

	# Wait at least 150ms
	usleep 200000

	# Bind WIFI device to MMC controller
	echo ${WIFI_MMC_HOST} > /sys/bus/platform/drivers/sdhci-esdhc-imx/bind

	# Load WIFI driver
	modprobe -d /vendor/lib/modules brcmfmac p2pon=1
}

# Power down WIFI chip
wifi_down()
{
	# Configure WIFI/BT pins
	config_pins

	# Unload WIFI driver
	modprobe -d /vendor/lib/modules -r brcmfmac

	# Unbind WIFI device from MMC controller
	if [ -e /sys/bus/platform/drivers/sdhci-esdhc-imx/${WIFI_MMC_HOST} ]; then
		echo ${WIFI_MMC_HOST} > /sys/bus/platform/drivers/sdhci-esdhc-imx/unbind
	fi

	# WIFI_EN down
	echo 0 > /sys/class/gpio/gpio${WIFI_EN_GPIO}/value

	# BT_BUF down
	echo 1 > /sys/class/gpio/gpio${BT_BUF_GPIO}/value

	# BT_EN down
	#echo 0 > /sys/class/gpio/gpio${BT_EN_GPIO}/value
	#echo 0 > /sys/class/rfkill/rfkill${BT_EN_RFKILL}/state

	usleep 10000

	# WIFI_PWR down
	echo 0 > /sys/class/gpio/gpio${WIFI_PWR_GPIO}/value
}

##################
# variscite-wifi #
##################

# Return true if WIFI interface exists
wifi_interface_exists()
{
	for i in $(seq 1 20); do
		[ -d /sys/class/net/wlan0 ] && return 0
		sleep 1
	done

	return 1
}

# Start WIFI hardware
wifi_start()
{
	# Setup WIFI control GPIOs
	wifi_pre_up
	wifi_up
	return 1
}

#################################################
#              Execution starts here            #
#################################################

wifi_start

# BT_BUF up
echo 0 > /sys/class/gpio/gpio${BT_BUF_GPIO}/value
setprop ro.boot.dart_imx8mp "true"
chip_id=`cat /sys/bus/mmc/devices/mmc0\:0001/mmc0\:0001\:1/device`

if [[ "$chip_id" = "0x4339" ]]; then
        setprop ro.boot.bt_firmware "BCM4335C0.hcd"
else
        setprop ro.boot.bt_firmware "BCM43430A1.hcd"
fi

# always set property even if wifi failed
# as property value "1" is expected in early-boot trigger
setprop sys.brcm.wifibt.completed 1

exit 0