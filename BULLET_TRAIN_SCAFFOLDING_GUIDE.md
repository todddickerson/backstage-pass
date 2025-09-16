# Bullet Train Super Scaffolding Guide

## Key Commands

### 1. Basic CRUD Scaffolding
```bash
# Full scaffold with model, views, controllers, API, tests
rails generate super_scaffold ModelName ParentModel,Team field:field_type

# Example
rails generate super_scaffold AccessPass Space,Team name:text_field price:number_field
```

### 2. Adding Fields to Existing Models (crud-field)
```bash
# Add field to existing scaffolded model - updates EVERYTHING
rails generate super_scaffold:field ModelName new_field:field_type

# Example  
rails generate super_scaffold:field AccessPass recurring_price:number_field
```

### 3. Skip Flags for Partial Generation
```bash
# Skip migration when model already exists
rails generate super_scaffold Model Parent,Team --skip-migration-generation

# Other skip flags
--skip-model          # Don't create model file
--skip-controller     # Don't create controller
--skip-views          # Don't create views  
--skip-routes         # Don't add routes
--skip-api           # Don't create API endpoints
--skip-tests         # Don't generate tests
```

## Field Types (NOT Database Types!)

Bullet Train uses **field partials** not Rails data types:

### Text Fields
- `text_field` - Simple text input
- `text_area` - Multi-line text
- `trix_editor` - Rich text editor
- `email_field` - Email input
- `password_field` - Password input
- `phone_field` - Phone number

### Numbers & Currency  
- `number_field` - Integer/decimal
- `percentage_field` - Percentage input

### Dates & Times
- `date_field` - Date picker
- `date_and_time_field` - DateTime picker

### Selections
- `super_select` - Enhanced select with search
- `super_select{class_name=Model}` - Model association
- `options{opt1,opt2,opt3}` - Static options (becomes enum)
- `multiple_select` - Multi-select

### Booleans
- `boolean` - Checkbox

### Files
- `file_field` - File upload
- `image_field` - Image upload with preview

### Special
- `color_field` - Color picker
- `cloudinary_image` - Cloudinary integration
- `address_field` - Address with geocoding

### Options & Modifiers
```bash
# Readonly field
field:field_type{readonly}

# Required field
field:field_type{required}

# Association
user:super_select{class_name=User}

# Multiple fields at once
rails generate super_scaffold:field Model field1:type field2:type field3:type
```

## Parent Chain Requirements

Models MUST trace back to Team:
```bash
# Direct child of Team
rails generate super_scaffold Space Team name:text_field

# Nested under Space (which belongs to Team)  
rails generate super_scaffold AccessPass Space,Team name:text_field

# Three levels deep
rails generate super_scaffold AccessPassExperience AccessPass,Space,Team
```

## Common Patterns

### 1. Create Model with Associations
```bash
# Has-many through pattern
rails generate super_scaffold AccessPass Space,Team name:text_field
rails generate super_scaffold AccessPassExperience AccessPass,Space,Team experience:super_select{class_name=Experience}
```

### 2. Add Complex Fields Later
```bash
# Initial simple scaffold
rails generate super_scaffold Product Team name:text_field

# Add fields progressively
rails generate super_scaffold:field Product price:number_field
rails generate super_scaffold:field Product description:trix_editor
rails generate super_scaffold:field Product category:super_select
```

### 3. Working with Existing Database
```bash
# Database/model exists, need UI only
rails generate super_scaffold Model Parent,Team fields --skip-migration-generation
```

## What Gets Generated

Super Scaffold creates/updates:
- ✅ Model with associations
- ✅ Database migration
- ✅ Controller (account namespace)
- ✅ Views (index, show, form, etc.)
- ✅ API controller & views (JSON)
- ✅ Routes (nested properly)
- ✅ Localization files
- ✅ Test files & factories
- ✅ Breadcrumbs
- ✅ Permissions (CanCan)
- ✅ Strong parameters
- ✅ OpenAPI documentation

## Gotchas & Solutions

### Problem: "Model already exists"
```bash
# Solution 1: Skip migration
rails generate super_scaffold Model Parent,Team --skip-migration-generation

# Solution 2: Use crud-field to add to existing
rails generate super_scaffold:field ExistingModel new_field:type
```

### Problem: "Parents must trace back to Team"
```bash
# Wrong - Space doesn't connect to Team
rails generate super_scaffold Experience Space

# Right - Include full parent chain
rails generate super_scaffold Experience Space,Team
```

### Problem: "Invalid attribute type"
```bash
# Wrong - Using Rails types
rails generate super_scaffold Model Team name:string

# Right - Using field partials
rails generate super_scaffold Model Team name:text_field
```

### Problem: Need enum field
```bash
# Create with super_select
rails generate super_scaffold Model Team status:super_select

# Then manually add enum to model
enum :status, {
  draft: 0,
  published: 1,
  archived: 2
}
```

## Best Practices

1. **Plan Before Scaffolding**
   - Write out all fields and relationships first
   - Validate parent chains trace to Team
   - Choose appropriate field partials

2. **Use crud-field for Iterations**
   - Start with minimal scaffold
   - Add fields progressively with crud-field
   - Maintains consistency across app

3. **Review Generated Code**
   - Check strong parameters
   - Verify associations
   - Update validations as needed

4. **Customize After Generation**
   - Add business logic to models
   - Enhance forms with conditions
   - Add custom scopes and methods

## Example Workflow

```bash
# 1. Create Space model
rails generate super_scaffold Space Team \
  name:text_field \
  slug:text_field \
  published:boolean

# 2. Create AccessPass products
rails generate super_scaffold AccessPass Space,Team \
  name:text_field \
  description:trix_editor \
  price_cents:number_field \
  pricing_type:super_select

# 3. Add fields later as needed
rails generate super_scaffold:field AccessPass stock_limit:number_field
rails generate super_scaffold:field AccessPass waitlist_enabled:boolean

# 4. Create join table for experiences
rails generate super_scaffold AccessPassExperience AccessPass,Space,Team \
  experience:super_select{class_name=Experience} \
  included:boolean
```

## References

- Bullet Train Docs: https://bullettrain.co/docs/super-scaffolding
- Field Partials: https://bullettrain.co/docs/field-partials
- Parent Chains: https://bullettrain.co/docs/parent-chains