#!/bin/bash

OS_VERSION=`lsb_release -r | cut -d':' -f2 | sed -e 's/^[[:space:]]*//'`

#depends versions
NETTLE_VER=3.5
P11_VER=0.23.2
GNUTLS_VER=3.6.12

nettle()
{
	PKG_CHECK=`pkg-config --modversion nettle`
	if [ "${PKG_CHECK}" != "${NETTLE_VER}" ]
	then
		echo " *** Downloading and installing neetle ***"
		wget –c https://ftp.gnu.org/gnu/nettle/nettle-3.5.tar.gz
		tar xvf nettle-3.5.tar.gz
		cd nettle-3.5/
		./configure $@ && make && sudo make install && sudo ldconfig 
		if [ ! $? -eq 0 ]
		then
			echo "*** Compiling of neetle package Failed. ***"
			exit 1
		fi
		cd ..
	fi
}

p11kit()
{
	PKG_CHECK=`pkg-config --modversion p11-kit-1`
	if [ "${PKG_CHECK}" != "${P11_VER}" ]
	then
		echo " *** Downloading and installing p11-kit ***"
		wget –c https://github.com/p11-glue/p11-kit/archive/0.23.2.tar.gz 
		tar xvf 0.23.2.tar.gz
		cd p11-kit-0.23.2
		./autogen.sh &&  ./configure $@ && make && sudo make install && sudo ldconfig
		if [ ! $? -eq 0 ]
		then
			echo "*** Compiling of p11-kit package Failed. ***"
			exit 1
		fi
		cd ..
	fi
}

gnutls()
{
	PKG_CHECK=`pkg-config --modversion gnutls`
	if [ "${PKG_CHECK}" != "${GNUTLS_VER}" ]
	then
		echo " *** Downloading and installing gnutls-3.6.12"
		wget –c https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-3.6.12.tar.xz
		tar xvf gnutls-3.6.12.tar.xz
		cd gnutls-3.6.12
		./configure $@ && make && sudo make install && sudo ldconfig
		if [ ! $? -eq 0 ]
		then    
		      echo "*** Compiling of gnutls package Failed ***"
		fi
		cd ..
	fi
}

ubuntu1404()
{
	echo "Proceeeding for Update on Ubuntu 14.04 "
	apt install libhogweed2 unbound-anchor libgpgme11-dev python-dev libgmp3-dev \
		    libunistring-dev libffi-dev gettext libtasn1-bin libtasn1-3-dev –y
	if [ ! $? -eq 0 ]
	then 
		echo " ***Installation of Samba dependenices Failed. ***"
		exit 1
	fi

	# install nettle
	nettle --enable-mini-gmp

	# install the pk11-kit
	p11kit --with-included-libtasn1

	# install GnuTLS
	gnutls --with-included-libtasn1
}

ubuntu1804()
{
	echo " Proceeeding for Update on Ubuntu 18.04 "
	apt install libhogweed4 unbound-anchor libgpgme-dev python-dev python3-dev libgmp3-dev \
		    libunistring-dev libffi-dev gettext libtasn1-bin libtasn1-6-dev -y
	if [ ! $? -eq 0 ]
	then 
		echo " ***Installation of Samba dependenices Failed. ***"
		exit 1
	fi

	# install nettle
	nettle --enable-mini-gmp

	# install the pk11-kit
	p11kit

	# install GnuTLS
	gnutls
}

main()
{
	# Make sure only root can run our script
	if [[ $EUID -ne 0 ]]; then
	   echo "This script must be run as root" 1>&2
	   exit 1
	fi

	echo "***Starting to Update the Ubuntu***"
	apt update -y && sudo apt upgrade -y
	if [ ! $? -eq 0 ] 
	then
		echo "*** Upgrade of Ubuntu Failed. Please make sure you have sudo access. ***"
		exit 1
	fi

	echo "***Starting to Install the build environment dependencies*** "
	apt install automake autopoint libtool build-essential pkg-config git -y
	if [ ! $? -eq 0 ]
	then
		echo "*** Installation of dependencies Failed ***"
		exit 1
	fi

	case "${OS_VERSION}" in
		"14.04")
			ubuntu1404
			;;
		"18.04")
			ubuntu1804
			;;
		*)
			echo "Sorry, I don't understand"
			;;
	esac
}

main $@
