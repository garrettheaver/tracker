require 'sequel'

db = Sequel.sqlite(File.expand_path(
  '../../entries.db', __FILE__))

unless db.table_exists?(:tasks)
  db.create_table :tasks do
    primary_key :id
    Integer :hotkey, unique: true, null: true
    String :name, null: false
  end
end

unless db.table_exists?(:entries)
  db.create_table :entries do
    primary_key :id
    foreign_key :task_id, :tasks, null: false
    DateTime :started_at, null: false
    DateTime :stopped_at, null: true
    index [:task_id, :started_at]
  end
end

class Task < Sequel::Model

  one_to_many :entries

  # Calculates the number of seconds which have been spent
  # on this task. Several pre-defined time-frames are
  # available.

  def elapsed(from = :total, upto = nil)
    today = Date.today
    monday = today - ((today.wday - 1) % 7)

    dataset =
      case from
      when :total
        entries
      when :this_month
        entries_dataset.between(today - today.day + 1,
          Date.new(today.year, today.month + 1, 1))
      when :last_week
        entries_dataset.between(monday - 7, monday)
      when :this_week
        entries_dataset.between(monday, monday + 7)
      when :yesterday
        entries_dataset.between(today - 1, today)
      when :today
        entries_dataset.between(today, today + 1)
      else
        entries_dataset.between(from, upto)
      end

    dataset.inject(0) { |t,e| t + e.seconds }
  end

end

class Entry < Sequel::Model

  many_to_one :task

  class << self
    def start(task)
      Entry.create(task: task, started_at: Time.now)
    end
  end

  def_dataset_method(:between) do |s,e|
    where { started_at >= s.to_time }.
      and { started_at < e.to_time }
  end

  def_dataset_method(:ephemeral) do
    where { (Sequel.function(:strftime, "%s", stopped_at) -
             Sequel.function(:strftime, "%s", started_at)) < 60 }
  end

  # Causes this entry to mark itself as complete at the time
  # of method calling. If the entry is less than 120 seconds
  # old we consider it meaningless overall and delete it.

  def stop!(ts = Time.now)
    update(stopped_at: ts)
    delete if seconds < 120
    nil
  end

  def seconds
    ((stopped_at ? stopped_at : Time.now) - started_at).round
  end

end

