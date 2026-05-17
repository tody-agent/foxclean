cask "foxclean" do
  version "1.0.0"
  sha256 "ca787b5ab00ec6ff52ae2840fd19ea1b5e00e1c0ea81b4b8e21f39c61e23c724"

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
