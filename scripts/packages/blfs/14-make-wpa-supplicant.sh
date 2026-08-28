#!/bin/bash
set -e
echo "Building BLFS-wpa_supplicant.."
echo "Approximate build time: 0.3 SBU"
echo "Required disk space: 45 MB"

# 14. wpa_supplicant
# wpa_supplicant does the authentication and key negotiation of a protected
# wireless network. The kernel driver and iw can see a network and associate
# with an open one, but anything with WPA needs this daemon running for the
# link to come up at all.
# https://www.linuxfromscratch.org/blfs/view/11.2/basicnet/wpa_supplicant.html

tar -xf /sources/wpa_supplicant-*.tar.gz -C /tmp/ \
    && mv /tmp/wpa_supplicant-* /tmp/wpa_supplicant \
    && pushd /tmp/wpa_supplicant/wpa_supplicant \
    && cat > .config << "ENDCONFIG"
CONFIG_BACKEND=file
CONFIG_CTRL_IFACE=y
CONFIG_DEBUG_FILE=y
CONFIG_DEBUG_SYSLOG=y
CONFIG_DEBUG_SYSLOG_FACILITY=LOG_DAEMON
CONFIG_DRIVER_NL80211=y
CONFIG_DRIVER_WEXT=y
CONFIG_DRIVER_WIRED=y
CONFIG_EAP_GTC=y
CONFIG_EAP_LEAP=y
CONFIG_EAP_MD5=y
CONFIG_EAP_MSCHAPV2=y
CONFIG_EAP_OTP=y
CONFIG_EAP_PEAP=y
CONFIG_EAP_TLS=y
CONFIG_EAP_TTLS=y
CONFIG_IEEE8021X_EAPOL=y
CONFIG_IPV6=y
CONFIG_LIBNL32=y
CONFIG_PEERKEY=y
CONFIG_PKCS12=y
CONFIG_READLINE=y
CONFIG_SMARTCARD=y
CONFIG_TLS=openssl
CONFIG_TLSV11=y
CONFIG_TLSV12=y
CONFIG_WPS=y
CFLAGS += -I/usr/include/libnl3
ENDCONFIG
    make BINDIR=/usr/sbin LIBDIR=/usr/lib \
    && install -v -m755 wpa_cli wpa_passphrase wpa_supplicant /usr/sbin/ \
    && install -v -m644 doc/docbook/wpa_supplicant.conf.5 /usr/share/man/man5/ \
    && install -v -m644 doc/docbook/wpa_cli.8 doc/docbook/wpa_passphrase.8 \
                        doc/docbook/wpa_supplicant.8 /usr/share/man/man8/ \
    && popd \
    && rm -rf /tmp/wpa_supplicant
