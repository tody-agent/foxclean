cask "foxclean" do
  version "1.0.0"
  sha256 "761daac09a044cba84426d6b30beb75795b1f4e898a1a4ba8b6eff83e9ec5670"

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
