# Code Style Guidelines for GitHub Copilot

## General Principles

- Write clean, fluent, self-documenting code
- Let the code speak for itself through clear naming and structure
- Minimize comments - use them only when the code cannot be made clearer
- Prefer expressive function and variable names over explanatory comments

## PowerShell Specific Guidelines

### Comments
- **Avoid**: Step-by-step comments in Main functions
- **Avoid**: Inline comments explaining what the code does if the function name is clear
- **Use**: Comments only for complex logic that cannot be simplified or non-obvious business rules

### Function Design
- Function names should clearly describe their purpose (verb-noun pattern)
- Functions should be small and focused on a single responsibility
- Parameters should have descriptive names

### Code Structure
- Organize functions logically before the Main function
- Keep the Main function clean and readable as a high-level workflow
- Use whitespace to separate logical blocks

## Examples

### Good (Fluent Code)
```powershell
function Main {
    Show-Header
    
    if (-not (Test-WingetInstalled)) {
        exit 1
    }
    
    $updateOutput = Get-WingetUpdateOutput
    if ($null -eq $updateOutput) {
        exit 1
    }
    
    $packageIds = Parse-PackageIds -updateOutput $updateOutput
    Show-PackageIds -packageIds $packageIds
    Show-Footer
}
```

### Avoid (Over-commented)
```powershell
function Main {
    # Step 1: Display header
    Show-Header
    
    # Step 2: Check if winget is installed
    if (-not (Test-WingetInstalled)) {
        exit 1
    }
    
    # Step 3: Get winget update output
    $updateOutput = Get-WingetUpdateOutput
    # ...
}
```

## When Comments Are Appropriate

- Complex regex patterns or algorithms
- Workarounds for known issues or limitations
- Business logic that is not immediately obvious
- API contracts or external dependencies
