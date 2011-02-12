# Stack #

    "a last in, first out (LIFO) data structure" -- Wikipedia

Stack is a useful little shell script for maintaining a list 
of things you're working on. It stores its data files in 
Dropbox, so your stack will be in sync across multiple computers.

### Installation ###
    curl https://github.com/pcl/stack/raw/master/stack.rb > ~/bin/stack
    chmod u+x ~/bin/stack
    gem install uuid json

### Usage ###
+ Add some stuff to your stack
        $ stack push "fix that customer NPE"
        $ stack push finish up documentation
        $ stack push respond to Peter's email

+ View your stack
        $ stack list
        3. respond to Peter's email
        2. finish up documentation
        1. fix that customer NPE

+ Move something up to the top of the stack
        $ stack touch 2
        $ stack list
        3. fix that customer NPE
        2. respond to Peter's email
        1. finish up documentation

+ Remove something from the stack
        $ stack drop 1
        $ stack list
        2. fix that customer NPE
        1. respond to Peter's email

+ Remove the topmost item from the stack
        $ stack pop
        $ stack list
        1. respond to Peter's email

### Motivation and Design Focus ###
Stack is a lightweight personal productivity tool. I try to keep my
stack small, limited to just the items I'm working on actively. In 
other words, it's my "guilt backlog" -- the list of things that I'm 
juggling in my head all the time.

It is not a bugtracker, or a collaboration tool, or any of the many
things that proper products like JIRA or Basecamp are great at. I
have no plans to grow it into a full-fledged tool like those, although
a certain level of integration could be nice.

### Wishlist ###
+ classify stack items for easy contextual filtering (work, home, etc.)
+ attach data to stack items:
        $ git diff | stack attach 1
        $ stack list
        1. fix that customer NPE (attachments: a)
        $ stack cat 1a
        <diff output here>
        $ stack cat 1a | git apply
+ load all my assigned tasks from JIRA into stack items:
        $ stack remote add jira http://my.jira.install/query
        $ stack pull jira
  This really depends on figuring out a lightweight way to classify items,
  since I don't want to see billions of issues in my stack -- I've already
  got JIRA for that!

### Known Issues ###
+ stack assumes that your Dropbox folder is at ~/Dropbox

### Multi-computer Notes ###

Stack stores its data files in Dropbox, so your stack will be in
sync across multiple computers. The stack data is stored in 
~/Dropbox/stack-data. If your Dropbox folder is somewhere else,
you'll need to modify this script to use a different location,
or add support for configuration via an environment variable or
~/.stack file or something.

The format is designed to work properly even if you add or remove
items while your computer is offline, and move to a different 
computer before it gets a chance to sync up. Of course, you won't 
see your full set of changes until all the machines have a chance
to communicate with Dropbox.
