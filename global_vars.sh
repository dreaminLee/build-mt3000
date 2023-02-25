glinet_builder_uri='https://github.com/gl-inet/gl-infra-builder.git'
glinet_builder_commitid='1f72c21b11b53143cd6f993c0dcb063d2081f635'
glinet_feeds_uri='https://github.com/gl-inet/gl-feeds.git'
openwrt_openwrt_uri='https://git.openwrt.org/openwrt/openwrt.git'
openwrt_packages_uri='https://git.openwrt.org/feed/packages.git'
openwrt_luci_uri='https://git.openwrt.org/project/luci.git'
openwrt_routing_uri='https://git.openwrt.org/feed/routing.git'
openwrt_telephony_uri='https://git.openwrt.org/feed/telephony.git'
openwrt_telephony_tag='openwrt-21.02'
mtk_openwrt_feeds_uri='https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds.git'

gl_infra_builder_config='config-mt798x-7.6.6.1.yml'
gl_infra_builder_config_local="${gl_infra_builder_config%.*}-local.yml"

glinet_builder_path='glinet/gl-infra-builder'
glinet_feeds_path='glinet/gl-feeds'
openwrt_openwrt_path='openwrt/openwrt'
openwrt_packages_path='openwrt/packages'
openwrt_luci_path='openwrt/luci'
openwrt_routing_path='openwrt/routing'
openwrt_telephony_path='openwrt/telephony'
mtk_openwrt_feeds_path='mtk/mtk-openwrt-feeds'

feeds_default='feeds.conf.default'
target_profile='target_mt7981_gl-mt3000.yml'
target_profile_local="${target_profile%.*}-local.yml"
