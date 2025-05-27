#!/usr/bin/env ruby

# frozen_string_literal: true

# Usage
#
# ./this OUTPUT
#
# Generate the combine anti-ad blocklist for dnscrypt-proxy

require "reinbow"
require "pathname"
require "json"
require "uri"
require "open-uri"

using Reinbow

OUTPUT =
    ( ARGV.shift or abort "Expect one argument" )
        .then { Pathname.new it }

puts "Output path: #{OUTPUT}"

SKK_LIST = "https://ruleset.skk.moe/sing-box/domainset/reject.json"

# Too long to put in one line w/o linewrap
ANTIAD_LIST =
    "anti-ad-domains.txt"
        .then { "privacy-protection-tools/anti-AD/master/#{it}" }
        .then { "https://raw.githubusercontent.com/#{it}" }

ADGUARD_LIST =
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt"

# rubocop:disable Style/MutableConstant
RULES = []
# rubocop:enable Style/MutableConstant

puts "Processing Skk list".yellow

# rubocop:disable Security/Open
URI.open( SKK_LIST ) do |resp|
    json = resp.read.then { JSON.parse it }

    abort "This tool only supports version 2" \
        if json["version"] != 2

    rules = json["rules"][0] or abort "Failed to grab rules field"

    # a.com -> =a.com
    rules["domain"]
        # .map { "=#{it}" }
        .then { RULES.concat it }

    # a.com -> a.com
    rules["domain_suffix"]
        .then { RULES.concat it }

    # a -> *a*
    rules["domain_keyword"]
        .map { "*#{it}*" }
        .then { RULES.concat it }
end
# rubocop:enable Security/Open

puts "Process anti-ad list".yellow

# rubocop:disable Security/Open
URI.open( ANTIAD_LIST ) do |resp|
    resp.read
        .lines( chomp: true )
        .reject { it.start_with? "#" } # comment
        .then { RULES.concat it }
end
# rubocop:enable Security/Open
#
puts "Process AdGuard list".yellow

# rubocop:disable Security/Open
URI.open( ADGUARD_LIST ) do |resp|
    resp.read
        .lines( chomp: true )
        .grep_v( /^(#|!)/ ) # comment
        .grep_v( %r{^/} ) # regex, not supported
        .grep_v( /^@/ ) # unblock, not supported
        .map { it.delete_prefix "||" } # || means including subdomain
        .map { it.gsub( /\^(.*)$/, "" ) } # ^ marks ending
        .grep_v( /\p{Number}$/ ) # IPs, no tld ends with number
        .grep_v( /^\|/ ) # positional, not supported
        .then { RULES.concat it }
end
# rubocop:enable Security/Open

puts "Write output".yellow

p RULES.size
p RULES.uniq.size

OUTPUT.open( "w" ) do |f|
    f.puts RULES.uniq.join "\n"
    f.flush
end
