require 'rails_helper'

describe 'edit enity page', type: :feature do
  let(:user) { create_really_basic_user }
  let(:entity) { create(:entity_org, last_user_id: user.sf_guard_user.id) }

  context 'user is not logged in' do
    before { visit edit_entity_path(entity) }
    redirects_to_login_page
  end

  context 'user is logged in' do
    before do
      login_as(user, scope: :user)
      visit edit_entity_path(entity)
    end
    after { logout(user) }

    feature 'Viewing the edit entity page' do
      scenario 'displays header, action buttons, and edit references panel' do
        expect(page.status_code).to eq 200
        expect(page).to have_current_path edit_entity_path(entity)
        page_has_selectors '#actions',
                           '#action-buttons',
                           '#edit-references-panel',
                           '#reference_url',
                           '#reference_name'
        page_has_selector '#entity-name', text: entity.name
      end
    end

    feature "Updating an entity's fields" do
      let(:new_short_description) { Faker::Lorem.sentence }

      context "selecting 'just cleaning up' " do
        scenario 'submitting a new short description' do
          check 'reference_just_cleaning_up'
          fill_in 'entity_blurb', :with => new_short_description
          click_button 'Update'

          expect(page).to have_current_path entity_path(entity)
          expect(entity.reload.blurb).to eql new_short_description
        end
      end

      context 'Adding a new reference' do
        let(:url) { Faker::Internet.unique.url }
        let(:ref_name) { 'reference-name' }
        let(:start_date) { '1950-01-01' }
        let(:update_entity) do
          proc {
            click_button 'create-new-reference-btn'
            fill_in 'reference_url', :with => url
            fill_in 'reference_name', :with => ref_name
            fill_in 'entity_start_date', :with => start_date
            click_button 'Update'
          }
        end

        def verify_redirect_and_start_date
          expect(page).to have_current_path entity_path(entity)
          expect(entity.reload.start_date).to eql start_date
        end

        def verify_last_reference
          expect(Reference.last.attributes.slice('referenceable_id', 'referenceable_type'))
            .to eql({ 'referenceable_id' => entity.id, 'referenceable_type' => 'Entity' })
        end

        context 'When the url does not exist as a document' do
          before do
            @document_count = Document.count
            update_entity.call
          end

          scenario 'updating the start date' do
            verify_redirect_and_start_date
            verify_last_reference
            expect(Document.count).to eql(@document_count + 1)
          end
        end

        context 'When the url already exists as a document' do
          before do
            Document.create!(url: url)
            @document_count = Document.count
            update_entity.call
          end

          scenario 'updating the start date' do
            verify_redirect_and_start_date
            verify_last_reference
            expect(Document.count).to eql(@document_count)
          end
        end

      end # end context adding a new reference
    end # end updating an entity's fields
  end # end context user is logged in
end