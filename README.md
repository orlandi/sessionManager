# sessionManager
A Simple MATLAB session manager to handle different sets of open editor files and paths.

It allows you to create and save different MATLAB sessions.
Each MATLAB session keeps track of opened files in the editor,
the working folder and the current path. (NOT the workspace).
It allows to quickly switch between the sessions.

## FIRST TIME
- Run `sessionManager.init();`  This copies the required files to
the user path.
If startup.m or finish.m files already exist in the userPath, you will
need to copy/edit them yourself.

## USAGE
### To create a new session:
- `sessionManager.new();` It asks for the desired name.
- `sessionManager.new('sessionName');` To automatically create 'sessionName'.

### To save the current session:
- `sessionManager.save();`

### To load an existing session:
- `sessionManager.load();` It asks which session to load.
- `sessionManager.load('sessionName');` To automatically load 'sessionName'.
- `sessionManager.load('list');` To list all existing sessions

### Notes
- When you close MATLAB it asks if you want to save the current
session.

- This manager modifies the main MATLAB window title to keep track
of the current session.

# Change Log

## [0.0.2] - 2021-09-27

### Added
- Added compatibility for multiple MATLAB version installs

### Modified
- Changed lastSession definitions for a popup list on startup
