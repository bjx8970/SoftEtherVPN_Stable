include $(TOPDIR)/rules.mk

PKG_NAME:=softethervpn
PKG_VERSION:=4.44.9807
PKG_RELEASE:=1
PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILES:=src/LICENSE.TXT
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

TARGET_CFLAGS += -Wno-error=incompatible-pointer-types

HAMCORE:=src/bin/BuiltHamcoreFiles/unix/hamcore.se2
UPSTREAM_MAKEFILE:=src/makefiles/linux_64bit_nobits.mak
SOFTETHER_LIBEXEC:=/usr/libexec/softethervpn

MAKE_FLAGS += -f $(UPSTREAM_MAKEFILE) -o $(HAMCORE) \
	CC="$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_CPPFLAGS) $(TARGET_LDFLAGS)"

define Build/Prepare
	test -n "$(SOFTETHER_SOURCE_DIR)" && test -s "$(SOFTETHER_SOURCE_DIR)/$(HAMCORE)"
	$(INSTALL_DIR) $(PKG_BUILD_DIR)
	$(CP) "$(SOFTETHER_SOURCE_DIR)/src" $(PKG_BUILD_DIR)/
	sed -i -e 's|^\tar |\t$(TARGET_AR) |' -e 's|^\tranlib |\t$(TARGET_RANLIB) |' \
		$(PKG_BUILD_DIR)/$(UPSTREAM_MAKEFILE)
	sed -i '/^VLAN \*NewTap(/a void FreeTap(VLAN *v);' $(PKG_BUILD_DIR)/src/Cedar/VLanUnix.h
	sed -i 's/c = getch();/c = getc(stdin);/' $(PKG_BUILD_DIR)/src/Cedar/Console.c
endef

define Build/Configure
endef

define Build/Compile
	$(INSTALL_DIR) $(addprefix $(PKG_BUILD_DIR)/,tmp/objs/Mayaqua tmp/objs/Cedar tmp/as \
		bin/vpnserver bin/vpnbridge bin/vpnclient bin/vpncmd)
	$(call Build/Compile/Default,build)
endef

define Package/softethervpn/Default
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=VPN
	URL:=https://www.softether.org/
	DEPENDS:=@aarch64 +softethervpn-base
endef

define Package/softethervpn-base
	$(call Package/softethervpn/Default)
	TITLE:=SoftEther VPN command-line utility and shared resources
	DEPENDS:=@aarch64 +libpthread +librt +libopenssl +libreadline +libncurses +zlib +kmod-tun
endef

define Package/softethervpn-server
	$(call Package/softethervpn/Default)
	TITLE:=SoftEther VPN server
endef

define Package/softethervpn-client
	$(call Package/softethervpn/Default)
	TITLE:=SoftEther VPN client
endef

define Package/softethervpn-bridge
	$(call Package/softethervpn/Default)
	TITLE:=SoftEther VPN bridge
endef

define Package/softethervpn-base/install
	$(INSTALL_DIR) $(1)$(SOFTETHER_LIBEXEC) $(1)/usr/bin
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/$(HAMCORE) $(1)$(SOFTETHER_LIBEXEC)/hamcore.se2
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/vpncmd/vpncmd $(1)$(SOFTETHER_LIBEXEC)/vpncmd
	$(INSTALL_BIN) ./files/launcher $(1)$(SOFTETHER_LIBEXEC)/launcher
	$(LN) ../libexec/softethervpn/launcher $(1)/usr/bin/vpncmd
endef

define InstallService
	$(INSTALL_DIR) $(1)$(SOFTETHER_LIBEXEC) $(1)/usr/bin $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/vpn$(2)/vpn$(2) $(1)$(SOFTETHER_LIBEXEC)/vpn$(2)
	$(LN) ../libexec/softethervpn/launcher $(1)/usr/bin/vpn$(2)
	$(INSTALL_DATA) /dev/null $(1)$(SOFTETHER_LIBEXEC)/vpn_$(2).config
	sed 's/@PROGRAM@/vpn$(2)/g' ./files/service.init > $(1)/etc/init.d/softethervpn$(2)
	chmod 0755 $(1)/etc/init.d/softethervpn$(2)
endef

define Package/softethervpn-server/install
	$(call InstallService,$(1),server)
endef

define Package/softethervpn-client/install
	$(call InstallService,$(1),client)
endef

define Package/softethervpn-bridge/install
	$(call InstallService,$(1),bridge)
endef

define Package/softethervpn-server/conffiles
$(SOFTETHER_LIBEXEC)/vpn_server.config
endef

define Package/softethervpn-client/conffiles
$(SOFTETHER_LIBEXEC)/vpn_client.config
endef

define Package/softethervpn-bridge/conffiles
$(SOFTETHER_LIBEXEC)/vpn_bridge.config
endef

$(eval $(call BuildPackage,softethervpn-base))
$(eval $(call BuildPackage,softethervpn-server))
$(eval $(call BuildPackage,softethervpn-client))
$(eval $(call BuildPackage,softethervpn-bridge))
