# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CHROMIUM_LANGS="
	af am ar bg bn ca cs da de el en-GB en-US es es-419 et fa fi fil fr gu he
	hi hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt-BR pt-PT ro ru sk sl sr
	sv sw ta te th tr uk ur vi zh-CN zh-TW"

inherit chromium-2 pax-utils xdg desktop

DESCRIPTION="Password manager and secure wallet"
HOMEPAGE="https://1password.com"
SRC_URI="amd64? ( https://downloads.1password.com/linux/tar/stable/x86_64/1password-latest.tar.gz -> 1password-amd64-${PV}.tar.gz )
arm64? ( https://downloads.1password.com/linux/tar/stable/aarch64/1password-latest.tar.gz -> 1password-arm64-${PV}.tar.gz )"

LICENSE="1password"
SLOT="0"
KEYWORDS="amd64 arm64"
RESTRICT="bindist mirror strip"

RDEPEND="
        acct-group/onepassword
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

  # Fill in policy kit file with a list of (the first 10) human users of the system.
  export POLICY_OWNERS
  POLICY_OWNERS="$(cut -d: -f1,3 /etc/passwd | grep -E ':[0-9]{4}$' | cut -d: -f1 | head -n 10 | sed 's/^/unix-user:/' | tr '\n' ' ')"
  eval "cat <<EOF
$(cat ${ED}/${ONEPASSWORD_HOME}/com.1password.1Password.policy.tpl)
EOF" > ./com.1password.1Password.policy

  # Install policy kit file for system unlock
  insinto /usr/share/polkit-1/actions
  insopts -m0644
  doins ./com.1password.1Password.policy

  # Install examples
  insinto /usr/share/doc/1password/examples
  doins ${ED}/${ONEPASSWORD_HOME}/resources/custom_allowed_browsers
  docompress -x /usr/share/doc/1password/examples/custom_allowed_browsers

  # Setup the Core App Integration helper binary with the correct permissions and group
  GROUP_NAME="onepassword"

  HELPER_PATH="/${ONEPASSWORD_HOME}/1Password-KeyringHelper"
  BROWSER_SUPPORT_PATH="/${ONEPASSWORD_HOME}/1Password-BrowserSupport"

  fowners :${GROUP_NAME} $HELPER_PATH
  # The binary requires setuid so it may interact with the Kernel keyring facilities
  fperms 4755 $HELPER_PATH

  # This gives no extra permissions to the binary. It only hardens it against environmental tampering.
  fowners :${GROUP_NAME} $BROWSER_SUPPORT_PATH
  fperms 2755 $BROWSER_SUPPORT_PATH

  # chrome-sandbox requires the setuid bit to be specifically set.
  # See https://github.com/electron/electron/issues/17972
  fperms 4755 /${ONEPASSWORD_HOME}/chrome-sandbox

  dosym /"${ONEPASSWORD_HOME}/${PN}" /usr/bin/${PN}

        local res
        for res in 32 64 256 512; do
                newicon -s ${res} ${ONEPASSWORD_HOME}/resources/icons/hicolor/${res}x${res}/apps/1password.png 1password.png
        done

        domenu ${ONEPASSWORD_HOME}/resources/1password.desktop
}
