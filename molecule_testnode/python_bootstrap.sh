#/bin/bash
curl https://pyenv.run | bash
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init --path)"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

pyenv install 3.10.6
pyenv global 3.10.6

pip3 install pipenv selinux
echo 'export PIPENV_VENV_IN_PROJECT=1' >> ~/.bashrc

cat << EOF >> ~/.bashrc
if [ -f /root/.pyenv/shims/python3 ] && [ ! -f /usr/bin/python ]; then
  ln --symbolic /root/.pyenv/shims/python3 /usr/bin/python3;
  ln --symbolic /root/.pyenv/shims/python /usr/bin/python;
fi
EOF
source ~/.bashrc
pip3 install --upgrade pip
