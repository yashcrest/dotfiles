#!/bin/sh

# Exit if any subcommand fails
set -e

# Config

show_intro() {
	cat << EOF

$0 will setup your Mac with the following:

* [Homebrew](https://brew.sh)
* [Node Version Manager](https://github.com/nvm-sh/nvm)
* [Node.js](https://nodejs.org)
* [Yarn](https://yarnpkg.com/)
* [Visual Studio Code](https://code.visualstudio.com/)
* [SSH keys](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

EOF
}

# Functions

wait_for_enter() {
	read -p "Press Enter to continue... "
	echo
}

get_user_email() {
	read -p "Enter your email: " USER_EMAIL
}

get_user_full_name() {
	read -p "Enter your full name: " USER_FULL_NAME
}

clone_repo() {
	echo "Cloning repo $1"
	git clone "$1"
}

setup_homebrew() {
	if ! command -v brew >/dev/null 2>&1; then
		echo "Install Homebrew"
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

		echo "Configure Homebrew"
		(echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >> "$HOME/.zprofile"
		eval "$(/usr/local/bin/brew shellenv)"
	fi
}


setup_node() {
	if ! command -v node >/dev/null 2>&1; then
		echo "Install Node.js"
		brew install node@20

		# echo "Configure Node.js"
		# nvm use node 20
	fi
}

setup_yarn() {
	echo "Configure Yarn"
	yarn config set strict-ssl false
	echo 'export NODE_OPTIONS=--openssl-legacy-provider' >> ~/.zshrc
	echo 'export NODE_TLS_REJECT_UNAUTHORIZED=0' >> ~/.zshrc
}

setup_git() {
  echo "Confgiure Git with $USER_FULL_NAME and $USER_EMAIL"
  git config --global user.name "$USER_FULL_NAME"
  git config --global user.email "$USER_EMAIL"
}

setup_ssh_keys() {
	SSH_CONFIG_DIRECTORY="$HOME/.ssh"
	SSH_KEY_NAME="id_ed25519"

	echo "Generating SSH keys with $USER_EMAIL"
	ssh-keygen -t ed25519 -C "$USER_EMAIL"

	echo "Starting SSH agent in the background"
	eval "$(ssh-agent -s)"

	echo "Config SSH keys"
	# Please DO NOT change the indent of this block
	cat << EOF > "$SSH_CONFIG_DIRECTORY/config"
Host github.com
HostName ssh.github.com
Port 443
User git
IgnoreUnknown UseKeychain
AddKeysToAgent yes
UseKeychain yes
IdentityFile ~/.ssh/id_ed25519
EOF

	echo "Add SSH private key to ssh-agent and store passphrase in keychain"
	ssh-add --apple-use-keychain "$SSH_CONFIG_DIRECTORY/$SSH_KEY_NAME"

	echo "SSH public key ($SSH_CONFIG_DIRECTORY/$SSH_KEY_NAME) is copied to your clipboard, please add it to GitHub account."
	echo "Reference: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account"
	cat "$SSH_CONFIG_DIRECTORY/$SSH_KEY_NAME.pub" | pbcopy
	wait_for_enter
}


setup_visual_studio_code() {
	if ! command -v code >/dev/null 2>&1; then
		echo "Install Visual Studio Code"
		brew install visual-studio-code
	fi
}

setup_karabiner_elements() {
	if ! brew list --cask | grep karabiner-elements >/dev/null 2>&1; then
		echo "Installing Karabiner Elements"
		brew install --cask karabiner-elements
	else
		echo "Karabiner-elements is already installed"
	fi

	GITHUB_LINK=https://github.com/yashcrest/karabiner
	KARABINER_PATH=~/.config/karabiner
	echo "Cloning Karabiner elements config from: $GITHUB_LINK"
	cd ~/Developer/ && git clone $GITHUB_LINK
	ln -s ~/Developer/karabiner ~/.config
	if $KARABINER_PATH then
		echo
		rm -rf $KARABINER_PATH
	fi
}

setup_oh_my_zsh () {
	if [! -d "$HOME/.oh-my-zsh"]; then
		echo "Installing oh-my-zsh"
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	else
		echo "oh-my-zsh is already installed"
	fi
}

setup_powerlevel10k () {
	
}

# Setup

show_intro
wait_for_enter
get_user_email
get_user_full_name
setup_homebrew
setup_node
setup_yarn
setup_git
# setup_ssh_keys
setup_visual_studio_code
setup_karabiner_elements
setup_oh_my_zsh
setup_powerlevel10k
