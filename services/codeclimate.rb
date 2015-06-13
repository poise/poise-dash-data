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
    class Codeclimate
      def self.update(db, name)
        page = conn.get(name).body
        gpa = page[/<div class="number">([0-9.]+)<\/div>/, 1]
        donut_url = page[/data-source="(\/repos\/\w*\/donut.json)"/, 1]
        donut = JSON.parse(conn.get(donut_url).body)
        {gpa: gpa, donut: donut}
      end

      def self.conn
        @conn ||= Faraday.new(url: 'https://codeclimate.com/github/') do |conn|
          conn.adapter Faraday.default_adapter
        end
      end

    end
  end
end
