require 'spec_helper'
describe 'oradb_fs' do
  context 'with default values for all parameters' do
    it { should contain_class('oradb_fs') }
  end
end
