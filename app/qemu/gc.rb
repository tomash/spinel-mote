# qemu-heap-kb: 48
# Memory pressure on a small heap: churn that only fits if the
# collector reclaims, roots past the 128-entry stack, runtime symbols past
# the 16-entry pool, the 8-entry String#length cache. (The recursion keeps
# arrays, not hashes: an empty Hash is ~800 B of tables, so 60 live ones do
# not fit in 16 KB -- see docs/mcu-levers.md. The 60-deep recursion keeps
# ~29 KB live, ~480 B a level, so this test runs with a 48 KB heap.)
def churn(rounds)
  keep = nil
  rounds.times do |i|
    a = Array.new(20) { |j| "s#{i}-#{j}" }
    keep = a if i % 50 == 0
  end
  keep.size
end
puts churn(400)

def chain(n)
  return 0 if n == 0
  a = "n#{n}"; b = [n, a]; c = [b, n]
  chain(n - 1) + c[0][0] - n + a.size
end
puts chain(60)

syms = (1..40).map { |i| "dyn_#{i}".to_sym }
puts syms.size, syms.uniq.size, (syms.last == :dyn_40)

strs = (1..30).map { |i| "é" * (i % 7) + "x" * i }
puts strs.map(&:length).sum
puts strs.map(&:length).sum

h = {}
300.times { |i| h["k#{i % 37}"] = i }
puts h.size, h["k5"]
puts "done"
