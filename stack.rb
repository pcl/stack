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
  drop <index>          remove the specified item from the stack
  touch <index>         move the specified item to the top of the stack"
HELP
end

def load_records
  records = []
  Dir.foreach(DATADIR) do |file|
    if file[0] != '.'
      records.push(JSON.parse(File.read(File.join(DATADIR, file))))
    end
  end
  records.sort { |a, b| a['last_activity'] <=> b['last_activity'] }
end

def list
  records = load_records()
  reversed = records.reverse
  reversed.each { |r| puts "#{records.index(r) + 1}. #{r['description']}" }
end

def store(record)
  File.open(File.join(DATADIR, record['id']), "w") do |file|
    file.write(JSON.unparse(record))
  end
end

def push(description)
  id = `uuidgen`.strip
  record = { 'id' => id, 'last_activity' => Time.now, 'description' => description }
  store(record)
end

def pop
  records = load_records
  record = records.last
  File.delete(File.join(DATADIR, record['id']))
end

# drops the 1-based index from the list
def drop(index)
  records = load_records
  record = records[index - 1]
  File.delete(File.join(DATADIR, record['id']))
end

# moves the 1-based index to the top of the list
def touch(index)
  records = load_records
  record = records[index - 1]
  record['last_activity'] = Time.now
  store(record)
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

    when :list
      assert_arg_count(args, 0)
      list

    when :push
      if args.count == 0
        throw "expected an item description"
      end
      push(args.join(' '))

    when :pop
      assert_arg_count(args, 0)
      pop

    when :drop
      assert_arg_count(args, 1)
      drop(args[0].to_i)

    when :touch
      assert_arg_count(args, 1)
      touch(args[0].to_i)
  end

  return 0
end

exit(run(ARGV.clone))