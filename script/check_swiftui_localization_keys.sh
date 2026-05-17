#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ruby -rset -e '
  base_path = "FoxCleanApp/en.lproj/Localizable.strings"
  abort("missing base localization: #{base_path}") unless File.size?(base_path)

  base_keys = File.read(base_path).scan(/^\s*"((?:\\"|[^"])*)"\s*=/).flatten.to_set
  literals = Set.new
  patterns = [
    /\b(?:Text|Button|Label|Toggle|Picker|TableColumn|CommandMenu)\(\s*"((?:\\"|[^"])*)"/,
    /\.accessibility(?:Label|Hint)\(\s*"((?:\\"|[^"])*)"/,
    /confirmationDialog\(\s*"((?:\\"|[^"])*)"/
  ]

  Dir["FoxCleanApp/**/*.swift"].sort.each do |file|
    text = File.read(file)
    patterns.each do |pattern|
      text.scan(pattern) do |match|
        literal = match.fetch(0)
        next if literal.include?("\\(")
        next if literal.empty?
        literals << literal
      end
    end
  end

  missing = literals.reject { |literal| base_keys.include?(literal) }.sort
  unless missing.empty?
    warn "SwiftUI localization literals missing from #{base_path}:"
    missing.each { |literal| warn "  #{literal}" }
    exit 1
  end

  puts "SwiftUI localization key coverage passed for #{literals.size} literals."
'
