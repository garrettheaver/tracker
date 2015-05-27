require_relative "./lib/models"

EXIT = 0
MAKE = 99

def print_tasks
  system 'clear'

  print "Current Task: %s\n\n" % [@entry ? @entry.task.name : "None"]
  print "Switch To:\n\n"

  Task.exclude(hotkey: nil).order(:hotkey).each do |t|
    today = Time.at(t.elapsed(:today)).utc.strftime("%H:%M")
    puts "%3d. (%s) %s" % [t.hotkey, today, t.name]
  end

  print "\n> "
end

def make_task
  print "New Task Name: "
  name = gets.chomp

  print "Assign Hotkey: "
  hotkey = gets.chomp.to_i
  hotkey = nil if [EXIT, MAKE].include?(hotkey)

  Task.where(hotkey: hotkey).update(hotkey: nil)
  Task.create(name: name, hotkey: hotkey)
end

def repl
  @entry = nil

  print_tasks

  while(EXIT != (i = gets.to_i)) do
    @entry.stop! if @entry

    task = MAKE == i ? make_task : Task.where(hotkey: i).first
    @entry = Entry.start(task)

    print_tasks
  end

  @entry.stop! if @entry
end

repl

