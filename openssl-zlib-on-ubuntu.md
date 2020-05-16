# OpenSSL-zlib on Ubuntu

## Compile and Install
```bash
sudo apt install zlib1g-dev
git clone https://github.com/openssl/openssl
cd openssl/
./config zlib
make
sudo make install
sudo bash -c 'echo "include /usr/local/lib" >> /etc/ld.so.conf'
sudo ldconfig
```

## Run
```bash
/usr/local/bin/openssl
```
