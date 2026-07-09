# Contributing

Thank you for your interest in contributing to the project! Before getting started, please take a moment to read through this guide to understand the development and contribution process.

## AI-Assisted Contributions

AI-assisted tools can be useful for learning, exploring solutions, and reducing repetitive work. However, contributors remain responsible for every change they submit.

Before opening a pull request, make sure you:

- Understand the code you are submitting and can explain how it works.
- Have reviewed AI-generated suggestions critically and made your own implementation decisions.
- Can modify, debug, and maintain the code without depending on AI tools that helped produce it.
- Have verified that the contribution follows this project's style, architecture, tests, and quality standards.

AI tools do not replace engineering judgment, testing, or code review. By submitting a contribution, you take ownership of the code and its long-term maintenance.

If you cannot explain the purpose and behavior of a piece of code, take the time to understand it before including it in your contribution.

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
