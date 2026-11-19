# OpenWrt ARM64 软件包

推送 `src/`、`openwrt/` 或工作流的改动到 `main` 或 `master` 后，GitHub Actions 会用官方 OpenWrt SDK 交叉编译当前提交。默认目标与路由器固件匹配：

| `DISTRIB_RELEASE` | `DISTRIB_TARGET` | `DISTRIB_ARCH` | 格式 |
| --- | --- | --- | --- |
| `25.12.5` | `mediatek/filogic` | `aarch64_cortex-a53` | `.apk` |

## 确认路由器目标

在路由器 SSH 中运行：

```sh
cat /etc/openwrt_release
```

`ARMv8 Processor rev 4` 不等于软件包架构。以 `DISTRIB_RELEASE`、`DISTRIB_TARGET` 和 `DISTRIB_ARCH` 为准。若默认构建没有匹配项，在 **Actions → Build OpenWrt ARM64 Packages → Run workflow** 中填入实际的 `release` 和 `target`。手动构建使用 OpenWrt 官方 24.10 或 25.12 发布版的 64 位 musl SDK，不支持 Snapshot；ImmortalWrt 等衍生固件需要其匹配的 SDK，不能假设通用。

## 下载和安装

在成功的 Actions 运行中下载 **Artifacts**。默认产物名为 `softethervpn-openwrt-25.12.5-mediatek-filogic-aarch64_cortex-a53`。解压后，将所需文件传到路由器的 `/tmp`。每个产物含 `base`（`vpncmd` 和公共资源）、`server`、`client`、`bridge` 四个包与校验文件。安装任一组件时同时提供 `base`；不必安装其他组件。不要混用不同目标或不同构建批次的文件，也不要与占用相同文件的 `softethervpn5-*` 一起安装。

以服务端为例，在只放了匹配版本软件包的 `/tmp` 中执行对应命令：

```sh
# OpenWrt 24.10 (.ipk)
opkg update
opkg install /tmp/softethervpn-base_*.ipk /tmp/softethervpn-server_*.ipk

# OpenWrt 25.12 (.apk)；只对已确认来源的本仓库构建产物允许未签名安装
apk update
apk add --allow-untrusted /tmp/softethervpn-base-*.apk /tmp/softethervpn-server-*.apk
```

依赖（包括 `kmod-tun`）由路由器自己的固件软件源提供，不随产物附带。安装后可用 `/etc/init.d/softethervpnserver enable` 设置开机启动，用 `/etc/init.d/softethervpnserver start` 启动服务，并用 `vpncmd` 配置。将服务器暴露到外网前，请先设置管理密码。
