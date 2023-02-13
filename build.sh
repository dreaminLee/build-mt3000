#!/bin/bash

# if you don't need proxy, please comment out next 2 lines
export http_proxy="http://10.0.2.2:10811"
export https_proxy="http://10.0.2.2:10811"
# used in docker
# export http_proxy="http://host.docker.internal:10811"
# export https_proxy="http://host.docker.internal:10811"

glinet_builder_uri='https://github.com/gl-inet/gl-infra-builder.git'
glinet_feeds_uri='https://github.com/gl-inet/gl-feeds.git'

openwrt_openwrt_uri='https://git.openwrt.org/openwrt/openwrt.git'
openwrt_packages_uri='https://git.openwrt.org/feed/packages.git'
openwrt_luci_uri='https://git.openwrt.org/project/luci.git'
openwrt_routing_uri='https://git.openwrt.org/feed/routing.git'
openwrt_telephony_uri='https://git.openwrt.org/feed/telephony.git'

mtk_openwrt_feeds_uri='https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds.git'

base=$1
if [ -z $base ]
then
    echo "provide a path for build root!"
    exit 1
fi
cd $base

mkdir -p mt3000
cd mt3000
build_root=$(pwd)

mkdir -p glinet
mkdir -p openwrt
mkdir -p mtk

# download all sources
echo "----------------------Cloning sources----------------------"
cd glinet
git clone $glinet_builder_uri
git clone $glinet_feeds_uri
cd $build_root

cd openwrt
git clone $openwrt_openwrt_uri
git clone $openwrt_packages_uri
git clone $openwrt_luci_uri
git clone $openwrt_routing_uri
git clone $openwrt_telephony_uri
cd telephony
git checkout openwrt-21.02
git checkout master
cd $build_root

cd mtk
git clone $mtk_openwrt_feeds_uri
cd $build_root

# change config's repo to local
echo "----------------------Generating build system----------------------"
cd glinet/gl-infra-builder
gl_infra_builder_config='config-mt798x-7.6.6.1.yml'
gl_infra_builder_config_local="${gl_infra_builder_config%.*}-local.yml"
cp -f ./configs/$gl_infra_builder_config ./configs/$gl_infra_builder_config_local
sed -i "s|https://github.com/openwrt/openwrt.git|${build_root}/openwrt/openwrt|" ./configs/$gl_infra_builder_config_local
cd $build_root

# generate openwrt build system
cd glinet/gl-infra-builder
# if git user email or user name is not set, set it
git_user_email=$(git config --global user.email)
if [ -z "$git_user_email" ]
then
    git config --global user.email "build@build.com"
fi
git_user_name=$(git config --global user.name)
if [ -z "$git_user_name" ]
then
    git config --global user.name "build"
fi
python3 setup.py -c ./configs/$gl_infra_builder_config_local
ln -s $build_root/glinet/gl-infra-builder/mt7981 ~/openwrt && cd ~/openwrt

# change openwrt and mtk feeds to local
feeds_default='feeds.conf.default'
sed -i "s|${openwrt_packages_uri}|${build_root}/openwrt/packages|" $feeds_default
sed -i "s|${openwrt_luci_uri}|${build_root}/openwrt/luci|" $feeds_default
sed -i "s|${openwrt_routing_uri}|${build_root}/openwrt/routing|" $feeds_default
sed -i "s|${openwrt_telephony_uri}|${build_root}/openwrt/telephony|" $feeds_default
sed -i "s|${mtk_openwrt_feeds_uri}|${build_root}/mtk/mtk-openwrt-feeds|" $feeds_default
# change profile's url to local
target_profile='target_mt7981_gl-mt3000.yml'
target_profile_local="${target_profile%.*}-local.yml"
cp -f ./profiles/$target_profile ./profiles/$target_profile_local
sed -i "s|${glinet_feeds_uri}|${build_root}/glinet/gl-feeds|g" ./profiles/$target_profile_local
./scripts/gen_config.py ${target_profile_local%.*} glinet_nas

# TODO adding plugins

# start building firmware
echo "----------------------Building firmware----------------------"
# replace current golang feed-packages-openwrt-22.03's golang
rm -rf feeds/packages/lang/golang
cd $build_root/openwrt/packages
git checkout openwrt-22.03
cd ~/openwrt
cp -r $build_root/openwrt/packages/lang/golang feeds/packages/lang/golang
./scripts/feeds update -a && ./scripts/feeds install -a && make defconfig
cd ~/openwrt
# make -j$(expr $(nproc) + 1)  V=s
# TODO cache download
make download -j1 V=s
if [ $? -eq 0]
then
    echo "----------------------Download completed----------------------"
else
    echo "Download failed, exiting......"
    exit 1
fi
make -j$(expr $(nproc) + 1) V=s
if [ $? -eq 0]
then
    echo "----------------------Build successed----------------------"
    exit 0
else
    echo "Build failed, exiting......"
    exit 1
fi
