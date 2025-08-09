# Family Chore Tracker - Requirements Document

## Project Overview

The Family Chore Tracker is a Rails 8 web application designed to help families manage household chores, motivate children through gamification, and prepare them for responsibility in the business world. The system allows parents to set up chores, children to complete daily checklists, and tracks rewards/earnings over time.

## Functional Requirements

### 1. User Management & Authentication

#### 1.1 User Roles
- **Parents/Adults**: Administrative users with full system access
- **Children**: Non-authenticated users who select their profile to access chores
- **Family Unit**: Container grouping all family members

#### 1.2 Authentication Requirements
- Parents must authenticate using secure login (email/password)
- Children access the system through simple name/profile selection
- Session management for both user types
- Secure logout functionality for parents

### 2. Chore Management System

#### 2.1 Chore Types
- **Constant Chores**: Daily recurring tasks assigned to specific children
  - Examples: Make bed, brush teeth, feed pets
  - Appear on child's list every day
  - Assigned to individual children
- **Rotational Chores**: Tasks distributed randomly among children
  - Examples: Take out trash, load dishwasher, sweep floor
  - Rotate fairly among children to prevent monotony
  - Algorithm ensures equal distribution over time

#### 2.2 Chore Properties
- Title and detailed description
- Difficulty level (Easy, Medium, Hard)
- Estimated time to complete
- Age appropriateness settings
- Photo/visual aids for clarity
- Point values for completion

#### 2.3 Chore Assignment Rules
- Parents can assign constant chores to specific children
- Rotational chores automatically distributed by system
- Age-based filtering (chores only appear for appropriate age groups)
- Seasonal/conditional chore availability

### 3. Daily Chore Lists

#### 3.1 List Generation
- Automatically generated daily at midnight
- Fallback generation on first child access if missing
- Combines constant + rotational chores for each child
- Maintains fair rotation history for rotational tasks

#### 3.2 Child Interface Requirements
- Mobile-first, touch-friendly design
- Large, clear checkboxes for task completion
- Progress indicator showing completion percentage
- Visual feedback for completed tasks
- Simple navigation suitable for children

#### 3.3 Completion Tracking
- Real-time updates when tasks are marked complete
- Timestamp recording for completion times
- Ability to uncheck tasks if needed
- Automatic progress calculation

### 4. Admin Dashboard

#### 4.1 Family Management
- Add/edit/remove children profiles
- Set age ranges and capabilities
- Manage family settings and preferences
- Configure payout intervals and rules

#### 4.2 Chore Management Interface
- Create, edit, and delete chores
- Assign chores to specific children (constant)
- Set up rotational chore pools
- Configure difficulty levels and point values
- Upload photos/instructions for chores

#### 4.3 Daily Review System
- View completed chores by child and date
- Mark chores as satisfactory/unsatisfactory
- Add notes/feedback for incomplete or poor work
- Ability to reassign unsatisfactory chores

#### 4.4 Analytics & Reporting
- Completion rates by child over time
- Most/least completed chores identification
- Earnings summaries and projections
- Historical trend analysis
- Export capabilities for record keeping

### 5. Extras & Rewards System

#### 5.1 Extra Tasks
- Optional high-value tasks for additional earnings
- Configurable monetary rewards per task
- Can be one-time or recurring opportunities
- Examples: Wash car ($5), Clean garage ($10), Organize closet ($3)

#### 5.2 Earnings Management
- Track accumulated earnings per child
- Display total all-time earnings
- Show current period earnings (until next payout)
- Configurable payout intervals (weekly, bi-weekly, monthly)
- Payout history and records

#### 5.3 Reward Calculation
- Automatic calculation based on completed tasks
- Bonus multipliers for completion streaks
- Deductions for unsatisfactory work (configurable)
- Admin ability to manually adjust earnings

### 6. Historical Tracking

#### 6.1 Data Retention
- Maintain complete history of all chore completions
- Store review notes and feedback
- Track earnings over time
- Preserve family configuration changes

#### 6.2 Historical Views
- Calendar view showing past completed chores
- Filter by child, date range, chore type
- Search functionality for specific chores or dates
- Export historical data for external analysis

### 7. Notification System

#### 7.1 Real-time Updates
- Live updates when children complete chores
- Notification badges for parents when review needed
- Status updates for incomplete chores

#### 7.2 Reminder System
- Optional daily reminders for incomplete chores
- Weekly summary emails for parents
- Payout reminder notifications

## Non-Functional Requirements

### 8. Performance Requirements

#### 8.1 Response Time
- Page load times under 2 seconds
- Real-time updates within 1 second
- Daily list generation under 5 seconds

#### 8.2 Scalability
- Support for families up to 10 children
- Handle 100+ chores per family
- Maintain performance with 1+ years of historical data

### 9. Usability Requirements

#### 9.1 Child-Friendly Design
- Large touch targets (minimum 44px)
- High contrast colors and clear fonts
- Simple, intuitive navigation
- Visual feedback for all interactions
- Minimal text, maximum visual cues

#### 9.2 Parent Administrative Interface
- Professional, efficient dashboard design
- Keyboard shortcuts for power users
- Bulk operation capabilities
- Clear data visualization

### 10. Security & Privacy Requirements

