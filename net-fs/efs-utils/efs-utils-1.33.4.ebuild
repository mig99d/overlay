# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
 
EAPI=8
 
DESCRIPTION="Utilities for Amazon Elastic File System (EFS)"
HOMEPAGE="https://github.com/aws/efs-utils"
SRC_URI="https://github.com/aws/efs-utils/archive/refs/tags/v1.33.4.tar.gz"
 
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="test"
RESTRICT="!test? ( test )"
 
DEPEND=""
RDEPEND="net-misc/stunnel dev-python/botocore"
BDEPEND="test? (
		dev-python/virtualenv
		dev-python/pip
		)"

src_test() {
	if use test ; then
		virtualenv .test || die
		source .test/activate || die
		pip install -r requirements.txt || die
		make test || die
	fi
}

src_compile() {
	./build-deb.sh || die
}

src_install() {
	cp -rf ${S}/build/debbuild/{etc,sbin,usr,var} ${D}
	keepdir /var/log/amazon/efs
}

pkg_postinst() {
    if [ "$(cat /proc/1/comm)" = "init" ]; then
        /sbin/restart amazon-efs-mount-watchdog &> /dev/null || true
    elif [ "$(cat /proc/1/comm)" = "systemd" ]; then
        if systemctl is-active --quiet amazon-efs-mount-watchdog; then
            systemctl try-restart amazon-efs-mount-watchdog.service &> /dev/null || true
        fi
    fi
}

pkg_prerm() {
    if [ "$(cat /proc/1/comm)" = "init" ]; then
        /sbin/stop amazon-efs-mount-watchdog &> /dev/null || true
    elif [ "$(cat /proc/1/comm)" = "systemd" ]; then
        if systemctl is-active --quiet amazon-efs-mount-watchdog; then
            systemctl --no-reload disable amazon-efs-mount-watchdog.service &> /dev/null || true
            systemctl stop amazon-efs-mount-watchdog.service &> /dev/null || true
        fi
    fi
}

pkg_postrm() {
    if [ "$(cat /proc/1/comm)" = "systemd" ]; then
        systemctl daemon-reload
    fi
    rm -f /var/log/amazon/efs/*
}
