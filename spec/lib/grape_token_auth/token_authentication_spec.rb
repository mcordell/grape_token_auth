# frozen_string_literal: true
require 'spec_helper'

module GrapeTokenAuth
  RSpec.describe TokenAuthentication do
    describe 'inclusion in a grape API' do
      it 'adds the helper API helper methods' do
        expect(Grape::API).to receive(:helpers).with GrapeTokenAuth::ApiHelpers

        class NewApi < Grape::API
          include GrapeTokenAuth::TokenAuthentication
        end
      end
    end
  end
end
