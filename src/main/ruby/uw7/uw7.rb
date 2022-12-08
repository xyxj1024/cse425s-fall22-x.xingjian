# University of Washington, Programming Languages, Homework 7, hw7.rb 
# (See also ML code)

# Xingjian Xuanyuan

# a little language for 2D geometry objects

# each subclass of GeometryExpression, including subclasses of GeometryValue,
# needs to respond to messages preprocess_prog and eval_prog
#
# each subclass of GeometryValue additionally needs:
#   * shift
#   * intersect, which uses the double-dispatch pattern
#   * intersectPoint, intersectLine, and intersectVerticalLine for 
#       for being called by intersect of appropriate clases and doing
#       the correct intersection calculuation
#   * (We would need intersectNoPoints and intersectLineSegment, but these
#      are provided by GeometryValue and should not be overridden.)
#   *  intersectWithSegmentAsLineResult, which is used by 
#      intersectLineSegment as described in the drawings
#
# you can define other helper methods, but will not find much need to

# Note: geometry objects should be immutable: assign to fields only during
#       object construction

# Note: For eval_prog, represent environments as arrays of 2-element arrays
#       as described in the drawings

class GeometryExpression  
  # do *not* change this class definition
  Epsilon = 0.00001
end

class GeometryValue
  # do *not* change methods in this class definition
  # you can add methods if you wish

  private
  # some helper methods that may be generally useful
  def real_close(r1, r2) 
    (r1 - r2).abs < GeometryExpression::Epsilon
  end
  def real_close_point(x1, y1, x2, y2) 
    real_close(x1, x2) && real_close(y1, y2)
  end
  # two_points_to_line could return a Line or a VerticalLine
  def two_points_to_line(x1, y1, x2, y2) 
    if real_close(x1, x2)
      VerticalLine.new(x1)
    else
      m = (y2 - y1).to_f / (x2 - x1)
      b = y1 - m * x1
      Line.new(m, b)
    end
  end

  public
  # Return if v is between end1 and end2
  def inbetween(v, end1, end2)
    (end1 - GeometryExpression::Epsilon <= v && 
     v <= end2 + GeometryExpression::Epsilon) || 
    (end2 - GeometryExpression::Epsilon <= v &&
     v <= end1 + GeometryExpression::Epsilon)
  end

  # we put this in this class so all subclasses can inherit it:
  # the intersection of self with a NoPoints is a NoPoints object
  def intersectNoPoints np
    np # could also have NoPoints.new here instead
  end

  # we put this in this class so all subclasses can inhert it:
  # the intersection of self with a LineSegment is computed by
  # first intersecting with the line containing the segment and then
  # calling the result's intersectWithSegmentAsLineResult with the segment
  def intersectLineSegment seg
    line_result = intersect(two_points_to_line(seg.x1, seg.y1, seg.x2, seg.y2))
    line_result.intersectWithSegmentAsLineResult(seg)
  end

  def eval_prog env
    self # all values evaluate to self
  end
  def preprocess_prog
    self # no pre-processing to do here
  end
  def shift(dx, dy)
    self
  end
end

class NoPoints < GeometryValue
  # do *not* change this class definition: everything is done for you
  # (although this is the easiest class, it shows what methods every subclass
  #  of geometry values needs)
  # However, you *may* move methods from here to a superclass if you wish to

  # Note: no initialize method only because there is nothing it needs to do
  def eval_prog env 
    self # all values evaluate to self
  end
  def preprocess_prog
    self # no pre-processing to do here
  end
  def shift(dx, dy)
    self # shifting no-points is no-points
  end
  def intersect other
    other.intersectNoPoints(self) # will be NoPoints but follow double-dispatch
  end
  def intersectPoint p
    self # intersection with point and no-points is no-points
  end
  def intersectLine line
    self # intersection with line and no-points is no-points
  end
  def intersectVerticalLine vline
    self # intersection with line and no-points is no-points
  end
  # if self is the intersection of (1) some shape s and (2) 
  # the line containing seg, then we return the intersection of the 
  # shape s and the seg. seg is an instance of LineSegment
  def intersectWithSegmentAsLineResult seg
    self
  end
end


