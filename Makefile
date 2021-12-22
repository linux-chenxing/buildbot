LINUX_ARGS = ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-

CHENXING_REPO = https://github.com/linux-chenxing/linux.git
CHENXING_UBOOT_REPO = https://github.com/linux-chenxing/u-boot.git

BRANCH_MAINLINEQUEUE = msc313_mainlining
BRANCH_WORKQUEUE = mstar_v5_16_rebase

NCPUS := $(shell nproc)

.PHONY:
	checkpatch_mainlinequeue \
	checkpatch_workqueue \
	dt-schema \
	linux_update \
	linux_workqueue \
	linux_mainlinequeue \
	u-boot_update

all: checkpatch

outputs:
	mkdir $@

dt-schema:
	pip3 install git+https://github.com/devicetree-org/dt-schema.git@master

linux:
	git clone $(CHENXING_REPO)
	git -C linux remote add torvalds https://github.com/torvalds/linux.git
	git -C linux fetch --all

linux_update: linux
	# just in case there is a source tree but it points at the wrong remote.
	git -C linux remote set-url origin $(CHENXING_REPO)
	git -C linux fetch --all

linux_mainlinequeue: linux_update
	git -C linux reset --hard origin/$(BRANCH_MAINLINEQUEUE)

linux_workqueue: linux_update
	git -C linux reset --hard origin/$(BRANCH_WORKQUEUE)

checkbindings_mainlinequeue: linux_mainlinequeue dt-schema
	$(MAKE) -C linux/ $(LINUX_ARGS) defconfig
	PATH=~/.local/bin/:$(PATH) $(MAKE) -C linux $(LINUX_ARGS) clean
	PATH=~/.local/bin/:$(PATH) $(MAKE) -C linux $(LINUX_ARGS) -j$(NCPUS) dt_binding_check

checkdtbs_mainlinequeue: linux_mainlinequeue dt-schema
	$(MAKE) -C linux/ $(LINUX_ARGS) allnoconfig
	cd linux && ./scripts/config --enable CONFIG_MMU
	cd linux && ./scripts/config --enable ARCH_MSTARV7
	$(MAKE) -C linux/ $(LINUX_ARGS) olddefconfig
	PATH=~/.local/bin/:$(PATH) $(MAKE) -C linux $(LINUX_ARGS) clean
	PATH=~/.local/bin/:$(PATH) $(MAKE) -C linux $(LINUX_ARGS) -j$(NCPUS) dtbs_check

checkpatch_mainlinequeue: linux_update
	cd linux && ./scripts/checkpatch.pl -g torvalds/master..origin/$(BRANCH_MAINLINEQUEUE)

# build the kernel without our junk
plainbuild_mainlinequeue: linux_mainlinequeue outputs
	$(MAKE) -C linux/ $(LINUX_ARGS) defconfig
	$(MAKE) -C linux/ $(LINUX_ARGS) -j$(NCPUS) W=1 | tee outputs/buildlog_mainlinequeue_plain.txt

# build the kernel with our junk
mstarbuild_mainlinequeue: linux_mainlinequeue outputs
	$(MAKE) -C linux/ $(LINUX_ARGS) defconfig
	cd linux && ./scripts/config --enable ARCH_MSTARV7
	$(MAKE) -C linux/ $(LINUX_ARGS) olddefconfig
	$(MAKE) -C linux/ $(LINUX_ARGS) clean
	$(MAKE) -C linux/ $(LINUX_ARGS) -j$(NCPUS) W=1 | tee outputs/buildlog_mainlinequeue_mstar.txt

