include version

ifndef VERSION_BUILD
VERSION_BUILD=0
endif

# LINUX_DISTRO := $(strip $(shell lsb_release -i | cut -d':' -f2))
# OS_VERSION := $(strip $(shell lsb_release -r | cut -d':' -f2))
OS_PLATFORM := $(shell uname -m)

PKG_NAME=r1samba
PKG_VERSION=$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_MAINT)-$(VERSION_BUILD)
PKG_NAME_FULL=$(PKG_NAME)_$(PKG_VERSION).$(OS_PLATFORM)

#depends versions
NETTLE_VER=3.5
P11_VER=0.23.2
GNUTLS_VER=3.6.12

SMB_VER=4.11.6
SMB_TAR=https://download.samba.org/pub/samba/stable/samba-$(SMB_VER).tar.gz
SMB_PATH=samba-$(SMB_VER)
SMB_TARGET_PATH=$(PKG_NAME_FULL)/opt/r1soft/$(PKG_NAME)
SMB_DIRS=bin etc private var
SMB_VAR_DIRS=cache lib lock locks run
SMB_BINS=smbd smbcontrol smbpasswd

all: r1samba

.PHONY: r1samba release

release: r1samba
	@echo "Creating r1samba Debian package"
	rm -rf tmp
	mkdir -p tmp/$(PKG_NAME_FULL)/DEBIAN

# Create file deb package
	@for files in `ls deb`; do \
		temp_files=`basename $$files`; \
		cp deb/$$temp_files tmp/$(PKG_NAME_FULL)/DEBIAN; \
		chmod 755 tmp/$(PKG_NAME_FULL)/DEBIAN/$$temp_files; \
	done
	sed -i 's/__VERSION__/$(PKG_VERSION)/g' tmp/$(PKG_NAME_FULL)/DEBIAN/control

# Create install dirs
	@for subdir in $(SMB_DIRS); do \
		temp_dir=`basename $$subdir`; \
		mkdir -p tmp/$(SMB_TARGET_PATH)/$$temp_dir; \
	done
	chmod 700 tmp/$(SMB_TARGET_PATH)/private

# Create dirs in var
	@for subdir in $(SMB_VAR_DIRS); do \
		temp_dir=`basename $$subdir`; \
		mkdir -p tmp/$(SMB_TARGET_PATH)/var/$$temp_dir; \
	done

# Copy binaries
	@for files in $(SMB_BINS); do \
		temp_file=`basename $$files`; \
		cp -f $(SMB_PATH)/bin/$$temp_file tmp/$(SMB_TARGET_PATH)/bin; \
	done

# Copy the smb.conf
	cp -f $(SMB_PATH)/examples/smb.conf.default tmp/$(SMB_TARGET_PATH)/etc/smb.conf 

# Build the deb package
	mkdir -p target
	cd tmp && fakeroot dpkg-deb --build $(PKG_NAME_FULL)
	mv tmp/$(PKG_NAME_FULL).deb target/
	rm -rf tmp


depends:
	@echo Check for nettle installation
	@if [ "$(shell pkg-config --modversion nettle)" != "$(NETTLE_VER)" ]; then \
		echo "Nettle $(NETTLE_VER) not found"; \
		exit 1; \
	else \
		echo "Nettle $(NETTLE_VER) found"; \
	fi

	@echo Check for p11-kit installation
	@if [ "$(shell pkg-config --modversion p11-kit-1)" != "$(P11_VER)" ]; then \
		echo "p11-kit $(P11_VER) not found"; \
		exit 1; \
	else \
		echo "p11-kit $(P11_VER) found"; \
	fi

	@echo check for GnuTLS installation
	@if [ "$(shell pkg-config --modversion gnutls)" != "$(GNUTLS_VER)" ]; then \
		echo "GnuTLS $(GNUTLS_VER) not found"; \
		exit 1; \
	else \
		echo "GnuTLS $(GNUTLS_VER) found"; \
	fi

configure:
	@echo Configuring the samba for compilation
	@if [ ! -d $(SMB_PATH) ]; then \
		make depends; \
		wget -c $(SMB_TAR); \
		tar xvf samba-$(SMB_VER).tar.gz; \
		cd $(SMB_PATH) && \
		./configure --prefix=/opt/r1soft/samba --disable-python --without-ad-dc \
			    --without-json --disable-cups  --without-libarchive \
			    --without-acl-support  --without-ldap  --without-ads \
			    --without-pam --bundled-libraries=ALL --with-static-modules=ALL \
			    --nonshared-binary=smbd/smbd,smbcontrol,smbpasswd; \
	fi

r1samba: configure smbd smbcontrol smbpasswd

smbd:
	cd $(SMB_PATH) && make $@/$@

smbcontrol:
	cd $(SMB_PATH) && make $@

smbpasswd:
	cd $(SMB_PATH) && make $@

clean:
	rm -rf $(SMB_PATH)
	rm -rf samba-$(SMB_VER).tar.gz
	rm -rf target/r1samba*

