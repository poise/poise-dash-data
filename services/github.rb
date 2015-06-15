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
    class GitHub
      def self.update(db, name)
        repo = conn.get("repos/#{name}").body
        raise repo['message'] if repo && repo.is_a?(Hash) && repo['message']
        # Delete to save some space and because we don't care.
        repo.delete('parent')
        repo.delete('source')
        branch = conn.get("repos/#{name}/branches/#{repo['default_branch']}").body
        raise branch['message'] if branch && branch.is_a?(Hash) && branch['message']
        pulls = conn.get("repos/#{name}/pulls").body
        raise pulls['message'] if pulls && pulls.is_a?(Hash) && pulls['message']
        {repo: repo, branch: branch, pulls: pulls}
      end

      def self.conn
        @conn ||= begin
          headers = {'Accept' => 'application/vnd.github.v3+json'}
          headers['Authorization'] = "token #{ENV['GITHUB_TOKEN']}" if ENV['GITHUB_TOKEN']
          Faraday.new(url: 'https://api.github.com/', headers: headers) do |conn|
            conn.response :json
            conn.adapter Faraday.default_adapter
          end
        end
      end

    end
  end
end
