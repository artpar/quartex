APP_NAME = HelloWorldApp
BUNDLE_NAME = $(APP_NAME).app
CONTENTS_DIR = $(BUNDLE_NAME)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
RESOURCES_DIR = $(CONTENTS_DIR)/Resources

SWIFT_FILES = main.swift AppDelegate.swift ViewController.swift
SWIFT_FLAGS = -target x86_64-apple-macosx10.13 -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk

.PHONY: all clean run

all: $(BUNDLE_NAME)

$(BUNDLE_NAME): $(SWIFT_FILES) Info.plist
	@echo "Building $(APP_NAME)..."
	@mkdir -p $(MACOS_DIR)
	@mkdir -p $(RESOURCES_DIR)
	@swiftc $(SWIFT_FLAGS) -o $(MACOS_DIR)/$(APP_NAME) $(SWIFT_FILES)
	@cp Info.plist $(CONTENTS_DIR)/
	@echo "Build complete: $(BUNDLE_NAME)"

run: $(BUNDLE_NAME)
	@echo "Running $(APP_NAME)..."
	@open $(BUNDLE_NAME)

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUNDLE_NAME)
	@echo "Clean complete"

install: $(BUNDLE_NAME)
	@echo "Installing $(APP_NAME) to /Applications..."
	@cp -R $(BUNDLE_NAME) /Applications/
	@echo "Installation complete"