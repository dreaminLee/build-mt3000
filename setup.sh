#!/bin/bash
set -e

# setup a buildsystem for GL.iNet MT3000 at pwd
base=$(pwd)

mkdir -p glinet
mkdir -p openwrt
mkdir -p mtk
mkdir -p dl_cache

echo "----------------------Cloning sources----------------------"

test_or_clone () {
    folder_path=$1
    clone_url=$2
    if [ -d $folder_path ]
    then
        echo "WARNING: ${folder_path} folder exists, use it at your own risk"
    else
        git clone $clone_url $folder_path
    fi
    cd $base
}

. global_vars
test_or_clone $glinet_builder_path $glinet_builder_uri
test_or_clone $glinet_feeds_path $glinet_feeds_uri
test_or_clone $openwrt_openwrt_path $openwrt_openwrt_uri
test_or_clone $openwrt_packages_path $openwrt_packages_uri
test_or_clone $openwrt_luci_path $openwrt_luci_uri
test_or_clone $openwrt_routing_path $openwrt_routing_uri
test_or_clone $openwrt_telephony_path $openwrt_telephony_uri
test_or_clone $mtk_openwrt_feeds_path $mtk_openwrt_feeds_uri

cd $glinet_builder_path
git checkout $glinet_builder_commitid
cd $base
cd $openwrt_telephony_path
git checkout $openwrt_telephony_tag
cd $base

echo "----------------------Generating build system----------------------"
# change config's repo to local
cd $glinet_builder_path
cp -f ./configs/$gl_infra_builder_config ./configs/$gl_infra_builder_config_local
sed -i "s|https://github.com/openwrt/openwrt.git|${base}/${openwrt_openwrt_path}|" ./configs/$gl_infra_builder_config_local
# generate openwrt build system
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

ln -sf $base/$glinet_builder_path/mt7981 ~/openwrt && cd ~/openwrt
sed -i "s|${openwrt_packages_uri}|${base}/${openwrt_packages_path}|" $feeds_default
sed -i "s|${openwrt_luci_uri}|${base}/${openwrt_luci_path}|" $feeds_default
sed -i "s|${openwrt_routing_uri}|${base}/${openwrt_routing_path}|" $feeds_default
sed -i "s|${openwrt_telephony_uri}|${base}/${openwrt_telephony_path}|" $feeds_default
sed -i "s|${mtk_openwrt_feeds_uri}|${base}/${mtk_openwrt_feeds_path}|" $feeds_default
target_profile='target_mt7981_gl-mt3000.yml'
target_profile_local="${target_profile%.*}-local.yml"
cp -f ./profiles/$target_profile ./profiles/$target_profile_local
sed -i "s|${glinet_feeds_uri}|${base}/${glinet_feeds_path}|g" ./profiles/$target_profile_local
./scripts/gen_config.py ${target_profile_local%.*}

echo "----------------------Building basic environment----------------------"
mkdir -p dl
cp -r -u -p $base/dl_cache/* ./dl
make downlaod V=s
make tools/install -j$(expr $(nproc) + 1)
make toolchain/install -j$(expr $(nproc) + 1)
make target/linux/compile -j$(expr $(nproc) + 1)

echo "Congratulations! you can now try to add plugins and compile them seperately"