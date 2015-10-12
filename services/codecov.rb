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
require 'parallel'
require 'travis'


module PoiseDashData
  module Services
    class Codecov
      def self.update(db, name)
        conn.get(name).body.tap do |data|
          raise data['reason'] if data['reason']
          # Save some space/transfer.
          data['report'].delete('files')
          data['report'].delete('suggestions')
          # Query for sparkline data.
          data['sparkline'] = sparkline(name)
        end
      end

      def self.sparkline(name)
        Parallel.map(travis_builds(name), in_threads: 100) do |build|
          commit = build.commit
          coverage_data = conn.get(name, ref: commit.sha).body
          coverage = coverage_data['report'] ? coverage_data['report']['coverage'] : 0
          {id: build.id, commit: commit.sha, number: build.number, coverage: coverage}
        end
      end

      def self.conn
        @conn ||= Faraday.new(url: 'https://codecov.io/api/github/') do |conn|
          conn.response :json
          conn.adapter Faraday.default_adapter
        end
      end

      def self.travis_builds(name)
        ::Travis::Repository.find(name).builds(event_type: 'push').select do |build|
          build.passed?
        end
      end

    end
  end
end
