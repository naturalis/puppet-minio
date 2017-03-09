require 'spec_helper'
describe 'minio' do
  context 'with default values for all parameters' do
    it { should contain_class('minio') }
  end
end
