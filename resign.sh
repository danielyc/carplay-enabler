#!/bin/zsh
# https://fotidim.com/carplay-apps-without-entitlements-in-an-actual-car-37a708758262

if [ -z "$1" ]
	then
		echo "$0 [ipa/app file to enable carplay on]"
		exit 1
fi

mkdir temp
cd temp

if [[ $1 == *.app ]]; then
	echo "Generating ipa structure"
	mkdir Payload
	cp -r ../$1 Payload/
else
	echo "Extracting ipa"
	unzip -q ../$1
fi

app=$(ls Payload/)

echo "Found $app"

if [ -f "Payload/$app/embedded.mobileprovision" ]; then
	echo "Merging entitlements"

	security cms -D -i "Payload/$app/embedded.mobileprovision" > provision.plist
	/usr/libexec/PlistBuddy -x -c 'Print:Entitlements' provision.plist > entitlements.plist
	/usr/libexec/PlistBuddy -x -c "Merge ../CarPlay.entitlements" entitlements.plist

	echo "Signing with CarPlay entitlement"
	uname=$(id -un)
	codesign -d --entitlements entitlements.plist -f -s "Apple Development: $uname" Payload/$app

	signed=$(codesign -d --entitlements - "Payload/$app" | grep -c "com.apple.developer.carplay-maps")
	if [ $signed > 0 ]; then
		echo "Signed succesfully!"
		zip -r "$app.ipa" Payload -q
		cp "$app.ipa" ../		
	else
		echo "Failed to sign!"
		exit 1
	fi

else
	echo "Generating entitlement"
	uname=$(id -un)
	codesign -d --entitlements ../CarPlay.entitlements -f -s "Apple Development: $uname" Payload/$app
	signed=$(codesign -d --entitlements - "Payload/$app" | grep -c "com.apple.developer.carplay-maps")
	if [ $signed > 0 ]; then
		echo "Signed succesfully!"
		zip -r "$app.ipa" Payload -q
		cp "$app.ipa" ../		
	else
		echo "Failed to sign!"
		exit 1
	fi
fi

cd ..
echo "Cleaning temporary files"
rm -rf temp
