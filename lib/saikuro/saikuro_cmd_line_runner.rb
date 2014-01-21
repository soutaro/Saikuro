# Really ugly command line runner stuff here for now
class SaikuroCMDLineRunner
  require 'stringio'
  require 'getoptlong'
  require 'fileutils'
  require 'find'

  # modification to RDoc.usage that allows main_program_file to be set
  # for RDoc.usage
  require 'saikuro/usage'
  RDoc::main_program_file = __FILE__

  include ResultIndexGenerator

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
    output_dir = "./"
    formater = "html"
    state_filter = Filter.new(5)
    token_filter = Filter.new(10, 25, 50)
    comp_state = comp_token = false
    begin
      opt = GetoptLong.new(
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

      opt.each do |arg,val|
        case arg
        when "-o"
          output_dir = val
        when "-h"
          RDoc.usage('help')
        when "-f"
          formater = val
        when "-c"
          comp_state = true
        when "-t"
          comp_token = true
        when "-k"
          token_filter.limit = val.to_i
        when "-s"
          token_filter.warn = val.to_i
        when "-d"
          token_filter.error = val.to_i
        when "-y"
          state_filter.limit = val.to_i
        when "-w"
          state_filter.warn = val.to_i
        when "-e"
          state_filter.error = val.to_i
        when "-p"
          files<< val
        when "-i"
          files.concat(get_ruby_files(val))
        when "-v"
          STDOUT.puts "Verbose mode on"
          $VERBOSE = true
        end

      end
      RDoc.usage if !comp_state && !comp_token
    rescue => err
      RDoc.usage
    end

    if formater =~ /html/i
      state_formater = StateHTMLComplexityFormater.new(STDOUT,state_filter)
      token_count_formater = HTMLTokenCounterFormater.new(STDOUT,token_filter)
    else
      state_formater = ParseStateFormater.new(STDOUT,state_filter)
      token_count_formater = TokenCounterFormater.new(STDOUT,token_filter)
    end

    state_formater = nil if !comp_state
    token_count_formater = nil if !comp_token

    idx_states, idx_tokens = Saikuro.analyze(files,
                                             state_formater,
                                             token_count_formater,
                                             output_dir)

    write_cyclo_index(idx_states, output_dir)
    write_token_index(idx_tokens, output_dir)
  end

end