class Point < GeometryValue
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods

  # Note: You may want a private helper method like the local
  #       helper function inbetween in the ML code
  attr_reader :x, :y
  def initialize(x, y)
    @x = x
    @y = y
  end

  def eval_prog env
    self # all values evaluate to self
  end
  def preprocess_prog
    self # no pre-processing to do here
  end
  def shift(dx, dy)
    Point.new(@x + dx, @y + dy)
  end
  # 1st dispatch
  def intersect other
    other.intersectPoint(self)
  end
  # 2nd dispatch
  def intersectPoint p
    if real_close_point(self.x, self.y, p.x, p.y)
      self
    else
      NoPoints.new
    end
  end
  def intersectLine line
    if real_close(y, line.m * x + line.b)
      self
    else
      NoPoints.new
    end
  end
  def intersectVerticalLine vline
    if real_close(x, vline.x)
      self
    else
      NoPoints.new
    end
  end
  def intersectWithSegmentAsLineResult seg
    if inbetween(x, seg.x1, seg.x2) and inbetween(y, seg.y1. seg.y2)
      self
    else
      NoPoints.new
    end
  end
end

class Line < GeometryValue
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods
  attr_reader :m, :b 
  def initialize(m, b)
    @m = m
    @b = b
  end

  def eval_prog env
    self # all values evaluate to self
  end
  def preprocess_prog
    self # no pre-processing to do here
  end
  def shift(dx, dy)
    # Line.new(@m, @b + dy - @m * dx)
    # sample solution
    # Line.new(@m, @m * (-dx) + @b + dy)
    Line.new(m, b + dy - m * dx)
  end
  # 1st dispatch
  def intersect other
    other.intersectLine(self)
  end
  # 2nd dispatch
  def intersectPoint p
    p.intersectLine(self)
  end
  def intersectLine line
    if real_close(m, line.m)
      if real_close(b, line.b)
        self
      else
        NoPoints.new
      end
    else
      @x = (line.b - b).to_f / (m - line.m)
      @y = m * @x + b
      Point.new(@x, @y)
    end
  end
  def intersectVerticalLine vline
    Point.new(vline.x, m * vline.x + b)
  end
  def intersectWithSegmentAsLineResult seg
    seg
  end
end

class VerticalLine < GeometryValue
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods
  attr_reader :x
  def initialize x
    @x = x
  end

  def eval_prog env
    self # all values evaluate to self
  end
  def preprocess_prog
    self # no pre-processing to do here
  end
  def shift(dx, dy)
    VerticalLine.new(x + dx)
  end
  # 1st dispatch
  def intersect other
    other.intersectVerticalLine(self)
  end
  # 2nd dispatch
  def intersectPoint p
    p.intersectVerticalLine(self)
  end
  def intersectLine line
    line.intersectVerticalLine(self)
  end
  def intersectVerticalLine vline
    if real_close(x, vline.x)
      self # same line
    else
      NoPoints.new # parallel
    end
  end
  def intersectWithSegmentAsLineResult seg
    seg
  end
end

