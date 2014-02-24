require 'cinch'
require 'open-uri'
require 'nokogiri'
require 'cgi'

class HelloBot
  include Cinch::Plugin
  match "hello"

  def execute(m)
    m.reply "Hello, #{m.user.nick} - how are you?"
  end
end

class Version
  include Cinch::Plugin
  match "version"
  def execute(m)
    m.reply "I am bsdhorse IRC bot v0.0.1 (licensed under the beerware license)"
  end
end

class Google
  include Cinch::Plugin
  match /google (.+)/

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

bot = Cinch::Bot.new do
  configure do |c|
    c.nick = 'bsdhorse'
    c.server = 'irc.oz.org' 
    c.channels = [ "#bugs" ]
    c.plugins.plugins = [HelloBot, Seen, Google, Version]
  end
end

bot.start
