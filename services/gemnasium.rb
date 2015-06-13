#
# Copyright 2015, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'faraday'


module PoiseDashData
  module Services
    class Gemnasium
      def self.update(db, name)
        conn.get("projects/#{name}/dependencies").body
      end

      def self.conn
        @conn ||= Faraday.new(url: 'https://api.gemnasium.com/v1/', headers: {'Accept' => 'application/json'}) do |conn|
          conn.request :basic_auth, 'X', ENV['GEMNASIUM_TOKEN']
          conn.response :json
          conn.adapter Faraday.default_adapter
        end
      end

    end
  end
end
