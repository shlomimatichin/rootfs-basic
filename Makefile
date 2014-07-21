ROOTFS = build/root
BUILT_PYTHON_PACKAGES = build/pyprebuilt

all: $(ROOTFS)

submit: $(ROOTFS)
	sudo -E solvent submitproduct rootfs $<

approve: $(ROOTFS)
	sudo -E solvent approve --product=rootfs

clean:
	sudo rm -fr build

$(ROOTFS): $(BUILT_PYTHON_PACKAGES)
	echo "Cleaning"
	-sudo rm -fr $(ROOTFS) $(ROOTFS).tmp
	echo "Bringing source"
	-mkdir $(@D)
	sudo -E solvent bring --repositoryBasename=rootfs-vanilla --product=rootfs --destination=$(ROOTFS).tmp
	echo "Installing basic package list"
	sudo chroot $(ROOTFS).tmp yum install $(RPMS_TO_INSTALL) --assumeyes
	echo "Copying prebuilt python packages"
	sudo cp -a $(BUILT_PYTHON_PACKAGES)/usr $(ROOTFS).tmp/
	echo "Verifying prebuilt python packages work"
	sudo ./chroot.sh $(ROOTFS).tmp python -c "import zmq"
	sudo mv $(ROOTFS).tmp $(ROOTFS)

$(BUILT_PYTHON_PACKAGES):
	echo "Cleaning (build python packages)"
	-sudo rm -fr $(BUILT_PYTHON_PACKAGES) $(BUILT_PYTHON_PACKAGES).tmp
	echo "Bringing source (build python packages)"
	-mkdir $(@D)
	sudo -E solvent bring --repositoryBasename=rootfs-vanilla --product=rootfs --destination=$(BUILT_PYTHON_PACKAGES).tmp
	echo "Installing build packages"
	sudo chroot $(BUILT_PYTHON_PACKAGES).tmp yum groupinstall "Development Tools" --assumeyes
	sudo chroot $(BUILT_PYTHON_PACKAGES).tmp yum install python-devel gcc-c++ --assumeyes
	sudo chroot $(BUILT_PYTHON_PACKAGES).tmp yum install python-pip python-devel --assumeyes
	sudo ./chroot.sh $(BUILT_PYTHON_PACKAGES).tmp pip install $(PYTHON_PACKAGES_TO_INSTALL)
	mkdir -p $(BUILT_PYTHON_PACKAGES)/usr/lib/python2.7
	mkdir -p $(BUILT_PYTHON_PACKAGES)/usr/lib64/python2.7
	sudo mv $(BUILT_PYTHON_PACKAGES).tmp/usr/lib/python2.7/site-packages $(BUILT_PYTHON_PACKAGES)/usr/lib/python2.7/
	sudo mv $(BUILT_PYTHON_PACKAGES).tmp/usr/lib64/python2.7/site-packages $(BUILT_PYTHON_PACKAGES)/usr/lib64/python2.7/
	sudo rm -fr $(BUILT_PYTHON_PACKAGES).tmp

#This list of packages: PRODUCTION & RELEASE. do not add debuggers, do not add compilers
#do not add packages customized by strato, as at this build stage we do not use distrato
RPMS_TO_INSTALL = \
    boost-iostreams \
    boost-program-options \
    boost-python \
    boost-system \
    boost-regex \
    boost-filesystem \
    ethtool \
    iperf \
    iproute \
    net-tools \
    patch \
    python-paramiko \
    python-pip \
    python-websockify \
    tar \
    tcpdump \
    xfsprogs \
    xmlrpc-c-c++ \
    redhat-lsb-core

#This list of python packages: basic packages, or packages that need binary compilation.
#this makefile compiles them without contaminating the main filesystem image with
#development tools. Do not add openstack.
PYTHON_PACKAGES_TO_INSTALL = \
	"pyzmq==14.3.1" \
	"simplejson==3.3.1" \
	"tornado==3.1.1" \
	"xmltodict==0.8.3" \
	"six==1.4.1" \
	"jinja2==2.7.1" \
	"pyyaml==3.10" \
	"psutil==1.2.1" \
	"anyjson==0.3.3" \
	"networkx==1.8.1" \
	"stevedore==0.14.1" \
	"taskflow==0.1.3" \
	"twisted==13.2.0" \
	"requests-toolbelt==0.2.0"
