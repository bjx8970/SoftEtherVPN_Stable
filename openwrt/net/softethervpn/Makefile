include $(TOPDIR)/rules.mk

PKG_NAME:=softethervpn
PKG_VERSION:=4.44
PKG_RELEASE:=1

# The workflow creates this archive from the exact GitHub checkout before invoking the SDK.
PKG_SOURCE:=softethervpn-source.tar.gz
PKG_SOURCE_URL:=file:///feed/net/softethervpn
# Replaced with the generated archive hash by the GitHub Actions workflow.
PKG_HASH:=0000000000000000000000000000000000000000000000000000000000000000

PKG_MAINTAINER:=SoftEtherVPN_Stable maintainers
PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILES:=LICENSE.TXT
PKG_BUILD_DEPENDS:=softethervpn/host
PKG_ASLR_PIE:=0

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
HOST_BUILD_DIR:=$(BUILD_DIR_HOST)/$(PKG_NAME)-$(PKG_VERSION)
HAMCORE_SE2:=$(STAGING_DIR_HOST)/share/softethervpn/hamcore.se2

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/host-build.mk

HOST_BUILD_DEPENDS:=readline/host ncurses/host

# The source tree contains the hamcore builder, but not its generated archive.
# Build that archive once with the host compiler and reuse it for the target.
HOST_MAKE_FLAGS += -C $(HOST_BUILD_DIR)
HOST_MAKE_FLAGS += -f src/makefiles/linux_$(if $(shell uname -m | grep 64),64,32)bit.mak

define Host/Configure
endef

define Host/Compile
	CC="$(HOSTCC) $(HOST_CFLAGS) $(HOST_CPPFLAGS) $(HOST_LDFLAGS)" \
		$(MAKE) $(HOST_MAKE_FLAGS) src/bin/BuiltHamcoreFiles/unix/hamcore.se2
endef

define Host/Install
	$(INSTALL_DIR) $(STAGING_DIR_HOST)/share/softethervpn
	$(INSTALL_DATA) $(HOST_BUILD_DIR)/src/bin/BuiltHamcoreFiles/unix/hamcore.se2 \
		$(HAMCORE_SE2)
endef

# The upstream makefiles call the compiler through CC and do not consume the
# normal OpenWrt CFLAGS variables, so pass the complete target toolchain
# command through CC as done by the existing OpenWrt SoftEther package.
MAKE_FLAGS += \
	-f src/makefiles/linux_$(if $(CONFIG_ARCH_64BIT),64,32)bit_nobits.mak \
	CC="$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_CPPFLAGS) $(TARGET_LDFLAGS)"

define Build/Configure
	$(INSTALL_DIR) $(PKG_BUILD_DIR)/src/bin/BuiltHamcoreFiles/unix
	$(CP) $(HAMCORE_SE2) $(PKG_BUILD_DIR)/src/bin/BuiltHamcoreFiles/unix/hamcore.se2
	perl -e 'utime(time() + 86400, time() + 86400, $$$$ARGV[0])' \
		$(PKG_BUILD_DIR)/src/bin/BuiltHamcoreFiles/unix/hamcore.se2
endef

define Build/Compile
	$(call Build/Compile/Default,build)
endef

define Package/softethervpn/Default
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=VPN
	TITLE:=SoftEther VPN
	URL:=https://www.softether.org/
	DEPENDS:=+libpthread +librt +libreadline +libopenssl +libncurses +kmod-tun +zlib
endef

define Package/softethervpn-base
	$(call Package/softethervpn/Default)
	TITLE+= (base tools)
	HIDDEN:=1
endef

define Package/softethervpn-server
	$(call Package/softethervpn/Default)
	TITLE+= (server)
	DEPENDS:=+softethervpn-base
endef

define Package/softethervpn-bridge
	$(call Package/softethervpn/Default)
	TITLE+= (bridge)
	DEPENDS:=+softethervpn-base
endef

define Package/softethervpn-client
	$(call Package/softethervpn/Default)
	TITLE+= (client)
	DEPENDS:=+softethervpn-base
endef

define Package/softethervpn/description
SoftEther VPN is a multi-protocol VPN server, bridge, client and command-line
utility supporting SSL-VPN, OpenVPN, L2TP, IPsec and other protocols.
endef

Package/softethervpn-base/description = $(Package/softethervpn/description)
Package/softethervpn-server/description = $(Package/softethervpn/description)
Package/softethervpn-bridge/description = $(Package/softethervpn/description)
Package/softethervpn-client/description = $(Package/softethervpn/description)

define Package/softethervpn-base/conffiles
/usr/libexec/softethervpn/lang.config
endef

define Package/softethervpn-server/conffiles
/usr/libexec/softethervpn/vpn_server.config
endef

define Package/softethervpn-bridge/conffiles
/usr/libexec/softethervpn/vpn_bridge.config
endef

define Package/softethervpn-client/conffiles
/usr/libexec/softethervpn/vpn_client.config
endef

define Package/softethervpn-base/install
	$(INSTALL_DIR) $(1)/usr/libexec/softethervpn $(1)/usr/bin
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/bin/vpnserver/hamcore.se2 \
		$(1)/usr/libexec/softethervpn/hamcore.se2
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/vpncmd/vpncmd \
		$(1)/usr/libexec/softethervpn/vpncmd
	$(INSTALL_BIN) ./files/vpncmd \
		$(1)/usr/bin/vpncmd
	$(INSTALL_DATA) ./files/empty.config \
		$(1)/usr/libexec/softethervpn/lang.config
endef

define Package/softethervpn-server/install
	$(INSTALL_DIR) $(1)/usr/libexec/softethervpn $(1)/usr/bin $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/vpnserver/vpnserver \
		$(1)/usr/libexec/softethervpn/vpnserver
	$(INSTALL_BIN) ./files/vpnserver \
		$(1)/usr/bin/vpnserver
	$(INSTALL_DATA) ./files/empty.config \
		$(1)/usr/libexec/softethervpn/vpn_server.config
	$(INSTALL_BIN) ./files/vpnserver.init \
		$(1)/etc/init.d/softethervpnserver
endef

define Package/softethervpn-bridge/install
	$(INSTALL_DIR) $(1)/usr/libexec/softethervpn $(1)/usr/bin $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/vpnbridge/vpnbridge \
		$(1)/usr/libexec/softethervpn/vpnbridge
	$(INSTALL_BIN) ./files/vpnbridge \
		$(1)/usr/bin/vpnbridge
	$(INSTALL_DATA) ./files/empty.config \
		$(1)/usr/libexec/softethervpn/vpn_bridge.config
	$(INSTALL_BIN) ./files/vpnbridge.init \
		$(1)/etc/init.d/softethervpnbridge
endef

define Package/softethervpn-client/install
	$(INSTALL_DIR) $(1)/usr/libexec/softethervpn $(1)/usr/bin $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/vpnclient/vpnclient \
		$(1)/usr/libexec/softethervpn/vpnclient
	$(INSTALL_BIN) ./files/vpnclient \
		$(1)/usr/bin/vpnclient
	$(INSTALL_DATA) ./files/empty.config \
		$(1)/usr/libexec/softethervpn/vpn_client.config
	$(INSTALL_BIN) ./files/vpnclient.init \
		$(1)/etc/init.d/softethervpnclient
endef

$(eval $(call BuildPackage,softethervpn-base))
$(eval $(call BuildPackage,softethervpn-server))
$(eval $(call BuildPackage,softethervpn-bridge))
$(eval $(call BuildPackage,softethervpn-client))
$(eval $(call HostBuild))
