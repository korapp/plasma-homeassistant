# Contributing

Thank you for your interest in contributing to the project! Before getting started, please take a moment to read through this guide to understand the development and contribution process.

## Branch Naming

When working on a new feature or bugfix, create a new branch from the `dev` branch:

```bash
git checkout dev
git pull origin dev

# For a new feature
git checkout -b feature/your-feature-name

# For a bugfix
git checkout -b bugfix/your-bugfix-name

```

## Conventional Commits

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification for commit messages. This helps in generating a meaningful changelog and versioning.

In short, it requires the following commit message format:

```
<type>(<optional scope>): <description>

[optional body]

[optional footer(s)]
```

### Examples

`feat(api): add new endpoint for user authentication`

`fix: resolve issue with button alignment`

## Code Style

Please follow the established code style guidelines in the project. If there is no specific guideline, maintain consistency with the existing code.

## Pull Request Process

1. Ensure your changes are based on the `dev` branch.
2. Run tests and linting locally before submitting a pull request.
3. Provide clear and concise pull request descriptions.
4. Reference relevant issues or pull requests in your description.
5. Follow up on reviews and address comments promptly.
