module EntitiesHelper


  def entity_hash_link(entity, name=nil, action=nil)
    name ||= entity['name']
    link_to name, Entity.legacy_url(entity['primary_ext'], entity['id'], name, action)
  end

  def tiny_entity_image(entity)
    content_tag('div', nil, class: "entity_tiny_image", style: "background-image: url('#{image_path(entity.featured_image_url('small'))}');")
  end

  def legacy_user_path(user)
    '/user/' + user.username
  end

  
  def active_tab?(tab_name, active_tab)
    if active_tab == tab_name
      return 'active'
    else
      return 'inactive'
    end
  end

# Relationships display

  def get_other_positions_and_memberships_heading(positions_count, other_positions_count, memberships_count)
    if other_positions_count == 0
      return 'Memberships'
    elsif memberships_count == 0
      if other_positions_count == positions_count
        return 'Positions'
      else
        return 'Other Positions'
      end
    elsif other_positions_count == positions_count
      return 'Positions & Memberships'
    else
      return 'Other Positions & Memberships'
    end
  end

  def display_section_heading(links)
    content_tag(:div, links.heading, class: "subsection") if links.count > 0
  end

  def get_section_order(entity)
    section_order_person = ['business_positions', 'government_positions', 'in_the_office_positions', 'other_positions_and_memberships', 'schools', 'holdings', 'services_transactions', 'family', 'professional_relationships', 'friendships', 'donation_recipients', 'staff']
    section_order_org = ['parents', 'children', 'other_positions_and_memberships', 'staff']

    entity.person? ? section_order_person : section_order_org
  end

  def group_by_entity(links)
    links.group_by { |l| l.entity2_id }.values
  end

  def order(links)
    return [] if links.empty?
    return links.sort { |a, b| b.related.links.count <=> a.related.links.count } if links[0].category_id == 4
    return links.sort { |a, b| b.relationship.amount <=> a.relationship.amount } if links[0].category_id == 5
    return links.sort { |a, b| LsDate.new(b.relationship.end_date) <=> LsDate.new(a.relationship.end_date) }
  end

  def display_extra_links_count(links)
    return '' if links.count <= 1
    "[+#{links.count - 1}]"
  end
end
