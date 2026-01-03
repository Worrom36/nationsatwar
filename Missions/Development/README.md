# Development Missions

Place your development and test mission files here.

## Mission File Structure

When you extract a `.miz` file, you'll see:
```
MissionName/
├── mission                    # Mission data file
├── options                    # Mission options
├── Scripts/                   # Scripts folder
│   ├── MOOSE/                # MOOSE framework
│   └── TerritorialConquest/ # Mission scripts
└── (other files)
```

## Workflow

1. Create mission in DCS Mission Editor
2. Save to this folder
3. Add scripts using Method 1 (direct file paths) - see `Docs/HOW_TO_ADD_SCRIPTS_TO_MISSION.md`
4. Test in DCS

**Note:** If you need to extract/edit mission files directly, rename `.miz` to `.zip`, extract, edit, then repack as `.miz`.

## Tips

- Keep a backup of working missions
- Test frequently
- Use version control (Git) for scripts
- Don't commit `.miz` files (they're in `.gitignore`)

