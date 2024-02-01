VERSION=1.0.0
P3PGO_VERSION=v1.0.0RC6
.PHONY: version
version:
	sed -i "s/^version: .*/version: ${VERSION}+$(shell git rev-list --count HEAD)/" "pubspec.yaml"
	-sed -i "s/^  Version: .*/  Version: ${VERSION}+$(shell git rev-list --count HEAD)/" "debian/debian.yaml"
	-sed -i "s/^Version=.*/Version=${VERSION}+$(shell git rev-list --count HEAD)/" "debian/gui/p3pch4t.desktop"

version_windows:
	powershell -Command "(Get-Content 'pubspec.yaml') -replace '^version: .*', 'version: 1.0.0+$(shell git rev-list --count HEAD)' | Set-Content 'pubspec.yaml'"

apk:
	flutter build apk --dart-define="P3PCH4T_VERSION=${VERSION}+$(shell git rev-list --count HEAD)"

exe:
	flutter build windows --dart-define="P3PCH4T_VERSION=${VERSION}+$(shell git rev-list --count HEAD)"
	powershell -Command "try { rm -ErrorAction stop -Force -Recurse .\build\windows\x64\runner\p3pch4t-win64-${VERSION}_$(shell git rev-list --count HEAD)  } catch [System.Management.Automation.ItemNotFoundException] { $$null }"
	powershell -Command "curl https://git.mrcyjanek.net/p3pch4t/p3pgo/releases/download/${P3PGO_VERSION}/win64_libp3pgo.dll.xz -O .\build\windows\x64\runner\Release\libp3pgo.dll.xz"
	C:\msys64\usr\bin\unxz.exe ./build/windows/x64/runner/Release/libp3pgo.dll.xz
	powershell -Command "mv .\build\windows\x64\runner\Release .\build\windows\x64\runner\p3pch4t-win64-${VERSION}_$(shell git rev-list --count HEAD)"
	powershell -Command "try { rm -ErrorAction stop -Force .\build\windows\x64\runner\p3pch4t-win64.zip } catch [System.Management.Automation.ItemNotFoundException] { $$null }" 
	powershell -Command "cd .\build\windows\x64\runner\ ; Compress-Archive -Path p3pch4t-win64-${VERSION}_$(shell git rev-list --count HEAD) -DestinationPath p3pch4t-win64.zip -Force"
	