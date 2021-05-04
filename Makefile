LINUX_ARGS = ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-

BRANCH_MAINLINEQUEUE = msc313_mainlining

.PHONY:
	checkpatch \
	dt-schema \
	linux_update

all: checkpatch

outputs:
	mkdir $@

dt-schema:
	pip3 install git+https://github.com/devicetree-org/dt-schema.git@master

linux:
	git clone https://github.com/fifteenhex/linux.git
	git -C linux remote add torvalds https://github.com/torvalds/linux.git
	git -C linux fetch --all

linux_update: linux
	git -C linux fetch --all

linux_mainlinequeue: linux_update
	git -C linux reset --hard origin/$(BRANCH_MAINLINEQUEUE)

checkbindings_mainlinequeue: linux_mainlinequeue dt-schema
	PATH=~/.local/bin/:$(PATH) $(MAKE) -C linux $(LINUX_ARGS) clean
	PATH=~/.local/bin/:$(PATH) $(MAKE) -C linux $(LINUX_ARGS) dt_binding_check

checkdtbs_mainlinequeue: linux_mainlinequeue dt-schema
	$(MAKE) -C linux/ $(LINUX_ARGS) allnoconfig
	cd linux && ./scripts/config --enable CONFIG_MMU
	cd linux && ./scripts/config --enable ARCH_MSTARV7
	$(MAKE) -C linux/ $(LINUX_ARGS) olddefconfig
	PATH=~/.local/bin/:$(PATH) $(MAKE) -C linux $(LINUX_ARGS) clean
	PATH=~/.local/bin/:$(PATH) $(MAKE) -C linux $(LINUX_ARGS) dtbs_check

checkpatch_mainlinequeue: linux_update
	cd linux && ./scripts/checkpatch.pl -g torvalds/master..origin/$(BRANCH_MAINLINEQUEUE)

# build the kernel without our junk
plainbuild_mainlinequeue: linux_mainlinequeue outputs
	$(MAKE) -C linux/ $(LINUX_ARGS) defconfig
	$(MAKE) -C linux/ $(LINUX_ARGS) W=1 | tee outputs/buildlog_mainlinequeue_plain.txt

# build the kernel with our junk
mstarbuild_mainlinequeue: linux_mainlinequeue outputs
	$(MAKE) -C linux/ $(LINUX_ARGS) defconfig
	cd linux && ./scripts/config --enable ARCH_MSTARV7
	$(MAKE) -C linux/ $(LINUX_ARGS) olddefconfig
	$(MAKE) -C linux/ $(LINUX_ARGS) clean
	$(MAKE) -C linux/ $(LINUX_ARGS) W=1| tee outputs/buildlog_mainlinequeue_mstar.txt
