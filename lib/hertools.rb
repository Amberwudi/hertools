# frozen_string_literal: true

require 'hertools/version'

module Hertools
  class Error < StandardError; end

  autoload :WebsiteParser, 'hertools/website_parser'
end
