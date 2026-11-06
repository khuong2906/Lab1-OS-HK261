#!/bin/bash
# cp bku.sh bku
# chmod +x bku
# sudo cp bku /usr/local/bin

install_bku_to_system() {
	cp bku.sh bku
	chmod +x bku
	sudo cp bku /usr/local/bin
	# sudo chmod +x bku
	rm bku
}

script_action="$1"

if [[ "$script_action" == "--install" ]]
	then
		required_dependencies=("diff" "cron" "grep" "sed" "find" "mkdir")
		echo "Checking dependencies..."
		for dependency_name in "${required_dependencies[@]}"
			do
				if ! command -v "$dependency_name"
					then
						echo "Error: Failed to install packages. Please check your package manager or install them manually"
						break
					fi
			done
		echo "All dependencies installed"
		install_bku_to_system
		echo "BKU installed to /usr/local/bin/bku"

elif [[ "$script_action" == "--uninstall" ]]
	then
		echo "Checking BKU uninstallation..."
		if [[ -f "/usr/local/bin/bku" ]]
			then
				bku stop
				sudo rm -f /usr/local/bin/bku
				echo "Removing BKU from /usr/local/bin/bku..."
				echo "Removing scheduled backups..."
				echo "BKU successfully uninstalled"
		else
			echo "Error: BKU is not installed in /usr/local/bin/bku"
			echo "Nothing to uninstall"
		fi

else
	echo "These are the action to set up the system:"
	echo "---------------------------------------------------------------"
	echo "| --install   | check dependecies and install the BKU system. |"
	echo "| --uninstall | to uninstall the system.                      |"
	echo "---------------------------------------------------------------"
fi
