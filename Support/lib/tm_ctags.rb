module TM_Ctags
  module_function
  
  def parse(line, index)
    name = line[/^(\w+)/, 1]
    path = line.split(/\t+/)[1]
    type = line.split(/\t+/)[-2]
    line_no = line[ /line:(\d+)/, 1]
    file = File.basename(path) + ":" + line_no
    
    if type =~ /function|method/
      args = parse_args( line )
      signature = name + "(" 
      signature << " " + args.join(", ") + " "
      signature << ")"
    else
      args = []
      signature = name
    end
    
    overview = "#{type} #{signature}   < #{file} >"
    
    { 
      'name' => name, 
      'signature' => signature, 
      'file' => file, 
      'path' => path, 
      'line' => line_no, 
      'index' => index, 
      'args' => args, 
      'type' => type,
      'overview' => overview
    }
  end
  
  def parse_args( line )
    sig = line[ %r{/\^\s*(.+?)\$/}, 1]
    raw = sig[/\((.*?)\)/, 1]
    if raw
      raw.delete(" ").split(',')
    else
      []
    end
  end

  def build_snippet( hit )
    has_args = hit['args'].length > 0
    snippet = hit['name']
    snippet << '(' if has_args || hit['type'] =~ /function/
    snippet << " #{args_snippet(hit['args'])} " if has_args
    snippet << ')' if has_args || hit['type'] =~ /function/
    snippet << '$0'
  end
  
  def args_snippet( args )
    result = ""
    tab_stop = 1
    optional = 0

    args.each_with_index do |arg, i|
      arg.gsub!('$', '\$')
      is_optional = false
      is_last = i + 1 == args.length
      if arg =~ /=/
        result << "${#{tab_stop}:"
        tab_stop += 1
        optional += 1
        is_optional = true
      end
      result << ", " if i > 0
      result << "${#{tab_stop}:#{arg}}"
      tab_stop += 1
    end
    result + '}' * optional
  end
  
  def goto( hit )
    TextMate.go_to :file => File.join(ENV['TM_PROJECT_DIRECTORY'], hit['path']), :line => hit['line']
  end
end