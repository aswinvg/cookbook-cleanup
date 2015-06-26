require 'pathname'
require 'time'

SECONDS = {
  minutes: 60,
  hours: 3600,
  days: 86_400,
  weeks: 604_800
}

action :clean do
  files = Pathname.glob(new_resource.name)
  Chef::Log.debug "Found dirs: #{files.join(',')}"
  if new_resource.keep_last
    keep_last = new_resource.keep_last
    files.sort! { |x, y| y.lstat.ctime <=> x.lstat.ctime }
    files = files[keep_last..-1] || [] # The || is necessary in 1.8.7 but not 1.9
    Chef::Log.info "Cleaning up: #{files.join(',')}"
    files.each do |file|
      kill_file(file)
      Chef::Log.info "#{dry_run_str}Removed #{file}"
    end
  elsif new_resource.older_than
    ot = new_resource.older_than
    time = Time.now.to_i
    diff = 0
    ot.each_pair do |k, v|
      diff += (SECONDS[k] * v)
    end
    new_time = time - diff
    files.each do |file|
      if file.lstat.atime < Time.at(new_time)
        kill_file(file)
        Chef::Log.info "#{dry_run_str}Deleting #{file}"
      else
        Chef::Log.info "#{dry_run_str}Not deleting #{file}"
      end
    end
  end
end

private

def dry_run_str
  new_resource.dry_run ? 'DRY_RUN: ' : ''
end

def kill_file(file)
  unless new_resource.dry_run
    if new_resource.directories && file.directory?
      file.rmtree
    elsif new_resource.files
      file.delete
    end
  end
end
