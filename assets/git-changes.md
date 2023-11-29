If you see this message it means that you didn't run build.sh to produce this build, instead you have probably just executed flutter build apk. This is fine but version information is missing.


$ p3pgo 

--------

On branch master
Your branch is up to date with 'origin/master'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   Makefile

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	p3pgo-0.8.f5f6770-dirty14.tar.gz

--------------------------------------------------
Changes not staged for commit:
diff --git i/Makefile w/Makefile
index 600255c..d2607ee 100644
--- i/Makefile
+++ w/Makefile
@@ -4,6 +4,8 @@ ANDROID_ARM64 := "aarch64-linux-android21-clang"
 ANDROID_386 := "i686-linux-android21-clang"
 ANDROID_AMD64 := "x86_64-linux-android21-clang"
 
+all: clean c_api_android c_api_linux
+
 c_api:
 	rm -rf build/api.so || true
 	mkdir -p build || true
@@ -15,7 +17,14 @@ c_api_android:
 	CGO_ENABLED=1 CC=${NDK_HOME}/${ANDROID_386} CXX=${NDK_HOME}/${ANDROID_386}++ GOOS=android GOARCH=386 go build -v -buildmode=c-shared -o build/api_android_x86.so .
 	CGO_ENABLED=1 CC=${NDK_HOME}/${ANDROID_AMD64} CXX=${NDK_HOME}/${ANDROID_AMD64}++ GOOS=android GOARCH=amd64 go build -v -buildmode=c-shared -o build/api_android_x86_64.so .
 
+c_api_linux:
+	CGO_ENABLED=1 CC=i686-linux-gnu-gcc CXX=i386-linux-gnu-g++ GOOS=linux GOARCH=386 go build -v -buildmode=c-shared -o build/api_linux_i386.so .
+	CGO_ENABLED=1 CC=x86_64-linux-gnu-gcc CXX=x86_64-linux-gnu-g++ GOOS=linux GOARCH=amd64 go build -v -buildmode=c-shared -o build/api_linux_amd64.so .
+	CGO_ENABLED=1 CC=arm-linux-gnueabihf-gcc CXX=arm-linux-gnueabihf-g++ GOOS=linux GOARCH=arm go build -v -buildmode=c-shared -o build/api_linux_armhf.so .
+	CGO_ENABLED=1 CC=aarch64-linux-gnu-gcc CXX=aarch64-linux-g++ GOOS=linux GOARCH=arm64 go build -v -buildmode=c-shared -o build/api_linux_aarch64.so .
+
+
 clean:
 	rm -rf build
 
-.PHONY: c_api clean c_api_android
\ No newline at end of file
+.PHONY: c_api clean c_api_android c_api_linux
\ No newline at end of file
no changes added to commit (use "git add" and/or "git commit -a")
