
require "erb"
require 'fileutils'
require 'htmlbeautifier'
require 'inifile'
require 'optparse'

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

base_path = "#{output_path}/#{module_name}"
FileUtils.mkdir(base_path) unless File.directory?(base_path)

tpl = ERB.new(File.read("module-form.tpl.erb"));
still_ugly = HtmlBeautifier.beautify(tpl.result, tab_stops: 4)
File.open("#{base_path}/#{module_name}-form.tpl.html", 'w') { |f| f.write(still_ugly) } if gen_form

info = lang_data["#{module_name}help"]
ugly_info = HtmlBeautifier.beautify(info, tab_stops: 4)

# some common issues fixed in a brutal way
ugly_info.gsub!(/, which are shown below/,"");
ugly_info.gsub!(/(To integrate.*into your store you need to follow a few simple steps:)/i, '<p translate>\1</p>')
ugly_info.gsub!(/(<li>)([A-Za-z\s]+)$/, "\\1\n<span translate>\\2</span>")
ugly_info.gsub!(/(<li>)(.+)(<\/li>)/, '<li translate>\2\3') # add translate to all li with text
ugly_info.gsub!(/(<.*>.*)'([A-Za-z\s]*)'(.*<\/.*>)/, '\1&quot;\2&quot;\3') # html entity for '
ugly_info.gsub!(/\\"/, '&quot;') # html entity for \""
ugly_info.gsub!(/->/, '&rarr;') # html ent for ->
ugly_info.gsub!(/(<li translate>)(<a.*)(>)(.*<\/a><\/li>)/, '<li>\2 translate>\4') # move translate to link field
ugly_info.gsub!(/([A-Za-z]+)(<\/li>)/, '\1.\2') # add '.' to end of lines
ugly_info.gsub!(/Setup your Internet merchant/, 'Set up your Internet merchant') # fix common spelling mistake
ugly_info.gsub!(/below/,"&REMOVEbelowREMOVE&") # mark `below` for removal
ugly_info.gsub!(/target=_blank/,'target="_blank"') # add quotes for target tag
ugly_info.gsub!(/target='_blank'/,'target="_blank"') # add quotes for target tag
ugly_info.gsub!(/(href=)(http.*?)(\s)/,'\1"\2"\3') # add quotes for href
ugly_info.gsub!(/(href=)'(http.*?)'(\s)/,'\1"\2"\3') # add quotes for href
# ugly_info.gsub!(/:shopPathSSL/,'{{ moduleCtrl.storeUrl }}') # store url


ugly_info = HtmlBeautifier.beautify(ugly_info, tab_stops: 4)

File.open("#{base_path}/#{module_name}-info.tpl.html", 'w') { |f| f.write(ugly_info) } if gen_info





