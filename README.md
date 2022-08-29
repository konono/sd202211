# Software Design 2022年 11月号 handson material

## ディレクトリの説明
- .github  <- github action用のファイル
- molecule_testnode <- x86_64マシン向けvagrantファイル
- molecule_testnode_aarch64  <- aarch64マシン向けvagrantファイル
- roles/apache <- テスト用のAnsible roleファイル
- roles/apache/molecule <- moleculeディレクトリ、配下にはシナリオが配置されています
- inventory <- vagrantで立ち上げたインスタンスのアクセス情報
- Pipfile <- pipenvで仮想環境を作るための設定ファイル
- tox.ini <- toxのconfigurationファイル、github actionで利用

## Moleculeの動作環境構築

本編ではページ数の関係からInstallの部分をscriptの実行に省略させて頂いています。
ここでは1からインストールを試してみたいユーザー向けにREADMEを記載しています。

Moleculeは様々なツールと協調して動作するため環境構築が少し煩雑です、またAnsibleを開発するための環境という意味でいうとMoleculeが動作するだけではなくAnsibleを開発する上で必要なpython, ansibleのマルチバージョンテストが可能な環境をこれから構築していきます。

まずは事前準備としてVagrantやKVM、VirtualBox、もしくはAWSなどを利用してAlmaLinux 8 or 9もしくはRocky Linux 8 or 9を立ち上げて下さい。

もしもRHEL9系を使われる場合はdocker上でsystemctlを利用しようとした際に問題が発生するので以下のコマンドを実行しておいて下さい。[^1]

[^1]: https://github.com/systemd/systemd/issues/19245

```
sed -i 's/GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="selinux=0, systemd.unified_cgroup_hierarchy=0"'/g /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
sudo reboot
```

### pythonのマルチバージョン環境の構築とpipenvのインストール

pyenvはpythonのマルチバージョン環境を構築することができるツールです。
Ansible roleを開発するだけだとpythonのバージョンについてあまり意識することが無いかもしれません。しかし、Ansible自体や、Ansible moduleはpythonで動いているため、厳密にはそれぞれpythonに対してのrequirementが存在しています。

そのためテスト環境ではどのpythonバージョンとAnsibleバージョンであれば動作するということを確認できる必要があるため導入しています。

まずは必要な依存パッケージをインストールしていきます。

```
dnf install -y gcc zlib zlib-devel bzip2-devel readline-devel sqlite-devel openssl openssl-devel git libffi-devel tar make xz-devel
```

次にpyenvをインストールしていきます、pyenvはinstallerが提供されているため今回の環境構築ではinstallerを使ってインストールします。

```
curl https://pyenv.run | bash
```

pyenvのインストール後PATHなどの設定が必要になるので.bashrcに書き込んでいきます。

```
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
```

RHEL8系以降/usr/bin/にOSが使うpythonが配置されていないことがあります。そのための対策として「pythonバイナリがなかった場合はlinkを配置する」記述を.bashrcに書き込んでおきます。[^2]

[^2]: https://rheb.hatenablog.com/entry/rhel8-python

```
cat << EOF >> ~/.bashrc
if [ -f /root/.pyenv/shims/python3 ] && [ ! -f /usr/bin/python ]; then
  ln --symbolic /root/.pyenv/shims/python3 /usr/bin/python3;
  ln --symbolic /root/.pyenv/shims/python /usr/bin/python;
fi
EOF
```

pyenvを使ったpythonのインストールは以下のコマンドで実施します。

```
pyenv install 3.10.6
pyenv uninstall 3.9.8
pyenv global 3.10.6
```

これでpythonのマルチバージョン環境の構築が完了しました。

次にpipenvのインストールを進めていきます、ここで設定している環境変数は.venvディレクトリをプロジェクト内に置くための設定です。

```
pip3 install pipenv selinux

echo 'export PIPENV_VENV_IN_PROJECT=1' >> ~/.bashrc
source ~/.bashrc
```

pipenvはプロジェクト毎にvirtualenvを自動的に作成・管理することができます。また、プロジェクト内のパッケージのインストール・アンインストールに追従してPipfileと呼ばれるpipenv用のconfigurationファイルを動的に変更します。

Pipfileにはpythonのバージョンも記述することができ、pyevnが導入されている環境であれば指定したpythonバージョンをインストールすることも可能です。

