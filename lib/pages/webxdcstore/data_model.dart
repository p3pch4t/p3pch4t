class WebXDCStoreMetaJSON {
  WebXDCStoreMetaJSON.fromJson(Map<String, dynamic> json) {
    (json['apps'] as Map<String, dynamic>).forEach((key, value) {
      apps[key] = WebXDCApp.fromJson(value as Map<String, dynamic>);
    });
  }
  Map<String, WebXDCApp> apps = {};
}

class WebXDCApp {
  WebXDCApp.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        uniqueId = json['uniqueId'] as String,
        shortDescription = json['shortDescription'] as String,
        description = json['description'] as String,
        source = json['source'] as String,
        banner = json['banner'] as String,
        supportedRelease = (json['supportedReleases'] as List<dynamic>).cast() {
    (json['releases'] as Map<String, dynamic>).forEach((key, value) {
      releases[key] = WebXDCRelease.fromJson(value as Map<String, dynamic>);
    });
  }

  final String name;
  final String uniqueId;
  final String shortDescription;
  final String description;
  final String source;
  final String banner;
  final List<String> supportedRelease;
  Map<String, WebXDCRelease> releases = {};
}

class WebXDCRelease {
  WebXDCRelease.fromJson(Map<String, dynamic> json)
      : image = json['image'] as String,
        command = json['command'] as String,
        sourceTarball = json['sourceTarball'] as String,
        webXDCDownload = json['WebXDCDownload'] as String,
        xdcSha512Sum = json['xdcsha512sum'] as String,
        tarSha512Sum = json['tarsha512sum'] as String;
  final String image;
  final String command;
  final String sourceTarball;
  final String webXDCDownload;
  final String xdcSha512Sum;
  final String tarSha512Sum;
}
