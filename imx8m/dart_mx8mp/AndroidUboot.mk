# uboot.imx in android combine scfw.bin and uboot.bin
MAKE += SHELL=/bin/bash

ifneq ($(AARCH64_GCC_CROSS_COMPILE),)
ATF_CROSS_COMPILE := $(strip $(AARCH64_GCC_CROSS_COMPILE))
IMX_DEVICE_PATH := device/variscite/imx8m/dart_mx8mp
else
  $(error shell env AARCH64_GCC_CROSS_COMPILE is not set)
endif

UBOOT_DTB="imx8mp-var-dart-dt8mcustomboard.dtb imx8mp-var-dart-dt8mcustomboard-legacy.dtb imx8mp-var-som-symphony.dtb"

define build_imx_uboot
	$(hide) echo Building i.MX U-Boot with firmware; \
	cp $(UBOOT_OUT)/u-boot-nodtb.$(strip $(1)) $(IMX_MKIMAGE_PATH)/imx-mkimage/iMX8M/.; \
	cp $(UBOOT_OUT)/spl/u-boot-spl.bin  $(IMX_MKIMAGE_PATH)/imx-mkimage/iMX8M/.; \
	cp $(UBOOT_OUT)/tools/mkimage  $(IMX_MKIMAGE_PATH)/imx-mkimage/iMX8M/mkimage_uboot; \
	cp $(UBOOT_OUT)/arch/arm/dts/imx8mp-var-dart-dt8mcustomboard.dtb $(IMX_MKIMAGE_PATH)/imx-mkimage/iMX8M/.; \
	cp $(UBOOT_OUT)/arch/arm/dts/imx8mp-var-dart-dt8mcustomboard-legacy.dtb $(IMX_MKIMAGE_PATH)/imx-mkimage/iMX8M/.; \
	cp $(UBOOT_OUT)/arch/arm/dts/imx8mp-var-som-symphony.dtb $(IMX_MKIMAGE_PATH)/imx-mkimage/iMX8M/.; \
	cp $(FSL_PROPRIETARY_PATH)/linux-firmware-imx/firmware/ddr/synopsys/lpddr4_pmu_train* $(IMX_MKIMAGE_PATH)/imx-mkimage/iMX8M/.; \
	$(MAKE) -C $(IMX_PATH)/arm-trusted-firmware/ PLAT=`echo $(2) | cut -d '-' -f1` clean; \
	if [ `echo $(2) | cut -d '-' -f2` = "trusty" ]; then \
		cp $(FSL_PROPRIETARY_PATH)/fsl-proprietary/uboot-firmware/imx8m/tee-imx8mp.bin $(IMX_MKIMAGE_PATH)/imx-mkimage/iMX8M/tee.bin; \
		$(MAKE) -C $(IMX_PATH)/arm-trusted-firmware/ CROSS_COMPILE="$(ATF_CROSS_COMPILE)" PLAT=`echo $(2) | cut -d '-' -f1` bl31 -B SPD=trusty 1>/dev/null || exit 1; \
	else \
		if [ -f $(IMX_MKIMAGE_PATH)/imx-mkimage/iMX8M/tee.bin ] ; then \
			rm -rf $(IMX_MKIMAGE_PATH)/imx-mkimage/iMX8M/tee.bin; \
		fi; \
		$(MAKE) -C $(IMX_PATH)/arm-trusted-firmware/ CROSS_COMPILE="$(ATF_CROSS_COMPILE)" PLAT=`echo $(2) | cut -d '-' -f1` bl31 -B 1>/dev/null || exit 1; \
	fi; \
	cp $(IMX_PATH)/arm-trusted-firmware/build/`echo $(2) | cut -d '-' -f1`/release/bl31.bin $(IMX_MKIMAGE_PATH)/imx-mkimage/iMX8M/bl31.bin; \
	$(MAKE) -C $(IMX_MKIMAGE_PATH)/imx-mkimage/ clean; \
	$(MAKE) -C $(IMX_MKIMAGE_PATH)/imx-mkimage/ SOC=iMX8MP dtbs=${UBOOT_DTB} flash_evk || exit 1; \
	cp $(UBOOT_OUT)/arch/arm/dts/imx8mp-var-dart-dt8mcustomboard.dtb $(IMX_MKIMAGE_PATH)/imx-mkimage/iMX8M/.; \
	cp $(UBOOT_OUT)/arch/arm/dts/imx8mp-var-dart-dt8mcustomboard-legacy.dtb $(IMX_MKIMAGE_PATH)/imx-mkimage/iMX8M/.; \
	cp $(UBOOT_OUT)/arch/arm/dts/imx8mp-var-som-symphony.dtb $(IMX_MKIMAGE_PATH)/imx-mkimage/iMX8M/.; \
	$(MAKE) -C $(IMX_MKIMAGE_PATH)/imx-mkimage/ SOC=iMX8MP dtbs=${UBOOT_DTB} print_fit_hab || exit 1; \
	cp $(IMX_MKIMAGE_PATH)/imx-mkimage/iMX8M/flash.bin $(UBOOT_COLLECTION)/u-boot-$(strip $(2)).imx; \

endef
