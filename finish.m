try
  sessionManager.save(false);
catch ME
  disp(ME.message);
  errordlg('Something went wrong while saving the current session','sessionManager save error');
  %answer = questdlg({'Something went wrong while saving the current session', 'Quit anyways?'},'sessionManager save error', 'Yes');
end