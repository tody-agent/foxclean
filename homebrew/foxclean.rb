cask "foxclean" do
  version "1.0.0"
  sha256 "58894cf9a7658a8e9bfe14e6ceef330f3726a89eb7cc6d8bfab9d04558e192dc"

  url "https://github.com/tody-agent/foxclean/releases/download/v#{version}/FoxClean-#{version}.dmg"
  name "FoxClean"
  desc "Free, telemetry-free macOS cleaner with native GUI and CLI"
  homepage "https://github.com/tody-agent/foxclean"

  app "FoxClean.app"
  binary "#{appdir}/FoxClean.app/Contents/Resources/fox"

  zap trash: [
    "~/Library/Application Support/FoxClean",
    "~/Library/Caches/dev.foxclean.app",
    "~/Library/Logs/FoxClean",
    "~/Library/Preferences/dev.foxclean.app.plist",
  ]
end
