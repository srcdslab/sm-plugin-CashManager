# Copilot Instructions for CashManager SourcePawn Plugin

## Repository Overview

This repository contains **CashManager**, a SourcePawn plugin for SourceMod that patches the maximum money limit in Counter-Strike: Source (CS:S). The plugin uses memory patching techniques to modify the game's hardcoded 16000 money limit, allowing server administrators to set custom money limits via the `mp_maxmoney` ConVar.

**Key Characteristics:**
- **Language**: SourcePawn (.sp files)
- **Platform**: SourceMod 1.11+ for Counter-Strike: Source only
- **Plugin Type**: Memory patching plugin (modifies game memory directly)
- **Build System**: SourceKnight (Python-based SourcePawn build tool)
- **Complexity**: Low - single-file plugin with gamedata configuration

## Technical Environment

### Dependencies
- **SourceMod**: 1.11.0+ (specified in sourceknight.yaml)
- **Game**: Counter-Strike: Source only (CS:S)
- **Build Tool**: SourceKnight 0.1
- **Compiler**: SourcePawn compiler (spcomp) via SourceKnight

### Project Structure
```
├── .github/
│   ├── workflows/ci.yml          # CI/CD pipeline
│   └── copilot-instructions.md   # This file
├── addons/sourcemod/
│   ├── scripting/
│   │   └── CashManager.sp        # Main plugin source
│   └── gamedata/
│       └── CashManager.games.txt # Game memory signatures
├── sourceknight.yaml            # Build configuration
└── .gitignore                   # Git ignore patterns
```

## Code Style & Standards

### SourcePawn Conventions (Strictly Enforced)
```sourcepawn
#pragma semicolon 1           // Always required
#pragma newdecls required     // Always required

// Variable naming
ConVar mp_maxmoney;           // Global variables (no g_ prefix in this codebase)
int matches = 0;              // camelCase for local variables
Address AddAccountAddr;       // PascalCase for important globals

// Function naming
public void OnPluginStart()   // PascalCase for public functions
void PatchMoney()            // PascalCase for private functions
```

### Memory Management Rules
```sourcepawn
// Handle management (this plugin uses CloseHandle, not delete)
Handle hGameConf = LoadGameConfigFile("CashManager.games");
// ... use handle ...
CloseHandle(hGameConf);       // This plugin uses CloseHandle for gamedata handles

// Address cleanup
Address maxmoney[MAXMATCHES]; // Global address array
// On plugin end, restore original values
StoreToAddress(maxmoney[i], 16000, NumberType_Int32);
maxmoney[i] = Address_Null;   // Clear references

// Note: This plugin predates newer SourceMod handle management
// New code should use 'delete handle' but this plugin maintains
// compatibility with CloseHandle pattern
```

## Plugin-Specific Architecture

### Memory Patching Workflow
1. **Gamedata Loading**: Load signatures and offsets from `CashManager.games.txt`
2. **Address Resolution**: Find `AddAccount` function address using gamedata
3. **Pattern Scanning**: Search for hardcoded 16000 values within function bounds
4. **Memory Patching**: Replace found values with ConVar value
5. **Cleanup**: Restore original values on plugin unload

### Critical Functions
```sourcepawn
public void OnPluginStart()    // Initialize patches, load gamedata
public void OnPluginEnd()     // Restore original memory values
void PatchMoney()             // Apply memory patches
void MaxMoneyChange()         // ConVar change handler
```

### Game Compatibility
- **Supported**: Counter-Strike: Source only
- **Check**: `AskPluginLoad2()` validates game directory
- **Failure**: Plugin fails gracefully on unsupported games

## Build & Development Process

### Build Commands
```bash
# Using SourceKnight (preferred method)
# Note: CI uses maxime1907/action-sourceknight@v1 GitHub Action
pip install sourceknight    # If not available in environment
sourceknight build         # Builds to .sourceknight/package/

# Manual compilation (if spcomp available)
spcomp addons/sourcemod/scripting/CashManager.sp

# CI Build (GitHub Actions)
# The repository uses action-sourceknight@v1 for automated builds
# See .github/workflows/ci.yml for the complete pipeline
```

### CI/CD Pipeline
- **Trigger**: Push, PR, manual dispatch
- **Build**: Ubuntu 24.04 with SourceKnight
- **Output**: Compiled .smx plugin + gamedata package
- **Release**: Automatic releases on tags and main/master branch

