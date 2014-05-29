require 'spec_helper'

describe Encore::Serializer do
  let(:serializer) { Encore::Serializer::Instance }
  let(:objects) { User.all }
  let(:serialized) { serializer.new(objects, include: include).as_json }

  let(:run_migrations!) do
    run_migration do
      create_table(:users, force: true) do |t|
        t.string :name, default: nil
        t.integer :project_id
      end
      create_table(:projects, force: true) do |t|
        t.string :name, default: nil
        t.integer :user_id
      end
    end
  end

  before do
    run_migrations!
    spawn_objects!
    create_records!
  end

  context 'can access' do
    context 'default' do
      let(:spawn_objects!) do
        spawn_model('User') do
          belongs_to :project
          belongs_to :irrelevant_reflection
        end
        spawn_serializer('UserSerializer') do
          attributes :name, :links

          def can_include
            %i(project)
          end
        end
        spawn_model('Project') do
          has_many :users
        end
        spawn_serializer('ProjectSerializer') do
          attributes :name
        end

      end
      let(:create_records!) do
        User.create name: 'Allan', project_id: 1
        User.create name: 'Doe', project_id: 2
      end
      let(:include) { '' }

      it { expect(serialized[:users][0][:links][:irrelevant_reflection]).to eq(nil) }
    end

    context 'not loaded with access' do
      let(:spawn_objects!) do
        spawn_model('User') do
          belongs_to :project
          belongs_to :irrelevant_reflection
        end
        spawn_serializer('UserSerializer') do
          attributes :name, :links

          def can_include
            %i(project)
          end
        end
        spawn_model('Project') do
          has_many :users
        end
        spawn_serializer('ProjectSerializer') do
          attributes :name
        end

      end
      let(:create_records!) do
        User.create name: 'Allan', project_id: 1
        User.create name: 'Doe', project_id: 2
      end
      let(:include) { '' }

      it { expect(serialized[:users][0][:links][:project].present?).to eq(true) }
    end

    context 'not loaded without access' do
      let(:spawn_objects!) do
        spawn_model('User') do
          belongs_to :project
          belongs_to :irrelevant_reflection
        end
        spawn_serializer('UserSerializer') do
          attributes :name, :links

          def can_include
            %i(project)
          end

          def can_access
            []
          end
        end
        spawn_model('Project') do
          has_many :users
        end
        spawn_serializer('ProjectSerializer') do
          attributes :name
        end

      end
      let(:create_records!) do
        User.create name: 'Allan', project_id: 1
        User.create name: 'Doe', project_id: 2
      end
      let(:include) { '' }

      it { expect(serialized[:users][0][:links][:project].present?).to eq(false) }
    end

    context 'loaded without access' do
      let(:spawn_objects!) do
        spawn_model('User') do
          belongs_to :project
          belongs_to :irrelevant_reflection
        end
        spawn_serializer('UserSerializer') do
          attributes :name, :links

          def can_include
            %i(project)
          end

          def can_access
            []
          end
        end
        spawn_model('Project') do
          has_many :users
        end
        spawn_serializer('ProjectSerializer') do
          attributes :name
        end

      end
      let(:create_records!) do
        User.create name: 'Allan', project_id: 1
        User.create name: 'Doe', project_id: 2
      end
      let(:include) { 'project' }

      it { expect(serialized[:users][0][:links][:project].present?).to eq(true) }
    end
  end

  context 'belongs_to' do
    let(:spawn_objects!) do
      spawn_model('User') do
        belongs_to :project
      end
      spawn_serializer('UserSerializer') do
        attributes :name, :links

        def can_include
          %i(project)
        end
      end
      spawn_model('Project') do
        has_many :users
      end
      spawn_serializer('ProjectSerializer') do
        attributes :name
      end

    end
    let(:create_records!) do
      User.create name: 'Allan', project_id: 1
      User.create name: 'Doe', project_id: 2
    end

    context 'not included' do
      let(:include) { '' }
      let(:expected_project) do
        {
          href: '/projects/1',
          id: '1',
          type: 'projects'
        }
      end

      it { expect(serialized[:users][0][:links][:project]).to eq(expected_project) }
    end

    context 'included' do
      let(:include) { 'project' }
      let(:expected_project) { '1' }

      it { expect(serialized[:users][0][:links][:project]).to eq(expected_project) }
    end
  end

  context 'has_many' do
    let(:spawn_objects!) do
      spawn_model('User') do
        has_many :projects
      end
      spawn_serializer('UserSerializer') do
        attributes :name, :links

        def can_include
          %i(projects)
        end
      end
      spawn_model('Project') do
        belongs_to :user
      end
      spawn_serializer('ProjectSerializer') do
        attributes :name
      end
    end

    let(:create_records!) do
      User.create name: 'Allan'
      User.create name: 'Doe'
      Project.create name: 'p1', user_id: 1
      Project.create name: 'p2', user_id: 1
    end

    context 'not included' do
      let(:include) { '' }
      let(:expected_project) do
        {
          href: '/projects?user_id=1',
          type: 'projects'
        }
      end

      it { expect(serialized[:users][0][:links][:projects]).to eq(expected_project) }
    end

    context 'included' do
      let(:include) { 'projects' }
      let(:expected_project) { %w(1 2) }

      it { expect(serialized[:users][0][:links][:projects]).to eq(expected_project) }
    end
  end

  context 'has_one' do
    let(:spawn_objects!) do
      spawn_model('User') do
        has_one :project
      end
      spawn_serializer('UserSerializer') do
        attributes :name, :links

        def can_include
          %i(project)
        end
      end
      spawn_model('Project')
      spawn_serializer('ProjectSerializer') do
        attributes :name
      end
    end

    let(:create_records!) do
      User.create name: 'Allan'
      User.create name: 'Doe'
      Project.create name: 'p1', user_id: 1
      Project.create name: 'p2', user_id: 2
    end

    context 'not included' do
      let(:include) { '' }
      let(:expected_project) do
        {
          href: '/users/1/project',
          type: 'projects'
        }
      end

      it { expect(serialized[:users][0][:links][:project]).to eq(expected_project) }
    end

    context 'included' do
      let(:include) { 'project' }
      let(:expected_project) { '1' }

      it { expect(serialized[:users][0][:links][:project]).to eq(expected_project) }
    end
  end
end
