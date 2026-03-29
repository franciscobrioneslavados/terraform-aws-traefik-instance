# Contributing

Thank you for your interest in contributing to this Terraform module!

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion:

1. Check if the issue already exists
2. If not, open a new issue with:
   - Clear description of the problem
   - Terraform version
   - AWS provider version
   - Steps to reproduce

### Submitting Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Run tests (if applicable)
5. Commit with clear messages: `git commit -m "feat: add new feature"`
6. Push to your fork: `git push origin feature/my-feature`
7. Open a Pull Request

### Coding Standards

- Follow Terraform best practices
- Use meaningful variable names
- Add descriptions to all variables and outputs
- Keep resources organized logically
- Test changes before submitting

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/terraform-aws-traefik-instance.git
cd terraform-aws-traefik-instance

# Install dependencies
brew install terraform checkov tflint

# Run validation
terraform fmt -check -recursive
terraform init -backend=false
terraform validate

# Run examples validation
cd examples/basic
terraform init -backend=false
terraform validate

# Run security scan
checkov -d .
```

## Release Process

1. Update `CHANGELOG.md` with changes
2. Create a git tag: `git tag v1.x.x`
3. Push tag: `git push origin --tags`
4. Create GitHub Release with release notes

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