### Testing Strategy
Since this is a memory-patching plugin:
1. **Compilation Test**: Ensure plugin compiles without errors
2. **Game Validation**: Must run on CS:S server for functional testing
3. **Memory Safety**: Verify original values are restored on unload
4. **ConVar Testing**: Test `mp_maxmoney` changes apply correctly

## Working with This Plugin

### Making Changes

#### Code Modifications
```sourcepawn
// When modifying memory patches:
1. Update pattern scanning logic in OnPluginStart()
2. Ensure cleanup in OnPluginEnd() matches
3. Test ConVar bounds if changing money limits
4. Verify gamedata signatures are still valid
```

#### Gamedata Updates
```
// When updating CashManager.games.txt:
1. Update signatures for new game versions
2. Verify offsets (AddAccountLen) are correct
3. Test on both Windows and Linux
4. Consider CS:S game updates that change memory layout
```

### Common Tasks

#### Adding New Game Support
1. Add new game section to `CashManager.games.txt`
2. Update `AskPluginLoad2()` game validation
3. Find appropriate function signatures
4. Test memory pattern scanning

#### Debugging Memory Issues
```sourcepawn
// Add debug output in OnPluginStart():
PrintToServer("Found %d money patches", matches);
for(int i = 0; i < matches; i++) {
    PrintToServer("Patch %d at address: %x", i, maxmoney[i]);
}
```

## Error Handling Patterns

### Critical Failures (SetFailState)
```sourcepawn
if(hGameConf == INVALID_HANDLE)
    SetFailState("Failed to load gamedata CashManager.games.txt");

if(!AddAccountAddr)
    SetFailState("Failed to get AddAccount address");
```

### Graceful Degradation
- Plugin fails completely if gamedata can't be loaded
- No partial functionality - all-or-nothing approach
- Game compatibility check prevents crashes

## Performance Considerations

### Optimization Notes
- **Pattern Scanning**: O(n) operation during plugin load only
- **Memory Patching**: O(1) operation triggered by ConVar changes
- **No Runtime Overhead**: No hooks or frequent operations
- **Memory Footprint**: Minimal - only stores addresses

### Scalability Limits
- **MAXMATCHES**: Limited to 10 concurrent patches (adjust if needed)
- **Game Updates**: Signatures may break with game updates
- **Platform Specific**: Separate signatures for Windows/Linux

## Security & Safety

### Memory Safety
- Always restore original values in `OnPluginEnd()`
- Validate addresses before writing
- Bounds checking with `AddAccountLen` offset
- No arbitrary memory access

### Game Integrity
- Only patches money limit values
- Doesn't modify game logic flow
- Reversible changes (restoration on unload)

## Troubleshooting Guide

### Common Issues

1. **"Failed to load gamedata"**
   - Check `CashManager.games.txt` file exists
   - Verify gamedata syntax is correct
   - Ensure file is in correct directory

2. **"Failed to get AddAccount address"**
   - Game version changed, signatures outdated
   - Check SourceMod logs for signature failures
   - May need gamedata update

3. **Plugin loads but money limit doesn't change**
   - Pattern scanning found 0 matches
   - Game memory layout changed
   - Verify `AddAccountLen` offset is correct

4. **Compilation Errors**
   - Ensure SourceMod includes are available
   - Check SourcePawn compiler version compatibility
   - Verify #pragma statements are present

### Debugging Commands
```sourcepawn
// Add to OnPluginStart() for debugging:
LogMessage("CashManager: Loaded gamedata successfully");
LogMessage("CashManager: Found %d memory patches", matches);
LogMessage("CashManager: AddAccount address: %x", AddAccountAddr);
```

## Version Control Best Practices

### Commit Messages
- `feat: add new game support for [game]`
- `fix: update gamedata signatures for latest CS:S update`
- `patch: improve memory pattern scanning reliability`

### Release Strategy
- **Semantic Versioning**: MAJOR.MINOR.PATCH
- **Breaking Changes**: Game compatibility changes
- **Minor Changes**: Feature additions, improved reliability
- **Patches**: Bug fixes, signature updates

---

## Quick Reference

### Essential Files
- `CashManager.sp`: Main plugin logic
- `CashManager.games.txt`: Memory signatures and offsets
- `sourceknight.yaml`: Build configuration

### Key ConVars
- `mp_maxmoney`: Sets maximum money limit (default: 65000)

### Memory Addresses
- `AddAccountAddr`: Base address of money addition function
- `maxmoney[]`: Array of patched memory locations

### Build Output
- Compiled plugin: `.sourceknight/package/common/addons/sourcemod/plugins/CashManager.smx`
- Gamedata: `addons/sourcemod/gamedata/CashManager.games.txt`