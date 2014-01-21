# Really ugly command line runner stuff here for now
class SaikuroCMDLineRunner
  require 'stringio'
  require 'getoptlong'
  require 'fileutils'
  require 'find'

  include ResultIndexGenerator

  attr_accessor :formater, :output_dir, :comp_state, :comp_token,
    :state_formater, :token_count_formater
  def initialize
    @opt = GetoptLong.new(
                         ["-o","--output_directory", GetoptLong::REQUIRED_ARGUMENT],
                         ["-h","--help", GetoptLong::NO_ARGUMENT],
                         ["-f","--formater", GetoptLong::REQUIRED_ARGUMENT],
                         ["-c","--cyclo", GetoptLong::NO_ARGUMENT],
                         ["-t","--token", GetoptLong::NO_ARGUMENT],
                         ["-y","--filter_cyclo", GetoptLong::REQUIRED_ARGUMENT],
                         ["-k","--filter_token", GetoptLong::REQUIRED_ARGUMENT],
                         ["-w","--warn_cyclo", GetoptLong::REQUIRED_ARGUMENT],
                         ["-s","--warn_token", GetoptLong::REQUIRED_ARGUMENT],
                         ["-e","--error_cyclo", GetoptLong::REQUIRED_ARGUMENT],
                         ["-d","--error_token", GetoptLong::REQUIRED_ARGUMENT],
                         ["-p","--parse_file", GetoptLong::REQUIRED_ARGUMENT],
                         ["-i","--input_directory", GetoptLong::REQUIRED_ARGUMENT],
                         ["-v","--verbose", GetoptLong::NO_ARGUMENT]
                         )
    self.output_dir = "./"
    self.formater = "html"
    self.comp_state = self.comp_token = false
  end

  def get_ruby_files(path)
    files = Array.new
    Find.find(path) do |f|
      if !FileTest.directory?(f)
	if f =~ /rb$/
	  files<< f
	end
      end
    end
    files
  end

  def run
    files = Array.new
    state_filter = Filter.new(5)
    token_filter = Filter.new(10, 25, 50)

    parse_opts(state_filter, token_filter, files)
    set_formatters(state_filter, token_filter)

    idx_states, idx_tokens = analyze(files)
    write_results(idx_states, idx_tokens)
  end

  def analyze(files)
    Saikuro.analyze(files,
      state_formater,
      token_count_formater,
      output_dir)
  end

  def write_results(idx_states, idx_tokens)
    write_cyclo_index(idx_states, output_dir)
    write_token_index(idx_tokens, output_dir)
  end

  def parse_opts(state_filter, token_filter, files)
    @opt.each do |arg,val|
      case arg
      when "-o"  then self.output_dir = val
      when "-h"  then usage('help')
      when "-f"  then self.formater = val
      when "-c"  then self.comp_state = true
      when "-t"  then self.comp_token = true
      when "-k"  then token_filter.limit = val.to_i
      when "-s"  then token_filter.warn = val.to_i
      when "-d"  then token_filter.error = val.to_i
      when "-y"  then state_filter.limit = val.to_i
      when "-w"  then state_filter.warn = val.to_i
      when "-e"  then state_filter.error = val.to_i
      when "-p"  then files<< val
      when "-i"  then files.concat(get_ruby_files(val))
      when "-v"
        STDOUT.puts "Verbose mode on"
        $VERBOSE = true
      end
    end
    usage if no_complexity_token_or_state?
  rescue => err
    p err
    usage
  end

  def usage(command=nil)
    p [@opt, command]
  end

  def no_complexity_token_or_state?
    !comp_state && !comp_token
  end

  def set_formatters(state_filter, token_filter)
    if formater =~ /html/i
      self.state_formater = StateHTMLComplexityFormater.new(STDOUT,state_filter)
      self.token_count_formater = HTMLTokenCounterFormater.new(STDOUT,token_filter)
    else
      self.state_formater = ParseStateFormater.new(STDOUT,state_filter)
      self.token_count_formater = TokenCounterFormater.new(STDOUT,token_filter)
    end

    self.state_formater = nil if !comp_state
    self.token_count_formater = nil if !comp_token
  end

end
