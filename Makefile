VERSION=1.0.0

.PHONY: version
version:
	sed -i "s/^version: .*/version: ${VERSION}+$(shell git rev-list --count HEAD)/" "pubspec.yaml"
	-sed -i "s/^  Version: .*/  Version: ${VERSION}+$(shell git rev-list --count HEAD)/" "debian/debian.yaml"
	-sed -i "s/^Version=.*/Version=${VERSION}+$(shell git rev-list --count HEAD)/" "debian/gui/anonero.desktop"

apk:
	flutter build apk --dart-define="P3PCH4T_VERSION=${VERSION}+$(shell git rev-list --count HEAD)"