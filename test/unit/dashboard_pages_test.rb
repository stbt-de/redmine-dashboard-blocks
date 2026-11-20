# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class DashboardPagesTest < ActiveSupport::TestCase
  include RedmineDashboardBlocks::TestHelper
  fixtures(*RedmineDashboardBlocks::TestHelper::FIXTURES)

  def setup
    @user = User.find(2)
    @user.pref.my_page_layout = { 'top' => ['issuequery'], 'left' => ['my_week'], 'right' => [] }
    @user.pref.my_page_settings = { 'my_week' => { target_hours: '32' } }
    @user.pref[:dashboard_blocks_pages] = nil
    @user.pref.save!
  end

  def pages
    RedmineDashboardBlocks::DashboardPages.new(@user.reload)
  end

  def test_bisherige_seite_ist_das_erste_dashboard
    list = pages.pages
    assert_equal [1], list.map(&:id)
    assert list.first.active
    assert_nil list.first.name
    assert_not pages.can_destroy?
  end

  def test_neues_dashboard_ist_leer_und_gewaehlt
    id = pages.create('  Team  ')
    @user.reload

    assert_equal 2, id
    assert_equal ['Team'], pages.pages.select(&:active).map(&:name)
    assert_equal({ 'top' => [], 'left' => [], 'right' => [] }, @user.pref.my_page_layout)
    assert_equal({}, @user.pref.my_page_settings)
  end

  def test_wechsel_tauscht_anordnung_und_einstellungen
    team = pages.create('Team')
    @user.reload.pref.add_block('my_week')
    @user.pref.update_block_settings('my_week', user_id: '3')
    @user.pref.save!

    assert pages.switch(1)
    @user.reload
    assert_equal ['my_week'], @user.pref.my_page_layout['left']
    assert_equal ['issuequery'], @user.pref.my_page_layout['top']
    assert_equal '32', @user.pref.my_page_settings('my_week')[:target_hours]
    assert_nil @user.pref.my_page_settings('my_week')[:user_id]

    assert pages.switch(team)
    @user.reload
    assert_equal ['my_week'], @user.pref.my_page_layout['top']
    assert_equal '3', @user.pref.my_page_settings('my_week')[:user_id]
  end

  def test_wechsel_auf_unbekanntes_oder_aktives_dashboard
    assert_not pages.switch(1)
    assert_not pages.switch(99)
    assert_equal ['issuequery'], @user.reload.pref.my_page_layout['top']
  end

  def test_umbenennen_und_leerer_name
    assert pages.rename(1, 'Start')
    assert_equal 'Start', pages.pages.first.name
    assert_not pages.rename(1, '   ')
    assert_nil pages.create('')
    assert_equal 'x' * 30, pages.tap { |p| p.rename(1, 'x' * 40) }.pages.first.name
  end

  def test_gewaehltes_loeschen_wechselt_zum_ersten
    pages.create('Team')
    assert pages.destroy(2)
    @user.reload

    assert_equal [1], pages.pages.map(&:id)
    assert_equal ['issuequery'], @user.pref.my_page_layout['top']
    assert_not pages.destroy(1), 'das letzte Dashboard bleibt'
  end

  def test_hoechstens_zehn
    9.times { |index| pages.create("D#{index}") }
    assert_not pages.can_add?
    assert_nil pages.create('Elf')
  end
end
