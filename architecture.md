# Family Chore Tracker - Architecture Document

## System Overview

The Family Chore Tracker is built using Rails 8 with modern web technologies to create a responsive, real-time family chore management system. The architecture emphasizes simplicity, maintainability, and child-friendly user experience while providing robust administrative capabilities for parents.

### Technology Stack

- **Backend**: Ruby 3.4.5, Rails 8.0.2
- **Database**: PostgreSQL 16
- **Frontend**: Hotwire (Turbo + Stimulus), CSS, JavaScript
- **Authentication**: Devise
- **Authorization**: Pundit
- **Background Jobs**: Solid Queue (Rails 8 default)
- **Caching**: Solid Cache (Rails 8 default)
- **Real-time**: Action Cable via Solid Cable
- **Asset Pipeline**: Propshaft
- **Deployment**: Docker with Kamal
- **Testing**: Minitest (Rails default)

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Web Browser (Children & Parents)          │
└─────────────────────┬───────────────────────────────────────┘
                      │ HTTPS
┌─────────────────────▼───────────────────────────────────────┐
│                    Rails Application                         │
│  ┌─────────────────┐ ┌──────────────────┐ ┌───────────────┐ │
│  │   Controllers   │ │      Views       │ │    Models     │ │
│  │                 │ │                  │ │               │ │
│  │ • Admin         │ │ • Admin Dashboard│ │ • Family      │ │
│  │ • Children      │ │ • Child Interface│ │ • Adult       │ │
│  │ • Chores        │ │ • Chore Forms    │ │ • Child       │ │
│  │ • Reviews       │ │ • Reports        │ │ • Chore       │ │
│  └─────────────────┘ └──────────────────┘ │ • Daily Lists │ │
│                                           │ • Completions │ │
│                                           └───────────────┘ │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                PostgreSQL Database                          │
│  ┌─────────────────────────────────────────────────────────┐│
│  │            Core Tables & Relationships                  ││
│  │                                                         ││
│  │  families → adults, children, chores, family_settings   ││
│  │  children → daily_chore_lists, chore_completions       ││
│  │  chores → chore_completions, chore_assignments         ││
│  │  extras → extra_completions                            ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘

Background Jobs (Solid Queue)
┌─────────────────────────────────────────────────────────────┐
│  • DailyChoreListGenerationJob (runs at midnight)           │
│  • ChoreReminderJob (optional notifications)                │
│  • PayoutCalculationJob (periodic earnings summary)         │
└─────────────────────────────────────────────────────────────┘
```

## Database Schema

### Core Models and Relationships

```ruby
# Family management
Family
├── has_many :adults
├── has_many :children  
├── has_many :chores
├── has_many :extras
└── has_one :family_setting

Adult
├── belongs_to :family
├── devise authentication
└── admin permissions

Child
├── belongs_to :family
├── has_many :daily_chore_lists
├── has_many :chore_completions
├── has_many :extra_completions
└── validates presence of name, age

# Chore system
Chore
├── belongs_to :family
├── has_many :chore_assignments (for constant chores)
├── has_many :chore_completions
├── enum chore_type: [:constant, :rotational]
├── enum difficulty: [:easy, :medium, :hard]
└── validates presence of title, description

DailyChoreList
├── belongs_to :child
├── has_many :chore_completions
├── validates uniqueness of child_id scoped to date
└── auto-generated daily

ChoreCompletion  
├── belongs_to :daily_chore_list
├── belongs_to :chore
├── belongs_to :child
├── enum status: [:pending, :completed, :reviewed_satisfactory, :reviewed_unsatisfactory]
└── timestamps for completion tracking

ChoreAssignment (for constant chores)
├── belongs_to :chore
├── belongs_to :child
└── ensures constant chores appear on child's daily list

# Extras and rewards
Extra
├── belongs_to :family
├── has_many :extra_completions
├── decimal :reward_amount, precision: 8, scale: 2
├── date :available_from, :available_until
└── validates presence of title, reward_amount

ExtraCompletion
├── belongs_to :child
├── belongs_to :extra
├── enum status: [:pending, :completed, :approved, :rejected]
├── decimal :earned_amount, precision: 8, scale: 2
└── timestamps for completion and approval

