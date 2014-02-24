require 'cinch'
require 'open-uri'
require 'nokogiri'
require 'cgi'

class HelloBot
  include Cinch::Plugin
  USAGE = "Says hello"
  match "hello"

  def execute(m)
    m.reply "Hello, #{m.user.nick} - how are you?"
  end
end

class Echo
  include Cinch::Plugin
  match /echo (.*)/
  USAGE = "Echoes text back to you. Example: !echo You are so funny."

  def execute(msg, text)
    msg.reply(text)
  end
end

class Version
  include Cinch::Plugin
  USAGE = "Show bsdhorse version and license information"

  match "version"
  def execute(m)
    m.reply "I am bsdhorse IRC bot v0.0.1 (licensed under the beerware license)"
  end
end

class Google
  include Cinch::Plugin
  match /google (.+)/

  USAGE = "I can google something for you. Example: !google freebsd"

  def search(query)
    url = "http://www.google.com/search?q=#{CGI.escape(query)}"
    res = Nokogiri::HTML(open(url)).at("h3.r")
    puts res
    title = res.text
    link = res.at('a')[:href]
    desc = res.at("./following::div").children.first.text
    CGI.unescape_html "#{title} - #{desc} (#{link})"
  rescue
    "I couldn't find any results, sorry mate."
  end

  def execute(m, query)
    m.reply(search(query))
  end
end


class Seen

  class SeenStruct < Struct.new(:who, :where, :what, :time)
    def to_s
      "[#{time.asctime}] #{who} was seen in #{where} saying #{what}"
    end
  end

  include Cinch::Plugin
  USAGE = "Ask when someone was last seen. Example !seen aje"
  listen_to :channel
  match /seen (.+)/
  
  def initialize(*args)
    super
    @users = {}
  end

  def listen(m)
    @users[m.user.nick] = SeenStruct.new(m.user, m.channel, m.message, Time.now)
  end

  def execute(m, nick)
    if nick == @bot.nick
      m.reply "That's me!"
    elsif nick == m.user.nick
      m.reply "That's you!"
    elsif @users.key?(nick)
      m.reply @users[nick].to_s
    else
      m.reply "I haven't seen #{nick}"
    end
  end
end

class Help
  include Cinch::Plugin
  USAGE = "Meta meta meta"
  match /help(?: (\S+))?/
  def execute(m, command)
    usage = case command
            when 'choose' then Choose::USAGE
            when 'seen' then Seen::USAGE
            when 'google' then Google::USAGE
            when 'hello' then HelloBot::USAGE
            when 'version' then Version::USAGE
            when 'echo' then Echo::USAGE
            else
              "I only obey the following commands preceded by '!': choose, seen, google, hello, version, echo"
            end
    m.reply(usage)
  end
end


class Choose
  include Cinch::Plugin
  USAGE = "Allow me to make a decision for you. Example: !choose several, comma separated, things"
  match /choose (.+)/
  def execute(m, list)
    items = list.split ','
    m.channel.action "I reached into the bag and pulled out.... #{items.sample.strip}."
  end
end


bot = Cinch::Bot.new do
  configure do |c|
    c.nick = 'bsdhorse'
    c.server = 'irc.oz.org' 
    c.channels = [ "#bugs" ]
    c.plugins.plugins = [HelloBot, Seen, Google, Version, Echo, Choose, Help]
  end
end

bot.start
