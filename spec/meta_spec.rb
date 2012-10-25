require 'spec_helper'
# This tests our RSpec setup works

describe 'Test suite' do
  it 'has a working ActiveRecord connection' do
    ActiveRecord::Base.connection.execute('SELECT * FROM `sqlite_master`')
  end
end