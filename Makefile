SHELL := /bin/bash
all: update_gitconfig update_zshrc install_oh_my_zsh install_plugins setup_rsa install_pyenv update_pyenv install_nodejs install_nvim update_nvim install_aws install_docker install_nf install_tf install_s3mount install_vscode restart_shell

update_gitconfig:
	git config --global core.editor "nvim"
	git config --global init.defaultBranch "main"
	git config --global push.default "current"
	git config --global push.autoSetupRemote "true"
	git config --global pull.rebase "false"
	git config --global alias.ac "!git add -A && git commit -a"
	git config --global alias.mainlog "log --graph --first-parent"
	git config --global alias.set-upstream "!git branch --set-upstream-to=origin/`git symbolic-ref --short HEAD`"

update_zshrc:
	if [ -f "$${HOME}/.zshrc" ]; then \
		cat "$${HOME}/.zshrc" > "$${HOME}/.zshrc.bak"; \
	else \
		echo "No existing .zshrc file found."; \
	fi; \
	cp zshrc_update "$${HOME}/.zshrc"

install_oh_my_zsh: update_zshrc
	if [ ! -d "$${HOME}/.oh-my-zsh" ]; then \
		sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc; \
		echo "Type 'exit' to continue installation script."; \
	else \
		echo "Oh My Zsh is already installed."; \
	fi

