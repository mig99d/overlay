# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CHROMIUM_LANGS="
	af am ar bg bn ca cs da de el en-GB en-US es es-419 et fa fi fil fr gu he
	hi hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt-BR pt-PT ro ru sk sl sr
	sv sw ta te th tr uk ur vi zh-CN zh-TW"

inherit chromium-2 pax-utils unpacker xdg

DESCRIPTION="Password manager and secure wallet"
HOMEPAGE="https://1password.com"
SRC_URI="amd64? ( https://downloads.1password.com/linux/tar/stable/x86_64/1password-latest.tar.gz -> 1password-amd64-${PV}.tar.gz )
arm64? ( https://downloads.1password.com/linux/tar/stable/aarch64/1password-latest.tar.gz -> 1password-arm64-${PV}.tar.gz )"

LICENSE="1password"
SLOT="0"
KEYWORDS="amd64 arm64"
RESTRICT="bindist mirror strip"

RDEPEND="
	dev-libs/nss
	sys-auth/polkit
	x11-libs/gtk+:3
	x11-libs/libXScrnSaver"

S="${WORKDIR}/"
ONEPASSWORD_HOME="opt/1Password"
QA_PREBUILT="*"

src_prepare() {
	mkdir -p $ONEPASSWORD_HOME
	mv 1password-${PV}.*/* $ONEPASSWORD_HOME
	rmdir 1password-${PV}.*
	pushd "${ONEPASSWORD_HOME}/locales" > /dev/null || die
	chromium_remove_language_paks
	popd > /dev/null || die

	default
}

src_install() {
	cp -r . "${ED}"
	pax-mark m "${ED}/${ONEPASSWORD_HOME}/${PN}"

	dosym /"${ONEPASSWORD_HOME}/${PN}" /usr/bin/${PN}
}
