#!/usr/bin/env ruby
require 'pp'
require 'json'

DATADIR="#{ENV['HOME']}/Dropbox/stack-data"

def help
  puts <<HELP
Usage: stack command [arguments]

Commands:
  help                  show this help message
  list                  list all items in the stack
  push <description>    add a new item to the stack
  pop                   remove the most-recent item from the stack
  drop <index>          remove the specified item from the stack"
HELP
end

def list
  records = []
  Dir.foreach(DATADIR) do |file|
    if file[0] != '.'
      records.push(JSON.parse(File.read(File.join(DATADIR, file))))
    end
  end
  records = records.sort { |a, b| a['last_activity'] <=> b['last_activity'] }
  reversed = records.reverse
  reversed.each { |r| puts "#{records.index(r) + 1}. #{r['description']}" }
end

def push(description)
  id = `uuidgen`.strip
  record = { :id => id, :last_activity => Time.now, :description => description }
  File.open(File.join(DATADIR, id), "w") do |file|
    file.write(JSON.unparse(record))
  end
end

def run(args)
  if args.count == 0
    help
    return -1
  end

  command = args.shift.to_sym

  case command
    when :help
      help

    when :list
      list

    when :push
      push(args.join(' '))

    when :pop
      pp "pop #{args}"

    when :drop
      pp "drop #{args}"
  end

  return 0
end

exit(run(ARGV.clone))