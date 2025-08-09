# Family Chore Tracker - Seed Data
# Creates a realistic family scenario for development and testing

puts "🏠 Creating family chore tracking seed data..."

# Create the Johnson Family
family = Family.find_or_create_by!(name: "The Johnson Family")
puts "Created family: #{family.name}"

# Create parent accounts
mom = Adult.find_or_create_by!(email: "mom@johnson.family") do |adult|
  adult.family = family
  adult.password = "password123"
  adult.first_name = "Sarah"
  adult.last_name = "Johnson"
  adult.role = "parent"
end

dad = Adult.find_or_create_by!(email: "dad@johnson.family") do |adult|
  adult.family = family
  adult.password = "password123"
  adult.first_name = "Mike"
  adult.last_name = "Johnson"
  adult.role = "parent"
end

puts "Created parents: #{mom.full_name} and #{dad.full_name}"

# Create children with different ages
emma = Child.find_or_create_by!(family: family, first_name: "Emma") do |child|
  child.birth_date = 12.years.ago.to_date
  child.avatar_color = "#FF6B6B"
  child.active = true
end

liam = Child.find_or_create_by!(family: family, first_name: "Liam") do |child|
  child.birth_date = 9.years.ago.to_date
  child.avatar_color = "#4ECDC4"
  child.active = true
end

zoe = Child.find_or_create_by!(family: family, first_name: "Zoe") do |child|
  child.birth_date = 6.years.ago.to_date
  child.avatar_color = "#45B7D1"
  child.active = true
end

puts "Created children: #{[emma, liam, zoe].map(&:first_name).join(", ")}"

# Create constant chores (daily habits)
constant_chores_data = [
  {
    title: "Make Bed",
    description: "Make your bed neatly with pillows arranged",
    chore_type: "constant",
    difficulty: "easy",
    estimated_minutes: 5,
    min_age: 4,
    base_value: 0.25,
    active: true
  },
  {
    title: "Brush Teeth",
    description: "Brush teeth thoroughly for 2 minutes, twice daily",
    chore_type: "constant", 
    difficulty: "easy",
    estimated_minutes: 3,
    min_age: 3,
    base_value: 0.0,
    active: true
  },
  {
    title: "Put Clothes in Hamper",
    description: "Put dirty clothes in the hamper, not on floor",
    chore_type: "constant",
    difficulty: "easy", 
    estimated_minutes: 1,
    min_age: 4,
    base_value: 0.25,
    active: true
  },
  {
    title: "Feed Pet",
    description: "Give Max fresh food and water",
    chore_type: "constant",
    difficulty: "easy",
    estimated_minutes: 5,
    min_age: 6,
    base_value: 1.00,
    active: true
  }
]

constant_chores_data.each do |chore_attrs|
  chore = Chore.find_or_create_by!(
    family: family,
    title: chore_attrs[:title]
  ) do |c|
    c.assign_attributes(chore_attrs)
  end
  puts "Created constant chore: #{chore.title}"
end

# Create rotational chores (shared household tasks)
rotational_chores_data = [
  {
    title: "Take Out Trash",
    description: "Empty all trash cans and take bags to curb",
    chore_type: "rotational",
    difficulty: "easy",
    estimated_minutes: 15,
    min_age: 8,
    base_value: 1.50,
    active: true
  },
  {
    title: "Load Dishwasher",
    description: "Load dirty dishes and run dishwasher",
    chore_type: "rotational",
    difficulty: "medium",
    estimated_minutes: 10,
    min_age: 9,
    base_value: 1.00,
    active: true
  },
  {
    title: "Sweep Kitchen Floor",
    description: "Sweep kitchen floor and dining area",
    chore_type: "rotational",
    difficulty: "easy",
    estimated_minutes: 8,
    min_age: 7,
    base_value: 1.00,
    active: true
  }
]

rotational_chores_data.each do |chore_attrs|
  chore = Chore.find_or_create_by!(
    family: family,
    title: chore_attrs[:title]
  ) do |c|
    c.assign_attributes(chore_attrs)
  end
  puts "Created rotational chore: #{chore.title}"
end

# Create extra earning opportunities
extras_data = [
  {
    title: "Wash Car",
    description: "Wash and dry the family car inside and out", 
    reward_amount: 5.00,
    available_from: Date.current,
    available_until: Date.current + 1.week,
    max_completions: 1,
    active: true
  },
  {
    title: "Weed Garden",
    description: "Pull weeds from flower beds and vegetable garden",
    reward_amount: 3.00,
    available_from: Date.current,
    available_until: Date.current + 3.days,
    max_completions: 3,
    active: true
  }
]

extras_data.each do |extra_attrs|
  extra = Extra.find_or_create_by!(
    family: family,
    title: extra_attrs[:title]
  ) do |e|
    e.assign_attributes(extra_attrs)
  end
  puts "Created extra: #{extra.title} ($#{extra.reward_amount})"
end

puts "✅ Seed data creation complete!"

# Print summary
puts "\n📊 Family Chore Tracker Summary:"
puts "Family: #{family.name}"
puts "Adults: #{family.adults.count}"
puts "Children: #{family.children.count}" 
puts "Active Children: #{family.active_children.count}"
puts "Total Chores: #{family.chores.count}"
puts "  - Constant: #{family.chores.constant.count}"
puts "  - Rotational: #{family.chores.rotational.count}"
puts "Extra Opportunities: #{family.extras.active.count}"

puts "\n🔑 Login Credentials:"
puts "Mom: mom@johnson.family / password123"
puts "Dad: dad@johnson.family / password123"

puts "\n👨‍👩‍👧‍👦 Children:"
family.active_children.each do |child|
  puts "#{child.first_name} (age #{child.age})"
end
