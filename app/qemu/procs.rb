# The proc side channel at 16 slots: narrow calls in slots, wider ones on
# the heap store, array spreads on both sides of 16.
add3 = proc { |a, b, c| a + b + c }
puts add3.call(1, 2, 3)
puts add3.call([4, 5, 6])

sum_all = ->(*xs) { xs.sum }
puts sum_all.call(*(1..10).to_a)
puts sum_all.call(*(1..20).to_a)
puts sum_all.call(*(1..40).to_a)

wide = lambda { |a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t|
  [a, h, p, q, t].sum
}
puts wide.call(*(1..20).to_a)

spread = proc { |a, b, *rest| "#{a} #{b} #{rest.size}" }
puts spread.call((1..5).to_a)

def each_pair_sum(list)
  list.each_slice(2).map { |x, y| yield(x, y) }
end
puts each_pair_sum((1..10).to_a) { |x, y| x * y }.inspect

puts %w[aa bbb c].map(&:length).inspect
m = 3.method(:+)
puts [1, 2, 3].map(&m).inspect
kw = ->(a, b: 2, **o) { "#{a} #{b} #{o.size}" }
puts kw.call(1, b: 5, c: 6, d: 7)
