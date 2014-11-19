require_relative 'bishop'
require_relative 'king'
require_relative 'knight'
require_relative 'queen'
require_relative 'pawn'
require_relative 'rook'

require 'colorize'

class Board

  attr_reader :ROW_SIZE, :COL_SIZE

  def pieces(color = nil)
    @grid.flatten.compact.select { |piece| color.nil? ? true : piece.color == color }
  end

  def [](pos)
    x, y = pos
    # p x
    # p y
    @grid[x][y]
  end

  def []=(pos, val)
    x, y = pos
    @grid[x][y] = val
  end

  def size
    @grid.size
  end

  def initialize(start = true)
    @ROW_SIZE = 6
    @COL_SIZE = 6
    @grid = Array.new(@ROW_SIZE) { Array.new(@COL_SIZE) }
    set_pieces if start
  end

  def set_pieces
    # pawns
    @grid[1].each_index do |i|
      @grid[1][i] = Pawn.new([1,i], :black, self)
    end
    white_pawn_loc = @ROW_SIZE - 2
    @grid[white_pawn_loc].each_index do |i|
      @grid[white_pawn_loc][i] = Pawn.new([white_pawn_loc,i], :white, self)
    end
    # back rows
    back = [Rook, Knight, Queen, King, Knight, Rook]
    @grid[0].each_index do |i|
      @grid[0][i] = back[i].new([0,i], :black, self)
    end
    white_piece_loc = @ROW_SIZE - 1
    @grid[white_piece_loc].each_index do |i|
      @grid[white_piece_loc][i] = back[i].new([white_piece_loc,i], :white, self)
    end
  end

  # check it.
  # should refactor to avoid having magic numbers
  # this and set_pieces
  def dup
    dup = Board.new(false)
    self.pieces.each do |piece|
      pos = piece.pos
      dup[pos] = piece.class.new(pos, piece.color, dup)
    end
  dup
  end

  def in_check?(color)
    king = pieces(color).find { |piece| piece.is_a?(King) }

    pieces.any? do |piece| # TODO add better way of getting opposite color pieces
      piece.moves.include?(king.pos) && piece.color != color
    end
  end

  def move(start, end_pos, color)
    if self[start].nil?
      raise MoveError.new "No piece at this start position."
    end

    unless self[start].valid_moves.include?(end_pos)
      raise MoveError.new "You can't move here!"
    end

    unless self[start].color == color
      raise MoveError.new "You can't move your opponent's pieces!"
    end

    make_move(start, end_pos)

    self  # return self so we can chain stuff after board.dup.move
  end

  def move!(start, end_pos)
    # these seven lines are *almost* dups from move() -- TODO refactor?
    if self[start].nil?
      raise MoveError.new "No piece at this start position."
    end

    unless self[start].moves.include?(end_pos)
      raise MoveError.new "You can't move here!"
    end

    make_move(start, end_pos)

    self  # return self so we can chain stuff after board.dup.move
  end

  def render

    color = :white
    puts " abcdef"
    row_counter = @ROW_SIZE + 1
    render = @grid.map do |row|
      color = flip_color(color)
      row_string = row.map do |cell|
        color = flip_color(color)
        cell.nil? ? " ".colorize(background: color) : cell.render.colorize(background:color)
      end.join("")
      row_counter -= 1
      [row_counter.to_s, row_string].join
    end.join("\n")

    puts render
  end

  def checkmate?(color)
    in_check?(color) &&
    pieces(color).all? { |piece| piece.valid_moves.empty? }
  end

  private

    def make_move(start, end_pos)
      self[end_pos], self[start] = self[start], nil
      self[end_pos].pos = end_pos
    end

    def flip_color(color)
      color == :light_blue ? :white : :light_blue
    end

end

class MoveError < StandardError
end
