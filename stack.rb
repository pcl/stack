#!/usr/bin/env ruby
require 'rubygems'
require 'pp'
require 'json'
require 'uuid'

def help
  puts <<HELP
Usage: stack command [arguments]

Commands:
  help                  show this help message
  list                  list all items in the stack
  push <description>    add a new item to the stack
  pop                   remove the most-recent item from the stack
  drop <index>          remove the specified item from the stack
  touch <index>         move the specified item to the top of the stack"
HELP
end

def datadir
  dropbox = "#{ENV['HOME']}/Dropbox"
  winDropbox = "#{ENV['HOME']}/My Dropbox"
  if File.directory?(dropbox)
    data = "#{dropbox}/.stack-data"
  elsif File.directory?(winDropbox)
    data = "#{winDropbox}/.stack-data"
  end

  if !File.directory?(data)
    puts "Creating stack data dir at #{data}"
    Dir.mkdir(data)
  end
  return data
end

class Record
  attr_accessor :id
  attr_accessor :description
  attr_accessor :last_activity

  def initialize(description)
    @id = UUID.new.generate
    @description = description
    @last_activity = now
  end

  def self.load(file)
    text = File.read(file)
    json = JSON.parse(text)
    record = Record.new(json['description'])
    record.id = json['id']
    record.last_activity = json['last_activity']
    return record
  end

  def to_json
    json = {}
    self.instance_variables.each do |var|
      key = var[1..-1]
      json[key] = self.instance_variable_get(var.to_sym)
    end
    JSON.unparse(json)
  end

  def store
    File.open(path, "w") do |file|
      file.write(to_json)
    end
  end

  def delete
    File.delete(path)
  end

  def path
    File.join(DATADIR, @id)
  end

  def touch
    @last_activity = now
  end
end

def load_records
  records = []
  Dir.foreach(DATADIR) do |file|
    # Bafflingly, on Windows, char literal comparison fails.
    if file[0] != '.' && file[0] != 46  # 46: decimal value of '.'
      records.push(Record.load(File.join(DATADIR, file)))
    end
  end
  records.sort { |a, b| a.last_activity <=> b.last_activity }
end

def list
  records = load_records()
  reversed = records.reverse
  reversed.each { |r| puts "#{records.index(r) + 1}. #{r.description}" }
end

def push(description)
  record = Record.new(description)
  record.store
end

def pop
  records = load_records
  record = records.last
  record.delete
end

# drops the 1-based index from the list
def drop(index)
  records = load_records
  record = records[index - 1]
  record.delete
end

# moves the 1-based index to the top of the list
def touch(index)
  records = load_records
  record = records[index - 1]
  record.touch
  record.store
end

def now()
  Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
end

def assert_arg_count(args, count)
  if args.count != count
    throw "expected exactly one index argument; got #{args.count}"
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
      return 0

    when :list
      assert_arg_count(args, 0)
      list
      return 0

    when :push
      if args.count == 0
        throw "expected an item description"
      end
      push(args.join(' '))
      return 0

    when :pop
      assert_arg_count(args, 0)
      pop
      return 0

    when :drop
      assert_arg_count(args, 1)
      drop(args[0].to_i)
      return 0

    when :touch
      assert_arg_count(args, 1)
      touch(args[0].to_i)
      return 0
  end

  help
  return -1
end


DATADIR = datadir()
statusCode = run(ARGV.clone)
exit(statusCode)
