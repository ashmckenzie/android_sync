class String

  # Trim characters from the start and end of string and return new string
  #
  def trim(chars)
    _trim("^%s*|%s*$", chars)
  end

  # Trim characters from the start and end of string and update receiver string
  #
  def trim!(chars)
    _trim("^%s*|%s*$", chars, true)
  end

  # Trim characters from the start of string and return new string
  #
  def ltrim(chars)
    _trim("^%s*", chars)
  end

  # Trim characters from the start of string and update receiver string
  #
  def ltrim!(chars)
    _trim("^%s*", chars, true)
  end 

  # Trim characters from the end of string and return new string
  #
  def rtrim(chars)
    _trim("%s*$", chars)
  end

  # Trim characters from the end of string and update receiver string
  #
  def rtrim!(chars)
    _trim("%s*$", chars, true)
  end 

  private

  def _trim(regex, chars, inline=false)
    chars = '\s' if chars.nil?
    chars = Regexp.escape(chars)
    regex.gsub!(/%s/, chars)
    self.send(inline ? 'gsub!' : 'gsub', /#{regex}/, '')
  end
end
