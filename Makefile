SHELL := /bin/bash
all: update_zshrc install_oh_my_zsh install_plugins install_mamba_env install_nodejs install_nvim update_nvim install_vscode install_tmux install_openvpn install_fzf install_java install_nf install_unzip install_tf restart_shell

update_zshrc:
	if [ -f "$$HOME/.zshrc" ]; then \
		cat "$$HOME/.zshrc" > "$$HOME/.zshrc.bak"; \
	else \
		echo "No existing .zshrc file found."; \
	fi; \
	cp zshrc_update "$$HOME/.zshrc"

install_oh_my_zsh: update_zshrc
	if [ ! -d "$$HOME/.oh-my-zsh" ]; then \
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
		plugin_dir="$$HOME/.oh-my-zsh/custom/plugins/$$plugin"; \
		if [ ! -d "$$plugin_dir" ]; then \
				git clone "$$plugin_url" "$$plugin_dir"; \
		else \
				echo "Plugin $$plugin is already installed."; \
		fi; \
	done

install_mamba_env: install_plugins
	if ! command -v conda &> /dev/null; then \
	        wget -O Miniforge3.sh "https://github.com/conda-forge/miniforge/releases/download/23.3.1-1/Mambaforge-23.3.1-1-Linux-x86_64.sh"; \
	        bash Miniforge3.sh -b -p "${HOME}/conda"; \
	        rm Miniforge3.sh; \
	        source "${HOME}/conda/etc/profile.d/conda.sh"; \
	        source "${HOME}/conda/etc/profile.d/mamba.sh"; \
	        conda activate; \
	        echo "Creating conda environment 'work'"; \
	        ${HOME}/conda/bin/mamba create -n work python=3.11 black pynvim isort awscli wheel setuptools virtualenv -c conda-forge -y; \
	        ${HOME}/conda/bin/conda init zsh; \
			echo "conda activate work" >> "${HOME}/.zshrc" ; \
	else \
	        if ! command -v mamba &> /dev/null; then \
	                conda install -y mamba -c conda-forge; \
	                mamba create -n work python=3.11 black pynvim isort awscli wheel setuptools virtualenv -c conda-forge -y; \
	        else \
	                if ! conda env list | grep -q "work"; then \
	                        mamba create -n work python=3.11 black pynvim isort awscli wheel setuptools virtualenv -c conda-forge -y; \
	                fi; \
	        fi; \
		conda init zsh; \
		echo "conda activate work" >> "${HOME}/.zshrc" ; \
	fi

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
		sudo apt update && sudo apt install -y neovim; \
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

install_vscode:
	if ! command -v code &> /dev/null; then \
		wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg ; \
		sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg ; \
		sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' ; \
		rm -f packages.microsoft.gpg ; \
		sudo apt install apt-transport-https ; \
		sudo apt update ; \
		sudo apt install code -y ; \
	else \
		echo "VS Code is already installed." ; \
	fi

install_tmux:
	if ! command -v tmux &> /dev/null; then \
		sudo apt update && sudo apt install -y tmux; \
	else \
		echo "tmux is already installed."; \
	fi

install_openvpn:
	if ! command -v openvpn &> /dev/null; then \
		sudo apt update && sudo apt install -y openvpn; \
	else \
		echo "OpenVPN is already installed."; \
	fi

install_fzf:
	if ! command -v fzf > /dev/null 2>&1; then \
		sudo apt update && sudo apt install -y fzf; \
	else \
		echo "fzf is already installed."; \
	fi

install_java:
	if ! command -v java &> /dev/null; then \
		sudo apt update && sudo apt install -y openjdk-11-jdk; \
	else \
		echo "Java is already installed."; \
	fi


install_nf: install_java
	if ! command -v nextflow > /dev/null 2>&1; then \
		curl -s https://get.nextflow.io | bash; \
		chmod +x nextflow; \
		sudo mv nextflow /usr/bin/nextflow; \
	else \
		echo "nextflow is already installed."; \
	fi

install_unzip:
	if ! command -v unzip > /dev/null 2>&1; then \
		sudo apt update && sudo apt install -y unzip; \
	else \
		echo "unzip is already installed."; \
	fi

install_tf: install_unzip
	if ! command -v terraform > /dev/null 2>&1; then \
		wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip; \
			unzip terraform_1.6.0_linux_amd64.zip; \
			sudo mv terraform /usr/local/bin/; \
			rm terraform_1.6.0_linux_amd64.zip; \
		else \
			echo "terraform is already installed."; \
		fi
restart_shell:
	echo "Please restart your shell for changes to take effect"
