#!/usr/bin/env ruby
require 'rubygems'
require 'pp'
require 'json'
require 'uuid'

def help
  puts <<HELP
Usage: stack command [arguments]

Commands:
  help                  Show this help message.

  list                  List items in the stack.

  push <description>    Add a new item to the stack.
  pop                   Remove the most-recent item from the stack.
  drop <index>          Remove the specified item from the stack.
  touch <index>         Move the specified item to the top of the stack.

  tag <index> <tag>     Add the specified tag to the specified item.
  tag <index> -<tag>    Remove the specified tag from the specified item.

  archive <index>       Move the item to the archive. See 'list' behavior below.
  archive list          List the archived items, ordered by date last touched.
  archive clear         Clear the archive."
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
  attr_accessor :tags
  attr_accessor :archived

  def initialize(description)
    @id = UUID.new.generate
    @description = description
    @last_activity = now
    @tags = []
    @archived = false
  end

  def self.load(file)
    text = File.read(file)
    json = JSON.parse(text)
    record = Record.new(json['description'])
    record.id = json['id']
    record.last_activity = json['last_activity']
    record.tags = json['tags']
    record.archived = json['archived'] || false
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

  def add_tag(tag)
    if !@tags.include?(tag)
      @tags.push(tag)
    end
  end

  def remove_tag(tag)
    @tags.delete(tag)
  end

  def has_tag?(tag)
    @tags != nil && @tags.include?(tag)
  end

  def self.load_all_records(dir)
    records = []
    Dir.foreach(dir) do |file|
      # Bafflingly, on Windows, char literal comparison fails.
      if file[0] != '.' && file[0] != 46  # 46: decimal value of '.'
        records.push(Record.load(File.join(dir, file)))
      end
    end
    records.sort { |a, b| a.last_activity <=> b.last_activity }
  end

  def self.load_records(dir, archived)
    records = load_all_records(dir)
    return records.select { |r| r.archived == archived }
  end
end

def list(archived)
  records = Record.load_records(DATADIR, archived)
  reversed = records.reverse
  reversed.each do |r|
    if !archived
      str = "#{records.index(r) + 1}. "
    else
      str = ""
    end
    str += r.description
    if r.tags != nil && r.tags.length > 0
      str += "   [#{r.tags.join(',')}]"
    end
    puts str
  end
end

def push(description)
  record = Record.new(description)
  record.store
end

def pop
  records = Record.load_records(DATADIR, false)
  record = records.last
  record.delete
end

# drops the 1-based index from the list
def drop(index)
  record = item(index)
  record.delete
end

# moves the 1-based index to the top of the list
def touch(index)
  record = item(index)
  record.touch
  record.store
end

def item(index)
  records = Record.load_records(DATADIR, false)
  records[index - 1]
end

def now()
  Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
end

def assert_arg_count(args, count)
  if args.count != count
    throw "expected exactly #{count} argument(s); got #{args.count}"
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
      list(false)
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

    when :tag
      assert_arg_count(args, 2)
      record = item(args[0].to_i)
      if args[1].start_with?("-")
        record.remove_tag(args[1][1..-1])
      else
        record.add_tag(args[1])
      end
      record.store
      return 0

    when :archive
      assert_arg_count(args, 1)
      if args[0].to_sym == :list
        list(true)
      elsif args[0].to_sym == :clear
        Record.load_records(DATADIR, true).each { |r| r.delete }
      else
        record = item(args[0].to_i)
        record.archived = true
        record.store
      end
      return 0

  end

  help
  return -1
end


DATADIR = datadir()
statusCode = run(ARGV.clone)
exit(statusCode)
