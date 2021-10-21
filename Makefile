LINUX_ARGS = ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-

CHENXING_REPO = https://github.com/linux-chenxing/linux.git

BRANCH_MAINLINEQUEUE = msc313_mainlining
BRANCH_WORKQUEUE = mstar_v5_14_rebase

NCPUS := $(shell nproc)

.PHONY:
	checkpatch_mainlinequeue \
	checkpatch_workqueue \
	dt-schema \
	linux_update

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

checkbindings_mainlinequeue: linux_mainlinequeue dt-schema
	PATH=~/.local/bin/:$(PATH) $(MAKE) -C linux $(LINUX_ARGS) clean
	PATH=~/.local/bin/:$(PATH) $(MAKE) -C linux $(LINUX_ARGS) dt_binding_check $(NCPUS)

checkdtbs_mainlinequeue: linux_mainlinequeue dt-schema
	$(MAKE) -C linux/ $(LINUX_ARGS) allnoconfig
	cd linux && ./scripts/config --enable CONFIG_MMU
	cd linux && ./scripts/config --enable ARCH_MSTARV7
	$(MAKE) -C linux/ $(LINUX_ARGS) olddefconfig
	PATH=~/.local/bin/:$(PATH) $(MAKE) -C linux $(LINUX_ARGS) clean
	PATH=~/.local/bin/:$(PATH) $(MAKE) -C linux $(LINUX_ARGS) dtbs_check $(NCPUS)

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

checkpatch_workqueue: linux_update
	cd linux && ./scripts/checkpatch.pl -g torvalds/master..origin/$(BRANCH_WORKQUEUE)
