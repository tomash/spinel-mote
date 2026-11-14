# KNOWN UPSTREAM BUG (spinel 0e124f742 and master c44e8ab65, also on the
# host): a proc auto-splatting one Array argument keeps only its first 16
# elements (codegen.c: `if (_sp_as_n > 16) _sp_as_n = 16`), so CRuby's
# "1 2 16" prints "1 2 14". Not a tiny-preset issue; kept to see it fixed.
spread = proc { |a, b, *rest| "#{a} #{b} #{rest.size}" }
puts spread.call((1..18).to_a)
