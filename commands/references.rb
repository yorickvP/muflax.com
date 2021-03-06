usage       'references'
summary     'updates references.mkd'
description 'Updates reference file with all internal links.'

required :s, :sites, 'sites'

module Nanoc::CLI::Commands
  class References < ::Nanoc::CLI::CommandRunner

    # collect links in site
    def extract_links site=nil
      current_site = load_site site

      page_links = ["<!-- (auto-generated) internal links for #{current_site.shared? ? "shared content" : "site: #{site}"} -->"]

      current_site.printed_items.each do |i|
        # don't include shared content with sites again
        unless current_site.shared?
          next if i.shared?
        end
        
        page_links << site_link(i[:title], i.identifier, current_site)
      
        unless i[:alt_titles].nil?
          i[:alt_titles].each do |title|
            page_links << site_link(title, i.identifier, current_site)
          end
        end
      end

      page_links
    end

    def site_link title, link, site
      "[#{title}]: #{site.shared? ? "" : site.url}#{link}"
    end
    
    def duplicate_links
      references = []
      
      Dir["content/references/*.mkd"].each do |ref|
        File.open(ref).each_line do |l|
          if m = l.match(/^ \[ (?<link>.+?) \] : /x)
            references << {
              link: m[:link],
              full_link: l.strip,
              file: ref,
            }
          end
        end
      end

      dups = false
      last_ref = nil
      references.sort_by{|x| x[:link]}.each do |ref|
        if not last_ref.nil? and ref[:link] == last_ref[:link]
          puts "Duplicate link '#{ref[:link]}' in '#{ref[:file]}' <-> '#{last_ref[:file]}'!"
          dups = true
        end

        last_ref = ref
      end

      raise "Duplicate links found!" if dups
    end

    def gospel_stories gospel
      ref_file = "content/references/supertext_#{gospel}.mkd"
      puts "header links for: #{ref_file}"

      File.open(ref_file, "w") do |ref|
        File.open("content_gospel/super/#{gospel}.mkd").each do |line|
          m = line.match(/^ \# .*  \( (?<story> S-\S+? ) \) \s+ {\# (?<anchor>s-\S+) } \s*$/x)
          if m
            link = local_link("gospel:super/#{gospel}/##{m[:anchor]}")
            ref.puts "[#{gospel} #{m[:story]}]: #{link}"
          end
        end
      end
    end

    
    def run
      ([nil] + sites_arg(options[:sites])).each do |site|
        shared = site.nil?
        
        # load site
        if shared
          puts "loading: shared content"
        else
          puts "loading: #{site}"
        end
        
        page_links = extract_links site
        puts "#links: #{page_links.size}"

        # save reference file
        ref_file = "content/references/site_#{shared ? "shared" : "#{site}"}.mkd"
        puts "saving to: #{ref_file}"
        File.open(ref_file, "w").write(page_links.join("\n"))
      end

      %w{mark}.each do |gospel|
        gospel_stories gospel
      end
      
      duplicate_links
    end
  end
end

runner Nanoc::CLI::Commands::References

