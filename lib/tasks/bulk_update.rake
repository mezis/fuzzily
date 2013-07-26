namespace :fuzzily do

  task bulk_update: :environment do
    Rails.application.eager_load!

    models = ActiveRecord::Base.descendants

    selected_models = ENV['MODELS'] && ENV['MODELS'].split(',')
    selected_methods = ENV['FIELDS'] && ENV['FIELDS'].split(',').map{|f| "bulk_update_fuzzy_"+f}

    models.select!{|model| selected_models.include? model.to_s} if selected_models

    models.each do |model|
      if selected_methods
        @methods = selected_methods & model.methods.map(&:to_s)
      else
        @methods = model.methods.grep(/bulk_update_fuzzy/)
      end
      @methods.each do |method|
        puts "Running #{model}\##{method}"
        model.send method
      end
    end
  end
end