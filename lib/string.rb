class String

  # Trim characters from the start and end of string
  #
  def trim(chars)
    _trim("^%s*|%s*$", chars)
  end

  # Trim characters from the start of string
  #
  def ltrim(chars)
    _trim("^%s*", chars)
  end

  # Trim characters from the end of string
  #
  def rtrim(chars)
    _trim("%s*$", chars)
  end

  private

  def _trim(regex, chars)
    chars = '\s' if chars.nil?
    chars = Regexp.escape(chars)
    regex.gsub!(/%s/, chars)
    self.gsub(/#{regex}/, '')
  end
end
