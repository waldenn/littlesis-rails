describe 'lists/new.html.erb' do 
  describe 'layout with no error' do
    context 'not admin' do 
      before do
        assign(:list, List.new)
        allow(view).to receive(:current_user).and_return(double(:admin? => false))
        render
      end

      it 'contains one form' do
        expect(rendered).to have_selector('form', :count => 1 )
      end

      it 'contains 4 text inputs' do
        expect(rendered).to have_selector('input[type=text]', :count => 4 )
      end

      it 'contains 1 text_area' do
        expect(rendered).to have_selector('textarea', :count => 1 )
      end
      
      it 'contains 1 checkboxes' do
        expect(rendered).to have_selector('input[type=checkbox]', :count => 1 )
      end

      it 'contains 1 submit button' do
        expect(rendered).to have_selector('input[type=submit]', :count => 1 )
      end

      it 'contains 1 link' do
        expect(rendered).to have_selector('a', :count => 1 )
      end

      it 'contains no error message' do
        expect(rendered).not_to have_selector('#error_explanation')
      end
      
      it 'does not show admin settings' do
        expect(rendered).not_to have_selector('#list-admin-settings-container')
      end

    end

    context 'is admin' do
      before do
        assign(:list, List.new)
        allow(view).to receive(:current_user).and_return(double(:admin? => true))
        render
      end
      
      it 'shows admin settings' do
        expect(view).to render_template(partial: '_settings_admin')
        expect(rendered).to have_selector('#list-admin-settings-container')
      end

    end
  end
  describe 'layout with errors' do 
    it 'has alert when there is an error' do 
      l = List.new
      l.save
      assign(:list, l)
      allow(view).to receive(:current_user).and_return(double(:admin? => false))
      render
      expect(rendered).to have_selector('#error_explanation')
    end
  end
end
