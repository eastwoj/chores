namespace :sample do
  desc "Create a sample family with Jason, Viviana, Josiah, and Raphaela"
  task create_family: :environment do
    puts "Creating sample family..."

    # Create or find admin role
    admin_role = Role.find_or_create_by!(name: "admin") do |role|
      role.description = "Administrator with full access to family settings and management"
    end
    puts "✓ Admin role created/found"

    # Create or find family
    family = Family.find_or_create_by!(name: "The Sample Family")
    puts "✓ Family '#{family.name}' found/created"

    # Create or find adults
    jason = Adult.find_or_initialize_by(email: "jason@example.com") do |adult|
      adult.first_name = "Jason"
      adult.last_name = "Parent"
      adult.password = "password123"
      adult.password_confirmation = "password123"
      adult.family = family
    end
    
    if jason.new_record?
      jason.save!
      puts "✓ Jason created"
    else
      puts "✓ Jason already exists"
    end
    
    # Ensure Jason has admin role
    unless jason.has_role?("admin")
      jason.adult_roles.find_or_create_by!(role: admin_role)
      puts "✓ Admin role assigned to Jason"
    else
      puts "✓ Jason already has admin role"
    end

    viviana = Adult.find_or_initialize_by(email: "viviana@example.com") do |adult|
      adult.first_name = "Viviana"
      adult.last_name = "Parent"
      adult.password = "password123"
      adult.password_confirmation = "password123"
      adult.family = family
    end
    
    if viviana.new_record?
      viviana.save!
      puts "✓ Viviana created"
    else
      puts "✓ Viviana already exists"
    end
    
    # Ensure Viviana has admin role
    unless viviana.has_role?("admin")
      viviana.adult_roles.find_or_create_by!(role: admin_role)
      puts "✓ Admin role assigned to Viviana"
    else
      puts "✓ Viviana already has admin role"
    end

    # Calculate birth dates
    josiah_birth_date = 8.years.ago.to_date
    raphaela_birth_date = 11.years.ago.to_date

    # Create or find children
    josiah = family.children.find_or_create_by!(first_name: "Josiah") do |child|
      child.birth_date = josiah_birth_date
      child.avatar_color = "#3B82F6" # Blue
      child.active = true
    end
    puts "✓ Josiah found/created (age #{josiah.age})"

    raphaela = family.children.find_or_create_by!(first_name: "Rafa") do |child|
      child.birth_date = raphaela_birth_date
      child.avatar_color = "#EC4899" # Pink
      child.active = true
    end
    puts "✓ Raphaela found/created (age #{raphaela.age})"

    puts "\nSample family setup complete!"
    puts "Family ID: #{family.id}"
    puts "Adults can sign in with:"
    puts "  Jason: jason@example.com / password123"
    puts "  Viviana: viviana@example.com / password123"
  end

  desc "Create sample chores for the family"
  task create_chores: :environment do
    puts "Creating sample chores..."
    
    family = Family.find_by(name: "The Sample Family")
    unless family
      puts "❌ No sample family found. Run 'rails sample:create_family' first."
      exit
    end

    josiah = family.children.find_by(first_name: "Josiah")
    raphaela = family.children.find_by(first_name: "Raphaela")

    # Create constant chores
    constant_chores_data = [
      { title: "Make bed", description: "Make your bed every morning", difficulty: :easy, estimated_minutes: 5, min_age: 5 },
      { title: "Get yourself ready", description: "Get dressed and ready for the day", difficulty: :easy, estimated_minutes: 10, min_age: 6 },
      { title: "Match socks", description: "Match and pair clean socks", difficulty: :easy, estimated_minutes: 5, min_age: 5 },
      { title: "Clean up room", description: "Tidy up bedroom and put things away", difficulty: :medium, estimated_minutes: 15, min_age: 6 },
      { title: "Bring laundry downstairs if full", description: "Check laundry basket and bring down if full", difficulty: :medium, estimated_minutes: 5, min_age: 8 }
    ]

    constant_chores_data.each do |chore_data|
      chore = family.chores.find_or_create_by!(title: chore_data[:title]) do |c|
        c.description = chore_data[:description]
        c.chore_type = :constant
        c.difficulty = chore_data[:difficulty]
        c.estimated_minutes = chore_data[:estimated_minutes]
        c.min_age = chore_data[:min_age]
        c.active = true
      end
      puts "✓ Constant chore: #{chore.title}"

      # Assign constant chores to age-appropriate children
      if chore.age_appropriate_for?(josiah) && !chore.assigned_children.include?(josiah)
        chore.chore_assignments.create!(child: josiah, active: true)
        puts "  → Assigned to Josiah"
      end
      if chore.age_appropriate_for?(raphaela) && !chore.assigned_children.include?(raphaela)
        chore.chore_assignments.create!(child: raphaela, active: true)
        puts "  → Assigned to Raphaela"
      end
    end

    # Create rotational chores
    rotational_chores_data = [
      { title: "Wash dishes once", description: "Wash dishes in the sink", difficulty: :medium, estimated_minutes: 10, min_age: 8 },
      { title: "Clean up TV room", description: "Tidy up and organize the TV room", difficulty: :medium, estimated_minutes: 15, min_age: 7 },
      { title: "Set the table", description: "Set up table for meals", difficulty: :easy, estimated_minutes: 5, min_age: 6 },
      { title: "Clear the table", description: "Clear dishes and items from table after meals", difficulty: :easy, estimated_minutes: 5, min_age: 6 },
      { title: "Refill pimi food and water", description: "Refill pet food and water bowls", difficulty: :easy, estimated_minutes: 5, min_age: 5 },
      { title: "Dust furniture", description: "Dust furniture in common areas", difficulty: :medium, estimated_minutes: 15, min_age: 8 }
    ]

    rotational_chores_data.each do |chore_data|
      chore = family.chores.find_or_create_by!(title: chore_data[:title]) do |c|
        c.description = chore_data[:description]
        c.chore_type = :rotational
        c.difficulty = chore_data[:difficulty]
        c.estimated_minutes = chore_data[:estimated_minutes]
        c.min_age = chore_data[:min_age]
        c.active = true
      end
      puts "✓ Rotational chore: #{chore.title}"
    end

    # Create extras
    extras_data = [
      { title: "Do the laundry", description: "Wash, dry, and fold a load of laundry", difficulty: :hard, estimated_minutes: 60, min_age: 10 },
      { title: "Disinfect remote controls, game controllers, and keyboards", description: "Clean and disinfect frequently used electronics", difficulty: :medium, estimated_minutes: 15, min_age: 8 },
      { title: "Sort and pair shoes in entryway or closets", description: "Organize and pair all shoes in designated areas", difficulty: :easy, estimated_minutes: 20, min_age: 7 }
    ]

    extras_data.each do |extra_data|
      extra = family.extras.find_or_create_by!(title: extra_data[:title]) do |e|
        e.description = extra_data[:description]
        e.difficulty = extra_data[:difficulty]
        e.estimated_minutes = extra_data[:estimated_minutes]
        e.min_age = extra_data[:min_age]
        e.active = true
      end
      puts "✓ Extra: #{extra.title}"
    end

    puts "\nSample chores and extras created!"
    puts "Constant chores: #{family.chores.constant.count}"
    puts "Rotational chores: #{family.chores.rotational.count}"
    puts "Extras: #{family.extras.count}"
    puts "\nYou can now test the chore assignment system!"
  end

  desc "Remove sample family data"
  task destroy_family: :environment do
    puts "Removing sample family data..."
    
    family = Family.find_by(name: "The Sample Family")
    if family
      family.destroy!
      puts "✓ Sample family removed"
    else
      puts "No sample family found"
    end
  end
end