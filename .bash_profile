# .bash_profile is executed for login shells, while .bashrc is executed for interactive non-login
# shells.

# When you login (type username and password) via console, either sitting at the machine, or
# remotely via ssh: .bash_profile is executed to configure your shell before the initial command
# prompt.

# But, if you’ve already logged into your machine and open a new terminal window (xterm) then
# .bashrc is executed before the window command prompt. .bashrc is also run when you start a new
# bash instance by typing /bin/bash in a terminal.

# On OS X, Terminal by default runs a login shell every time, so this is a little different to most
# other systems, but you can configure that in the preferences.

exec /bin/bash
