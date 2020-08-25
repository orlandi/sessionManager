classdef sessionManager
% SESSIONMANAGER Simple MATLAB session manager
%   Allows you to create and save different MATLAB sessions
%   Each MATLAB session keeps track of opened files in the editor
%   the working folder and the current path. (NOT the workspace)
%   It allows to quickly switch between the sessions.
%
%   FIRST TIME:
%   - Run: sessionManager.init(); % This will copy the required files to
%   the user path.
%   If startup.m or finish.m files already exist in the userPath, you will
%   need to copy/edit them yourself.
%
%   USAGE:
%   To create a new session:
%   - sessionManager.new(); % Will ask for the desired name
%   - sessionManager.new('sessionName'); % To automatically create 'sessionName'
%
%   To save the current session:
%   - sessionManager.save();
%
%   To load an existing session:
%   - sessionManager.load(); % Will ask which session to load
%   - sessionManager.load('sessionName'); % To automatically load 'sessionName'
%
%   When you close MATLAB it will ask if you want to save the current
%   session. It will reopen that session on the next MATLAB run.
%
%   NOTE: this manager modified the main MATLAB window title to keep track
%   of the current session.
%
% Copyright (C) 2020, Javier G. Orlandi <javierorlandi@javierorlandi.com>

  methods(Static)
    function init()
      % INIT Script to initialize the session manager
      if(~exist(fullfile(userpath, 'sessionManager'), 'dir'))
        mkdir(fullfile(userpath, 'sessionManager'));
      end
      if(exist(fullfile(userpath, 'startup.m'), 'file'))
        answer = questdlg({sprintf('startup.m alreaddy exists in %s', userpath), 'Do you want to overwrite it?'},'Overwrite', 'No');
        switch answer
          case 'Yes'
            copyfile('startup.m', fullfile(userpath, 'startup.m'));
          otherwise
            fprintf('Session manager initialization aborted.\n');
            return;
        end
      else
        copyfile('startup.m', fullfile(userpath, 'startup.m'));
      end
      if(exist(fullfile(userpath, 'finish.m'), 'file'))
        answer = questdlg({sprintf('finish.m alreaddy exists in %s', userpath), 'Do you want to overwrite it?'},'Overwrite', 'No');
        switch answer
          case 'Yes'
            copyfile('finish.m', fullfile(userpath, 'finish.m'));
          otherwise
            fprintf('Session manager initialization aborted.\n');
            return;
        end
      else
        copyfile('finish.m', fullfile(userpath, 'finish.m'));
      end
      copyfile('sessionManager.m', fullfile(userpath, 'sessionManager', 'sessionManager.m'));
      copyfile('newid.m', fullfile(userpath, 'sessionManager', 'newid.m'));
      addpath(fullfile(userpath, 'sessionManager'));
      fprintf('sessionManager succesfully initialized.\n');
    end
    
    % ---------------------------------------------------------------------
    function new(varargin)
      % NEW creates a new session
      %
      % USAGE:
      %  - sessionManager.new()
      %  - sessionManager.new('sessionName') - Automatically creates the
      %  session 'sessionName'.
      
      % Try to save the current session - cancel otherwise
      if(~sessionManager.save(false))
        return;
      end
      if(nargin > 0)
        sessionName = varargin{1};
      else
        answer = newid('Enter session name','Session Name', [1 60], {''});
        if(isempty(answer) || isempty(answer{1}))
          return;
        else
          sessionName = answer{1};
          sessionFullFile = fullfile(userpath, 'sessionManager', [sessionName '.sess']);
          if(exist(sessionFullFile, 'file'))
            answer = questdlg({sprintf('A session named "%s" already exists.', sessionName),'Do you want to overwrite it?'},'Overwrite session', 'No');
            switch answer
              case 'Yes'
              otherwise
                return;
            end
          end
        end
      end
      % Generate title for the new session
      w = java.awt.Window.getOwnerlessWindows;
      mainWindow = w(arrayfun(@(x)(isa(x, 'com.mathworks.mde.desk.MLMainFrame')), w));

      mainTitle = sprintf('MATLAB r%s (%s)', version('-release'), version('-description'));
      newTitle = sprintf('%s - %s.sess', mainTitle, sessionName);
      mainWindow.setTitle(newTitle);
      sessionManager.save();
    end
    
    % ---------------------------------------------------------------------
    function success = save(varargin)
      % SAVE saves the current session
      %
      % USAGE:
      %  sessionManager.save()
      %  sessionManager.save(false) - Asks for confirmation
      %
      % OUTPUT:
      % success - True if the session was succesfully loaded. False
      % otherwise.
      
      if(nargin > 0)
        force = varargin{1};
      else
        force = true;
      end
      success = false;
      % Check the title for an open project;
      w = java.awt.Window.getOwnerlessWindows;
      mainWindow = w(arrayfun(@(x)(isa(x, 'com.mathworks.mde.desk.MLMainFrame')), w));
      curTitle = char(mainWindow.getTitle);
      curSession = regexp(curTitle, '- .*.sess$');
      % Check if a session is open (by the tile)
      if(~isempty(curSession))
        curSessionFileName = curTitle((curSession+2):end);
        [~, curSessionName, ~] = fileparts(curSessionFileName);
        % Ask if we want to save
        if(~force)
          answer = questdlg(sprintf( 'Do you want to save the open session (%s)?', curSessionName),'Session save', 'Yes');
        else
          answer = 'Yes';
        end
        switch answer
          case 'Yes'
            sessionFullFile = fullfile(userpath, 'sessionManager', curSessionFileName);
            docArray = matlab.desktop.editor.getAll;
            sessionEditorFiles = cell(1,length(docArray));
            for fIdx = 1:length(docArray)
                sessionEditorFiles{fIdx} = docArray(fIdx).Filename;
            end
            act = matlab.desktop.editor.getActive;
            sessionEditorFilesActive = act.Filename;
            assignin('base','sessionEditorFiles', sessionEditorFiles)
            assignin('base','sessionName', curSessionFileName)
            assignin('base','sessionEditorFilesActive', sessionEditorFilesActive)
            assignin('base','workingDir', pwd)
            p = path;
            tdir = tempdir;
            %curSession = regexp(curTitle, '- .*.sess$');
            [st, ei] = regexp(p, ['.' strrep(tdir,'\','\\') '.*?;']);
            if(~isempty(st))
              fprintf('Removing %s from the current path\n', p((st+1):ei));
              p((st+1):ei) = [];
            end
            assignin('base','sessionPath', p);
            % Let's not save the whole workspace
            %evalin('base', sprintf('save %s -mat -v7.3', sessionFullFile));
            evalin('base', sprintf('save %s sessionName sessionEditorFiles sessionPath workingDir sessionEditorFilesActive -mat -v7.3', sessionFullFile));
            assignin('base','lastSession', curSessionFileName)
            evalin('base', sprintf('save %s lastSession -mat -v7.3', fullfile(userpath, 'sessionManager', 'lastSession.sess')));
            evalin('base','clear sessionEditorFiles sessionName lastSession sessionPath workingDir sessionEditorFilesActive');
            success = true;
          case 'No'
            success = true;
          otherwise
            success = false;
        end
      else
        success = true;
      end
    end
    
    % ---------------------------------------------------------------------
    function load(varargin)
      % LOAD loads an existing session
      %
      % USAGE:
      %  sessionManager.load() - Opens a file dialog to select the session
      %  to load.
      %  - sessionManager.load('sessionName') - Automatically loads the
      %  session 'sessionName'.
      
      if(~sessionManager.save(false))
          return;
      end
      if(nargin > 0)
        fileName = varargin{1};
        pathName = '';
      else
        [fileName, pathName] = uigetfile(fullfile(userpath,'sessionManager','*.sess'));
        if(isempty(fileName))
          return;
        end
      end
      sessFiles = load(fullfile(pathName, fileName), '-mat');
      cd(sessFiles.workingDir);
      w = java.awt.Window.getOwnerlessWindows;
      mainWindow = w(arrayfun(@(x)(isa(x, 'com.mathworks.mde.desk.MLMainFrame')), w));
      curTiltle = mainWindow.getTitle();
      mainTitle = sprintf('MATLAB r%s (%s)', version('-release'), version('-description'));
      newTitle = sprintf('%s - %s', mainTitle, sessFiles.sessionName);
      mainWindow.setTitle(newTitle);
      closeNoPrompt(matlab.desktop.editor.getAll);
      for it = 1:length(sessFiles.sessionEditorFiles)
        matlab.desktop.editor.openDocument(sessFiles.sessionEditorFiles{it});
      end
      matlab.desktop.editor.openDocument(sessFiles.sessionEditorFilesActive);
      try
        userpath('reset');
        path(sessFiles.sessionPath);
        addpath(fullfile(userpath, 'sessionManager'));
      catch ME
        fprintf('Something went wrong loading the previous session path\n');
        disp(ME.message);
      end
      fprintf('Session %s succesfully loaded\n', sessFiles.sessionName);
    end
  end    
end
