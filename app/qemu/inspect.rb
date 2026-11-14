puts [1, 2].inspect
a = [1, 2, 3].map { |x| x * 2 }
puts a.inspect
p a
puts %w[aa bbb].map(&:length).inspect
puts({ a: 1 }.inspect)
puts [1, "x", :y].inspect
