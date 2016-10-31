CONFIGURATION?=Release
TARGET=Kinvey
PRODUCT_NAME=$(TARGET)Kit
MODULE=$(PRODUCT_NAME).framework
FRAMEWORK=NonModule/$(PRODUCT_NAME).framework
STATIC_LIB=libKinvey.a
OUTPUT_FOLDER=build
PWD=$(dir $(shell pwd))$(notdir $(shell pwd))
VERSION=$(shell /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${PWD}/KinveyKit/Info.plist")
DEPLOY_FOLDER=$(OUTPUT_FOLDER)/$(PRODUCT_NAME)-$(VERSION)

all: build doc
	
build:
	xcodebuild -configuration $(CONFIGURATION) -target $(TARGET) ONLY_ACTIVE_ARCH=NO -sdk iphoneos
	xcodebuild -configuration $(CONFIGURATION) -target $(TARGET) ONLY_ACTIVE_ARCH=NO -sdk iphonesimulator
	cd $(OUTPUT_FOLDER); \
	mkdir $(CONFIGURATION)-universal; \
	cp -R $(CONFIGURATION)-iphoneos/include $(CONFIGURATION)-universal; \
	lipo -create $(CONFIGURATION)-iphoneos/$(STATIC_LIB) $(CONFIGURATION)-iphonesimulator/$(STATIC_LIB) -output $(CONFIGURATION)-universal/$(STATIC_LIB); \
	cd $(CONFIGURATION)-universal; \
	mkdir -p $(FRAMEWORK)/Versions/A/Headers; \
	ln -sfh A "$(FRAMEWORK)/Versions/Current"; \
	ln -sfh Versions/Current/Headers "$(FRAMEWORK)/Headers"; \
	ln -sfh "Versions/Current/$(PRODUCT_NAME)" "$(FRAMEWORK)/$(PRODUCT_NAME)"; \
	cp include/$(PRODUCT_NAME)/*.h "$(FRAMEWORK)/Versions/A/Headers"; \
	cp $(STATIC_LIB) "$(FRAMEWORK)/Versions/A/$(PRODUCT_NAME)"
	
	xcodebuild -configuration $(CONFIGURATION) -target $(PRODUCT_NAME) -sdk iphoneos
	xcodebuild -configuration $(CONFIGURATION) -target $(PRODUCT_NAME) -sdk iphonesimulator
	cd $(OUTPUT_FOLDER); \
	cp -R $(CONFIGURATION)-iphonesimulator/$(MODULE) $(CONFIGURATION)-universal; \
	lipo -create $(CONFIGURATION)-iphoneos/$(MODULE)/$(PRODUCT_NAME) $(CONFIGURATION)-iphonesimulator/$(MODULE)/$(PRODUCT_NAME) -output $(CONFIGURATION)-universal/$(MODULE)/$(PRODUCT_NAME)
	
doc:
	cd ../Tools; \
	./build-doc ../KinveyKit

pkg: all
	rm -Rf mkdir -p $(DEPLOY_FOLDER)
	mkdir -p $(DEPLOY_FOLDER)
	cp -R doc/built-docs/com.kinvey.$(PRODUCT_NAME).docset $(DEPLOY_FOLDER)
	cp -R $(OUTPUT_FOLDER)/$(CONFIGURATION)-universal/$(FRAMEWORK) $(DEPLOY_FOLDER)
	cp LICENSES $(DEPLOY_FOLDER)
	mkdir -p $(DEPLOY_FOLDER)/Module/$(MODULE)
	cp -R $(OUTPUT_FOLDER)/$(CONFIGURATION)-universal/$(MODULE) $(DEPLOY_FOLDER)/Module
	cd $(DEPLOY_FOLDER); \
	cd ..; zip -r $(PRODUCT_NAME)-$(VERSION).zip $(PRODUCT_NAME)-$(VERSION)
	
deploy: pkg
	cd ../Tools/upload-to-amazon-aws-s3; \
	npm install; \
	npm start
	
deploy-reference:
	rm -Rf devcenter
	git clone git@github.com:Kinvey/devcenter.git
	cd devcenter; \
	git remote add staging git@heroku.com:v3yk1n-devcenter.git; \
	git remote add production git@heroku.com:kinvey-devcenter-prod.git
	rm -R devcenter/content/reference/ios/api
	cp -R doc/output/html devcenter/content/reference/ios
	mv devcenter/content/reference/ios/html devcenter/content/reference/ios/api
	cd devcenter; \
	git add content/reference/ios/*/*; \
	git commit -m "iOS Release Version $(VERSION)"; \
	git push origin master; \
	git push staging master; \
	git push production master

deploy-cocoapods:
	cd ..; \
	pod trunk push KinveyKit.podspec --verbose
	
show-version:
	@cat README.md | grep 'KinveyKit ([0-9]*.[0-9]*.[0-9]*, \w* [0-9]* [0-9]*)' | awk {'print $$2'} | sed 's/[(,]//g' | xargs echo 'README.md        '
	@cat KinveyKit/KinveyVersion.h | grep '#define __KINVEYKIT_VERSION__ @"[0-9]*.[0-9]*.[0-9]*"' | awk {'print $$3'} | sed 's/[@"]//g' | xargs echo 'KinveyVersion.h  '
	@/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${PWD}/KinveyKit/Info.plist" | xargs echo 'Info.plist       '
	@cat ../KinveyKit.podspec | grep "s.version          = \"[0-9]*.[0-9]*.[0-9]*\"" | awk {'print $$3'} | sed 's/"//g' | xargs echo 'KinveyKit.podspec'
	@agvtool what-version | awk '0 == NR % 2' | awk {'print $1'} | xargs echo 'Project Version  '
	
set-version:
	@echo 'Current Version:'
	@echo '----------------------'
	@$(MAKE) show-version
	
	@echo
	
	@echo 'New General Version: (Example: 1.xx.x)'
	@read version; \
	\
	echo 'New Project Version: (Example: 1.xxx)'; \
	read project_version; \
	\
	sed -i -e s/KinveyKit\ \([0-9]*.[0-9]*.[0-9]*,\ [a-zA-Z]*\ [0-9]*\ [0-9]*\)/KinveyKit\ \($$version,\ $(shell date '+%B\ %d\ %Y')\)/g README.md; \
	rm README.md-e; \
	\
	sed -i -e "s/#define __KINVEYKIT_VERSION__ @\"[0-9]*.[0-9]*.[0-9]*\"/#define __KINVEYKIT_VERSION__ @\"$$version\"/g" KinveyKit/KinveyVersion.h; \
	rm KinveyKit/KinveyVersion.h-e; \
	\
	/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $$version" "${PWD}/KinveyKit/Info.plist"; \
	\
	sed -i -e "s/s.version          = \"[0-9]*.[0-9]*.[0-9]*\"/s.version          = \"$$version\"/g" ../KinveyKit.podspec; \
	rm ../KinveyKit.podspec-e; \
	\
	agvtool new-version $$project_version > /dev/null

	@echo
	@echo

	@echo 'New Version:'
	@echo '----------------------'
	@$(MAKE) show-version

clean:
	rm -Rf $(OUTPUT_FOLDER)
	rm -Rf doc
