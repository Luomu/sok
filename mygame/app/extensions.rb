# Extension methods (not sure if that's a ruby term)
class Array
  # Select a random element
  def random_element
    return self.sample()
  end

  # Select and remove a random element (like a card from a deck)
  def draw_random_element!
    if self.length == 0
    return nil
    end

    idx  = rand(self.length)
    elem = self[idx]
    self.delete_at(idx)
    return elem
  end

  def average
    return 0 if self.empty?
    self.sum / self.size.to_f
  end

  # Unsafe xyzw/rgba accessors
  def x
    return self[0]
  end

  def y
    return self[1]
  end

  def z
    return self[2]
  end

  def w
    return self[3]
  end

  def r
    return self[0]
  end

  def g
    return self[1]
  end

  def b
    return self[2]
  end

  def a
    return self[3]
  end
end

class Hash
  def set_color_rgb color
    self.r = color.r
    self.g = color.g
    self.b = color.b
    return self
  end
end
