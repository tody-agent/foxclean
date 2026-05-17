cask "foxclean" do
  version "1.0.0"
  sha256 "0080a4d9d66f17b58d52cf01edf4c036dd0ccce427b2db3f7fa259835ffaf49c"

  url "https://github.com/foxclean/foxclean/releases/download/v#{version}/FoxClean-#{version}.dmg"
  name "FoxClean"
  desc "Free, telemetry-free macOS cleaner with native GUI and CLI"
  homepage "https://github.com/foxclean/foxclean"

  app "FoxClean.app"
  binary "#{appdir}/FoxClean.app/Contents/Resources/fox"

  zap trash: [
    "~/Library/Application Support/FoxClean",
    "~/Library/Caches/dev.foxclean.app",
    "~/Library/Logs/FoxClean",
    "~/Library/Preferences/dev.foxclean.app.plist",
  ]
end
