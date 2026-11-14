# Exceptions under the tiny preset: setjmp/longjmp frames (the board's
# 56-byte jmp_buf), builtin class ids and names, the parent table.
class AppError < StandardError; end
class SensorError < AppError
  def initialize(msg = "sensor fault") = super
end

def deep(n)
  return raise SensorError if n == 0
  deep(n - 1)
end

def guarded(n)
  begin
    deep(n)
  rescue AppError => e
    "#{e.class}: #{e.message} (#{e.is_a?(StandardError)})"
  ensure
    puts "ensure #{n}"
  end
end

puts guarded(3)
puts guarded(0)

[[-> { 1 / 0 }, "ZeroDivisionError"],
 [-> { [1, 2].fetch(9) }, "IndexError"],
 [-> { { a: 1 }.fetch(:b) }, "KeyError"],
 [-> { Integer("x1") }, "ArgumentError"],
 [-> { nil.upcase }, "NoMethodError"],
 [-> { raise "plain" }, "RuntimeError"]].each do |blk, want|
  begin
    blk.call
  rescue StandardError => e
    puts "#{e.class.name == want} #{e.class} kind_of=#{e.kind_of?(StandardError)}"
  end
end

tries = 0
begin
  tries += 1
  raise ArgumentError, "try #{tries}" if tries < 3
  puts "retried to #{tries}"
rescue ArgumentError
  retry
end

def nest(d)
  begin
    if d == 0
      raise KeyError, "bottom"
    else
      nest(d - 1)
    end
  rescue IndexError => e
    raise if d < 5
    puts "caught at #{d}: #{e.class} < IndexError = #{e.is_a?(IndexError)}"
  ensure
    print d, " "
  end
end
nest(6)
puts

r = catch(:done) do
  10.times { |i| throw :done, i * 7 if i == 4 }
  :never
end
puts "catch #{r}"

begin
  begin
    raise TypeError, "inner"
  rescue => e
    raise RuntimeError, "outer"
  end
rescue => e
  puts "#{e.message} cause=#{e.cause.class}"
end
puts "done"
