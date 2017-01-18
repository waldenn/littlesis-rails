require 'rails_helper'

describe RelationshipsController, type: :controller do
  before(:all) do
    Entity.skip_callback(:create, :after, :create_primary_ext)
    DatabaseCleaner.start
  end

  after(:all) do
    Entity.set_callback(:create, :after, :create_primary_ext)
    DatabaseCleaner.clean
  end

  it { should route(:get, '/relationships/1').to(action: :show, id: 1) }
  it { should route(:post, '/relationships').to(action: :create) }

  describe 'GET #show' do
    before do
      @rel = build(:relationship)
      expect(Relationship).to receive(:find).with('1').and_return(@rel)
      get :show, id: 1
    end

    it { should respond_with(:success) }
    it { should render_template(:show) }

    it 'assigns relationship' do
      expect(assigns(:relationship)).to eql @rel
    end
  end

  describe 'POST #create' do
    login_admin
    let(:e1) { create(:person) }
    let(:e2) { create(:mega_corp_inc) }

    def example_params(entity1_id='10', entity2_id='20')
      {
        relationship: {
          entity1_id: entity1_id,
          entity2_id: entity2_id,
          category_id: '1'
        },
        reference: {
          name: 'Interesting website',
          source_detail: '',
          source: 'http://example.com',
          publication_date: '2016-01-01',
          ref_type: '1'
        }
      }
    end

    context 'with valid params' do
      def post_request
        post :create, example_params(e1.id, e2.id)
      end

      it 'responds with 201' do
        post_request
        expect(response.status).to eq 201
      end

      it 'sends back json with relationship_id' do
        post_request
        expect(JSON.parse(response.body)).to eql ({ "relationship_id" => Relationship.last.id})
      end

      it 'should create a new relationship' do
        expect { post_request }.to change { Relationship.count }.by(1)
      end

      it 'should create a new Reference' do
        expect { post_request }.to change { Reference.count }.by(1)
      end

      it 'should create reference with correct fields' do
        post_request
        r = Reference.last
        expect(r.name).to eql 'Interesting website'
        expect(r.ref_type).to eql 1
        expect(r.object_model).to eql 'Relationship'
        expect(r.object_id). to eql Relationship.last.id
      end
    end

    context 'with invalid params' do
      it 'responds with 400 if missing category_id' do
        post :create, example_params.tap { |x| x[:relationship].delete(:category_id) }
        expect(response.status).to eq 400
      end

      it 'sends error json with bad relationship params' do
        post :create, example_params.tap { |x| x[:relationship].delete(:category_id) }
        expect(JSON.parse(response.body)).to have_key 'relationship'
        expect(JSON.parse(response.body)).to have_key 'reference'
        expect(JSON.parse(response.body)['relationship']).to have_key 'category_id'
      end

      it 'responds with 400 if reference source' do
        post :create, example_params.tap { |x| x[:reference].delete(:source) }
        expect(response.status).to eq 400
      end

      it 'sends error json with reference params' do
        post :create, example_params.tap { |x| x[:reference].delete(:source) }
        expect(JSON.parse(response.body)).to have_key 'relationship'
        expect(JSON.parse(response.body)).to have_key 'reference'
        expect(JSON.parse(response.body)['reference']). to have_key 'source'
        expect(JSON.parse(response.body)['relationship']).not_to have_key 'category_id'
      end

      it 'sends error json with reference & relationship params' do 
        post :create, example_params.tap { |x| x[:reference].delete(:source) }.tap { |x| x[:relationship].delete(:category_id) }
        expect(JSON.parse(response.body)['reference']).to have_key 'source'
        expect(JSON.parse(response.body)['relationship']).to have_key 'category_id'
      end
    end

    describe 'params' do
      before do
        r = build(:generic_relationship)
        allow(r).to receive(:save!)
        allow(Relationship).to receive(:new).and_return(r)
      end

      it do
        should permit(:entity1_id, :entity2_id, :category_id)
                .for(:create, params: example_params).on(:relationship)
      end

      it do
        should permit(:name, :source, :source_detail, :publication_date, :ref_type)
                .for(:create, params: example_params).on(:reference)
      end
    end
  end # end describe POST #create

  describe 'post bulk_add' do
    login_user

    it 'sends error message if given bad reference' do
      post :bulk_add, relationships: [], category_id: 1, reference: { source: '', name: 'important source' }
      expect(response.status).to eq 400
    end

    context 'When submitting two good relationships' do
      before do
        @e1 = create(:corp)
        @e2 = create(:corp)
      end
      let(:relationship1) do
        { 'name' => 'jane doe',
          'blurb' =>  nil,
          'primary_ext' => 'Person',
          'amount' => 500,
          'description1' => 'contribution',
          'start_date' => '2017-01-01',
          'end_date' => nil,
          'is_current' => nil }
      end
      let(:relationship2) do
        { 'name' => @e2.id,
          'blurb' =>  nil,
          'primary_ext' => 'Org',
          'amount' =>  1000,
          'description1' => 'contribution',
          'start_date' => nil,
          'end_date' => nil,
          'is_current' => nil }
      end
      let(:params) do
        { 'entity1_id' => @e1.id,
          'category_id' => 5,
          'reference' => { 'source' => 'http://example.com', 'name' => 'example.com' },
          'relationships' => [relationship1, relationship2]
        }
      end

      it 'should return status 201' do
        post :bulk_add, params
        expect(response.status).to eql 201
      end

      # one entity is new, one isn't
      it 'creates one new entity' do
        expect { post :bulk_add, params }.to change { Entity.count }.by(1)
      end

      it 'creates two relationsips' do
        expect { post :bulk_add, params }.to change { Relationship.count }.by(2)
      end

      it 'creates two donations' do
        expect { post :bulk_add, params }.to change { Donation.count }.by(2)
      end

      it 'creates two References' do
        expect { post :bulk_add, params }.to change { Reference.count }.by(2)
        expect(Reference.last(2).map(&:source)).to eql ['http://example.com'] * 2
      end
    end

    context 'When submitting Relationship with category field' do
      before { @e1 = create(:corp) }

      let(:relationship1) do
        { 'name' => 'Jane Doe',
          'blurb' => nil,
          'primary_ext' => 'Person',
          'description1' => 'board member',
          'start_date' => '2017-01-01',
          'is_board' => true,
          'end_date' => nil,
          'is_current' => nil }
      end
      let(:params) do
        { 'entity1_id' => @e1.id,
          'category_id' => 1,
          'reference' => { 'source' => 'http://example.com', 'name' => 'example.com' },
          'relationships' => [relationship1]
        }
      end
      
      it 'creates one relationship' do
        expect { post :bulk_add, params }.to change { Relationship.count }.by(1)
      end

      it 'creates one Position' do
        expect { post :bulk_add, params }.to change { Position.count }.by(1)
        expect(Position.last.relationship.entity1_id).to eql @e1.id
      end

      it 'updates position' do
        post :bulk_add, params
        expect(Position.last.is_board).to eql true
      end
    end

    context 'bad relationship data' do
      before { @e1 = create(:corp) }
      let(:relationship1) do
        { 'name' => 'Jane Doe',
          'blurb' => nil,
          'primary_ext' => 'Person',
          'description1' => 'board member',
          'start_date' => 'this is not a real date' }
      end
      let(:params) do
        { 'entity1_id' => @e1.id,
          'category_id' => 12,
          'reference' => { 'source' => 'http://example.com', 'name' => 'example.com' },
          'relationships' => [relationship1]
        }
      end
      
      it 'does not create a relationship' do
        expect { post :bulk_add, params }.not_to change { Relationship.count }
      end

      it 'responds with 422' do
        expect { post :bulk_add, params }.not_to change { Relationship.count }
        expect(response.status).to eql 422
      end
    end

    context 'one good relationsihp json and one bad realtionship json' do
      let(:relationship1) do
        { 'name' => 'jane doe',
          'blurb' =>  nil,
          'primary_ext' => 'Person',
          'start_date' => '2017-01-01',
          'end_date' => nil,
          'is_current' => nil }
      end
      let(:relationship2) do
        {'name' => 'evil corp',
         'blurb' => nil,
         'primary_ext' => 'Org',
         'start_date' => 'this is not a real date',
         'end_date' => nil,
         'is_current' => nil }
      end
      let(:params) do
        { 'entity1_id' => create(:corp).id,
          'category_id' => 12,
          'reference' => { 'source' => 'http://example.com', 'name' => 'example.com' },
          'relationships' => [relationship1, relationship2] }
      end

      it 'creates one relationship' do
        expect { post :bulk_add, params }.to change { Relationship.count }.by(1)
      end

      it 'responds with 207' do
        post :bulk_add, params
        expect(response.status).to eql 207
      end
    end
  end

  describe 'make_or_get_entity' do
    login_user
    let(:relationship) { { 'name' => 'new person', 'blurb' => 'words', 'primary_ext' => 'Person', 'is_board' => true } }
    let(:relationship_existing) { { 'name' => '666', 'blurb' => '', 'primary_ext' => 'Person' } }
    let(:relationship_error) { { 'name' => 'i am a cat', 'blurb' => 'meow', 'primary_ext' => nil } }

    specify { expect { |b| controller.send(:make_or_get_entity, relationship, &b) }.to yield_with_args(Entity) }

    it 'creates new entity' do
      expect { controller.send(:make_or_get_entity, relationship) {} }.to change { Entity.count }.by(1) 
    end

    it' finds existing entity' do
      expect(Entity).to receive(:find_by_id).with(666).and_return(create(:person))
      controller.send(:make_or_get_entity, relationship_existing) {}
    end

    context 'With bad data' do
      before do
        @controller = RelationshipsController.new
        allow(@controller).to receive(:current_user).and_return(double(:sf_guard_user_id => 1234))
        @controller.instance_variable_set(:@errors, 0)
      end
      specify { expect { |b| @controller.send(:make_or_get_entity, relationship_error, &b) }.not_to yield_control }
      it 'increases error count' do
        expect { @controller.send(:make_or_get_entity, relationship_error) }
          .to change { @controller.instance_variable_get(:@errors) }.by(1)
      end
    end
  end
end
