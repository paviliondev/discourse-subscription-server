# frozen_string_literal: true

if ENV['SIMPLECOV']
  require 'simplecov'

  SimpleCov.start do
    root "plugins/discourse-subscription-server"
    track_files "plugins/discourse-subscription-server/**/*.rb"
    add_filter { |src| src.filename =~ /(\/spec\/|\/db\/|plugin\.rb)/ }
    SimpleCov.minimum_coverage 95
  end
end

require 'rails_helper'
