require "awesome_print"
require "nokogiri"
require "open-uri"

class Object;   def try(name); send(name); end; end
class NilClass; def try(name); self; end; end

puts "Enter character name (Illidan assumed)"
name = gets
puts "...retrieving data for #{name}"

page        = Nokogiri::HTML(open("http://www.wow-heroes.com/get_char.php?zone=us&server=Illidan&name=#{name.chomp}&live=1"))
Boss        = Struct.new(:pretty_name, :regex_name)
Ranking     = Struct.new(:mode, :boss_id, :spec, :rank)
BossRanking = Struct.new(:boss_name, :ranks)

puts "...data retrieved, live as of #{Time.now}"

boss_id_hash = {
  "60009" => "Feng the Accursed",
  "60047" => "Amethyst Guardian",
  "60143" => "Gara'jal the Spiritbinder",
  "60400" => "Jan-xi",
  "60410" => "Elegon",
  "60583" => "Protector Kaolan",
  "60999" => "Sha of Fear",
  "61421" => "Zian of the Endless Shadow",
  "62442" => "Tsulong",
  "62837" => "Grand Empress Shek'zeer",
  "62983" => "Lei Shi",
  "63664" => "Blade Lord Ta'yak",
  "63666" => "Amber-Shaper Un'sok",
  "63667" => "Garalon",
  "65501" => "Wind Lord Mel'jarak",
  "66791" => "Imperial Vizier Zor'lok",
  "67977" => "Tortos",
  "68036" => "Durumu the Forgotten",
  "68065" => "Megaera",
  "68078" => "Iron Qon",
  "68397" => "Lei Shen",
  "68476" => "Horridon",
  "68905" => "Lu'lin",
  "69017" => "Primordius",
  "69078" => "Sul the Sandcrawler",
  "69427" => "Dark Animus",
  "69465" => "Jin'rokh the Breaker",
  "69712" => "Ji-Kun"
}

dungeons = {
  "Mogushan Vaults (Part 1)" => [
    Boss.new("Dogs", /guardian/i),
    Boss.new("Feng", /feng/i),
    Boss.new("Gara'jal", /gara'jal/i)
  ],
  "Mogushan Vaults (Part 2)" => [
    Boss.new("Kings", /zian/i),
    Boss.new("Elegon", /elegon/i),
    Boss.new("Twin Emps", /jan-xi/i)
  ],
  "Heart of Fear (Part 1)" => [
    Boss.new("Vizier", /imperial vizier/i),
    Boss.new("Blade Lord", /blade lord/i),
    Boss.new("Garalon", /garalon/i)
  ],
  "Heart of Fear (Part 2)" => [
    Boss.new("Wind Lord", /wind lord/i),
    Boss.new("Amber", /amber-shaper/i),
    Boss.new("Empress", /grand empress/i)
  ],
  "Terrace" => [
    Boss.new("Council", /protector/i),
    Boss.new("Tsulong", /tsulong/i),
    Boss.new("Lei Shi", /lei shi/i),
    Boss.new("Sha", /sha of fear/i)
  ],
  "Throne of Thunder (Part 1)" => [
    Boss.new("Jin'Rokh", /jin'rokh/i),
    Boss.new("Dino", /horridon/i),
    Boss.new("Council", /sandcrawler/i),
  ],
  "Throne of Thunder (Part 2)" => [
    Boss.new("Tortos", /tortos/i),
    Boss.new("Megaera", /megaera/i),
    Boss.new("Ji-Kun", /ji-kun/i),
  ],
  "Throne of Thunder (Part 3)" => [
    Boss.new("Durumu", /durumu/i),
    Boss.new("Primordius", /primordius/i),
    Boss.new("Dark Animus", /dark animus/i),
  ],
  "Throne of Thunder (Part 4)" => [
    Boss.new("Iron Qon", /iron qon/i),
    Boss.new("Fire and Ice Bitch", /lu'lin/i),
    Boss.new("Lei Shen", /lei shen/i)
  ]
}

rankings    = page.css(".wolranklist div.dragon-bg").map do |div|
  Ranking.new(
    { "lfr" => "LFR", "silver" => "N", "gold" => "HM" }[div.attr("class").split(/\s+/).find { |klass| klass =~ /d-/ }.gsub(/d-/, "")],
    div.at_css(".wolbossicons").attr("class").split(/\s+/).find { |klass| klass =~ /boss-/ }.gsub(/boss-/, ""),
    div.at_css(".wolspecicon").attr("class").split(/\s+/)[-1].split(/-/)[-1],
    div.at_css(".raidrankpos").text.to_i
  )
end

ordered_ranks = rankings.group_by(&:spec).map do |spec, spec_ranks|
  {
    spec: spec,
    boss_ranks: spec_ranks.group_by(&:boss_id).map do |boss_id, boss_ranks|
      BossRanking.new(
        boss_id_hash[boss_id],
        boss_ranks.sort { |a, b| %w|LFR N HM|.index(a) <=> %w|LFR N HM|.index(b) }
      )
    end
  }
end

puts "\n"

ordered_ranks.sort_by { |i| i[:spec] }.each do |hash|
  puts hash[:spec].upcase.split(//).join(" ")
  puts "-" * 50

  dungeons.each do |dungeon_name, bosses|
    puts "%-25s\t%s\t%s\t%s" % ([dungeon_name] + %w|LFR N HM|)

    bosses.each do |boss|
      if boss_ranks = hash[:boss_ranks].find { |boss_rank| boss_rank.boss_name =~ boss.regex_name }
        puts "%-25s\t%s\t%s\t%s" % [
          boss.pretty_name,
          boss_ranks.ranks.find { |ranking| ranking.mode == "LFR" }.try(:rank) || ?-,
          boss_ranks.ranks.find { |ranking| ranking.mode == "N" }.try(:rank)   || ?-,
          boss_ranks.ranks.find { |ranking| ranking.mode == "HM" }.try(:rank)  || ?-
        ]
      else
        puts "%-25s\t%s\t%s\t%s" % ([boss.pretty_name] + [?-] * 3)
      end
    end

    puts
  end
end && nil
