# frozen_string_literal: true

module Jekyll
  module Gensocial
    class Generator < Jekyll::Generator
      safe true
      priority :lowest

      def generate(site)
        config = Utils.deep_merge_hashes(Gensocial::DEFAULTS, site.config.fetch("jekyll-gensocial", {}))

        return unless config["enabled"] == true

        process_docs(site.pages, site: site, config: config)
        process_docs(site.posts.docs, site: site, config: config)
      end

      private

      def process_docs(docs, site:, config:)
        docs.each do |doc|
          doc_config = Utils.deep_merge_hashes(config, doc.data.fetch("jekyll-gensocial", {}))

          image_size = Geometry::Size.new(doc_config["size"])
          text_config = ImageCreator::TextLayerConfig.new(doc_config["text"], base_path: site.source)
          bg_config = ImageCreator::BackgroundLayerConfig.new(doc_config["background"], base_path: site.source)

          text = doc.data["title"] || text_config.string
          image_path = doc.data["image"]

          next if text.nil? || image_path.nil? 

          write_image(
            path: site.in_source_dir(image_path),
            text: text,
            image_size: image_size,
            text_config: text_config,
            bg_config: bg_config
          )

          base = site.source
          dir = File.dirname(image_path)
          name = File.basename(image_path)

          site.static_files << Jekyll::StaticFile.new(site, base, dir, name)
        end
      end

      def write_image(path:, text:, image_size:, text_config: , bg_config:)
        image = get_image_creator(
          text: text,
          image_size: image_size,
          bg_config: bg_config,
          text_config: text_config
        ).image

        image.write(path)
      end

      def get_image_creator(text:, image_size:, bg_config:, text_config:)
        image_creator = ImageCreator::Composer.new(image_size: image_size)
        image_creator.add_bg_layer(config: bg_config)
        image_creator.add_text_layer(text, config: text_config)

        image_creator
      end
    end
  end
end
