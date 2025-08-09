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

    raphaela = family.children.find_or_create_by!(first_name: "Raphaela") do |child|
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