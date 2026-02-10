#!/bin/bash

PKG_PATH="$GITHUB_WORKSPACE/wrt/package/"

set -e

echo "=========================================="
echo "Rust 修复方案：替换为 ImmortalWrt 23.05 稳定版"
echo "=========================================="

# 1. 移除当前可能有问题的 Rust 定义
rm -rf feeds/packages/lang/rust

# 2. 从 ImmortalWrt 23.05 分支拉取稳定的 Rust
# 这个分支的 Rust 版本（如 1.85.0）对应的 CI 预编译包通常是长期有效的
echo ">>> Cloning Rust from ImmortalWrt 23.05 branch..."
git clone --depth 1 -b openwrt-23.05 https://github.com/immortalwrt/packages.git temp_packages

# 3. 替换
cp -r temp_packages/lang/rust feeds/packages/lang/

# 4. 清理
rm -rf temp_packages

echo ">>> Rust replaced with stable version from 23.05 branch."

# 5. 确保 download-ci-llvm 是开启的 (默认就是开启的，这里只是保险)
# 我们希望下载预编译包，而不是本地编译
RUST_MK="feeds/packages/lang/rust/Makefile"
if grep -q "download-ci-llvm" "$RUST_MK"; then
    sed -i 's/download-ci-llvm=false/download-ci-llvm=true/g' "$RUST_MK"
    echo ">>> Verified: download-ci-llvm is ENABLED."
else
    echo ">>> Note: download-ci-llvm option not found, assuming default behavior."
fi

echo "=========================================="
echo "修复完成。请继续编译。"
echo "=========================================="

#预置HomeProxy数据
if [ -d *"homeproxy"* ]; then
	echo " "

	HP_RULE="surge"
	HP_PATH="homeproxy/root/etc/homeproxy"

	rm -rf ./$HP_PATH/resources/*

	git clone -q --depth=1 --single-branch --branch "release" "https://github.com/Loyalsoldier/surge-rules.git" ./$HP_RULE/
	cd ./$HP_RULE/ && RES_VER=$(git log -1 --pretty=format:'%s' | grep -o "[0-9]*")

	echo $RES_VER | tee china_ip4.ver china_ip6.ver china_list.ver gfw_list.ver
	awk -F, '/^IP-CIDR,/{print $2 > "china_ip4.txt"} /^IP-CIDR6,/{print $2 > "china_ip6.txt"}' cncidr.txt
	sed 's/^\.//g' direct.txt > china_list.txt ; sed 's/^\.//g' gfw.txt > gfw_list.txt
	mv -f ./{china_*,gfw_list}.{ver,txt} ../$HP_PATH/resources/

	cd .. && rm -rf ./$HP_RULE/

	cd $PKG_PATH && echo "homeproxy date has been updated!"
fi

#修改argon主题字体和颜色
if [ -d *"luci-theme-argon"* ]; then
	echo " "

	cd ./luci-theme-argon/

	sed -i "s/primary '.*'/primary '#5e72e4'/; s/'0.2'/'0.5'/; s/'none'/'bing'/; s/'600'/'normal'/" ./luci-app-argon-config/root/etc/config/argon

	cd $PKG_PATH && echo "theme-argon has been fixed!"
fi

#修改qca-nss-drv启动顺序
NSS_DRV="../feeds/nss_packages/qca-nss-drv/files/qca-nss-drv.init"
if [ -f "$NSS_DRV" ]; then
	echo " "

	sed -i 's/START=.*/START=85/g' $NSS_DRV

	cd $PKG_PATH && echo "qca-nss-drv has been fixed!"
fi

#修改qca-nss-pbuf启动顺序
NSS_PBUF="./kernel/mac80211/files/qca-nss-pbuf.init"
if [ -f "$NSS_PBUF" ]; then
	echo " "

	sed -i 's/START=.*/START=86/g' $NSS_PBUF

	cd $PKG_PATH && echo "qca-nss-pbuf has been fixed!"
fi

#修复TailScale配置文件冲突
TS_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
if [ -f "$TS_FILE" ]; then
	echo " "

	sed -i '/\/files/d' $TS_FILE

	cd $PKG_PATH && echo "tailscale has been fixed!"
fi

#修复DiskMan编译失败
DM_FILE="./luci-app-diskman/applications/luci-app-diskman/Makefile"
if [ -f "$DM_FILE" ]; then
	echo " "

	sed -i '/ntfs-3g-utils /d' $DM_FILE

	cd $PKG_PATH && echo "diskman has been fixed!"
fi

#修复luci-app-netspeedtest相关问题
if [ -d *"luci-app-netspeedtest"* ]; then
	echo " "

	cd ./luci-app-netspeedtest/

	sed -i '$a\exit 0' ./netspeedtest/files/99_netspeedtest.defaults
	sed -i 's/ca-certificates/ca-bundle/g' ./speedtest-cli/Makefile

	cd $PKG_PATH && echo "netspeedtest has been fixed!"
fi
