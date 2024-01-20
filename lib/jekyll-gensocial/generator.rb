# frozen_string_literal: true
require 'logger'
require 'securerandom'
module Jekyll
  module Gensocial
    class Generator < Jekyll::Generator
      safe true
      priority :lowest

      def generate(site)
        config = Utils.deep_merge_hashes(
          Gensocial::DEFAULTS,
          site.config.fetch("jekyll-gensocial", {})
        )

        return unless config["enabled"] == true

        process_docs(site.pages, :site => site, :config => config)
        process_docs(site.posts.docs, :site => site, :config => config)
      end

      private

      def process_docs(docs, site:, config:)
        docs.each do |doc|
          doc_config = Utils.deep_merge_hashes(config, doc.data.fetch("jekyll-gensocial", {}))
          
          if config["only_on_demand"] == true 
            if !doc.data.fetch("jekyll-gensocial", {}).nil? && !doc.data.fetch("jekyll-gensocial", {}).empty?
              process_doc(doc, :site => site, :config => doc_config)
            end 
          else 
            next if doc.data["image"].nil? || File.exist?(site.in_source_dir(doc.data["image"]))
            process_doc(doc, :site => site, :config => doc_config)
          end
         
          
        end
      end

      def image_config(config, base_path:)
        {
          :size => Geometry::Size.new(config["size"]),
          :text => ImageCreator::TextLayerConfig.new(
            config["text"],
            :base_path => base_path
          ),
          :bg   => ImageCreator::BackgroundLayerConfig.new(
            config["background"],
            :base_path => base_path
          ),
        }
      end

      def process_doc(doc, site:, config:)
        image_config = image_config(config, :base_path => site.source)

        text = doc.data["title"] || image_config[:text].string
        image_path = doc.data["image"]

        return if text.nil? || text.empty?
        return if image_path.nil? && config['default_path'].nil?
        if image_path.nil?
          image_path = config['default_path'] + generate_image_name_from_title(text) + '.png'
        end
        write_image(
          :path         => site.in_source_dir(image_path),
          :text         => text,
          :image_config => image_config
        )
        doc.data["image"] = image_path
        base = site.source
        dir = File.dirname(image_path)
        name = File.basename(image_path)

        site.static_files << Jekyll::StaticFile.new(site, base, dir, name)
      end

      def write_image(path:, text:, image_config:)
        image = get_image_creator(
          :text         => text,
          :image_config => image_config
        ).image
        
        image.write(path)
      end

      def generate_image_name_from_title(title)
        # Grab the first 20 characters of the title
        processed_title = title[0, 20]

        # Generate a short random GUID (we'll just use the first 8 characters of a UUID for brevity)
        short_guid = SecureRandom.uuid[0, 8]

        # Append the short GUID to the processed title
        full_title = "#{processed_title}-#{short_guid}"

        # Make the title URL-friendly
        # downcase, replace spaces with hyphens, and remove non-alphanumeric characters except hyphens
        url_friendly_title = full_title.downcase.gsub(' ', '-').gsub(/[^a-z0-9-]/, '')

        return url_friendly_title
      end


      def get_image_creator(text:, image_config:)
        image_creator = ImageCreator::Composer.new(:image_size => image_config[:size])
        image_creator.add_bg_layer(:config => image_config[:bg])
        image_creator.add_text_layer(text, :config => image_config[:text])

        image_creator
      end
    end
  end
end
