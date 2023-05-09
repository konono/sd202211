#/bin/bash
curl https://pyenv.run | bash

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

pyenv install 3.10.6
pyenv global 3.10.6

pip3 install pipenv selinux

cat << "EOL" >> ~/.bashrc
export PIPENV_VENV_IN_PROJECT=1

## Set path for pyenv
export PYENV_ROOT="${HOME}/.pyenv"

if [ -d "${PYENV_ROOT}" ]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init - --no-rehash)"
fi
if [ -f /root/.pyenv/shims/python3 ] && [ ! -f /usr/bin/python ]; then
  ln --symbolic /root/.pyenv/shims/python3 /usr/bin/python3;
  ln --symbolic /root/.pyenv/shims/python /usr/bin/python;
fi
EOL

source ~/.bashrc
pip3 install --upgrade pip
