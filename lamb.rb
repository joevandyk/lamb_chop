#!/usr/bin/env ruby

require 'rubygems'
require 'fox16' 
include Fox 


class MTZ_2_CNS < FXMainWindow 
  MTZ2VARIOUS = "#{ENV['CCP4_BIN']}/mtz2various"
  def initialize(app) 
    @mtz_filename = ""
    super(app, "Preparing MTZ for CNS", :width => 500, :height => 360) 
    add_buttons_and_shit
  end 

  def create 
    super 
    show(PLACEMENT_SCREEN) 
  end 

  def add_buttons_and_shit
    label = FXLabel.new(self, "Pick your MTZ file plz", :opts => JUSTIFY_LEFT)
    mtz_selection_button = FXButton.new(self, "Choose File")
    mtz_selection_button.connect(SEL_COMMAND) do 
      show_file_selection_dialog
    end
    go_button = FXButton.new(self, "GO") 
    go_button.connect(SEL_COMMAND) do
      execute_program
    end
    @output_text = FXText.new(self, :opts => LAYOUT_FILL)
  end

  def show_file_selection_dialog
    dialog = FXFileDialog.new(self, "Open MTZ file")
    dialog.patternList = ["MTZ Files (*.mtz, *.MTZ)"]
    dialog.selectMode = SELECTFILE_EXISTING
    if dialog.execute != 0
      @mtz_filename = dialog.filename
      puts "file selected was #{ @mtz_filename }"
    end
  end

  def get_job_title_from_mtz mtz_filename
    output = `#{ENV['CCP4']}/etc/mtzdmp #{mtz_filename} -e`
    match_data = output.match(/F_([^ ]*)/)
    match_data[1] if match_data
  end

  def error message, title="ERROR"
    FXMessageBox.error self, MBOX_OK, title, message
  end

  def information message, title="Info"
    FXMessageBox.information self, MBOX_OK, title, message
  end

  def execute_program
    error("No MTZ file selected") and return unless File.exist?(@mtz_filename)
    input_filename = @mtz_filename
    output_filename = @mtz_filename + ".cv"

    job_title = get_job_title_from_mtz(@mtz_filename)

    program = "#{MTZ2VARIOUS} hklin #{input_filename}  hklout #{output_filename}"

    puts "INPUT: #{ input_filename }"
    puts "OUTPUT: #{ output_filename }"
    puts "PROGRAM: #{ program }"

    command = IO.popen(program, "w+")
    output = ""
    if !command.closed?
      command << "OUTPUT CNS\n"
      command << "labin  FP=F_#{job_title} SIGFP=SIGF_#{job_title} FREE=FreeR_flag\n"
      command << "end\n"
      output = command.read
      command.close
    end

    if $?.success?
      information "It ran ok"
      @output_text.text = output
    else
      error "IT DIDN'T WORK"
    end

  end

end 

if __FILE__ == $0 
  FXApp.new do |app| 
    MTZ_2_CNS.new(app) 
    app.create 
    app.run 
  end 
end 