# Configuration
FamilySetting
├── belongs_to :family
├── integer :payout_interval_days, default: 7
├── decimal :base_chore_value, precision: 8, scale: 2, default: 0.50
├── boolean :auto_approve_after_48_hours, default: true
└── json :notification_settings
```

### Detailed Schema

```sql
-- Core family structure
CREATE TABLE families (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE TABLE adults (
  id BIGSERIAL PRIMARY KEY,
  family_id BIGINT NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  email VARCHAR NOT NULL,
  encrypted_password VARCHAR NOT NULL,
  first_name VARCHAR NOT NULL,
  last_name VARCHAR NOT NULL,
  role VARCHAR DEFAULT 'parent',
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  -- Devise columns
  reset_password_token VARCHAR,
  reset_password_sent_at TIMESTAMP,
  remember_created_at TIMESTAMP,
  sign_in_count INTEGER DEFAULT 0,
  current_sign_in_at TIMESTAMP,
  last_sign_in_at TIMESTAMP,
  current_sign_in_ip INET,
  last_sign_in_ip INET
);

CREATE TABLE children (
  id BIGSERIAL PRIMARY KEY,
  family_id BIGINT NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  first_name VARCHAR NOT NULL,
  birth_date DATE,
  avatar_color VARCHAR DEFAULT '#3B82F6',
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Chore management
CREATE TABLE chores (
  id BIGSERIAL PRIMARY KEY,
  family_id BIGINT NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  title VARCHAR NOT NULL,
  description TEXT,
  instructions TEXT,
  chore_type INTEGER NOT NULL DEFAULT 0, -- 0=constant, 1=rotational
  difficulty INTEGER DEFAULT 0, -- 0=easy, 1=medium, 2=hard  
  estimated_minutes INTEGER,
  min_age INTEGER,
  max_age INTEGER,
  base_value DECIMAL(8,2) DEFAULT 0.50,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE TABLE chore_assignments (
  id BIGSERIAL PRIMARY KEY,
  chore_id BIGINT NOT NULL REFERENCES chores(id) ON DELETE CASCADE,
  child_id BIGINT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  UNIQUE(chore_id, child_id)
);

-- Daily tracking
CREATE TABLE daily_chore_lists (
  id BIGSERIAL PRIMARY KEY,
  child_id BIGINT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  generated_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  UNIQUE(child_id, date)
);

CREATE TABLE chore_completions (
  id BIGSERIAL PRIMARY KEY,
  daily_chore_list_id BIGINT NOT NULL REFERENCES daily_chore_lists(id) ON DELETE CASCADE,
  chore_id BIGINT NOT NULL REFERENCES chores(id) ON DELETE CASCADE,  
  child_id BIGINT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  status INTEGER DEFAULT 0, -- 0=pending, 1=completed, 2=reviewed_satisfactory, 3=reviewed_unsatisfactory
  completed_at TIMESTAMP,
  reviewed_at TIMESTAMP,
  reviewed_by BIGINT REFERENCES adults(id),
  review_notes TEXT,
  earned_amount DECIMAL(8,2) DEFAULT 0.00,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Extras system
CREATE TABLE extras (
  id BIGSERIAL PRIMARY KEY,
  family_id BIGINT NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  title VARCHAR NOT NULL,
  description TEXT,
  reward_amount DECIMAL(8,2) NOT NULL,
  available_from DATE,
  available_until DATE,
  max_completions INTEGER, -- null = unlimited
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE TABLE extra_completions (
  id BIGSERIAL PRIMARY KEY,
  extra_id BIGINT NOT NULL REFERENCES extras(id) ON DELETE CASCADE,
  child_id BIGINT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  status INTEGER DEFAULT 0, -- 0=pending, 1=completed, 2=approved, 3=rejected
  completed_at TIMESTAMP,
  approved_at TIMESTAMP,
  approved_by BIGINT REFERENCES adults(id),
  earned_amount DECIMAL(8,2) DEFAULT 0.00,
  notes TEXT,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Family configuration
CREATE TABLE family_settings (
  id BIGSERIAL PRIMARY KEY,
  family_id BIGINT NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  payout_interval_days INTEGER DEFAULT 7,
  base_chore_value DECIMAL(8,2) DEFAULT 0.50,
  auto_approve_after_48_hours BOOLEAN DEFAULT true,
  notification_settings JSONB DEFAULT '{}',
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  UNIQUE(family_id)
);

-- Indexes for performance
CREATE INDEX idx_chore_completions_child_date ON chore_completions(child_id, created_at);
CREATE INDEX idx_chore_completions_status ON chore_completions(status);
CREATE INDEX idx_daily_chore_lists_date ON daily_chore_lists(date);
CREATE INDEX idx_chores_family_type ON chores(family_id, chore_type);
CREATE INDEX idx_chores_active ON chores(active) WHERE active = true;
CREATE INDEX idx_extra_completions_child ON extra_completions(child_id);
```

## Application Architecture

### MVC Structure

#### Models

```ruby
# app/models/family.rb
class Family < ApplicationRecord
  has_many :adults, dependent: :destroy
  has_many :children, dependent: :destroy  
  has_many :chores, dependent: :destroy
  has_many :extras, dependent: :destroy
  has_one :family_setting, dependent: :destroy
  
  validates :name, presence: true
  
  after_create :create_default_settings
  
  def active_children
    children.where(active: true)
  end
end

# app/models/adult.rb
class Adult < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable
         
  belongs_to :family
  
  validates :first_name, :last_name, presence: true
  
  def full_name
    "#{first_name} #{last_name}"
  end
end

# app/models/child.rb  
class Child < ApplicationRecord
  belongs_to :family
  has_many :daily_chore_lists, dependent: :destroy
  has_many :chore_completions, dependent: :destroy
  has_many :extra_completions, dependent: :destroy
  has_many :chore_assignments, dependent: :destroy
  has_many :constant_chores, -> { where(chore_type: :constant) }, 
           through: :chore_assignments, source: :chore
  
  validates :first_name, presence: true
  validates :birth_date, presence: true
  
  scope :active, -> { where(active: true) }
  
  def age
    return nil unless birth_date
    ((Date.current - birth_date) / 365.25).floor
  end
  
  def current_period_earnings
    # Calculate earnings since last payout
    chore_completions.reviewed_satisfactory
                    .where(reviewed_at: last_payout_date..)
                    .sum(:earned_amount) +
    extra_completions.approved
                    .where(approved_at: last_payout_date..)
                    .sum(:earned_amount)
  end
  
  def total_lifetime_earnings
    chore_completions.reviewed_satisfactory.sum(:earned_amount) +
    extra_completions.approved.sum(:earned_amount)
  end
end

# app/models/chore.rb
class Chore < ApplicationRecord
  belongs_to :family
  has_many :chore_assignments, dependent: :destroy
  has_many :assigned_children, through: :chore_assignments, source: :child
  has_many :chore_completions, dependent: :destroy
  
  enum chore_type: { constant: 0, rotational: 1 }
  enum difficulty: { easy: 0, medium: 1, hard: 2 }
  
  validates :title, presence: true
  validates :chore_type, presence: true
  
  scope :active, -> { where(active: true) }
  scope :age_appropriate, ->(age) { 
    where("(min_age IS NULL OR min_age <= ?) AND (max_age IS NULL OR max_age >= ?)", age, age) 
  }
end

# app/models/daily_chore_list.rb
class DailyChoreList < ApplicationRecord
  belongs_to :child
  has_many :chore_completions, dependent: :destroy
  has_many :chores, through: :chore_completions
  
  validates :date, presence: true, uniqueness: { scope: :child_id }
  
  scope :for_date, ->(date) { where(date: date) }
  
  def completion_percentage
    return 0 if chore_completions.empty?
    (completed_count.to_f / chore_completions.count * 100).round
  end
  
  def completed_count
    chore_completions.completed.count
  end
  
  def pending_review_count
    chore_completions.completed.count - chore_completions.reviewed_satisfactory.count
  end
end
```

#### Controllers

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!, except: [:show, :index] # Allow children access
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  protected
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name])
  end
  
  def current_family
    @current_family ||= current_adult&.family
  end
end

# app/controllers/admin/base_controller.rb
class Admin::BaseController < ApplicationController
  before_action :authenticate_adult!
  before_action :ensure_admin_access
  
  private
  
  def authenticate_adult!
    redirect_to new_adult_session_path unless adult_signed_in?
  end
  
  def ensure_admin_access
    redirect_to root_path unless current_adult&.family
  end
  
  def current_adult
    current_user
  end
end

# app/controllers/admin/dashboard_controller.rb
class Admin::DashboardController < Admin::BaseController
  def index
    @family = current_family
    @children = @family.active_children.includes(:daily_chore_lists)
    @pending_reviews = ChoreCompletion.joins(:child)
                                     .where(child: { family: @family })
                                     .completed
                                     .includes(:chore, :child)
    @recent_completions = ChoreCompletion.joins(:child)
                                        .where(child: { family: @family })
                                        .recent
                                        .includes(:chore, :child)
  end
end

# app/controllers/children_controller.rb  
class ChildrenController < ApplicationController
  skip_before_action :authenticate_user!
  
  def index
    # Simple child selection screen
    @family = Family.first # Single family deployment
    @children = @family&.active_children || []
  end
  
  def show
    @child = Child.find(params[:id])
    @daily_list = @child.daily_chore_lists.find_or_create_by(date: Date.current) do |list|
      list.generated_at = Time.current
      generate_daily_chores(list)
    end
    @chore_completions = @daily_list.chore_completions.includes(:chore)
  end
  
  private
  
  def generate_daily_chores(daily_list)
    DailyChoreListGenerationService.call(daily_list.child, daily_list.date)
  end
end

# app/controllers/chore_completions_controller.rb
class ChoreCompletionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:update]
  
  def update
    @completion = ChoreCompletion.find(params[:id])
    
    if params[:completed] == "true"
      @completion.mark_completed!
    else
      @completion.mark_pending!
    end
    
    respond_to do |format|
      format.turbo_stream
      format.json { render json: @completion }
    end
  end
end
```

#### Views Structure

```
app/views/
├── layouts/
│   ├── application.html.erb          # Main layout
│   ├── admin.html.erb                # Admin dashboard layout
│   └── child.html.erb                # Child-friendly layout
├── children/
│   ├── index.html.erb                # Child selection screen
│   └── show.html.erb                 # Daily chore checklist
├── admin/
│   ├── dashboard/
│   │   └── index.html.erb            # Admin overview
│   ├── chores/
│   │   ├── index.html.erb            # Chore management
│   │   ├── new.html.erb              # Create chore
│   │   └── edit.html.erb             # Edit chore
│   ├── children/
│   │   ├── index.html.erb            # Child management
│   │   └── show.html.erb             # Child details
│   └── reviews/
│       └── index.html.erb            # Review pending chores
└── shared/
    ├── _navigation.html.erb          # Admin navigation
    ├── _child_navigation.html.erb    # Child navigation
    └── _flash_messages.html.erb      # Flash notifications
```

## Service Layer Architecture

### Core Services

```ruby
# app/services/daily_chore_list_generation_service.rb
class DailyChoreListGenerationService
  def self.call(child, date = Date.current)
    new(child, date).call
  end
  
  def initialize(child, date)
    @child = child
    @date = date
    @family = child.family
  end
  
  def call
    daily_list = find_or_create_daily_list
    
    # Add constant chores
    add_constant_chores(daily_list)
    
    # Add rotational chores using fair distribution
    add_rotational_chores(daily_list)
    
    daily_list
  end
  
  private
  
  def add_constant_chores(daily_list)
    constant_chores = @child.constant_chores.active.age_appropriate(@child.age)
    
    constant_chores.each do |chore|
      daily_list.chore_completions.find_or_create_by(chore: chore, child: @child) do |completion|
        completion.earned_amount = chore.base_value
      end
    end
  end
  
  def add_rotational_chores(daily_list)
    rotational_chores = @family.chores.rotational.active.age_appropriate(@child.age)
    assigned_chores = ChoreRotationService.call(@child, @date, rotational_chores)
    
    assigned_chores.each do |chore|
      daily_list.chore_completions.find_or_create_by(chore: chore, child: @child) do |completion|
        completion.earned_amount = chore.base_value
      end  
    end
  end
end

# app/services/chore_rotation_service.rb
class ChoreRotationService
  def self.call(child, date, available_chores)
    new(child, date, available_chores).call
  end
  
  def initialize(child, date, available_chores)
    @child = child
    @date = date
    @available_chores = available_chores
    @family = child.family
  end
  
  def call
    # Implement fair rotation algorithm
    # Consider:
    # - Recent chore history (avoid same chore within 7 days)
    # - Equal distribution across all children
    # - Difficulty balance
    # - Age appropriateness
    
    siblings = @family.active_children
    chores_needed_per_child = calculate_chores_per_child
    
    assign_chores_fairly(siblings, chores_needed_per_child)
  end
  
  private
  
  def calculate_chores_per_child
    # Distribute available rotational chores evenly
    total_chores = @available_chores.count
    active_children_count = @family.active_children.count
    
    (total_chores.to_f / active_children_count).ceil
  end
  
  def assign_chores_fairly(siblings, chores_per_child)
    # Implementation of fair rotation algorithm
    # Returns array of chores assigned to @child
  end
end

# app/services/earnings_calculation_service.rb
class EarningsCalculationService
  def self.call(child, period_start = nil)
    new(child, period_start).call
  end
  
  def initialize(child, period_start)
    @child = child
    @period_start = period_start || child.last_payout_date
  end
  
  def call
    {
      current_period: calculate_current_period_earnings,
      lifetime: calculate_lifetime_earnings,
      breakdown: earnings_breakdown
    }
  end
  
  private
  
  def calculate_current_period_earnings
    # Sum earnings since last payout
  end
  
  def calculate_lifetime_earnings  
    # Sum all historical earnings
  end
  
  def earnings_breakdown
    # Detailed breakdown by chore type, dates, etc.
  end
end
```

## Background Jobs

```ruby
# app/jobs/daily_chore_list_generation_job.rb
class DailyChoreListGenerationJob < ApplicationJob
  queue_as :default
  
  def perform(date = Date.current)
    Family.includes(:children).find_each do |family|
      family.active_children.find_each do |child|
        DailyChoreListGenerationService.call(child, date)
      end
    end
  end
end

# Schedule in config/schedule.rb (if using whenever gem)
# Or use Rails cron job scheduling
# every 1.day, at: '12:01 am' do
#   runner "DailyChoreListGenerationJob.perform_later"
# end

# app/jobs/auto_approval_job.rb  
class AutoApprovalJob < ApplicationJob
  queue_as :default
  
  def perform
    # Auto-approve chores completed > 48 hours ago (configurable)
    ChoreCompletion.completed
                   .where("completed_at < ?", 48.hours.ago)
                   .where(status: :completed)
                   .includes(:daily_chore_list)
                   .find_each do |completion|
      next unless completion.daily_chore_list.child.family.family_setting.auto_approve_after_48_hours
      
      completion.update!(
        status: :reviewed_satisfactory,
        reviewed_at: Time.current,
        reviewed_by: nil # System approval
      )
    end
  end
end
```

## Security Architecture

### Authentication Strategy

```ruby
# Adults use Devise with standard authentication
# Children use simple profile selection with session storage

# app/controllers/concerns/child_authentication.rb
module ChildAuthentication
  extend ActiveSupport::Concern
  
  def current_child
    @current_child ||= Child.find(session[:child_id]) if session[:child_id]
  end
  
  def child_signed_in?
    current_child.present?
  end
  
  def sign_in_child(child)
    session[:child_id] = child.id
    @current_child = child
  end
  
  def sign_out_child
    session[:child_id] = nil
    @current_child = nil
  end
end
```

### Authorization with Pundit

```ruby
# app/policies/application_policy.rb
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end
end

# app/policies/chore_policy.rb
class ChorePolicy < ApplicationPolicy
  def index?
    user.is_a?(Adult) && user.family == record.family
  end
  
  def show?
    # Adults can see their family's chores
    # Children can see chores assigned to them
    if user.is_a?(Adult)
      user.family == record.family
    elsif user.is_a?(Child)
      user.family == record.family && record.age_appropriate_for?(user)
    else
      false
    end
  end
  
  def create?
    user.is_a?(Adult)
  end
  
  def update?
    user.is_a?(Adult) && user.family == record.family
  end
  
  def destroy?
    user.is_a?(Adult) && user.family == record.family
  end
end
```

## Performance Considerations

### Database Optimization

```sql
-- Critical indexes for performance
CREATE INDEX CONCURRENTLY idx_chore_completions_child_date 
  ON chore_completions(child_id, created_at DESC);
  
CREATE INDEX CONCURRENTLY idx_chore_completions_review_queue
  ON chore_completions(status, completed_at) 
  WHERE status = 1; -- completed but not reviewed

CREATE INDEX CONCURRENTLY idx_daily_chore_lists_lookup
  ON daily_chore_lists(child_id, date);

-- Partial indexes for active records
CREATE INDEX CONCURRENTLY idx_chores_active_rotational
  ON chores(family_id, chore_type) 
  WHERE active = true AND chore_type = 1;
```

### Caching Strategy

```ruby
# app/models/child.rb
class Child < ApplicationRecord
  # Cache expensive calculations
  def current_period_earnings
    Rails.cache.fetch("child_#{id}_current_earnings", expires_in: 1.hour) do
      calculate_current_period_earnings
    end
  end
  
  # Invalidate cache when earnings change
  after_update :invalidate_earnings_cache
  
  private
  
  def invalidate_earnings_cache
    Rails.cache.delete("child_#{id}_current_earnings")
  end
end

# Use Russian Doll caching for child checklists
# app/views/children/show.html.erb
<% cache [@child, @daily_list] do %>
  <!-- Child's daily checklist -->
<% end %>
```

### Real-time Updates

```javascript
// app/javascript/controllers/chore_completion_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "progress"]
  
  toggle(event) {
    const checkbox = event.target
    const completionId = checkbox.dataset.completionId
    const completed = checkbox.checked
    
    fetch(`/chore_completions/${completionId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.getCSRFToken()
      },
      body: JSON.stringify({
        completed: completed
      })
    })
    .then(response => response.json())
    .then(data => {
      this.updateProgress(data.completion_percentage)
      this.showFeedback(completed)
    })
  }
  
  updateProgress(percentage) {
    const progressBar = this.progressTarget
    progressBar.style.width = `${percentage}%`
    progressBar.textContent = `${percentage}%`
  }
  
  showFeedback(completed) {
    // Show visual feedback for completion
    if (completed) {
      this.element.classList.add('completed')
      // Maybe trigger a fun animation
    } else {
      this.element.classList.remove('completed')  
    }
  }
  
  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]').getAttribute('content')
  }
}
```

## Deployment Architecture

### Docker Configuration

```dockerfile
# Dockerfile (already generated by Rails 8)
FROM ruby:3.4.5-alpine

