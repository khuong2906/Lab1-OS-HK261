CC = gcc
CFLAGS = -Wall -Wextra -std=c11
TARGET = cnew
SOURCE = main.c
INSTALL_DIR = /usr/local/bin
SUDO = sudo
REQUIRED_DEPENDENCIES = gcc git

all: $(TARGET)

$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE)

install:
	@echo "Checking dependencies..."
	@for dependency_name in $(REQUIRED_DEPENDENCIES); do \
		if ! command -v $$dependency_name > /dev/null; then \
			echo "Error: $$dependency_name is not installed. Please install it manually"; \
			exit 1; \
		fi; \
	done
	@echo "All dependencies installed"
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE)
	chmod +x $(TARGET)
	$(SUDO) mv $(TARGET) $(INSTALL_DIR)/$(TARGET)
	@echo "CNEW installed to $(INSTALL_DIR)/$(TARGET)"

uninstall:
	@echo "Checking CNEW uninstallation..."
	@if [ -f "$(INSTALL_DIR)/$(TARGET)" ]; then \
		$(SUDO) rm -f $(INSTALL_DIR)/$(TARGET); \
		rm -f $(TARGET); \
		echo "Removing CNEW from $(INSTALL_DIR)/$(TARGET)..."; \
		echo "Cleaning up build files..."; \
		echo "CNEW successfully uninstalled"; \
	else \
		echo "Error: CNEW is not installed in $(INSTALL_DIR)/$(TARGET)"; \
		echo "Nothing to uninstall"; \
	fi

clean:
	rm -f $(TARGET)

help:
	@echo "These are the action to set up the system:"
	@echo "----------------------------------------------------------------"
	@echo "| make           | compile main.c into the cnew binary.        |"
	@echo "| make install   | check dependencies and install CNEW.        |"
	@echo "| make uninstall | uninstall the system.                       |"
	@echo "| make clean     | remove the cnew binary in this folder.      |"
	@echo "----------------------------------------------------------------"

.PHONY: all install uninstall clean help
