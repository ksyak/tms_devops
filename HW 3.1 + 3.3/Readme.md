```
vagrant@vm2:~$ cat /etc/apt/sources.list
# Оригинальные репозитории отключены — всё идёт через Nexus
# deb http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse

deb [trusted=yes] http://192.168.1.200:8081/repository/apt-proxy jammy main restricted universe multiverse
deb [trusted=yes] http://192.168.1.200:8081/repository/apt-proxy jammy-updates main restricted universe multiverse
deb [trusted=yes] http://192.168.1.200:8081/repository/apt-proxy jammy-security main restricted universe multiverse

```

```
vagrant@vm2:~$ sudo apt update
Hit:1 http://192.168.1.200:8081/repository/apt-proxy jammy InRelease
Hit:2 http://192.168.1.200:8081/repository/apt-proxy jammy-updates InRelease
Hit:3 http://192.168.1.200:8081/repository/apt-proxy jammy-security InRelease
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
All packages are up to date.

vagrant@vm2:/var/log/apt$ pip install --index-url http://admin:4e9d4ebf-6c72-4bb5-afae-5adf68c51df3@192.168.1.200:8081/repository/pypi-proxy/simple/   --trusted-host 192.168.1.200 konsole
Defaulting to user installation because normal site-packages is not writeable
Looking in indexes: http://admin:****@192.168.1.200:8081/repository/pypi-proxy/simple/
Collecting konsole
  Downloading http://192.168.1.200:8081/repository/pypi-proxy/packages/konsole/0.7.0/konsole-0.7.0-py3-none-any.whl (10.0 kB)
Installing collected packages: konsole
Successfully installed konsole-0.7.0

```


``