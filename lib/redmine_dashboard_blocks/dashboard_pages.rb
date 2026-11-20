# frozen_string_literal: true

module RedmineDashboardBlocks
  # Mehrere Dashboards je Benutzer auf "Meine Seite", oben als Reiter.
  #
  # Redmine kennt nur eine Anordnung je Benutzer (my_page_layout) und die
  # Einstellungen ihrer Blöcke (my_page_settings). Die bleiben die Wahrheit
  # für das gerade gewählte Dashboard – Hinzufügen, Verschieben, Entfernen
  # und Blockeinstellungen funktionieren dadurch unverändert. Die übrigen
  # Dashboards liegen daneben in den Benutzereinstellungen; beim Wechsel
  # tauscht diese Klasse Anordnung und Einstellungen aus.
  #
  # Gespeichert unter pref[:dashboard_blocks_pages]:
  #   { 'active' => 1, 'next_id' => 3,
  #     'pages' => [{ 'id' => 1, 'name' => nil },            # aktiv: Daten bei Redmine
  #                 { 'id' => 2, 'name' => 'Team', 'layout' => {…}, 'settings' => {…} }] }
  # Name nil: Standardname aus der Sprache ("Übersicht").
  class DashboardPages
    KEY = :dashboard_blocks_pages
    MAX_PAGES = 10
    MAX_NAME_LENGTH = 30

    Page = Struct.new(:id, :name, :active, keyword_init: true)

    def initialize(user)
      @pref = user.pref
    end

    def pages
      data['pages'].map do |page|
        Page.new(id: page['id'], name: page['name'], active: page['id'] == active_id)
      end
    end

    def active_id
      data['active']
    end

    def exists?(id)
      raw(id).present?
    end

    def can_add?
      data['pages'].size < MAX_PAGES
    end

    def can_destroy?
      data['pages'].size > 1
    end

    # Zum Dashboard wechseln; false, wenn es nicht existiert oder schon aktiv ist
    def switch(id)
      id = id.to_i
      return false if id == active_id || !exists?(id)

      stash_active
      restore(id)
      save
    end

    # Neues, leeres Dashboard anlegen und dorthin wechseln
    def create(name)
      name = clean_name(name)
      return nil if name.blank? || !can_add?

      stash_active
      id = data['next_id']
      data['next_id'] = id + 1
      data['pages'] << { 'id' => id, 'name' => name }
      @pref.my_page_layout = { 'top' => [], 'left' => [], 'right' => [] }
      @pref.my_page_settings = {}
      data['active'] = id
      save && id
    end

    def rename(id, name)
      page = raw(id)
      name = clean_name(name)
      return false if page.nil? || name.blank?

      page['name'] = name
      save
    end

    # Löschen; war es das gewählte, gilt danach das erste übrige
    def destroy(id)
      id = id.to_i
      return false unless exists?(id) && can_destroy?

      data['pages'].reject! { |page| page['id'] == id }
      restore(data['pages'].first['id']) if id == active_id
      save
    end

    private

    def data
      @data ||= begin
        stored = @pref[KEY]
        if stored.is_a?(Hash) && stored['pages'].present?
          stored.deep_dup
        else
          # Erste Nutzung: die bisherige "Meine Seite" wird Dashboard 1
          { 'active' => 1, 'next_id' => 2, 'pages' => [{ 'id' => 1, 'name' => nil }] }
        end
      end
    end

    def raw(id)
      data['pages'].detect { |page| page['id'] == id.to_i }
    end

    # Gewähltes Dashboard aus Redmines Einstellungen in seinen Eintrag
    def stash_active
      page = raw(active_id)
      page['layout'] = @pref.my_page_layout.deep_dup
      page['settings'] = @pref.my_page_settings.deep_dup
    end

    # Dashboard aus seinem Eintrag in Redmines Einstellungen
    def restore(id)
      page = raw(id)
      @pref.my_page_layout = page.delete('layout') || { 'top' => [], 'left' => [], 'right' => [] }
      @pref.my_page_settings = page.delete('settings') || {}
      data['active'] = page['id']
    end

    def save
      @pref[KEY] = data.deep_dup
      @pref.save
    end

    def clean_name(name)
      name.to_s.squish.first(MAX_NAME_LENGTH)
    end
  end
end