class LineSegment < GeometryValue
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods
  # Note: This is the most difficult class. In the sample solution,
  #       preprocess_prog is about 15 lines long and 
  #       intersectWithSegmentAsLineResult is about 40 lines long
  attr_reader :x1, :y1, :x2, :y2
  def initialize (x1, y1, x2, y2)
    @x1 = x1
    @y1 = y1
    @x2 = x2
    @y2 = y2
  end

  def eval_prog env
    self # all values evaluate to self
  end
  def preprocess_prog
    if real_close_point(x1, y1, x2, y2)
      Point.new(x1, y1)
    elsif real_close(x1, x2)
      # if x coordinates are the same, end1 is below end2
      LineSegment.new(x2, y2, x1, y1)
    elsif x1 > x2
      # otherwise, end1 is to the left of end2
      LineSegment.new(x2, y2, x1, y1)
    else
      self
    end
  end
  def shift(dx, dy)
    LineSegment.new(x1 + dx, y1 + dy, x2 + dx, y2 + dy)
  end
  # 1st dispatch
  def intersect other
    other.intersectLineSegment(self)
  end
  # 2nd dispatch
  def intersectPoint p
    p.intersectLineSegment(self)
  end
  def intersectLine line
    line.intersectLineSegment(self)
  end
  def intersectVerticalLine vline
    vline.intersectLineSegment(self)
  end
  # sample solution
  def intersectWithSegmentAsLineResult seg
    if real_close(x1, x2)
      # the segments are on a vertical line
      # let segment a start at or below start of segment b
      aXstart, aYstart, aXend, aYend, bXstart, bYstart, bXend, bYend =
        if y1 < seg.y1
          [@x1, @y1, @x2, @y2, seg.x1, seg.y1, seg.x2, seg.y2]
        else
          [seg.x1, seg.y1, seg.x2, seg.y2, @x1, @y1, @x2, @y2]
        end
      if real_close(aYend, bYstart)
        Point.new(aXend, aYend) # just touching
      elsif aYend < bYstart
        NoPoints.new # disjoint
      elsif aYend > bYend
        LineSegment.new(bXstart, bYstart, bXend, bYend) # b inside a
      else
        LineSegment.new(bXstart, bYstart, aXend, aYend) # overlapping
      end
    else
      # the segments are on a non-vertical line
      # let segment a start at or to the left of start of segment b
      aXstart, aYstart, aXend, aYend, bXstart, bYstart, bXend, bYend =
        if x1 < seg.x1
          [x1, y1, x2, y2, seg.x1, seg.y1, seg.x2, seg.y2]
        else
          [seg.x1, seg.y1, seg.x2, seg.y2, x1, y1, x2, y2]
        end
      if real_close(aXend, bXstart)
        Point.new(aXend, aYend) # just touching
      elsif aXend < bXstart
        NoPoints.new # disjoint
      elsif aXend > bXend
        LineSegment.new(bXstart, bYstart, bXend, bYend) # b inside a
      else
        LineSegment.new(bXstart, bYstart, aXend, aYend) # overlapping
      end
    end
  end
  # def intersectWithSegmentAsLineResult seg
    # seg2 = self
    # if real_close(seg.x1, seg.x2)
      # b = seg
      # a = seg2
      # if seg.y1 < seg2.y1
        # a = seg
        # b = seg2
      # end
      # if real_close(a.y2, b.y1)
        # Point(a.x2, a.y2)
      # elsif a.y2 < b.y1
        # NoPoints.new
      # elsif a.y2 > b.y2
        # LineSegment.new(b.x1, b.y1, b.x2, b.y2)
      # else
        # LineSegment.new(b.x1, b.y1, a.x2, a.y2)
      # end
    # else
      # a = seg2
      # b = seg
      # if seg.x1 < seg2.x1
        # a = seg
        # b = seg2
      # end
      # if real_close(a.x2, b.x1)
        # Point.new(a.x2, a.y2)
      # elsif a.x2 < b.x1
        # NoPoints.new
      # elsif a.x2 > b.x2
        # LineSegment.new(b.x1, b.y1, b.x2, b.y2)
      # else
        # LineSegment.new(b.x1, b.y1, a.x2, a.y2)
      # end
    # end
  # end
end

# Note: there is no need for getter methods for the non-value classes

class Intersect < GeometryExpression
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods
  def initialize(e1, e2)
    @e1 = e1
    @e2 = e2
  end

  def eval_prog env
    # e1_value = @e1.eval_prog(env)
    # e2_value = @e2.eval_prog(env)
    # e1_value.intersect(e2_value)
    # sample solution
    @e1.eval_prog(env).intersect @e2.eval_prog(env)
  end
  def preprocess_prog
    Intersect.new(@e1.preprocess_prog, @e2.preprocess_prog)
  end
end

class Let < GeometryExpression
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods
  # Note: Look at Var to guide how you implement Let
  def initialize(s, e1, e2)
    @s = s
    @e1 = e1
    @e2 = e2
  end

  def eval_prog env
    # eval_value = @e1.eval_prog(env)
    # new_env = [[@s, eval_value]] + env
    # @e2.eval_prog(new_env)
    env_copy = Array.new(env)
    @pair = env_copy.assoc @s
    if @pair == nil
      # If not found, add the pair to the environment
      @e2.eval_prog(env_copy.push([@s, @e1.eval_prog(env)]))
    else
      # If found, shadow previous definition
      @pair[1] = @e1.eval_prog(env)
      @e2.eval_prog(env_copy)
    end
  end
  def preprocess_prog
    Let.new(@s, @e1.preprocess_prog, @e2.preprocess_prog)
  end
end

class Var < GeometryExpression
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods
  def initialize s
    @s = s
  end

  def preprocess_prog
    self # no pre-processing to do here
  end
  def eval_prog env # remember: do not change this method
    pr = env.assoc @s
    raise "undefined variable" if pr.nil?
    pr[1]
  end
end

class Shift < GeometryExpression
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods
  def initialize(dx, dy, e)
    @dx = dx
    @dy = dy
    @e = e
  end

  def eval_prog env
    # eval_value = @e.eval_prog(env)
    # eval_value.shift(@dx, @dy)
    # sample solution
    @e.eval_prog(env).shift(@dx, @dy)
  end
  def preprocess_prog
    Shift.new(@dx, @dy, @e.preprocess_prog)
  end
end