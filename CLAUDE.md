# Family Chore Tracker - Project Context

## Architectural Philosophy

The document serves as our architectural north star, ensuring we maintain consistency in design decisions and can onboard new developers effectively. It emphasizes that we're not just building software, but creating a digital representation of how families work together.

This foundation will guide the implementation of the actual PORO classes and rich model enhancements next.

## Core Principles

- Follow Sandi Metz principles: Small objects, single responsibility, composition over inheritance
- Apply Clean Code principles: Meaningful names, dependency inversion, clear interfaces
- Use POROs + Rich Models instead of Service Objects for better testability and maintainability
- Organize business logic into clear categories: Policies, Generators, Calculators, Validators
- Write code that speaks the domain language and reflects how families actually work

## Key Files

- `/Users/jason/Projects/chores/requirements.md` - Complete functional and technical requirements
- `/Users/jason/Projects/chores/architecture.md` - Technical architecture and database design
- `/Users/jason/Projects/chores/architecture_philosophy.md` - Design philosophy and implementation patterns

## Development Guidelines

- Always read the architecture philosophy document before implementing new features
- Create POROs for complex business logic that needs isolated testing
- Keep models rich with domain behavior while maintaining single responsibility
- Use dependency injection for testability
- Follow the established directory structure and naming conventions