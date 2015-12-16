
require "erb"
require 'inifile'
require 'optparse'
require 'htmlbeautifier'

class Hash
  def hmap(&block)
    self.inject({}){ |hash,(k,v)| hash.merge( block.call(k,v) ) }
  end
end

gen_form = false
gen_info = false
dry_run = false
module_name = ""
language_file = ""
fields = nil
output_path = "src/app/provider-modules"

OptionParser.new do |opts|

  opts.on("-x", "gen form") {gen_form = true}
  opts.on("-y", "gen info") {gen_info = true}
  opts.on("-d", "dry run") {dry_run = true}
  opts.on("-o", "--outputpath string", /.*/i,
          "path/to/modules") {|arg| output_path = arg}
  opts.on("-m", "--module string", /.*/i,
          "psigate") {|arg| module_name = arg}
  opts.on("-l", "--language path_to_language_file",
          /.*.ini/i,
          "path/to/language.ini"
          ) {|arg| language_file = arg}
  opts.on("-f", "--fields fields", Array, "displayName, merchantId") do |list|
    fields = list
  end

  begin
    opts.parse!
  rescue OptionParser::ParseError => error
    $stderr.puts error
    $stderr.puts "(-h or --help will show valid options)"
    exit 1
  end
end

# downcase all the keys
lang_data = IniFile.load(language_file)['global']
lang_data = lang_data.hmap do |k, v|
  { k.downcase => v  }
end

fields = fields.map{ |e| e.strip }
fields = Hash[*fields.zip(fields).flatten].hmap do |k, v|
  language_key = "#{module_name}#{k.downcase}"
  language_key_help = "#{module_name}#{k.downcase}help"
  title = lang_data[language_key]
  help = lang_data[language_key_help]
  {k => {'title' => title, 'help' => help}}
end

base_path = "#{output_path}/#{module_name}/#{module_name}"
tpl = ERB.new(File.read("module-form.tpl.erb"));
still_ugly = HtmlBeautifier.beautify(tpl.result, tab_stops: 4)
File.open("#{base_path}-form.tpl.html", 'w') { |f| f.write(still_ugly) } if gen_form

info = lang_data["#{module_name}help"]
ugly_info = HtmlBeautifier.beautify(info, tab_stops: 4)
File.open("#{base_path}-info.tpl.html", 'w') { |f| f.write(ugly_info) } if gen_info