またPipfileの他にPipfile.lockというファイルも作成され動的に変更されます、このファイルは明示的にインストールしたものだけでなく依存関係の解決のためにインストールされたpip packageのインストールされた時点のバージョンまで記録されています、そのためpipenvをインストールしている環境同士であればPipfile.lockファイルがあるディレクトリでpipenv syncコマンドを実行するだけで全く同じpythonのvirtual env環境を構築することができます。

Pipfileのサンプル
```
[root@node1 sd202211]# cat Pipfile
[[source]]
url = "https://pypi.org/simple"
verify_ssl = true
name = "pypi"

[packages]
ansible-lint = "*"
yamllint = "*"
molecule = {extras = ["docker", "podman"], version = "*"}
ansible-core = "*"
setuptools = "*"
tox = "*"

[dev-packages]

[requires]
python_version = "3.10"
```

Pipfile.lockのサンプル
```
=== snip ====
    "default": {
        "ansible-compat": {
            "hashes": [
                "sha256:676db8ec0449d1f07038625b8ebb8ceef5f8ad3a1af3ee82d4ed66b9b04cb6fa",
                "sha256:ce69a67785ae96e8962794a47494339991a0ae242ab5dd14a76ee2137d09072e"
            ],
            "markers": "python_version >= '3.8'",
            "version": "==2.2.0"
        },
        "ansible-core": {
            "hashes": [
                "sha256:449dbcfbfe18e4f23dec0c29b9aa60d76d205657a8e136484f4edea49faf7614",
                "sha256:eec5042530ff1c0c8d13a36fa047c6dd9157efeefd464a856b4ce38be4cd1988"
            ],
            "index": "pypi",
            "version": "==2.13.3"
        },
        "ansible-lint": {
            "hashes": [
                "sha256:8bba51a5da393db8fcbb050677fc59d8b2c9b7ebaf75f562619468375f40a318",
                "sha256:b02c5222450c469196c9cc28d3128e50f6bcf9549d5dd15c3cfbf47c70b5b06e"
            ],
            "index": "pypi",
            "version": "==6.5.1"
        },
        "arrow": {
            "hashes": [
                "sha256:05caf1fd3d9a11a1135b2b6f09887421153b94558e5ef4d090b567b47173ac2b",
                "sha256:d622c46ca681b5b3e3574fcb60a04e5cc81b9625112d5fb2b44220c36c892177"
            ],
            "markers": "python_full_version >= '3.6.0'",
            "version": "==1.2.2"
        },
=== snip ====
```

次にこの先Moleculeで必要になるDocker deamonのインストールを進めていきます。

### docker CEのインストール
dockerをインストールしていきます、RHEL8系以降のOSであればpodmanを利用することがリファレンスかもしれませんが、今回は広く世の中で使われているdockerをインストールすることにしています。

dockerパッケージをインストールするためにdocker-ceのレポジトリの設定を行います。

```
cat <<'EOF' > /etc/yum.repos.d/docker-ce.repo
[docker-ce-stable]
name=Docker CE Stable - $basearch
baseurl=https://download.docker.com/linux/centos/\$releasever/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF
```
docker CEのインストールとdocker deamonの立ち上げ

```
dnf install -y docker-ce docker-ce-cli containerd.io
systemctl enable --now docker
```

これでpythonのマルチバージョン環境の構築が完了しました。

次にMoleculeのインストールを進めていきます。

### Moleculeのインストールと動作確認

moleculeとｍoleculeが利用するpip packageをインストールします、またmoleculeを実行するためにroleファイルが必要なので、git cloneでダウンロードしてきます。

```
git clone https://github.com/konono/sd202211_molecule.git && cd sd202211_molecule
dnf install -y sshpass
pipenv install ansible-lint yamllint molecule[docker] ansible-core setuptools
```

インストールが完了したらmoleculeが実際に動作するかを確認してみましょう。

```
cd roles/apache
molecule test
=== snip ===
INFO     Running default > verify
INFO     Running Ansible Verifier

PLAY [Verify] ******************************************************************

TASK [Check httpd server is running] *******************************************
ok: [instance]

TASK [assert return content] ***************************************************
ok: [instance] => {
    "changed": false,
    "msg": "Apache successfully deployed!!!"
}

PLAY RECAP *********************************************************************
instance                   : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

INFO     Verifier completed successfully.
=== snip ===
```

ログが長いためここでは省略いたしますが、```Verifier completed successfully.```が確認できればmoleculeのインストールは無事完了です！お疲れさまでした！