# build the kernel with our junk
mstarbuild_workqueue: linux_workqueue outputs
	$(MAKE) -C linux/ $(LINUX_ARGS) defconfig
	cd linux && ./scripts/config --disable ARCH_ACTIONS
	cd linux && ./scripts/config --disable ARCH_ALPINE
	cd linux && ./scripts/config --disable ARCH_WM8850
	cd linux && ./scripts/config --disable ARCH_VEXPRESS
	cd linux && ./scripts/config --disable ARCH_VIRT
	cd linux && ./scripts/config --disable ARCH_ZYNQ
	cd linux && ./scripts/config --disable ARCH_ARTPEC
	cd linux && ./scripts/config --disable ARCH_ASPEED
	cd linux && ./scripts/config --disable ARCH_AT91
	cd linux && ./scripts/config --disable ARCH_BCM
	cd linux && ./scripts/config --disable ARCH_BERLIN
	cd linux && ./scripts/config --disable ARCH_DIGICOLOR
	cd linux && ./scripts/config --disable ARCH_EXYNOS
	cd linux && ./scripts/config --disable ARCH_HIGHBANK
	cd linux && ./scripts/config --disable ARCH_HISI
	cd linux && ./scripts/config --disable ARCH_MXC
	cd linux && ./scripts/config --disable ARCH_KEYSTONE
	cd linux && ./scripts/config --disable ARCH_MEDIATEK
	cd linux && ./scripts/config --disable ARCH_MESON
	cd linux && ./scripts/config --disable ARCH_MILBEAUT
	cd linux && ./scripts/config --disable ARCH_MMP
	cd linux && ./scripts/config --disable ARCH_MVEBU
	cd linux && ./scripts/config --disable ARCH_TEGRA
	cd linux && ./scripts/config --disable ARCH_QCOM
	cd linux && ./scripts/config --disable ARCH_OMAP3
	cd linux && ./scripts/config --disable ARCH_OMAP4
	cd linux && ./scripts/config --disable SOC_AM33XX
	cd linux && ./scripts/config --disable SOC_AM43XX
	cd linux && ./scripts/config --disable SOC_DRA7XX
	cd linux && ./scripts/config --disable SOC_OMAP5
	cd linux && ./scripts/config --disable ARCH_ROCKCHIP
	cd linux && ./scripts/config --disable ARCH_RENESAS
	cd linux && ./scripts/config --disable ARCH_INTEL_SOCFPGA
	cd linux && ./scripts/config --disable PLAT_SPEAR
	cd linux && ./scripts/config --disable ARCH_STI
	cd linux && ./scripts/config --disable ARCH_STM32
	cd linux && ./scripts/config --disable ARCH_SUNXI
	cd linux && ./scripts/config --disable ARCH_UNIPHIER
	cd linux && ./scripts/config --disable ARCH_U8500
	cd linux && ./scripts/config --enable ARCH_MSTARV7
	#
	cd linux && ./scripts/config --disable HIGHMEM
	cd linux && ./scripts/config --disable EFI
	# unneeded network
	cd linux && ./scripts/config --disable B53

	$(MAKE) -C linux/ $(LINUX_ARGS) olddefconfig
	$(MAKE) -C linux/ $(LINUX_ARGS) clean
	$(MAKE) -C linux/ $(LINUX_ARGS) -j$(NCPUS) W=1 | tee outputs/buildlog_mainlinequeue_mstar.txt

checkpatch_workqueue: linux_update
	cd linux && ./scripts/checkpatch.pl -g torvalds/master..origin/$(BRANCH_WORKQUEUE)

outputs/kernel_ssd20xd.itb: kernel_ssd20xd.its mstarbuild_workqueue
	mkdir -p outputs
	mkimage -f $< $@

UBOOT_BRANCH=mstar_rebase_mainline_20211217

u-boot:
	git clone $(CHENXING_UBOOT_REPO)
	git -C $@ fetch --all

u-boot-update: u-boot
	git -C $< fetch --all
	git -C $< reset --hard origin/$(UBOOT_BRANCH)

define u-boot-build-defconfig
	make -C u-boot $1_defconfig
	make -C u-boot CROSS_COMPILE=arm-linux-gnueabihf-
	tar czf $@ u-boot/ipl u-boot/u-boot.img
endef

outputs/u-boot-breadbee.tar.gz: u-boot-update
	$(call u-boot-build-defconfig,msc313_breadbee)

outputs/u-boot-dongshanpione.tar.gz: u-boot-update
	$(call u-boot-build-defconfig,mstar_infinity2m_dongshanpione)

outputs/u-boot-unitv2.tar.gz: u-boot-update
	$(call u-boot-build-defconfig,mstar_infinity2m_unitv2)

outputs/u-boot-som2d01.tar.gz: u-boot-update
	$(call u-boot-build-defconfig,mstar_infinity2m_som2d01)