# Install dependencies
RUN apk add --no-cache build-base postgresql-dev nodejs npm

# Set working directory
WORKDIR /app

# Copy and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy application
COPY . .

# Precompile assets
RUN bundle exec rails assets:precompile

# Expose port
EXPOSE 3000

# Start server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

### Production Configuration

```yaml
# config/deploy.yml (Kamal configuration)
service: chores
image: family-chores

servers:
  web:
    - 192.168.1.100

registry:
  server: registry.digitalocean.com/family-apps
  username: your-username
  password:
    - REGISTRY_PASSWORD

env:
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_PASSWORD
    - SECRET_KEY_BASE
  clear:
    DATABASE_HOST: postgres
    DATABASE_NAME: chores_production
    RAILS_ENV: production

accessories:
  postgres:
    image: postgres:16
    host: 192.168.1.100
    env:
      secret:
        - POSTGRES_PASSWORD
      clear:
        POSTGRES_DB: chores_production
    files:
      - config/init.sql:/docker-entrypoint-initdb.d/setup.sql
    directories:
      - data:/var/lib/postgresql/data
```

## Testing Strategy

### Test Structure

```ruby
# test/test_helper.rb
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

# test/models/child_test.rb
require "test_helper"

class ChildTest < ActiveSupport::TestCase
  test "should calculate age correctly" do
    child = children(:alice)
    child.birth_date = 10.years.ago.to_date
    
    assert_equal 10, child.age
  end
  
  test "should calculate current period earnings" do
    child = children(:alice)
    
    # Create some completed chores
    completion = chore_completions(:alice_make_bed)
    completion.update!(
      status: :reviewed_satisfactory,
      earned_amount: 0.50,
      reviewed_at: 1.day.ago
    )
    
    assert_equal 0.50, child.current_period_earnings
  end
end

# test/services/daily_chore_list_generation_service_test.rb
require "test_helper"

class DailyChoreListGenerationServiceTest < ActiveSupport::TestCase
  test "generates daily list with constant and rotational chores" do
    child = children(:alice)
    date = Date.current
    
    list = DailyChoreListGenerationService.call(child, date)
    
    assert_not_nil list
    assert_equal date, list.date
    assert_equal child, list.child
    assert list.chore_completions.any?
  end
  
  test "includes constant chores assigned to child" do
    child = children(:alice)
    constant_chore = chores(:make_bed)
    chore_assignments(:alice_make_bed) # Fixture assigning chore to child
    
    list = DailyChoreListGenerationService.call(child)
    
    chore_ids = list.chore_completions.pluck(:chore_id)
    assert_includes chore_ids, constant_chore.id
  end
end

# test/system/child_chore_completion_test.rb
require "application_system_test_case"

class ChildChoreCompletionTest < ApplicationSystemTestCase
  test "child can complete chores from their daily list" do
    child = children(:alice)
    
    visit child_path(child)
    
    assert_text "Today's Chores"
    
    # Check off a chore
    first_chore = find(".chore-item", match: :first)
    checkbox = first_chore.find("input[type=checkbox]")
    checkbox.check
    
    # Should see progress update
    assert_text "Progress: 50%" # Assuming 2 chores, 1 completed
    
    # Should see visual feedback
    assert first_chore.has_css?('.completed')
  end
end
```

