#! /usr/bin/env ruby

require 'find'
require 'pp'
require 'optparse'

options = {}

optparse = OptionParser.new do|opts|
  opts.banner = "Usage: weigh.rb [options] file1 file2 ..."

  options[:verbose] = false
  opts.on( '-v', '--verbose', 'Output more information' ) do
    options[:verbose] = true
  end

  options[:depth] = 1
  opts.on( '-d', '--depth DEPTH', 'Sumarize deeper than DEPTH' ) do|d|
    options[:depth] = d
  end

  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

optparse.parse!

def neat_size(size)
  # return a human readble size from the bytes supplied
  size = size.to_f
  if size > 2 ** 40       # TiB: 1024 GiB
    neat = sprintf("%.2f TiB", size / 2**40)
  elsif size > 2 ** 30    # GiB: 1024 MiB
    neat = sprintf("%.2f GiB", size / 2**30)
  elsif  size > 2 ** 20   # MiB: 1024 KiB
    neat = sprintf("%.2f MiB", size / 2**20)
  elsif size > 2 ** 10    # KiB: 1024 B
    neat = sprintf("%.2f KiB", size / 2**10)
  else                    # bytes
    neat = sprintf("%.0f bytes", size)
  end
  neat
end

#def sum_dir(dir,curdep,sumdep)
def sum_dir(dir,verbose=false)
  # return the size of a given directory
  #"Entering: #{dir}"
  count=0
  dir_size=0
  data={}
  Find.find(dir) do |path|
    count += 1
    next if FileTest.symlink?(path)
    next if dir == path
    if FileTest.directory?(path)
      ret = sum_dir(path,verbose)
      size = ret[:dir_size]
      count += ret[:count]
      dir_size += size
      Find.prune
    else
      size = FileTest.size(path)
      #puts "File: #{path} is #{size}"
      puts "Found zero size file: #{path}" if verbose
      dir_size += size
    end
  end
  #puts "Exiting: #{dir} with #{dir_size}"
  data[:dir_size] = dir_size
  data[:count] = count
  data
end

pathlist = []
if ARGV.size > 0
  ARGV.each do |f|
    pathlist << f
  end
else
  pathlist << "."
end

total_size = 0
summary = {}
count = 0
sumdep = options[:depth]
verbose = options[:verbose]

pathlist.each do |p|
  curdep = 0
  Find.find(p) do |path|
    count += 1
    next if FileTest.symlink?(path)
    if FileTest.directory?(path)
      next if p == path
      ret = sum_dir(path,verbose)
      dir_size = ret[:dir_size]
      next if dir_size == 0
      count += ret[:count]
      total_size += dir_size
      summary["#{path}/"] = dir_size
      Find.prune
    else
      size = FileTest.size(path)
      next if size == 0
      total_size += size
      summary["#{path}"] = size
    end
  end
end

# Print summary
summary.sort{|a,b| a[1]<=>b[1]}.each { |elem|
  size     = elem[1]
  filename = elem[0]
  puts sprintf("%15s   %s\n", neat_size(size), filename)
}

puts sprintf("%16s %s\n", "---", "---")
puts sprintf("%15s   %s\n", neat_size(total_size), ":total size")
#puts sprintf("%15s   %s\n", "#{count}", ":counted")
puts sprintf("%16s %s\n", "---", "---")
