# Copyright 1999-2025 Gentoo Author
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Portuguese Citizen Card Middleware"
HOMEPAGE="https://github.com/amagovpt/autenticacao.gov"

inherit git-r3 unpacker

EGIT_CLONE_TYPE="single"
EGIT_REPO_URI="https://github.com/amagovpt/autenticacao.gov.git"
EGIT_COMMIT="v$PV"

LICENSE="EUPL"
SLOT="3"
KEYWORDS="~amd64 ~x86 ~aarch64"
IUSE="java"

# sudo apt install pcscd qml-module-qt-labs-folderlistmodel qml-module-qt-labs-settings qml-module-qt-labs-platform qml-module-qtgraphicaleffects qml-module-qtquick-controls qml-module-qtquick-controls2 qml-module-qtquick-dialogs qml-module-qtquick-layouts qml-module-qtquick-templates2 qml-module-qtquick-window2 qml-module-qtquick2 qt5-gtk-platformtheme libnsspem fonts-lato policykit-1
DEPEND="dev-lang/swig
        dev-build/qconf
        >=dev-libs/xml-security-c-2.0.4
	>=dev-libs/openssl-3.0.8
	>=media-libs/openjpeg-2.4.0
	<media-libs/openjpeg-2.6.0
	java? ( dev-java/openjdk:11 )"
RDEPEND="${DEPEND}
        >=sys-apps/pcsc-lite-1.5.0
	sys-apps/pcsc-tools
	app-crypt/ccid
	>=dev-qt/qtcore-5
	dev-qt/qtchooser
	>=dev-libs/xml-security-c-2.0.4
	>=dev-libs/xerces-c-3.2.4
	>=dev-libs/openssl-3.0.8
	app-text/poppler[qt5]
	>=dev-libs/libzip-1.6.1
	>=net-misc/curl-7.80.0
	dev-qt/qtgraphicaleffects
	dev-qt/qtquickcontrols
	dev-qt/qtquickcontrols2
	>=dev-libs/openpace-1.1.3
	>=dev-libs/cJSON-1.7.15
	!app-misc/autenticacao-gov-pt:2
	!app-misc/cartao-cidadao-svn"

PATCHES=(
	${FILESDIR}/java-path-3.8.0.patch
	)

src_unpack() {
	unpacker_src_unpack
	git-r3_fetch
	git-r3_checkout
}

src_prepare() {
	default
	pushd "${S}" >/dev/null
	rm -rf ./docs README.md license.txt
	mv pteid-mw-pt/_src/eidmw/* .
	rm -rf pteid-mw-pt
	use !java && rm -rf eidlibJava_Wrapper
	popd >/dev/null
	use !java && eapply "${FILESDIR}/pteid-mw.pro.patch"
}

src_configure() {
	# configure
	if [[ -x ${ECONF_SOURCE:-.}/configure ]] ; then
		${ECONF_SOURCE:-.}/configure || die "Error: econf failed"
	elif [[ -f ${ECONF_SOURCE:-.}/configure ]] ; then
		fperms 755 ${ECONF_SOURCE:-.}/configure
		${ECONF_SOURCE:-.}/configure || die "Error: econf failed"
	else
		default
	fi
}

src_compile() {
	# qmake
	if [ -f pteid-mw.pro ]; then
		/usr/lib64/qt5/bin/qmake pteid-mw.pro
	else
		die "Error: compile phase failed because is missing pteid-mw.pro!"
	fi

	# make
	if [ -f Makefile ] || [ -f GNUmakefile ] || [ -f makefile ]; then
		emake || die "Error: emake failed"
	else
		die "Error: compile phase failed because is missing Makefile!"
	fi
}

src_install() {
	# make install
	dodir /usr/local/lib
	if [[ -f Makefile ]] || [[ -f GNUmakefile ]] || [[ -f makefile ]] ; then
		emake INSTALL_ROOT="${ED}" DESTDIR="${ED}" install || die "Error: emake install failed"
	else
		die "Error: install phase failed because is missing Makefile!"
	fi

	# install additional icons and images from ubuntu package
	dodir /usr/share/pixmaps
	dodir /usr/share/applications
	dodir /usr/share/doc/pteid-mw
	dodir /usr/share/icons/hicolor/64x64/mimetypes
	dodir /usr/share/icons/hicolor/scalable/apps
	dodir /usr/local/lib/pteid_jni
	insinto /usr/share/pixmaps
	doins debian/pteid-signature.png
	insinto /usr/share/applications
	doins debian/pteid-mw-gui.desktop
	insinto /usr/share/doc/pteid-mw
	doins debian/copyright
	doins debian/changelog
# 	insinto /usr/share/icons/hicolor/64x64/mimetypes
# 	doins "${WORKDIR}"/usr/share/icons/hicolor/64x64/mimetypes/gnome-mime-application-x-signedcc.png
# 	doins "${WORKDIR}"/usr/share/icons/hicolor/64x64/mimetypes/application-x-signedcc.png
	insinto /usr/share/icons/hicolor/scalable/apps
	doins debian/pteid-scalable.svg
	if use !java; then
		insinto /usr/local/lib/pteid_jni
		doins "${WORKDIR}"/usr/local/lib/pteid_jni/pteidlibj.jar
	fi
}