## Monitoring and Observability

### Application Monitoring

```ruby
# config/application.rb
config.middleware.use(Rack::Attack) # Rate limiting

# app/controllers/concerns/request_logging.rb
module RequestLogging
  extend ActiveSupport::Concern
  
  included do
    before_action :log_request_details
    after_action :log_response_time
  end
  
  private
  
  def log_request_details
    @request_start = Time.current
    Rails.logger.info({
      request_id: request.request_id,
      method: request.method,
      path: request.path,
      user_type: current_user.class.name,
      user_id: current_user&.id
    }.to_json)
  end
  
  def log_response_time
    duration = (Time.current - @request_start) * 1000
    Rails.logger.info({
      request_id: request.request_id,
      duration_ms: duration.round(2),
      status: response.status
    }.to_json)
  end
end
```

### Health Checks

```ruby
# app/controllers/health_controller.rb
class HealthController < ApplicationController
  skip_before_action :authenticate_user!
  
  def show
    checks = {
      database: check_database,
      cache: check_cache,
      jobs: check_background_jobs
    }
    
    all_healthy = checks.values.all? { |check| check[:status] == 'ok' }
    
    render json: {
      status: all_healthy ? 'ok' : 'error',
      checks: checks,
      timestamp: Time.current.iso8601
    }, status: all_healthy ? 200 : 503
  end
  
  private
  
  def check_database
    ActiveRecord::Base.connection.execute("SELECT 1")
    { status: 'ok', message: 'Database connection successful' }
  rescue => e
    { status: 'error', message: e.message }
  end
  
  def check_cache
    Rails.cache.write('health_check', Time.current.to_i)
    { status: 'ok', message: 'Cache write successful' }
  rescue => e
    { status: 'error', message: e.message }
  end
  
  def check_background_jobs
    # Check if Solid Queue is processing jobs
    recent_jobs = SolidQueue::Job.where('created_at > ?', 5.minutes.ago).count
    { status: 'ok', message: "#{recent_jobs} jobs processed recently" }
  rescue => e
    { status: 'error', message: e.message }
  end
end
```

This comprehensive architecture provides a solid foundation for building a scalable, maintainable family chore tracking application with Rails 8, emphasizing child-friendly user experience while providing robust administrative capabilities for parents.