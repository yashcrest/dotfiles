#!/bin/bash


# Exit if any subcommand fails
set -e

# --- Configuration ---

# List of command-line tools to install
formulae=(
	git
	node@20 # Pinned to version 20
	yarn
)

# List of GUI applications to install
casks=(
	visual-studio-code
	github
	rectangle
	sourcetree
	karabiner-elements
	notion
	obsidian
	maccy
	webcatalog
	figma
	1password
	cursor
	warp
)

# --- Functions ---

show_intro() {
	cat <<EOF

$0 will setup your Mac.
Press Enter to review the packages and continue...

EOF
}

wait_for_enter() {
	read -p "Press Enter to continue... "
	echo
}

get_user_info() {
	read -p "Enter your email for Git and SSH: " USER_EMAIL
	read -p "Enter your full name for Git: " USER_FULL_NAME
}

# Makes the script architecture-aware (Intel vs Apple Silicon)
setup_homebrew() {
	if ! command -v brew >/dev/null 2>&1; then
		echo "Installing Homebrew..."
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	fi

	echo "Configuring Homebrew Shell Environment..."
	local brew_path
	if [[ -x "/opt/homebrew/bin/brew" ]]; then # Apple Silicon
		brew_path="/opt/homebrew/bin/brew"
	elif [[ -x "/usr/local/bin/brew" ]]; then # Intel
		brew_path="/usr/local/bin/brew"
	else
		echo "ERROR: Homebrew installation not found." >&2
		exit 1
	fi

	eval "$($brew_path shellenv)"
	# Add to .zprofile to make it available in new shells
	if ! grep -q "$brew_path shellenv" "$HOME/.zprofile"; then
		(echo; echo "eval \"\$($brew_path shellenv)\"") >> "$HOME/.zprofile"
	fi
}

install_packages() {
	echo "Installing Homebrew formulae..."
	for formula in "${formulae[@]}"; do
		if ! brew list "$formula" &>/dev/null; then
			echo "Installing $formula..."
			brew install "$formula"
		else
			echo "$formula is already installed."
		fi
	done

	echo "Installing Homebrew casks..."
	for cask in "${casks[@]}"; do
		if ! brew list --cask "$cask" &>/dev/null; then
			echo "Installing $cask..."
			brew install --cask "$cask"
		else
			echo "$cask is already installed."
		fi
	done
}

configure_git() {
	echo "Configuring Git with $USER_FULL_NAME and $USER_EMAIL..."
	git config --global user.name "$USER_FULL_NAME"
	git config --global user.email "$USER_EMAIL"
}

setup_ssh_keys() {
	local ssh_key_path="$HOME/.ssh/id_ed25519"
	if [ -f "$ssh_key_path" ]; then
		echo "SSH key already exists. Skipping generation."
	else
		echo "Generating SSH keys with $USER_EMAIL..."
		ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$ssh_key_path" -N ""
	fi

	eval "$(ssh-agent -s)"

	# Create a robust SSH config for GitHub over HTTPS
	local ssh_config_path="$HOME/.ssh/config"
	if ! grep -q "Host github.com" "$ssh_config_path" 2>/dev/null; then
		echo "Configuring SSH for GitHub..."
		# Using '>>' to append safely
		cat <<EOF >>"$ssh_config_path"

# GitHub configuration
Host github.com
  HostName ssh.github.com
  Port 443
  User git
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile $ssh_key_path
EOF
	fi

	ssh-add --apple-use-keychain "$ssh_key_path"

	echo "SSH public key is copied to your clipboard. Add it to your GitHub account."
	pbcopy < "${ssh_key_path}.pub"
	wait_for_enter
}

configure_karabiner() {
	echo "Configuring Karabiner-Elements..."
	local repo_path="$HOME/Developer/karabiner"
	local config_path="$HOME/.config/karabiner"

	if [ ! -d "$repo_path" ]; then
		echo "Cloning Karabiner config repository..."
		git clone "https://github.com/yashcrest/karabiner" "$repo_path"
	else
		echo "Karabiner config repository already exists."
	fi

	# Safely back up existing config before creating symlink
	if [ -e "$config_path" ]; then
		echo "Backing up existing Karabiner config to ${config_path}.bak..."
		mv "$config_path" "${config_path}.bak"
	fi
	
	mkdir -p "$(dirname "$config_path")"
	ln -s "$repo_path" "$config_path"
	echo "Karabiner-Elements configured."
}

setup_oh_my_zsh() {
	if [ ! -d "$HOME/.oh-my-zsh" ]; then
		echo "Installing Oh My Zsh..."
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	else
		echo "Oh My Zsh is already installed."
	fi
}

configure_node_env() {
	echo "Configuring Node.js environment variables in .zshrc..."
	if ! grep -q "NODE_OPTIONS" "$HOME/.zshrc"; then
		cat <<EOF >>"$HOME/.zshrc"

# Custom Node.js Environment
export NODE_OPTIONS=--openssl-legacy-provider
export NODE_EXTRA_CA_CERTS=/Library/Application\ Support/Netskope/STAgent/data/nscert.pem
EOF
	fi
}


# --- Main Execution ---

show_intro
wait_for_enter

get_user_info
setup_homebrew
install_packages
configure_git
setup_ssh_keys
configure_karabiner
setup_oh_my_zsh
configure_node_env

echo "✅ Mac setup complete!"