#### 10.1 Data Protection
- Secure password storage using bcrypt
- HTTPS encryption for all communications
- Session security and timeout handling
- Protection against common web vulnerabilities (XSS, CSRF, SQL injection)

#### 10.2 Privacy Considerations
- Minimal data collection (family-focused)
- No external data sharing
- Secure handling of child information
- COPPA compliance considerations

### 11. Technical Requirements

#### 11.1 Browser Support
- Modern browsers (Chrome, Firefox, Safari, Edge)
- Mobile browser optimization
- Progressive Web App capabilities
- Offline functionality for checklists

#### 11.2 Device Support
- Responsive design for desktop, tablet, mobile
- Touch-optimized interface
- Support for various screen sizes
- Accessibility features (WCAG 2.1 AA compliance)

## User Stories

### Parent User Stories

**Epic: Family Setup**
- As a parent, I want to create profiles for each child so I can track their individual progress
- As a parent, I want to set age ranges for my children so age-appropriate chores are assigned
- As a parent, I want to configure payout intervals so I can align with our family's allowance schedule

**Epic: Chore Management**
- As a parent, I want to create daily chores that each child must do so they develop consistent habits
- As a parent, I want to set up rotating chores so no child always gets stuck with the worst jobs
- As a parent, I want to assign difficulty levels to chores so children are appropriately challenged

**Epic: Review & Oversight**
- As a parent, I want to review completed chores so I can ensure quality work
- As a parent, I want to mark unsatisfactory work so children learn to meet standards
- As a parent, I want to see completion trends so I can identify areas needing attention

**Epic: Rewards Management**
- As a parent, I want to set up extra earning opportunities so motivated children can earn more
- As a parent, I want to track each child's earnings so I know how much to pay them
- As a parent, I want to adjust earning rules so the system matches our family values

### Child User Stories

**Epic: Daily Chores**
- As a child, I want to see my daily chore list so I know what I need to do
- As a child, I want to check off completed chores so I can track my progress
- As a child, I want to see how much money I'm earning so I stay motivated

**Epic: Extra Opportunities**
- As a child, I want to see available extra chores so I can earn additional money
- As a child, I want to know how much each extra pays so I can choose which ones to do
- As a child, I want to see my total earnings so I know how much I've made

**Epic: Progress Tracking**
- As a child, I want to see my completion percentage so I know how I'm doing today
- As a child, I want to look back at previous days so I can see my progress over time
- As a child, I want visual feedback when I complete tasks so I feel accomplished

## Acceptance Criteria

### Daily List Generation
- **Given** it's midnight on a new day, **When** the system runs the daily generation job, **Then** each child receives a new list combining their constant chores plus a fair rotation of shared chores
- **Given** a child accesses the app and no daily list exists, **When** they load their profile, **Then** a daily list is generated immediately with proper chore distribution

### Chore Completion
- **Given** a child has uncompleted chores, **When** they tap a chore checkbox, **Then** the chore is marked complete, the progress bar updates, and earnings are calculated
- **Given** a chore is marked complete, **When** a parent reviews it as unsatisfactory, **Then** the chore returns to incomplete status and earnings are adjusted

### Fair Rotation
- **Given** multiple children share rotational chores, **When** daily lists are generated over time, **Then** each child receives an approximately equal distribution of each type of rotational chore

### Admin Review Process
- **Given** children have completed chores, **When** a parent accesses the review dashboard, **Then** they can see all completions with options to mark satisfactory/unsatisfactory and add notes
- **Given** a parent marks work unsatisfactory, **When** the child views their list, **Then** the chore appears as needing to be redone

### Earnings Calculation
- **Given** a child completes chores and extras, **When** the system calculates earnings, **Then** the amounts are correctly totaled and displayed in both current period and all-time views
- **Given** a payout period ends, **When** an admin processes payouts, **Then** current period earnings reset to zero and the amount is recorded in payout history

## Business Rules

### Chore Distribution Rules
1. No child should receive the same rotational chore more than once in a 7-day period unless unavoidable
2. Chores marked as age-inappropriate should never appear on a child's list
3. Constant chores must appear every day unless specifically disabled by admin
4. The system must maintain historical fairness - track rotation over 30-day periods

### Reward Rules
1. Only satisfactory chore completions earn money
2. Extra tasks require admin approval before payment
3. Earnings are calculated in real-time but paid on schedule
4. Parents can manually adjust earnings up or down with required notes

### Review Rules
1. Parents have 48 hours to review completed chores before auto-approval
2. Unsatisfactory marks require written explanation
3. Children can appeal unsatisfactory reviews through parent discussion
4. Emergency chores (safety-related) cannot be marked unsatisfactory

## Assumptions & Constraints

### Assumptions
- Families will have 2-8 children typically
- Children can read at basic level or have parent assistance
- Parents will actively engage with review process
- Internet connectivity available for real-time updates

### Constraints
- Single-family deployment (no multi-tenant requirements)
- English language only in initial version
- Web-based interface only (no native mobile apps)
- Limited offline functionality
- Budget constraints favor simple, maintainable solutions

## Future Enhancements (Out of Scope for MVP)

- Multi-family support for extended families
- Integration with smart home devices
- Photo verification of completed chores
- Advanced gamification with badges and achievements
- Social features (compare with friends)
- Integration with family calendar systems
- Multilingual support
- Native mobile applications
- Voice control integration
- AI-powered chore suggestions based on family patterns