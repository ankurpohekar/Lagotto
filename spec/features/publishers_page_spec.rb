require "rails_helper"

describe "publishers", type: :feature, vcr: true, js: true do
  before(:each) { sign_in }

  it "show no publishers" do
    visit "/publishers"

    expect(page).to have_css ".alert-info", text: "There are currently no publishers"
    expect(page).to have_css "#new-publisher"
  end

  it "new publisher" do
    visit "/publishers"

    click_link "new-publisher"
    expect(page).to have_css ".alert-info", text: "Please enter a search term"

    fill_in "query", with: "plos"
    click_button "submit"
    expect(page).to have_css ".panel-heading a", text: "Public Library of Science (PLoS)"
  end
end

# expect(page).to have_css "h4.work a", text: "Public Library of Science (PLoS)"
