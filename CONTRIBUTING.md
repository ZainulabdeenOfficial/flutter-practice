<div align="center">

# 🤝 Contributing to Flutter Practice Projects

*Thank you for your interest in contributing! We welcome contributions from developers of all skill levels.*

</div>

---

## 📖 Table of Contents

- [🎯 Code of Conduct](#-code-of-conduct)
- [🚀 Getting Started](#-getting-started)
- [💡 How Can I Contribute?](#-how-can-i-contribute)
- [📋 Pull Request Process](#-pull-request-process)
- [🎨 Coding Standards](#-coding-standards)
- [📝 Commit Message Guidelines](#-commit-message-guidelines)
- [🐛 Bug Reports](#-bug-reports)
- [💡 Feature Requests](#-feature-requests)
- [📚 Documentation](#-documentation)
- [❓ Questions](#-questions)

---

## 🎯 Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for everyone. We pledge to make participation in our project a harassment-free experience for everyone, regardless of:

- Age, body size, disability, ethnicity, gender identity and expression
- Level of experience, education, socio-economic status
- Nationality, personal appearance, race, religion
- Sexual identity and orientation

### Our Standards

**Positive behavior includes:**
- ✅ Using welcoming and inclusive language
- ✅ Being respectful of differing viewpoints and experiences
- ✅ Gracefully accepting constructive criticism
- ✅ Focusing on what is best for the community
- ✅ Showing empathy towards other community members

**Unacceptable behavior includes:**
- ❌ Trolling, insulting/derogatory comments, and personal or political attacks
- ❌ Public or private harassment
- ❌ Publishing others' private information without permission
- ❌ Other conduct which could reasonably be considered inappropriate

---

## 🚀 Getting Started

### Prerequisites

Before contributing, make sure you have:

1. **Flutter SDK** (version 3.27.4 or later)
2. **Git** installed on your system
3. **A GitHub account**
4. **A code editor** (VS Code or Android Studio recommended)

### Setting Up Your Development Environment

1. **Fork the Repository**
   - Click the "Fork" button at the top right of the repository page

2. **Clone Your Fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/flutter-practice.git
   cd flutter-practice
   ```

3. **Add Upstream Remote**
   ```bash
   git remote add upstream https://github.com/ZainulabdeenOfficial/flutter-practice.git
   ```

4. **Install Dependencies**
   ```bash
   flutter pub get
   ```

5. **Verify Setup**
   ```bash
   flutter doctor
   ```

---

## 💡 How Can I Contribute?

There are many ways to contribute to this project:

### 1. 🐛 Report Bugs

Found a bug? Please check if it's already reported in [Issues](https://github.com/ZainulabdeenOfficial/flutter-practice/issues). If not, create a new issue with:
- Clear, descriptive title
- Steps to reproduce
- Expected vs actual behavior
- Screenshots (if applicable)
- Flutter/Dart version

### 2. ✨ Suggest Enhancements

Have an idea? Open an issue with:
- Clear description of the enhancement
- Why it would be useful
- Possible implementation approach

### 3. 📝 Improve Documentation

- Fix typos or clarify existing documentation
- Add examples or tutorials
- Translate documentation
- Write blog posts or create video tutorials

### 4. 💻 Write Code

- Fix bugs
- Implement new features
- Add new practice projects
- Improve existing projects
- Write tests

### 5. 🎨 Design

- Improve UI/UX of existing projects
- Create design mockups
- Suggest better layouts

---

## 📋 Pull Request Process

### Step 1: Create a Branch

Always create a new branch for your work:

```bash
# Update your fork
git fetch upstream
git checkout main
git merge upstream/main

# Create a new branch
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

**Branch Naming Conventions:**
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Adding or updating tests
- `style/` - Code style changes

### Step 2: Make Your Changes

- Write clean, readable code
- Follow the [coding standards](#-coding-standards)
- Add comments where necessary
- Update documentation if needed
- Test your changes thoroughly

### Step 3: Commit Your Changes

```bash
git add .
git commit -m "type: brief description"
```

See [Commit Message Guidelines](#-commit-message-guidelines) for more details.

### Step 4: Push to Your Fork

```bash
git push origin feature/your-feature-name
```

### Step 5: Create a Pull Request

1. Go to your fork on GitHub
2. Click "Compare & pull request"
3. Fill in the PR template with:
   - **Title:** Clear, concise description
   - **Description:** What changes you made and why
   - **Related Issues:** Link any related issues
   - **Screenshots:** If UI changes are made
   - **Testing:** How you tested the changes

### Step 6: Code Review

- Respond to feedback promptly
- Make requested changes
- Keep discussions professional and constructive
- Once approved, your PR will be merged!

---

## 🎨 Coding Standards

### Dart/Flutter Style Guide

Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style):

#### Naming Conventions

```dart
// Classes, enums, typedefs: UpperCamelCase
class HomePage { }
enum Color { red, green, blue }

// Libraries, packages, directories, files: lowercase_with_underscores
my_package/
  home_page.dart

// Variables, constants, parameters, functions: lowerCamelCase
var itemCount = 3;
const maxTimeout = 1000;
void calculateTotal() { }

// Constants: lowerCamelCase (not SCREAMING_CAPS)
const pi = 3.14;
const defaultTimeout = 1000;
```

#### Formatting

```dart
// Use dartfmt (or flutter format)
flutter format .

// Line length: 80 characters (preferred)
// Use trailing commas for better formatting
Widget build(BuildContext context) {
  return Column(
    children: [
      Text('Hello'),
      Text('World'),
    ],
  );
}
```

#### Best Practices

```dart
// ✅ DO use const constructors when possible
const SizedBox(height: 10);

// ✅ DO use relative imports for files in lib/
import 'package:myapp/widgets/button.dart';

// ✅ DO use meaningful variable names
var userName = 'John'; // ✅ Good
var n = 'John';        // ❌ Bad

// ✅ DO prefer final over var
final name = 'John';

// ✅ DO handle errors appropriately
try {
  // code
} catch (e) {
  print('Error: $e');
}
```

### Widget Structure

```dart
class MyWidget extends StatelessWidget {
  // 1. Constructor
  const MyWidget({Key? key, required this.title}) : super(key: key);

  // 2. Properties
  final String title;

  // 3. Build method
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(title),
    );
  }
}
```

### Project Structure

```
lib/
├── main.dart           # App entry point
├── models/            # Data models
├── screens/           # Screen widgets
├── widgets/           # Reusable widgets
├── services/          # API, database services
├── utils/             # Helper functions
└── constants/         # App constants
```

---

## 📝 Commit Message Guidelines

### Format

```
type: subject

body (optional)

footer (optional)
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, semicolons, etc.)
- **refactor**: Code refactoring
- **test**: Adding or updating tests
- **chore**: Maintenance tasks

### Examples

```bash
feat: add dice game project

docs: update README with project list

fix: resolve null pointer in BMI calculator

style: format code with dartfmt

refactor: simplify login validation logic

test: add unit tests for stopwatch
```

### Best Practices

- ✅ Use present tense ("add" not "added")
- ✅ Use imperative mood ("move" not "moves")
- ✅ Keep subject line under 50 characters
- ✅ Capitalize the subject line
- ✅ Don't end with a period
- ✅ Separate subject from body with blank line

---

## 🐛 Bug Reports

### Before Submitting

1. **Search existing issues** - Your bug might already be reported
2. **Try the latest version** - The bug might be fixed
3. **Check the documentation** - Make sure it's actually a bug

### What to Include

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '...'
3. Scroll down to '...'
4. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment:**
 - OS: [e.g. Windows, macOS, Linux]
 - Flutter Version: [e.g. 3.27.4]
 - Device: [e.g. Pixel 5, iPhone 12]

**Additional context**
Any other information about the problem.
```

---

## 💡 Feature Requests

### Template

```markdown
**Is your feature request related to a problem?**
A clear description of the problem.

**Describe the solution you'd like**
What you want to happen.

**Describe alternatives you've considered**
Other solutions you've thought about.

**Additional context**
Screenshots, mockups, or examples.
```

---

## 📚 Documentation

### What Needs Documentation?

- New features or projects
- Complex code logic
- Setup instructions
- API changes
- Breaking changes

### Documentation Style

- Write in clear, simple language
- Use examples where appropriate
- Include code snippets
- Add screenshots for UI features
- Keep it up to date

---

## ❓ Questions

### Where to Ask?

- **General questions**: [GitHub Discussions](https://github.com/ZainulabdeenOfficial/flutter-practice/discussions)
- **Bug reports**: [GitHub Issues](https://github.com/ZainulabdeenOfficial/flutter-practice/issues)
- **Feature requests**: [GitHub Issues](https://github.com/ZainulabdeenOfficial/flutter-practice/issues)
- **Security issues**: Email zu4425@gmail.com

### Response Time

- We aim to respond to issues within 48 hours
- PRs are typically reviewed within one week
- Be patient and respectful

---

## 🎯 First Time Contributing?

**Don't worry!** Here are some beginner-friendly tasks:

- 📝 Fix typos in documentation
- 🎨 Improve code comments
- 📸 Add screenshots to project READMEs
- 🧪 Write simple test cases
- 📖 Translate documentation

Look for issues labeled:
- `good first issue`
- `help wanted`
- `documentation`
- `beginner friendly`

---

## 🏆 Recognition

Contributors will be:
- Added to our contributors list
- Credited in release notes
- Mentioned in project updates
- Part of our growing community!

---

<div align="center">

## 💙 Thank You!

Your contributions make this project better for everyone.

**Questions?** Feel free to reach out:
- GitHub: [@ZainulabdeenOfficial](https://github.com/ZainulabdeenOfficial)
- Email: zu4425@gmail.com

[Back to Main README](README.md) • [Learning Resources](LEARN.md)

### Happy Contributing! 🚀

</div>
