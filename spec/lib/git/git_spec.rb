# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/git/git.rb'

# rubocop:disable Metrics/LineLength
describe 'Git::Git' do
  include FakeFS::SpecHelpers

  def create_mock_open_status(status)
    status_object = double
    allow(status_object).to receive(:success?) { status == 1 }
    allow(status_object).to receive(:to_s) { status.to_s }
    status_object
  end

  def mock_execute(stdout_andstderr_str, status, execution_count: 1, expected_command: anything)
    # mock the call and repsonse to execute the git command
    expect(Open3).to receive(:capture2e).exactly(execution_count).times do |*args|
      if !expected_command.is_a?(RSpec::Mocks::ArgumentMatchers::AnyArgMatcher) && !expected_command.nil?
        # remove the options hash, we are not going to verify it's contents
        args.reject! { |arg| arg.is_a?(Hash) }

        # confirm we got the args we expected
        expect(args).to eq(expected_command.split(/ /))
      end
      [stdout_andstderr_str, create_mock_open_status(status)]
    end
  end

  it 'can be created' do
    git = Git::Git.new('repository_name')

    expect(git.repository_url).to eq('git@github.com:repository_name.git')
    expect(git.repository_path).to eq('/tmp/git/repository_name')
  end

  it 'can be created with a different cache path' do
    git = Git::Git.new('repository_name', git_cache_path: './mycache')

    expect(git.repository_url).to eq('git@github.com:repository_name.git')
    expect(git.repository_path).to eq('./mycache/repository_name')
  end

  context 'with a git repository' do
    before do
      @git = Git::Git.new('repository_name')
    end

    it 'can execute a command' do
      mock_execute('sample output', 1)
      expect(@git.execute('sample command')).to eq('sample output')
    end

    it 'raises GitError when a command fails' do
      mock_execute('sample output', 0)
      expect { @git.execute('sample command') }.to raise_exception(Git::GitError)
    end

    describe 'clone_repository' do
      it 'can clone into a new directory' do
        response = \
          "Cloning into '#{@git.repository_name}'..." \
          'remote: Counting objects: 1080, done.' \
          'remote: Compressing objects: 100% (83/83), done.' \
          'remote: Total 1080 (delta 34), reused 0 (delta 0), pack-reused 994' \
          'Receiving objects: 100% (1080/1080), 146.75 KiB | 0 bytes/s, done.' \
          'Resolving deltas: 100% (641/641), done.' \
          'Checking connectivity... done.'
        mock_execute(response, 1)
        @git.clone_repository('default_branch')
      end

      it 'can update a previously cloned repository' do
        expect(@git).to receive(:reset).exactly(1).times
        expect(@git).to receive(:checkout_branch)
        mock_execute('Success', 1, execution_count: 3)
        FileUtils.mkpath(@git.repository_path)
        @git.clone_repository('default_branch')
      end
    end

    describe 'push' do
      it 'can push a branch' do
        response = \
          'Counting objects: 20, done.' \
          'Delta compression using up to 8 threads.' \
          'Compressing objects: 100% (18/18), done.' \
          'Writing objects: 100% (20/20), 2.47 KiB | 0 bytes/s, done.' \
          'Total 20 (delta 11), reused 0 (delta 0)' \
          "To #{@git.repository_url}" \
          '19087ab..9cdd9db  master -> master'
        mock_execute(response, 1)
        expect(@git.push).to eq(true)
      end

      it 'can push a branch using dry run' do
        response = \
          "To #{@git.repository_url}" \
          '19087ab..9cdd9db  master -> master'
        mock_execute(response, 1, expected_command: '/usr/bin/git push --dry-run origin')
        expect(@git.push(dry_run: true)).to eq(true)
      end

      it 'can detect if a push results in a no-op' do
        mock_execute("Everything up-to-date\n", 1)
        expect(@git.push).to eq(false)
      end
    end

    describe 'checkout_branch' do
      it 'can checkout a branch' do
        expect(@git).to receive(:reset).exactly(2).times
        mock_execute('Success', 1)
        @git.checkout_branch('branch_name')
      end

      it 'escapes backticks in branch names' do
        expect(@git).to receive(:reset).exactly(2).times
        mock_execute('sample output', 1, expected_command: '/usr/bin/git checkout branch_\\`name')
        @git.checkout_branch('branch_`name')
      end
    end

    describe 'reset' do
      it 'can reset a branch to HEAD of origin' do
        expect(@git).to receive(:current_branch_name).and_return('master')
        mock_execute("HEAD is now at beb5e09 Merge branch 'master'", 1)
        @git.reset
      end

      it 'escapes backticks in branch names' do
        expect(@git).to receive(:current_branch_name).and_return('branch_`name')
        mock_execute('sample output', 1, expected_command: '/usr/bin/git reset --hard origin/branch_\\`name')
        @git.reset
      end
    end

    describe 'get_branch_list' do
      it 'can parse a branch list' do
        mock_execute(
          "origin/test_1~2015-10-19 17:58:24 -0700~Nicholas Ellis~<nellis@invoca.com>\norigin/test_build~2015-10-19 15:03:22 -0700~Bob Smith~<bob@invoca.com>\norigin/test_build_b~2015-10-19 16:52:40 -0700~Nicholas Ellis~<nellis@invoca.com>",
          1
        )

        branch_list = []
        branch_list << Git::GitBranch.new(
          'repository_name',
          'test_1',
          DateTime.iso8601('2015-10-19T17:58:24-0700'),
          'Nicholas Ellis',
          'nellis@invoca.com'
        )
        branch_list << Git::GitBranch.new(
          'repository_name',
          'test_build',
          DateTime.iso8601('2015-10-19T15:03:22-0700'),
          'Bob Smith',
          'bob@invoca.com'
        )
        branch_list << Git::GitBranch.new(
          'repository_name',
          'test_build_b',
          DateTime.iso8601('2015-10-19T16:52:40-0700'),
          'Nicholas Ellis',
          'nellis@invoca.com'
        )

        expect(@git.branch_list).to eq(branch_list)
      end
    end

    describe 'merge_branches' do
      it 'returns false, with conflicts, if merge is not clean' do
        expect(@git).to receive(:current_branch_name).and_return('91/eb/WEB-1723_Ringswitch_DB_Conn_Loss')
        mock_execute(
          "From github.com:/Invoca/web\n" \
          " * branch            85/t/trello_adwords_dashboard_tiles_auto_adjust_font_size -> FETCH_HEAD\n" \
          "warning: Cannot merge binary files: test/fixtures/whitepages.sql (HEAD vs. fedc8e0cfa136d5e1f84005ab6d82235122b0006)\n" \
          "Auto-merging test/workers/adwords_detail_worker_test.rb\n" \
          "CONFLICT (content): Merge conflict in test/workers/adwords_detail_worker_test.rb\n" \
          "CONFLICT (modify/delete): pegasus/backdraft/pegasus_dashboard/spec/views/call_cost_tile_spec.js deleted in fedc8e0cfa136d5e1f84005ab6d82235122b0006 and modified in HEAD. Version HEAD of pegasus/backdraft/pegasus_dashboard/spec/views/call_cost_tile_spec.js left in tree.\n" \
          "    Auto-merging pegasus/backdraft/dist/pegasus_dashboard.js\n" \
          "Automatic merge failed; fix conflicts and then commit the result.\n",
          0
        )

        conflict = Git::GitConflict.new(
          'repository_name',
          '91/eb/WEB-1723_Ringswitch_DB_Conn_Loss',
          '85/t/trello_adwords_dashboard_tiles_auto_adjust_font_size',
          ['test/workers/adwords_detail_worker_test.rb', 'pegasus/backdraft/pegasus_dashboard/spec/views/call_cost_tile_spec.js']
        )
        expect(
          @git.merge_branches(
            '91/eb/WEB-1723_Ringswitch_DB_Conn_Loss',
            '85/t/trello_adwords_dashboard_tiles_auto_adjust_font_size'
          )
        ).to eq([false, conflict])
      end

      it 'aborts unsuccessful merge if requested' do
        expect(@git).to receive(:current_branch_name).and_return('91/eb/WEB-1723_Ringswitch_DB_Conn_Loss')
        mock_execute(
          "From github.com:/Invoca/web\n" \
          " * branch            85/t/trello_adwords_dashboard_tiles_auto_adjust_font_size -> FETCH_HEAD\n" \
          "warning: Cannot merge binary files: test/fixtures/whitepages.sql (HEAD vs. fedc8e0cfa136d5e1f84005ab6d82235122b0006)\n" \
          "Auto-merging test/workers/adwords_detail_worker_test.rb\n" \
          "CONFLICT (content): Merge conflict in test/workers/adwords_detail_worker_test.rb\n" \
          "CONFLICT (modify/delete): pegasus/backdraft/pegasus_dashboard/spec/views/call_cost_tile_spec.js deleted in fedc8e0cfa136d5e1f84005ab6d82235122b0006 and modified in HEAD. Version HEAD of pegasus/backdraft/pegasus_dashboard/spec/views/call_cost_tile_spec.js left in tree.\n" \
          "    Auto-merging pegasus/backdraft/dist/pegasus_dashboard.js\n" \
          'Automatic merge failed; fix conflicts and then commit the result.',
          0
        )
        expect(@git).to receive(:reset)

        conflict = Git::GitConflict.new(
          'repository_name',
          '91/eb/WEB-1723_Ringswitch_DB_Conn_Loss',
          '85/t/trello_adwords_dashboard_tiles_auto_adjust_font_size',
          [
            'test/workers/adwords_detail_worker_test.rb',
            'pegasus/backdraft/pegasus_dashboard/spec/views/call_cost_tile_spec.js'
          ]
        )
        expect(
          @git.merge_branches(
            '91/eb/WEB-1723_Ringswitch_DB_Conn_Loss',
            '85/t/trello_adwords_dashboard_tiles_auto_adjust_font_size',
            keep_changes: false
          )
        ).to eq([false, conflict])
      end

      it 'aborts successful merge if requested' do
        expect(@git).to receive(:current_branch_name).and_return('91/eb/WEB-1723_Ringswitch_DB_Conn_Loss')
        mock_execute(
          "From github.com:/Invoca/web\n" \
          " * branch            85/t/trello_adwords_dashboard_tiles_auto_adjust_font_size -> FETCH_HEAD\n" \
          "Auto-merging test/workers/adwords_detail_worker_test.rb\n" \
          "    Auto-merging pegasus/backdraft/dist/pegasus_dashboard.js\n",
          1
        )
        expect(@git).to receive(:reset)

        expect(
          @git.merge_branches(
            '91/eb/WEB-1723_Ringswitch_DB_Conn_Loss',
            '85/t/trello_adwords_dashboard_tiles_auto_adjust_font_size',
            keep_changes: false
          )
        ).to eq([true, nil])
      end

      it 'returns true, with no conflicts, if merge is clean' do
        expect(@git).to receive(:current_branch_name).and_return('91/eb/WEB-1723_Ringswitch_DB_Conn_Loss')
        mock_execute(
          "From github.com:/Invoca/web\n" \
          " * branch            85/t/trello_adwords_dashboard_tiles_auto_adjust_font_size -> FETCH_HEAD\n" \
          "Auto-merging test/workers/adwords_detail_worker_test.rb\n" \
          "    Auto-merging pegasus/backdraft/dist/pegasus_dashboard.js\n",
          1
        )

        expect(
          @git.merge_branches(
            '91/eb/WEB-1723_Ringswitch_DB_Conn_Loss',
            '85/t/trello_adwords_dashboard_tiles_auto_adjust_font_size'
          )
        ).to eq([true, nil])
      end

      it 'returns false, with no conflicts, if nothing is merged' do
        expect(@git).to receive(:current_branch_name).and_return('91/eb/WEB-1723_Ringswitch_DB_Conn_Loss')
        mock_execute(
          "From github.com:mikeweaver/git-conflict-detector\n" \
          " * branch            master     -> FETCH_HEAD\n" \
          "Already up-to-date.\n",
          1
        )
        expect(
          @git.merge_branches(
            '91/eb/WEB-1723_Ringswitch_DB_Conn_Loss',
            '85/t/trello_adwords_dashboard_tiles_auto_adjust_font_size'
          )
        ).to eq([false, nil])
      end

      it 'checks out branch if needed' do
        expect(@git).to receive(:current_branch_name).and_return('not_the_right_branch')
        expect(@git).to receive(:checkout_branch)
        mock_execute(
          "From github.com:mikeweaver/git-conflict-detector\n" \
          " * branch            master     -> FETCH_HEAD\n" \
          "Already up-to-date.\n",
          1
        )
        expect(
          @git.merge_branches(
            '91/eb/WEB-1723_Ringswitch_DB_Conn_Loss',
            '85/t/trello_adwords_dashboard_tiles_auto_adjust_font_size'
          )
        ).to eq([false, nil])
      end

      it 'merges a tag, if requested' do
        expect(@git).to receive(:current_branch_name).and_return('91/eb/WEB-1723_Ringswitch_DB_Conn_Loss')
        mock_execute(
          "From github.com:/Invoca/web\n" \
          " * branch            85/t/trello_adwords_dashboard_tiles_auto_adjust_font_size -> FETCH_HEAD\n" \
          "Auto-merging test/workers/adwords_detail_worker_test.rb\n" \
          "    Auto-merging pegasus/backdraft/dist/pegasus_dashboard.js\n",
          1
        )

        expect(
          @git.merge_branches(
            '91/eb/WEB-1723_Ringswitch_DB_Conn_Loss',
            '85/t/trello_adwords_dashboard_tiles_auto_adjust_font_size',
            source_tag_name: 'tag_name'
          )
        ).to eq([true, nil])
      end

      it 'escapes backticks and spaces in branch names but not commit messages' do
        expect(@git).to receive(:current_branch_name).and_return('target`name')
        mock_execute(
          "From github.com:/Invoca/web\n" \
              " * branch            85/t/trello_adwords_dashboard_tiles_auto_adjust_font_size -> FETCH_HEAD\n" \
              "Auto-merging test/workers/adwords_detail_worker_test.rb\n",
          1,
          expected_command: '/usr/bin/git merge --no-edit -m "commit `message" origin/source\\`name\ space'
        )

        @git.merge_branches(
          'target`name',
          'source`name space',
          commit_message: 'commit `message'
        )
      end
    end

    describe 'lookup_tag' do
      it 'can lookup a tag' do
        mock_execute("tag-exists\n", 1)
        expect(@git.lookup_tag('tag-e*')).to eq('tag-exists')
      end

      it 'raises when the tag cannot be found' do
        mock_execute('fatal: No names found, cannot describe anything.', 0)
        expect { @git.lookup_tag('does-not-exist') }.to raise_exception(Git::GitError)
      end
    end

    describe 'file_diff_branch_with_ancestor' do
      it 'can diff the branch' do
        mock_execute("file1.txt\nfile2.txt\n", 1)
        expect(@git.file_diff_branch_with_ancestor('branch', 'ancestor_branch')).to eq(['file1.txt', 'file2.txt'])
      end

      it 'can handle an up to date branch' do
        mock_execute('', 1)
        expect(@git.file_diff_branch_with_ancestor('branch', 'ancestor_branch')).to eq([])
      end

      it 'escapes backticks in branch names' do
        mock_execute(
          "file1.txt\nfile2.txt\n",
          1,
          expected_command: '/usr/bin/git diff --name-only $(git merge-base origin/ancestor\\`_branch origin/branch\\`name)..origin/branch\\`name'
        )
        @git.file_diff_branch_with_ancestor('branch`name', 'ancestor`_branch')
      end
    end

    describe 'commit_diff_refs' do
      it 'can diff a branch' do
        mocked_output = ["efd778098239838c165ffab2f12ad293f32824c8\tAuthor 1\tauthor1@email.com\t2016-07-14T10:09:45-07:00\tMerge branch 'production'\n",
                         "667f3e5347c48c04663209682642fd8d6d93fde2\tAuthor 2\tauthor2@email.com\t2016-07-14T16:46:35-07:00\tMerge pull request #5584 from Owner/repo/dimension_repair\n"].join
        expected_array = [Git::GitCommit.new('efd778098239838c165ffab2f12ad293f32824c8', "Merge branch 'production'", nil, 'Author 1', 'author1@email.com'),
                          Git::GitCommit.new('667f3e5347c48c04663209682642fd8d6d93fde2', 'Merge pull request #5584 from Owner/repo/dimension_repair', nil, 'Author 2', 'author2@email.com')]
        mock_execute(
          mocked_output,
          1,
          expected_command: "/usr/bin/git log --format=%H\t%an\t%ae\t%aI\t%s --no-color origin/ancestor_branch..origin/branch"
        )
        expect(@git.commit_diff_refs('branch', 'ancestor_branch')).to eq(expected_array)
      end

      it 'can handle a comparison with no changes' do
        mock_execute('', 1)
        expect(@git.commit_diff_refs('branch', 'ancestor_branch')).to eq([])
      end

      it 'can fetch before doing the comparison' do
        mock_execute('', 1)
        expect(@git).to receive(:fetch_all)
        expect(@git.commit_diff_refs('branch', 'ancestor_branch', fetch: true)).to eq([])
      end

      it 'can diff a sha with a branch' do
        mock_execute(
          '',
          1,
          expected_command: "/usr/bin/git log --format=%H\t%an\t%ae\t%aI\t%s --no-color origin/ancestor_branch..e2a7e607745d63da4d7f8486e0619e91a410f796"
        )
        @git.commit_diff_refs('e2a7e607745d63da4d7f8486e0619e91a410f796', 'ancestor_branch')
      end

      it 'can diff a sha with a sha' do
        mock_execute(
          '',
          1,
          expected_command: "/usr/bin/git log --format=%H\t%an\t%ae\t%aI\t%s --no-color c5e8de4eb36a2d1b9f66543966ede9ce9cc28a89..e2a7e607745d63da4d7f8486e0619e91a410f796"
        )
        @git.commit_diff_refs('e2a7e607745d63da4d7f8486e0619e91a410f796', 'c5e8de4eb36a2d1b9f66543966ede9ce9cc28a89')
      end

      it 'escapes backticks in ref names' do
        mock_execute(
          '',
          1,
          expected_command: "/usr/bin/git log --format=%H\t%an\t%ae\t%aI\t%s --no-color origin/ancestor\\`_branch..origin/branch\\`name"
        )
        @git.commit_diff_refs('branch`name', 'ancestor`_branch')
      end
    end

    describe 'get_current_branch_name' do
      it 'can get the branch name' do
        mock_execute("path/branch\n", 1)
        expect(@git.current_branch_name).to eq('path/branch')
      end
    end
  end
end
