addpath(fullfile(userpath, 'sessionManager'));
sessionManagerPath = fullfile(userpath, 'sessionManager');
if(exist(fullfile(sessionManagerPath,'lastSession.sess'), 'file'))
  load(fullfile(sessionManagerPath,'lastSession.sess'), '-mat');
  if(exist(fullfile(sessionManagerPath,lastSession), 'file'))
  	fprintf('Loading last session: %s\n', lastSession);
    sessionManager.load(lastSession);
  end
end