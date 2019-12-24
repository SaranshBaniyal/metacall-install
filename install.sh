#!/usr/bin/env bash

#	MetaCall Install Script by Parra Studios
#	Cross-platform set of scripts to install MetaCall infrastructure.
#
#	Copyright (C) 2016 - 2019 Vicente Eduardo Ferrer Garcia <vic798@gmail.com>
#
#	Licensed under the Apache License, Version 2.0 (the "License");
#	you may not use this file except in compliance with the License.
#	You may obtain a copy of the License at
#
#		http://www.apache.org/licenses/LICENSE-2.0
#
#	Unless required by applicable law or agreed to in writing, software
#	distributed under the License is distributed on an "AS IS" BASIS,
#	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#	See the License for the specific language governing permissions and
#	limitations under the License.

# Set mode
set -eu -o pipefail

# Expose stream 3 as a pipe to the standard output of itself
exec 3>&1

# Check if program exists
program() {
	[ -t 1 ] && command -v $1 > /dev/null
}

# Set up colors
if program tput; then
	ncolors=$(tput colors)
	if [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
		bold="$(tput bold		|| echo)"
		normal="$(tput sgr0		|| echo)"
		black="$(tput setaf 0	|| echo)"
		red="$(tput setaf 1		|| echo)"
		green="$(tput setaf 2	|| echo)"
		yellow="$(tput setaf 3	|| echo)"
		blue="$(tput setaf 4	|| echo)"
		magenta="$(tput setaf 5	|| echo)"
		cyan="$(tput setaf 6	|| echo)"
		white="$(tput setaf 7	|| echo)"
	fi
fi

# Title message
title() {
	printf "%b\n\n" "${bold:-}$@${normal:-}"
}

# Warning message
warning() {
	printf "%b\n" "${yellow:-}‼${normal:-} $@"
}

# Error message
err() {
	printf "%b\n" "${red:-}✘${normal:-} $@" >&2
}

# Print message
print() {
	printf "%b\n" "${normal:-}▷ $@" >&3
}

# Success message
success() {
	printf "%b\n" "${green:-}✔${normal:-} $@" >&3
}

# Check if a list of programs exist or aborts
programs_required() {
	for prog in "$@"; do
		if ! program $prog; then
			err "The program '$prog' is not found, it is required to run the installer. Aborting installation."
			exit 1
		fi
	done
}

# Check if at least one program exists in the list or aborts
programs_required_one() {
	for prog in "$@"; do
		if program $prog; then
			return
		fi
	done

	err "None of the following programs are installed: $@. One of them is required at least to download the tarball. Aborting installation."
	exit 1
}

# Check all dependencies
dependencies() {
	print "Checking system dependencies"

	# Check if required programs are installed
	programs_required tar grep tail awk rev cut

	# Check if download programs are installed
	programs_required_one curl wget

	success "Dependencies satisfied."
}

# Download tarball
download() {
	local url="https://github.com/metacall/distributable/releases/latest"
	local tmp="/tmp/metacall-tarball.tar.gz"
	local os="$1"
	local arch="$2"

	print "Start to download the tarball."

	if program curl; then
		local tag_url=$(curl -Ls -o /dev/null -w %{url_effective} ${url})
	elif program wget; then
		local tag_url=$(wget -O /dev/null ${url} 2>&1 | grep Location: | tail -n 1 | awk '{print $2}')
	fi

	local version=$(printf "${tag_url}" | rev | cut -d '/' -f1 | rev)
	local final_url=$(printf "https://github.com/metacall/distributable/releases/download/${version}/metacall-tarball-${os}-${arch}.tar.gz")
	local fail=false

	if program curl; then
		curl --retry 10 -f --create-dirs -LS ${final_url} --output ${tmp} || fail=true
	elif program wget; then
		wget --tries 10 -O ${tmp} ${final_url} || fail=true
	fi

	if "${fail}" == true; then
		err "The tarball metacall-tarball-${os}-${arch}.tar.gz could not be downloaded." \
			"  Please, refer to https://github.com/metacall/install/issues and create a new issue." \
			"  Aborting installation."
		exit 1
	fi

	success "Tarball downloaded."
}

# Show title
title "MetaCall Self-Contained Binary Installer"

# Check dependencies
dependencies

# Detect operative system and architecture

# print "$OSTYPE"

# Download tarball
download linux amd64

# Extract

