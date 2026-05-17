cask "foxclean" do
  version "1.0.0"
  sha256 "9924a514b3c9ce97890fee56f692cb88f86e49dd4c38dcf4c56358f5b21d03e6"

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
