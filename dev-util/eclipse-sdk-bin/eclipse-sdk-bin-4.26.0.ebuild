# Copyright 1999-2020 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=7

inherit eutils desktop

SR="R"
RNAME="2022-12"

SRC_BASE="https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/${RNAME}/${SR}/eclipse-java-${RNAME}-${SR}-linux-gtk"

DESCRIPTION="Eclipse SDK"
HOMEPAGE="http://www.eclipse.org"
SRC_URI="amd64? ( ${SRC_BASE}-x86_64.tar.gz&r=1 -> eclipse-java-${RNAME}-${SR}-linux-gtk-x86_64-${PV}.tar.gz )
arm64? ( ${SRC_BASE}-aarch64.tar.gz&r=1 -> eclipse-java-${RNAME}-${SR}-linux-gtk-aarch64-${PV}.tar.gz )"

LICENSE="EPL-1.0"
SLOT="4.26"
KEYWORDS="~x86 ~amd64 ~arm64"
IUSE=""

RDEPEND="
	virtual/jdk:17
	x11-libs/gtk+:3"

S=${WORKDIR}/eclipse

src_install() {
	local dest=/opt/${PN}-${SLOT}

	insinto ${dest}
	doins -r features icon.xpm plugins artifacts.xml p2 eclipse.ini configuration dropins

	exeinto ${dest}
	doexe eclipse

	docinto html
	dodoc -r readme/*

	cp "${FILESDIR}"/eclipserc-bin-${SLOT} "${T}" || die
	cp "${FILESDIR}"/eclipse-bin-${SLOT} "${T}" || die
	sed "s@%SLOT%@${SLOT}@" -i "${T}"/eclipse{,rc}-bin-${SLOT} || die

	insinto /etc
	newins "${T}"/eclipserc-bin-${SLOT} eclipserc-bin-${SLOT}

	newbin "${T}"/eclipse-bin-${SLOT} eclipse-bin-${SLOT}
	make_desktop_entry "eclipse-bin-${SLOT}" "Eclipse ${PV} (bin)" "${dest}/icon.xpm"
}
