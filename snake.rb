# frozen_string_literal: true

require 'io/console'
require 'colorize'

# It provides a way to draw
# things on the screen
class Screen
  attr_accessor :total_height, :total_width

  def initialize
    @total_height = `stty size`.scan(/\d+/)[0].to_i
    @total_width = `stty size`.scan(/\d+/)[1].to_i
  end

  def clear_screen
    puts "\033[2J"
  end

  # rubocop:disable Naming/MethodParameterName
  def move_cursor(x, y)
    print "\033[#{y};#{x}H"
  end
  # rubocop:enable Naming/MethodParameterName

  def draw(position, symbol)
    move_cursor(position[0], position[1])
    print symbol
  end

  def draw_multiple(positions, symbol)
    positions.each do |pos_x, pos_y|
      draw([pos_x, pos_y], symbol)
    end
  end
end

# It keeps track of the snake's position on the screen
class Snake
  BODY_SEGMENT = '#'.red.on_light_white
  HEAD = '#'.light_white.on_red

  attr_accessor :positions

  def initialize(screen)
    @screen = screen
    set_initial_position
  end

  def set_initial_position
    initial_width = @screen.total_width / 2
    @positions = [[initial_width, @screen.total_height / 2]]

    5.times do |i|
      @positions << [initial_width + i, @screen.total_height / 2]
    end
  end

  def head_position
    @positions.last
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def update_position(direction)
    x, y = head_position

    @positions.push(
      case direction
      when 'A' then y.positive? ? [x, y - 1] : [x, @screen.total_height]
      when 'B' then y < @screen.total_height ? [x, y + 1] : [x, 0]
      when 'C' then x < @screen.total_width ? [x + 1, y] : [0, y]
      when 'D' then x.positive? ? [x - 1, y] : [@screen.total_width, y]
      end
    )
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def ate_self?
    @positions[0..-2].any? { |x, y| head_position[0] == x && head_position[1] == y }
  end

  def draw
    @screen.draw_multiple(positions[0..-2], BODY_SEGMENT)
    @screen.draw(head_position, HEAD)
  end
end

# It's a class that represents a food item that can be eaten by the snake
class Food
  BODY = '*'.on_yellow

  attr_reader :food_x, :food_y, :position

  def initialize(screen)
    @screen = screen
    reset_position!
  end

  def reset_position!
    @position = [
      rand(2..@screen.total_width - 2),
      rand(2..@screen.total_height - 2)
    ]
  end

  def draw
    @screen.draw(@position, BODY)
  end
end

# It initializes the game,
# sets up the snake, food, and screen, and then starts the game loop
class SnakeGame
  def initialize
    @screen = Screen.new
    @snake = Snake.new(@screen)
    @food = Food.new(@screen)
    @score = 0
    @speed_step = 0.01
    @speed = 0.05
    @direction = 'C'
  end

  # rubocop:disable Metrics/MethodLength
  def start!
    loop do
      Thread.new { track_movement }

      @snake.update_position(@direction)
      break if @snake.ate_self?

      check_if_fruit_eaten
      @screen.clear_screen
      @snake.draw
      @food.draw
      pin_cursor
      sleep(@speed)
    end

    @screen.clear_screen
    finish!
  end
  # rubocop:enable Metrics/MethodLength

  private

  def track_movement
    $stdin.noecho do |io|
      while (c = io.getch.tap { |char| exit(1) if char == "\u0003" })
        if %w[A B].include?(@direction) && %w[C D].include?(c.chr)
          @direction = c.chr
        elsif %w[C D].include?(@direction) && %w[A B].include?(c.chr)
          @direction = c.chr
        end
      end
    end
  end

  def check_if_fruit_eaten
    if @snake.head_position[0] == @food.position[0] && @snake.head_position[1] == @food.position[1]
      @food.reset_position!
      increase_level
    else
      @snake.positions.shift
    end
  end

  def increase_level
    @score += 1
    @speed -= @speed_step if (@score % 10).zero?
  end

  def pin_cursor
    @screen.move_cursor(0, 0)
  end

  def finish!
    puts "Game over! Your score: #{@score.to_s.red}"
  end
end

SnakeGame.new.start!
