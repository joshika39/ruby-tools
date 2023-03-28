class ApplicationController < ActionController::Base
  before_action :init

  def hex_to_rgb(hex_str)
    hex_color = hex_str
    hex_color = hex_color.gsub("#", "")
    hex_int = hex_color.to_i(16)
    red = (hex_int >> 16) & 0xFF
    green = (hex_int >> 8) & 0xFF
    blue = hex_int & 0xFF
    [red, green, blue]
  end

  def rgb_to_hsv(red, green, blue)

    max_color = [red, green, blue].max
    min_color = [red, green, blue].min

    puts "Max: #{max_color}, min: #{min_color}"
    puts "Red: #{red}, Green: #{green}, Blue: #{blue}"
    if red == green and green == blue
      hue = 0
    elsif max_color == red
      hue = (green - blue).to_f / (max_color - min_color).to_f
    elsif max_color == green then
      hue = 2.0 + (blue - red).to_f / (max_color - min_color).to_f
    elsif max_color == blue then
      hue = 4.0 + (red - green).to_f / (max_color - min_color).to_f
    end
    hue *= 60

    if hue < 0
      hue += 360
    end

    hue = hue.round(2)
    value = (max_color.to_f / 255).round(2)

    if max_color > 0
      saturation = (1 - min_color / max_color.to_f).round(2)
    else
      saturation = 0
    end
    logger.info [hue, saturation, value]
    [hue, saturation.round(2), value.round(2)]
  end

  def hsv_to_rgb(hsv)
    logger.info "started hsv to rgb: #{hsv}"
    hue = hsv[0]
    sat = hsv[1]
    value = hsv[2]

    conv = value * sat
    x = conv * (1 - ((hue.to_f / 60.to_f) % 2 - 1).abs)
    m = value - conv

    if 0 <= hue and hue < 60
      rgb_ = [conv, x, 0]
    elsif 60 <= hue and hue < 120
      rgb_ = [x, conv, 0]
    elsif 120 <= hue and hue < 180
      rgb_ = [0, conv, x]
    elsif 180 <= hue and hue < 240
      rgb_ = [0, x, conv]
    elsif 240 <= hue and hue < 300
      rgb_ = [x, 0, conv]
    else
      rgb_ = [conv, 0, x]
    end
    rgb = [((rgb_[0] + m) * 255).to_i, ((rgb_[1] + m) * 255).to_i, ((rgb_[2] + m) * 255).to_i]
    logger.info "HSV -> RGB: #{rgb}"
    rgb
  end

  def rgb_to_hex(rgb)
    def get_hex_digit(num)
      hex_num = num.to_s(16).rjust(2, '0')
      logger.info "hex from: #{num} to #{hex_num}"
      hex_num
    end

    color_value = sprintf("##{get_hex_digit(rgb[0])}#{get_hex_digit(rgb[1])}#{get_hex_digit(rgb[2])}")
    logger.info color_value
    color_value
  end

  def get_alt_hsv(hsv, hue_diff, sat_delta, value_delta)
    h = hsv[0]
    s = hsv[1]
    v = hsv[2]

    h1 = (h + hue_diff) % 360
    s1 = if s >= 0.2
           s + sat_delta
         else
           s
         end
    v1 = if v >= 0.4
           v + value_delta
         else
           v
         end
    logger.info [h1, s1, v1]
    [h1, s1, v1]
  end

  def get_complementary(hsv, hue_diff, sat_diff, val_diff)
    h = hsv[0]
    s = hsv[1]
    v = hsv[2]

    new_hsv = [(h + hue_diff) % 360, s + sat_diff, v + val_diff]
    logger.info new_hsv
    new_hsv
  end

  def change_angle(hsv, new_angle)
    s = hsv[1]
    v = hsv[2]

    new_hsv = [new_angle, s, v]
    logger.info "New angle: #{new_hsv}"
    new_hsv
  end

  def get_accents(base_color)
    _hsv_colors = Array.new(9)
    _hsv_colors[4] = base_color
    (0..5).each do |i|
      _hsv_colors[i] = [base_color[0], 0.2 + ((base_color[1] - 0.2).abs / 5) * (i + 1), 1 - ((base_color[2] - 1).abs / 5) * (i + 1)]
    end
    helper_i = 0
    (5..8).reverse_each do |i|
      _hsv_colors[5 + helper_i] = [base_color[0], 1 - ((base_color[1] - 1).abs / 4.0) * (i - 5).abs, 0.4 + ((base_color[2] - 0.4).abs / 4) * (i - 5)]
      helper_i += 1
    end
    logger.info _hsv_colors
    _hsv_colors
  end

  def init
    if session[:theme]
      @base_color = session[:theme]
    else
      session[:theme] = "#3ae0bf"
      @base_color = "#3ae0bf"
    end

    rgb = hex_to_rgb(@base_color)
    hsv = rgb_to_hsv(rgb[0], rgb[1], rgb[2])

    info_hsv = change_angle(hsv, 200)
    success_hsv = change_angle(hsv, 100)
    warning_hsv = change_angle(hsv, 55)
    error_hsv = change_angle(hsv, 8)

    @base_accents = get_accents(hsv)

    @c1_accents = get_accents(get_complementary(hsv, 99, 0, 0)).map { |c| rgb_to_hex(hsv_to_rgb(c))}
    @c2_accents = get_accents(get_complementary(hsv, 171, 0, 0)).map { |c| rgb_to_hex(hsv_to_rgb(c))}

    @success_accents = get_accents(success_hsv)
    @error_accents = get_accents(error_hsv)

    @info_accents = get_accents(info_hsv).map { |info| rgb_to_hex(hsv_to_rgb(info)) }
    @warning_accents = get_accents(warning_hsv).map { |warn| rgb_to_hex(hsv_to_rgb(warn)) }

    logger.info @base_accents
  end

  helper_method :hsv_to_rgb, :rgb_to_hex
end