install_plugins: install_oh_my_zsh
	declare -A plugins=( \
		["ohmyzsh-full-autoupdate"]="https://github.com/Pilaton/OhMyZsh-full-autoupdate.git" \
		["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions.git" \
		["zsh-completions"]="https://github.com/zsh-users/zsh-completions.git" \
		["zsh-vi-mode"]="https://github.com/jeffreytse/zsh-vi-mode.git" \
	); \
	for plugin in "$${!plugins[@]}"; do \
		plugin_url="$${plugins[$$plugin]}"; \
		plugin_dir="$${HOME}/.oh-my-zsh/custom/plugins/$${plugin}"; \
		if [ ! -d "$$plugin_dir" ]; then \
				git clone "$$plugin_url" "$$plugin_dir"; \
		else \
				echo "Plugin $$plugin is already installed."; \
		fi; \
	done

setup_rsa:
	if [ ! -d "$${HOME}/.ssh/" ]; then
		mkdir "$${HOME}/.ssh"
	fi
	if [ ! -f "$${HOME}/.ssh/id_rsa" ] || [ ! -f "$${HOME}/.ssh/id_rsa.pub" ]; then
		rm -f "$${HOME}/.ssh/id_rsa" "$${HOME}/.ssh/id_rsa.pub"
		ssh-keygen -f "$${HOME}/.ssh/id_rsa" -t rsa -N ''
	fi

install_pyenv: install_plugins
	# Remove any existing Conda installations first
	if [ -d "$${HOME}/conda" ] || [ -d "$${HOME}/miniconda3" ] || [ -d "$${HOME}/anaconda3" ] || [ -d "opt/conda" ]; then \
		echo "Removing existing Conda installations..."; \
		rm -rf "$${HOME}/conda" "$${HOME}/miniconda3" "$${HOME}/anaconda3" "/opt/conda"; \
	fi
	# Install pyenv
	echo "Installing pyenv..."
	rm -rf "$${HOME}/.pyenv"
	curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
	# Append pyenv init to .zshrc in a safe manner
	echo 'export PYENV_ROOT="$${HOME}/.pyenv"' >> "$${HOME}/.zshrc"
	echo '[ -d "$${PYENV_ROOT}/bin" ] && export PATH="$${PYENV_ROOT}/bin:$${PATH}"' >> "$${HOME}/.zshrc"
	echo 'eval "$$(pyenv init -)"' >> "$${HOME}/.zshrc"
	echo 'eval "$$(pyenv virtualenv-init -)"' >> "$${HOME}/.zshrc"
	export PYENV_ROOT="${HOME}/.pyenv"; \
		export PATH="${PYENV_ROOT}/bin:${PATH}"; \
		"$${HOME}/.pyenv/bin/pyenv" init -; \
		"$${HOME}/.pyenv/bin/pyenv" virtualenv-init -; \
		"$${HOME}/.pyenv/bin/pyenv" install 3.11.4; \
		"$${HOME}/.pyenv/bin/pyenv" global 3.11.4; \
		"$${HOME}/.pyenv/bin/pyenv" rehash; \
		"$${HOME}/.pyenv/shims/python3" -m pip install --user pipx; \
		"$${HOME}/.pyenv/shims/python3" -m pipx ensurepath; \
		"$${HOME}/.pyenv/shims/pipx" install pipenv==2023.6.12; \
		"$${HOME}/.pyenv/shims/pip" install --upgrade pip setuptools virtualenv wheel;
	echo "pyenv with Python 3.11.4 installed and configured globally."

update_pyenv: install_pyenv
	if [ -f "$${HOME}/Pipfile" ]; then \
		cat "$${HOME}/Pipfile" > "$${HOME}/Pipfile.bak"; \
	else \
		echo "No existing Pipfile file found."; \
	fi; \
	cp Pipfile "$${HOME}/Pipfile"
	cd $$HOME; \
		pipenv lock; \
		pipenv sync; 

install_nodejs:
	if ! command -v node &> /dev/null; then \
		wget https://nodejs.org/dist/v18.18.0/node-v18.18.0-linux-x64.tar.xz; \
		tar -xf node-v18.18.0-linux-x64.tar.xz; \
		sudo cp node-v18.18.0-linux-x64/bin/* /usr/bin/; \
		rm -rf node-v18.18.0-linux-x64 node-v18.18.0-linux-x64.tar.xz; \
	else \
		echo "Node.js is already installed."; \
	fi

install_nvim: install_nodejs
	if ! command -v nvim &> /dev/null; then \
		curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage ; \
		chmod u+x nvim.appimage ; \
		sudo mkdir -p /usr/local/bin ; \
		sudo mv nvim.appimage /usr/local/bin/nvim.appimage ; \
		export CUSTOM_NVIM_PATH="/usr/local/bin/nvim.appimage" ; \
		set -u ; \
		sudo update-alternatives --install /usr/bin/nvim nvim "$${CUSTOM_NVIM_PATH}" 110 ; \
		sudo update-alternatives --install /usr/bin/ex ex "$${CUSTOM_NVIM_PATH}" 110 ; \
		sudo update-alternatives --install /usr/bin/vi vi "$${CUSTOM_NVIM_PATH}" 110 ; \
		sudo update-alternatives --install /usr/bin/view view "$${CUSTOM_NVIM_PATH}" 110 ; \
		sudo update-alternatives --install /usr/bin/vim vim "$${CUSTOM_NVIM_PATH}" 110 ; \
		sudo update-alternatives --install /usr/bin/vimdiff vimdiff "$${CUSTOM_NVIM_PATH}" 110 ; \
	else \
		echo "Neovim is already installed."; \
	fi

update_nvim: install_nvim
	mkdir -p "${HOME}/.config/nvim"
	if [ -f "${HOME}/.config/nvim/init.vim" ]; then \
		cat "${HOME}/.config/nvim/init.vim" > "${HOME}/.config/nvim/init.vim.bak"; \
	else \
		echo "No existing init.vim file found."; \
	fi
	cp init.vim "${HOME}/.config/nvim/init.vim"
	nvim -c "PlugInstall" -c "qa"
	nvim -c "PlugUpdate" -c "qa"

install_aws:
	if ! command -v aws > /dev/null 2>&1; then \
		curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; \
		unzip awscliv2.zip; \
		sudo ./aws/install; \
		rm -rf aws; \
	else \
		echo "awscli is already installed."; \
	fi

install_docker:
	# Add Docker's official GPG key:
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc
	echo "deb [arch=$$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
		$$(. /etc/os-release && echo "$$VERSION_CODENAME") stable" | \
		sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt-get update
	sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

install_nf:
	if ! command -v nextflow > /dev/null 2>&1; then \
		curl -s https://get.nextflow.io | bash; \
		chmod +x nextflow; \
		sudo mv nextflow /usr/bin/nextflow; \
	else \
		echo "nextflow is already installed."; \
	fi

install_tf:
	if ! command -v terraform > /dev/null 2>&1; then \
		wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip; \
			unzip terraform_1.6.0_linux_amd64.zip; \
			sudo mv terraform /usr/local/bin/; \
			rm terraform_1.6.0_linux_amd64.zip; \
	else \
		echo "terraform is already installed."; \
	fi


install_s3mount:
	if ! command -v mount-s3 &> /dev/null; then \
		wget https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.deb; \
		sudo apt-get install ./mount-s3.deb; \
		rm mount-s3.deb; \
	else \
		echo "s3-mountpoint is already installed." ; \
	fi

install_vscode:
	if ! command -v code &> /dev/null; then \
		wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg ; \
		sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg ; \
		sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' ; \
		rm -f packages.microsoft.gpg ; \
		sudo apt update ; \
		sudo apt install code -y ; \
	else \
		echo "VS Code is already installed." ; \
	fi

restart_shell:
	echo "Please restart your shell for changes to take effect"

