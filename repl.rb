require_relative "./lib/models"
require "colorize"

EXIT = 0
HOUR = 60 * 60

def strftime(seconds)
  if seconds > 24 * HOUR
    "%2d:%2d" % [seconds / HOUR, (seconds % HOUR) / 60]
  else
    Time.at(seconds).utc.strftime("%H:%M")
  end
end

def print_tasks
  system 'clear'
  print "Current Task: %s\n" % [@entry ? @entry.task.name.yellow : "None".red]

  today = Date.today
  total = Entry.between(today, today + 1).inject(0){ |t,e| t + e.seconds }
  print "Tracked Today: %s\n\n" % [strftime(total).green]

  print "Switch To:\n\n"

  Task.exclude(hotkey: nil).order(:hotkey).each do |t|
    puts "%3d. %s %s" % [t.hotkey, strftime(t.elapsed(:today)).blue, t.name]
  end

  print "\n> "
end

def print_stats
  system 'clear'
  print "Stats for all Tasks:\n\n"

  scales = { today: :blue, yesterday: :cyan, this_week: :yellow, last_week: :green }

  # calculate and display a total for each scale column

  totals = scales.map do |k,v|
    strftime(Task.inject(0) { |n,t| n + t.elapsed(k) }).send(v)
  end

  puts "%4s %s %s %s %s\n\n" % ([''] + totals)

  # next output the tasks which have been assigned a hotkey in numeric order

  Task.exclude(hotkey: nil).order(:hotkey).each do |t|
    vals = scales.map { |k,v| strftime(t.elapsed(k)).send(v) }
    puts "%3s. %s %s %s %s %s" % ([t.hotkey] + vals + [t.name])
  end

  print "\n"

  # finally output the non hotkey tasks in simple name order

  Task.where(hotkey: nil).order(:name).each do |t|
    vals = scales.map { |k,v| strftime(t.elapsed(k)).send(v) }
    puts "%4s %s %s %s %s %s" % ([''] + vals + [t.name])
  end

  gets
end

def make_task
  print "New Task Name: "
  name = gets.chomp

  print "Assign Hotkey: "
  hotkey = gets.chomp.to_i
  hotkey = nil if [EXIT].include?(hotkey)

  Task.where(hotkey: hotkey).update(hotkey: nil)
  Task.create(name: name, hotkey: hotkey)
end

def stop_current_task!
  @entry = @entry.stop! if @entry
end

def repl
  @entry = nil

  print_tasks

  loop do

    c = gets.chomp

    case c
    when "0"
      stop_current_task!
    when "q"
      stop_current_task!
      break
    when "n"
      stop_current_task!
      @entry = Entry.start(make_task)
    when "s"
      print_stats
    else
      stop_current_task!
      task = Task.where(hotkey: c.to_i).first
      @entry = Entry.start(task) if task
    end

    print_tasks

  end

  @entry
end

repl

