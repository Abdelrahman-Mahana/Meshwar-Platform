{ pkgs, ... }: {
  channel = "stable-23.11";

  packages = [
    pkgs.flutter
    pkgs.jdk17
    pkgs.nodejs_20
  ];

  env = {};

  idx = {
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
    ];

    workspace = {
      onCreate = {
        flutter-pub-get = "flutter pub get";
      };
    };

    previews = {
      enable = true;
      previews = {
        web = {
          command = [ "flutter" "run" "-d" "web-server" "--web-port" "$PORT" "--web-hostname" "0.0.0.0" ];
          manager = "flutter";
        };
      };
    };
  };
}
