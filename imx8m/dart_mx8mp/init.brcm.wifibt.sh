#!/vendor/bin/sh

#################################
# /etc/wifi/variscite-wifi.conf #
#################################

#BT_EN_GPIO=68
BT_EN_RFKILL=0

BT_REG_ON_GPIO=79
BT_REG_ON_GPIO_SOM=110

BT_BUF_GPIO=41
BT_BUF_GPIO_SOM=4

#WIFI_MMC_HOST=30b40000.mmc
#WIFI_SDIO_ID_FILE=/sys/bus/mmc/devices/mmc0:0001/mmc0:0001:1/device
#WIFI_5G_SDIO_ID=0x4339

# Return true if board is VAR-SOM-MX8M-PLUS
board_is_var_som_mx8m_plus()
{
	grep -q VAR-SOM-MX8M-PLUS /sys/devices/soc0/machine
}

# Configure VAR-SOM-MX8M-PLUS WIFI/BT pins
config_pins()
{
	BT_REG_ON_GPIO=${BT_REG_ON_GPIO_SOM}
	BT_BUF_GPIO=${BT_BUF_GPIO_SOM}
}

######################################
# /etc/wifi/variscite-wifi-common.sh #
######################################

# Power up bluetooth regulator
bluetooth_up()
{
	# Configure WIFI/BT pins
	config_pins

	if [ ! -d /sys/class/gpio/gpio${BT_REG_ON_GPIO} ]; then
		echo ${BT_REG_ON_GPIO} > /sys/class/gpio/export
		echo out > /sys/class/gpio/gpio${BT_REG_ON_GPIO}/direction
	fi

	if [ ! -d /sys/class/gpio/gpio${BT_BUF_GPIO} ]; then
		echo ${BT_BUF_GPIO} > /sys/class/gpio/export
		echo out > /sys/class/gpio/gpio${BT_BUF_GPIO}/direction
	fi

	# BT_REG_ON Low
	#echo 0 > /sys/class/gpio/gpio${BT_REG_ON_GPIO}/value

	# Wait at least 100us
	usleep 100



	# BT_BUF up
	echo 0 > /sys/class/gpio/gpio${BT_BUF_GPIO}/value


}


##################
# Ezurio-Bluetooth #
##################


# Start Bluetooth hardware
bluetooth_start()
{
	# Setup Bluetooth control GPIOs
	bluetooth_up

	return 1
}


#################################################
#              Execution starts here            #
#################################################

bluetooth_start

# BT_BUF up
#echo 0 > /sys/class/gpio/gpio${BT_BUF_GPIO}/value
insmod vendor/lib/modules/rfkill.ko
insmod vendor/lib/modules/compat.ko
insmod vendor/lib/modules/cfg80211.ko
insmod vendor/lib/modules/brcmutil.ko
insmod vendor/lib/modules/brcmfmac.ko regdomain="ETSI"
setprop ro.boot.dart_imx8mp "true"
chip_id=`cat /sys/bus/mmc/devices/mmc0\:0001/mmc0\:0001\:1/device`
setprop ro.boot.bt_firmware "CYW55560A1.hcd"

# always set property even if wifi failed
# as property value "1" is expected in early-boot trigger
setprop sys.brcm.wifibt.completed 1
exit 0
