
######################
### Action Effects ###
######################

class Effects

  attr_accessor :effects
  
  def initialize(effects)
    @effects = { gold: 0, food: 0, prestige: 0, reputation: 0, power: 0, risk: 0, karma: 0, general: 0 }.merge(effects)
  end

  def +(x) = Effects.new(@effects.merge(x.is_a?(Effects) ? x.effects : x) { |_, a, b| a + b })

  def *(x) = Effects.new(@effects.merge(x.is_a?(Effects) ? x.effects : x) { |_, a, b| a * b })

  def inverse = Effects.new(@effects.transform_values { |v| v * -1 })

  def scale(n) = Effects.new(@effects.transform_values { |v| n * v })

  def sum = @effects.values.sum

  def show = '(' + @effects.map { |k, v| "#{k.to_s[0..1]} #{v.round(3)}"}.join(', ') + ')'

end

class Priorities < Effects

  def initialize(priorities=nil)
    priorities ||= { gold: rand(0.0..2), food: rand(0.0..2), prestige: rand(0.0..2), reputation: rand(-2.0..2), power: rand(-1.0..2), risk: rand(-2.0..1), karma: rand(0.0..2) }
    @effects = { gold: 0, food: 0, prestige: 0, reputation: 0, power: 0, risk: 0, karma: 0, general: 1 }.merge(priorities)
  end

end